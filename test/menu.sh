#!/bin/bash
# Kvantum Metro menü sınaması: verilen Qt programını iç içe KWin'de Metro stili ve simgeleriyle çalıştırır
#   bash test/menu.sh <çıktı dizini> <program> [bekleme]
set -u
KOK="$(cd "$(dirname "$0")/.." && pwd)"
CIKTI="$1"; PROG="$2"; BEKLE="${3:-3}"
mkdir -p "$CIKTI"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mtmenu
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY DISPLAY
TCFG=/tmp/claude-$(id -u)/menu-cfg; rm -rf "$TCFG"; mkdir -p "$TCFG/Kvantum"
cp -r "$HOME/.config/Kvantum/Metro" "$TCFG/Kvantum/"; printf '[General]\ntheme=Metro\n' > "$TCFG/Kvantum/kvantum.kvconfig"
printf '[Icons]\nTheme=Windows 8.1\n[General]\nColorScheme=Metro\nfont=Segoe UI,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\nmenuFont=Segoe UI,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\n[KDE]\nwidgetStyle=metro\n' > "$TCFG/kdeglobals"
export XDG_CONFIG_HOME="$TCFG" FONTCONFIG_FILE="$HOME/.local/share/metrothemeplasma/fonts.conf" QT_STYLE_OVERRIDE=metro QT_PLUGIN_PATH="$HOME/.local/share/metrothemeplasma/eklenti" QT_QPA_PLATFORMTHEME=kde
dbus-run-session -- bash -c "
  kwin_wayland --virtual --width 1280 --height 800 --socket mtmenu-0 --no-lockscreen >\"$CIKTI/kwin.log\" 2>&1 &
  for i in \$(seq 50); do [ -S \"$XDG_RUNTIME_DIR/mtmenu-0\" ] && break; sleep 0.1; done
  WAYLAND_DISPLAY=mtmenu-0 QT_QPA_PLATFORM=wayland \"$PROG\" >\"$CIKTI/prog.log\" 2>&1 &
  sleep $BEKLE
  WAYLAND_DISPLAY=mtmenu-0 spectacle -b -n -f -o \"$CIKTI/1.png\" >/dev/null 2>&1
  kill \$(jobs -p) 2>/dev/null
" > "$CIKTI/oturum.log" 2>&1
