#pragma once
#include <QQuickImageProvider>

// "image://desen/<kimlik>/<dosya>?c1=rrggbb&c2=rrggbb&a=rrggbb&v=rrggbb"
// Başlangıç arka planı desen resmi; c1/c2 verilirse iki renkli yeniden boyama yapılır
// (c1 → arka plan rengi a, c2 → vurgu rengi v; ara tonlar doğrusal, sapmalar korunur).
class DesenSaglayici : public QQuickImageProvider
{
public:
    DesenSaglayici();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
