#!/bin/bash
# Kilit ekranını iç içe KWin'de sına: bash test/kilit.sh <çıktı dizini>
S="$1"; mkdir -p "$S"
L="$(cd "$(dirname "$0")/.." && pwd)/plasma/shells/io.github.yyozcan.metroshell/contents/lockscreen"
cp "$(dirname "$0")/../ortak/IlerlemeHalkasi.qml" "$L/"
# kscreenlocker bağlam özelliklerini kök öğeye yerleştirilmiş bir kopya (sınama)
T="$S/kilit"; rm -rf "$T"; cp -r "$L" "$T"
python3 - "$T/MetroKilit.qml" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
ek = """    id: ui
    property string kscreenlocker_userName: "Yiğit Yüksel"
    property string kscreenlocker_userImage: ""
    property QtObject authenticator: QtObject {
        property bool unlocked: false
        property bool pamTimeout: false
        property bool hadPrompt: false
        signal failed(int kind)
        signal succeeded()
        function startAuthenticating() {}
        function stopAuthenticating() {}
        function respond(p) { if (p === "dogru") succeeded(); else failed(0) }
    }
"""
s=s.replace("    id: ui\n", ek, 1)
open(p,"w").write(s)
PY
L="$T"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mt
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
export FONTCONFIG_FILE=$HOME/.local/share/metrothemeplasma/fonts.conf QT_FORCE_STDERR_LOGGING=1
unset WAYLAND_DISPLAY DISPLAY
dbus-run-session -- bash -c "
kwin_wayland --virtual --width 1920 --height 1080 --socket mt-0 --no-lockscreen >'$S/kwin.log' 2>&1 &
sleep 2; export WAYLAND_DISPLAY=mt-0 QT_QPA_PLATFORM=wayland
/usr/lib/qt6/bin/qml '$(dirname "$0")/kilit-sinama.qml' -- '$L' > '$S/qml.log' 2>&1 &
sleep 2; spectacle -b -n -f -o '$S/1.png'; sleep 1.8; spectacle -b -n -f -o '$S/2.png'; sleep 2; spectacle -b -n -f -o '$S/3.png'
kill \$(jobs -p)" >/dev/null 2>&1
