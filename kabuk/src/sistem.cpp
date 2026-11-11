#include "sistem.h"

#include <KIO/CommandLauncherJob>
#include <KIO/OpenUrlJob>
#include <KUser>
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusReply>
#include <QDateTime>
#include <QDir>
#include <QLocale>
#include <QFileInfo>
#include <QHostInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QUrl>

static void cagir(const QString &servis, const QString &yol, const QString &arayuz, const QString &yontem,
                  const QVariantList &arg = {}, bool sistem = false)
{
    auto m = QDBusMessage::createMethodCall(servis, yol, arayuz, yontem);
    m.setArguments(arg);
    (sistem ? QDBusConnection::systemBus() : QDBusConnection::sessionBus()).asyncCall(m);
}

Sistem::Sistem(QObject *parent)
    : QObject(parent)
{
    m_gizlemeZamanlayici.setSingleShot(true);
    connect(&m_gizlemeZamanlayici, &QTimer::timeout, this, [this] { bildirimleriGizle(0); });
    auto bus = QDBusConnection::sessionBus();
    bus.connect(QStringLiteral("org.kde.keyboard"), QStringLiteral("/Layouts"), QStringLiteral("org.kde.KeyboardLayouts"),
                QStringLiteral("layoutChanged"), this, SLOT(klavyeOku()));
    bus.connect(QStringLiteral("org.kde.keyboard"), QStringLiteral("/Layouts"), QStringLiteral("org.kde.KeyboardLayouts"),
                QStringLiteral("layoutListChanged"), this, SLOT(klavyeOku()));
    QTimer::singleShot(0, this, &Sistem::klavyeOku);
}

QString Sistem::adSoyad() const
{
    KUser u;
    const QString ad = u.property(KUser::FullName).toString();
    return ad.isEmpty() ? u.loginName() : ad;
}

QString Sistem::kullanici() const
{
    return KUser().loginName();
}

QString Sistem::avatar() const
{
    const QString as = QStringLiteral("/var/lib/AccountsService/icons/") + KUser().loginName();
    for (const QString &p : {KUser().faceIconPath(), as, QDir::homePath() + QStringLiteral("/.face.icon"), QDir::homePath() + QStringLiteral("/.face")})
        if (!p.isEmpty() && QFileInfo(p).isReadable() && QFileInfo(p).size() > 0)
            return QUrl::fromLocalFile(p).toString();
    return {};
}

QString Sistem::bilgisayarAdi() const
{
    return QHostInfo::localHostName();
}

void Sistem::kilitle()
{
    cagir(QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("/ScreenSaver"), QStringLiteral("org.freedesktop.ScreenSaver"), QStringLiteral("Lock"));
}

void Sistem::oturumuKapat()
{
    cagir(QStringLiteral("org.kde.Shutdown"), QStringLiteral("/Shutdown"), QStringLiteral("org.kde.Shutdown"), QStringLiteral("logout"));
}

void Sistem::kapat()
{
    cagir(QStringLiteral("org.kde.Shutdown"), QStringLiteral("/Shutdown"), QStringLiteral("org.kde.Shutdown"), QStringLiteral("logoutAndShutdown"));
}

void Sistem::yenidenBaslat()
{
    cagir(QStringLiteral("org.kde.Shutdown"), QStringLiteral("/Shutdown"), QStringLiteral("org.kde.Shutdown"), QStringLiteral("logoutAndReboot"));
}

void Sistem::uyku()
{
    cagir(QStringLiteral("org.freedesktop.login1"), QStringLiteral("/org/freedesktop/login1"), QStringLiteral("org.freedesktop.login1.Manager"),
          QStringLiteral("Suspend"), {true}, true);
}

void Sistem::kullaniciDegistir()
{
    cagir(QStringLiteral("org.kde.ksmserver"), QStringLiteral("/KSMServer"), QStringLiteral("org.kde.KSMServerInterface"), QStringLiteral("openSwitchUserDialog"));
}

void Sistem::ac(const QString &url)
{
    auto *job = new KIO::OpenUrlJob(QUrl::fromUserInput(url, QDir::homePath()));
    job->start();
}

void Sistem::calistir(const QString &komut)
{
    auto *job = new KIO::CommandLauncherJob(komut);
    job->start();
}

void Sistem::ayarAc(const QString &modul)
{
    if (modul.isEmpty())
        calistir(QStringLiteral("systemsettings"));
    else
        calistir(QStringLiteral("systemsettings ") + modul);
}

QString Sistem::bildirimBitis() const
{
    return m_bitis ? QLocale(QLocale::Turkish).toString(m_bitis->time(), QStringLiteral("HH:mm")) : QString();
}

void Sistem::bildirimleriGizle(int saat)
{
    QDBusInterface n(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                     QStringLiteral("org.freedesktop.Notifications"));
    if (m_gizlemeCerez) {
        n.call(QStringLiteral("UnInhibit"), m_gizlemeCerez);
        m_gizlemeCerez = 0;
        delete m_bitis;
        m_bitis = nullptr;
        m_gizlemeZamanlayici.stop();
    }
    if (saat > 0) {
        QDBusReply<uint> r = n.call(QStringLiteral("Inhibit"), QStringLiteral("metro-kabuk"),
                                    QStringLiteral("Bildirimler gizlendi"), QVariantMap());
        if (r.isValid())
            m_gizlemeCerez = r.value();
        m_bitis = new QDateTime(QDateTime::currentDateTime().addSecs(saat * 3600));
        m_gizlemeZamanlayici.start(saat * 3600 * 1000);
    }
    Q_EMIT bildirimDegisti();
}

void Sistem::klavyeOku()
{
    QDBusInterface k(QStringLiteral("org.kde.keyboard"), QStringLiteral("/Layouts"), QStringLiteral("org.kde.KeyboardLayouts"));
    QDBusMessage r = k.call(QStringLiteral("getLayoutsList"));
    m_duzenler.clear();
    if (r.type() == QDBusMessage::ReplyMessage && !r.arguments().isEmpty()) {
        const QDBusArgument arg = r.arguments().first().value<QDBusArgument>();
        arg.beginArray();
        while (!arg.atEnd()) {
            QString kisa, varyant, uzun;
            arg.beginStructure();
            arg >> kisa >> varyant >> uzun;
            arg.endStructure();
            m_duzenler << QVariantMap{{QStringLiteral("kisa"), kisa.toUpper()}, {QStringLiteral("uzun"), uzun}};
        }
        arg.endArray();
    }
    QDBusReply<uint> d = k.call(QStringLiteral("getLayout"));
    m_duzen = d.isValid() ? int(d.value()) : 0;
    Q_EMIT klavyeDegisti();
}

void Sistem::klavyeSec(int i)
{
    cagir(QStringLiteral("org.kde.keyboard"), QStringLiteral("/Layouts"), QStringLiteral("org.kde.KeyboardLayouts"), QStringLiteral("setLayout"), {uint(i)});
}

QString Sistem::komutCiktisi(const QString &program, const QStringList &arg, int zamanAsimi) const
{
    QProcess p;
    p.start(program, arg);
    if (!p.waitForFinished(zamanAsimi)) {
        p.kill();
        return {};
    }
    return QString::fromUtf8(p.readAllStandardOutput()).trimmed();
}

bool Sistem::programVar(const QString &ad) const
{
    return !QStandardPaths::findExecutable(ad).isEmpty();
}
