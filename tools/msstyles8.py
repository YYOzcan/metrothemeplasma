"""Windows 8/8.1 .msstyles (derlenmiş VARIANT biçimi) okuyucu.

    st = MsStyles("aero.msstyles")
    st.classes                       -> ["documentation", ..., "globals", "WINDOW", ...]
    st.props("WINDOW", part, state)  -> {ad: değer}
    st.find("WINDOW")                -> {(part, state): {ad: değer}}
    st.image(id)                     -> PNG bytes (IMAGE kaynağı)
    st.imagefile("WINDOW", part, state, n=None) -> PNG bytes

Özellik kaydı: 8 adet int32 başlık (ad, tür, sınıf, parça, durum, kısa, ayrılmış, boyut),
ardından veri; kayıtlar 8 bayta hizalanır.
"""
import struct
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from peres import PEResources  # noqa: E402

# vssym32.h TMT_* adları (yalnızca kullanılanlar ve sık görülenler)
AD = {
    2: "DIBDATA", 8: "GLYPHDIBDATA",
    201: "STRING", 202: "INT", 203: "BOOL", 204: "COLOR", 205: "MARGINS", 206: "FILENAME",
    207: "SIZE", 208: "POSITION", 209: "RECT", 210: "FONT", 211: "INTLIST",
    401: "COLORSCHEMES", 402: "SIZES", 403: "CHARSET", 601: "NAME",
    1201: "CAPTIONFONT", 1202: "SMALLCAPTIONFONT", 1203: "MENUFONT", 1204: "STATUSFONT",
    1205: "MSGBOXFONT", 1206: "ICONTITLEFONT", 1401: "FLATMENUS",
    1601: "SIZINGBORDERWIDTH", 1602: "SCROLLBARWIDTH", 1603: "SCROLLBARHEIGHT",
    1604: "CAPTIONBARWIDTH", 1605: "CAPTIONBARHEIGHT", 1606: "SMCAPTIONBARWIDTH",
    1607: "SMCAPTIONBARHEIGHT", 1608: "MENUBARWIDTH", 1609: "MENUBARHEIGHT", 1610: "PADDEDBORDERWIDTH",
    1801: "MINCOLORDEPTH", 1901: "CSSNAME", 1902: "XMLNAME", 1903: "LASTUPDATED", 1904: "ALIAS",
    2001: "SCROLLBAR", 2002: "BACKGROUND", 2003: "ACTIVECAPTION", 2004: "INACTIVECAPTION",
    2005: "MENU", 2006: "WINDOW", 2007: "WINDOWFRAME", 2008: "MENUTEXT", 2009: "WINDOWTEXT",
    2010: "CAPTIONTEXT", 2011: "ACTIVEBORDER", 2012: "INACTIVEBORDER", 2013: "APPWORKSPACE",
    2014: "HIGHLIGHT", 2015: "HIGHLIGHTTEXT", 2016: "BTNFACE", 2017: "BTNSHADOW", 2018: "GRAYTEXT",
    2019: "BTNTEXT", 2020: "INACTIVECAPTIONTEXT", 2021: "BTNHIGHLIGHT", 2022: "DKSHADOW3D",
    2023: "LIGHT3D", 2024: "INFOTEXT", 2025: "INFOBK", 2026: "BUTTONALTERNATEFACE",
    2027: "HOTTRACKING", 2028: "GRADIENTACTIVECAPTION", 2029: "GRADIENTINACTIVECAPTION",
    2030: "MENUHILIGHT", 2031: "MENUBAR",
    2401: "IMAGECOUNT", 2402: "ALPHALEVEL", 2403: "BORDERSIZE", 2404: "ROUNDCORNERWIDTH",
    2405: "ROUNDCORNERHEIGHT", 2406: "GRADIENTRATIO1", 2411: "PROGRESSCHUNKSIZE",
    2412: "PROGRESSSPACESIZE", 2413: "SATURATION", 2414: "TEXTBORDERSIZE", 2415: "ALPHATHRESHOLD",
    2416: "WIDTH", 2417: "HEIGHT", 2418: "GLYPHINDEX", 2419: "TRUESIZESTRETCHMARK",
    2420: "MINDPI1", 2421: "MINDPI2", 2422: "MINDPI3", 2423: "MINDPI4", 2424: "MINDPI5",
    2425: "TEXTGLOWSIZE", 2426: "FRAMESPERSECOND", 2427: "PIXELSPERFRAME", 2428: "ANIMATIONDELAY",
    2429: "GLOWINTENSITY", 2430: "OPACITY", 2431: "COLORIZATIONCOLOR", 2432: "COLORIZATIONOPACITY",
    2433: "MINDPI6", 2434: "MINDPI7",
    2601: "GLYPHFONT",
    3001: "IMAGEFILE", 3002: "IMAGEFILE1", 3003: "IMAGEFILE2", 3004: "IMAGEFILE3",
    3005: "IMAGEFILE4", 3006: "IMAGEFILE5", 3007: "STOCKIMAGEFILE", 3008: "GLYPHIMAGEFILE",
    3009: "IMAGEFILE6", 3010: "IMAGEFILE7",
    3201: "TEXT", 3301: "CLASSICVALUE",
    3401: "OFFSET", 3402: "TEXTSHADOWOFFSET", 3403: "MINSIZE", 3404: "MINSIZE1", 3405: "MINSIZE2",
    3406: "MINSIZE3", 3407: "MINSIZE4", 3408: "MINSIZE5", 3409: "NORMALSIZE",
    3410: "MINSIZE6", 3411: "MINSIZE7",
    3601: "SIZINGMARGINS", 3602: "CONTENTMARGINS", 3603: "CAPTIONMARGINS",
    3801: "BORDERCOLOR", 3802: "FILLCOLOR", 3803: "TEXTCOLOR", 3804: "EDGELIGHTCOLOR",
    3805: "EDGEHIGHLIGHTCOLOR", 3806: "EDGESHADOWCOLOR", 3807: "EDGEDKSHADOWCOLOR",
    3808: "EDGEFILLCOLOR", 3809: "TRANSPARENTCOLOR", 3810: "GRADIENTCOLOR1", 3811: "GRADIENTCOLOR2",
    3812: "GRADIENTCOLOR3", 3813: "GRADIENTCOLOR4", 3814: "GRADIENTCOLOR5", 3815: "SHADOWCOLOR",
    3816: "GLOWCOLOR", 3817: "TEXTBORDERCOLOR", 3818: "TEXTSHADOWCOLOR", 3819: "GLYPHTEXTCOLOR",
    3820: "GLYPHTRANSPARENTCOLOR", 3821: "FILLCOLORHINT", 3822: "BORDERCOLORHINT",
    3823: "ACCENTCOLORHINT", 3824: "TEXTCOLORHINT", 3825: "HEADING1TEXTCOLOR",
    3826: "HEADING2TEXTCOLOR", 3827: "BODYTEXTCOLOR",
    4001: "BGTYPE", 4002: "BORDERTYPE", 4003: "FILLTYPE", 4004: "SIZINGTYPE", 4005: "HALIGN",
    4006: "CONTENTALIGNMENT", 4007: "VALIGN", 4008: "OFFSETTYPE", 4009: "ICONEFFECT",
    4010: "TEXTSHADOWTYPE", 4011: "IMAGELAYOUT", 4012: "GLYPHTYPE", 4013: "IMAGESELECTTYPE",
    4014: "GLYPHFONTSIZINGTYPE", 4015: "TRUESIZESCALINGTYPE",
    5001: "USERPICTURE", 5002: "DEFAULTPANESIZE", 5003: "BLENDCOLOR", 5004: "CUSTOMSPLITRECT",
    5005: "ANIMATIONBUTTONRECT", 5006: "ANIMATIONDURATION",
    5100: "IMMERSIVECOLOR",
    5128: "ANIMATIONTYPE", 5129: "ANIMATIONTIMINGFUNCTION", 5130: "ANIMATIONDURATIONMS",
    6000: "TRANSITIONDURATIONS", 7001: "SCALEDBACKGROUND",
    8000: "ATLASIMAGE", 8001: "ATLASINPUTIMAGE", 8002: "ATLASRECT",
}
# özellik türleri
TUR = {200: "ENUM", 201: "STRING", 202: "INT", 203: "BOOL", 204: "COLOR", 205: "MARGINS",
       206: "FILENAME", 207: "SIZE", 208: "POSITION", 209: "RECT", 210: "FONT", 211: "INTLIST",
       213: "DISKSTREAM", 214: "STREAM", 215: "BITMAPREF", 216: "FLOAT", 217: "FLOATLIST",
       240: "SIMPLIFIEDIMAGETYPE", 241: "HIGHCONTRASTCOLORTYPE"}


class MsStyles:
    def __init__(self, path):
        self.res = PEResources(open(path, "rb").read())
        # CMAP: sıfır sonlu UTF-16 sınıf adları, her biri 8 bayta hizalı; dizin = sınıf kimliği
        d = self.res.get("CMAP", "CMAP")
        self.classes = []
        o = 0
        while o + 1 < len(d):
            e = o
            while e + 1 < len(d) and d[e:e + 2] != b"\0\0":
                e += 2
            self.classes.append(d[o:e].decode("utf-16-le"))
            o = (e + 2 + 7) & ~7
        self.records = []
        self._parse(self.res.get("VARIANT", "NORMAL"))
        self._idx = {}
        for rec in self.records:
            self._idx.setdefault(rec["class"], []).append(rec)

    def _value(self, typ, d, short):
        try:
            return self._value2(typ, d, short)
        except struct.error:
            return short

    def _value2(self, typ, d, short):
        if typ in (202, 200, 203, 241):            # INT/ENUM/BOOL
            return struct.unpack_from("<i", d)[0] if len(d) >= 4 else short
        if typ == 204:                              # COLOR (BGR)
            v = struct.unpack_from("<I", d)[0]
            return "#%02x%02x%02x" % (v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF)
        if typ in (205, 209):                       # MARGINS/RECT
            return struct.unpack_from("<4i", d)
        if typ in (207, 208):
            return struct.unpack_from("<2i", d)
        if typ in (206, 240, 215):                  # FILENAME -> IMAGE kimliği
            return struct.unpack_from("<i", d)[0] if len(d) >= 4 else short
        if typ == 201:
            return d.decode("utf-16-le", "replace").rstrip("\0")
        if typ == 211:
            n = struct.unpack_from("<i", d)[0]
            return list(struct.unpack_from("<%di" % n, d, 4))
        if typ == 216:
            return struct.unpack_from("<f", d)[0]
        if typ == 217:
            return list(struct.unpack_from("<%df" % (len(d) // 4), d))
        if typ == 210:                              # LOGFONT kimliği (STRING tablosu)
            return struct.unpack_from("<i", d)[0] if len(d) >= 4 else short
        return d

    def _parse(self, v):
        o = 0
        n = len(v)
        while o + 32 <= n:
            name, typ, cls, part, state, short, _res, size = struct.unpack_from("<8i", v, o)
            o += 32
            if short == 0:
                d = v[o:o + size]
                o += size
            else:
                d = struct.pack("<i", short)
            o = (o + 7) & ~7
            self.records.append({"name": AD.get(name, name), "id": name, "type": typ,
                                 "class": self.classes[cls] if 0 <= cls < len(self.classes) else cls,
                                 "part": part, "state": state, "value": self._value(typ, d, short)})

    def find(self, cls):
        out = {}
        for r in self._idx.get(cls, []):
            out.setdefault((r["part"], r["state"]), {})[r["name"]] = r["value"]
        return out

    def props(self, cls, part=0, state=0, inherit=True):
        """Bir parça/durum için özellikler; inherit: durum 0 ve parça 0 değerleri altta kalır."""
        f = self.find(cls)
        out = {}
        if inherit:
            out.update(f.get((0, 0), {}))
            out.update(f.get((part, 0), {}))
        out.update(f.get((part, state), {}))
        return out

    def image(self, rid):
        d = self.res.get("IMAGE", rid)
        if d is None:
            d = self.res.get("STREAM", rid)
        return d

    def imagefile(self, cls, part=0, state=0, key="IMAGEFILE"):
        p = self.props(cls, part, state)
        rid = p.get(key)
        if rid is None and key == "IMAGEFILE":
            rid = p.get("IMAGEFILE1")
        return self.image(rid) if isinstance(rid, int) else None


if __name__ == "__main__":
    st = MsStyles(sys.argv[1])
    want = sys.argv[2] if len(sys.argv) > 2 else None
    if not want:
        names = sorted({r["class"] for r in st.records if isinstance(r["class"], str)})
        print("\n".join(names))
    else:
        for (p, s), d in sorted(st.find(want).items()):
            print(f"[{want} p={p} s={s}]")
            for k, v in d.items():
                print(f"   {k} = {v}")
