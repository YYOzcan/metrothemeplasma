"""Bir C++/Qt kaynak ağacındaki arayüz dizelerini sözlükle Türkçeleştirir (yerinde).

    python3 -I tools/uygulama_cevir.py <kaynak dizini> <sozluk.json> [<sozluk2.json> ...]

Sözlük biçimi (JSON):
    { "Open": "Aç",
      "Name": {"tr": "Ad", "dosyalar": ["DevicePropertiesDialog.cpp"]},   # yalnızca bu dosyalarda
      "&File": {"tr": "&Dosya", "baglam": "addMenu"},                        # yalnızca bu metni içeren satırlarda
      "Ready": {"tr": "Hazır", "zorla": true} }                               # karşılaştırma satırlarında da

Kurallar:
- Yalnızca tam dize değişmezleri ("…") değiştirilir; .ui dosyalarında <string>…</string>.
- DBus, KConfig, JSON/özellik anahtarı gibi arayüz dışı kullanımlar atlanır (ATLA deseni).
- Değişmeyen sözlük girdileri (kaynakta artık olmayan dizeler) --rapor ile listelenir.
"""
import html
import json
from xml.sax.saxutils import escape as xml_kacis
import re
import sys
from pathlib import Path

ATLA = re.compile(
    r"QDBus|callDBus|\.call\(|asyncCall|readEntry|writeEntry|KConfigGroup|\.group\(|"
    r"\.value\(\s*QString|\.value\(\s*QLatin|\.value\(\s*\"|\.contains\(\s*\"|property\(\"|setProperty\(\"|"
    r"setObjectName|objectName\(|QJsonObject|\[\s*QStringLiteral\(\"|\[\s*\"|"
    r"startsWith\(|endsWith\(|indexOf\(|== *QLatin|== *QString|== *\"|!= *\"|"
    r"QProcess|startDetached|::fromLatin1|qputenv|qgetenv|getenv|QRegularExpression|"
    r"Q_PROPERTY|Q_CLASSINFO|registerService|registerObject|connect\(.*SIGNAL|qDebug|qWarning|qInfo|qCritical"
)


def yukle(yollar):
    """Sözlükleri birleştirir. "//ayar": {"zorla": true} o dosyadaki bütün girdileri
    karşılaştırma/anahtar satırlarında da çevirir (tutarlılık: aynı metin her yerde aynı çeviri)."""
    s = {}
    for y in yollar:
        veri = json.loads(Path(y).read_text())
        ayar = veri.get("//ayar", {}) if isinstance(veri.get("//ayar"), dict) else {}
        for k, v in veri.items():
            if k.startswith("//"):
                continue
            g = dict(v) if isinstance(v, dict) else {"tr": v}
            if ayar.get("zorla") and "zorla" not in g:
                g["zorla"] = True
            s[k] = g
    return s


def parcali(s, sozluk):
    """"Sistem ve Güvenlik/Linux Update" gibi birleşik yollar: her parça sözlükteyse parça parça çevir."""
    for ayirici in ("/", "\\"):
        if ayirici in s:
            parcalar = s.split(ayirici)
            # en az iki dolu parça ("View/" gibi ayar anahtarı önekleri çevrilmez)
            if sum(1 for p in parcalar if p) >= 2 and all(p in sozluk for p in parcalar if p):
                return ayirici.join(sozluk[p]["tr"] if p else p for p in parcalar), all(sozluk[p].get("zorla") for p in parcalar if p)
    return None, False


def kacis(t):
    return t.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def coz(ham):
    """Kaynaktaki dize değişmezini mantıksal dizeye çevirir (\\n, \\t, \\", \\\\)."""
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(m.group(1), "\\" + m.group(1)), ham)


def cevir(kok, sozluk, rapor=False):
    kullanilan = set()
    degisen = 0
    for p in sorted(Path(kok).rglob("*")):
        if p.suffix not in (".cpp", ".h", ".ui") or not p.is_file():
            continue
        metin = p.read_text(errors="ignore")
        yeni = metin
        if p.suffix == ".ui":
            def ui(m):
                s = html.unescape(m.group(2))
                g = sozluk.get(s)
                if g and (not g.get("dosyalar") or p.name in g["dosyalar"]):
                    kullanilan.add(s)
                    return m.group(1) + xml_kacis(g["tr"]) + m.group(3)
                return m.group(0)
            yeni = re.sub(r"(<string[^>]*>)([^<]+)(</string>)", ui, yeni)
        else:
            satirlar = []
            for satir in yeni.split("\n"):
                atla = bool(ATLA.search(satir)) and "tr(" not in satir

                def deg(m):
                    s = coz(m.group(2))
                    g = sozluk.get(s)
                    if not g:
                        ceviri, zorla = parcali(s, sozluk)
                        if ceviri is None:
                            return m.group(0)
                        g = {"tr": ceviri, "zorla": zorla}
                    # anahtar/karşılaştırma satırları yalnızca "zorla" girdileriyle çevrilir
                    # (ör. aynı metinle atanıp karşılaştırılan durum dizeleri)
                    if atla and not g.get("zorla"):
                        return m.group(0)
                    if g.get("dosyalar") and p.name not in g["dosyalar"]:
                        return m.group(0)
                    if g.get("baglam") and g["baglam"] not in satir:
                        return m.group(0)
                    kullanilan.add(s)
                    yeni_dize = '"' + kacis(g["tr"]) + '"'
                    # Latin-1 sarmalayıcıları Türkçe karakterleri bozar: UTF-8'e çevir
                    if m.group(1):
                        return "QString::fromUtf8(" + yeni_dize
                    if m.group(3):
                        return yeni_dize + "_s"
                    return yeni_dize
                satirlar.append(re.sub(r'(QLatin1String(?:View)?\(\s*)?"((?:[^"\\\n]|\\.)*)"(_L1)?', deg, satir))
            yeni = "\n".join(satirlar)
        if yeni != metin:
            p.write_text(yeni)
            degisen += 1
    if rapor:
        for k in sozluk:
            if k not in kullanilan:
                print("kullanılmadı:", json.dumps(k, ensure_ascii=False), file=sys.stderr)
    return degisen, len(kullanilan)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    d, k = cevir(args[0], yukle(args[1:]), "--rapor" in sys.argv)
    print(f"  çeviri: {d} dosya, {k} dize")
