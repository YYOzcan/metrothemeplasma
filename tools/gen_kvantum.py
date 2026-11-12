#!/usr/bin/env python3
"""Windows 8.1 Kvantum teması ("Metro") — aero.msstyles denetim resimlerinden.

    python3 -I tools/gen_kvantum.py <aero.msstyles> <çıktı dizini>

Düğme, onay kutusu, radyo, kaydırma çubuğu, sekme, başlık, ilerleme, kaydırıcı, döndürme, araç çubuğu,
metin kutusu kenarı msstyles'tan (ön-çarpılmış alfa düzeltilerek); menüler Windows 8 menü renkleriyle.
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import kvantum_taban as gk  # noqa: E402
from msstyles8 import MsStyles, durumlar, resim  # noqa: E402
from svgsayfa import Sheet  # noqa: E402

S = 2


def buyut(im):
    return im.resize((im.width * S, im.height * S), Image.NEAREST)


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


def main(msstyles, cikti):
    st = MsStyles(msstyles)
    d = Path(cikti) / gk.NAME
    d.mkdir(parents=True, exist_ok=True)
    s = Sheet(scale=S, width=900)

    def parca(cls, p):
        pr = st.props(cls, p, 0)
        oz = st.find(cls).get((p, 0), {})
        # DPI'ye göre seçilen parçalarda IMAGEFILE1 (%100); yoksa parçanın kendi IMAGEFILE'ı
        rid = (oz.get("IMAGEFILE1") if oz.get("IMAGESELECTTYPE") else None) or oz.get("IMAGEFILE") \
            or oz.get("IMAGEFILE1") or pr.get("IMAGEFILE") or pr.get("IMAGEFILE1")
        im = resim(st, rid) if rid else None
        return im, pr.get("IMAGECOUNT", 1), pr.get("SIZINGMARGINS", (0, 0, 0, 0))

    def kv(el, durum, im, l, r, t, b, w=None, h=None):
        if w or h:
            im = gerdir(im, w or im.width, h or im.height, l, r, t, b)
        s.add_kv_frame(el, durum, buyut(im), l, t, r, b)

    def ind(eid, im):
        s.add_image(eid, buyut(im), im.width, im.height)

    # ---- basma düğmesi: Normal, Üzerinde, Basılı, Devre dışı, Varsayılan
    im, n, (l, r, t, b) = parca("Button", 1)
    ds = durumlar(im, n)
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("toggled", 2), ("disabled", 3), ("default", 4)]:
        kv("btn", durum, ds[i], 3, 3, 3, 3, 30, 23)

    # ---- araç çubuğu düğmesi (8 durum: N, H, P, D, Checked, HotChecked, ...)
    im, n, m = parca("Toolbar", 1)
    ds = durumlar(im, n)
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("disabled", 3), ("toggled", 4)]:
        kv("tbaritem", durum, ds[i], 3, 3, 3, 3, 24, 24)

    # ---- açılır kutu: salt okunur gövde (düğme gibi) + sağ düğme
    im, n, m = parca("Combobox", 5)
    ds = durumlar(im, n)
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("toggled", 2), ("disabled", 3)]:
        kv("combo", durum, ds[i], 3, 3, 3, 3, 30, 21)
    # açılır ok: Windows 8'deki 7x4 piksellik keskin üçgen (zemin "combo" çerçevesinden gelir)
    def ucgen(renk):
        # Kvantum oku kare alana ölçekler: 9x9 tuvalin ortasında 7x4 üçgen (en-boy oranı korunur)
        z = Image.new("RGBA", (9, 9))
        for sat in range(4):
            for x in range(sat, 7 - sat):
                z.putpixel((x + 1, sat + 3), renk)
        return z
    for durum, rn in [("normal", (0, 0, 0, 255)), ("focused", (0, 0, 0, 255)), ("pressed", (0, 0, 0, 255)),
                      ("toggled", (0, 0, 0, 255)), ("disabled", (160, 160, 160, 255))]:
        ind(f"carrow-{durum}", ucgen(rn))
    s.newline()

    # ---- kaydırma çubuğu okları (20 durum: yukarı/aşağı/sol/sağ x N,H,P,D + 4 üzerinde)
    im, n, m = parca("ScrollBar", 1)
    ds = durumlar(im, n)
    for di, yon in enumerate(["up", "down", "left", "right"]):
        for si, durum in enumerate(["normal", "focused", "pressed", "disabled"]):
            ind(f"scarrow-{yon}-{durum}", ds[di * 4 + si])
    s.newline()
    # başparmak (yatay), oluk, tutamak
    im, n, (l, r, t, b) = parca("ScrollBar", 2)
    th = durumlar(im, n)
    im, n, m = parca("ScrollBar", 4)
    tr = durumlar(im, n)
    im, n, m = parca("ScrollBar", 8)
    gr = durumlar(im, n)
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("toggled", 2), ("disabled", 3)]:
        kv("scrollslide", durum, th[i], 3, 3, 3, 3, 30, 17)
        kv("trough", durum, tr[i].resize((24, 17), Image.NEAREST), 1, 1, 1, 1)
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("disabled", 3)]:
        ind(f"sgrip-{durum}", gr[i])
    s.newline()

    # ---- onay kutusu (20 durum: işaretsiz, işaretli, karışık, ... x 4), radyo (8)
    im, n, m = parca("Button", 3)
    ck = durumlar(im, n)
    for ki, tur in enumerate(["", "checked-", "tristate-"]):
        for si, durum in enumerate(["normal", "focused", "pressed", "disabled"]):
            ind(f"checkbox-{tur}{durum}", ck[ki * 4 + si])
    im, n, m = parca("Button", 2)
    rb = durumlar(im, n)
    for ki, tur in enumerate(["", "checked-"]):
        for si, durum in enumerate(["normal", "focused", "pressed", "disabled"]):
            ind(f"radio-{tur}{durum}", rb[ki * 4 + si])
    s.newline()

    # ---- grup kutusu, sekmeler, sekme bölmesi
    im, n, m = parca("Button", 4)
    for durum in gk.STATES:
        kv("gbox", durum, im, 2, 2, 2, 2, 24, 24)
    im, n, m = parca("Tab", 1)
    tt = durumlar(im, n)            # N, Üzerinde, Seçili, Devre dışı, Odak
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("toggled", 2), ("disabled", 3)]:
        kv("tab", durum, tt[i], 2, 2, 3, 1, 40, 22)
    im, n, m = parca("Tab", 9)
    for durum in gk.STATES:
        kv("tbf", durum, im, 1, 1, 1, 1, 24, 24)

    # ---- ilerleme çubuğu: oluk + Windows 8 yeşil dolgu
    im, n, m = parca("Progress", 1)
    for durum in gk.STATES:
        kv("pbgutter", durum, im, 3, 3, 3, 3, 24, 16)
    im, n, m = parca("Progress", 5)
    dolgu = im.crop((0, 0, im.width, im.height))
    for durum in ["normal", "focused", "toggled"]:
        kv("pbc", durum, dolgu, 2, 2, 2, 2, 24, 14)
    s.newline()

    # ---- kaydırıcı: oluk + başparmak (alta bakan)
    im, n, m = parca("TrackBar", 1)
    for durum in gk.STATES:
        kv("slider", durum, im, 1, 1, 1, 1, 24, 4)
    im, n, m = parca("TrackBar", 4)
    thb = durumlar(im, n)           # N, H, P, Odak, D
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("disabled", 4)]:
        ind(f"scursor-{durum}", thb[i])
    s.newline()

    # ---- başlık sütunu, ağaç okları (Gezgin üçgenleri), boyutlandırma tutamağı
    im, n, m = parca("Header", 1)
    hd = durumlar(im, n)
    for durum, i in [("normal", 0), ("focused", 1), ("pressed", 2), ("toggled", 2), ("disabled", 0)]:
        kv("hdr", durum, hd[i], 2, 2, 2, 2, 24, 24)
    im, n, m = parca("Explorer::TreeView", 2)
    tg = durumlar(im, n)            # kapalı, açık
    im2, n2, m2 = parca("Explorer::TreeView", 4)
    tgh = durumlar(im2, n2) if im2 else tg
    for durum in ["normal", "focused", "pressed"]:
        ind(f"tree-plus-{durum}", (tgh if durum != "normal" else tg)[0])
        ind(f"tree-minus-{durum}", (tgh if durum != "normal" else tg)[1])
    im, n, m = parca("Status", 3)
    ind("resize-grip-normal", durumlar(im, n)[0])
    s.newline()

    # ---- döndürme düğmeleri
    for yon, p in [("up", 1), ("down", 2)]:
        im, n, m = parca("Spin", p)
        sp = durumlar(im, n)
        for si, durum in enumerate(["normal", "focused", "pressed", "disabled"]):
            z = gerdir(sp[si], 16, 11, 3, 3, 3, 3)
            ok = gk.img(9, 9, gk.triangle(yon, "#838383" if durum == "disabled" else "#000000")).resize((7, 7))
            z.alpha_composite(ok, (5, 2))
            ind(f"spind-{yon}-{durum}", z)
        s.add_image(f"spind-plus-normal", gk.img(9, 9, '<path d="M1,4h7v1h-7z M4,1h1v7h-1z" fill="#000"/>'), 9, 9)
    s.newline()

    # ---- metin kutusu kenarı (N, Üzerinde, Odak, Devre dışı)
    im, n, m = parca("Edit", 6)
    ed = durumlar(im, n)
    for durum, i in [("normal", 0), ("focused", 2), ("pressed", 2), ("toggled", 2), ("disabled", 3)]:
        kv("ledit", durum, ed[i], 2, 2, 2, 2, 24, 22)

    # ---- araç çubuğu zemini
    for durum in gk.STATES:
        s.add_kv_frame("tlbar", durum, buyut(Image.new("RGBA", (8, 8), (240, 240, 240, 255))), 1, 1, 1, 1)

    # ---- menüler (Windows 8: #F0F0F0 zemin, #979797 kenar; seçili öğe açık mavi #D1E2F2, kenar #78AEE5)
    def menu_zemin():
        im = Image.new("RGBA", (24, 24), (240, 240, 240, 255))
        for x in range(24):
            im.putpixel((x, 0), (151, 151, 151, 255)); im.putpixel((x, 23), (151, 151, 151, 255))
            im.putpixel((0, x), (151, 151, 151, 255)); im.putpixel((23, x), (151, 151, 151, 255))
        return im

    def menu_ogesi(secili):
        im = Image.new("RGBA", (24, 20), (0, 0, 0, 0))
        if secili:
            im = Image.new("RGBA", (24, 20), (209, 226, 242, 255))
            for x in range(24):
                im.putpixel((x, 0), (120, 174, 229, 255)); im.putpixel((x, 19), (120, 174, 229, 255))
            for y in range(20):
                im.putpixel((0, y), (120, 174, 229, 255)); im.putpixel((23, y), (120, 174, 229, 255))
        return im
    for durum in gk.STATES:
        s.add_kv_frame("mnu", durum, buyut(menu_zemin()), 2, 2, 2, 2)
        sec = durum in ("focused", "pressed", "toggled")
        s.add_kv_frame("menuitem", durum, buyut(menu_ogesi(sec)), 1, 1, 1, 1)
        s.add_kv_frame("mbaritem", durum, buyut(menu_ogesi(sec)), 1, 1, 1, 1)
        s.add_kv_frame("mubar", durum, buyut(Image.new("RGBA", (24, 20), (245, 246, 247, 255))), 1, 1, 1, 1)
        s.add_kv_frame("common", durum, gk.generic_frame(durum), 1, 1, 1, 1)
        tip = Image.new("RGBA", (24, 24), (255, 255, 255, 255))
        for x in range(24):
            tip.putpixel((x, 0), (118, 118, 118, 255)); tip.putpixel((x, 23), (118, 118, 118, 255))
            tip.putpixel((0, x), (118, 118, 118, 255)); tip.putpixel((23, x), (118, 118, 118, 255))
        s.add_kv_frame("ttip", durum, buyut(tip), 2, 2, 2, 2)
        # liste seçimi (Windows 8 Gezgin: açık mavi)
        if durum in ("toggled", "pressed"):
            iv = Image.new("RGBA", (24, 20), (204, 232, 255, 255))
            s.add_kv_frame("iview", durum, buyut(iv), 1, 1, 1, 1)
            s.add_kv_frame("iview", durum + "-inactive", buyut(Image.new("RGBA", (24, 20), (217, 217, 217, 255))), 1, 1, 1, 1)
        elif durum == "focused":
            s.add_kv_frame("iview", durum, buyut(Image.new("RGBA", (24, 20), (229, 243, 255, 255))), 1, 1, 1, 1)
        else:
            s.add_kv_frame("iview", durum, buyut(Image.new("RGBA", (24, 20))), 1, 1, 1, 1)
    for durum in ["normal", "focused", "pressed", "disabled"]:
        for yon in ["up", "down", "left", "right"]:
            col = "#838383" if durum == "disabled" else "#000000"
            s.add_image(f"arrow-{yon}-{durum}", gk.img(9, 9, gk.triangle(yon, col)), 9, 9)
    s.newline()
    s.add_kv_frame("focus", "x", gk.focus_frame(), 1, 1, 1, 1)

    svg = s.svg().replace('id="focus-x-', 'id="focus-').replace('id="focus-x"', 'id="focus"')
    (d / f"{gk.NAME}.svg").write_text(svg)
    cfg = gk.KVCONFIG
    cfg = cfg.replace("slider_handle_width=21\nslider_handle_length=11",
                      f"slider_handle_width={thb[0].height}\nslider_handle_length={thb[0].width}")
    cfg = cfg.replace("menu_shadow_depth=4", "menu_shadow_depth=5")
    (d / f"{gk.NAME}.kvconfig").write_text(cfg)
    print("kvantum ->", d)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "build/kvantum")
