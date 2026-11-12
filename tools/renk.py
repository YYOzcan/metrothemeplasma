"""Windows 8.1 pencere rengi (Renk ve Görünüm) hesapları.

Ayar dosyası: ~/.config/metrothemeplasma/ayarlar.ini
    [Pencere]
    renk=otomatik | #rrggbb        (otomatik: duvar kağıdının baskın rengi)
    yogunluk=55                    (Renk yoğunluğu, 0..100)
"""
import configparser
import colorsys
import os
from pathlib import Path

CFG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "metrothemeplasma/ayarlar.ini"
DATA = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "metrothemeplasma"

# Windows 8.1 "Renk ve Görünüm" örnekleri (Otomatik + 15 renk)
ORNEKLER = ["#6b6b6b", "#2f4f8f", "#0f6fbf", "#2aa1d8", "#109a9a", "#2e8b3f", "#86b72f", "#d6a700",
            "#e3780c", "#d03d16", "#c41f3a", "#c4207e", "#8e3db9", "#5a42b5", "#ffd8e5"]


def ayarlar():
    c = configparser.ConfigParser(interpolation=None)
    c.optionxform = str
    if CFG.exists():
        try:
            c.read(CFG, encoding="utf-8")
        except configparser.Error:
            pass
    return c


def oku(bolum, anahtar, varsayilan=""):
    """QSettings değerleri tırnaklı yazabilir ("#180053"): tırnakları at."""
    v = ayarlar().get(bolum, anahtar, fallback=varsayilan)
    return v.strip().strip('"')


def yaz(bolum, degerler):
    """ayarlar.ini'de yalnızca verilen anahtarları satır satır günceller (QSettings biçimi korunur)."""
    satirlar = CFG.read_text(encoding="utf-8").splitlines() if CFG.exists() else []
    out, icinde, yazildi, bulundu = [], False, set(), False
    for st in satirlar + [None]:
        yeni_bolum = st is None or (st.strip().startswith("[") and st.strip().endswith("]"))
        if yeni_bolum and icinde:
            for k, v in degerler.items():
                if k not in yazildi:
                    out.append(f"{k}={v}")
            icinde = False
        if st is None:
            break
        if yeni_bolum:
            icinde = st.strip()[1:-1] == bolum
            bulundu = bulundu or icinde
            out.append(st)
            continue
        if icinde and "=" in st and st.split("=", 1)[0].strip() in degerler:
            k = st.split("=", 1)[0].strip()
            out.append(f"{k}={degerler[k]}")
            yazildi.add(k)
            continue
        out.append(st)
    if not bulundu:
        if out and out[-1].strip():
            out.append("")
        out.append(f"[{bolum}]")
        out += [f"{k}={v}" for k, v in degerler.items()]
    CFG.parent.mkdir(parents=True, exist_ok=True)
    CFG.write_text("\n".join(out).rstrip("\n") + "\n", encoding="utf-8")


def gecerli_duvar():
    """Metro kabuğunun masaüstü duvar kağıdı (paketse içindeki en büyük resim)."""
    import re
    yap = CFG.parent.parent
    for ad in ("plasma-io.github.yyozcan.metroshell-appletsrc",):
        p = yap / ad
        if not p.exists():
            continue
        m = re.search(r"\[Wallpaper\]\[org\.kde\.image\]\[General\][^\[]*?^Image=([^\n]+)", p.read_text(errors="replace"), re.M | re.S)
        if not m:
            continue
        y = m.group(1).strip()
        if y.startswith("file://"):
            from urllib.parse import unquote
            y = unquote(y[7:])
        yol = Path(y)
        if yol.is_dir():
            adaylar = sorted((yol / "contents/images").glob("*"), key=lambda f: f.stat().st_size)
            if adaylar:
                return adaylar[-1]
        elif yol.exists():
            return yol
    return None


def hex2rgb(h):
    h = h.strip().lstrip("#")
    if len(h) == 8:
        h = h[2:]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgb2hex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(v)))) for v in c[:3])


def karistir(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def duvar_rengi(yol):
    """Duvar kağıdının baskın rengi (Windows 8 otomatik renk: doygun ve parlak tonlara ağırlık)."""
    from PIL import Image
    im = Image.open(yol).convert("RGB")
    im.thumbnail((160, 160))
    kova = [[0.0, 0, 0, 0] for _ in range(36)]
    for r, g, b in im.getdata():
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if s < 0.2 or v < 0.2:
            continue
        w = s * v
        k = kova[min(35, int(h * 36))]
        k[0] += w
        k[1] += r * w
        k[2] += g * w
        k[3] += b * w
    en = max(range(36), key=lambda i: kova[(i - 1) % 36][0] * 0.5 + kova[i][0] + kova[(i + 1) % 36][0] * 0.5)
    w = sum(kova[(en + d) % 36][0] for d in (-1, 0, 1))
    if w < 1:
        return (107, 107, 107)
    c = tuple(sum(kova[(en + d) % 36][j] for d in (-1, 0, 1)) / w for j in (1, 2, 3))
    h, s, v = colorsys.rgb_to_hsv(*(x / 255 for x in c))
    s = min(0.85, max(0.45, s))
    v = min(0.85, max(0.55, v))
    return tuple(x * 255 for x in colorsys.hsv_to_rgb(h, s, v))


def varsayilan_duvar():
    return DATA / "win/Windows/Web/Wallpaper/Windows/img0.jpg"


def pencere_rengi(duvar=None):
    """(renk RGB, yoğunluk 0..1)"""
    r = oku("Pencere", "renk", "otomatik")
    try:
        y = int(oku("Pencere", "yogunluk", "55")) / 100
    except ValueError:
        y = 0.55
    if r == "otomatik":
        d = duvar or gecerli_duvar() or varsayilan_duvar()
        try:
            c = duvar_rengi(d)
        except Exception:
            c = hex2rgb("#2aa1d8")
    else:
        c = hex2rgb(r)
    return c, y


def cerceve(c, y, etkin=True):
    """Win8 DWM: opak çerçeve = renk ile açık griyi yoğunluk oranında karıştırır.
    Etkin olmayan pencereler neredeyse beyaz-gri."""
    if etkin:
        return karistir((217, 217, 217), c, 0.25 + 0.65 * y)
    return karistir((235, 235, 235), c, 0.08 + 0.12 * y)


def gorev_cubugu(c, y):
    """Görev çubuğu: rengin saydam hali + %20 siyah örtü (aero.msstyles TaskBar2Composited)."""
    taban = karistir((40, 40, 40), c, 0.55 + 0.4 * y)
    koyu = tuple(v * 0.80 for v in taban)
    return koyu, 0.80 + 0.15 * y
