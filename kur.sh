#!/usr/bin/env bash
# MetroThemePlasma kurulum betiği — Windows 8.1 deneyimi, KDE Plasma 6 üzerinde
#
#   bash kur.sh --win "/yol/Windows 8.1.iso"   kendi Windows 8.1 kopyandan dosyaları içe aktar ve kur
#   bash kur.sh                    (içe aktarılmışsa) görselleri üret + kullanıcıya kur — sudo gerekmez
#   sudo bash kur.sh --sistem      SDDM oturum girdisi, /usr/local/bin/startmetro-wayland, SDDM teması
#   sudo bash kur.sh --sddm-metro  SDDM oturum açma ekranını Windows 8.1 yap
#   sudo bash kur.sh --plymouth    açılış ekranını Windows 8.1 yap (geri: --plymouth-geri)
#   bash kur.sh --kaldir           kullanıcı dosyalarını kaldır (önceki tema geri yüklenir)
#
# Depoda Microsoft dosyası yoktur: bütün görseller kurulumda senin Windows 8.1 kopyandan üretilir.
set -euo pipefail

KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$KOK"
PY="python3 -I"

# ------------------------------------------------------------------ sistem (root) kısımları
gercek_ev() {  # sudo ile çağrıldığında asıl kullanıcının ev dizini
    if [[ -n "${SUDO_USER:-}" ]]; then getent passwd "$SUDO_USER" | cut -d: -f6; else echo "$HOME"; fi
}

if [[ "${1:-}" == "--sddm-metro" ]]; then
    [[ $EUID -eq 0 ]] || { echo "sudo bash $0 --sddm-metro" >&2; exit 1; }
    [[ -d /usr/share/sddm/themes/metrothemeplasma ]] || { echo "Önce: sudo bash $0 --sistem" >&2; exit 1; }
    mkdir -p /etc/sddm.conf.d
    # önceki temayı sakla (geri almak için)
    onceki=$(sed -n 's/^Current=//p' /etc/sddm.conf.d/*.conf 2>/dev/null | grep -v '^metrothemeplasma$' | tail -1 || true)
    [[ -n "$onceki" ]] && echo "$onceki" > /usr/share/sddm/themes/metrothemeplasma/.onceki
    printf '[Theme]\nCurrent=metrothemeplasma\n' > /etc/sddm.conf.d/zz-metrothemeplasma.conf
    echo "SDDM teması: metrothemeplasma   (geri almak: sudo rm /etc/sddm.conf.d/zz-metrothemeplasma.conf)"
    exit 0
fi

if [[ "${1:-}" == "--plymouth" || "${1:-}" == "--plymouth-geri" ]]; then
    [[ $EUID -eq 0 ]] || { echo "sudo bash $0 ${1}" >&2; exit 1; }
    T=/usr/share/plymouth/themes/metrothemeplasma
    if [[ "$1" == "--plymouth-geri" ]]; then
        onceki=$(cat "$T/.onceki" 2>/dev/null || echo bgrt)
        systemctl disable metro-boot-bekle.service 2>/dev/null || true
        rm -f /etc/systemd/system/metro-boot-bekle.service
        sed -i '/^# MetroThemePlasma$/d; /^UseSimpledrm=1$/d' /etc/plymouth/plymouthd.conf
        plymouth-set-default-theme -R "$onceki"
        rm -rf "$T" /usr/local/lib/metrothemeplasma
        echo "Plymouth teması geri alındı: $onceki"
        exit 0
    fi
    [[ -f build/plymouth/metrothemeplasma/logo-1.png ]] || { echo "Önce kullanıcı olarak: bash $0 --win <ISO>" >&2; exit 1; }
    onceki=$(plymouth-set-default-theme 2>/dev/null || true)
    [[ "$onceki" == "metrothemeplasma" ]] && onceki=$(cat "$T/.onceki" 2>/dev/null || true)
    rm -rf "$T"
    cp -r build/plymouth/metrothemeplasma "$T"
    [[ -n "$onceki" && "$onceki" != "metrothemeplasma" ]] && echo "$onceki" > "$T/.onceki"
    install -Dm755 plymouth/metro-boot-bekle /usr/local/lib/metrothemeplasma/metro-boot-bekle
    install -Dm644 plymouth/metro-boot-bekle.service /etc/systemd/system/metro-boot-bekle.service
    systemctl daemon-reload
    systemctl enable metro-boot-bekle.service
    # Plymouth 24+ simpledrm'i asıl sürücü gelene dek yok sayar; UseSimpledrm=1 ile logo hemen çizilir
    conf=/etc/plymouth/plymouthd.conf
    grep -q '^\[Daemon\]' "$conf" 2>/dev/null || printf '[Daemon]\nTheme=metrothemeplasma\n' >> "$conf"
    if ! grep -q '^UseSimpledrm=' "$conf"; then
        sed -i '0,/^\[Daemon\]/s//[Daemon]\n# MetroThemePlasma\nUseSimpledrm=1/' "$conf"
    fi
    echo "==> initramfs yeniden oluşturuluyor (birkaç dakika sürebilir)"
    plymouth-set-default-theme -R metrothemeplasma
    echo "Plymouth: Windows 8.1 açılış ekranı. Geri almak: sudo bash $0 --plymouth-geri"
    exit 0
fi

if [[ "${1:-}" == "--sistem" ]]; then
    [[ $EUID -eq 0 ]] || { echo "Bu kısım root ister:  sudo bash $0 --sistem" >&2; exit 1; }
    EV="$(gercek_ev)"
    install -Dm755 session/startmetro-wayland /usr/local/bin/startmetro-wayland
    install -Dm644 session/metrothemeplasma.desktop /usr/share/wayland-sessions/metrothemeplasma.desktop
    T=/usr/share/sddm/themes/metrothemeplasma
    onceki=$(cat "$T/.onceki" 2>/dev/null || true)
    rm -rf "$T"
    cp -r sddm/metrothemeplasma "$T"
    [[ -n "$onceki" ]] && echo "$onceki" > "$T/.onceki"
    mkdir -p "$T/metro"
    # kendi Windows 8.1 kopyandan: kilit ekranı resmi ve varsayılan hesap resmi
    W="$EV/.local/share/metrothemeplasma"
    [[ -f "$W/win/Windows/Web/Screen/img100.jpg" ]] && cp "$W/win/Windows/Web/Screen/img100.jpg" "$T/metro/img100.jpg"
    [[ -f "$W/varlik/user-200.png" ]] && cp "$W/varlik/user-200.png" "$T/metro/user-200.png"
    # kullanıcının Başlangıç renkleri ve kilit ekranı resmi
    A="$EV/.config/metrothemeplasma/ayarlar.ini"
    if [[ -f "$A" ]]; then
        arka=$(sed -n '/^\[Renk\]/,/^\[/{s/^arkaPlan="\?\(#[0-9a-fA-F]\{6\}\)"\?$/\1/p}' "$A" | head -1)
        vurgu=$(sed -n '/^\[Renk\]/,/^\[/{s/^vurgu="\?\(#[0-9a-fA-F]\{6\}\)"\?$/\1/p}' "$A" | head -1)
        [[ -n "$arka" ]] && sed -i "s/^arkaPlan=.*/arkaPlan=$arka/" "$T/theme.conf"
        [[ -n "$vurgu" ]] && sed -i "s/^vurgu=.*/vurgu=$vurgu/" "$T/theme.conf"
    fi
    # Segoe UI (SDDM karşılayıcısı kullanıcı yazı tiplerini göremez)
    if [[ -d "$W/yazitipi" ]]; then
        mkdir -p /usr/local/share/fonts/metrothemeplasma
        cp "$W"/yazitipi/segoeui*.ttf "$W"/yazitipi/seguisym.ttf /usr/local/share/fonts/metrothemeplasma/ 2>/dev/null || true
        fc-cache -f /usr/local/share/fonts >/dev/null 2>&1 || true
    fi
    chmod -R a+rX "$T"
    echo "Oturum kuruldu: SDDM'de 'MetroThemePlasma (Wayland)' seçilebilir."
    echo "Windows 8.1 oturum açma ekranı kuruldu (etkin değil). Etkinleştirmek için:  sudo bash $0 --sddm-metro"
    exit 0
fi

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
MT="$DATA/metrothemeplasma"
WIN="$MT/win"

if [[ "${1:-}" == "--kaldir" ]]; then
    [[ -x "$BIN/metro-profil" ]] && "$BIN/metro-profil" geri || true
    systemctl --user disable --now metro-kabuk.service 2>/dev/null || true
    rm -f "$CFG/systemd/user/metro-kabuk.service" "$DATA/dbus-1/services/io.github.yyozcan.MetroKabuk.service"
    systemctl --user daemon-reload 2>/dev/null || true
    rm -rf "$DATA/aurorae/themes/Metro" "$CFG/Kvantum/Metro" "$DATA/plasma/desktoptheme/Metro" \
           "$DATA/color-schemes/Metro.colors" "$DATA"/plasma/plasmoids/io.github.yyozcan.metro* \
           "$DATA/plasma/shells/io.github.yyozcan.metroshell" "$DATA/plasma/look-and-feel/io.github.yyozcan.metro" \
           "$DATA"/wallpapers/Metro-* "$DATA/icons/Windows 8.1" "$DATA/icons/Windows 8.1 Aero" "$DATA/sounds/Windows 8.1" \
           "$DATA/kwin/tabbox/metro_alttab" "$DATA/kwin/scripts/metro_koseler" \
           "$CFG/plasma-workspace/env/metrothemeplasma.sh" \
           "$BIN"/metro-profil "$BIN"/metro-oturum "$BIN"/metro-renk "$BIN"/metro-kabuk "$MT" \
           "${XDG_STATE_HOME:-$HOME/.local/state}/metrothemeplasma" "${XDG_CACHE_HOME:-$HOME/.cache}/metrothemeplasma"
    echo "Kullanıcı dosyaları kaldırıldı (ayarlar: $CFG/metrothemeplasma duruyor). Sistem kısmı için:"
    echo "  sudo bash $0 --plymouth-geri"
    echo "  sudo rm -rf /usr/local/bin/startmetro-wayland /usr/share/wayland-sessions/metrothemeplasma.desktop \\"
    echo "              /usr/share/sddm/themes/metrothemeplasma /etc/sddm.conf.d/zz-metrothemeplasma.conf \\"
    echo "              /usr/local/share/fonts/metrothemeplasma"
    exit 0
fi

# ------------------------------------------------------------------ içe aktarma
if [[ "${1:-}" == "--win" ]]; then
    [[ -n "${2:-}" ]] || { echo "kullanım: bash $0 --win <Windows 8.1 ISO | install.wim>" >&2; exit 1; }
    echo "==> Windows 8.1 dosyaları içe aktarılıyor"
    $PY tools/metro_iceaktar.py "$2" "$WIN"
fi
[[ -f "$WIN/Windows/Resources/Themes/aero/aero.msstyles" ]] || {
    echo "Windows 8.1 dosyaları içe aktarılmamış. Önce:  bash $0 --win <Windows 8.1 ISO>" >&2; exit 1; }
MSSTYLES="$WIN/Windows/Resources/Themes/aero/aero.msstyles"

kopyala() {  # kopyala <kaynak> <hedef-dizin>
    rm -rf "$2"
    mkdir -p "$(dirname "$2")"
    cp -r "$1" "$2"
}

# ------------------------------------------------------------------ üretim
echo "==> Görseller Windows 8.1 kopyandan üretiliyor ($WIN)"
rm -rf build/varlik build/aurorae build/kvantum build/desktoptheme build/color-schemes build/icons build/sounds build/wallpapers
# renk aracı (metro-renk) üreteçleri buradan kullanır; ayarlar.ini'ye göre pencere rengi
kopyala tools "$MT/tools"
rm -rf "$MT/tools/__pycache__"
$PY tools/gen_varlik.py "$WIN" build/varlik
$PY tools/gen_desen.py "$WIN" build/varlik/desen
$PY tools/gen_aurorae.py "$MSSTYLES" build/aurorae >/dev/null
$PY tools/gen_kvantum.py "$MSSTYLES" build/kvantum >/dev/null
$PY tools/gen_desktoptheme.py "$MSSTYLES" build/desktoptheme >/dev/null
$PY tools/gen_renkler.py "$MSSTYLES" build/color-schemes/Metro.colors >/dev/null
$PY tools/gen_ikon.py "$WIN" "build/icons/Windows 8.1" >/dev/null
$PY tools/gen_imlec.py "$WIN" "build/icons/Windows 8.1 Aero" >/dev/null
$PY tools/gen_ses.py "$WIN" "build/sounds/Windows 8.1" >/dev/null
$PY tools/gen_duvar.py "$WIN" build/wallpapers >/dev/null
arka=$(sed -n '/^\[Renk\]/,/^\[/{s/^arkaPlan="\?\(#[0-9a-fA-F]\{6\}\)"\?$/\1/p}' "$CFG/metrothemeplasma/ayarlar.ini" 2>/dev/null | head -1)
$PY tools/gen_plymouth.py "$WIN" build/plymouth/metrothemeplasma "${arka:-#180053}" >/dev/null

# ------------------------------------------------------------------ metro-kabuk (Başlangıç ekranı, tılsımlar)
echo "==> metro-kabuk derleniyor"
CMAKE=/usr/bin/cmake; [[ -x $CMAKE ]] || CMAKE=cmake
$CMAKE -S kabuk -B build/kabuk -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
ninja -C build/kabuk | tail -1
install -Dm755 build/kabuk/metro-kabuk "$BIN/metro-kabuk"

echo "==> Windows 8.1 bildirim alanı (sistem tepsisi) derleniyor"
if $CMAKE -S plasma/tepsi -B build/tepsi -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && ninja -C build/tepsi >/dev/null 2>&1; then
    install -Dm755 build/tepsi/bin/io.github.yyozcan.metrotepsi.so "$MT/eklenti/plasma/applets/io.github.yyozcan.metrotepsi.so"
    rm -rf "$MT/qml/io/github/yyozcan/private/metrotepsi"; mkdir -p "$MT/qml/io/github/yyozcan/private"
    cp -r build/tepsi/bin/io/github/yyozcan/private/metrotepsi "$MT/qml/io/github/yyozcan/private/"
    kopyala plasma/tepsi/systemtray/package "$DATA/plasma/plasmoids/io.github.yyozcan.metrotepsi"
else
    echo "   (derlenemedi; Plasma'nın sistem tepsisi kullanılır)"
fi

echo "==> Windows 8 bildirimleri (Plasma uygulamacığı) derleniyor"
if $CMAKE -S plasma/bildirim -B build/bildirim -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && ninja -C build/bildirim >/dev/null 2>&1; then
    install -Dm755 build/bildirim/bin/plasma/applets/io.github.yyozcan.metrobildirim.so \
        "$MT/eklenti/plasma/applets/io.github.yyozcan.metrobildirim.so"
else
    echo "   (derlenemedi: plasma-workspace geliştirme dosyaları eksik olabilir; Plasma'nın bildirimleri kullanılır)"
fi

# ------------------------------------------------------------------ kurulum
echo "==> Kuruluyor ($DATA, $CFG)"
kopyala build/varlik "$MT/varlik"
kopyala kabuk/qml "$MT/kabuk/qml"
kopyala plasma/qml "$MT/qml"
kopyala build/aurorae/Metro "$DATA/aurorae/themes/Metro"
kopyala build/kvantum/Metro "$CFG/Kvantum/Metro"
kopyala build/desktoptheme/Metro "$DATA/plasma/desktoptheme/Metro"
install -Dm644 build/color-schemes/Metro.colors "$DATA/color-schemes/Metro.colors"
kopyala "build/icons/Windows 8.1" "$DATA/icons/Windows 8.1"
kopyala "build/icons/Windows 8.1 Aero" "$DATA/icons/Windows 8.1 Aero"
kopyala "build/sounds/Windows 8.1" "$DATA/sounds/Windows 8.1"
for w in build/wallpapers/*/; do kopyala "$w" "$DATA/wallpapers/$(basename "$w")"; done
for p in plasma/plasmoids/*/; do kopyala "$p" "$DATA/plasma/plasmoids/$(basename "$p")"; done
kopyala plasma/shells/io.github.yyozcan.metroshell "$DATA/plasma/shells/io.github.yyozcan.metroshell"
kopyala plasma/look-and-feel/io.github.yyozcan.metro "$DATA/plasma/look-and-feel/io.github.yyozcan.metro"
# görünüm-ve-his düzeni = kabuk düzeni (tek kaynak)
install -Dm644 plasma/shells/io.github.yyozcan.metroshell/contents/layout.js \
    "$DATA/plasma/look-and-feel/io.github.yyozcan.metro/contents/layouts/io.github.yyozcan.metroshell-layout.js"
# ortak QML (dönen noktalar): kilit ekranı, kapatma ekranı, açılış
for d in "$DATA/plasma/shells/io.github.yyozcan.metroshell/contents/lockscreen" \
         "$DATA/plasma/shells/io.github.yyozcan.metroshell/contents/logout" \
         "$DATA/plasma/look-and-feel/io.github.yyozcan.metro/contents/splash"; do
    cp ortak/IlerlemeHalkasi.qml "$d/"
done
kopyala kwin/tabbox/metro_alttab "$DATA/kwin/tabbox/metro_alttab"
kopyala kwin/scripts/metro_koseler "$DATA/kwin/scripts/metro_koseler"

echo "==> Segoe UI (Windows 8.1) — yalnızca Metro oturumunda"
mkdir -p "$MT/yazitipi"
cp "$WIN"/Windows/Fonts/segoeui*.ttf "$WIN"/Windows/Fonts/segui*.ttf "$MT/yazitipi/" 2>/dev/null || true
install -Dm644 session/metro-fonts.conf "$MT/fonts.conf"
FONTCONFIG_FILE="$MT/fonts.conf" fc-cache -f "$MT/yazitipi" >/dev/null 2>&1 || true

echo "==> Metro oturumu varsayılanları (XDG katmanı)"
XDGK="$MT/xdg"
rm -rf "$XDGK"; mkdir -p "$XDGK"
# metro-kabuk: systemd kullanıcı hizmeti (plasma-workspace.target; yalnızca Metro oturumunda koşar,
# çökerse yeniden başlar) + DBus etkinleştirme (Başlat düğmesi kabuk yoksa onu başlatır)
mkdir -p "$CFG/systemd/user" "$DATA/dbus-1/services"
sed "s|@BIN@|$BIN|" session/metro-kabuk.service > "$CFG/systemd/user/metro-kabuk.service"
install -Dm644 session/io.github.yyozcan.MetroKabuk.service "$DATA/dbus-1/services/io.github.yyozcan.MetroKabuk.service"
rm -f "$CFG/autostart/metro-kabuk.desktop"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable metro-kabuk.service 2>/dev/null || true
APP="$MT/data/applications"
rm -rf "$APP"; mkdir -p "$APP"
sed "s|@BIN@|$BIN|" session/metro-kabuk.desktop > "$APP/metro-kabuk.desktop"
# Dosya Gezgini: "Başlangıç ekranına sabitle" (bu veri dizini yalnızca Metro oturumunda XDG_DATA_DIRS'te)
install -Dm755 session/servicemenus/metro-baslangica-sabitle.desktop "$MT/data/kio/servicemenus/metro-baslangica-sabitle.desktop"


echo "==> Oturum yardımcıları"
install -Dm755 session/metro-profil "$BIN/metro-profil"
install -Dm755 session/metro-oturum "$BIN/metro-oturum"
install -Dm755 session/metro-renk "$BIN/metro-renk"
install -Dm644 session/metrothemeplasma-env.sh "$CFG/plasma-workspace/env/metrothemeplasma.sh"

# pencere çerçevesi rengi ([Pencere] cerceve): Alt+Tab bunu okur
"$BIN/metro-renk" uygula --sessiz || true
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma_theme_Metro* 2>/dev/null || true

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/metrothemeplasma"
mkdir -p "$STATE"
echo "$KOK" > "$STATE/kaynak"

echo
echo "Kullanıcı kurulumu tamam."
if [[ ! -f /usr/share/wayland-sessions/metrothemeplasma.desktop ]] || ! cmp -s session/startmetro-wayland /usr/local/bin/startmetro-wayland; then
    echo "Oturum girdisi için bir kez çalıştır:  sudo bash $KOK/kur.sh --sistem"
fi
echo "Sonra oturumu kapatıp SDDM'de 'MetroThemePlasma (Wayland)' seç."
