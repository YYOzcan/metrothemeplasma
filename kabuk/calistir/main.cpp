// metro-calistir — Windows 8.1 "Çalıştır" iletişim kutusu (Win+R).
// Metinler shell32.dll.mui iletişim kutusu 1003 ve dize 12353'ten (Türkçe Windows 8.1).
// Görünüm Kvantum "Metro" temasından gelir; konum (sol alt, görev çubuğunun üstü) metro_koseler KWin betiğinde.
#include <QApplication>
#include <QComboBox>
#include <QDialog>
#include <QDialogButtonBox>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QIcon>
#include <QJsonArray>
#include <QJsonDocument>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QPushButton>
#include <QStandardPaths>
#include <QUrl>
#include <QVBoxLayout>

#include <KIO/CommandLauncherJob>
#include <KIO/OpenUrlJob>
#include <KService>

static QString gecmisDosyasi()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/metrothemeplasma/calistir.json");
}

static QStringList gecmisOku()
{
    QFile f(gecmisDosyasi());
    if (!f.open(QIODevice::ReadOnly))
        return {};
    QStringList l;
    for (const auto &v : QJsonDocument::fromJson(f.readAll()).array())
        l << v.toString();
    return l;
}

static void gecmisYaz(const QString &komut)
{
    QStringList l = gecmisOku();
    l.removeAll(komut);
    l.prepend(komut);
    while (l.size() > 26) // Windows RunMRU: a-z
        l.removeLast();
    QDir().mkpath(QFileInfo(gecmisDosyasi()).absolutePath());
    QFile f(gecmisDosyasi());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(QJsonArray::fromStringList(l)).toJson(QJsonDocument::Compact));
}

// Windows komutlarının bu sistemdeki karşılıkları
static QString windowsKarsiligi(const QString &komut)
{
    struct E { const char *win; QStringList adaylar; };
    static const QList<E> esler = {
        {"cmd", {QStringLiteral("konsole"), QStringLiteral("kgx"), QStringLiteral("xterm")}},
        {"powershell", {QStringLiteral("konsole")}},
        {"notepad", {QStringLiteral("kwrite"), QStringLiteral("kate"), QStringLiteral("gnome-text-editor")}},
        {"calc", {QStringLiteral("kcalc"), QStringLiteral("gnome-calculator")}},
        {"mspaint", {QStringLiteral("kolourpaint"), QStringLiteral("pinta")}},
        {"explorer", {QStringLiteral("dolphin"), QStringLiteral("nautilus")}},
        {"control", {QStringLiteral("systemsettings")}},
        {"taskmgr", {QStringLiteral("metro-gorev"), QStringLiteral("plasma-systemmonitor")}},
        {"msinfo32", {QStringLiteral("kinfocenter")}},
        {"devmgmt.msc", {QStringLiteral("kinfocenter")}},
        {"diskmgmt.msc", {QStringLiteral("partitionmanager"), QStringLiteral("gnome-disks")}},
        {"eventvwr", {QStringLiteral("ksystemlog")}},
        {"snippingtool", {QStringLiteral("spectacle")}},
        {"wordpad", {QStringLiteral("kwrite"), QStringLiteral("calligrawords")}},
        {"iexplore", {QStringLiteral("firefox"), QStringLiteral("chromium")}},
        {"charmap", {QStringLiteral("kcharselect")}},
        {"magnify", {QStringLiteral("kmag")}},
        {"osk", {QStringLiteral("onboard")}},
    };
    const QString ilk = komut.section(QLatin1Char(' '), 0, 0).toLower().remove(QStringLiteral(".exe"));
    for (const auto &e : esler) {
        if (ilk == QLatin1String(e.win)) {
            for (const auto &a : e.adaylar)
                if (!QStandardPaths::findExecutable(a).isEmpty())
                    return a + komut.mid(komut.section(QLatin1Char(' '), 0, 0).size());
        }
    }
    return {};
}

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("metro-calistir"));
    app.setDesktopFileName(QStringLiteral("metro-calistir"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("system-run")));

    QDialog d;
    d.setWindowTitle(QStringLiteral("Çalıştır"));
    d.setObjectName(QStringLiteral("metro-calistir"));

    auto *simge = new QLabel;
    simge->setPixmap(QIcon::fromTheme(QStringLiteral("system-run")).pixmap(32, 32));
    simge->setAlignment(Qt::AlignTop);
    auto *aciklama = new QLabel(QStringLiteral("Bir program, klasör, belge veya Internet kaynağının adını yazdığınızda Windows sizin için açacaktır."));
    aciklama->setWordWrap(true);

    auto *etiket = new QLabel(QStringLiteral("&Aç:"));
    auto *kutu = new QComboBox;
    kutu->setEditable(true);
    kutu->setInsertPolicy(QComboBox::NoInsert);
    kutu->addItems(gecmisOku());
    kutu->setCurrentIndex(kutu->count() ? 0 : -1);
    kutu->lineEdit()->selectAll();
    etiket->setBuddy(kutu);

    // Windows sırası: Tamam, İptal, Gözat... (sağa yaslı)
    auto *tamam = new QPushButton(QStringLiteral("Tamam"));
    auto *iptal = new QPushButton(QStringLiteral("İptal"));
    auto *gozat = new QPushButton(QStringLiteral("G&özat..."));
    auto *dugmeler = new QHBoxLayout;
    dugmeler->setSpacing(8);
    dugmeler->addStretch(1);
    for (auto *b : {tamam, iptal, gozat}) {
        b->setMinimumWidth(88);
        dugmeler->addWidget(b);
    }
    tamam->setDefault(true);
    tamam->setAutoDefault(true);
    tamam->setEnabled(!kutu->currentText().trimmed().isEmpty());
    QObject::connect(kutu, &QComboBox::editTextChanged, tamam, [tamam](const QString &t) { tamam->setEnabled(!t.trimmed().isEmpty()); });

    auto *ust = new QHBoxLayout;
    ust->setSpacing(14);
    ust->addWidget(simge);
    ust->addWidget(aciklama, 1);
    auto *orta = new QHBoxLayout;
    orta->setSpacing(10);
    orta->addWidget(etiket);
    orta->addWidget(kutu, 1);
    auto *ana = new QVBoxLayout(&d);
    ana->setContentsMargins(14, 16, 12, 12);
    ana->setSpacing(14);
    ana->addLayout(ust);
    ana->addLayout(orta);
    ana->addSpacing(6);
    ana->addLayout(dugmeler);
    d.setFixedSize(398, 175);

    QObject::connect(gozat, &QPushButton::clicked, &d, [&] {
        const QString f = QFileDialog::getOpenFileName(&d, QStringLiteral("Gözat"), QDir::homePath(),
                                                       QStringLiteral("Programlar (*.desktop *.sh *.AppImage);;Tüm Dosyalar (*)"));
        if (!f.isEmpty())
            kutu->setEditText(f.contains(QLatin1Char(' ')) ? QLatin1Char('"') + f + QLatin1Char('"') : f);
    });
    QObject::connect(iptal, &QPushButton::clicked, &d, &QDialog::reject);
    QObject::connect(tamam, &QPushButton::clicked, &d, [&] {
        const QString girilen = kutu->currentText().trimmed();
        if (girilen.isEmpty())
            return;
        QString yol = girilen;
        if (yol.startsWith(QLatin1Char('"')) && yol.endsWith(QLatin1Char('"')))
            yol = yol.mid(1, yol.size() - 2);
        if (yol.startsWith(QLatin1Char('~')))
            yol = QDir::homePath() + yol.mid(1);
        const bool url = girilen.contains(QStringLiteral("://")) || girilen.startsWith(QStringLiteral("www."));
        bool basarili = false;
        if (url || QFileInfo::exists(yol)) {
            QUrl u = url ? QUrl::fromUserInput(girilen) : QUrl::fromLocalFile(yol);
            if (!url && QFileInfo(yol).isExecutable() && !QFileInfo(yol).isDir()) {
                auto *job = new KIO::CommandLauncherJob(yol, {});
                job->exec();
            } else {
                auto *job = new KIO::OpenUrlJob(u);
                job->exec();
            }
            basarili = true;
        } else {
            QString komut = windowsKarsiligi(girilen);
            if (komut.isEmpty()) {
                const QString ilk = girilen.section(QLatin1Char(' '), 0, 0);
                if (!QStandardPaths::findExecutable(ilk).isEmpty())
                    komut = girilen;
                else if (auto s = KService::serviceByDesktopName(ilk.toLower()))
                    komut = s->exec().section(QLatin1Char(' '), 0, 0) + girilen.mid(ilk.size());
            }
            if (!komut.isEmpty()) {
                auto *job = new KIO::CommandLauncherJob(komut);
                job->exec();
                basarili = true;
            }
        }
        if (!basarili) {
            QMessageBox m(QMessageBox::Critical, girilen,
                          QStringLiteral("Windows '%1' öğesini bulamıyor. Yazımı denetleyin ve yeniden deneyin.").arg(girilen),
                          QMessageBox::Ok, &d);
            m.button(QMessageBox::Ok)->setText(QStringLiteral("Tamam"));
            m.exec();
            kutu->lineEdit()->selectAll();
            return;
        }
        gecmisYaz(girilen);
        d.accept();
    });

    d.show();
    kutu->setFocus();
    QObject::connect(&d, &QDialog::finished, &app, [&app](int) { QMetaObject::invokeMethod(&app, &QApplication::quit, Qt::QueuedConnection); });
    return app.exec();
}
