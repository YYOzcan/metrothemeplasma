#include "kabuk.h"
#include "../../ortak/metroceviri.h"

#include <KGlobalAccel>
#include <QAction>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QTimer>
#include <QDebug>

Kabuk::Kabuk(QObject *parent)
    : QObject(parent)
{
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Kabuk"), this, QDBusConnection::ExportScriptableSlots);

    // Windows tuşu tek başına (KWin 6.8: yalnız değiştirici tuş kısayolları KGlobalAccel'de "Meta") + Ctrl+Esc.
    // Windows'ta değiştirilemez; kayıtlı eski değer (yalnız Ctrl+Esc) varsa ezilir.
    connect(kisayol(QStringLiteral("baslangic"), mtr(QStringLiteral("Başlangıç ekranı")), {QKeySequence(Qt::Key_Meta), Qt::CTRL | Qt::Key_Escape}, true),
            &QAction::triggered, this, &Kabuk::Baslangic);
    connect(kisayol(QStringLiteral("tilsimlar"), mtr(QStringLiteral("Tılsımlar")), {Qt::META | Qt::Key_C}),
            &QAction::triggered, this, &Kabuk::Tilsimlar);
    connect(kisayol(QStringLiteral("ara"), QStringLiteral("Her yerde ara"), {Qt::META | Qt::Key_S, Qt::META | Qt::Key_Q}),
            &QAction::triggered, this, [this] { Ara(QString()); });
    connect(kisayol(QStringLiteral("ara-dosyalar"), QStringLiteral("Dosyalarda ara"), {Qt::META | Qt::Key_F}),
            &QAction::triggered, this, [this] { Ara(QStringLiteral("dosyalar")); });
    connect(kisayol(QStringLiteral("ara-ayarlar"), QStringLiteral("Ayarlarda ara"), {Qt::META | Qt::Key_W}),
            &QAction::triggered, this, [this] { Ara(QStringLiteral("ayarlar")); });
    connect(kisayol(QStringLiteral("ayarlar"), mtr(QStringLiteral("Ayarlar tılsımı")), {Qt::META | Qt::Key_I}),
            &QAction::triggered, this, &Kabuk::Ayarlar);
    connect(kisayol(QStringLiteral("aygitlar"), mtr(QStringLiteral("Aygıtlar tılsımı")), {Qt::META | Qt::Key_K}),
            &QAction::triggered, this, &Kabuk::Aygitlar);
    connect(kisayol(QStringLiteral("paylas"), mtr(QStringLiteral("Paylaş tılsımı")), {Qt::META | Qt::Key_H}),
            &QAction::triggered, this, &Kabuk::Paylas);
    connect(kisayol(QStringLiteral("guc-menusu"), mtr(QStringLiteral("Hızlı bağlantı menüsü")), {Qt::META | Qt::Key_X}),
            &QAction::triggered, this, [this] { GucMenusu(-1, -1); });
    connect(kisayol(QStringLiteral("gecis"), mtr(QStringLiteral("Uygulamalar arasında geçiş yap")), {Qt::META | Qt::Key_Tab}),
            &QAction::triggered, this, &Kabuk::Gecis);
    connect(kisayol(QStringLiteral("dosya-gezgini"), QStringLiteral("Dosya Gezgini"), {Qt::META | Qt::Key_E}),
            &QAction::triggered, this, [this] { Q_EMIT gezginIste(); });
    connect(kisayol(QStringLiteral("calistir"), mtr(QStringLiteral("Çalıştır")), {Qt::META | Qt::Key_R}),
            &QAction::triggered, this, [this] { Q_EMIT calistirIste(); });
    connect(kisayol(QStringLiteral("gorev-yoneticisi"), mtr(QStringLiteral("Görev Yöneticisi")), {Qt::CTRL | Qt::SHIFT | Qt::Key_Escape}),
            &QAction::triggered, this, [this] { Q_EMIT gorevYoneticisiIste(); });
    connect(kisayol(QStringLiteral("ekran-goruntusu"), mtr(QStringLiteral("Ekran görüntüsü al ve kaydet")), {Qt::META | Qt::Key_Print}),
            &QAction::triggered, this, &Kabuk::EkranGoruntusu);
}

QAction *Kabuk::kisayol(const QString &ad, const QString &metin, const QList<QKeySequence> &tuslar, bool zorla)
{
    auto *a = new QAction(metin, this);
    a->setObjectName(ad);
    a->setProperty("componentName", QStringLiteral("metro-kabuk"));
    a->setProperty("componentDisplayName", mtr(QStringLiteral("Metro Kabuğu")));
    KGlobalAccel::self()->setDefaultShortcut(a, tuslar);
    if (!KGlobalAccel::self()->setShortcut(a, tuslar, zorla ? KGlobalAccel::NoAutoloading : KGlobalAccel::Autoloading))
        qWarning() << "kısayol alınamadı (başka bileşende):" << ad << tuslar;
    return a;
}

void Kabuk::Baslangic() { Q_EMIT baslangicIste(0); }
void Kabuk::BaslangicAc() { Q_EMIT baslangicIste(1); }
void Kabuk::BaslangicKapat() { Q_EMIT baslangicIste(2); }
void Kabuk::Uygulamalar() { Q_EMIT baslangicIste(3); }
void Kabuk::Tilsimlar() { Q_EMIT tilsimIste(); }
void Kabuk::TilsimIpucu(int kose) { Q_EMIT tilsimIpucuIste(kose); }
void Kabuk::Ara(const QString &kapsam) { Q_EMIT araIste(kapsam); }
void Kabuk::Ayarlar() { Q_EMIT ayarlarIste(); }
void Kabuk::Aygitlar() { Q_EMIT aygitlarIste(); }
void Kabuk::Paylas() { Q_EMIT paylasIste(); }
void Kabuk::GucMenusu(int x, int y) { Q_EMIT gucMenusuIste(x, y); }
void Kabuk::Gecis() { Q_EMIT gecisIste(); }
void Kabuk::SolUstKose() { Q_EMIT solUstKoseIste(); }
void Kabuk::SolAltKose() { Q_EMIT solAltKoseIste(); }
void Kabuk::EkranGoruntusu() { Q_EMIT ekranGoruntusuIste(); }
void Kabuk::Kisisellestir() { Q_EMIT kisisellestirIste(); }
void Kabuk::BilgisayarAyarlari(const QString &sayfa) { Q_EMIT bilgisayarAyarlariIste(sayfa); }
void Kabuk::Bolme(const QString &tur) { Q_EMIT bolmeIste(tur); }
void Kabuk::AraMetin(const QString &metin) { Q_EMIT araMetinIste(metin); }
void Kabuk::BaslangicaSabitle(const QString &yol) { Q_EMIT sabitleIste(yol); }
void Kabuk::IlkOturum() { Q_EMIT ilkOturumIste(); }
void Kabuk::OtomatikKullanPaneli(const QString &yol) { Q_EMIT otomatikPanelSinaIste(yol); }
void Kabuk::KapatmaEngeli(const QString &tur) { Q_EMIT kapatmaEngeliSinaIste(tur); }
void Kabuk::GorevYoneticisi() { Q_EMIT gorevYoneticisiIste(); }

// Windows görev çubuğu menüsü: Pencereleri basamakla / üst üste göster / yan yana göster (user32 CascadeWindows,
// TileWindows) ve "Geri Al". KWin betiğiyle: etkin ekranın çalışma alanında, bu masaüstündeki küçültülmemiş
// normal pencereler; önceki konumlar betik içinde (workspace üzerinde) saklanır.
void Kabuk::PencereDuzeni(const QString &tur)
{
    static const char *betik = R"JS(
const tur = "%1";
const ekran = workspace.activeScreen;
const alan = workspace.clientArea(KWin.MaximizeArea, ekran, workspace.currentDesktop);
const pen = workspace.stackingOrder.filter(w => w.normalWindow && !w.minimized && !w.skipTaskbar
    && w.moveable && w.resizeable && w.output === ekran
    && (w.onAllDesktops || w.desktops.indexOf(workspace.currentDesktop) >= 0));
if (tur === "geri") {
    const eski = %2;
    for (const w of workspace.stackingOrder) {
        const k = eski.find(e => e.id === String(w.internalId));
        if (k) w.frameGeometry = { x: k.x, y: k.y, width: k.width, height: k.height };
    }
} else if (pen.length) {
    // önceki konumlar metro-kabuk'ta saklanır ("Geri Al")
    callDBus("io.github.yyozcan.MetroKabuk", "/Kabuk", "io.github.yyozcan.MetroKabuk", "PencereDuzeniKaydet",
             JSON.stringify(pen.map(w => ({ id: String(w.internalId), x: w.frameGeometry.x, y: w.frameGeometry.y,
                                             width: w.frameGeometry.width, height: w.frameGeometry.height }))));
    const n = pen.length;
    const yerlestir = (w, x, y, g, y2) => {
        w.setMaximize(false, false);
        w.frameGeometry = { x: Math.round(x), y: Math.round(y), width: Math.round(g), height: Math.round(y2) };
    };
    if (tur === "basamak") {
        // en alttaki pencere sol üstte, etkin pencere en önde; her adım başlık çubuğu yüksekliği kadar
        const adim = 30;
        const g = Math.max(320, alan.width * 0.6), y = Math.max(240, alan.height * 0.6);
        const sigan = Math.max(1, Math.floor(Math.min((alan.width - g) / adim, (alan.height - y) / adim)) + 1);
        pen.forEach((w, i) => yerlestir(w, alan.x + (i % sigan) * adim, alan.y + (i % sigan) * adim, g, y));
    } else {
        // TileWindows: üst üste = satırlar, yan yana = sütunlar; 3'ten çoksa ızgara
        const yatay = tur === "ustuste";
        const ana = n <= 3 ? n : Math.ceil(Math.sqrt(n));
        const yan = Math.ceil(n / ana);
        pen.forEach((w, i) => {
            const a = i % ana, b = Math.floor(i / ana);
            const sonSutun = b === yan - 1 ? n - b * ana : ana;
            if (yatay) {
                const h = alan.height / Math.min(ana, n), gw = alan.width / yan;
                yerlestir(w, alan.x + b * gw, alan.y + a * (alan.height / sonSutun), gw, alan.height / sonSutun);
            } else {
                const gw = alan.width / sonSutun, h = alan.height / yan;
                yerlestir(w, alan.x + a * gw, alan.y + b * h, gw, h);
            }
        });
    }
}
)JS";
    const QString dizin = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    const QString yol = dizin + QStringLiteral("/metro-pencere-duzeni.js");
    QFile f(yol);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    f.write(QString::fromUtf8(betik).arg(tur, m_oncekiDuzen).toUtf8());
    f.close();
    const QString ad = QStringLiteral("metro-pencere-duzeni");
    QDBusInterface kwin(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting"), QStringLiteral("org.kde.kwin.Scripting"));
    kwin.call(QStringLiteral("unloadScript"), ad);
    const QDBusReply<int> kimlik = kwin.call(QStringLiteral("loadScript"), yol, ad);
    if (!kimlik.isValid() || kimlik.value() < 0)
        return;
    QDBusInterface calis(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting/Script%1").arg(kimlik.value()),
                         QStringLiteral("org.kde.kwin.Script"));
    calis.call(QStringLiteral("run"));
    QTimer::singleShot(2000, this, [ad] {
        QDBusInterface k(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting"), QStringLiteral("org.kde.kwin.Scripting"));
        k.call(QStringLiteral("unloadScript"), ad);
    });
}
void Kabuk::YenidenYukle() { Q_EMIT yenidenYukleIste(); }
