#include "otomatik.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QTimer>
#include <QUrl>

#include <KIO/OpenUrlJob>
#include <Solid/Device>
#include <Solid/DeviceNotifier>
#include <Solid/StorageAccess>
#include <Solid/StorageDrive>
#include <Solid/StorageVolume>

static const QString BILDIRIM = QStringLiteral("org.freedesktop.Notifications");
static const QString BILDIRIM_YOL = QStringLiteral("/org/freedesktop/Notifications");

OtomatikKullan::OtomatikKullan(QObject *parent)
    : QObject(parent)
{
    connect(Solid::DeviceNotifier::instance(), &Solid::DeviceNotifier::deviceAdded, this, &OtomatikKullan::aygitEklendi);
    QDBusConnection::sessionBus().connect(BILDIRIM, BILDIRIM_YOL, BILDIRIM, QStringLiteral("ActionInvoked"), this,
                                          SLOT(eylem(uint, QString)));
}

void OtomatikKullan::aygitEklendi(const QString &udi)
{
    Solid::Device aygit(udi);
    if (!aygit.is<Solid::StorageAccess>() || !aygit.is<Solid::StorageVolume>())
        return;
    if (aygit.as<Solid::StorageVolume>()->isIgnored())
        return;
    // yalnızca çıkarılabilir / takılıp çıkarılabilir sürücüler (USB bellek, kart, optik)
    Solid::Device ust = aygit;
    bool cikarilabilir = false;
    while (ust.isValid()) {
        if (auto *s = ust.as<Solid::StorageDrive>()) {
            cikarilabilir = s->isRemovable() || s->isHotpluggable();
            break;
        }
        ust = ust.parent();
    }
    if (!cikarilabilir)
        return;

    QString ad = aygit.description();
    if (ad.isEmpty())
        ad = QStringLiteral("Çıkarılabilir Disk");

    auto m = QDBusMessage::createMethodCall(BILDIRIM, BILDIRIM_YOL, BILDIRIM, QStringLiteral("Notify"));
    QVariantMap ipucu{{QStringLiteral("desktop-entry"), QStringLiteral("metro-kabuk")},
                      {QStringLiteral("x-kde-display-appname"), QStringLiteral("Otomatik Kullan")}};
    m << QStringLiteral("Otomatik Kullan") << uint(0) << aygit.icon() << ad
      << QStringLiteral("Bu aygıta ne olacağını seçmek için dokunun.")
      << QStringList{QStringLiteral("default"), QStringLiteral("Klasörü aç")} << ipucu << int(-1);
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
    Solid::Device aygit(udi);
    auto *erisim = aygit.as<Solid::StorageAccess>();
    if (!erisim)
        return;
    auto ac = [](const QString &yol) {
        auto *job = new KIO::OpenUrlJob(QUrl::fromLocalFile(yol), QStringLiteral("inode/directory"));
        job->start();
    };
    if (erisim->isAccessible()) {
        ac(erisim->filePath());
        return;
    }
    connect(erisim, &Solid::StorageAccess::setupDone, this, [erisim, ac](Solid::ErrorType hata, const QVariant &, const QString &) {
        if (hata == Solid::NoError)
            ac(erisim->filePath());
    });
    erisim->setup();
}
