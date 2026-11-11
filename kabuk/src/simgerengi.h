#pragma once
#include <QHash>
#include <QObject>
#include <QColor>

// Masaüstü uygulaması kutucuklarının zemin rengi: simgenin baskın rengi (Windows 8.1'deki gibi)
class SimgeRengi : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE QColor renk(const QString &simge, const QColor &yedek);
    Q_INVOKABLE QColor acik(const QColor &c, qreal oran) const { return c.lighter(int(100 * oran)); }
    Q_INVOKABLE QColor koyu(const QColor &c, qreal oran) const { return c.darker(int(100 * oran)); }
    Q_INVOKABLE QColor karistir(const QColor &a, const QColor &b, qreal t) const;
private:
    QHash<QString, QColor> m_onbellek;
};
