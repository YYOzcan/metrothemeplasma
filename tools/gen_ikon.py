#!/usr/bin/env python3
"""Kendi Windows 8.1 kopyandaki simgelerden "Windows 8.1" simge teması.

    python3 -I tools/gen_ikon.py <win dizini> <çıktı: .../icons/Windows 8.1>

imageres.dll / shell32.dll / explorer.exe / pnidui.dll / SndVolSSO.dll / ActionCenter.dll ...
Eksik adlar index.theme'deki Inherits zinciriyle (Windows 7 Aero → breeze → hicolor) tamamlanır.
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ikon import at_size, icon_images  # noqa: E402

BOYUTLAR = [16, 22, 24, 32, 48, 64, 96, 128, 256]
SEMBOLIK = {"status", "devices", "actions", "places"}

I = "System32/imageres.dll"
SH = "System32/shell32.dll"
EX = "explorer.exe"
PN = "System32/pnidui.dll"
SV = "System32/SndVolSSO.dll"
AC = "System32/ActionCenter.dll"

MAP = [
    # ------------------------------------------------------------- yerler
    (I, 3, "places", "folder inode-directory folder-blue folder-grey folder-yellow folder-orange folder-red folder-green folder-violet folder-black folder-brown folder-cyan folder-magenta folder-root folder-temp folder-tar folder-development folder-games folder-git folder-script"),
    (I, 4, "places", "folder-open folder-drag-accept"),
    (I, 112, "places", "folder-documents folder-text folder-txt"),
    (I, 113, "places", "folder-pictures folder-image folder-images folder-photo folder-screenshots"),
    (I, 108, "places", "folder-music folder-sound folder-audio"),
    (I, 189, "places", "folder-videos folder-video folder-movie"),
    (I, 184, "places", "folder-download folder-downloads"),
    (I, 183, "places", "user-desktop desktop folder-desktop"),
    (I, 123, "places", "user-home go-home folder-home user-identity"),
    (I, 109, "places", "computer user-home-computer system computer-symbolic"),
    (I, 25, "places", "network-workgroup folder-network network folder-remote network-server-symbolic"),
    (I, 1013, "places", "network-server server folder-publicshare folder-public"),
    (I, 1024, "places", "folder-favorites bookmarks starred favorites bookmark-new-list"),
    (I, 1023, "places", "folder-templates folder-library"),
    (I, 55, "places", "user-trash trash-empty emptytrash user-trash-symbolic"),
    (I, 54, "places", "user-trash-full trash-full"),
    (I, 1040, "places", "folder-cloud folder-onedrive"),
    (I, 1025, "places", "folder-saved-search system-search-folder"),
    (I, 1026, "places", "folder-recent document-open-recent"),
    # ------------------------------------------------------------- aygıtlar
    (I, 32, "devices", "drive-harddisk drive-harddisk-root harddisk drive-harddisk-solidstate drive-multidisk"),
    (I, 36, "devices", "drive-harddisk-system"),
    (I, 30, "devices", "drive-removable-media drive-removable-media-usb drive-removable-media-usb-pendrive media-flash media-flash-sd-mmc media-flash-memory-stick"),
    (I, 56, "devices", "drive-optical media-optical drive-cdrom media-optical-data media-optical-dvd media-optical-dvd-video"),
    (I, 61, "devices", "media-optical-audio media-optical-cd-audio"),
    (I, 33, "devices", "folder-remote-smb drive-harddisk-network network-drive"),
    (I, 51, "devices", "printer printer-network"),
    (I, 57, "devices", "camera-photo camera"),
    (I, 46, "devices", "camera-video camera-web"),
    (I, 47, "devices", "phone smartphone"),
    (I, 95, "devices", "scanner"),
    (I, 34, "devices", "cpu computer-chip memory"),
    ("System32/main.cpl", 100, "devices", "input-mouse preferences-desktop-mouse"),
    ("System32/main.cpl", 200, "devices", "input-keyboard preferences-desktop-keyboard"),
    ("System32/mmsys.cpl", 3004, "devices", "audio-card audio-speakers audio-headphones"),
    (I, 101, "devices", "video-display preferences-desktop-display display"),
    (I, 1008, "devices", "computer-laptop"),
    # ------------------------------------------------------------- dosya türleri
    (I, 2, "mimetypes", "unknown application-octet-stream text-x-generic-template application-x-zerosize"),
    (I, 102, "mimetypes", "text-x-generic text-plain text-x-log text-x-readme text-x-changelog text-markdown text-x-csrc text-x-c++src text-x-chdr text-x-python text-x-java text-css text-x-makefile application-json application-xml text-xml application-x-yaml application-toml"),
    (I, 15, "mimetypes", "application-x-executable application-x-ms-dos-executable application-x-msdownload application-x-sharedlib application-x-desktop application-x-appimage exec application-x-shellscript text-x-script"),
    (I, 133, "mimetypes", "video-x-generic video-mp4 video-x-matroska video-webm video-x-msvideo video-mpeg video-quicktime"),
    (I, 131, "mimetypes", "audio-x-generic audio-mpeg audio-x-wav audio-x-vorbis+ogg audio-flac audio-x-flac audio-mp4 audio-x-mpegurl"),
    (I, 70, "mimetypes", "image-x-generic image-png image-jpeg image-bmp image-gif image-tiff image-webp image-x-icon image-svg+xml image-x-xcf image-avif"),
    ("System32/zipfldr.dll", 101, "mimetypes", "application-zip application-x-archive package-x-generic application-x-compressed-tar application-x-7z-compressed application-x-rar application-x-tar application-x-bzip-compressed-tar application-x-xz-compressed-tar application-gzip application-x-zstd-compressed-tar application-x-zip"),
    ("System32/fontext.dll", 410, "mimetypes", "font-x-generic application-x-font-ttf font-ttf font-otf application-x-font-otf"),
    ("Program Files/Windows NT/Accessories/wordpad.exe", 128, "mimetypes", "application-rtf text-rtf x-office-document application-msword application-vnd.oasis.opendocument.text application-vnd.openxmlformats-officedocument.wordprocessingml.document"),
    ("Program Files/Internet Explorer/iexplore.exe", 32529, "mimetypes", "text-html application-xhtml+xml"),
    # ------------------------------------------------------------- uygulamalar
    (EX, "ICO_MYCOMPUTER", "apps", "system-file-manager org.kde.dolphin dolphin file-manager"),
    ("System32/cmd.exe", "IDI_APPICON", "apps", "utilities-terminal org.kde.konsole konsole terminal"),
    ("System32/notepad.exe", 2, "apps", "accessories-text-editor org.kde.kwrite kwrite text-editor"),
    ("System32/calc.exe", 234, "apps", "accessories-calculator org.kde.kcalc kcalc calc"),
    ("System32/control.exe", 101, "apps", "preferences-system systemsettings preferences-desktop org.kde.systemsettings"),
    ("System32/Taskmgr.exe", 30651, "apps", "utilities-system-monitor org.kde.plasma-systemmonitor ksysguard plasma-systemmonitor"),
    ("Program Files/Internet Explorer/iexplore.exe", 7, "apps", "internet-web-browser web-browser"),
    ("Program Files/Windows Media Player/wmplayer.exe", "IDR_MAINFRAME", "apps", "multimedia-player applications-multimedia media-player"),
    ("System32/SnippingTool.exe", 165, "apps", "org.kde.spectacle spectacle applets-screenshooter accessories-screenshot"),
    ("System32/mspaint.exe", 2, "apps", "org.kde.kolourpaint kolourpaint applications-graphics"),
    ("System32/charmap.exe", 111, "apps", "accessories-character-map org.kde.kcharselect kcharselect"),
    ("HelpPane.exe", 107, "apps", "help-browser org.kde.khelpcenter khelpcenter help-contents"),
    (I, 27, "apps", "preferences-system-windows preferences-desktop-theme"),
    # ------------------------------------------------------------- görev çubuğu bildirim alanı (beyaz, Windows 8)
    (PN, 3026, "status", "network-wireless-100 network-wireless-connected-100 network-wireless-signal-excellent network-wireless"),
    (PN, 3025, "status", "network-wireless-80 network-wireless-connected-75 network-wireless-signal-good"),
    (PN, 3024, "status", "network-wireless-60 network-wireless-connected-50 network-wireless-signal-ok"),
    (PN, 3023, "status", "network-wireless-40 network-wireless-20 network-wireless-connected-25 network-wireless-signal-low"),
    (PN, 3022, "status", "network-wireless-0 network-wireless-connected-00 network-wireless-signal-none"),
    (PN, 3021, "status", "network-wireless-disconnected network-wireless-offline network-wireless-available"),
    (PN, 3048, "status", "network-wired network-wired-activated network-connect network-transmit-receive network-idle"),
    (PN, 3051, "status", "network-wired-disconnected network-offline network-disconnect network-wired-unavailable network-limited network-error"),
    (PN, 3300, "status", "network-flightmode-on airplane-mode"),
    (SV, 124, "status", "audio-volume-high audio-volume-high-danger audio-volume-high-warning audio-ready"),
    (SV, 123, "status", "audio-volume-medium"),
    (SV, 122, "status", "audio-volume-low"),
    (SV, 121, "status", "audio-volume-low-zero audio-volume-zero"),
    (SV, 120, "status", "audio-volume-muted audio-off"),
    (AC, 5, "status", "notifications notification-inactive notification-empty preferences-desktop-notification-bell"),
    (AC, 6, "status", "notification-active notification-new notifications-new"),
    (AC, 8, "status", "notifications-disabled notification-disabled"),
]


def main(win, cikti):
    win, cikti = Path(win), Path(cikti)
    if cikti.exists():
        import shutil
        shutil.rmtree(cikti)
    onbellek = {}
    baglamlar = set()
    yazilan = 0
    for dosya, kimlik, baglam, adlar in MAP:
        yol = win / dosya if (win / dosya).exists() else win / "Windows" / dosya
        if not yol.exists():
            continue
        if yol not in onbellek:
            try:
                onbellek[yol] = icon_images(yol.read_bytes())
            except Exception:
                onbellek[yol] = {}
        gruplar = onbellek[yol]
        g = gruplar.get(kimlik)
        if not g:
            continue
        for b in BOYUTLAR:
            im = at_size(g, b)
            d = cikti / f"{b}x{b}" / baglam
            d.mkdir(parents=True, exist_ok=True)
            baglamlar.add(f"{b}x{b}/{baglam}")
            for ad in adlar.split():
                im.save(d / f"{ad}.png")
                yazilan += 1
                if baglam in SEMBOLIK and not ad.endswith("-symbolic"):
                    im.save(d / f"{ad}-symbolic.png")
    # Başlat logosu (twinui): menülerde görünsün diye Windows mavisi
    logo = win.parent / "varlik/baslat-64.png"
    if not logo.exists():
        logo = Path(__file__).resolve().parent.parent / "build/varlik/baslat-64.png"
    if logo.exists():
        beyaz = Image.open(logo).convert("RGBA")
        mavi = Image.new("RGBA", beyaz.size, (30, 116, 184, 255))
        mavi.putalpha(beyaz.getchannel("A"))
        for b in BOYUTLAR:
            d = cikti / f"{b}x{b}" / "places"
            d.mkdir(parents=True, exist_ok=True)
            baglamlar.add(f"{b}x{b}/places")
            for ad in ("start-here", "start-here-kde", "start-here-kde-plasma", "distributor-logo"):
                mavi.resize((b, b), Image.LANCZOS).save(d / f"{ad}.png")
    # Windows 8 Dosya Gezgini gezinti okları (ExplorerFrame.dll BITMAP 590: 18 px, 591: 25 px;
    # 6 dilim: devre dışı geri, devre dışı ileri, geri, ileri, onay, geçmiş). Windows 7'nin mavi
    # yuvarlak düğmeleri (miras alınan tema) yerine düz siyah oklar.
    ef = win / "Windows/System32/ExplorerFrame.dll"
    if ef.exists():
        try:
            from peres import PEResources
            import dib
            r = PEResources(ef.read_bytes())
            def serit(k):
                d = r.get("BITMAP", k)
                if d is None:
                    return None
                im = dib.decode_dib(d)
                return (im[0] if isinstance(im, tuple) else im).convert("RGBA")
            kucuk, buyuk = serit(590), serit(591)
            if kucuk is not None and buyuk is not None:
                def dilim(sr, i):
                    e = sr.height
                    return sr.crop((i * e, 0, (i + 1) * e, e))
                def boyutla(im, b):
                    out = Image.new("RGBA", (b, b))
                    if im.width >= b:
                        k = (im.width - b) // 2
                        out = im.crop((k, k, k + b, k + b))
                    else:
                        out.paste(im, ((b - im.width) // 2, (b - im.height) // 2))
                    return out
                for b in (16, 22, 24, 32):
                    kaynak = kucuk if b <= 16 else buyuk
                    d = cikti / f"{b}x{b}" / "actions"
                    d.mkdir(parents=True, exist_ok=True)
                    baglamlar.add(f"{b}x{b}/actions")
                    geri, ileri = boyutla(dilim(kaynak, 2), b), boyutla(dilim(kaynak, 3), b)
                    yukari = ileri.rotate(90)   # Windows 8 "Bir düzey yukarı" oku: aynı çizimde yukarı
                    for ad, im in (("go-up", yukari), ("go-previous", geri), ("go-next", ileri), ("go-previous-rtl", ileri),
                                   ("go-next-rtl", geri), ("go-previous-view", geri), ("go-next-view", ileri)):
                        im.save(d / f"{ad}.png")
                        im.save(d / f"{ad}-symbolic.png")
                        yazilan += 2
        except Exception as x:  # noqa: BLE001
            print("  gezinti okları atlandı:", x)
    tur = {"places": "Places", "devices": "Devices", "mimetypes": "MimeTypes", "apps": "Applications",
           "status": "Status", "actions": "Actions", "categories": "Categories"}
    dizinler = sorted(baglamlar, key=lambda x: (int(x.split("x")[0]), x))
    metin = ["[Icon Theme]", "Name=Windows 8.1", "Comment=Windows 8.1 simgeleri (kendi kopyandan)",
             "Inherits=Windows 7 Aero,breeze,hicolor", "Example=folder", "DisplayDepth=32",
             "Directories=" + ",".join(dizinler), ""]
    for dz in dizinler:
        b = int(dz.split("x")[0])
        metin += [f"[{dz}]", f"Size={b}", f"Context={tur.get(dz.split('/')[1], 'Applications')}", "Type=Fixed", ""]
    (cikti / "index.theme").write_text("\n".join(metin))
    print("simge teması ->", cikti, yazilan, "dosya")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
