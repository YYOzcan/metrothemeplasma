/*  This file is part of the KDE project
    SPDX-FileCopyrightText: 2021 Aleix Pol Gonzalez <aleixpol@kde.org>
    SPDX-FileCopyrightText: 2023 Devin Lin <devin@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
#include "QuickAuthDialog.h"
#include "IdentitiesModel.h"
#include "config.h"

#include <PolkitQt1/Authority>

#include <KConfigGroup>
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <KNotification>
#include <KRuntimePlatform>
#include <KUser>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QStandardPaths>
#include <QQmlApplicationEngine>
#include <QQuickImageProvider>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

// simge teması adı -> resim (eylemin simgesi, ör. "gparted")
class SimgeSaglayici : public QQuickImageProvider
{
public:
    SimgeSaglayici()
        : QQuickImageProvider(QQuickImageProvider::Pixmap)
    {
    }
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &istenen) override
    {
        const int b = istenen.width() > 0 ? istenen.width() : 32;
        QPixmap p = QIcon::fromTheme(id).pixmap(b, b);
        if (size)
            *size = p.size();
        return p;
    }
};

// İsteği yapan program (Windows'taki "Program adı"): polkit yalnızca süreç kimliğini verir.
// pkexec ise çalıştırılacak program onun argümanıdır; .desktop girdisi varsa görünen ad ve simge oradan.
static QVariantMap programBilgisi(const PolkitQt1::Details &details, const QString &ileti)
{
    QVariantMap m;
    // pkexec: yetkiyi soran (caller) pkexec'in kendisi, özne (subject) onun üst süreci
    auto surec = [](const QString &pid, QStringList &arg, QString &exe) {
        arg.clear();
        exe.clear();
        if (pid.isEmpty())
            return;
        QFile f(QStringLiteral("/proc/%1/cmdline").arg(pid));
        if (f.open(QIODevice::ReadOnly))
            for (const QByteArray &p : f.readAll().split('\0'))
                if (!p.isEmpty())
                    arg << QString::fromLocal8Bit(p);
        exe = QFileInfo(QStringLiteral("/proc/%1/exe").arg(pid)).symLinkTarget();
    };
    QStringList arg;
    QString exe;
    surec(details.lookup(QStringLiteral("polkit.caller-pid")), arg, exe);
    const bool pkexecMi = QFileInfo(exe).fileName() == QLatin1String("pkexec") || (!arg.isEmpty() && QFileInfo(arg.first()).fileName() == QLatin1String("pkexec"));
    if (!pkexecMi || arg.isEmpty()) {
        QStringList a2;
        QString e2;
        surec(details.lookup(QStringLiteral("polkit.subject-pid")), a2, e2);
        if (!a2.isEmpty() || !e2.isEmpty()) {
            arg = a2;
            exe = e2;
        }
    }
    QString program = exe.isEmpty() ? arg.value(0) : exe;
    QStringList komut = arg;
    if (pkexecMi) {
        int i = 1;
        while (i < arg.size() && arg[i].startsWith(QLatin1Char('-'))) {
            if (arg[i] == QLatin1String("--user") || arg[i] == QLatin1String("-u"))
                ++i;
            ++i;
        }
        komut = arg.mid(i);
        program = komut.value(0);
        if (!program.isEmpty() && !program.contains(QLatin1Char('/')))
            program = QStandardPaths::findExecutable(program);
    }
    // son çare: iletideki `…' (pkexec iletisi)
    if (program.isEmpty()) {
        const int a = ileti.indexOf(QLatin1Char('`')), b = ileti.indexOf(QLatin1Char('\''), a + 1);
        if (a >= 0 && b > a)
            program = ileti.mid(a + 1, b - a - 1);
    }
    if (program.isEmpty())
        return m;
    m.insert(QStringLiteral("program"), program);
    m.insert(QStringLiteral("command_line"), komut.isEmpty() ? program : komut.join(QLatin1Char(' ')));
    const QString temel = QFileInfo(program).fileName();
    m.insert(QStringLiteral("programAdi"), temel);
    // .desktop: önce aynı adlı, sonra Exec'i bu program olan
    QStringList dizinler = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    for (const QString &d : std::as_const(dizinler)) {
        const QFileInfoList dosyalar = QDir(d).entryInfoList({QStringLiteral("*.desktop")}, QDir::Files);
        for (const QFileInfo &fi : dosyalar) {
            QFile f(fi.absoluteFilePath());
            if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
                continue;
            QString ad, adTr, simge, exec;
            bool girdi = false;
            while (!f.atEnd()) {
                const QString satir = QString::fromUtf8(f.readLine()).trimmed();
                if (satir.startsWith(QLatin1Char('[')))
                    girdi = satir == QLatin1String("[Desktop Entry]");
                else if (girdi && satir.startsWith(QLatin1String("Name=")))
                    ad = satir.mid(5);
                else if (girdi && satir.startsWith(QLatin1String("Name[tr]=")))
                    adTr = satir.mid(9);
                else if (girdi && satir.startsWith(QLatin1String("Icon=")))
                    simge = satir.mid(5);
                else if (girdi && satir.startsWith(QLatin1String("Exec=")))
                    exec = satir.mid(5);
            }
            const QString ilk = exec.section(QLatin1Char(' '), 0, 0).remove(QLatin1Char('"'));
            if (fi.completeBaseName() == temel || ilk == program || QFileInfo(ilk).fileName() == temel) {
                m.insert(QStringLiteral("programAdi"), adTr.isEmpty() ? ad : adTr);
                if (!simge.isEmpty())
                    m.insert(QStringLiteral("programSimge"), simge);
                return m;
            }
        }
    }
    return m;
}

QuickAuthDialog::QuickAuthDialog(const QString &actionId,
                                 const QString &message,
                                 const PolkitQt1::Details &details,
                                 const PolkitQt1::Identity::List &identities)
    : QObject(nullptr)
    , m_actionId(actionId)
    , m_config("uacpolkitagentrc")
{
    auto engine = new QQmlApplicationEngine(this);
    engine->addImageProvider(QStringLiteral("icon"), new SimgeSaglayici);
    // polkit ayrıntıları (pkexec: program, command_line): "Program adı" / "Program konumu"
    QVariantMap ayrintilar;
    const QStringList anahtarlar = details.keys();
    for (const QString &k : anahtarlar)
        ayrintilar.insert(k, details.lookup(k));
    const QVariantMap pb = programBilgisi(details, message);
    for (auto it = pb.cbegin(); it != pb.cend(); ++it)
        if (!ayrintilar.contains(it.key()))
            ayrintilar.insert(it.key(), it.value());
#ifdef METRO_UAC_SINAMA
    qWarning() << "SINAMA eylem" << actionId << "ayrintilar" << ayrintilar << "ileti" << message;
#endif
    QVariantMap props = {
        {"mainText", message},
        {"ayrintilar", ayrintilar},
    };

    const auto actions = PolkitQt1::Authority::instance()->enumerateActionsSync();
    for (const PolkitQt1::ActionDescription &desc : actions) {
        if (actionId == desc.actionId()) {
            qDebug() << "Action description has been found";
            props.insert("descriptionString", desc.description());
            props.insert("descriptionActionId", desc.actionId());
            props.insert("descriptionVendorName", desc.vendorName());
            props.insert("descriptionVendorUrl", desc.vendorUrl());
            props.insert("descriptionIcon", desc.iconName());
            break;
        }
    }

    engine->setInitialProperties(props);
    engine->rootContext()->setContextObject(new KLocalizedQmlContext(engine));

    // Windows 8.1 diyaloğu; yüklenemezse (ör. eksik QML modülü) AeroThemePlasma'nın Windows 7 diyaloğu —
    // kimlik doğrulama hiçbir zaman diyalogsuz kalmasın
    engine->load(QStringLiteral("qrc:/qml/MetroUac.qml"));
    if (engine->rootObjects().isEmpty()) {
        qWarning() << "MetroUac.qml yüklenemedi; Windows 7 diyaloğuna dönülüyor";
        props.remove(QStringLiteral("ayrintilar"));
        engine->setInitialProperties(props);
        engine->load(QStringLiteral("qrc:/qml/QuickAuthDialog.qml"));
    }

    m_theDialog = qobject_cast<QQuickWindow *>(engine->rootObjects().constFirst());

    auto idents = qobject_cast<IdentitiesModel *>(m_theDialog->property("identitiesModel").value<QObject *>());
    idents->setIdentities(identities, false);
    if (!identities.isEmpty()) {
        int initialIndex = std::max(0, idents->indexForUser(KUser().loginName()));
        m_theDialog->setProperty("identitiesCurrentIndex", initialIndex);
    }

    // listen for dialog accept/reject
    connect(m_theDialog, SIGNAL(accept()), this, SIGNAL(okClicked()));
    connect(m_theDialog, SIGNAL(reject()), this, SIGNAL(rejected()));
    connect(m_theDialog, SIGNAL(userSelected()), this, SIGNAL(userSelected()));
}

enum KirigamiInlineMessageTypes { Information = 0, Positive = 1, Warning = 2, Error = 3 };

QString QuickAuthDialog::actionId() const
{
    return m_actionId;
}

QString QuickAuthDialog::password() const
{
    return m_theDialog->property("password").toString();
}

void QuickAuthDialog::showError(const QString &message)
{
    m_theDialog->setProperty("inlineMessageType", Error);
    m_theDialog->setProperty("inlineMessageText", message);
}

void QuickAuthDialog::showInfo(const QString &message)
{
    m_theDialog->setProperty("inlineMessageType", Information);
    m_theDialog->setProperty("inlineMessageText", message);
}

PolkitQt1::Identity QuickAuthDialog::adminUserSelected() const
{
    return PolkitQt1::Identity::fromString(m_theDialog->property("selectedIdentity").toString());
}

void QuickAuthDialog::authenticationFailure()
{
    QTimer::singleShot(0, m_theDialog, SLOT(authenticationFailure()));
}

void QuickAuthDialog::show()
{
    // Windows 8.1 diyaloğu önce ekranı karartır (goster); Windows 7 diyaloğunda düz show
    QTimer::singleShot(0, m_theDialog, [this] {
        if (!QMetaObject::invokeMethod(m_theDialog, "goster"))
            m_theDialog->show();
#ifdef METRO_UAC_SINAMA
        // yalnızca sınama derlemesi (kurulmaz): iç içe oturumda parolayı yazmadan uçtan uca dene
        const QString p = qEnvironmentVariable("METRO_UAC_SINAMA_PAROLA");
        if (!p.isEmpty())
            QTimer::singleShot(2500, m_theDialog, [this, p] {
                m_theDialog->setProperty("password", p);
                QMetaObject::invokeMethod(m_theDialog, "accept");
            });
#endif
    });
}

void QuickAuthDialog::hide()
{
    QTimer::singleShot(0, m_theDialog, SLOT(hide()));
}

void QuickAuthDialog::request([[maybe_unused]] const QString &request, [[maybe_unused]] bool echo)
{
    QTimer::singleShot(0, m_theDialog, SLOT(request()));
}

#include "moc_QuickAuthDialog.cpp"
