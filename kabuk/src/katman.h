#pragma once
#include <QObject>
#include <QWindow>

// QML pencerelerini wlr-layer-shell yüzeyine çevirir (Başlangıç ekranı, tılsımlar, paneller).
class Katman : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    enum Kenar { Ust = 1, Alt = 2, Sol = 4, Sag = 8 };
    Q_ENUM(Kenar)
    enum Seviye { ArkaPlan = 0, Altta = 1, Ustte = 2, EnUstte = 3 };
    Q_ENUM(Seviye)
    enum Klavye { KlavyeYok = 0, KlavyeOzel = 1, KlavyeIstekle = 2 };
    Q_ENUM(Klavye)

    // pencere gösterilmeden önce çağrılmalı
    Q_INVOKABLE void ayarla(QWindow *pencere, int seviye, int kenarlar, int klavye, int dislamaAlani,
                            const QString &kapsam, int ust = 0, int sag = 0, int alt = 0, int sol = 0);
    Q_INVOKABLE void klavyeAyarla(QWindow *pencere, int klavye);
    // görünür yüzeyin katmanını değiştirir (layer-shell set_layer)
    Q_INVOKABLE void katmanAyarla(QWindow *pencere, int seviye);
    Q_INVOKABLE void kenarBosluk(QWindow *pencere, int ust, int sag, int alt, int sol);
};
