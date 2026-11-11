#!/usr/bin/env python3
"""Windows 8.1 açılış ekranı (Plymouth): bootres.dll logosu + dönen noktalar; kapanışta "Kapatılıyor".

    python3 -I tools/gen_plymouth.py <win dizini> <çıktı: build/plymouth/metrothemeplasma> [#arkaplan]

Üretilenler: logo-1..5.png (winlogo*.bmp, siyah → saydam), halka-000..109.png (ProgressRing kareleri,
4,4 sn döngü, 25 kare/sn), kapat-*.png (Segoe UI Light yazılar), renk.script (kapanış zemin rengi).
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

KARE = 110
SURE = 4.4
BOYUT = 96
# WinRT ProgressRing anahtar kareleri: (zaman, açı, bezier)
KARELER = [(0.000, -110, None), (0.433, 10, (0.02, 0.33, 0.38, 0.77)), (1.200, 93, None),
           (1.617, 205, (0.57, 0.17, 0.95, 0.75)), (2.017, 357, (0, 0.19, 0.07, 0.72)), (2.783, 439, None),
           (3.217, 585, (0, 0, 0.95, 0.37))]


def bezier(p, x):
    lo, hi = 0.0, 1.0
    t = x
    for _ in range(24):
        t = (lo + hi) / 2
        bx = 3 * (1 - t) ** 2 * t * p[0] + 3 * (1 - t) * t * t * p[2] + t ** 3
        if bx < x:
            lo = t
        else:
            hi = t
    return 3 * (1 - t) ** 2 * t * p[1] + 3 * (1 - t) * t * t * p[3] + t ** 3


def aci(u):
    if u <= 0:
        return KARELER[0][1]
    for i in range(1, len(KARELER)):
        if u <= KARELER[i][0]:
            x = (u - KARELER[i - 1][0]) / (KARELER[i][0] - KARELER[i - 1][0])
            y = bezier(KARELER[i][2], x) if KARELER[i][2] else x
            return KARELER[i - 1][1] + (KARELER[i][1] - KARELER[i - 1][1]) * y
    return KARELER[-1][1]


def halka(zaman, boyut=BOYUT, ss=4):
    B = boyut * ss
    im = Image.new("RGBA", (B, B), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r_nokta = B / 18
    r = B / 2 - r_nokta
    for i in range(5):
        u = zaman - i * 0.167
        if u < 0 or u >= 3.217:
            continue
        # yavaşlama bölgesi (10°..93°) tepeye ortalanır: noktalar alttan doğar, tepede toplanır
        a = math.radians(aci(u) - 142)
        cx = B / 2 + r * math.cos(a)
        cy = B / 2 + r * math.sin(a)
        d.ellipse([cx - r_nokta, cy - r_nokta, cx + r_nokta, cy + r_nokta], fill=(255, 255, 255, 255))
    return im.resize((boyut, boyut), Image.LANCZOS)


def yazi(metin, yol, px=72):
    for aday in ("segoeuil.ttf", "segoeuisl.ttf", "segoeui.ttf"):
        try:
            f = ImageFont.truetype(str(yol / aday), px)
            break
        except OSError:
            f = None
    if f is None:
        f = ImageFont.load_default()
    kutu = f.getbbox(metin)
    im = Image.new("RGBA", (kutu[2] + 8, px + px // 2), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((4, 0), metin, font=f, fill=(255, 255, 255, 255))
    return im


def main(win, cikti, arka="#180053"):
    win, cikti = Path(win), Path(cikti)
    cikti.mkdir(parents=True, exist_ok=True)
    for i in range(1, 6):
        p = win / f"Boot/winlogo{i}.bmp"
        if not p.exists():
            continue
        im = Image.open(p).convert("RGBA")
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, _ = px[x, y]
                # siyah zemin → saydam (kenar yumuşatma pikselleri kısmi alfa)
                a = max(r, g, b)
                px[x, y] = (0, 204, 255, a) if a else (0, 0, 0, 0)
        im.save(cikti / f"logo-{i}.png")
    for k in range(KARE):
        halka(k * SURE / KARE).save(cikti / f"halka-{k:03d}.png")
    fontlar = win / "Windows/Fonts"
    yazi("Kapatılıyor", fontlar).save(cikti / "kapat-kapat.png")
    yazi("Yeniden başlatılıyor", fontlar).save(cikti / "kapat-yeniden.png")
    h = arka.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    (cikti / "renk.script").write_text(f"global.arka_r = {r:.4f};\nglobal.arka_g = {g:.4f};\nglobal.arka_b = {b:.4f};\n")
    kaynak = Path(__file__).resolve().parent.parent / "plymouth"
    betik = (kaynak / "metrothemeplasma.script").read_text()
    # Plymouth betiği başka dosya içe aktaramaz: renk sabitleri betiğin başına yazılır
    (cikti / "metrothemeplasma.script").write_text((cikti / "renk.script").read_text() + betik)
    (cikti / "metrothemeplasma.plymouth").write_text((kaynak / "metrothemeplasma.plymouth").read_text())
    print("plymouth ->", cikti)


if __name__ == "__main__":
    main(*sys.argv[1:])
