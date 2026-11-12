// metro-uygulama: Windows 8.1 Modern ("Metro") uygulamalarının ortak tam ekran ana programı.
//   metro-uygulama <ad>        ad: hesap-makinesi, alarmlar, hava-durumu, fotograflar, ses-kaydedici
// Her uygulama ayrı süreçtir; Wayland app_id'si "metro-<ad>" olur, böylece görev çubuğu ve
// Alt+Tab onu kendi .desktop dosyasıyla (simge, ad) eşler. Aynı uygulama ikinci kez açılırsa
// çalışan kopya öne gelir.
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QPointer>
#include <QThreadPool>
#include <QFileInfo>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocale>
#include <QLocalSocket>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QUrl>

#include "../src/dosya.h"
#ifdef METRO_WEBENGINE
#include <QtWebEngineQuick/qtwebenginequickglobal.h>
#endif

// QML'e küçük yardımcılar: program çalıştırma, komut çıktısı
class Yardimci : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList argumanlar MEMBER m_argumanlar NOTIFY argumanlarDegisti)
public:
    using QObject::QObject;
    QStringList m_argumanlar;
Q_SIGNALS:
    void argumanlarDegisti();
    void kopyaIlerleme(int n, int toplam);
    void kopyaBitti(int n, const QString &hedef);
public:
    // fotoğraf/video dosyaları (Otomatik Kullan > içeri aktar): yinelemeli, en yeni önce
    Q_INVOKABLE QVariantList medyaBul(const QString &dizin, int enFazla = 2000) const
    {
        static const QStringList uzantilar{QStringLiteral("jpg"), QStringLiteral("jpeg"), QStringLiteral("png"), QStringLiteral("gif"),
                                           QStringLiteral("bmp"), QStringLiteral("heic"), QStringLiteral("webp"), QStringLiteral("tif"),
                                           QStringLiteral("tiff"), QStringLiteral("dng"), QStringLiteral("cr2"), QStringLiteral("nef"),
                                           QStringLiteral("mp4"), QStringLiteral("mov"), QStringLiteral("avi"), QStringLiteral("mkv"),
                                           QStringLiteral("3gp"), QStringLiteral("mts"), QStringLiteral("m4v"), QStringLiteral("wmv")};
        QList<QFileInfo> l;
        QDirIterator it(dizin, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext() && l.size() < enFazla) {
            const QFileInfo f(it.next());
            if (uzantilar.contains(f.suffix().toLower()))
                l << f;
        }
        std::sort(l.begin(), l.end(), [](const QFileInfo &a, const QFileInfo &b) { return a.lastModified() > b.lastModified(); });
        QVariantList v;
        for (const QFileInfo &f : std::as_const(l))
            v << QVariantMap{{QStringLiteral("yol"), f.absoluteFilePath()}, {QStringLiteral("url"), QUrl::fromLocalFile(f.absoluteFilePath()).toString()},
                             {QStringLiteral("video"), QStringList{QStringLiteral("mp4"), QStringLiteral("mov"), QStringLiteral("avi"), QStringLiteral("mkv"), QStringLiteral("3gp"), QStringLiteral("mts"), QStringLiteral("m4v"), QStringLiteral("wmv")}.contains(f.suffix().toLower())},
                             {QStringLiteral("tarih"), f.lastModified()}};
        return v;
    }
    // yinelemeli dosya listesi (Müzik, Video): ad, klasör (albüm), üst klasör (sanatçı), adres
    Q_INVOKABLE QVariantList dosyaBul(const QString &dizin, const QStringList &uzantilar, int enFazla = 5000) const
    {
        QVariantList v;
        QDirIterator it(dizin, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
        while (it.hasNext() && v.size() < enFazla) {
            const QFileInfo f(it.next());
            if (!uzantilar.contains(f.suffix().toLower()))
                continue;
            const QDir d = f.dir();
            QDir u = d;
            u.cdUp();
            v << QVariantMap{{QStringLiteral("yol"), f.absoluteFilePath()}, {QStringLiteral("url"), QUrl::fromLocalFile(f.absoluteFilePath()).toString()},
                             {QStringLiteral("ad"), f.completeBaseName()}, {QStringLiteral("klasor"), d.absolutePath() == QDir(dizin).absolutePath() ? QString() : d.dirName()},
                             {QStringLiteral("ust"), u.absolutePath().startsWith(QDir(dizin).absolutePath() + QLatin1Char('/')) ? u.dirName() : QString()},
                             {QStringLiteral("tarih"), f.lastModified()}, {QStringLiteral("boyut"), f.size()}};
        }
        return v;
    }
    // Müzik/Videolar gibi kitaplık dizini (Türkçe ya da İngilizce ad)
    Q_INVOKABLE QString kitaplik(const QString &tur) const
    {
        const auto konum = tur == QLatin1String("muzik") ? QStandardPaths::MusicLocation
                         : tur == QLatin1String("video") ? QStandardPaths::MoviesLocation
                         : tur == QLatin1String("indirilen") ? QStandardPaths::DownloadLocation : QStandardPaths::PicturesLocation;
        return QStandardPaths::writableLocation(konum);
    }
    // arka planda kopyala (aynı adlı dosya varsa "ad (2).uzantı"); ilerleme ve bitiş sinyalle
    Q_INVOKABLE void kopyala(const QStringList &dosyalar, const QString &hedef)
    {
        QDir().mkpath(hedef);
        QPointer<Yardimci> ben(this);
        QThreadPool::globalInstance()->start([ben, dosyalar, hedef] {
            int n = 0;
            for (int i = 0; i < dosyalar.size(); ++i) {
                const QFileInfo k(dosyalar[i]);
                QString h = hedef + QLatin1Char('/') + k.fileName();
                for (int s = 2; QFileInfo::exists(h); ++s)
                    h = hedef + QLatin1Char('/') + k.completeBaseName() + QStringLiteral(" (%1).").arg(s) + k.suffix();
                if (QFile::copy(k.absoluteFilePath(), h)) {
                    ++n;
                    QFile(h).setFileTime(k.lastModified(), QFileDevice::FileModificationTime);
                }
                if (ben)
                    QMetaObject::invokeMethod(ben, [ben, i, dosyalar] { if (ben) Q_EMIT ben->kopyaIlerleme(i + 1, dosyalar.size()); }, Qt::QueuedConnection);
            }
            if (ben)
                QMetaObject::invokeMethod(ben, [ben, n, hedef] { if (ben) Q_EMIT ben->kopyaBitti(n, hedef); }, Qt::QueuedConnection);
        });
    }
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
    // Internet Explorer (Modern): QtWebEngine uygulama nesnesinden önce başlatılmalı
    const bool web = argc > 1 && qstrcmp(argv[1], "internet-explorer") == 0;
#ifdef METRO_WEBENGINE
    if (web) {
        QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
        QtWebEngineQuick::initialize();
    }
#else
    Q_UNUSED(web)
#endif
    QGuiApplication app(argc, argv);
    // Metro uygulamaları Türkçe: tarih/sayı biçimleri (ay adları, ondalık virgül)
    QLocale::setDefault(QLocale(QLocale::Turkish, QLocale::Turkey));
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
            // çalışan kopyaya argümanları ilet (ör. --iceri-aktar <dizin>)
            s.write(arg.mid(2).join(QLatin1Char('\x1f')).toUtf8() + "\n");
            s.waitForBytesWritten(300);
            return 0;
        }
    }
    QLocalServer::removeServer(soket);
    QLocalServer sunucu;
    sunucu.listen(soket);
    const QStringList argumanlar = arg.mid(2);

    Dosya dosya;
    Yardimci yardimci;
    yardimci.m_argumanlar = argumanlar;
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
            QObject::connect(b, &QLocalSocket::readyRead, b, [b, &yardimci] {
                const QString satir = QString::fromUtf8(b->readLine()).trimmed();
                if (!satir.isEmpty()) {
                    yardimci.m_argumanlar = satir.split(QLatin1Char('\x1f'));
                    Q_EMIT yardimci.argumanlarDegisti();
                }
            });
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
