#pragma once
#include <QObject>
#include <QString>
#include <QVariant>

// Küçük dosya yardımcıları (kutucuk düzeni JSON'u, yapılandırma yolları)
class Dosya : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString yapilandirma READ yapilandirma CONSTANT)
    Q_PROPERTY(QString veri READ veri CONSTANT)
    Q_PROPERTY(QString ev READ ev CONSTANT)
public:
    using QObject::QObject;
    QString yapilandirma() const;   // ~/.config/metrothemeplasma
    QString veri() const;           // ~/.local/share/metrothemeplasma
    QString ev() const;
    Q_INVOKABLE QString oku(const QString &yol) const;
    Q_INVOKABLE bool yaz(const QString &yol, const QString &icerik) const;
    Q_INVOKABLE bool var(const QString &yol) const;
    Q_INVOKABLE QStringList resimler(const QString &dizin, int enFazla = 60) const;
    Q_INVOKABLE QString url(const QString &yol) const;
    Q_INVOKABLE qint64 degisim(const QString &yol) const;
};
