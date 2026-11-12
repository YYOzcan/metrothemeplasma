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


def ilk_oturum(win, cikti):
    import json
    import re
    oobe = win / "Windows/System32/oobe"
    st = PEResources((oobe / "tr-TR/msoobeFirstLogonAnim.dll.mui").read_bytes()).strings()
    html = (oobe / "FirstLogonAnim.html").read_text(encoding="utf-8", errors="ignore")
    def dizi(ad):
        m = re.search(ad + r"=\[([0-9,]+)\]", html)
        return [int(x) for x in m.group(1).split(",")] if m else []
    r, g, b = dizi("rValues"), dizi("gValues"), dizi("bValues")
    renkler = ["#%02x%02x%02x" % t for t in zip(r, g, b)] or ["#008a00", "#2671eb", "#8c0095", "#ac193d", "#ff8f32", "#00aaaa"]
    m = re.search(r"steps=(\d+)", html)
    veri = {"metin": {str(k): v for k, v in st.items()}, "renkler": renkler, "adim": int(m.group(1)) if m else 240}
    (cikti / "ilk-oturum.json").write_text(json.dumps(veri, ensure_ascii=False, indent=1))


def metro_uygulamalari(win, cikti, liste):
    """Metro uygulamalarının simgeleri: kutucuk rengi kare + beyaz Segoe UI Symbol glifi (Uygulamalar görünümü,
    görev çubuğu, Alt+Tab); kutucukta kare kutucuk rengiyle birleşir, yalnız glif görünür."""
    import json
    from PIL import Image, ImageDraw, ImageFont
    yazi = ImageFont.truetype(str(win / "Windows/Fonts/seguisym.ttf"), 132)
    for u in json.loads(Path(liste).read_text()):
        im = Image.new("RGBA", (256, 256), u["renk"])
        d = ImageDraw.Draw(im)
        x0, y0, x1, y1 = d.textbbox((0, 0), u["glif"], font=yazi)
        d.text(((256 - (x1 - x0)) / 2 - x0, (256 - (y1 - y0)) / 2 - y0), u["glif"], font=yazi, fill="white")
        im.save(cikti / ("uygulama-%s.png" % u["ad"]))


def winver(win, cikti):
    """winver.ini + winver-marka.png (linver yaması okur): basebrd.dll BITMAP 121 ve dizeleri,
    shell32.dll.mui "Hakkında" iletişim kutusu (14352) ve sürüm biçimi (60)."""
    import re
    brd = win / "Windows/Branding/Basebrd"
    bb = PEResources((brd / "basebrd.dll").read_bytes())
    d = bb.get("BITMAP", 121)
    if d is not None:
        dib_resim(d).save(cikti / "winver-marka.png")
    bs = PEResources((brd / "tr-TR/basebrd.dll.mui").read_bytes()).strings()
    sh = PEResources((win / "Windows/System32/tr-TR/shell32.dll.mui").read_bytes())
    metin = sh.get("DIALOG", 14352).decode("utf-16-le", "ignore")
    parcalar = [x for x in re.split(r"[\x00-\x1f\uffff]+", metin) if len(x) > 3]
    baslik = next((x for x in parcalar if "%s" in x), "%s Hakkında").replace("%s", "Windows")
    uzun = next((x for x in parcalar if "%WINDOWS_LONG%" in x), "").lstrip("\x80\x81\x82")
    lisans = next((x for x in parcalar if "<A>" in x), "")
    lisans = lisans.replace("<A>", '<a style="color: #0066cc;" href="https://support.microsoft.com/tr-tr/windows/'
                            'microsoft-software-license-terms-e26eedad-97a2-5250-2670-aad156b654bd">').replace("</A>", "</a>")
    bicim = sh.strings().get(60, "Sürüm %d.%d (Yapım No %d%s)%s")
    surum = bicim.replace("%d.%d", "6.3").replace("%d%s", "9600").replace("%s", "")
    satirlar = ["[Windows81]", f"baslik={baslik}", "marka=winver-marka.png", "urun=Microsoft Windows",
                f"surum={surum}", f"telif={bs.get(14, '')}", f"ad={bs.get(13, bs.get(35, 'Windows 8.1'))}",
                f"lisans={lisans}", f"uzun={uzun.replace('%WINDOWS_LONG%', '%1')}"]
    # QSettings INI: değerlerdeki özel karakterler için tırnak
    def q(v):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    out = [satirlar[0]] + [k + "=" + q(v) for k, v in (x.split("=", 1) for x in satirlar[1:])]
    (cikti / "winver.ini").write_text("\n".join(out) + "\n")


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
    # görev çubuğu saati açılır penceresinin analog saati (timedate.cpl: kadran + üst parlaklık/merkez)
    td = PEResources((s32 / "timedate.cpl").read_bytes())
    for ad, k in (("saat-kadran", 5000), ("saat-ust", 5001)):
        d = td.get("PNGFILE", k)
        if d:
            (cikti / f"{ad}.png").write_bytes(d)
    # Windows 8.1 ilk oturum animasyonu (FirstLogonAnim): metinler msoobeFirstLogonAnim.dll.mui,
    # renk döngüsü FirstLogonAnim.html'den
    try:
        ilk_oturum(win, cikti)
    except Exception as x:  # noqa: BLE001
        print("  ilk oturum animasyonu atlandı:", x)
    liste = Path(__file__).resolve().parent.parent / "session/metro-uygulamalari/uygulamalar.json"
    try:
        metro_uygulamalari(win, cikti, liste)
    except Exception as x:  # noqa: BLE001
        print("  Metro uygulama simgeleri atlandı:", x)
    # Windows Hakkında (linver): marka görseli ve metinler kendi kopyandan
    try:
        winver(win, cikti)
    except Exception as x:  # noqa: BLE001
        print("  winver bilgisi atlandı:", x)
    # hesap resmi
    hr = win / "ProgramData/Microsoft/User Account Pictures"
    for a in ("user.png", "user-200.png", "user-40.png"):
        if (hr / a).exists():
            shutil.copy(hr / a, cikti / a)
    print("  varlıklar:", len(list(cikti.glob("*.png"))), "resim")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
