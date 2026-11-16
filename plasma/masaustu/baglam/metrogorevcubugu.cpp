// MetroThemePlasma görev çubuğu sağ tık menüsü (Windows 8.1 explorer.exe.mui MENU 205):
//   Pencereleri basamakla · Pencereleri üst üste göster · Pencereleri yan yana göster · Masaüstünü göster
//   [Geri Al …] │ Görev Yöneticisi │ Görev çubuğunu kilitle · Özellikler
// Pencere düzeni ve Görev Yöneticisi metro-kabuk'ta (DBus); kilit = Plasma'nın parçacık kilidi.
#include <Plasma/Containment>
#include <Plasma/ContainmentActions>
#include <Plasma/Corona>

#include <KPluginFactory>
#include <KWindowSystem>

#include <QAction>
#include <QDBusConnection>
#include <QDBusMessage>

class MetroGorevCubugu : public Plasma::ContainmentActions
{
    Q_OBJECT
public:
    MetroGorevCubugu(QObject *ust, const QVariantList &args)
        : Plasma::ContainmentActions(ust, args)
    {
        auto ekle = [this](const QString &metin, auto islev) {
            auto *a = new QAction(metin, this);
            connect(a, &QAction::triggered, this, islev);
            return a;
        };
        auto ayrac = [this] {
            auto *a = new QAction(this);
            a->setSeparator(true);
            return a;
        };
        m_basamak = ekle(QStringLiteral("&Pencereleri basamakla"), [this] { duzen(QStringLiteral("basamak"), QStringLiteral("Basamakla")); });
        m_ustuste = ekle(QStringLiteral("Pen&cereleri üst üste göster"), [this] { duzen(QStringLiteral("ustuste"), QStringLiteral("Üst Üste Göster")); });
        m_yanyana = ekle(QStringLiteral("Pencereleri yan yana g&öster"), [this] { duzen(QStringLiteral("yanyana"), QStringLiteral("Yan Yana Göster")); });
        m_masaustu = ekle(QStringLiteral("Masaüstünü göst&er"), [] { KWindowSystem::setShowingDesktop(!KWindowSystem::showingDesktop()); });
        m_geri = ekle(QStringLiteral("Geri &Al"), [this] {
            kabuk(QStringLiteral("PencereDuzeni"), {QStringLiteral("geri")});
            m_geriMetin.clear();
        });
        m_ayrac1 = ayrac();
        m_gorev = ekle(QStringLiteral("&Görev Yöneticisi"), [this] { kabuk(QStringLiteral("GorevYoneticisi")); });
        m_ayrac2 = ayrac();
        m_kilit = ekle(QStringLiteral("Görev çubuğun&u kilitle"), [this] {
            if (Plasma::Corona *c = containment() ? containment()->corona() : nullptr)
                c->setImmutability(c->immutability() == Plasma::Types::Mutable ? Plasma::Types::UserImmutable : Plasma::Types::Mutable);
        });
        m_kilit->setCheckable(true);
        m_ozellikler = ekle(QStringLiteral("Ö&zellikler"), [this] { kabuk(QStringLiteral("BilgisayarAyarlari"), {QStringLiteral("gezinti")}); });
    }

    QList<QAction *> contextualActions() override
    {
        // Windows: masaüstü gösterilirken "Açık pencereleri göster"
        m_masaustu->setText(KWindowSystem::showingDesktop() ? QStringLiteral("Açık pencereleri göst&er") : QStringLiteral("Masaüstünü göst&er"));
        m_geri->setVisible(!m_geriMetin.isEmpty());
        m_geri->setText(QStringLiteral("Geri &Al ") + m_geriMetin);
        Plasma::Corona *c = containment() ? containment()->corona() : nullptr;
        m_kilit->setChecked(c && c->immutability() != Plasma::Types::Mutable);
        m_kilit->setEnabled(c && c->immutability() != Plasma::Types::SystemImmutable);
        return {m_basamak, m_ustuste, m_yanyana, m_masaustu, m_geri, m_ayrac1, m_gorev, m_ayrac2, m_kilit, m_ozellikler};
    }

private:
    void duzen(const QString &tur, const QString &ad)
    {
        kabuk(QStringLiteral("PencereDuzeni"), {tur});
        m_geriMetin = ad;
    }
    static void kabuk(const QString &yontem, const QVariantList &args = {})
    {
        QDBusMessage m = QDBusMessage::createMethodCall(QStringLiteral("io.github.yyozcan.MetroKabuk"), QStringLiteral("/Kabuk"),
                                                        QStringLiteral("io.github.yyozcan.MetroKabuk"), yontem);
        m.setArguments(args);
        QDBusConnection::sessionBus().send(m);
    }

    QAction *m_basamak, *m_ustuste, *m_yanyana, *m_masaustu, *m_geri, *m_ayrac1, *m_gorev, *m_ayrac2, *m_kilit, *m_ozellikler;
    QString m_geriMetin;
};

K_PLUGIN_CLASS_WITH_JSON(MetroGorevCubugu, "metrogorevcubugu.json")

#include "metrogorevcubugu.moc"
