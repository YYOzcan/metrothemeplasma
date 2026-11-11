#include "desen.h"
#include <QColor>
#include <QStandardPaths>
#include <QUrlQuery>
#include <algorithm>

DesenSaglayici::DesenSaglayici()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage DesenSaglayici::requestImage(const QString &id, QSize *size, const QSize &)
{
    const int soru = id.indexOf(QLatin1Char('?'));
    const QString yol = soru < 0 ? id : id.left(soru);
    if (yol.contains(QLatin1String("..")))
        return {};
    const QString dosya = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/metrothemeplasma/varlik/desen/") + yol;
    QImage im(dosya);
    if (im.isNull())
        return {};
    im = im.convertToFormat(QImage::Format_ARGB32);
    if (soru >= 0) {
        const QUrlQuery q(id.mid(soru + 1));
        auto renk = [&](const char *ad) { return QColor(QLatin1Char('#') + q.queryItemValue(QLatin1String(ad))); };
        const QColor c1 = renk("c1"), c2 = renk("c2"), a = renk("a"), v = renk("v");
        if (c1.isValid() && c2.isValid() && a.isValid() && v.isValid() && !(a == c1 && v == c2)) {
            const float v1[3] = {float(c1.red()), float(c1.green()), float(c1.blue())};
            const float yon[3] = {c2.red() - v1[0], c2.green() - v1[1], c2.blue() - v1[2]};
            const float boy = std::max(1.0f, yon[0] * yon[0] + yon[1] * yon[1] + yon[2] * yon[2]);
            const float da[3] = {a.red() - v1[0], a.green() - v1[1], a.blue() - v1[2]};
            const float dv[3] = {float(v.red() - c2.red()), float(v.green() - c2.green()), float(v.blue() - c2.blue())};
            for (int y = 0; y < im.height(); ++y) {
                QRgb *s = reinterpret_cast<QRgb *>(im.scanLine(y));
                for (int x = 0; x < im.width(); ++x) {
                    const int al = qAlpha(s[x]);
                    if (al == 0)
                        continue;
                    const float p[3] = {float(qRed(s[x])), float(qGreen(s[x])), float(qBlue(s[x]))};
                    float t = ((p[0] - v1[0]) * yon[0] + (p[1] - v1[1]) * yon[1] + (p[2] - v1[2]) * yon[2]) / boy;
                    t = std::clamp(t, 0.0f, 1.0f);
                    int o[3];
                    for (int k = 0; k < 3; ++k)
                        o[k] = std::clamp(int(p[k] + da[k] * (1 - t) + dv[k] * t + 0.5f), 0, 255);
                    s[x] = qRgba(o[0], o[1], o[2], al);
                }
            }
        }
    }
    if (size)
        *size = im.size();
    return im;
}
