"""Metro arayüzünü bir dile çevirir: Türkçe kurulu kopyadan o dilin kopyasını üretir.

    python3 -I tools/dil_uygula.py agac  <dil> <kaynak dizin> <hedef dizin>   # QML/JS/JSON değişmezleri
    python3 -I tools/dil_uygula.py json  <dil> <çıktı.json>                   # C++ için düz sözlük
    python3 -I tools/dil_uygula.py rapor <dil> <dizin>                        # çevrilmeden kalan Türkçe metinler
    python3 -I tools/dil_uygula.py sec                                        # sistemin dili (metro-dil ile aynı kural)

Çeviri dosyası diller/<dil>.tsv (UTF-8, sekmeyle ayrılmış, değerler JSON kaçışlı: \\" \\n):
    123<TAB>çeviri                 kaynak.tsv'deki 123 numaralı metin
    123@Dosya.qml<TAB>çeviri       yalnız bu dosyada (aynı Türkçe metin başka anlamda kullanılıyorsa)
    =Türkçe metin<TAB>çeviri       kaynak.tsv'de olmayan ek metin
Satırı olmayan metinler değişmez. "category:" (ayar grubu adı) değerleri hiçbir zaman çevrilmez.
"""
import json
import os
import re
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dil_ortak import DILLER, coz, dil_sec, dizeler, kacir  # noqa: E402

KOK = Path(__file__).resolve().parent.parent
DIL = KOK / "diller"
TURKCE = re.compile(r"[çğıöşüÇĞİÖŞÜ]")


def _deger(ham):
    # kaçışsız çift tırnak da kabul edilir (An "Start" anheften)
    return json.loads('"' + re.sub(r'(?<!\\)"', r'\\"', ham) + '"')


def kaynak():
    k = {}
    for satir in (DIL / "kaynak.tsv").read_text(encoding="utf-8").splitlines():
        if satir.strip():
            n, v = satir.split("\t", 1)
            k[n] = _deger(v)
    return k


def yukle(dil):
    """(genel sözlük, dosyaya özel sözlük {(dosya adı, kaynak): çeviri})"""
    genel, ozel = {}, {}
    yol = DIL / f"{dil}.tsv"
    if dil == "tr" or not yol.exists():
        return genel, ozel
    k = kaynak()
    for no, satir in enumerate(yol.read_text(encoding="utf-8").splitlines(), 1):
        if not satir.strip() or satir.startswith("#"):
            continue
        anahtar, _, ham = satir.partition("\t")
        try:
            ceviri = _deger(ham)
        except json.JSONDecodeError as e:
            raise SystemExit(f"{yol}:{no}: kaçış hatası: {e}")
        dosya = None
        if "@" in anahtar and not anahtar.startswith("="):
            anahtar, dosya = anahtar.split("@", 1)
        if anahtar.startswith("="):
            metin = _deger(anahtar[1:])
        else:
            if anahtar not in k:
                raise SystemExit(f"{yol}:{no}: bilinmeyen numara {anahtar}")
            metin = k[anahtar]
        if dosya:
            ozel[(dosya, metin)] = ceviri
        else:
            genel[metin] = ceviri
    return genel, ozel


def cevir_metin(t, ad, genel, ozel):
    parcalar, son = [], 0
    for bas, bit, tirnak, icerik in dizeler(t, "js"):
        if tirnak == "`":
            continue
        if re.search(r"(^|[\s{;])category\s*:\s*$", t[max(0, bas - 40):bas]):
            continue
        v = coz(icerik)
        yeni = ozel.get((ad, v), genel.get(v))
        if yeni is None or yeni == v:
            continue
        parcalar.append(t[son:bas])
        parcalar.append(tirnak + kacir(yeni, tirnak) + tirnak)
        son = bit
    parcalar.append(t[son:])
    return "".join(parcalar)


def agac(dil, kaynak_dizin, hedef):
    kaynak_dizin, hedef = Path(kaynak_dizin), Path(hedef)
    if hedef.exists():
        shutil.rmtree(hedef)
    shutil.copytree(kaynak_dizin, hedef, symlinks=True)
    genel, ozel = yukle(dil)
    if not genel and not ozel:
        return
    for p in hedef.rglob("*"):
        if p.is_symlink() or not p.is_file() or p.suffix not in (".qml", ".js", ".json") or p.name == "metadata.json":
            continue
        t = p.read_text(encoding="utf-8", errors="surrogateescape")
        y = cevir_metin(t, p.name, genel, ozel)
        if y != t:
            p.write_text(y, encoding="utf-8", errors="surrogateescape")


def rapor(dil, dizin):
    """Çevrilmiş kopyada kalan Türkçe: kaynak listesindeki bir metinle aynı olanlar ve sözlükte olmayan,
    Türkçeye özgü harf (ğ ı ş İ) içeren değişmezler (yorumlar ve metadata.json hariç)."""
    genel, ozel = yukle(dil)
    hedefler = set(genel.values()) | set(ozel.values())
    kaynaklar = set(kaynak().values())
    kalan = {}
    for p in Path(dizin).rglob("*"):
        if not p.is_file() or p.suffix not in (".qml", ".js", ".json") or p.name == "metadata.json":
            continue
        for _, _, tirnak, icerik in dizeler(p.read_text(errors="ignore"), "js"):
            v = coz(icerik)
            if v in hedefler:
                continue
            if (v in kaynaklar and v not in hedefler and dil != "tr") or re.search(r"[ğışİŞĞ]", v):
                kalan.setdefault(v, set()).add(p.name)
    for v, d in sorted(kalan.items()):
        print(json.dumps(v, ensure_ascii=False), "  ←", ", ".join(sorted(d))[:80])
    print(len(kalan), "metin çevrilmeden kaldı", file=sys.stderr)


if __name__ == "__main__":
    komut = sys.argv[1]
    if komut == "agac":
        agac(sys.argv[2], sys.argv[3], sys.argv[4])
    elif komut == "json":
        genel, _ = yukle(sys.argv[2])
        Path(sys.argv[3]).parent.mkdir(parents=True, exist_ok=True)
        Path(sys.argv[3]).write_text(json.dumps(genel, ensure_ascii=False, indent=0), encoding="utf-8")
    elif komut == "rapor":
        rapor(sys.argv[2], sys.argv[3])
    elif komut == "sec":
        ev = os.environ
        diller = []
        try:
            rc = (Path(ev.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "plasma-localerc").read_text()
            m = re.search(r"^\[Translations\][^\[]*?^LANGUAGE=(.+)$", rc, re.M | re.S)
            if m:
                diller += m.group(1).strip().split(":")
            m = re.search(r"^\[Formats\][^\[]*?^LANG=(.+)$", rc, re.M | re.S)
            if m and not diller:
                diller.append(m.group(1).strip())
        except OSError:
            pass
        for d in ("LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG"):
            if ev.get(d):
                diller += ev[d].split(":")
        print(dil_sec(diller))
    else:
        raise SystemExit(__doc__)
    _ = DILLER
