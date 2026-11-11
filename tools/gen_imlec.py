#!/usr/bin/env python3
"""Windows 8.1 aero imleçlerinden (Windows/Cursors/aero_*.cur, .ani) Xcursor teması "Windows 8.1 Aero".

    python3 -I tools/gen_imlec.py <win dizini> <çıktı: .../icons/Windows 8.1 Aero>

.cur içindeki 32/48/64 boyutları ve .ani canlandırmaları (Meşgul, Arka planda çalışıyor) korunur;
metin (I) ve artı imleçleri user32.dll'den (aero.theme'de boş oldukları için Windows'unkiler).
"""
import io
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dib import decode_dib  # noqa: E402
from peres import PEResources  # noqa: E402

ADLAR = {
    "aero_arrow.cur": "default left_ptr arrow top_left_arrow x-cursor X_cursor right_ptr draft_large draft_small context-menu copy alias dnd-copy dnd-link link dnd-ask dnd-move dnd-none",
    "aero_working.ani": "progress left_ptr_watch half-busy 3ecb610c1bf2410f44200f48c40d3599 08e8e1c95fe2fc01f976f1e063a24ccd 00000000000000020006000e7e9ffc3f",
    "aero_busy.ani": "wait watch",
    "aero_link.cur": "pointer hand1 hand2 pointing_hand hand e29285e634086352946a0e7090d73106 9d800788f1b08800ae810202380a0822",
    "aero_helpsel.cur": "help question_arrow whats_this left_ptr_help 5c6cd98b3f3ebcb1f9c7f1c204630408 d9ce0ab605698f320427677b458ad60b",
    "aero_unavail.cur": "not-allowed forbidden crossed_circle no-drop circle dnd-no-drop 03b6e0fcb3499374a867c041f52298f0",
    "aero_pen.cur": "pencil draft",
    "aero_move.cur": "move fleur size_all all-scroll grab grabbing openhand closedhand 4498f0e0c1937ffe01fd06f973665830 9081237383d90e509aa00f00170e968f",
    "aero_nesw.cur": "nesw-resize size_bdiag fd_double_arrow ne-resize sw-resize top_right_corner bottom_left_corner fcf1c3c7cd4491d801f1e1c78f100000 ur_angle ll_angle",
    "aero_nwse.cur": "nwse-resize size_fdiag bd_double_arrow nw-resize se-resize top_left_corner bottom_right_corner c7f8f8f7f8f8f8f8f8f8f8f8f8f8f8f8 ul_angle lr_angle",
    "aero_ns.cur": "ns-resize size_ver sb_v_double_arrow v_double_arrow n-resize s-resize row-resize top_side bottom_side split_v 00008160000006810000408080010102 2870a09082c103050810ffdffffe0204",
    "aero_ew.cur": "ew-resize size_hor sb_h_double_arrow h_double_arrow e-resize w-resize col-resize left_side right_side split_h 028006030e0e7ebffc7f7070c0600140 14fef782d02440884392942c11205230",
    "aero_up.cur": "up-arrow center_ptr sb_up_arrow",
}
USER32 = {101: "text xterm ibeam vertical-text", 103: "crosshair cross tcross cross_reverse diamond_cross cell plus zoom-in zoom-out color-picker"}


def decode_cursor(blob):
    """CURSOR kaynağı (sıcak nokta öneki çıkarılmış) -> RGBA. Ters çevirme pikselleri siyah olur."""
    hsize, w, h2, planes, bpp = struct.unpack_from("<IiiHH", blob, 0)
    h = h2 // 2
    hdr = bytearray(blob[:hsize])
    struct.pack_into("<i", hdr, 8, h)
    img, _ = decode_dib(bytes(hdr) + blob[hsize:])
    a = np.asarray(img).copy()
    ncol = 0 if bpp > 8 else (struct.unpack_from("<I", blob, 32)[0] or (1 << bpp))
    xor_stride = ((w * bpp + 31) // 32) * 4
    off = hsize + ncol * 4 + xor_stride * h
    and_stride = ((w + 31) // 32) * 4
    m = np.frombuffer(blob[off:off + and_stride * h], np.uint8).reshape(h, and_stride)
    andbits = np.unpackbits(m, axis=1)[:, :w][::-1]
    if bpp == 32 and a[:, :, 3].any():
        return Image.fromarray(a, "RGBA")
    lum = a[:, :, :3].max(axis=2)
    out = a.copy()
    out[:, :, 3] = 255
    transparent = (andbits == 1) & (lum == 0)
    invert = (andbits == 1) & (lum > 0)
    out[transparent] = 0
    out[invert] = (0, 0, 0, 255)
    return Image.fromarray(out, "RGBA")


def with_shadow(img):
    """(kullanılmıyor: Windows 8 aero imleçlerinin gölgesi resmin içinde)"""
    a = np.asarray(img)
    alpha = Image.fromarray(a[:, :, 3])
    sh = Image.new("L", img.size)
    sh.paste(alpha, (2, 2))
    sh = sh.filter(ImageFilter.GaussianBlur(1.2)).point(lambda v: int(v * 0.35))
    shadow = Image.merge("RGBA", [Image.new("L", img.size, 0)] * 3 + [sh])
    shadow.alpha_composite(img)
    return shadow


def xcursor(frames):
    """frames: [(boyut, RGBA, xhot, yhot, gecikme)] -> Xcursor baytları (ARGB, önçarpımlı)."""
    ntoc = len(frames)
    header = struct.pack("<4sIII", b"Xcur", 16, 0x10000, ntoc)
    pos = 16 + ntoc * 12
    toc, chunks = b"", b""
    for size, img, xh, yh, delay in frames:
        w, h = img.size
        a = np.asarray(img).astype(np.uint32)
        al = a[:, :, 3]
        r = a[:, :, 0] * al // 255
        g = a[:, :, 1] * al // 255
        b = a[:, :, 2] * al // 255
        argb = (al << 24) | (r << 16) | (g << 8) | b
        chunk = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, size, 1, w, h, xh, yh, delay) + argb.astype("<u4").tobytes()
        toc += struct.pack("<III", 0xFFFD0002, size, pos)
        pos += len(chunk)
        chunks += chunk
    return header + toc + chunks


def cur_coz(veri):
    """.cur dosyası -> [(boyut, RGBA, xhot, yhot)]"""
    _, tur, n = struct.unpack_from("<HHH", veri, 0)
    out = []
    for i in range(n):
        w, h, cc, _r, hx, hy, boy, off = struct.unpack_from("<BBBBHHII", veri, 6 + 16 * i)
        blob = veri[off:off + boy]
        if blob[:8] == b"\x89PNG\r\n\x1a\n":
            im = Image.open(io.BytesIO(blob)).convert("RGBA")
        else:
            im = decode_cursor(blob)
        out.append((im.width, im, hx, hy))
    return out


def ani_coz(veri):
    """.ani (RIFF ACON) -> ([kareler: [(boyut, RGBA, xh, yh)]], [gecikme ms], sıra)"""
    kareler, hizlar, sira = [], None, None
    varsayilan = 6
    o = 12
    while o + 8 <= len(veri):
        ad, boy = struct.unpack_from("<4sI", veri, o)
        govde = veri[o + 8:o + 8 + boy]
        if ad == b"anih":
            varsayilan = struct.unpack_from("<I", govde, 28)[0] or 6
        elif ad == b"rate":
            hizlar = list(struct.unpack_from("<%dI" % (boy // 4), govde))
        elif ad == b"seq ":
            sira = list(struct.unpack_from("<%dI" % (boy // 4), govde))
        elif ad == b"LIST" and govde[:4] == b"fram":
            p = 4
            while p + 8 <= len(govde):
                a2, b2 = struct.unpack_from("<4sI", govde, p)
                if a2 == b"icon":
                    kareler.append(cur_coz(govde[p + 8:p + 8 + b2]))
                p += 8 + b2 + (b2 & 1)
        o += 8 + boy + (boy & 1)
    sira = sira or list(range(len(kareler)))
    hizlar = hizlar or [varsayilan] * len(sira)
    return [kareler[i] for i in sira], [int(r * 1000 / 60) for r in hizlar]


def boyutlu(girdiler, boyut):
    """İstenen boyuttaki girdi; yoksa en yakın büyükten küçült."""
    for b, im, hx, hy in girdiler:
        if b == boyut:
            return im, hx, hy
    en = max(girdiler, key=lambda g: g[0])
    b, im, hx, hy = en
    return im.resize((boyut, boyut), Image.LANCZOS), hx * boyut // b, hy * boyut // b


def main(win, cikti):
    win, cikti = Path(win), Path(cikti)
    kd = win / "Windows/Cursors"
    cdir = cikti / "cursors"
    cdir.mkdir(parents=True, exist_ok=True)
    for dosya, adlar in ADLAR.items():
        p = kd / dosya
        if not p.exists():
            continue
        cerceveler = []
        if dosya.endswith(".ani"):
            kareler, gecikme = ani_coz(p.read_bytes())
            for boyut in (32, 48, 64):
                for kare, g in zip(kareler, gecikme):
                    im, x, y = boyutlu(kare, boyut)
                    cerceveler.append((boyut, im, x, y, g))
        else:
            gir = cur_coz(p.read_bytes())
            for boyut in (24, 32, 48, 64):
                im, x, y = boyutlu(gir, boyut)
                cerceveler.append((boyut, im, x, y, 0))
        veri = xcursor(cerceveler)
        for ad in adlar.split():
            (cdir / ad).write_bytes(veri)
    # metin ve artı imleçleri: user32.dll
    u = win / "Windows/System32/user32.dll"
    if u.exists():
        r = PEResources(u.read_bytes())
        tekler = {n: d for t, n, l, d in r.items() if t == "CURSOR"}
        for t, n, l, d in r.items():
            if t != "GROUP_CURSOR" or n not in USER32:
                continue
            cnt = struct.unpack_from("<H", d, 4)[0]
            gir = []
            for i in range(cnt):
                rid = struct.unpack_from("<H", d, 6 + 14 * i + 12)[0]
                blob = tekler.get(rid)
                if not blob:
                    continue
                hx, hy = struct.unpack_from("<HH", blob, 0)
                im = decode_cursor(blob[4:])
                gir.append((im.width, im, hx, hy))
            if not gir:
                continue
            cerceveler = []
            for boyut in (24, 32, 48, 64):
                im, x, y = boyutlu(gir, boyut)
                cerceveler.append((boyut, im, x, y, 0))
            veri = xcursor(cerceveler)
            for ad in USER32[n].split():
                (cdir / ad).write_bytes(veri)
    (cikti / "index.theme").write_text("[Icon Theme]\nName=Windows 8.1 Aero\nComment=Windows 8.1 aero imleçleri (kendi kopyandan)\n")
    (cikti / "cursor.theme").write_text("[Icon Theme]\nName=Windows 8.1 Aero\n")
    print("imleçler ->", cdir, f"({len(list(cdir.iterdir()))} ad)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
