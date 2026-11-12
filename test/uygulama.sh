#!/bin/bash
# İç içe, başsız KWin'de bir Metro uygulamasını sına (gerçek oturuma dokunmaz).
#   bash test/uygulama.sh <çıktı dizini> <uygulama adı> "<bekle N; foto; tus <xdotool tuşu yok: wtype> ...>"
set -u
KOK="$(cd "$(dirname "$0")/.." && pwd)"
CIKTI="$1"; AD="$2"; KOMUTLAR="$3"
mkdir -p "$CIKTI"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mtu
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY DISPLAY
export QT_FORCE_STDERR_LOGGING=1 FONTCONFIG_FILE="$KOK/session/metro-fonts.conf"
dbus-run-session -- bash -c "
  kwin_wayland --virtual --width 1920 --height 1080 --socket mtu-0 --no-lockscreen >\"$CIKTI/kwin.log\" 2>&1 &
  for i in \$(seq 50); do [ -S \"$XDG_RUNTIME_DIR/mtu-0\" ] && break; sleep 0.1; done
  export WAYLAND_DISPLAY=mtu-0 QT_QPA_PLATFORM=wayland
  METRO_UYGULAMA_QML=\"$KOK/kabuk/uygulamalar\" \"$KOK/build/kabuk/metro-uygulama\" $AD >\"$CIKTI/uygulama.log\" 2>&1 &
  IFS=';' read -ra K <<< \"$KOMUTLAR\"
  n=0
  for k in \"\${K[@]}\"; do
    k=\$(echo \$k)
    [ -z \"\$k\" ] && continue
    case \"\$k\" in
      foto*) n=\$((n+1)); spectacle -b -n -f -o \"$CIKTI/\$n.png\" >/dev/null 2>&1 ;;
      bekle*) sleep \${k#bekle } ;;
    esac
  done
  kill \$(jobs -p) 2>/dev/null
" > "$CIKTI/oturum.log" 2>&1
