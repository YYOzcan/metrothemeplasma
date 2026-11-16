#!/bin/bash
# SDDM teması sınaması (gerçek SDDM'e dokunmaz): sddm-greeter test kipinde, iç içe başsız KWin'de.
#   bash test/sddm.sh <çıktı dizini> [sinama değeri: 1 | kapanis] [bekleme sn]
set -u
KOK="$(cd "$(dirname "$0")/.." && pwd)"
CIKTI="$1"; SINAMA="${2:-1}"; BEKLE="${3:-4}"
mkdir -p "$CIKTI"
T=/tmp/claude-$(id -u)/sddm-sinama; rm -rf "$T"; cp -r "$KOK/sddm/metrothemeplasma" "$T"
[ -d /usr/share/sddm/themes/metrothemeplasma/metro ] && cp -r /usr/share/sddm/themes/metrothemeplasma/metro "$T/"
sed -i '/^sinama=/d' "$T/theme.conf"; printf 'sinama=%s\n' "$SINAMA" >> "$T/theme.conf"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mtsddm
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY DISPLAY
export FONTCONFIG_FILE="$KOK/session/metro-fonts.conf"
G=$(command -v sddm-greeter-qt6 || command -v sddm-greeter)
dbus-run-session -- bash -c "
  kwin_wayland --virtual --width 1920 --height 1080 --socket mtsddm-0 --no-lockscreen >\"$CIKTI/kwin.log\" 2>&1 &
  for i in \$(seq 50); do [ -S \"$XDG_RUNTIME_DIR/mtsddm-0\" ] && break; sleep 0.1; done
  WAYLAND_DISPLAY=mtsddm-0 QT_QPA_PLATFORM=wayland $G --test-mode --theme \"$T\" >\"$CIKTI/greeter.log\" 2>&1 &
  sleep $BEKLE
  WAYLAND_DISPLAY=mtsddm-0 spectacle -b -n -f -o \"$CIKTI/1.png\" >/dev/null 2>&1
  kill \$(jobs -p) 2>/dev/null
" > "$CIKTI/oturum.log" 2>&1
