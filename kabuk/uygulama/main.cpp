// metro-uygulama: Windows 8.1 Modern ("Metro") uygulamalarının ortak tam ekran ana programı.
//   metro-uygulama <ad>        ad: hesap-makinesi, alarmlar, hava-durumu, fotograflar, ses-kaydedici
// Her uygulama ayrı süreçtir; Wayland app_id'si "metro-<ad>" olur, böylece görev çubuğu ve
// Alt+Tab onu kendi .desktop dosyasıyla (simge, ad) eşler. Aynı uygulama ikinci kez açılırsa
// çalışan kopya öne gelir.
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QUrl>

#include "../src/dosya.h"

// QML'e küçük yardımcılar: program çalıştırma, komut çıktısı
class Yardimci : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE void calistir(const QString &program, const QStringList &arg) { QProcess::startDetached(program, arg); }
    Q_INVOKABLE QString cikti(const QString &program, const QStringList &arg, int zamanAsimi = 3000) const
    {
        QProcess p;
        p.start(program, arg);
        if (!p.waitForFinished(zamanAsimi)) {
            p.kill();
            return {};
        }
        return QString::fromUtf8(p.readAllStandardOutput());
    }
    Q_INVOKABLE bool programVar(const QString &ad) const { return !QStandardPaths::findExecutable(ad).isEmpty(); }
    Q_INVOKABLE QString ortam(const QString &ad) const { return qEnvironmentVariable(ad.toUtf8().constData()); }
    Q_INVOKABLE bool sil(const QString &yol) const { return QFile::remove(yol); }
    Q_INVOKABLE bool dizinOlustur(const QString &yol) const { return QDir().mkpath(yol); }
    Q_INVOKABLE QVariantList dosyalar(const QString &dizin, const QStringList &desenler) const
    {
        QVariantList l;
        const auto bilgiler = QDir(dizin).entryInfoList(desenler, QDir::Files, QDir::Time);
        for (const QFileInfo &f : bilgiler)
            l << QVariantMap{{QStringLiteral("yol"), f.absoluteFilePath()}, {QStringLiteral("ad"), f.completeBaseName()},
                             {QStringLiteral("tarih"), f.lastModified()}, {QStringLiteral("boyut"), f.size()}};
        return l;
    }
};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    const QStringList arg = app.arguments();
    const QString ad = arg.value(1);
    if (ad.isEmpty() || ad.startsWith(QLatin1Char('-'))) {
        qWarning("kullanım: metro-uygulama <hesap-makinesi|alarmlar|hava-durumu|fotograflar|ses-kaydedici>");
        return 1;
    }
    app.setApplicationName(QStringLiteral("metro-") + ad);
    app.setDesktopFileName(QStringLiteral("metro-") + ad);
    app.setOrganizationName(QStringLiteral("metrothemeplasma"));

    // tek kopya: çalışan kopya varsa onu öne getir
    const QString soket = QStringLiteral("metro-uygulama-") + ad;
    {
        QLocalSocket s;
        s.connectToServer(soket);
        if (s.waitForConnected(300)) {
            s.write("goster\n");
            s.waitForBytesWritten(300);
            return 0;
        }
    }
    QLocalServer::removeServer(soket);
    QLocalServer sunucu;
    sunucu.listen(soket);

    Dosya dosya;
    Yardimci yardimci;
    QQmlApplicationEngine motor;
    const QString qmlDizin = qEnvironmentVariableIsSet("METRO_UYGULAMA_QML")
        ? qEnvironmentVariable("METRO_UYGULAMA_QML")
        : QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/metrothemeplasma/kabuk/uygulamalar");
    auto *c = motor.rootContext();
    c->setContextProperty(QStringLiteral("UygulamaAdi"), ad);
    c->setContextProperty(QStringLiteral("Dosya"), &dosya);
    c->setContextProperty(QStringLiteral("Yardimci"), &yardimci);
    c->setContextProperty(QStringLiteral("SinamaKip"), qEnvironmentVariable("METRO_SINAMA_KIP"));
    motor.load(QUrl::fromLocalFile(qmlDizin + QStringLiteral("/Ana.qml")));
    if (motor.rootObjects().isEmpty())
        return 1;
    auto *pencere = qobject_cast<QQuickWindow *>(motor.rootObjects().constFirst());
    QObject::connect(&sunucu, &QLocalServer::newConnection, &app, [&] {
        while (auto *b = sunucu.nextPendingConnection()) {
            QObject::connect(b, &QLocalSocket::disconnected, b, &QObject::deleteLater);
            if (pencere) {
                pencere->showFullScreen();
                pencere->raise();
                pencere->requestActivate();
            }
        }
    });
    return app.exec();
}

#include "main.moc"
