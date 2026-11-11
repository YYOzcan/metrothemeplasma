#!/usr/bin/env python3
"""Windows 8.1 pencere çerçevesi (Aurorae "Metro") — aero.msstyles DWM atlasından.

    python3 -I tools/gen_aurorae.py <aero.msstyles> <çıktı dizini> [#renk yoğunluk]

Düğme zeminleri ve glifler DWMWindow atlasından (STREAM 1060, %100) alınır; çerçeve rengi
Renk ve Görünüm ayarından (renk.py) hesaplanır. Başlık ortalı, Segoe UI, gölgesiz (Windows 8).
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import renk  # noqa: E402
from msstyles8 import MsStyles, atlas, durumlar  # noqa: E402
from svgsayfa import Sheet  # noqa: E402

TEMA = "Metro"
K = 8            # çerçeve kalınlığı (sol, sağ, alt)
UST = 30         # başlık çubuğu yüksekliği (üst kenar dahil)
GOLGE = 0        # Aurorae gölgesi KWin'in kendi gölgesiyle çizilir

# DWMWindow parça numaraları (atlas incelemesiyle): zemin 4 durum = normal, üzerinde, basılı, devre dışı
ZEMIN = {"kucuk": 3, "buyuk": 5, "kapat": 7, "kapat-pasif": 8}
GLIF = {"kapat": 12, "yardim": 16, "buyut": 20, "kucult": 24, "geri": 28}   # %100 boyutları


def cerceve_resmi(dolgu, dis, ic, maksimum=False):
    W, H = 160, UST + 40 + K
    im = Image.new("RGBA", (W, H), dolgu + (255,))
    d = ImageDraw.Draw(im)
    if not maksimum:
        d.rectangle([0, 0, W - 1, H - 1], outline=dis + (255,))
        # istemci alanını çevreleyen ince çizgi
        d.rectangle([K - 1, UST - 1, W - K, H - K], outline=ic + (255,))
    return im


def dugme(zemin, glif, renk_glif=None):
    """zemin: 4 durumlu atlas parçası (3 px yatay, 1 px dikey kenar payıyla); glif: 4 durum."""
    out = []
    zs = durumlar(zemin, 4)
    gs = durumlar(glif, 4)
    for i in range(4):
        z = zs[i].crop((3, 1, zs[i].width - 3, zs[i].height - 1))
        im = z.copy()
        g = gs[i]
        im.alpha_composite(g, ((im.width - g.width) // 2, (im.height - g.height) // 2))
        out.append(im)
    return out


def dugme_svg(etkin, pasif):
    s = Sheet(scale=1, width=400)
    adlar = ["active", "hover", "pressed", "deactivated"]
    for ad, im in zip(adlar, etkin):
        s.add_image(f"{ad}-center", im, im.width, im.height)
    s.newline()
    for ad, im in zip(adlar, pasif):
        s.add_image(f"{'inactive' if ad == 'active' else ad + '-inactive'}-center", im, im.width, im.height)
    s.newline()
    return s.svg()


def main(msstyles, cikti, renk_hex=None, yogunluk=None):
    st = MsStyles(msstyles)
    if renk_hex:
        c, y = renk.hex2rgb(renk_hex), (int(yogunluk) / 100 if yogunluk else 0.55)
    else:
        c, y = renk.pencere_rengi()
    etkin = tuple(int(v) for v in renk.cerceve(c, y, True))
    pasif = tuple(int(v) for v in renk.cerceve(c, y, False))
    d = Path(cikti) / TEMA
    d.mkdir(parents=True, exist_ok=True)

    s = Sheet(scale=1, width=700)
    for onek, dolgu, maks in [("decoration", etkin, False), ("decoration-inactive", pasif, False),
                              ("decoration-maximized", etkin, True), ("decoration-maximized-inactive", pasif, True)]:
        dis = tuple(int(v * 0.72) for v in dolgu)
        ic = tuple(int(v * 0.86) for v in dolgu)
        im = cerceve_resmi(dolgu, dis, ic, maks)
        if maks:
            s.add_frame(onek, im, 1, UST, 1, 1)
        else:
            s.add_frame(onek, im, K, UST, K, K)
    (d / "decoration.svg").write_text(s.svg())

    def parca(no):
        im, n = atlas(st, "DWMWindow", no)
        return im
    zk, zb, zkapat, zkapatp = parca(ZEMIN["kucuk"]), parca(ZEMIN["buyuk"]), parca(ZEMIN["kapat"]), parca(ZEMIN["kapat-pasif"])
    # etkin olmayan pencerede glifler soluk (4. satır) — normal durum için onu kullan
    def pasif_glif(g):
        gs = durumlar(g, 4)
        w, h = g.width, g.height // 4
        out = Image.new("RGBA", (w, h * 4))
        for i, k in enumerate([3, 1, 2, 3]):
            out.paste(gs[k], (0, i * h))
        return out
    for tur, zemin, glif in [("minimize", zk, "kucult"), ("maximize", zb, "buyut"), ("restore", zb, "geri"),
                             ("help", zk, "yardim"), ("close", zkapat, "kapat")]:
        g = parca(GLIF[glif])
        etkin_d = dugme(zemin, g)
        pasif_d = dugme(zkapatp if tur == "close" else zemin, pasif_glif(g))
        (d / f"{tur}.svg").write_text(dugme_svg(etkin_d, pasif_d))

    gk = zk.width - 6
    gkapat = zkapat.width - 6
    yuk = zk.height // 4 - 2
    (d / f"{TEMA}rc").write_text(f"""[General]
ActiveTextColor=0,0,0
InactiveTextColor=0,0,0
UseTextShadow=false
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=150
DecorationPosition=0
Shadow=true
HaloActive=false
HaloInactive=false

[Layout]
BorderLeft={K}
BorderRight={K}
BorderBottom={K}
TitleEdgeTop=1
TitleEdgeBottom=0
TitleEdgeLeft={K}
TitleEdgeRight={K - 1}
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=2
TitleEdgeRightMaximized=0
TitleBorderLeft=4
TitleBorderRight=4
TitleHeight={UST - 1}
ButtonWidth={gk}
ButtonWidthMinimize={gk}
ButtonWidthMaximizeRestore={gk}
ButtonWidthClose={gkapat}
ButtonWidthMenu=20
ButtonHeight={yuk}
ButtonSpacing=0
ButtonMarginTop=0
ButtonMarginTopMaximized=0
ExplicitButtonSpacer=0
PaddingTop=0
PaddingBottom=0
PaddingLeft=0
PaddingRight=0
""")
    (d / "metadata.json").write_text(json.dumps({
        "KPlugin": {"Id": TEMA, "Name": "Windows 8.1", "Version": "1.0",
                    "Description": "Windows 8.1 pencere çerçevesi (aero.msstyles'tan)",
                    "Authors": [{"Name": "MetroThemePlasma"}]},
        "KPackageStructure": "KWin/Aurorae"}, indent=2, ensure_ascii=False))
    (d / "metadata.desktop").write_text(f"""[Desktop Entry]
Name=Windows 8.1
Comment=Windows 8.1 pencere çerçevesi
X-KDE-PluginInfo-Name={TEMA}
X-KDE-PluginInfo-Author=MetroThemePlasma
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL-3.0-or-later
""")
    print("aurorae ->", d, "renk", renk.rgb2hex(etkin))


if __name__ == "__main__":
    main(*sys.argv[1:])
