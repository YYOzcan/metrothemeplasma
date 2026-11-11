# MetroThemePlasma — her Plasma oturumunun başında çalışır (startplasma tarafından source edilir)
if [ -x "$HOME/.local/bin/metro-profil" ]; then
    if [ "$PLASMA_DEFAULT_SHELL" = "io.github.yyozcan.metroshell" ]; then
        "$HOME/.local/bin/metro-profil" metro >/dev/null 2>&1
    else
        # Metro oturumu düzgün kapanmadıysa önceki temayı geri getir
        "$HOME/.local/bin/metro-profil" geri >/dev/null 2>&1
    fi
fi
