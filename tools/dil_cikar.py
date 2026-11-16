"""Metro'nun kendi arayüz metinlerini (Türkçe kaynak) toplar: diller/kaynak.json {metin: [dosyalar]}.

    python3 -I tools/dil_cikar.py [--yaz]

QML/JS/JSON'da çift tırnaklı değişmezler, C++'ta QStringLiteral/QString("…") içindekiler.
Kimlik gibi görünenler (küçük harf ASCII, yol, renk, URL, yazı tipi adı …) alınmaz.
Çeviriler diller/<dil>.json: {kaynak: çeviri}; tools/dil_uygula.py kurulumda kopyalara uygular.
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dil_ortak import coz, dizeler  # noqa: E402

KOK = Path(__file__).resolve().parent.parent
QML = ["kabuk/qml", "kabuk/uygulamalar", "plasma/plasmoids", "plasma/gorevler/package", "plasma/tepsi/systemtray/package",
       "plasma/bildirim/applet", "plasma/masaustu/package", "plasma/shells", "plasma/look-and-feel", "sddm", "uac/qml", "ortak"]
CPP = ["kabuk/src", "plasma/masaustu/baglam", "plasma/masaustu/folder", "uac/src", "plasma/gorevler", "kabuk/uygulama", "kabuk/calistir"]

DEGISMEZ = re.compile(r'"((?:[^"\\\n]|\\.)+)"')
CPP_DEG = re.compile(r'(?:QStringLiteral|QString|QLatin1String|tr|i18n|i18nc)\(\s*"((?:[^"\\\n]|\\.)+)"')
TURKCE = re.compile(r"[çğıöşüÇĞİÖŞÜ]")
KIMLIK = re.compile(r"^[a-z0-9_.:/#%\-+*?=,;()\[\]{}<>|&!' ]*$")
ATLA = re.compile(r"^(file:|qrc:|image:|https?:|/|\.|#|\\u)|\.(qml|png|svg|jpg|js|json|desktop|so|ini|conf|mui|wav)$|"
                  r"^(Segoe UI.*|Segoe.*|Consolas|Noto.*|Qt\..*|[A-Z][A-Za-z]+\.[A-Za-z.]+)$|^(Kirigami|PlasmaCore|org\.|io\.|kcm_)")


def arayuz_metni(v):
    if len(v) < 2 or ATLA.search(v):
        return False
    if re.search(r"\);|\(\s*'|writeConfig|replace\(|=>|\bvar\b|\$\{|--group|kwriteconfig|qdbus|\|\||2>/dev/null|\$\(|"
                 r"^(sh|cd|ls|awk|konsole|plasmashell|timedatectl|spectacle|notify-send|import|panels|control) |"
                 r"^[A-Za-z]+;([A-Za-z]+;)*$|^[A-Z_]{3,}$|^(Build|Ctrl|Alt|Meta)[ +]|^<|[<>]$|^\[|\{\}|anchors\.|\.png", v):
        return False
    if KIMLIK.match(v):           # tamamen küçük harf ASCII: kimlik/anahtar
        return False
    if not re.search(r"[A-Za-zçğıöşüÇĞİÖŞÜ]{2}", v):
        return False
    if re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", v) and not TURKCE.search(v):
        # tek ASCII sözcük: Türkçe bir sözcükse al (büyük harfle başlayan), CamelCase tür adlarını alma
        return v[0].isupper() and not re.search(r"[a-z][A-Z]", v)
    return True


def topla():
    sonuc = {}

    def ekle(v, p):
        sonuc.setdefault(v, set()).add(str(p.relative_to(KOK)))

    for d in QML:
        for p in sorted((KOK / d).rglob("*")):
            if p.suffix not in (".qml", ".js", ".json") or "build" in p.parts or p.name == "metadata.json":
                continue
            t = p.read_text(errors="ignore")
            for bas, son, tirnak, icerik in dizeler(t, "js"):
                if tirnak == "`":
                    continue
                onu = t[max(0, bas - 600):bas]
                # KDE kataloğuyla çevrilen i18n*() (ATP çatalları), içe aktarmalar, kimlik/yol özellikleri
                if re.search(r"i18n[a-z]*\(\s*(?:\"(?:[^\"\\]|\\.)*\"\s*,\s*)*$", onu) or re.search(r"(^|\n)\s*import\s+\S*$", onu):
                    continue
                if re.search(r"(^|[\s{;])(id|objectName|source|icon\.name|iconName|font\.family|family|imagePath|prefix|category|location)\s*:\s*$", onu):
                    continue
                v = coz(icerik)
                if arayuz_metni(v):
                    ekle(v, p)
    for d in CPP:
        for p in sorted((KOK / d).rglob("*")):
            if p.suffix not in (".cpp", ".h") or "build" in p.parts or "_autogen" in str(p):
                continue
            t = p.read_text(errors="ignore")
            for bas, son, tirnak, icerik in dizeler(t, "cpp"):
                satir = t[t.rfind("\n", 0, bas) + 1:t.find("\n", son)]
                if re.search(r"QDBus|callDBus|qDebug|qWarning|qInfo|qCritical|Q_CLASSINFO|registerService|setObjectName|readEntry|writeEntry|#include|i18n", satir):
                    continue
                v = coz(icerik)
                if TURKCE.search(v) and arayuz_metni(v):
                    ekle(v, p)
    return {k: sorted(v) for k, v in sorted(sonuc.items())}


if __name__ == "__main__":
    s = topla()
    haric = set(json.loads((KOK / "diller/haric.json").read_text()))
    s = {k: v for k, v in s.items() if k not in haric}
    if "--yaz" in sys.argv:
        (KOK / "diller/kaynak.json").write_text(json.dumps(s, ensure_ascii=False, indent=1))
    print(len(s), "metin")
