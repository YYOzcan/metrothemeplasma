#!/usr/bin/env python3
"""Windows 8.1 Başlangıç ekranı arka plan desenlerini (imageres.dll RCDATA 20200..22100) çıkarır.

    python3 -I tools/gen_desen.py <win dizini> <çıktı: varlik/desen> [--onizle <dizin>]

Kaynak biçimi (çözümlenmiş):
  kapsayıcı : 8 u32 başlık (sihir 0x0007ACCF, .., girdi sayısı, .., toplam veri boyu), 8 u32'lik girdiler
              [tür, ofset, boy, c1, c2, 0, kip, ..]; tür 1 = resim (12 bayt önek: en, boy, 1 + PNG),
              diğerleri = sahne; tür değeri ölçek maskesidir (6 = %100, 8 = %140, 16 = %180, 30 = hepsi).
  sahne     : [sihir, genişlik(f), resim sayısı, davranış sayısı, düğüm sayısı, ek kayıt, 0, üst(düğüm 0)]
              + resim başvuruları (8 u32) + düğümler (16 u32) + davranışlar (9 u32).
  düğüm     : [bayrak, resim(-1 = grup), x, y, açı, ölçek, çapaX, çapaY, eksenX, eksenY, 0,0,0,0, opaklık, sonraki düğümün üstü]
  davranış  : [tür, özellik, düğüm, kip, genlik, çarpan, ofset, min, max]
              tür 0 = yatay kaydırma paralaksı, 1 = öteleme (özellik 4: dikey), 2 = döndürme.
  resim     : c1/c2 başvuru renkleri (c1 → arka plan rengi, c2 → vurgu rengi), kip 1 = iki renkli yeniden
              boyama, 3 = çok renkli (boyanmaz).
Çıktı: <kimlik>/sahne.json + <kimlik>/<n>.png; metro-kabuk bunları kaydırmayla canlandırır.
"""
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from peres import PEResources  # noqa: E402

SIHIR = 0x0007ACCF
FMAX = 3.0e38


def f32(u):
    return struct.unpack("<f", struct.pack("<I", u))[0]


def renk(u):
    """Bellekteki RGBA bayt sırası (u32 LE) -> '#rrggbb', alfa"""
    b = struct.pack("<I", u)
    return "#%02x%02x%02x" % (b[0], b[1], b[2]), b[3]


def sahne_coz(d, olcek_biti=6):
    if struct.unpack_from("<I", d, 0)[0] != SIHIR:
        return None
    sayi = struct.unpack_from("<I", d, 8)[0]
    toplam = struct.unpack_from("<I", d, 0x18)[0]
    taban = len(d) - toplam
    girdiler = []
    for i in range(sayi):
        o = 0x20 + 32 * i
        girdiler.append(struct.unpack_from("<7I", d, o))
    sahneler = [g for g in girdiler if g[0] != 1]
    sec = [g for g in sahneler if g[0] & olcek_biti] or sahneler
    if not sec:
        return None
    tur, ofs, boy = sec[-1][:3]
    b = d[taban + ofs:taban + ofs + boy]
    _, _, nres, ndav, ndug, nek, _, ust0 = struct.unpack_from("<8I", b, 0)
    genislik = struct.unpack_from("<f", b, 4)[0]
    resimler = []
    for i in range(nres):
        t, o, s, c1, c2, _z, kip = struct.unpack_from("<7I", b, 32 + 32 * i)
        veri = d[taban + o:taban + o + s]
        w, h, _bir = struct.unpack_from("<3I", veri, 0)
        r1, _a1 = renk(c1)
        r2, _a2 = renk(c2)
        resimler.append({"png": veri[12:], "w": w, "h": h, "c1": r1, "c2": r2, "tur": kip & 0xFFFF,
                         "esik": (kip >> 16) & 0xFF})
    p = 32 + 32 * nres
    u = struct.unpack_from("<%dI" % (ndug * 16), b, p)
    dugumler = []
    for k in range(ndug):
        a = u[k * 16:(k + 1) * 16]
        ust = -1 if k == 0 else u[(k - 1) * 16 + 15]
        dugumler.append({
            "bayrak": a[0], "r": struct.unpack("<i", struct.pack("<I", a[1]))[0],
            "x": f32(a[2]), "y": f32(a[3]), "aci": f32(a[4]), "olcek": f32(a[5]),
            "ax": f32(a[6]), "ay": f32(a[7]), "px": f32(a[8]), "py": f32(a[9]),
            "opak": f32(a[14]), "ust": ust})
    q = p + ndug * 64
    kalan = struct.unpack_from("<%dI" % ((len(b) - q) // 4), b, q)
    # davranış kayıtları 9 alanlıdır ve ilk alanı önceki kaydın sonunda durur (düğümlerdeki gibi)
    alanlar = (u[ndug * 16 - 1],) + tuple(kalan) if ndug else tuple(kalan)
    davranislar = []
    for i in range(ndav):
        a = alanlar[i * 9:(i + 1) * 9]
        if len(a) < 9:
            break
        davranislar.append({"tur": a[0], "ozellik": a[1], "dugum": a[2], "kip": a[3], "genlik": f32(a[4]),
                            "carpan": f32(a[5]), "ofset": f32(a[6]), "min": f32(a[7]), "max": f32(a[8])})
    return {"genislik": genislik, "resimler": resimler, "dugumler": dugumler, "davranislar": davranislar,
            "olcekTuru": tur}


def baskin_renk(png):
    import io
    from PIL import Image
    im = Image.open(io.BytesIO(png)).convert("RGB")
    c = sorted(im.getcolors(1 << 20), reverse=True)
    return "#%02x%02x%02x" % c[0][1]


def sinir(v):
    if v > FMAX:
        return None
    if v < -FMAX:
        return None
    return v


def aktar(win, cikti):
    win, cikti = Path(win), Path(cikti)
    res = PEResources((win / "Windows/System32/imageres.dll").read_bytes())
    kimlikler = sorted(n for t, n, l, d in res.items() if t == "RCDATA" and isinstance(n, int) and 20000 <= n <= 23000)
    yazilan = []
    for kid in kimlikler:
        try:
            s = sahne_coz(res.get("RCDATA", kid))
        except (struct.error, IndexError):
            s = None
        if not s:
            continue
        d = cikti / str(kid)
        d.mkdir(parents=True, exist_ok=True)
        resimler = []
        for i, r in enumerate(s["resimler"]):
            (d / f"{i}.png").write_bytes(r["png"])
            resimler.append({"dosya": f"{i}.png", "w": r["w"], "h": r["h"], "c1": r["c1"], "c2": r["c2"],
                             "tur": r["tur"], "esik": r["esik"]})
        dugumler = [{k: (round(v, 3) if isinstance(v, float) else v) for k, v in n.items() if k != "bayrak"}
                    for n in s["dugumler"]]
        yatay = {"dugum": 0, "carpan": 0.5}
        dikey = None
        for b in s["davranislar"]:
            if b["tur"] == 0:
                yatay = {"dugum": b["ozellik"] if b["ozellik"] < len(dugumler) else 0, "carpan": round(b["carpan"], 4)}
            elif b["tur"] == 1 and b["ozellik"] == 4:
                dikey = {"dugum": b["dugum"], "carpan": round(b["carpan"], 4), "min": sinir(b["min"]), "max": sinir(b["max"])}
            elif b["tur"] == 1 and b["dugum"] < len(dugumler):
                dugumler[b["dugum"]]["kay"] = {"carpan": round(b["carpan"], 4), "ofset": round(b["ofset"], 3),
                                               "min": sinir(b["min"]), "max": sinir(b["max"])}
            elif b["tur"] == 2 and b["dugum"] < len(dugumler):
                dugumler[b["dugum"]]["don"] = {"kip": b["kip"], "genlik": round(b["genlik"], 3),
                                               "carpan": round(b["carpan"], 5), "ofset": round(b["ofset"], 3)}
        # ön ayar renkleri: küçük resmin zemin rengi + iki renkli resimlerin vurgu başvurusu
        kucuk = res.get("PNG", kid + 1)
        arka = baskin_renk(kucuk) if kucuk else None
        vurgu = next((r["c2"] for r in s["resimler"] if r["tur"] == 1), None)
        (d / "sahne.json").write_text(json.dumps({
            "kimlik": kid, "genislik": round(s["genislik"], 2), "yatay": yatay, "dikey": dikey,
            "arkaPlan": arka, "vurgu": vurgu, "resimler": resimler, "dugumler": dugumler}, ensure_ascii=False))
        yazilan.append(kid)
    # düz renk (desen yok) ön ayarı
    print("  desenler:", len(yazilan), "sahne ->", cikti)
    return yazilan


# ------------------------------------------------------------------ sınama amaçlı çizim (QML ile aynı kurallar)
def boya(im, c1, c2, arka, vurgu):
    """İki renkli yeniden boyama: c1 → arka plan, c2 → vurgu (ara tonlar doğrusal, sapmalar korunur)."""
    import numpy as np
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    rgb = a[:, :, :3]
    v1 = np.array(c1, np.float32)
    v2 = np.array(c2, np.float32)
    yon = v2 - v1
    t = np.clip(((rgb - v1) @ yon) / max(1.0, float(yon @ yon)), 0, 1)[:, :, None]
    out = rgb + (np.array(arka, np.float32) - v1) * (1 - t) + (np.array(vurgu, np.float32) - v2) * t
    a[:, :, :3] = np.clip(out, 0, 255)
    from PIL import Image
    return Image.fromarray(a.astype("uint8"), "RGBA")


def ciz(dizin, W=1920, H=1080, kaydirma=0, arka=None, vurgu=None):
    import math
    from PIL import Image
    dizin = Path(dizin)
    s = json.loads((dizin / "sahne.json").read_text())
    h2r = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
    arka = arka or s["arkaPlan"] or "#180053"
    vurgu = vurgu or s["vurgu"] or "#4617b4"
    tuval = Image.new("RGBA", (W, H), h2r(arka) + (255,))
    dug = s["dugumler"]
    # dünya dönüşümleri: (a, b, c, d, e, f) afin
    def carp(m, n):
        return (m[0] * n[0] + m[2] * n[1], m[1] * n[0] + m[3] * n[1], m[0] * n[2] + m[2] * n[3], m[1] * n[2] + m[3] * n[3],
                m[0] * n[4] + m[2] * n[5] + m[4], m[1] * n[4] + m[3] * n[5] + m[5])
    dunya = {}
    for i, n in enumerate(dug):
        x = n["x"] + n["ax"] * W
        y = n["y"] + n["ay"] * H
        if i == s["yatay"]["dugum"]:
            x -= min(kaydirma * s["yatay"]["carpan"], max(0, s["genislik"] - W))
        aci = n["aci"]
        if "don" in n:
            dn = n["don"]
            if dn["kip"] == 1:
                aci += dn["ofset"] - dn["genlik"] * (1 - math.cos(dn["carpan"] * kaydirma)) / 2
            else:
                aci += dn["carpan"] * kaydirma + dn["ofset"]
        r = math.radians(aci)
        co, si = math.cos(r) * n["olcek"], math.sin(r) * n["olcek"]
        px, py = n["px"], n["py"]
        # T(x,y) * T(p) * R*S * T(-p)
        yerel = (co, si, -si, co, x + px - (co * px - si * py), y + py - (si * px + co * py))
        ust = dunya.get(n["ust"])
        dunya[i] = carp(ust[0], yerel) if ust else yerel
        dunya[i] = (dunya[i], (ust[1] if ust else 1.0) * n["opak"])
        if n["r"] < 0:
            continue
        res = s["resimler"][n["r"]]
        im = Image.open(dizin / res["dosya"]).convert("RGBA")
        if res["tur"] == 1:
            im = boya(im, h2r(res["c1"]), h2r(res["c2"]), h2r(arka), h2r(vurgu))
        m, op = dunya[i]
        det = m[0] * m[3] - m[1] * m[2]
        if abs(det) < 1e-9:
            continue
        ters = (m[3] / det, -m[2] / det, (m[2] * m[5] - m[3] * m[4]) / det,
                -m[1] / det, m[0] / det, (m[1] * m[4] - m[0] * m[5]) / det)
        kat = im.transform((W, H), Image.AFFINE, ters, Image.BILINEAR)
        if op < 0.999:
            al = kat.getchannel("A").point(lambda v: int(v * op))
            kat.putalpha(al)
        tuval.alpha_composite(kat)
    return tuval


if __name__ == "__main__":
    win, cikti = sys.argv[1], sys.argv[2]
    ids = aktar(win, cikti)
    if "--onizle" in sys.argv:
        hedef = Path(sys.argv[sys.argv.index("--onizle") + 1])
        hedef.mkdir(parents=True, exist_ok=True)
        for kid in ids:
            ciz(Path(cikti) / str(kid)).save(hedef / f"{kid}.png")
