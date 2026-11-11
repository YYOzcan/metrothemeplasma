#include "katman.h"
#include <LayerShellQt/Window>

void Katman::ayarla(QWindow *pencere, int seviye, int kenarlar, int klavye, int dislamaAlani,
                    const QString &kapsam, int ust, int sag, int alt, int sol)
{
    if (!pencere)
        return;
    auto *ls = LayerShellQt::Window::get(pencere);
    ls->setLayer(LayerShellQt::Window::Layer(seviye));
    ls->setAnchors(LayerShellQt::Window::Anchors(kenarlar));
    ls->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivity(klavye));
    ls->setExclusiveZone(dislamaAlani);
    ls->setScope(kapsam);
    ls->setMargins(QMargins(sol, ust, sag, alt));
    ls->setWantsToBeOnActiveScreen(true);
    ls->setActivateOnShow(klavye != 0);
}

void Katman::klavyeAyarla(QWindow *pencere, int klavye)
{
    if (pencere)
        LayerShellQt::Window::get(pencere)->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivity(klavye));
}

void Katman::kenarBosluk(QWindow *pencere, int ust, int sag, int alt, int sol)
{
    if (pencere)
        LayerShellQt::Window::get(pencere)->setMargins(QMargins(sol, ust, sag, alt));
}
