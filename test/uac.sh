#!/bin/bash
# UAC diyaloğunun görünümü (polkit'e dokunmaz): bash test/uac.sh <çıktı> [bilinmeyen] [ayrinti]
set -u
KOK="$(cd "$(dirname "$0")/.." && pwd)"
CIKTI="$1"; shift
mkdir -p "$CIKTI"
T=/tmp/claude-$(id -u)/uac-onizleme; rm -rf "$T"; mkdir -p "$T"
cp -r "$KOK/test/uac/." "$T/"; cp "$KOK/uac/qml/MetroUac.qml" "$T/"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mtuac
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY DISPLAY
export FONTCONFIG_FILE="$KOK/session/metro-fonts.conf"
dbus-run-session -- bash -c "
  kwin_wayland --virtual --width 1280 --height 800 --socket mtuac-0 --no-lockscreen >\"$CIKTI/kwin.log\" 2>&1 &
  for i in \$(seq 50); do [ -S \"$XDG_RUNTIME_DIR/mtuac-0\" ] && break; sleep 0.1; done
  export WAYLAND_DISPLAY=mtuac-0 QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME=kde
  qml6 -I \"$T\" \"$T/Onizleme.qml\" -- $* >\"$CIKTI/qml.log\" 2>&1 &
  sleep 3
  spectacle -b -n -f -o \"$CIKTI/1.png\" >/dev/null 2>&1
  kill \$(jobs -p) 2>/dev/null
" > "$CIKTI/oturum.log" 2>&1
