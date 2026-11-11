#!/usr/bin/env python3
"""KDE renk şeması "Metro" — aero.msstyles sysmetrics sistem renklerinden (Windows 8.1 klasik renkleri)
ve pencere çerçeve renginden.

    python3 -I tools/gen_renkler.py <aero.msstyles> <çıktı .colors> [#renk yoğunluk]
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import renk  # noqa: E402
from msstyles8 import MsStyles  # noqa: E402

# sysmetrics renk kimlikleri (1601 + COLOR_* dizini)
SIRA = ["SCROLLBAR", "BACKGROUND", "ACTIVECAPTION", "INACTIVECAPTION", "MENU", "WINDOW", "WINDOWFRAME",
        "MENUTEXT", "WINDOWTEXT", "CAPTIONTEXT", "ACTIVEBORDER", "INACTIVEBORDER", "APPWORKSPACE",
        "HIGHLIGHT", "HIGHLIGHTTEXT", "BTNFACE", "BTNSHADOW", "GRAYTEXT", "BTNTEXT", "INACTIVECAPTIONTEXT",
        "BTNHIGHLIGHT", "DKSHADOW", "LIGHT", "INFOTEXT", "INFOBK", "ALTERNATE", "HOTTRACKING",
        "GRADIENTACTIVE", "GRADIENTINACTIVE", "MENUHILIGHT", "MENUBAR"]


def sistem_renkleri(st):
    p = {}
    for r in st.records:
        if r["class"] == "sysmetrics" and isinstance(r["id"], int) and 1601 <= r["id"] <= 1631 and r["type"] == 204:
            p[SIRA[r["id"] - 1601]] = renk.hex2rgb(r["value"])
    return p


def k(c):
    return ",".join(str(int(round(v))) for v in c[:3])


def grup(ad, zemin, alternatif, yazi, pasif, etkin=(0, 102, 204), baglanti=(0, 102, 204), odak=(51, 153, 255), uzerinde=(153, 209, 255)):
    return f"""[{ad}]
BackgroundAlternate={k(alternatif)}
BackgroundNormal={k(zemin)}
DecorationFocus={k(odak)}
DecorationHover={k(uzerinde)}
ForegroundActive={k(etkin)}
ForegroundInactive={k(pasif)}
ForegroundLink={k(baglanti)}
ForegroundNegative=232,17,35
ForegroundNeutral=202,129,0
ForegroundNormal={k(yazi)}
ForegroundPositive=16,124,16
ForegroundVisited=102,0,153

"""


def main(msstyles, cikti, renk_hex=None, yogunluk=None):
    st = MsStyles(msstyles)
    s = sistem_renkleri(st)
    if renk_hex:
        c, y = renk.hex2rgb(renk_hex), (int(yogunluk) / 100 if yogunluk else 0.55)
    else:
        c, y = renk.pencere_rengi()
    etkin = renk.cerceve(c, y, True)
    pasif = renk.cerceve(c, y, False)
    yuz, pencere, yazi, gri = s["BTNFACE"], s["WINDOW"], s["WINDOWTEXT"], s["GRAYTEXT"]
    secim, secimYazi, link = s["HIGHLIGHT"], s["HIGHLIGHTTEXT"], s["HOTTRACKING"]
    metin = "[General]\nColorScheme=Metro\nName=Windows 8.1\nshadeSortColumn=false\n\n[KDE]\ncontrast=4\n\n"
    metin += grup("Colors:Button", (225, 225, 225), (236, 236, 236), s["BTNTEXT"], gri, link, link)
    metin += grup("Colors:Complementary", (40, 40, 40), (60, 60, 60), (255, 255, 255), (200, 200, 200),
                  (255, 255, 255), (255, 255, 255), (255, 255, 255), (255, 255, 255))
    metin += grup("Colors:Header", yuz, pencere, yazi, gri, link, link)
    metin += grup("Colors:Selection", secim, (102, 178, 255), secimYazi, (230, 240, 255), secimYazi, secimYazi)
    metin += grup("Colors:Tooltip", pencere, pencere, (87, 87, 87), gri, link, link)
    metin += grup("Colors:View", pencere, (246, 246, 246), yazi, gri, link, link)
    metin += grup("Colors:Window", yuz, (233, 233, 233), yazi, gri, link, link)
    metin += f"""[WM]
activeBackground={k(etkin)}
activeBlend={k(etkin)}
activeForeground=0,0,0
inactiveBackground={k(pasif)}
inactiveBlend={k(pasif)}
inactiveForeground=0,0,0
"""
    Path(cikti).parent.mkdir(parents=True, exist_ok=True)
    Path(cikti).write_text(metin)
    print("renk şeması ->", cikti)


if __name__ == "__main__":
    main(*sys.argv[1:])
