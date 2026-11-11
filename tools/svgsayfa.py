"""SVG sayfası yardımcıları: 9 dilim, gömülü PNG, rsvg ile rasterleme (XPThemePlasma'dan)."""
from __future__ import annotations

import base64
import io
import subprocess
from dataclasses import dataclass, field

from PIL import Image

_gid = 0


def _new_id(prefix="g"):
    global _gid
    _gid += 1
    return f"{prefix}{_gid}"


def lingrad(stops, x1=0, y1=0, x2=0, y2=1, gid=None):
    """(defs_xml, url) döndürür. Konumlar objectBoundingBox biriminde."""
    gid = gid or _new_id("lg")
    s = "".join(
        f'<stop offset="{o}" stop-color="{c[:7]}"'
        + (f' stop-opacity="{int(c[7:9], 16) / 255:.3f}"' if len(c) == 9 else "")
        + "/>"
        for o, c in stops
    )
    return (f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>',
            f"url(#{gid})")


def radgrad(stops, cx=0.5, cy=0.5, r=0.5, fx=None, fy=None, gid=None):
    gid = gid or _new_id("rg")
    fx = cx if fx is None else fx
    fy = cy if fy is None else fy
    s = "".join(
        f'<stop offset="{o}" stop-color="{c[:7]}"'
        + (f' stop-opacity="{int(c[7:9], 16) / 255:.3f}"' if len(c) == 9 else "")
        + "/>"
        for o, c in stops
    )
    return (f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}" fx="{fx}" fy="{fy}">{s}</radialGradient>',
            f"url(#{gid})")


def svg_doc(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{defs}</defs>{body}</svg>')


def rrect_path(x, y, w, h, tl=0, tr=0, br=0, bl=0):
    """Köşeleri ayrı ayrı yuvarlatılmış dikdörtgen yolu."""
    return (f"M{x + tl},{y} H{x + w - tr} "
            + (f"A{tr},{tr} 0 0 1 {x + w},{y + tr} " if tr else "")
            + f"V{y + h - br} "
            + (f"A{br},{br} 0 0 1 {x + w - br},{y + h} " if br else "")
            + f"H{x + bl} "
            + (f"A{bl},{bl} 0 0 1 {x},{y + h - bl} " if bl else "")
            + f"V{y + tl} "
            + (f"A{tl},{tl} 0 0 1 {x + tl},{y} " if tl else "")
            + "Z")


def render(svg: str, scale: float = 1.0) -> Image.Image:
    """SVG metnini RGBA PIL görüntüsüne çevirir (rsvg-convert)."""
    out = subprocess.run(["rsvg-convert", "-z", str(scale), "-f", "png"],
                         input=svg.encode(), capture_output=True, check=True).stdout
    return Image.open(io.BytesIO(out)).convert("RGBA")


def png_b64(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    return base64.b64encode(buf.getvalue()).decode()


# ------------------------------------------------------------ 9 dilim ---
PARTS = ["topleft", "top", "topright", "left", "center", "right",
         "bottomleft", "bottom", "bottomright"]


def nine_slice(img: Image.Image, l, t, r, b, scale=1):
    """Görüntüyü (piksel cinsinden, ölçek uygulanmış) 9 parçaya böler.
    Dönüş: {parça: (PIL görüntü, mantıksal genişlik, mantıksal yükseklik)}"""
    W, H = img.size
    L, T, R, B = (int(round(v * scale)) for v in (l, t, r, b))
    xs = [0, L, W - R, W]
    ys = [0, T, H - B, H]
    out = {}
    i = 0
    for yi in range(3):
        for xi in range(3):
            name = PARTS[i]
            i += 1
            x0, x1, y0, y1 = xs[xi], xs[xi + 1], ys[yi], ys[yi + 1]
            if x1 <= x0 or y1 <= y0:
                continue
            crop = img.crop((x0, y0, x1, y1))
            out[name] = (crop, (x1 - x0) / scale, (y1 - y0) / scale)
    return out


# ------------------------------------------------------------ SVG sayfası ---
@dataclass
class Sheet:
    """Kimlikli raster/vektör elemanları yan yana dizen basit SVG sayfası."""
    scale: float = 1.0
    width: float = 1200
    items: list = field(default_factory=list)
    _x: float = 0
    _y: float = 0
    _row_h: float = 0
    gap: float = 4

    def _place(self, w, h):
        if self._x + w > self.width and self._x > 0:
            self._x = 0
            self._y += self._row_h + self.gap
            self._row_h = 0
        pos = (self._x, self._y)
        self._x += w + self.gap
        self._row_h = max(self._row_h, h)
        return pos

    def newline(self):
        self._x = 0
        self._y += self._row_h + self.gap * 2
        self._row_h = 0

    def add_image(self, eid, img: Image.Image, w=None, h=None):
        w = w if w is not None else img.size[0] / self.scale
        h = h if h is not None else img.size[1] / self.scale
        x, y = self._place(w, h)
        self.items.append(
            f'<image id="{eid}" x="{x}" y="{y}" width="{w}" height="{h}" '
            f'preserveAspectRatio="none" xlink:href="data:image/png;base64,{png_b64(img)}"/>')
        return x, y

    def add_rect(self, eid, w, h, fill="#000000", opacity=0.0):
        """Görünmez/ipucu elemanları (hint-*) için düz dikdörtgen."""
        x, y = self._place(w, h)
        self.items.append(f'<rect id="{eid}" x="{x}" y="{y}" width="{w}" height="{h}" '
                          f'fill="{fill}" fill-opacity="{opacity}"/>')

    def add_frame(self, prefix, img, l, t, r, b, sep="-", center_name="center",
                  skip=()):
        """9 dilimi `prefix-topleft` ... `prefix-center` adlarıyla ekler.
        prefix boşsa adlar `topleft`, `center` olur."""
        parts = nine_slice(img, l, t, r, b, self.scale)
        x0 = None
        for name in PARTS:
            if name not in parts or name in skip:
                continue
            crop, w, h = parts[name]
            n = center_name if name == "center" else name
            eid = f"{prefix}{sep}{n}" if prefix else n
            if eid.endswith(sep) and prefix:
                eid = prefix
            self.add_image(eid, crop, w, h)
        self.newline()

    def add_kv_frame(self, el, state, img, l, t, r, b):
        """Kvantum adlandırması: el-state-top ..., iç kısım: el-state"""
        parts = nine_slice(img, l, t, r, b, self.scale)
        for name in PARTS:
            if name not in parts:
                continue
            crop, w, h = parts[name]
            eid = f"{el}-{state}" if name == "center" else f"{el}-{state}-{name}"
            self.add_image(eid, crop, w, h)
        self.newline()

    def svg(self):
        H = self._y + self._row_h + self.gap
        return svg_doc(self.width, H, "\n".join(self.items))


def draw(w, h, body, defs="", scale=1.0) -> Image.Image:
    return render(svg_doc(w, h, body, defs), scale)
