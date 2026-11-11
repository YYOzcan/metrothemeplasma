#include "dosya.h"
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUrl>

QString Dosya::yapilandirma() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/metrothemeplasma");
}

QString Dosya::veri() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/metrothemeplasma");
}

QString Dosya::ev() const
{
    return QDir::homePath();
}

QString Dosya::oku(const QString &yol) const
{
    QFile f(yol);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return QString::fromUtf8(f.readAll());
}

bool Dosya::yaz(const QString &yol, const QString &icerik) const
{
    QDir().mkpath(QFileInfo(yol).absolutePath());
    QSaveFile f(yol);
    if (!f.open(QIODevice::WriteOnly))
        return false;
    f.write(icerik.toUtf8());
    return f.commit();
}

bool Dosya::var(const QString &yol) const
{
    return QFileInfo::exists(yol);
}

QStringList Dosya::resimler(const QString &dizin, int enFazla) const
{
    QStringList out;
    QDirIterator it(dizin, {QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"), QStringLiteral("*.png"), QStringLiteral("*.webp")},
                    QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext() && out.size() < enFazla)
        out << QUrl::fromLocalFile(it.next()).toString();
    return out;
}

QString Dosya::url(const QString &yol) const
{
    return QUrl::fromLocalFile(yol).toString();
}

qint64 Dosya::degisim(const QString &yol) const
{
    return QFileInfo(yol).lastModified().toMSecsSinceEpoch();
}
