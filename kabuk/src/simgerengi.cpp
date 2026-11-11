#include "simgerengi.h"
#include <QIcon>
#include <QImage>
#include <QPixmap>
#include <cmath>

QColor SimgeRengi::karistir(const QColor &a, const QColor &b, qreal t) const
{
    return QColor::fromRgbF(a.redF() * (1 - t) + b.redF() * t, a.greenF() * (1 - t) + b.greenF() * t,
                            a.blueF() * (1 - t) + b.blueF() * t, a.alphaF() * (1 - t) + b.alphaF() * t);
}

QColor SimgeRengi::renk(const QString &simge, const QColor &yedek)
{
    if (simge.isEmpty())
        return yedek;
    auto it = m_onbellek.constFind(simge);
    if (it != m_onbellek.constEnd())
        return it->isValid() ? *it : yedek;

    QIcon ic = simge.startsWith(QLatin1Char('/')) ? QIcon(simge) : QIcon::fromTheme(simge);
    QImage im = ic.pixmap(48, 48).toImage().convertToFormat(QImage::Format_ARGB32);
    // ton histogramı: doygun, görünür piksellerin baskın tonu
    double kova[36] = {}, r[36] = {}, g[36] = {}, b[36] = {};
    double toplam = 0;
    for (int y = 0; y < im.height(); ++y) {
        const QRgb *s = reinterpret_cast<const QRgb *>(im.constScanLine(y));
        for (int x = 0; x < im.width(); ++x) {
            const QColor c = QColor::fromRgba(s[x]);
            if (c.alpha() < 160)
                continue;
            const double sat = c.hsvSaturationF(), val = c.valueF();
            if (sat < 0.28 || val < 0.22)
                continue;
            const int h = std::clamp(int(c.hsvHueF() * 36), 0, 35);
            const double w = sat * val;
            kova[h] += w;
            r[h] += c.redF() * w;
            g[h] += c.greenF() * w;
            b[h] += c.blueF() * w;
            toplam += w;
        }
    }
    QColor sonuc;
    if (toplam > 6) {
        int en = 0;
        double enw = 0;
        for (int i = 0; i < 36; ++i) {
            const double w = kova[(i + 35) % 36] * 0.5 + kova[i] + kova[(i + 1) % 36] * 0.5;
            if (w > enw) { enw = w; en = i; }
        }
        double rr = 0, gg = 0, bb = 0, ww = 0;
        for (int d = -1; d <= 1; ++d) {
            const int i = (en + d + 36) % 36;
            rr += r[i]; gg += g[i]; bb += b[i]; ww += kova[i];
        }
        QColor c = QColor::fromRgbF(rr / ww, gg / ww, bb / ww);
        // kutucuk zemini: beyaz yazı okunacak kadar koyu, Metro kadar doygun
        float h, s, v;
        c.getHsvF(&h, &s, &v);
        s = std::clamp(s * 1.05f, 0.45f, 0.95f);
        v = std::clamp(v * 0.80f, 0.38f, 0.72f);
        sonuc = QColor::fromHsvF(h, s, v);
    }
    m_onbellek.insert(simge, sonuc);
    return sonuc.isValid() ? sonuc : yedek;
}
