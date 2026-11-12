#!/usr/bin/env bash
# MetroThemePlasma kurulum betiği — Windows 8.1 deneyimi, KDE Plasma 6 üzerinde
#
#   bash kur.sh --win "/yol/Windows 8.1.iso"   kendi Windows 8.1 kopyandan dosyaları içe aktar ve kur
#   bash kur.sh                    (içe aktarılmışsa) görselleri üret + kullanıcıya kur — sudo gerekmez
#   sudo bash kur.sh --sistem      SDDM oturum girdisi, /usr/local/bin/startmetro-wayland, SDDM teması
#   sudo bash kur.sh --sddm-metro  SDDM oturum açma ekranını Windows 8.1 yap
#   sudo bash kur.sh --plymouth    açılış ekranını Windows 8.1 yap (geri: --plymouth-geri)
#   bash kur.sh --yukselt          Windows 8.1'e Yükseltme Yardımcısı (grafik sihirbaz; ATP'den ya da sıfırdan)
#   bash kur.sh --kaldir           kullanıcı dosyalarını kaldır (önceki tema geri yüklenir)
#
# Depoda Microsoft dosyası yoktur: bütün görseller kurulumda senin Windows 8.1 kopyandan üretilir.
set -euo pipefail

KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$KOK"
PY="python3 -I"

# ------------------------------------------------------------------ sistem (root) kısımları
# pkexec ile çağrıldıysa asıl kullanıcı (Yükseltme Yardımcısı tek UAC onayıyla root kısmını çalıştırır)
if [[ -z "${SUDO_USER:-}" && -n "${PKEXEC_UID:-}" ]]; then
    SUDO_USER=$(getent passwd "$PKEXEC_UID" | cut -d: -f1); export SUDO_USER
fi
gercek_ev() {  # sudo ile çağrıldığında asıl kullanıcının ev dizini
    if [[ -n "${SUDO_USER:-}" ]]; then getent passwd "$SUDO_USER" | cut -d: -f6; else echo "$HOME"; fi
}

# Windows 8.1'e Yükseltme Yardımcısı (AeroThemePlasma'dan ya da sıfırdan): grafik sihirbaz.
# Yalnızca sihirbazın ana programını derler; kurulumun geri kalanını sihirbaz adım adım yapar.
if [[ "${1:-}" == "--yukselt" ]]; then
    cd "$KOK"
    CMAKE=/usr/bin/cmake; [[ -x $CMAKE ]] || CMAKE=cmake
    echo "==> Yükseltme Yardımcısı hazırlanıyor"
    $CMAKE -S kabuk -B build/kabuk -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null && ninja -C build/kabuk metro-uygulama >/dev/null \
        || { echo "Derlenemedi: qt6-base, qt6-declarative, kio, layer-shell-qt, cmake ve ninja gerekli." >&2; exit 1; }
    METRO_UYGULAMA_QML="$KOK/kabuk/uygulamalar" METRO_KAYNAK="$KOK" exec build/kabuk/metro-uygulama yukseltme
fi

# Yükseltme Yardımcısı'nın root adımı (pkexec, tek onay): --yukseltme-sistem <plymouth 0|1> <sddm 0|1> <oturum 0|1>
if [[ "${1:-}" == "--yukseltme-sistem" ]]; then
    [[ $EUID -eq 0 ]] || { echo "root gerekli" >&2; exit 1; }
    cd "$KOK"
    echo "==> Oturum, oturum açma ekranı teması ve kendiliğinden güncelleme kuruluyor"
    bash "$KOK/kur.sh" --sistem || exit 1
    if [[ "${3:-0}" == 1 ]]; then echo "==> Oturum açma ekranı: Windows 8.1"; bash "$KOK/kur.sh" --sddm-metro || true; fi
    if [[ "${4:-0}" == 1 ]]; then
        echo "==> Varsayılan oturum: MetroThemePlasma"
        D=/var/lib/sddm/state.conf
        if [[ -f $D ]] && grep -q '^\[Last\]' $D; then
            if grep -q '^Session=' $D; then sed -i 's|^Session=.*|Session=/usr/share/wayland-sessions/metrothemeplasma.desktop|' $D
            else sed -i 's|^\[Last\]|[Last]\nSession=/usr/share/wayland-sessions/metrothemeplasma.desktop|' $D; fi
        else
            mkdir -p /var/lib/sddm; printf '[Last]\nSession=/usr/share/wayland-sessions/metrothemeplasma.desktop\nUser=%s\n' "$SUDO_USER" >> $D
        fi
        chown sddm:sddm $D 2>/dev/null || true
    fi
    if [[ "${2:-0}" == 1 ]]; then echo "==> Açılış ekranı (Windows logosu) kuruluyor; initramfs yeniden oluşturuluyor"; bash "$KOK/kur.sh" --plymouth || true; fi
    echo "==> Sistem kısmı tamam"
    exit 0
fi

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
        rm -f /etc/mkinitcpio.conf.d/20-metrothemeplasma-kms.conf
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
    # NVIDIA: sürücü initramfs'te değilse açılışın ortasında ekranı devralır ve açılış ekranı kesilir.
    # Erken KMS: modüller initramfs'e girer, Windows logosu ve noktalar baştan sona yerel çözünürlükte döner
    # (pipefail: grep -q erken çıkınca lspci SIGPIPE alır; çıktı önce bir değişkene)
    ekran=$(lspci 2>/dev/null || true)
    # (Türkçe yerelde büyük/küçük dönüşümü "NVIDIA"yı "nvıdıa" yapar: dönüşümsüz, lspci'nin yazımıyla)
    if [[ "$ekran" =~ (VGA|3D)[^$'\n']*NVIDIA ]] && modinfo nvidia_drm >/dev/null 2>&1; then
        printf '# MetroThemePlasma: Plymouth için NVIDIA erken KMS\nMODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)\n' \
            > /etc/mkinitcpio.conf.d/20-metrothemeplasma-kms.conf
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
    # Plasma/Qt/KDE güncellenince kendiliğinden yeniden derle ve kur (pacman kancası; ATP'ninkinden sonra çalışır)
    if [[ -d /etc/pacman.d ]]; then
        install -Dm755 session/kanca/metro-guncelle-hook /usr/local/bin/metro-guncelle-hook
        install -Dm644 session/kanca/91-metro-guncelle.hook /etc/pacman.d/hooks/91-metro-guncelle.hook
        printf '# MetroThemePlasma kaynağı ve kullanıcısı (metro-guncelle-hook)\nKAYNAK=%q\nKULLANICI=%q\n' \
            "$KOK" "${SUDO_USER:-$(stat -c %U "$KOK")}" > /etc/metrothemeplasma.conf
    fi
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
    rm -f "$CFG/systemd/user/metro-kabuk.service" "$DATA/dbus-1/services/io.github.yyozcan.MetroKabuk.service" \
          "$CFG/systemd/user/plasma-polkit-agent.service.d/zz-metrothemeplasma.conf"
    systemctl --user daemon-reload 2>/dev/null || true
    rm -rf "$DATA/aurorae/themes/Metro" "$CFG/Kvantum/Metro" "$DATA/plasma/desktoptheme/Metro" \
           "$DATA/color-schemes/Metro.colors" "$DATA"/plasma/plasmoids/io.github.yyozcan.metro* \
           "$DATA/plasma/shells/io.github.yyozcan.metroshell" "$DATA/plasma/look-and-feel/io.github.yyozcan.metro" \
           "$DATA"/wallpapers/Metro-* "$DATA/icons/Windows 8.1" "$DATA/icons/Windows 8.1 Aero" "$DATA/sounds/Windows 8.1" \
           "$DATA/kwin/tabbox/metro_alttab" "$DATA/kwin/scripts/metro_koseler" \
           "$CFG/plasma-workspace/env/metrothemeplasma.sh" \
           "$BIN"/metro-profil "$BIN"/metro-yukselt "$BIN"/metro-oturum "$BIN"/metro-renk "$BIN"/metro-kabuk "$BIN"/metro-calistir "$BIN"/metro-uygulama "$BIN"/metro-surum-denetimi "$CFG/systemd/user/metro-surum-denetimi.service" "$DATA/applications/metro-yukseltme.desktop" "$MT" \
           "$BIN"/explorer "$BIN"/devmgmt "$BIN"/linver "$BIN"/control "$BIN"/winver "$BIN"/metro-denetim \
           "${XDG_STATE_HOME:-$HOME/.local/state}/metrothemeplasma" "${XDG_CACHE_HOME:-$HOME/.cache}/metrothemeplasma"
    echo "Kullanıcı dosyaları kaldırıldı (ayarlar: $CFG/metrothemeplasma duruyor). Sistem kısmı için:"
    echo "  sudo bash $0 --plymouth-geri"
    echo "  sudo rm -rf /usr/local/bin/startmetro-wayland /usr/share/wayland-sessions/metrothemeplasma.desktop \\"
    echo "              /usr/share/sddm/themes/metrothemeplasma /etc/sddm.conf.d/zz-metrothemeplasma.conf \\"
    echo "              /usr/local/share/fonts/metrothemeplasma /usr/local/bin/metro-guncelle-hook \\"
    echo "              /etc/pacman.d/hooks/91-metro-guncelle.hook /etc/metrothemeplasma.conf"
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
install -Dm755 build/kabuk/metro-calistir "$BIN/metro-calistir"
install -Dm755 build/kabuk/metro-uygulama "$BIN/metro-uygulama"

echo "==> Windows 8.1 bildirim alanı (sistem tepsisi) derleniyor"
if $CMAKE -S plasma/tepsi -B build/tepsi -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && ninja -C build/tepsi >/dev/null 2>&1; then
    install -Dm755 build/tepsi/bin/io.github.yyozcan.metrotepsi.so "$MT/eklenti/plasma/applets/io.github.yyozcan.metrotepsi.so"
    rm -rf "$MT/qml/io/github/yyozcan/private/metrotepsi"; mkdir -p "$MT/qml/io/github/yyozcan/private"
    cp -r build/tepsi/bin/io/github/yyozcan/private/metrotepsi "$MT/qml/io/github/yyozcan/private/"
    kopyala plasma/tepsi/systemtray/package "$DATA/plasma/plasmoids/io.github.yyozcan.metrotepsi"
else
    echo "   (derlenemedi; Plasma'nın sistem tepsisi kullanılır)"
fi

echo "==> Windows 8.1 görev çubuğu düğmeleri (ATP SevenTasks çatalı) derleniyor"
rm -f "$MT/eklenti/plasma/applets/io.github.yyozcan.metrogorevler.so"
if [[ -d /usr/lib/qt6/qml/aeroshell/taskmanager ]] \
   && $CMAKE -S plasma/gorevler -B build/gorevler -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 \
   && ninja -C build/gorevler >/dev/null 2>&1; then
    install -Dm755 build/gorevler/bin/io.github.yyozcan.metrogorevler.so "$MT/eklenti/plasma/applets/io.github.yyozcan.metrogorevler.so"
    $PY tools/gen_gorevler.py "$MSSTYLES" build/gorevler-svg
    kopyala plasma/gorevler/package "$DATA/plasma/plasmoids/io.github.yyozcan.metrogorevler"
    cp build/gorevler-svg/*.svg "$DATA/plasma/plasmoids/io.github.yyozcan.metrogorevler/contents/ui/svgs/"
else
    rm -rf "$DATA/plasma/plasmoids/io.github.yyozcan.metrogorevler"
    echo "   (AeroThemePlasma'nın aeroshell.taskmanager modülü yok ya da derlenemedi; Plasma'nın görev çubuğu kullanılır)"
fi

# çatallanan ATP uygulamacıklarının çevirileri (çeviri alanı uygulamacık kimliğiyle değişti)
for es in "seventasks:metrogorevler" "systemtray:metrotepsi" "notifications:metrobildirim"; do
    for mo in /usr/share/locale/*/LC_MESSAGES/plasma_applet_io.gitgud.wackyideas.${es%%:*}.mo; do
        [[ -f $mo ]] || continue
        dil=$(basename "$(dirname "$(dirname "$mo")")")
        install -Dm644 "$mo" "$DATA/locale/$dil/LC_MESSAGES/plasma_applet_io.github.yyozcan.${es##*:}.mo"
    done
done

echo "==> Windows uygulamaları: Dosya Gezgini + Denetim Masası, Aygıt Yöneticisi, Windows Hakkında (Türkçe)"
# upstream projeler git alt modülü (uygulamalar/); kopyaları build/uyg altında yamalanıp Türkçeleştirilir
[[ -d .git ]] && git submodule update --init --quiet uygulamalar 2>/dev/null || true
UY="$KOK/build/uyg"
rm -rf "$UY"; mkdir -p "$UY" build/ceviri
$PY tools/gen_tz_sozluk.py "$WIN" uygulamalar/linux-explorer/src/data/control/WindowsTimeZones.cpp build/ceviri/saat-dilimleri.json 2>/dev/null || true
uyg_hazirla() {  # uyg_hazirla <ad> <sözlük...>
    local ad=$1; shift
    [[ -f uygulamalar/$ad/README.md ]] || { echo "   ($ad alt modülü yok, atlandı)"; return 1; }
    cp -r "uygulamalar/$ad" "$UY/$ad"; rm -rf "$UY/$ad/.git"
    ( cd "$UY/$ad"
      if [[ -f "$KOK/uygulamalar/yamalar/$ad.patch" ]]; then patch -s -p1 < "$KOK/uygulamalar/yamalar/$ad.patch" || exit 1; fi
      if [[ -f "$KOK/uygulamalar/yamalar/$ad.py" ]]; then $PY "$KOK/uygulamalar/yamalar/$ad.py" || exit 1; fi ) || return 1
    $PY tools/uygulama_cevir.py "$UY/$ad" "$@" >/dev/null
}
if uyg_hazirla linux-explorer uygulamalar/ceviri/linux-devmgmt.json uygulamalar/ceviri/linux-explorer.json build/ceviri/saat-dilimleri.json \
   && $CMAKE -S "$UY/linux-explorer" -B "$UY/linux-explorer/b" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 \
   && ninja -C "$UY/linux-explorer/b" >/dev/null 2>&1; then
    install -Dm755 "$UY/linux-explorer/b/explorer" "$BIN/explorer"
else
    echo "   (Dosya Gezgini derlenemedi: libAeroQt, kio, cups gerekli)"
fi
if uyg_hazirla linux-devmgmt uygulamalar/ceviri/linux-devmgmt.json \
   && $CMAKE -S "$UY/linux-devmgmt" -B "$UY/linux-devmgmt/b" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 \
   && ninja -C "$UY/linux-devmgmt/b" >/dev/null 2>&1; then
    install -Dm755 "$UY/linux-devmgmt/b/devmgmt" "$BIN/devmgmt"
else
    echo "   (Aygıt Yöneticisi derlenemedi)"
fi
if uyg_hazirla linver uygulamalar/ceviri/linver.json \
   && ( cd "$UY/linver" && mkdir -p b && cd b && qmake6 .. >/dev/null 2>&1 && make -j"$(nproc)" >/dev/null 2>&1 ); then
    install -Dm755 "$UY/linver/b/linver" "$BIN/linver"
else
    echo "   (Windows Hakkında derlenemedi: qmake6 gerekli)"
fi
# Windows komutları: control (Denetim Masası), winver
printf '#!/bin/sh\n# Windows control.exe: Denetim Masası (Dosya Gezgini içinde)\n[ $# -gt 0 ] && exec "%s/explorer" "controlpanel:///$*"\nexec "%s/explorer" --control-panel\n' "$BIN" "$BIN" > "$BIN/control"
printf '#!/bin/sh\nexec "%s/linver" "$@"\n' "$BIN" > "$BIN/winver"
chmod 755 "$BIN/control" "$BIN/winver"
ln -sf control "$BIN/metro-denetim"
# Dosya Gezgini ilk ayarları (yoksa): Windows adları (Windows Update, Kullanıcılar…) ve Windows 8.1 rozeti
EXC="$CFG/explorer/explorer.conf"
if [[ -x "$BIN/explorer" && ! -f "$EXC" ]]; then
    mkdir -p "$(dirname "$EXC")"
    printf '[Branding]\nuseWindowsNames=true\nwindowsFriendlyMode=true\n\n[ControlPanel]\nBranding\\style=1\n' > "$EXC"
fi
# Windows Hakkında: yalnızca kapat düğmesi (upstream add_rule.sh ile aynı KWin kuralı, sabit grup adıyla)
if [[ -x "$BIN/linver" ]] && ! grep -q '^\[metro-linver\]' "$CFG/kwinrulesrc" 2>/dev/null; then
    kwriteconfig6 --file kwinrulesrc --group metro-linver --key Description "Windows Hakkında (MetroThemePlasma)"
    kwriteconfig6 --file kwinrulesrc --group metro-linver --key clientmachine localhost
    kwriteconfig6 --file kwinrulesrc --group metro-linver --key minimizerule 2
    kwriteconfig6 --file kwinrulesrc --group metro-linver --key wmclass linver
    kwriteconfig6 --file kwinrulesrc --group metro-linver --key wmclassmatch 1
    kurallar=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
    sayi=$(kreadconfig6 --file kwinrulesrc --group General --key count --default 0)
    kwriteconfig6 --file kwinrulesrc --group General --key rules "${kurallar:+$kurallar,}metro-linver"
    kwriteconfig6 --file kwinrulesrc --group General --key count $((sayi + 1))
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

# KWin kuralı yaz (sabit grup adıyla, bir kez): kwin_kurali <grup> <açıklama> <anahtar=değer>...
kwin_kurali() {
    local grup="$1" aciklama="$2"; shift 2
    grep -q "^\[$grup\]" "$CFG/kwinrulesrc" 2>/dev/null && return 0
    kwriteconfig6 --file kwinrulesrc --group "$grup" --key Description "$aciklama"
    local kv
    for kv in "$@"; do kwriteconfig6 --file kwinrulesrc --group "$grup" --key "${kv%%=*}" "${kv#*=}"; done
    local kurallar sayi
    kurallar=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
    sayi=$(kreadconfig6 --file kwinrulesrc --group General --key count --default 0)
    kwriteconfig6 --file kwinrulesrc --group General --key rules "${kurallar:+$kurallar,}$grup"
    kwriteconfig6 --file kwinrulesrc --group General --key count $((sayi + 1))
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
}

echo "==> Kullanıcı Hesabı Denetimi (Windows 8.1 polkit kimlik doğrulama aracısı) derleniyor"
# ATP'nin uac-polkit-agent çatalı; yalnızca Metro oturumunda plasma-polkit-agent.service'in yerine geçer
# (kullanıcı drop-in'i; derlenemezse ya da ikili yoksa ATP'nin / KDE'nin aracısı çalışır)
DROPIN="$CFG/systemd/user/plasma-polkit-agent.service.d/zz-metrothemeplasma.conf"
if $CMAKE -S uac -B build/uac -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && ninja -C build/uac >/dev/null 2>&1; then
    install -Dm755 build/uac/metro-uac "$MT/bin/metro-uac"
    install -Dm644 session/metro-uac.conf "$DROPIN"
    systemctl --user daemon-reload 2>/dev/null || true
    kwin_kurali metro-uac "Kullanıcı Hesabı Denetimi (MetroThemePlasma)" clientmachine=localhost \
        "wmclass=(polkit-kde-authentication-agent-1)|(metro-uac)" wmclassmatch=3 \
        "title=Kullanıcı Hesabı Denetimi" titlematch=1 minimizerule=2 above=true aboverule=2 \
        placement=5 placementrule=2
    kwin_kurali metro-uac-perde "Kullanıcı Hesabı Denetimi karartması (MetroThemePlasma)" clientmachine=localhost \
        "wmclass=(polkit-kde-authentication-agent-1)|(metro-uac)" wmclassmatch=3 \
        title=metro-uac-perde titlematch=1 skiptaskbar=true skiptaskbarrule=2 skipswitcher=true skipswitcherrule=2 \
        skippager=true skippagerrule=2 noborder=true noborderrule=2 minimizerule=2
else
    echo "   (derlenemedi: polkit-qt6 gerekli; mevcut kimlik doğrulama aracısı kullanılır)"
fi

echo "==> Windows 8 bildirimleri (Plasma uygulamacığı) derleniyor"
if $CMAKE -S plasma/bildirim -B build/bildirim -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 && ninja -C build/bildirim >/dev/null 2>&1; then
    install -Dm755 build/bildirim/bin/plasma/applets/io.github.yyozcan.metrobildirim.so \
        "$MT/eklenti/plasma/applets/io.github.yyozcan.metrobildirim.so"
else
    echo "   (derlenemedi: plasma-workspace geliştirme dosyaları eksik olabilir; Plasma'nın bildirimleri kullanılır)"
fi

# ------------------------------------------------------------------ QML denetimi
# Tek bir QML hatası (ör. olmayan bir özelliğe atama) metro-kabuk'un tamamını düşürür: kurmadan önce yakala
QMLLINT=/usr/lib/qt6/bin/qmllint
if [[ -x $QMLLINT ]]; then
    hata=""
    for d in kabuk/qml kabuk/uygulamalar plasma/plasmoids/*/contents/ui plasma/qml/org/kde/plasma/workspace/osd; do
        hata+=$($QMLLINT -I "$d" "$d"/*.qml 2>&1 | grep -E 'Could not find property|\[syntax\]|^Error' || true)
    done
    if [[ -n $hata ]]; then
        echo "$hata" >&2
        echo "QML hatası bulundu; kurulum durduruldu (kurulu sürüm değiştirilmedi)." >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------ kurulum
echo "==> Kuruluyor ($DATA, $CFG)"
kopyala build/varlik "$MT/varlik"
kopyala kabuk/qml "$MT/kabuk/qml"
kopyala kabuk/uygulamalar "$MT/kabuk/uygulamalar"
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
# Windows uygulamaları (yalnızca Metro oturumunda görünür)
for g in session/uygulamalar/*.desktop; do
    ikili=$(sed -n 's|^Exec=@BIN@/\([^ ]*\).*|\1|p' "$g" | head -1)
    [[ -x "$BIN/$ikili" ]] && sed "s|@BIN@|$BIN|g" "$g" > "$APP/$(basename "$g")"
done
# Windows 8.1 Modern uygulamaları: yalnızca Metro oturumunda görünen uygulama girdileri (app_id metro-<ad>)
$PY - "$MT" "$BIN" <<'PYEOF'
import json, sys
from pathlib import Path
mt, bin_ = Path(sys.argv[1]), sys.argv[2]
hedef = mt / "data/applications"
hedef.mkdir(parents=True, exist_ok=True)
import shutil
for u in json.loads(Path("kabuk/uygulamalar/uygulamalar.json").read_text()):
    # Modern uygulama ya da (Mağaza gibi) kurulu bir programa kısayol
    if u.get("exec"):
        komut = next((e for e in u["exec"] if shutil.which(e)), None)
        if not komut:
            continue
    else:
        komut = f"{bin_}/metro-uygulama {u['ad']}" + (" %u" if u.get("mime") else "")
    (hedef / f"metro-{u['ad']}.desktop").write_text(
        "[Desktop Entry]\nType=Application\n"
        f"Name={u['isim']}\nComment={u['aciklama']}\n"
        f"Exec={komut}\n"
        f"Icon={mt}/varlik/uygulama-{u['ad']}.png\n"
        f"Categories={u['kategori']}\nKeywords={u['anahtar']};\n"
        + (f"MimeType={u['mime']}\n" if u.get("mime") else "")
        + ("" if u.get("exec") else f"StartupWMClass=metro-{u['ad']}\nX-Metro-Uygulamasi=true\n")
        + f"X-Metro-Renk={u['renk']}\n")
PYEOF
# Dosya Gezgini: "Başlangıç ekranına sabitle" (bu veri dizini yalnızca Metro oturumunda XDG_DATA_DIRS'te)
install -Dm755 session/servicemenus/metro-baslangica-sabitle.desktop "$MT/data/kio/servicemenus/metro-baslangica-sabitle.desktop"


echo "==> Oturum yardımcıları"
install -Dm755 session/metro-profil "$BIN/metro-profil"
install -Dm755 session/metro-yukselt "$BIN/metro-yukselt"
install -Dm755 session/metro-oturum "$BIN/metro-oturum"
install -Dm755 session/metro-renk "$BIN/metro-renk"
install -Dm644 session/metrothemeplasma-env.sh "$CFG/plasma-workspace/env/metrothemeplasma.sh"

# pencere çerçevesi rengi ([Pencere] cerceve): Alt+Tab bunu okur
"$BIN/metro-renk" uygula --sessiz || true
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}"/plasma_theme_Metro* 2>/dev/null || true

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/metrothemeplasma"
mkdir -p "$STATE"
echo "$KOK" > "$STATE/kaynak"
# Yükseltme Yardımcısı AeroThemePlasma oturumunun uygulama listesinde de görünsün (Windows 7'deki
# "Windows 8.1'e yükselt" gibi); Metro'da aynı kimlikli girdi bunu gölgeler
if [[ -f "$CFG/plasma-io.gitgud.wackyideas.desktop-appletsrc" && -f "$MT/data/applications/metro-yukseltme.desktop" ]]; then
    install -Dm644 "$MT/data/applications/metro-yukseltme.desktop" "$DATA/applications/metro-yukseltme.desktop"
fi
# bu kurulumun derlendiği sürümler (metro-surum-denetimi: Plasma güncellenip kanca çalışmadıysa oturumda yeniden kurar)
pacman -Q plasma-workspace kwin libplasma qt6-base qt6-declarative layer-shell-qt > "$STATE/derleme-surumleri" 2>/dev/null || true
install -Dm755 session/metro-surum-denetimi "$BIN/metro-surum-denetimi"
sed "s|@BIN@|$BIN|" session/metro-surum-denetimi.service > "$CFG/systemd/user/metro-surum-denetimi.service"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable metro-surum-denetimi.service 2>/dev/null || true

# AeroThemePlasma'dan yükseltme: ilk Metro oturumunda Windows 7 ayarları taşınır (metro-yukselt)
if [[ -f "$CFG/plasma-io.gitgud.wackyideas.desktop-appletsrc" ]]; then
    echo
    echo "==> AeroThemePlasma (Windows 7) bulundu — Windows 8.1'e yükseltme"
    "$BIN/metro-yukselt" --dene | sed 's/^/   /'
    if [[ -f "$CFG/metrothemeplasma/yukseltme.json" ]]; then
        echo "   (yükseltme daha önce yapıldı; yeniden uygulamak için: metro-yukselt --zorla)"
    elif [[ -f "$CFG/plasma-io.github.yyozcan.metroshell-appletsrc" ]]; then
        echo "   Metro zaten kullanılıyor; Windows 7 ayarlarını yine de taşımak için: metro-yukselt --zorla"
    else
        echo "   Bunlar ilk Metro oturumunda kendiliğinden taşınır. AeroThemePlasma oturumu olduğu gibi kalır."
    fi
fi
# ATP kaldırılırsa: hangi bileşen neye düşer
[[ -d /usr/lib/qt6/qml/aeroshell/taskmanager ]] || echo "   Not: ATP'nin aeroshell.taskmanager modülü yok; görev çubuğu Plasma'nın simge görev yöneticisini kullanır."
[[ -e /usr/lib/libAeroQt.so.0 ]] || echo "   Not: libAeroQt yok (AUR: libaero-qt-git); Dosya Gezgini yerine Dolphin kullanılır."

echo
echo "Kullanıcı kurulumu tamam."
if [[ ! -f /usr/share/wayland-sessions/metrothemeplasma.desktop ]] || ! cmp -s session/startmetro-wayland /usr/local/bin/startmetro-wayland \
   || { [[ -d /etc/pacman.d ]] && ! cmp -s session/kanca/metro-guncelle-hook /usr/local/bin/metro-guncelle-hook; }; then
    echo "Oturum girdisi için bir kez çalıştır:  sudo bash $KOK/kur.sh --sistem"
fi
echo "Sonra oturumu kapatıp SDDM'de 'MetroThemePlasma (Wayland)' seç."
