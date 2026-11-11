"""DIB (BITMAP / ICON) çözücü — XPThemePlasma msstyles.py'den."""
import struct

import numpy as np
from PIL import Image


def _rle(data, w, h, bits):
    """RLE8/RLE4 piksel verisini (alttan üste satırlar) indeks dizisine açar."""
    out = np.zeros((h, w), np.uint8)
    x = y = i = 0
    n = len(data)
    while i + 1 < n and y < h:
        cnt, val = data[i], data[i + 1]
        i += 2
        if cnt > 0:
            for k in range(cnt):
                if x < w:
                    out[y, x] = val if bits == 8 else ((val >> 4) if k % 2 == 0 else (val & 15))
                x += 1
        elif val == 0:
            x, y = 0, y + 1
        elif val == 1:
            break
        elif val == 2:
            x += data[i]
            y += data[i + 1]
            i += 2
        else:
            if bits == 8:
                for k in range(val):
                    if x < w:
                        out[y, x] = data[i + k]
                    x += 1
                i += val + (val & 1)
            else:
                nbytes = (val + 1) // 2
                for k in range(val):
                    b = data[i + k // 2]
                    if x < w:
                        out[y, x] = (b >> 4) if k % 2 == 0 else (b & 15)
                    x += 1
                i += nbytes + (nbytes & 1)
    return out



def decode_dib(dib: bytes) -> Image.Image:
    """BITMAP kaynağını (BITMAPINFOHEADER + piksel) RGBA görüntüye çevirir."""
    hsize, w, h, planes, bpp, comp = struct.unpack_from("<IiiHHI", dib, 0)
    clr_used = struct.unpack_from("<I", dib, 32)[0]
    bottom_up = h > 0
    h = abs(h)
    off = hsize
    palette = None
    if bpp <= 8:
        n = clr_used or (1 << bpp)
        pal = np.frombuffer(dib, np.uint8, n * 4, off).reshape(n, 4)
        palette = pal[:, [2, 1, 0]]
        off += n * 4
    elif comp == 3:  # BI_BITFIELDS
        off += 12
    if comp in (1, 2):   # BI_RLE8 / BI_RLE4
        idx = _rle(dib[off:], w, h, 8 if comp == 1 else 4)
        rgba = np.dstack([palette[idx], np.full((h, w), 255, np.uint8)])
        if bottom_up:
            rgba = rgba[::-1]
        return Image.fromarray(np.ascontiguousarray(rgba), "RGBA"), bpp
    stride = ((w * bpp + 31) // 32) * 4
    raw = np.frombuffer(dib, np.uint8, stride * h, off).reshape(h, stride)
    if bpp == 32:
        px = raw[:, :w * 4].reshape(h, w, 4)
        rgba = px[:, :, [2, 1, 0, 3]].copy()
    elif bpp == 24:
        px = raw[:, :w * 3].reshape(h, w, 3)
        rgba = np.dstack([px[:, :, [2, 1, 0]], np.full((h, w), 255, np.uint8)])
    elif bpp == 8:
        idx = raw[:, :w]
        rgba = np.dstack([palette[idx], np.full((h, w), 255, np.uint8)])
    elif bpp == 4:
        b = raw[:, :(w + 1) // 2]
        idx = np.empty((h, b.shape[1] * 2), np.uint8)
        idx[:, 0::2] = b >> 4
        idx[:, 1::2] = b & 15
        idx = idx[:, :w]
        rgba = np.dstack([palette[idx], np.full((h, w), 255, np.uint8)])
    elif bpp == 1:
        bits = np.unpackbits(raw, axis=1)[:, :w]
        rgba = np.dstack([palette[bits], np.full((h, w), 255, np.uint8)])
    else:
        raise ValueError(f"{bpp} bpp desteklenmiyor")
    if bottom_up:
        rgba = rgba[::-1]
    return Image.fromarray(np.ascontiguousarray(rgba), "RGBA"), bpp


