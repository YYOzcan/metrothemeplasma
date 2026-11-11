#!/usr/bin/env python3
"""Windows 8.1 "Windows Varsayılanı" ses düzeninden freedesktop ses teması "Windows 8.1".

    python3 -I tools/gen_ses.py <win dizini> <çıktı: .../sounds/Windows 8.1>

Windows 8'de varsayılan olarak başlangıç/kapanış sesi çalmaz; oturum açma sesi (Windows Logon)
yalnızca "Windows Oturum Açma" olayındadır. Küçültme/büyütme sesi yoktur.
"""
import shutil
import sys
from pathlib import Path

SESLER = {
    "service-login": "Windows Logon.wav",
    "desktop-login": "Windows Logon.wav",
    "service-logout": "Windows Logoff Sound.wav",
    "desktop-logout": "Windows Logoff Sound.wav",
    "bell": "Windows Ding.wav",
    "bell-window-system": "Windows Ding.wav",
    "bell-terminal": "Windows Ding.wav",
    "dialog-error": "Windows Critical Stop.wav",
    "dialog-error-critical": "Windows Critical Stop.wav",
    "dialog-error-serious": "Windows Critical Stop.wav",
    "dialog-warning": "Windows Exclamation.wav",
    "dialog-warning-auth": "Windows Exclamation.wav",
    "dialog-information": "Windows Background.wav",
    "dialog-question": "Windows Background.wav",
    "message": "Windows Notify System Generic.wav",
    "message-new-instant": "Windows Notify Messaging.wav",
    "message-new-email": "Windows Notify Email.wav",
    "message-highlight": "Windows Notify System Generic.wav",
    "message-sent-instant": "Windows Default.wav",
    "complete": "Windows Default.wav",
    "outcome-success": "Windows Default.wav",
    "device-added": "Windows Hardware Insert.wav",
    "device-removed": "Windows Hardware Remove.wav",
    "device-added-failure": "Windows Hardware Fail.wav",
    "battery-low": "Windows Battery Low.wav",
    "battery-caution": "Windows Battery Critical.wav",
    "power-unplug-battery-low": "Windows Battery Low.wav",
    "trash-empty": "recycle.wav",
    "network-connectivity-lost": "Windows Exclamation.wav",
    "menu-click": "Windows Navigation Start.wav",
    "phone-incoming-call": "Ring01.wav",
    "alarm-clock-elapsed": "Alarm01.wav",
    "completion-fail": "Windows Error.wav",
    "dialog-warning-popup-blocked": "Windows Pop-up Blocked.wav",
    "audio-volume-change": "Windows Background.wav",
}


def main(win, cikti):
    kaynak, cikti = Path(win) / "Windows/Media", Path(cikti)
    stereo = cikti / "stereo"
    shutil.rmtree(cikti, ignore_errors=True)
    stereo.mkdir(parents=True)
    n = 0
    for ad, dosya in SESLER.items():
        if (kaynak / dosya).exists():
            shutil.copy2(kaynak / dosya, stereo / f"{ad}.wav")
            n += 1
    (cikti / "index.theme").write_text("[Sound Theme]\nName=Windows 8.1\nName[tr]=Windows 8.1\n"
                                       "Comment=Windows 8.1 varsayılan ses düzeni (kendi kopyandan)\n"
                                       "Inherits=freedesktop\nDirectories=stereo\n\n[stereo]\nOutputProfile=stereo\n")
    print("ses teması ->", cikti, f"({n} ses)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
