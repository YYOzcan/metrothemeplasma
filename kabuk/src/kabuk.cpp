#include "kabuk.h"

#include <KGlobalAccel>
#include <QAction>
#include <QDBusConnection>
#include <QDebug>

Kabuk::Kabuk(QObject *parent)
    : QObject(parent)
{
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Kabuk"), this, QDBusConnection::ExportScriptableSlots);

    // Windows tuşu tek başına (KWin 6.8: yalnız değiştirici tuş kısayolları KGlobalAccel'de "Meta") + Ctrl+Esc.
    // Windows'ta değiştirilemez; kayıtlı eski değer (yalnız Ctrl+Esc) varsa ezilir.
    connect(kisayol(QStringLiteral("baslangic"), QStringLiteral("Başlangıç ekranı"), {QKeySequence(Qt::Key_Meta), Qt::CTRL | Qt::Key_Escape}, true),
            &QAction::triggered, this, &Kabuk::Baslangic);
    connect(kisayol(QStringLiteral("tilsimlar"), QStringLiteral("Tılsımlar"), {Qt::META | Qt::Key_C}),
            &QAction::triggered, this, &Kabuk::Tilsimlar);
    connect(kisayol(QStringLiteral("ara"), QStringLiteral("Her yerde ara"), {Qt::META | Qt::Key_S, Qt::META | Qt::Key_Q}),
            &QAction::triggered, this, [this] { Ara(QString()); });
    connect(kisayol(QStringLiteral("ara-dosyalar"), QStringLiteral("Dosyalarda ara"), {Qt::META | Qt::Key_F}),
            &QAction::triggered, this, [this] { Ara(QStringLiteral("dosyalar")); });
    connect(kisayol(QStringLiteral("ara-ayarlar"), QStringLiteral("Ayarlarda ara"), {Qt::META | Qt::Key_W}),
            &QAction::triggered, this, [this] { Ara(QStringLiteral("ayarlar")); });
    connect(kisayol(QStringLiteral("ayarlar"), QStringLiteral("Ayarlar tılsımı"), {Qt::META | Qt::Key_I}),
            &QAction::triggered, this, &Kabuk::Ayarlar);
    connect(kisayol(QStringLiteral("aygitlar"), QStringLiteral("Aygıtlar tılsımı"), {Qt::META | Qt::Key_K}),
            &QAction::triggered, this, &Kabuk::Aygitlar);
    connect(kisayol(QStringLiteral("paylas"), QStringLiteral("Paylaş tılsımı"), {Qt::META | Qt::Key_H}),
            &QAction::triggered, this, &Kabuk::Paylas);
    connect(kisayol(QStringLiteral("guc-menusu"), QStringLiteral("Hızlı bağlantı menüsü"), {Qt::META | Qt::Key_X}),
            &QAction::triggered, this, [this] { GucMenusu(-1, -1); });
    connect(kisayol(QStringLiteral("gecis"), QStringLiteral("Uygulamalar arasında geçiş yap"), {Qt::META | Qt::Key_Tab}),
            &QAction::triggered, this, &Kabuk::Gecis);
    connect(kisayol(QStringLiteral("calistir"), QStringLiteral("Çalıştır"), {Qt::META | Qt::Key_R}),
            &QAction::triggered, this, [this] { Q_EMIT calistirIste(); });
    connect(kisayol(QStringLiteral("gorev-yoneticisi"), QStringLiteral("Görev Yöneticisi"), {Qt::CTRL | Qt::SHIFT | Qt::Key_Escape}),
            &QAction::triggered, this, [this] { Q_EMIT gorevYoneticisiIste(); });
    connect(kisayol(QStringLiteral("ekran-goruntusu"), QStringLiteral("Ekran görüntüsü al ve kaydet"), {Qt::META | Qt::Key_Print}),
            &QAction::triggered, this, &Kabuk::EkranGoruntusu);
}

QAction *Kabuk::kisayol(const QString &ad, const QString &metin, const QList<QKeySequence> &tuslar, bool zorla)
{
    auto *a = new QAction(metin, this);
    a->setObjectName(ad);
    a->setProperty("componentName", QStringLiteral("metro-kabuk"));
    a->setProperty("componentDisplayName", QStringLiteral("Metro Kabuğu"));
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
void Kabuk::YenidenYukle() { Q_EMIT yenidenYukleIste(); }
