#!/usr/bin/env python3
"""Kabuğun kullandığı Windows 8.1 görsellerini adlandırılmış PNG'lere çıkarır.

    python3 -I tools/gen_varlik.py <win dizini> <hedef varlik dizini>

twinui.dll  -> tılsım simgeleri, Başlat düğmesi, Masaüstü kutucuğu, uygulama başlık düğmeleri
authui.dll  -> oturum açma kullanıcı çerçeveleri, parola anahtarı
imageres.dll-> varsayılan kullanıcı resmi, Başlangıç arka plan küçük resimleri
"""
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from peres import PEResources  # noqa: E402

TWINUI = {
    # tılsımlar: 100% / 140% / 180% (48 / 67 / 86 px)
    "tilsim-aygitlar": (7220, 7225, 7230),
    "tilsim-ara": (7221, 7226, 7231),
    "tilsim-ayarlar": (7222, 7227, 7232),
    "tilsim-paylas": (7223, 7228, 7233),
    "tilsim-aygitlar-koyu": (7260, 7265, 7270),
    "tilsim-ara-koyu": (7261, 7266, 7271),
    "tilsim-ayarlar-koyu": (7262, 7267, 7272),
    "tilsim-paylas-koyu": (7263, 7268, 7273),
    "tilsim-aygitlar-golge": (7290, 7295, 7300),
    "tilsim-ara-golge": (7291, 7296, 7301),
    "tilsim-ayarlar-golge": (7292, 7297, 7302),
    "tilsim-paylas-golge": (7293, 7298, 7303),
    "tilsim-baslangic-golge": (7294, 7299, 7304),
    "tilsim-baslangic": (7320, 7321, 7322),
    "tilsim-baslangic-isik": (7310, 7311, 7312),
    # görev çubuğu Başlat düğmesi (8.1)
    "baslat-32": (11701,), "baslat-16": (11702,), "baslat-kontur-32": (11703,), "baslat-kontur-16": (11704,),
    "baslat-40": (11705,), "baslat-20": (11706,), "baslat-kontur-40": (11707,), "baslat-48": (11709,),
    "baslat-64": (11713,), "baslat-kontur-64": (11715,), "baslat-isik-32": (11718,), "baslat-isik-64": (11717,),
    "baslat-isik-80": (11719,),
    # Masaüstü kutucuğu (varsayılan duvar kağıdı küçük resmi)
    "masaustu-kucuk": (4541,), "masaustu-orta": (4546,), "masaustu-genis": (4551,), "masaustu-buyuk": (4555,),
    # Metro uygulama başlık çubuğu düğmeleri
    "baslik-menu": (9611,), "baslik-kucult": (9635,), "baslik-kapat": (9645,),
    # onay işareti, ok
    "onay": (3579,), "onay-beyaz": (3584,), "ok": (3594,), "ok-beyaz": (3599,),
}
AUTHUI = {
    "kullanici-cerceve": (12238,), "kullanici-cerceve-kucuk": (12233,),
    "parola-anahtar": (13500,), "resimli-parola": (17542,), "pin": (17000,),
}
IMAGERES = {
    "kullanici-varsayilan": ("PNG", 5293), "kullanici-varsayilan-kucuk": ("PNG", 5290),
}


def dib_resim(d):
    """BITMAP kaynağı (BITMAPINFOHEADER + piksel) -> PIL resmi; 32 bit ön-çarpılmış alfa düzeltilir."""
    import io
    import struct
    from PIL import Image
    hs, w, h, _pl, bpp, comp = struct.unpack_from("<IiiHHI", d, 0)
    if bpp != 32:
        pal = (struct.unpack_from("<I", d, 32)[0] or (1 << bpp)) * 4 if bpp <= 8 else 0
        bmp = b"BM" + struct.pack("<IHHI", 14 + len(d), 0, 0, 14 + hs + pal) + d
        return Image.open(io.BytesIO(bmp)).convert("RGBA")
    o = hs + (12 if comp == 3 and hs == 40 else 0)
    ah = abs(h)
    ham = d[o:o + w * ah * 4]
    im = Image.frombytes("RGBA", (w, ah), ham, "raw", "BGRA")
    if h > 0:
        im = im.transpose(Image.FLIP_TOP_BOTTOM)
    px = im.load()
    for y in range(ah):
        for x in range(w):
            r, g, b, a = px[x, y]
            if 0 < a < 255:
                px[x, y] = (min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a), a)
    return im


def kaydet(res, tur, kimlik, hedef):
    d = res.get(tur, kimlik)
    if d is None:
        return False
    hedef.write_bytes(d)
    return True


def main(win, cikti):
    win, cikti = Path(win), Path(cikti)
    cikti.mkdir(parents=True, exist_ok=True)
    s32 = win / "Windows/System32"
    tw = PEResources((s32 / "twinui.dll").read_bytes())
    for ad, kimlikler in TWINUI.items():
        for i, k in enumerate(kimlikler):
            ek = "" if len(kimlikler) == 1 else ["", "@140", "@180"][i]
            kaydet(tw, "IMAGE", k, cikti / f"{ad}{ek}.png")
    au = PEResources((s32 / "authui.dll").read_bytes())
    for ad, (k,) in AUTHUI.items():
        d = au.get("BITMAP", k)
        if d is None:
            continue
        im = dib_resim(d)
        im.save(cikti / f"{ad}.png")
    ir = PEResources((s32 / "imageres.dll").read_bytes())
    for ad, (tur, k) in IMAGERES.items():
        kaydet(ir, tur, k, cikti / f"{ad}.png")
    # Başlangıç arka planı küçük resimleri (Kişiselleştir bölmesi)
    kd = cikti / "desen-kucuk"
    kd.mkdir(exist_ok=True)
    for t, n, l, d in ir.items():
        if t == "PNG" and isinstance(n, int) and 20001 <= n <= 22101 and n % 100 == 1:
            (kd / f"{n - 1}.png").write_bytes(d)
    # hesap resmi
    hr = win / "ProgramData/Microsoft/User Account Pictures"
    for a in ("user.png", "user-200.png", "user-40.png"):
        if (hr / a).exists():
            shutil.copy(hr / a, cikti / a)
    print("  varlıklar:", len(list(cikti.glob("*.png"))), "resim")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
