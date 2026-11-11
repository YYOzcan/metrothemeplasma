#!/bin/bash
# İç içe, başsız KWin oturumunda metro-kabuk testi.
#   bash test/ic-ice.sh <çıktı dizini> "<dbus komutları; ...>" [bekleme]
# Örnek: bash test/ic-ice.sh /tmp/x "BaslangicAc" 
set -u
KOK="$(cd "$(dirname "$0")/.." && pwd)"
CIKTI="$1"; KOMUTLAR="$2"; BEKLE="${3:-2.5}"
mkdir -p "$CIKTI"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mt
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
unset FONTCONFIG_FILE WAYLAND_DISPLAY DISPLAY
export QT_FORCE_STDERR_LOGGING=1
export FONTCONFIG_FILE="$KOK/session/metro-fonts.conf"
dbus-run-session -- bash -c "
  kwin_wayland --virtual --width 1920 --height 1080 --socket mt-0 --no-lockscreen >\"$CIKTI/kwin.log\" 2>&1 &
  for i in \$(seq 50); do [ -S \"$XDG_RUNTIME_DIR/mt-0\" ] && break; sleep 0.1; done
  export WAYLAND_DISPLAY=mt-0 QT_QPA_PLATFORM=wayland
  METRO_QML=\"$KOK/kabuk/qml\" \"$KOK/build/kabuk/metro-kabuk\" >\"$CIKTI/kabuk.log\" 2>&1 &
  sleep 2.5
  IFS=';' read -ra K <<< \"$KOMUTLAR\"
  n=0
  for k in \"\${K[@]}\"; do
    k=\$(echo \$k)
    [ -z \"\$k\" ] && continue
    if [[ \"\$k\" == foto* ]]; then
      n=\$((n+1)); sleep $BEKLE
      spectacle -b -n -f -o \"$CIKTI/\$n.png\" >/dev/null 2>&1
    elif [[ \"\$k\" == bekle* ]]; then sleep \${k#bekle }
    elif [[ \"\$k\" == tus* ]]; then :
    else
      qdbus6 io.github.yyozcan.MetroKabuk /Kabuk io.github.yyozcan.MetroKabuk.\$k >/dev/null 2>&1 || echo \"dbus hata: \$k\" >> \"$CIKTI/kabuk.log\"
    fi
  done
  kill %2 %1 2>/dev/null
" > "$CIKTI/oturum.log" 2>&1
