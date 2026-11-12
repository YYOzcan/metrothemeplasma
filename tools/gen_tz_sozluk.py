"""Saat dilimi görünen adları için çeviri sözlüğü: kaynaktaki İngilizce Windows adları ↔ kendi
Windows 8.1 kopyandaki tzres.dll.mui Türkçe adları (aynı UTC farkı + ad benzerliği ile eşlenir).

    python3 -I tools/gen_tz_sozluk.py <win dizini> <WindowsTimeZones.cpp> <çıktı.json>
"""
import difflib
import json
import re
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from peres import PEResources  # noqa: E402

# İngilizce şehir/bölge adlarının Türkçe yazımları (benzerlik ölçümüne yardım)
YAKIN = {"Pacific": "Pasifik", "Eastern": "Doğu", "Central": "Orta", "Mountain": "Dağ", "Atlantic": "Atlantik",
         "Time": "Saati", "US & Canada": "ABD ve Kanada", "Islands": "Adaları", "West": "Batı", "East": "Doğu",
         "Coordinated Universal Time": "Eşgüdümlü Evrensel Saat", "Standard": "Standart", "Arabian": "Arap",
         "Athens": "Atina", "Bucharest": "Bükreş", "Istanbul": "İstanbul", "Moscow": "Moskova", "Brussels": "Brüksel",
         "Copenhagen": "Kopenhag", "Rome": "Roma", "Vienna": "Viyana", "Warsaw": "Varşova", "Prague": "Prag",
         "Jerusalem": "Kudüs", "Cairo": "Kahire", "Beijing": "Pekin", "Tokyo": "Tokyo", "Seoul": "Seul",
         "India": "Hindistan", "Greenland": "Grönland", "Azores": "Azorlar", "Hawaii": "Hawaii", "Alaska": "Alaska",
         "Brasilia": "Brasilia", "Caracas": "Karakas", "Mexico": "Meksika", "Baghdad": "Bağdat", "Tehran": "Tahran",
         "Kabul": "Kabil", "Kathmandu": "Katmandu", "Bangkok": "Bangkok", "Hanoi": "Hanoi", "Jakarta": "Cakarta",
         "Singapore": "Singapur", "Sydney": "Sidney", "Canberra": "Canberra", "Melbourne": "Melbourne",
         "Auckland": "Auckland", "Wellington": "Wellington", "Fiji": "Fiji", "Samoa": "Samoa", "Dateline": "Tarih Çizgisi"}


def sade(t):
    t = unicodedata.normalize("NFKD", t.lower())
    return "".join(c for c in t if c.isalnum() or c == " ")


def main(win, kaynak, cikti):
    mui = Path(win) / "Windows/System32/tr-TR/tzres.dll.mui"
    tr = [v for _, v in sorted(PEResources(mui.read_bytes()).strings().items()) if v.startswith("(UTC")]
    en = re.findall(r'\{\s*"(\(UTC[^"]*)"', Path(kaynak).read_text())
    onek = lambda s: s.split(")")[0] + ")"
    sozluk, kullanilan = {}, set()
    for e in en:
        adaylar = [t for t in tr if onek(t) == onek(e) and t not in kullanilan]
        if not adaylar:
            continue
        govde = e[len(onek(e)):].strip()
        for a, b in YAKIN.items():
            govde = govde.replace(a, b)
        en_iyi = max(adaylar, key=lambda t: difflib.SequenceMatcher(None, sade(govde), sade(t[len(onek(t)):])).ratio())
        oran = difflib.SequenceMatcher(None, sade(govde), sade(en_iyi[len(onek(en_iyi)):])).ratio()
        if len(adaylar) == 1 or oran >= 0.35:
            sozluk[e] = {"tr": en_iyi, "zorla": True}
            kullanilan.add(en_iyi)
    Path(cikti).parent.mkdir(parents=True, exist_ok=True)
    Path(cikti).write_text(json.dumps(sozluk, ensure_ascii=False, indent=1))
    print(f"  saat dilimleri: {len(sozluk)}/{len(en)} eşlendi")


if __name__ == "__main__":
    main(*sys.argv[1:4])
