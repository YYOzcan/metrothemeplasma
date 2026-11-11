#!/usr/bin/env python3
"""Windows 8.1 duvar kağıtları -> Plasma duvar kağıdı paketleri (~/.local/share/wallpapers/Metro-*).

    python3 -I tools/gen_duvar.py <win dizini> <çıktı dizini>
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mui import metinler  # noqa: E402


def paket(kaynak, hedef, ad):
    hedef = Path(hedef)
    shutil.rmtree(hedef, ignore_errors=True)
    (hedef / "contents/images").mkdir(parents=True)
    w, h = Image.open(kaynak).size
    shutil.copy(kaynak, hedef / f"contents/images/{w}x{h}{Path(kaynak).suffix}")
    im = Image.open(kaynak).convert("RGB")
    im.thumbnail((400, 250))
    im.save(hedef / "contents/screenshot.png")
    (hedef / "metadata.json").write_text(json.dumps({
        "KPlugin": {"Id": hedef.name, "Name": ad, "Name[tr]": ad, "License": "Windows 8.1 (kendi kopyanız)",
                    "Authors": [{"Name": "Microsoft"}]}}, indent=2, ensure_ascii=False))


def main(win, cikti):
    web = Path(win) / "Windows/Web/Wallpaper"
    tui = metinler("themeui.dll")
    adlar = {"Theme1": tui.get(2113) or "Çizgiler ve renkler", "Theme2": tui.get(2112) or "Çiçekler"}
    n = 0
    if (web / "Windows/img0.jpg").exists():
        paket(web / "Windows/img0.jpg", Path(cikti) / "Metro-Windows", "Windows 8.1")
        n += 1
    for tema, ad in adlar.items():
        for i, p in enumerate(sorted((web / tema).glob("img*.jpg"), key=lambda x: int(x.stem[3:])), 1):
            paket(p, Path(cikti) / f"Metro-{tema}-{i}", f"{ad} {i}")
            n += 1
    print("duvar kağıtları ->", cikti, n)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
