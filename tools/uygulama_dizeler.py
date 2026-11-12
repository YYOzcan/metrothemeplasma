"""C++/Qt kaynaklarındaki olası arayüz dizelerini listeler (çeviri sözlüğü hazırlamak için).

    python3 -I tools/uygulama_dizeler.py <kaynak dizini> > dizeler.txt

Çıktı: her satırda JSON dize; yol, komut, kimlik, DBus adı gibi arayüz dışı dizeler elenir.
"""
import json
import re
import sys
from pathlib import Path

DIZE = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
ELE = re.compile(r"^[a-z0-9_.\-/:%@#*?=+]+$|^[A-Z0-9_]+$|^(org|com|io|net)\.|^/|^\.|://|\.(png|svg|ico|desktop|conf|so|json|ini|xml|log|txt)$|^#[0-9a-fA-F]{3,8}$|^%\d$|^[\W\d_]+$")


def dizeler(kok):
    sonuc = {}
    for p in sorted(Path(kok).rglob("*")):
        if p.suffix not in (".cpp", ".h", ".ui"):
            continue
        metin = p.read_text(errors="ignore")
        if p.suffix == ".ui":
            for m in re.finditer(r"<string[^>]*>([^<]+)</string>", metin):
                s = m.group(1)
                if not ELE.search(s):
                    sonuc.setdefault(s, set()).add(p.name)
            continue
        for satir in metin.splitlines():
            t = satir.strip()
            if t.startswith(("#include", "//", "qDebug", "qWarning", "qCritical", "Q_LOGGING")):
                continue
            for m in DIZE.finditer(satir):
                s = re.sub(r"\\(.)", lambda k: {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(k.group(1), "\\" + k.group(1)), m.group(1))
                if len(s) < 2 or not re.search(r"[A-Za-z]{2}", s) or ELE.search(s):
                    continue
                if re.fullmatch(r"[a-z][A-Za-z0-9]*", s) or re.fullmatch(r"[A-Za-z]+\.[A-Za-z.]+", s):
                    continue  # kimlik/özellik adı
                sonuc.setdefault(s, set()).add(p.name)
    return sonuc


if __name__ == "__main__":
    for s, d in dizeler(sys.argv[1]).items():
        print(json.dumps(s, ensure_ascii=False), "  #", ",".join(sorted(d))[:60])
