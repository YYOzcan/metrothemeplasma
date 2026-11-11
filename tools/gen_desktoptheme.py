#!/usr/bin/env python3
"""Windows 8.1 Plasma masaüstü teması ("Metro"): görev çubuğu, görev düğmeleri, ipuçları, açılır pencereler.

    python3 -I tools/gen_desktoptheme.py <aero.msstyles> <çıktı dizini> [#renk yoğunluk]

Görev çubuğu zemini Renk ve Görünüm renginden (renk.py) + aero.msstyles TaskBar2Composited örtüsünden;
görev düğmeleri TaskBand2Composited8 (7 durum) resminden; ipucu Tooltip'ten.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import renk  # noqa: E402
from msstyles8 import MsStyles, durumlar, resim  # noqa: E402
from svgsayfa import Sheet  # noqa: E402

AD = "Metro"
YUK = 40          # görev çubuğu yüksekliği (Windows 8.1, %100)


def yaz(yol, sayfa):
    yol.parent.mkdir(parents=True, exist_ok=True)
    yol.write_text(sayfa.svg())


def gerdir(im, W, H, l, r, t, b):
    w, h = im.size
    out = Image.new("RGBA", (W, H))
    xs = [(0, l, 0, l), (l, w - r, l, W - r), (w - r, w, W - r, W)]
    ys = [(0, t, 0, t), (t, h - b, t, H - b), (h - b, h, H - b, H)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if sx1 <= sx0 or sy1 <= sy0 or dx1 <= dx0 or dy1 <= dy0:
                continue
            out.alpha_composite(im.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST), (dx0, dy0))
    return out


def golge(w, h, derinlik=6, opak=0.28):
    im = Image.new("RGBA", (w + derinlik * 2, h + derinlik * 2))
    d = ImageDraw.Draw(im)
    d.rectangle([derinlik, derinlik + 1, derinlik + w - 1, derinlik + h], fill=(0, 0, 0, int(255 * opak)))
    return im.filter(ImageFilter.GaussianBlur(derinlik / 2.2))


def panel(st, d, c, y):
    taban, opak = renk.gorev_cubugu(c, y)
    ortu = resim(st, 881)            # 1x40: üstte koyu çizgi, altta %20 siyah
    im = Image.new("RGBA", (20, YUK), tuple(int(v) for v in taban) + (int(255 * opak),))
    if ortu:
        o = ortu.resize((20, YUK), Image.NEAREST)
        im.alpha_composite(o)
    s = Sheet(scale=1, width=300)
    for onek in ["south", "north", ""]:
        s.add_frame(onek, im, 1, 1, 1, 1)
    dik = im.rotate(90, expand=True)
    for onek in ["west", "east"]:
        s.add_frame(onek, dik, 1, 1, 1, 1)
    for onek in ["south", "north", "west", "east", ""]:
        p = f"{onek}-" if onek else ""
        for kenar in ["top", "bottom", "left", "right"]:
            s.add_rect(f"{p}hint-{kenar}-margin", 1, 1)
    yaz(d / "widgets/panel-background.svg", s)
    yaz(d / "opaque/widgets/panel-background.svg", s)
    yaz(d / "solid/widgets/panel-background.svg", s)


def gorevler(st, d):
    """TaskBand2Composited8 düğmesi (60x40, 7 durum): 0-2 çalışıyor (normal/üzerinde/basılı),
    3-5 etkin (normal/üzerinde/basılı), 6 dikkat (turuncu yanıp sönme)."""
    ds = durumlar(resim(st, 1129), 7)
    s = Sheet(scale=1, width=600)
    eslem = {"normal": 0, "minimized": 0, "hover": 4, "focus": 3, "attention": 6, "pressed": 5}
    for tur, i in eslem.items():
        im = gerdir(ds[i], 60, YUK, 3, 3, 3, 3)
        s.add_frame(tur, im, 3, 3, 3, 3)
        for kenar in ["south", "north", "west", "east"]:
            s.add_frame(f"{kenar}-{tur}", im, 3, 3, 3, 3)
    yaz(d / "widgets/tasks.svg", s)


def ipucu(st, d):
    im = resim(st, 933)     # 9x22: beyaz, #767676 kenar
    if im is None:
        im = Image.new("RGBA", (9, 22), (255, 255, 255, 255))
    im = gerdir(im, 30, 30, 4, 4, 4, 4)
    s = Sheet(scale=1, width=300)
    s.add_frame("", im, 4, 4, 4, 4)
    s.add_frame("shadow", golge(30, 30, 4, 0.22), 6, 6, 6, 6)
    for kenar in ["top", "bottom", "left", "right"]:
        s.add_rect(f"hint-{kenar}-margin", 4, 4)
    yaz(d / "widgets/tooltip.svg", s)


def acilir(d, c, y):
    """Bildirim alanı açılır pencereleri (TrayNotifyFlyout): beyaz gövde, çerçeve renginde ince kenar."""
    kenar = tuple(int(v * 0.8) for v in renk.cerceve(c, y, True))
    im = Image.new("RGBA", (40, 40), (255, 255, 255, 255))
    dr = ImageDraw.Draw(im)
    dr.rectangle([0, 0, 39, 39], outline=kenar + (255,))
    s = Sheet(scale=1, width=400)
    s.add_frame("", im, 2, 2, 2, 2)
    s.add_frame("shadow", golge(40, 40, 8, 0.32), 10, 10, 10, 10)
    for k in ["top", "bottom", "left", "right"]:
        s.add_rect(f"hint-{k}-margin", 8, 8)
    yaz(d / "dialogs/background.svg", s)
    yaz(d / "solid/dialogs/background.svg", s)
    yaz(d / "opaque/dialogs/background.svg", s)
    # masaüstü uygulamacıkları
    s2 = Sheet(scale=1, width=300)
    s2.add_frame("", im, 2, 2, 2, 2)
    s2.add_frame("shadow", golge(40, 40, 6, 0.25), 8, 8, 8, 8)
    yaz(d / "widgets/background.svg", s2)
    yaz(d / "widgets/translucentbackground.svg", s2)


def gorunum_ogesi(d, c, y):
    """Liste öğeleri: Windows 8 açık mavi seçim (#cce8ff / #99d1ff)."""
    def kutu(dolgu, kenar):
        im = Image.new("RGBA", (20, 20), dolgu)
        ImageDraw.Draw(im).rectangle([0, 0, 19, 19], outline=kenar)
        return im
    s = Sheet(scale=1, width=300)
    s.add_frame("hover", kutu((229, 243, 255, 255), (229, 243, 255, 255)), 2, 2, 2, 2)
    s.add_frame("selected", kutu((204, 232, 255, 255), (153, 209, 255, 255)), 2, 2, 2, 2)
    s.add_frame("selected+hover", kutu((204, 232, 255, 255), (102, 167, 232, 255)), 2, 2, 2, 2)
    s.add_frame("normal", Image.new("RGBA", (20, 20)), 2, 2, 2, 2)
    yaz(d / "widgets/viewitem.svg", s)


RENKLER = """[Colors:Window]
BackgroundNormal=255,255,255
BackgroundAlternate=240,240,240
ForegroundNormal=0,0,0
ForegroundInactive=109,109,109
ForegroundActive=0,102,204
ForegroundLink=0,102,204
ForegroundVisited=102,0,153
ForegroundNegative=232,17,35
ForegroundNeutral=202,129,0
ForegroundPositive=16,124,16
DecorationFocus=51,153,255
DecorationHover=153,209,255

[Colors:View]
BackgroundNormal=255,255,255
BackgroundAlternate=246,246,246
ForegroundNormal=0,0,0
ForegroundInactive=109,109,109
ForegroundActive=0,102,204
ForegroundLink=0,102,204
ForegroundVisited=102,0,153
ForegroundNegative=232,17,35
ForegroundNeutral=202,129,0
ForegroundPositive=16,124,16
DecorationFocus=51,153,255
DecorationHover=153,209,255

[Colors:Button]
BackgroundNormal=225,225,225
BackgroundAlternate=236,236,236
ForegroundNormal=0,0,0
ForegroundInactive=109,109,109
ForegroundActive=0,102,204
ForegroundLink=0,102,204
ForegroundVisited=102,0,153
ForegroundNegative=232,17,35
ForegroundNeutral=202,129,0
ForegroundPositive=16,124,16
DecorationFocus=51,153,255
DecorationHover=153,209,255

[Colors:Selection]
BackgroundNormal=51,153,255
BackgroundAlternate=102,178,255
ForegroundNormal=255,255,255
ForegroundInactive=230,240,255
ForegroundActive=255,255,255
ForegroundLink=255,255,255
ForegroundVisited=255,255,255
ForegroundNegative=255,200,200
ForegroundNeutral=255,230,160
ForegroundPositive=200,255,200
DecorationFocus=51,153,255
DecorationHover=153,209,255

[Colors:Tooltip]
BackgroundNormal=255,255,255
BackgroundAlternate=255,255,255
ForegroundNormal=87,87,87
ForegroundInactive=109,109,109
ForegroundActive=0,102,204
ForegroundLink=0,102,204
ForegroundVisited=102,0,153
ForegroundNegative=232,17,35
ForegroundNeutral=202,129,0
ForegroundPositive=16,124,16
DecorationFocus=51,153,255
DecorationHover=153,209,255

[Colors:Complementary]
BackgroundNormal=40,40,40
BackgroundAlternate=60,60,60
ForegroundNormal=255,255,255
ForegroundInactive=210,210,210
ForegroundActive=255,255,255
ForegroundLink=255,255,255
ForegroundVisited=230,230,255
ForegroundNegative=255,170,160
ForegroundNeutral=255,220,120
ForegroundPositive=160,255,160
DecorationFocus=255,255,255
DecorationHover=255,255,255

[Colors:Header]
BackgroundNormal=255,255,255
BackgroundAlternate=240,240,240
ForegroundNormal=0,0,0
ForegroundInactive=109,109,109
ForegroundActive=0,102,204
ForegroundLink=0,102,204
ForegroundVisited=102,0,153
ForegroundNegative=232,17,35
ForegroundNeutral=202,129,0
ForegroundPositive=16,124,16
DecorationFocus=51,153,255
DecorationHover=153,209,255
"""


def main(msstyles, cikti, renk_hex=None, yogunluk=None):
    st = MsStyles(msstyles)
    if renk_hex:
        c, y = renk.hex2rgb(renk_hex), (int(yogunluk) / 100 if yogunluk else 0.55)
    else:
        c, y = renk.pencere_rengi()
    d = Path(cikti) / AD
    d.mkdir(parents=True, exist_ok=True)
    panel(st, d, c, y)
    gorevler(st, d)
    ipucu(st, d)
    acilir(d, c, y)
    gorunum_ogesi(d, c, y)
    (d / "colors").write_text(RENKLER)
    (d / "metadata.json").write_text(json.dumps({
        "KPackageStructure": "Plasma/Theme",
        "KPlugin": {"Id": AD, "Name": "Windows 8.1", "Name[tr]": "Windows 8.1",
                    "Description": "Windows 8.1 Plasma teması (aero.msstyles'tan)",
                    "Description[tr]": "Windows 8.1 Plasma teması (aero.msstyles'tan)",
                    "License": "GPL-3.0-or-later", "Version": "1.0",
                    "Authors": [{"Name": "MetroThemePlasma"}]},
        "X-Plasma-API": "5.0",
        "X-Plasma-Theme-Fallback": "default",
    }, indent=2, ensure_ascii=False))
    (d / "plasmarc").write_text("[ContrastEffect]\nenabled=false\n[BlurBehindEffect]\nenabled=false\n"
                                "[AdaptiveTransparency]\nenabled=false\n")
    print("masaüstü teması ->", d)


if __name__ == "__main__":
    main(*sys.argv[1:])
