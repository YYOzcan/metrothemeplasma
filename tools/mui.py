"""Türkçe .mui dosyalarından STRINGTABLE metinleri.

    from mui import metinler
    metinler("twinui.dll")  -> {id: "metin"}
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from functools import lru_cache
from pathlib import Path

from peres import PEResources

WIN = Path(os.environ.get("METRO_WIN", Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
                          / "metrothemeplasma/win"))


def mui_yolu(ad):
    for d in ("Windows/System32/tr-TR", "Windows/tr-TR", "Windows/SystemResources"):
        for p in (WIN / d).glob("*.mui") if (WIN / d).is_dir() else []:
            if p.name.lower() == (ad + ".mui").lower():
                return p
    return None


@lru_cache(None)
def metinler(ad):
    p = mui_yolu(ad)
    if not p:
        return {}
    return PEResources(p.read_bytes()).strings()


if __name__ == "__main__":
    import re
    import sys
    ad, desen = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else ".")
    for k, v in sorted(metinler(ad).items()):
        if re.search(desen, v, re.I):
            print(k, repr(v))
