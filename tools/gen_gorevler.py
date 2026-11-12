"""Windows 8.1 görev çubuğu düğmeleri (Metro görev çubuğu, ATP SevenTasks çatalı) için svgs/tasks.svg.

    python3 -I tools/gen_gorevler.py <aero.msstyles> <çıktı dizini>

Kaynak: aero.msstyles TaskBand2Composited8::TaskBand2
  p6  IMAGEFILE 1129 (60x40, 7 durum): 0 çalışıyor, 1 üzerinde, 2 basılı, 3 etkin, 4 etkin+üzerinde,
                                       5 etkin+basılı, 6 dikkat (turuncu)
  p13 IMAGEFILE 1136 (8x40, 3 durum): gruplanmış pencerelerin sağ kenardaki yığın çizgileri (1: iki, 2: üç+)
  p9/p11/p12/p10  1132/1133/1134/1135: ilerleme (yeşil), hata (kırmızı), duraklatıldı (sarı), belirsiz
"""
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from msstyles8 import MsStyles, durumlar, resim  # noqa: E402
from svgsayfa import Sheet  # noqa: E402


def main(msstyles, cikti):
    st = MsStyles(msstyles)
    ds = durumlar(resim(st, 1129), 7)
    s = Sheet(scale=1, width=700)
    for ad, i in [("normal", 0), ("normal-hover", 1), ("pressed", 2), ("active", 3), ("active-hover", 4),
                  ("active-pressed", 5), ("attention", 6), ("attention-hover", 6),
                  ("launcher-hover", 1), ("launcher-pressed", 2)]:
        s.add_frame(ad, ds[i], 3, 3, 3, 3)
    s.newline()
    # grup yığını: sol tarafı boş, sağ 8 piksel 1136'dan
    yigin = durumlar(resim(st, 1136), 3)
    for ad, i in [("group", 1), ("active-group", 1), ("group3", 2), ("active-group3", 2)]:
        im = Image.new("RGBA", (24, yigin[i].height))
        im.paste(yigin[i], (16, 0))
        s.add_frame(ad, im, 1, 3, 8, 3)
    s.newline()
    for ad, rid in [("progress", 1132), ("error", 1133), ("paused", 1134), ("marquee", 1135)]:
        im = resim(st, rid)
        im = im.resize((im.width, 40), Image.BILINEAR)
        s.add_frame(ad, im, 2, 2, 2, 2)
        for kenar in ["south", "north", "west", "east"]:
            s.add_frame(f"{kenar}-{ad}", im, 2, 2, 2, 2)
    d = Path(cikti)
    d.mkdir(parents=True, exist_ok=True)
    (d / "tasks.svg").write_text(s.svg())

    # atlama listesi ve pencere listesi öğeleri: Windows 8 düz vurgu (Windows 7'nin yuvarlak mavi geçişi yerine)
    def kutu(dolgu, kenar):
        im = Image.new("RGBA", (12, 12), dolgu)
        for x in range(12):
            im.putpixel((x, 0), kenar); im.putpixel((x, 11), kenar)
            im.putpixel((0, x), kenar); im.putpixel((11, x), kenar)
        return im
    bos = Image.new("RGBA", (12, 12))
    sicak = kutu((229, 243, 255, 255), (204, 232, 255, 255))
    secili = kutu((204, 232, 255, 255), (153, 209, 255, 255))
    j = Sheet(scale=1, width=200)
    for ad, im in [("normal", bos), ("hover", sicak), ("selected", secili)]:
        j.add_frame(ad, im, 2, 2, 2, 2)
    (d / "jumplistitem.svg").write_text(j.svg())
    # küçük resim / pencere listesi (görev çubuğu renginde zemin üstünde): beyaz yarı saydam
    m = Sheet(scale=1, width=200)
    for ad, im in [("normal", bos), ("hover", kutu((255, 255, 255, 40), (255, 255, 255, 90))),
                   ("pressed", kutu((255, 255, 255, 70), (255, 255, 255, 120))),
                   ("active", kutu((255, 255, 255, 55), (255, 255, 255, 110))),
                   ("attention", kutu((255, 200, 80, 90), (255, 200, 80, 160)))]:
        m.add_frame(ad, im, 2, 2, 2, 2)
    (d / "menuitem.svg").write_text(m.svg())


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
