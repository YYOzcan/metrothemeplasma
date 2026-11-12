#include <QHash>
#include "uygulamalar.h"

#include <KApplicationTrader>
#include <KIO/ApplicationLauncherJob>
#include <KIO/OpenFileManagerWindowJob>
#include <KServiceAction>
#include <KSycoca>
#include <QCollator>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QStandardPaths>
#include <QUrl>
#include <algorithm>

// AeroThemePlasma'nın Windows 7 adları (~/.local/share/applications, iki oturumda ortak) Metro'da
// Windows 8.1'deki karşılıklarıyla gösterilir
static QString windows81Adi(const QString &ad, const QString &kimlik = QString())
{
    // aynı adlı iki girdi olmasın: Metro'nun kendi Dosya Gezgini ve Denetim Masası varken
    // ATP'nin bu adları verdiği Dolphin ve Sistem Ayarları kendi adlarıyla
    if (kimlik == QLatin1String("org.kde.dolphin.desktop") && !QStandardPaths::locate(QStandardPaths::ApplicationsLocation, QStringLiteral("explorer.desktop")).isEmpty())
        return QStringLiteral("Dolphin");
    if (kimlik == QLatin1String("systemsettings.desktop") && ad == QLatin1String("Denetim Masası"))
        return QStringLiteral("Sistem Ayarları");
    static const QHash<QString, QString> esle{
        {QStringLiteral("Internet Explorer 8"), QStringLiteral("Internet Explorer (masaüstü)")},
        {QStringLiteral("Windows Gezgini"), QStringLiteral("Dosya Gezgini")},
        {QStringLiteral("Windows Explorer"), QStringLiteral("Dosya Gezgini")},
    };
    return esle.value(ad, ad);
}

static QString yapilandirmaDizini()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/metrothemeplasma");
}

// Türkçe büyük harf (i -> İ) ve ASCII dışı harf grupları
static QString harfBul(const QString &ad)
{
    static const QLocale tr(QLocale::Turkish, QLocale::Turkey);
    for (const QChar c : ad) {
        if (c.isLetter())
            return tr.toUpper(QString(c));
        if (c.isDigit())
            return QStringLiteral("#");
    }
    return QStringLiteral("#");
}

Uygulamalar::Uygulamalar(QObject *parent)
    : QAbstractListModel(parent)
{
    kullanimYukle();
    gorulenYukle();
    yukle();
    connect(KSycoca::self(), &KSycoca::databaseChanged, this, [this] {
        yukle();
    });
}

QString Uygulamalar::kategoriBul(const KService::Ptr &s) const
{
    // Windows 8.1 "kategoriye göre" sıralaması Başlat menüsü klasörlerini kullanır;
    // burada freedesktop ana kategorileri Türkçe klasör adlarına çevrilir
    const QStringList k = s->categories();
    auto var = [&](const char *a) { return k.contains(QLatin1String(a)); };
    if (var("Game")) return QStringLiteral("Oyunlar");
    if (var("Settings") || var("DesktopSettings") || var("HardwareSettings")) return QStringLiteral("Ayarlar");
    if (var("System") || var("Monitor") || var("TerminalEmulator") || var("PackageManager")) return QStringLiteral("Sistem Araçları");
    if (var("Development") || var("IDE")) return QStringLiteral("Geliştirme");
    if (var("Office")) return QStringLiteral("Ofis");
    if (var("Graphics")) return QStringLiteral("Grafik");
    if (var("AudioVideo") || var("Audio") || var("Video")) return QStringLiteral("Çoklu Ortam");
    if (var("Network") || var("WebBrowser") || var("Email")) return QStringLiteral("İnternet");
    if (var("Education") || var("Science")) return QStringLiteral("Eğitim");
    if (var("Accessibility")) return QStringLiteral("Erişim Kolaylığı");
    if (var("Utility")) return QStringLiteral("Donatılar");
    return QStringLiteral("Diğer");
}

void Uygulamalar::yukle()
{
    const auto servisler = KApplicationTrader::query([](const KService::Ptr &s) {
        return !s->noDisplay() && s->showOnCurrentPlatform() && s->showInCurrentDesktop() && !s->exec().isEmpty();
    });
    QList<Kayit> yeni;
    QSet<QString> goruldu;
    for (const auto &s : servisler) {
        Kayit k;
        k.s = s;
        k.kimlik = s->storageId();
        if (goruldu.contains(k.kimlik))
            continue;
        goruldu.insert(k.kimlik);
        k.ad = windows81Adi(s->name(), s->storageId());
        k.harf = harfBul(k.ad);
        k.kategori = kategoriBul(s);
        k.anahtar = (s->name() + QLatin1Char(' ') + s->genericName() + QLatin1Char(' ') + s->keywords().join(QLatin1Char(' '))
                     + QLatin1Char(' ') + s->untranslatedGenericName() + QLatin1Char(' ') + QFileInfo(s->exec().section(QLatin1Char(' '), 0, 0)).fileName())
                        .toLower();
        k.kurulum = QFileInfo(s->entryPath()).birthTime();
        if (!k.kurulum.isValid())
            k.kurulum = QFileInfo(s->entryPath()).lastModified();
        yeni << k;
    }
    QCollator c(QLocale(QLocale::Turkish, QLocale::Turkey));
    c.setCaseSensitivity(Qt::CaseInsensitive);
    c.setNumericMode(true);
    std::sort(yeni.begin(), yeni.end(), [&](const Kayit &a, const Kayit &b) {
        return c.compare(a.ad, b.ad) < 0;
    });
    beginResetModel();
    m_liste = yeni;
    endResetModel();
    if (!m_gorulenVar) {
        // ilk çalıştırma: var olan her şey "görülmüş" sayılır
        gorulduIsaretle();
    }
    Q_EMIT sayiDegisti();
}

int Uygulamalar::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_liste.size());
}

QVariant Uygulamalar::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_liste.size())
        return {};
    const Kayit &k = m_liste.at(index.row());
    switch (role) {
    case Qt::DisplayRole:
    case AdRol: return k.ad;
    case KimlikRol: return k.kimlik;
    case GenelAdRol: return k.s->genericName();
    case AciklamaRol: return k.s->comment();
    case SimgeRol: return k.s->icon();
    case KategoriRol: return k.kategori;
    case HarfRol: return k.harf;
    case KurulumRol: return k.kurulum;
    case YeniRol: return m_gorulenVar && !m_gorulen.contains(k.kimlik);
    case KullanimRol: return m_kullanim.value(k.kimlik);
    case SiraRol: return index.row();
    case AnahtarRol: return k.anahtar;
    }
    return {};
}

QHash<int, QByteArray> Uygulamalar::roleNames() const
{
    return {{KimlikRol, "kimlik"}, {AdRol, "ad"}, {GenelAdRol, "genelAd"}, {AciklamaRol, "aciklama"},
            {SimgeRol, "simge"}, {KategoriRol, "kategori"}, {HarfRol, "harf"}, {KurulumRol, "kurulum"},
            {YeniRol, "yeni"}, {KullanimRol, "kullanim"}, {SiraRol, "sira"}, {AnahtarRol, "anahtar"}};
}

int Uygulamalar::yeniSayisi() const
{
    if (!m_gorulenVar)
        return 0;
    return int(std::count_if(m_liste.begin(), m_liste.end(), [this](const Kayit &k) {
        return !m_gorulen.contains(k.kimlik);
    }));
}

const Uygulamalar::Kayit *Uygulamalar::kayit(const QString &kimlik) const
{
    for (const auto &k : m_liste)
        if (k.kimlik == kimlik)
            return &k;
    return nullptr;
}

bool Uygulamalar::var(const QString &kimlik) const
{
    return kayit(kimlik) || KService::serviceByStorageId(kimlik);
}

QString Uygulamalar::bul(const QStringList &adaylar) const
{
    for (const auto &a : adaylar)
        if (KService::serviceByStorageId(a))
            return KService::serviceByStorageId(a)->storageId();
    return {};
}

void Uygulamalar::baslat(const QString &kimlik)
{
    KService::Ptr s = KService::serviceByStorageId(kimlik);
    if (!s)
        return;
    auto *job = new KIO::ApplicationLauncherJob(s);
    job->start();
    m_kullanim[s->storageId()]++;
    kullanimKaydet();
    if (!m_gorulen.contains(s->storageId())) {
        m_gorulen.insert(s->storageId());
        gorulduIsaretle();
    }
    Q_EMIT baslatildi(s->storageId());
}

void Uygulamalar::dosyaIleBaslat(const QString &kimlik, const QStringList &urller)
{
    KService::Ptr s = KService::serviceByStorageId(kimlik);
    if (!s)
        return;
    auto *job = new KIO::ApplicationLauncherJob(s);
    QList<QUrl> u;
    for (const auto &x : urller)
        u << QUrl::fromUserInput(x);
    job->setUrls(u);
    job->start();
}

QVariantList Uygulamalar::eylemler(const QString &kimlik) const
{
    QVariantList out;
    KService::Ptr s = KService::serviceByStorageId(kimlik);
    if (!s)
        return out;
    for (const KServiceAction &a : s->actions()) {
        if (a.noDisplay() || a.isSeparator())
            continue;
        out << QVariantMap{{QStringLiteral("ad"), a.name()}, {QStringLiteral("metin"), a.text()}, {QStringLiteral("simge"), a.icon()}};
    }
    return out;
}

void Uygulamalar::eylemCalistir(const QString &kimlik, const QString &eylem)
{
    KService::Ptr s = KService::serviceByStorageId(kimlik);
    if (!s)
        return;
    for (const KServiceAction &a : s->actions()) {
        if (a.name() == eylem) {
            auto *job = new KIO::ApplicationLauncherJob(a);
            job->start();
            return;
        }
    }
}

QVariantMap Uygulamalar::bilgi(const QString &kimlik) const
{
    KService::Ptr s = KService::serviceByStorageId(kimlik);
    if (!s)
        return {};
    return {{QStringLiteral("kimlik"), s->storageId()}, {QStringLiteral("ad"), windows81Adi(s->name(), s->storageId())},
            {QStringLiteral("simge"), s->icon()}, {QStringLiteral("aciklama"), s->comment()},
            {QStringLiteral("genelAd"), s->genericName()}, {QStringLiteral("yol"), s->entryPath()},
            {QStringLiteral("kategoriler"), s->categories()},
            // Metro uygulamaları: kutucuk rengi .desktop'ta (X-Metro-Renk)
            {QStringLiteral("renk"), s->property<QString>(QStringLiteral("X-Metro-Renk"))}};
}

void Uygulamalar::dosyaKonumunuAc(const QString &kimlik)
{
    KService::Ptr s = KService::serviceByStorageId(kimlik);
    if (!s)
        return;
    // Windows'taki gibi programın kendisini göster; bulunamazsa .desktop dosyasını
    QString ikili = QStandardPaths::findExecutable(s->exec().section(QLatin1Char(' '), 0, 0).remove(QLatin1Char('"')));
    const QString yol = ikili.isEmpty() ? s->entryPath() : QFileInfo(ikili).canonicalFilePath();
    KIO::highlightInFileManager({QUrl::fromLocalFile(yol)});
}

QVariantList Uygulamalar::ara(const QString &metin, int enFazla) const
{
    QVariantList bas, ic;
    const QString m = metin.trimmed().toLower();
    if (m.isEmpty())
        return {};
    for (const auto &k : m_liste) {
        const QString ad = k.ad.toLower();
        QVariantMap v{{QStringLiteral("kimlik"), k.kimlik}, {QStringLiteral("ad"), k.ad}, {QStringLiteral("simge"), k.s->icon()},
                      {QStringLiteral("aciklama"), k.s->genericName()}};
        if (ad.startsWith(m) || ad.contains(QLatin1Char(' ') + m))
            bas << v;
        else if (k.anahtar.contains(m))
            ic << v;
    }
    bas += ic;
    return bas.mid(0, enFazla);
}

void Uygulamalar::kullanimYukle()
{
    QFile f(yapilandirmaDizini() + QStringLiteral("/kullanim.json"));
    if (!f.open(QIODevice::ReadOnly))
        return;
    const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
    for (auto it = o.begin(); it != o.end(); ++it)
        m_kullanim[it.key()] = it.value().toInt();
}

void Uygulamalar::kullanimKaydet() const
{
    QDir().mkpath(yapilandirmaDizini());
    QJsonObject o;
    for (auto it = m_kullanim.begin(); it != m_kullanim.end(); ++it)
        o[it.key()] = it.value();
    QFile f(yapilandirmaDizini() + QStringLiteral("/kullanim.json"));
    if (f.open(QIODevice::WriteOnly))
        f.write(QJsonDocument(o).toJson(QJsonDocument::Compact));
}

void Uygulamalar::gorulenYukle()
{
    QFile f(yapilandirmaDizini() + QStringLiteral("/gorulen.json"));
    if (!f.open(QIODevice::ReadOnly))
        return;
    m_gorulenVar = true;
    for (const auto &v : QJsonDocument::fromJson(f.readAll()).array())
        m_gorulen.insert(v.toString());
}

void Uygulamalar::gorulduIsaretle()
{
    for (const auto &k : m_liste)
        m_gorulen.insert(k.kimlik);
    m_gorulenVar = true;
    QJsonArray a;
    for (const auto &g : m_gorulen)
        a << g;
    QDir().mkpath(yapilandirmaDizini());
    QFile f(yapilandirmaDizini() + QStringLiteral("/gorulen.json"));
    if (f.open(QIODevice::WriteOnly))
        f.write(QJsonDocument(a).toJson(QJsonDocument::Compact));
    if (!m_liste.isEmpty())
        Q_EMIT dataChanged(index(0), index(int(m_liste.size()) - 1), {YeniRol});
    Q_EMIT sayiDegisti();
}

QVariantList Uygulamalar::hepsi() const
{
    QVariantList out;
    out.reserve(m_liste.size());
    for (const auto &k : m_liste) {
        out << QVariantMap{{QStringLiteral("kimlik"), k.kimlik}, {QStringLiteral("ad"), k.ad}, {QStringLiteral("simge"), k.s->icon()},
                           {QStringLiteral("kategori"), k.kategori}, {QStringLiteral("harf"), k.harf},
                           {QStringLiteral("kurulum"), k.kurulum.toMSecsSinceEpoch()},
                           {QStringLiteral("yeni"), m_gorulenVar && !m_gorulen.contains(k.kimlik)},
                           {QStringLiteral("kullanim"), m_kullanim.value(k.kimlik)},
                           {QStringLiteral("anahtar"), k.anahtar}};
    }
    return out;
}
