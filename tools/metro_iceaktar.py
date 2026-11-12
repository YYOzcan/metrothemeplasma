#!/usr/bin/env python3
"""Kendi Windows 8.1 kopyandan (ISO veya install.wim) MetroThemePlasma'nın kullandığı dosyaları çıkarır.

    python3 -I tools/metro_iceaktar.py <Windows 8.1 ISO | install.wim> [hedef]

Hedef varsayılanı ~/.local/share/metrothemeplasma/win — dosyalar Windows'taki yollarıyla
(Windows/System32/twinui.dll ...) saklanır. Depoya hiçbir Microsoft dosyası girmez; bütün
görseller kurulumda bu dizinden üretilir.

Ayrıca bootres.dll içindeki gömülü WIM (açılış logosu winlogo*.bmp) Boot/ altına açılır.
"""
import os
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from peres import PEResources  # noqa: E402

# install.wim içinden alınacak yollar (7z joker karakterleri)
YOLLAR = [
    # görsel stil, temalar
    "Windows/Resources/Themes/aero.theme",
    "Windows/Resources/Themes/theme1.theme",
    "Windows/Resources/Themes/theme2.theme",
    "Windows/Resources/Themes/aero/aero.msstyles",
    "Windows/Resources/Themes/aero/aerolite.msstyles",
    "Windows/Resources/Themes/aero/tr-TR/*",
    "Windows/Resources/Themes/aero/Shell/*",
    # kabuk: Başlangıç ekranı, tılsımlar, oturum açma, simgeler
    "Windows/System32/twinui.dll",
    "Windows/System32/twinui.appcore.dll",
    "Windows/System32/authui.dll",
    "Windows/System32/imageres.dll",
    "Windows/System32/shell32.dll",
    "Windows/System32/themeui.dll",
    "Windows/System32/bootux.dll",
    "Windows/System32/Windows.UI.Immersive.dll",
    "Windows/System32/Windows.UI.Search.dll",
    "Windows/System32/ExplorerFrame.dll",
    # Windows Hakkında (linver): sürüm marka görseli; Aygıt Yöneticisi simgeleri
    "Windows/Branding/Basebrd/basebrd.dll",
    "Windows/Branding/Basebrd/tr-TR/*",
    "Windows/System32/setupapi.dll",
    "Windows/System32/devmgr.dll",
    "Windows/System32/pnidui.dll",
    "Windows/System32/SndVolSSO.dll",
    "Windows/System32/stobject.dll",
    "Windows/System32/batmeter.dll",
    "Windows/System32/ActionCenter.dll",
    "Windows/System32/timedate.cpl",
    "Windows/System32/shutdownux.dll",
    "Windows/System32/logoncontroller.dll",
    "Windows/System32/netshell.dll",
    "Windows/System32/wmploc.DLL",
    "Windows/System32/mmres.dll",
    "Windows/System32/DDORes.dll",
    "Windows/System32/accessibilitycpl.dll",
    "Windows/System32/werconcpl.dll",
    "Windows/System32/display.dll",
    "Windows/System32/main.cpl",
    "Windows/System32/mmsys.cpl",
    "Windows/System32/inetcpl.cpl",
    "Windows/System32/sysdm.cpl",
    "Windows/System32/appwiz.cpl",
    "Windows/System32/powercpl.dll",
    "Windows/System32/fontext.dll",
    "Windows/System32/zipfldr.dll",
    "Windows/System32/user32.dll",
    "Windows/System32/comres.dll",
    "Windows/System32/setupapi.dll",
    "Windows/System32/dsuiext.dll",
    "Windows/System32/mstscax.dll",
    "Windows/System32/wpdshext.dll",
    "Windows/System32/Taskmgr.exe",
    "Windows/System32/notepad.exe",
    "Windows/System32/calc.exe",
    "Windows/System32/mspaint.exe",
    "Windows/System32/cmd.exe",
    "Windows/System32/control.exe",
    "Windows/System32/SnippingTool.exe",
    "Windows/System32/mspaint.exe",
    "Windows/System32/magnify.exe",
    "Windows/System32/osk.exe",
    "Windows/System32/narrator.exe",
    "Windows/System32/charmap.exe",
    "Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
    "Windows/System32/xpsrchvw.exe",
    "Windows/System32/StikyNot.exe",
    "Windows/System32/SoundRecorder.exe",
    "Windows/System32/mstsc.exe",
    "Windows/System32/perfmon.exe",
    "Windows/System32/resmon.exe",
    "Windows/System32/eventvwr.exe",
    "Windows/System32/msinfo32.exe",
    "Windows/System32/regedt32.exe",
    "Windows/regedit.exe",
    "Windows/explorer.exe",
    "Windows/HelpPane.exe",
    "Windows/write.exe",
    "Program Files/Windows Media Player/wmplayer.exe",
    "Program Files/Internet Explorer/iexplore.exe",
    "Program Files/Windows NT/Accessories/wordpad.exe",
    # Türkçe metinler (.mui)
    "Windows/System32/tr-TR/*",
    "Windows/tr-TR/*",
    "Windows/SystemResources/*",
    "Windows/ImmersiveControlPanel/*",
    # açılış
    "Windows/Boot/Resources/bootres.dll",
    "Windows/Boot/Fonts/*",
    # duvar kağıtları, kilit ekranı, sesler, imleçler, yazı tipleri, hesap resimleri
    "Windows/Web/*",
    "Windows/Media/*",
    "Windows/Cursors/*",
    "Windows/Fonts/segoe*.ttf",
    "Windows/Fonts/segui*.ttf",
    "Windows/Fonts/consola*.ttf",
    "Windows/Fonts/calibri*.ttf",
    "Windows/Fonts/tahoma*.ttf",
    "ProgramData/Microsoft/User Account Pictures/*",
]


def yedi_zip():
    for ad in ("7z", "7zz", "7za"):
        if shutil.which(ad):
            return ad
    sys.exit("7z bulunamadı (pacman -S 7zip)")


def wim_bul(kaynak, gecici):
    kaynak = Path(kaynak)
    if kaynak.suffix.lower() in (".wim", ".esd"):
        return kaynak
    print("  ISO'dan install.wim çıkarılıyor (~3 GB, bir dakika sürebilir)")
    for ad in ("sources/install.wim", "sources/install.esd"):
        r = subprocess.run([yedi_zip(), "e", "-y", f"-o{gecici}", str(kaynak), ad],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        p = Path(gecici) / Path(ad).name
        if r.returncode == 0 and p.exists():
            return p
    sys.exit("ISO içinde sources/install.wim yok")


def bootres_ac(hedef):
    """bootres.dll RCDATA/1 içindeki WIM'i (winlogo1..5.bmp) Boot/ altına aç."""
    dll = hedef / "Windows/Boot/Resources/bootres.dll"
    if not dll.exists():
        return
    veri = PEResources(dll.read_bytes()).get("RCDATA", 1)
    if not veri or veri[:4] != b"MSWI":
        return
    with tempfile.TemporaryDirectory() as t:
        w = Path(t) / "bootres.wim"
        w.write_bytes(veri)
        cik = hedef / "Boot"
        cik.mkdir(exist_ok=True)
        subprocess.run([yedi_zip(), "x", "-y", f"-o{cik}", str(w)], stdout=subprocess.DEVNULL, check=True)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    hedef = Path(sys.argv[2] if len(sys.argv) > 2 else
                 Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "metrothemeplasma/win")
    hedef.mkdir(parents=True, exist_ok=True)
    onbellek = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    onbellek.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=onbellek, prefix="metro-iso-") as gecici:
        wim = wim_bul(sys.argv[1], gecici)
        print(f"  dosyalar çıkarılıyor -> {hedef}")
        # 7z bulunamayan yollar için hata verir; her şey yine de çıkarılır
        subprocess.run([yedi_zip(), "x", "-y", f"-o{hedef}", str(wim)] + YOLLAR,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if not (hedef / "Windows/Resources/Themes/aero/aero.msstyles").exists():
        sys.exit("aero.msstyles çıkarılamadı: bu bir Windows 8.1 kurulum kalıbı mı?")
    bootres_ac(hedef)
    # sürüm denetimi (6.3 = Windows 8.1)
    print("  tamam:", sum(1 for _ in hedef.rglob("*") if _.is_file()), "dosya")


if __name__ == "__main__":
    main()
