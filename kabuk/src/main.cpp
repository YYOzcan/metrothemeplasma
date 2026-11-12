// metro-kabuk — MetroThemePlasma'nın Windows 8.1 kabuğu:
// Başlangıç ekranı, Uygulamalar görünümü, tılsımlar, saat paneli, Ara/Paylaş/Aygıtlar/Ayarlar
// bölmeleri, hızlı bağlantı menüsü (Win+X) ve sol geçiş çubuğu.
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickImageProvider>
#include <QQmlContext>
#include <QQuickWindow>
#include <QStandardPaths>

#include <KRunner/ResultsModel>
#include <KRunner/RunnerManager>

#include "desen.h"
#include "dosya.h"
#include "kabuk.h"
#include "katman.h"
#include "medya.h"
#include "simgerengi.h"
#include "sistem.h"
#include "uygulamalar.h"

// "image://simge/<ad>": simge temasından (Windows 8.1 simgeleri) piksel resmi
class SimgeSaglayici : public QQuickImageProvider
{
public:
    SimgeSaglayici() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &istenen) override
    {
        const int b = istenen.isValid() ? qMax(istenen.width(), istenen.height()) : 64;
        QIcon ic = id.startsWith(QLatin1Char('/')) ? QIcon(id) : QIcon::fromTheme(id);
        if (ic.isNull())
            ic = QIcon::fromTheme(QStringLiteral("application-x-executable"));
        QPixmap p = ic.pixmap(QSize(b, b));
        if (size)
            *size = p.size();
        return p;
    }
};

int main(int argc, char **argv)
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    QQuickWindow::setDefaultAlphaBuffer(true);
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("metro-kabuk"));
    app.setOrganizationDomain(QStringLiteral("yyozcan.github.io"));
    app.setDesktopFileName(QStringLiteral("metro-kabuk"));
    app.setQuitOnLastWindowClosed(false);

    auto bus = QDBusConnection::sessionBus();
    if (!bus.registerService(QStringLiteral("io.github.yyozcan.MetroKabuk"))) {
        // zaten çalışıyor: Başlangıç ekranını aç/kapat
        auto m = QDBusMessage::createMethodCall(QStringLiteral("io.github.yyozcan.MetroKabuk"), QStringLiteral("/Kabuk"),
                                                QStringLiteral("io.github.yyozcan.MetroKabuk"), QStringLiteral("Baslangic"));
        bus.call(m);
        return 0;
    }

    qmlRegisterType<KRunner::ResultsModel>("Metro", 1, 0, "AramaModeli");
    qmlRegisterUncreatableType<Katman>("Metro", 1, 0, "Katman", QStringLiteral("bağlam nesnesi"));

    Kabuk kabuk;
    Uygulamalar uygulamalar;
    Sistem sistem;
    Dosya dosya;
    SimgeRengi simgeRengi;
    Medya medya;
    Katman katman;

    const QString qmlDizin = qEnvironmentVariable("METRO_QML",
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/metrothemeplasma/kabuk/qml"));

    // --giris: oturumun ilk çalıştırmasında Başlangıç ekranı açılış animasyonuyla gelir.
    // Oturum kimliği $XDG_RUNTIME_DIR altında tutulur; systemd yeniden başlatınca tekrar açılmaz.
    bool oturumGirisi = false;
    if (app.arguments().contains(QStringLiteral("--giris"))) {
        const QString kimlik = qEnvironmentVariable("XDG_SESSION_ID", QStringLiteral("?")) + QLatin1Char(':')
                             + qEnvironmentVariable("WAYLAND_DISPLAY");
        QFile isaret(QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + QStringLiteral("/metro-kabuk-oturum"));
        QString onceki;
        if (isaret.open(QIODevice::ReadOnly)) {
            onceki = QString::fromUtf8(isaret.readAll()).trimmed();
            isaret.close();
        }
        if (onceki != kimlik) {
            oturumGirisi = true;
            if (isaret.open(QIODevice::WriteOnly | QIODevice::Truncate))
                isaret.write(kimlik.toUtf8());
        }
    }

    QQmlApplicationEngine *motor = nullptr;
    auto yukle = [&] {
        delete motor;
        motor = new QQmlApplicationEngine;
        auto *c = motor->rootContext();
        c->setContextProperty(QStringLiteral("Kabuk"), &kabuk);
        c->setContextProperty(QStringLiteral("Uygulamalar"), &uygulamalar);
        c->setContextProperty(QStringLiteral("Sistem"), &sistem);
        c->setContextProperty(QStringLiteral("Dosya"), &dosya);
        c->setContextProperty(QStringLiteral("SimgeRengi"), &simgeRengi);
        c->setContextProperty(QStringLiteral("Medya"), &medya);
        c->setContextProperty(QStringLiteral("KatmanYardimci"), &katman);
        c->setContextProperty(QStringLiteral("OturumGirisi"), oturumGirisi);
        // sınama: animasyonları bu ms'de dondur (test/ic-ice.sh ile kare kare bakmak için)
        c->setContextProperty(QStringLiteral("SinamaDondur"), qEnvironmentVariableIntValue("METRO_SINAMA_DONDUR"));
        c->setContextProperty(QStringLiteral("SinamaUzak"), qEnvironmentVariableIntValue("METRO_SINAMA_UZAK") == 1);
        oturumGirisi = false; // yeniden yüklemede bir daha değil
        c->setContextProperty(QStringLiteral("QmlDizini"), QUrl::fromLocalFile(qmlDizin + QLatin1Char('/')).toString());
        motor->addImageProvider(QStringLiteral("simge"), new SimgeSaglayici);
        motor->addImageProvider(QStringLiteral("desen"), new DesenSaglayici);
        motor->addImportPath(qmlDizin);
        motor->load(QUrl::fromLocalFile(qmlDizin + QStringLiteral("/Ana.qml")));
    };
    QObject::connect(&kabuk, &Kabuk::yenidenYukleIste, &app, [&] {
        QMetaObject::invokeMethod(&app, yukle, Qt::QueuedConnection);
    });
    yukle();
    if (motor->rootObjects().isEmpty())
        return 1;
    return app.exec();
}
