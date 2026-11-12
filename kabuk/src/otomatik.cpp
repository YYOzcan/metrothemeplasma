#include "otomatik.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>

#include <KIO/OpenUrlJob>
#include <Solid/Device>
#include <Solid/DeviceNotifier>
#include <Solid/StorageAccess>
#include <Solid/StorageDrive>
#include <Solid/StorageVolume>

static const QString BILDIRIM = QStringLiteral("org.freedesktop.Notifications");
static const QString BILDIRIM_YOL = QStringLiteral("/org/freedesktop/Notifications");

static QString ayarDosyasi()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/metrothemeplasma/ayarlar.ini");
}

OtomatikKullan::OtomatikKullan(QObject *parent)
    : QObject(parent)
{
    connect(Solid::DeviceNotifier::instance(), &Solid::DeviceNotifier::deviceAdded, this, &OtomatikKullan::aygitEklendi);
    QDBusConnection::sessionBus().connect(BILDIRIM, BILDIRIM_YOL, BILDIRIM, QStringLiteral("ActionInvoked"), this,
                                          SLOT(eylem(uint, QString)));
}

QVariantMap OtomatikKullan::aygitBilgisi(const QString &udi) const
{
    Solid::Device aygit(udi);
    if (!aygit.is<Solid::StorageAccess>() || !aygit.is<Solid::StorageVolume>())
        return {};
    if (aygit.as<Solid::StorageVolume>()->isIgnored())
        return {};
    // yalnızca çıkarılabilir / takılıp çıkarılabilir sürücüler (USB bellek, kart, optik)
    Solid::Device ust = aygit;
    bool cikarilabilir = false;
    QString tur = QStringLiteral("cikarilabilir");
    while (ust.isValid()) {
        if (auto *s = ust.as<Solid::StorageDrive>()) {
            cikarilabilir = s->isRemovable() || s->isHotpluggable();
            switch (s->driveType()) {
            case Solid::StorageDrive::CompactFlash:
            case Solid::StorageDrive::MemoryStick:
            case Solid::StorageDrive::SmartMedia:
            case Solid::StorageDrive::SdMmc:
            case Solid::StorageDrive::Xd:
                tur = QStringLiteral("bellekKarti");
                break;
            default:
                break;
            }
            break;
        }
        ust = ust.parent();
    }
    if (!cikarilabilir)
        return {};
    // Windows: "ETİKET (E:)"; Linux'ta sürücü harfi yok, etiket ya da "Çıkarılabilir Disk" (shell32 9309)
    QString ad = aygit.as<Solid::StorageVolume>()->label();
    if (ad.isEmpty())
        ad = tur == QLatin1String("bellekKarti") ? QStringLiteral("Bellek kartı") : QStringLiteral("Çıkarılabilir Disk");
    auto *erisim = aygit.as<Solid::StorageAccess>();
    return {{QStringLiteral("udi"), udi}, {QStringLiteral("ad"), ad}, {QStringLiteral("simge"), aygit.icon()},
            {QStringLiteral("tur"), tur}, {QStringLiteral("yol"), erisim->isAccessible() ? erisim->filePath() : QString()}};
}

void OtomatikKullan::aygitEklendi(const QString &udi)
{
    const QVariantMap a = aygitBilgisi(udi);
    if (a.isEmpty())
        return;
    QSettings s(ayarDosyasi(), QSettings::IniFormat);
    s.beginGroup(QStringLiteral("OtomatikKullan"));
    if (!s.value(QStringLiteral("etkin"), true).toBool())
        return;
    const QString varsayilan = s.value(a.value(QStringLiteral("tur")).toString(), QStringLiteral("sor")).toString();
    if (varsayilan != QLatin1String("sor")) {
        eylemYap(udi, QString(), varsayilan);
        return;
    }
    auto m = QDBusMessage::createMethodCall(BILDIRIM, BILDIRIM_YOL, BILDIRIM, QStringLiteral("Notify"));
    QVariantMap ipucu{{QStringLiteral("desktop-entry"), QStringLiteral("metro-kabuk")},
                      {QStringLiteral("x-kde-display-appname"), QStringLiteral("Otomatik Kullan")}};
    m << QStringLiteral("Otomatik Kullan") << uint(0) << a.value(QStringLiteral("simge")).toString() << a.value(QStringLiteral("ad")).toString()
      << QStringLiteral("Bu aygıta ne olacağını seçmek için dokunun.")
      << QStringList{QStringLiteral("default"), QStringLiteral("Seç")} << ipucu << int(-1);
    auto *izle = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(m), this);
    connect(izle, &QDBusPendingCallWatcher::finished, this, [this, izle, udi] {
        QDBusPendingReply<uint> c = *izle;
        if (!c.isError())
            m_bildirimler.insert(c.value(), udi);
        izle->deleteLater();
    });
}

void OtomatikKullan::eylem(uint kimlik, const QString &ad)
{
    Q_UNUSED(ad)
    const QString udi = m_bildirimler.take(kimlik);
    if (udi.isEmpty())
        return;
    const QVariantMap a = aygitBilgisi(udi);
    if (!a.isEmpty())
        Q_EMIT panelIste(a);
}

bool OtomatikKullan::programVar(const QString &ad) const
{
    return !QStandardPaths::findExecutable(ad).isEmpty();
}

void OtomatikKullan::varsayilanYap(const QString &tur, const QString &eylem)
{
    QSettings s(ayarDosyasi(), QSettings::IniFormat);
    s.beginGroup(QStringLiteral("OtomatikKullan"));
    s.setValue(tur, eylem);
}

void OtomatikKullan::eylemYap(const QString &udi, const QString &yol, const QString &eylem)
{
    if (eylem == QLatin1String("hicbir") || eylem == QLatin1String("sor") || eylem.isEmpty())
        return;
    auto yap = [eylem](const QString &dizin) {
        if (eylem == QLatin1String("klasor")) {
            auto *job = new KIO::OpenUrlJob(QUrl::fromLocalFile(dizin), QStringLiteral("inode/directory"));
            job->start();
        } else if (eylem == QLatin1String("fotograf")) {
            QProcess::startDetached(QStandardPaths::findExecutable(QStringLiteral("metro-uygulama"),
                                                                   {QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + QStringLiteral("/.local/bin")}),
                                    {QStringLiteral("fotograflar"), QStringLiteral("--iceri-aktar"), dizin});
        } else if (eylem == QLatin1String("yedek")) {
            QProcess::startDetached(QStringLiteral("deja-dup"), {});
        }
    };
    if (udi.isEmpty()) {
        if (!yol.isEmpty())
            yap(yol);
        return;
    }
    Solid::Device aygit(udi);
    auto *erisim = aygit.as<Solid::StorageAccess>();
    if (!erisim)
        return;
    if (erisim->isAccessible()) {
        yap(erisim->filePath());
        return;
    }
    connect(erisim, &Solid::StorageAccess::setupDone, this, [erisim, yap](Solid::ErrorType hata, const QVariant &, const QString &) {
        if (hata == Solid::NoError)
            yap(erisim->filePath());
    }, Qt::SingleShotConnection);
    erisim->setup();
}
