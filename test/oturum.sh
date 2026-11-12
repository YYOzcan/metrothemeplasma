#!/bin/bash
# İç içe, başsız tam Metro oturumu (KWin + plasmashell + metro-kabuk), gerçek yapılandırmadan yalıtılmış.
#   bash test/oturum.sh <çıktı dizini> "<komut; komut; ...>"
# komutlar: foto | bekle <sn> | calistir <program...> | kabuk <DBus yöntemi [arg]> | sh <kabuk komutu>
set -u
CIKTI="$1"; KOMUTLAR="$2"
mkdir -p "$CIKTI"
export XDG_RUNTIME_DIR=/run/user/$(id -u)/mt
rm -rf "$XDG_RUNTIME_DIR"; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY DISPLAY
T=/tmp/claude-$(id -u)/metro-oturum
rm -rf "$T"; mkdir -p "$T/config" "$T/state" "$T/cache"
export XDG_CONFIG_HOME="$T/config" XDG_STATE_HOME="$T/state" XDG_CACHE_HOME="$T/cache"
cp -r "$HOME/.config/metrothemeplasma" "$XDG_CONFIG_HOME/" 2>/dev/null
mkdir -p "$XDG_CONFIG_HOME/Kvantum"; cp -r "$HOME/.config/Kvantum/Metro" "$XDG_CONFIG_HOME/Kvantum/"
export QT_FORCE_STDERR_LOGGING=1
export PLASMA_DEFAULT_SHELL=io.github.yyozcan.metroshell METROTHEMEPLASMA_SESSION=1
export XDG_CONFIG_DIRS="$HOME/.local/share/metrothemeplasma/xdg:/etc/xdg"
export XDG_DATA_DIRS="$HOME/.local/share/metrothemeplasma/data:/usr/local/share:/usr/share"
export FONTCONFIG_FILE="$HOME/.local/share/metrothemeplasma/fonts.conf"
export XDG_CURRENT_DESKTOP=KDE XDG_SESSION_TYPE=wayland KDE_FULL_SESSION=true KDE_SESSION_VERSION=6
export QT_QPA_PLATFORMTHEME=kde
export QML_IMPORT_PATH="$HOME/.local/share/metrothemeplasma/qml"
"$HOME/.local/bin/metro-profil" metro > "$CIKTI/profil.log" 2>&1
dbus-run-session -- bash -c "
  kwin_wayland --virtual --width 1920 --height 1080 --socket mt-0 --no-lockscreen >\"$CIKTI/kwin.log\" 2>&1 &
  for i in \$(seq 50); do [ -S \"$XDG_RUNTIME_DIR/mt-0\" ] && break; sleep 0.1; done
  export WAYLAND_DISPLAY=mt-0 QT_QPA_PLATFORM=wayland
  kbuildsycoca6 >/dev/null 2>&1
  /usr/lib/kactivitymanagerd >/dev/null 2>&1 &
  sleep 1
  plasmashell >\"$CIKTI/plasmashell.log\" 2>&1 &
  sleep 5
  \"$HOME/.local/bin/metro-kabuk\" >\"$CIKTI/kabuk.log\" 2>&1 &
  sleep 2
  IFS=';' read -ra K <<< \"$KOMUTLAR\"
  n=0
  for k in \"\${K[@]}\"; do
    k=\$(echo \$k)
    [ -z \"\$k\" ] && continue
    case \"\$k\" in
      foto*) n=\$((n+1)); sleep 1.5; spectacle -b -n -f -o \"$CIKTI/\$n.png\" >/dev/null 2>&1 ;;
      bekle*) sleep \${k#bekle } ;;
      calistir*) \${k#calistir } >>\"$CIKTI/uygulama.log\" 2>&1 & ;;
      kabuk*) qdbus6 io.github.yyozcan.MetroKabuk /Kabuk io.github.yyozcan.MetroKabuk.\${k#kabuk } >/dev/null 2>&1 || echo \"dbus hata: \$k\" >> \"$CIKTI/kabuk.log\" ;;
      sh*) bash -c \"\${k#sh }\" >>\"$CIKTI/sh.log\" 2>&1 ;;
    esac
  done
  kill \$(jobs -p) 2>/dev/null
" > "$CIKTI/oturum.log" 2>&1
