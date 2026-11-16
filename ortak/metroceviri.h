// MetroThemePlasma C++ arayüz metinleri için çeviri: mtr("Türkçe metin") etkin dildeki karşılığını döndürür.
// Etkin dil metro-dil'in yazdığı ~/.local/share/metrothemeplasma/dil/aktif dosyasındadır (oturum başında
// sistem dilinden seçilir); sözlük aynı dizindeki <dil>.json ({Türkçe: çeviri}, tools/dil_uygula.py json).
// Dosya yoksa ya da metin sözlükte yoksa Türkçe kaynak olduğu gibi döner.
#pragma once

#include <QFile>
#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QStandardPaths>
#include <QString>

inline QString metroDil()
{
    static const QString dil = [] {
        // sınama: METRO_DIL=de (gerçek kurulumu değiştirmeden)
        if (qEnvironmentVariableIsSet("METRO_DIL"))
            return qEnvironmentVariable("METRO_DIL");
        QFile f(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                + QStringLiteral("/metrothemeplasma/dil/aktif"));
        if (f.open(QIODevice::ReadOnly)) {
            const QString d = QString::fromUtf8(f.readAll()).trimmed();
            if (!d.isEmpty())
                return d;
        }
        return QStringLiteral("tr");
    }();
    return dil;
}

inline const QHash<QString, QString> &metroSozluk()
{
    static const QHash<QString, QString> sozluk = [] {
        QHash<QString, QString> h;
        if (metroDil() == QLatin1String("tr"))
            return h;
        QFile f(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                + QStringLiteral("/metrothemeplasma/dil/") + metroDil() + QStringLiteral(".json"));
        if (!f.open(QIODevice::ReadOnly))
            return h;
        const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
        for (auto it = o.begin(); it != o.end(); ++it)
            h.insert(it.key(), it.value().toString());
        return h;
    }();
    return sozluk;
}

inline QString mtr(const QString &metin)
{
    const auto &s = metroSozluk();
    const auto it = s.constFind(metin);
    return it == s.constEnd() ? metin : *it;
}

// etkin dilin yerel ayarı (tarih/sayı biçimleri, ay adları)
inline QLocale metroYerel()
{
    static const QHash<QString, QString> yerel{{QStringLiteral("tr"), QStringLiteral("tr_TR")}, {QStringLiteral("en"), QStringLiteral("en_US")},
                                               {QStringLiteral("de"), QStringLiteral("de_DE")}, {QStringLiteral("fr"), QStringLiteral("fr_FR")},
                                               {QStringLiteral("es"), QStringLiteral("es_ES")}, {QStringLiteral("it"), QStringLiteral("it_IT")},
                                               {QStringLiteral("pt_BR"), QStringLiteral("pt_BR")}, {QStringLiteral("ru"), QStringLiteral("ru_RU")},
                                               {QStringLiteral("pl"), QStringLiteral("pl_PL")}, {QStringLiteral("nl"), QStringLiteral("nl_NL")},
                                               {QStringLiteral("az"), QStringLiteral("az_AZ")}};
    return QLocale(yerel.value(metroDil(), QStringLiteral("tr_TR")));
}

// etkin dilin çevrilmiş QML kopyası (kurulumda üretilir): <veri>/metrothemeplasma/dil/<dil>/<goreli>; yoksa Türkçe asıl
inline QString metroQmlDizini(const QString &goreli)
{
    const QString veri = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/metrothemeplasma/");
    if (metroDil() != QLatin1String("tr")) {
        const QString d = veri + QStringLiteral("dil/") + metroDil() + QLatin1Char('/') + goreli;
        if (QFile::exists(d))
            return d;
    }
    return veri + goreli;
}
