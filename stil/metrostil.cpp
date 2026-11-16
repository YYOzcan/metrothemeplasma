// MetroThemePlasma Qt stili ("metro"): Kvantum Metro'nun üstüne ince bir QProxyStyle.
// Menüleri Windows 8.1'in aero.msstyles MENU sınıfındaki değerlerle kendisi çizer (Kvantum'da simge oluğu,
// oluk çizgisi, onay zemini ve Windows ölçüleri yoktur); geri kalan her şey Kvantum'a bırakılır.
//
// msstyles MENU (ISO): POPUPBACKGROUND #F0F0F0, POPUPBORDERS 1 px #979797, POPUPGUTTER sağında 1 px #D7D7D7,
// POPUPITEM üzerinde: kenar rgba(0,107,217,128) + dolgu rgba(0,131,255,33) (#F0F0F0 üstünde #78AEE4/#D1E2F2),
// devre dışı-üzerinde: rgba(107,107,107,128) + rgba(123,123,123,33), yazı #000000, devre dışı #6D6D6D,
// POPUPSEPARATOR 1 px #D7D7D7, POPUPCHECKBACKGROUND gri #DADADA / mavi #26A0DA kenarlı yarı saydam kare.
// Geometri Windows menülerininki: kenar 1 + iç boşluk 2, öğe 22 px, ayraç 7 px, simge 16 px, oluk 28 px,
// yazı 33 px'ten; sağda alt menü oku. Gölge: KWindowShadow (KWin çizer).
#include <QApplication>
#include <QMenu>
#include <QPainter>
#include <QPainterPath>
#include <QPointer>
#include <QProxyStyle>
#include <QStyleFactory>
#include <QStyleOption>
#include <QStylePlugin>
#include <QWindow>

#include <KWindowShadow>

namespace
{
const QColor ZEMIN(0xF0, 0xF0, 0xF0);
const QColor KENAR(0x97, 0x97, 0x97);
const QColor OLUK(0xD7, 0xD7, 0xD7);
const QColor YAZI(0x00, 0x00, 0x00);
const QColor SOLUK(0x6D, 0x6D, 0x6D);

constexpr int CERCEVE = 1;      // POPUPBORDERS
constexpr int IC = 2;           // kenar ile öğeler arası
constexpr int OGE = 22;         // öğe yüksekliği
constexpr int AYRAC = 7;        // ayraç yüksekliği
constexpr int OLUK_GEN = 28;    // simge oluğu (menü kenarından)
constexpr int YAZI_X = 33;      // yazının başladığı x (menü kenarından)
constexpr int SAG = 30;         // sağ boşluk (alt menü oku dahil)
}

class MetroStil : public QProxyStyle
{
public:
    explicit MetroStil(QStyle *taban)
        : QProxyStyle(taban)
    {
    }

    // ------------------------------------------------------------------ menüler Kvantum'a bırakılmaz
    void polish(QWidget *w) override
    {
        if (auto *m = qobject_cast<QMenu *>(w)) {
            // Kvantum'un saydam gölge kenarlarını ve kenar boşluklarını uygulama; düz Windows menüsü
            m->setAttribute(Qt::WA_TranslucentBackground, false);
            m->setContentsMargins(0, 0, 0, 0);
            m->installEventFilter(golgeYonetici());
            return;
        }
        QProxyStyle::polish(w);
    }
    void unpolish(QWidget *w) override
    {
        if (qobject_cast<QMenu *>(w)) {
            w->removeEventFilter(golgeYonetici());
            return;
        }
        QProxyStyle::unpolish(w);
    }
    using QProxyStyle::polish;
    using QProxyStyle::unpolish;

    int pixelMetric(PixelMetric m, const QStyleOption *o = nullptr, const QWidget *w = nullptr) const override
    {
        switch (m) {
        case PM_MenuPanelWidth:
            return CERCEVE;
        case PM_MenuHMargin:
        case PM_MenuVMargin:
            return IC;
        case PM_MenuDesktopFrameWidth:
            return 0;
        case PM_SubMenuOverlap:
            return -3;
        case PM_MenuScrollerHeight:
            return 16;
        default:
            break;
        }
        return QProxyStyle::pixelMetric(m, o, w);
    }

    int styleHint(StyleHint h, const QStyleOption *o = nullptr, const QWidget *w = nullptr, QStyleHintReturn *r = nullptr) const override
    {
        switch (h) {
        case SH_Menu_SubMenuPopupDelay:
            return 400;     // Windows SPI_GETMENUSHOWDELAY
        case SH_Menu_AllowActiveAndDisabled:
            return 1;       // devre dışı öğe de gri vurgulanır
        case SH_Menu_MouseTracking:
        case SH_Menu_SubMenuSloppyCloseTimeout:
            return h == SH_Menu_MouseTracking ? 1 : 400;
        case SH_Menu_Scrollable:
            return 1;
        default:
            break;
        }
        return QProxyStyle::styleHint(h, o, w, r);
    }

    QSize sizeFromContents(ContentsType t, const QStyleOption *o, const QSize &s, const QWidget *w = nullptr) const override
    {
        if (t == CT_MenuItem) {
            const auto *mi = qstyleoption_cast<const QStyleOptionMenuItem *>(o);
            if (!mi)
                return QProxyStyle::sizeFromContents(t, o, s, w);
            if (mi->menuItemType == QStyleOptionMenuItem::Separator)
                return {10, AYRAC};
            QString metin = mi->text;
            QString kisayol;
            const int sekme = metin.indexOf(QLatin1Char('\t'));
            if (sekme >= 0) {
                kisayol = metin.mid(sekme + 1);
                metin = metin.left(sekme);
            }
            const QFontMetrics fm(mi->font);
            int gen = YAZI_X - IC - CERCEVE + fm.horizontalAdvance(metin) + SAG;
            if (!kisayol.isEmpty())
                gen += 24 + fm.horizontalAdvance(kisayol);
            return {gen, qMax(OGE, fm.height() + 6)};
        }
        return QProxyStyle::sizeFromContents(t, o, s, w);
    }

    void drawPrimitive(PrimitiveElement e, const QStyleOption *o, QPainter *p, const QWidget *w = nullptr) const override
    {
        if (e == PE_PanelMenu || e == PE_FrameMenu) {
            if (e == PE_PanelMenu)
                p->fillRect(o->rect, ZEMIN);
            p->save();
            p->setPen(KENAR);
            p->setBrush(Qt::NoBrush);
            p->drawRect(o->rect.adjusted(0, 0, -1, -1));
            // simge oluğunun çizgisi (POPUPGUTTER sağ kenarı)
            if (qobject_cast<const QMenu *>(w)) {
                p->setPen(OLUK);
                const int x = o->rect.left() + OLUK_GEN - 1;
                p->drawLine(x, o->rect.top() + CERCEVE, x, o->rect.bottom() - CERCEVE);
            }
            p->restore();
            return;
        }
        QProxyStyle::drawPrimitive(e, o, p, w);
    }

    void drawControl(ControlElement e, const QStyleOption *o, QPainter *p, const QWidget *w = nullptr) const override
    {
        if (e == CE_MenuEmptyArea) {
            p->fillRect(o->rect, ZEMIN);
            return;
        }
        if (e != CE_MenuItem)
            return QProxyStyle::drawControl(e, o, p, w);
        const auto *mi = qstyleoption_cast<const QStyleOptionMenuItem *>(o);
        if (!mi)
            return QProxyStyle::drawControl(e, o, p, w);

        const QRect r = mi->rect;
        // menü kenarına göre konumlar (öğe dikdörtgeni kenar + iç boşluk kadar içeride başlar)
        const int x0 = r.left() - IC - CERCEVE;
        p->save();
        p->setRenderHint(QPainter::Antialiasing, false);

        if (mi->menuItemType == QStyleOptionMenuItem::Separator) {
            p->setPen(OLUK);
            const int y = r.top() + r.height() / 2;
            p->drawLine(x0 + YAZI_X - 3, y, r.right(), y);
            p->restore();
            return;
        }

        const bool etkin = mi->state & State_Enabled;
        const bool secili = mi->state & State_Selected;
        // simge oluğunun çizgisi öğenin üstünden de geçer (vurgulu değilse)
        if (!secili) {
            p->setPen(OLUK);
            p->drawLine(x0 + OLUK_GEN - 1, r.top(), x0 + OLUK_GEN - 1, r.bottom());
        }
        if (secili) {
            // POPUPITEM üzerinde / devre dışı-üzerinde
            const QColor kenar = etkin ? QColor(0, 107, 217, 128) : QColor(107, 107, 107, 128);
            const QColor dolgu = etkin ? QColor(0, 131, 255, 33) : QColor(123, 123, 123, 33);
            const QRect v = r.adjusted(0, 0, -1, -1);
            p->fillRect(v.adjusted(1, 1, 0, 0), dolgu);
            p->setPen(kenar);
            p->drawRect(v);
        }

        // onay / seçenek: POPUPCHECKBACKGROUND (22x22, 16 px işaret)
        const QRect onayKutu(x0 + 3, r.top() + (r.height() - 22) / 2, 22, 22);
        if (mi->checkType != QStyleOptionMenuItem::NotCheckable && mi->checked) {
            const bool mavi = etkin;
            p->setPen(mavi ? QColor(0x26, 0xA0, 0xDA) : QColor(0xDA, 0xDA, 0xDA));
            p->setBrush(mavi ? QColor(0x25, 0x9E, 0xD9, 61) : QColor(0xD9, 0xD9, 0xD9, 61));
            p->drawRect(onayKutu.adjusted(0, 0, -1, -1));
            p->setRenderHint(QPainter::Antialiasing, true);
            p->setPen(QPen(etkin ? YAZI : SOLUK, 1.6, Qt::SolidLine, Qt::SquareCap, Qt::MiterJoin));
            p->setBrush(etkin ? YAZI : SOLUK);
            const QPointF c = QRectF(onayKutu).center();
            if (mi->checkType == QStyleOptionMenuItem::Exclusive) {
                p->drawEllipse(c, 3.0, 3.0);
            } else {
                p->setBrush(Qt::NoBrush);
                QPainterPath iz;
                iz.moveTo(c.x() - 4, c.y());
                iz.lineTo(c.x() - 1.5, c.y() + 3);
                iz.lineTo(c.x() + 4, c.y() - 3.5);
                p->drawPath(iz);
            }
            p->setRenderHint(QPainter::Antialiasing, false);
        } else if (!mi->icon.isNull()) {
            const QIcon::Mode kip = etkin ? QIcon::Normal : QIcon::Disabled;
            const QPixmap pm = mi->icon.pixmap(QSize(16, 16), p->device() ? p->device()->devicePixelRatioF() : 1.0, kip);
            p->drawPixmap(QRect(onayKutu.left() + 3, onayKutu.top() + 3, 16, 16), pm);
        }

        // metin ve kısayol
        QString metin = mi->text;
        QString kisayol;
        const int sekme = metin.indexOf(QLatin1Char('\t'));
        if (sekme >= 0) {
            kisayol = metin.mid(sekme + 1);
            metin = metin.left(sekme);
        }
        p->setFont(mi->font);
        p->setPen(etkin ? YAZI : SOLUK);
        const QRect yazi(x0 + YAZI_X, r.top(), r.right() - (x0 + YAZI_X) - SAG + 8, r.height());
        int bayrak = Qt::AlignVCenter | Qt::AlignLeft | Qt::TextSingleLine | Qt::TextShowMnemonic;
        if (!proxy()->styleHint(SH_UnderlineShortcut, mi, w))
            bayrak |= Qt::TextHideMnemonic;
        p->drawText(yazi, bayrak, metin);
        if (!kisayol.isEmpty())
            p->drawText(yazi, Qt::AlignVCenter | Qt::AlignRight | Qt::TextSingleLine, kisayol);

        // alt menü oku (POPUPSUBMENU: küçük dolu üçgen)
        if (mi->menuItemType == QStyleOptionMenuItem::SubMenu) {
            p->setRenderHint(QPainter::Antialiasing, true);
            p->setPen(Qt::NoPen);
            p->setBrush(etkin ? YAZI : SOLUK);
            const int ax = r.right() - 12, ay = r.top() + r.height() / 2;
            QPolygonF uc;
            uc << QPointF(ax, ay - 4) << QPointF(ax + 4, ay) << QPointF(ax, ay + 4);
            p->drawPolygon(uc);
        }
        p->restore();
    }

private:
    // Windows 8 menü gölgesi: KWin'in çizdiği yumuşak gölge (KWindowShadow), menü gösterilince
    class GolgeYonetici : public QObject
    {
    public:
        using QObject::QObject;
        bool eventFilter(QObject *o, QEvent *e) override
        {
            if (e->type() == QEvent::Show) {
                if (auto *m = qobject_cast<QMenu *>(o))
                    golgeKur(m);
            }
            return false;
        }

    private:
        static QImage parca(int gen, int yuk, int ox, int oy)
        {
            // 5 px yumuşak gölge: köşe ve kenar parçaları tek bir yuvarlatılmış dikdörtgenin bulanık izinden
            constexpr int G = 6;
            QImage im(gen, yuk, QImage::Format_ARGB32_Premultiplied);
            im.fill(Qt::transparent);
            for (int y = 0; y < yuk; ++y)
                for (int x = 0; x < gen; ++x) {
                    const int dx = qMax(0, qMax(G - (x + ox), (x + ox) - G - 1));
                    const int dy = qMax(0, qMax(G - (y + oy), (y + oy) - G - 1));
                    const double d = std::sqrt(double(dx * dx + dy * dy));
                    const double a = qMax(0.0, 1.0 - d / G);
                    im.setPixelColor(x, y, QColor(0, 0, 0, int(a * a * 70)));
                }
            return im;
        }
        static void golgeKur(QMenu *m)
        {
            if (!m->windowHandle())
                return;
            auto *g = m->findChild<KWindowShadow *>();
            if (!g) {
                g = new KWindowShadow(m);
                constexpr int G = 6;
                auto tile = [](const QImage &im) {
                    auto *t = new KWindowShadowTile;
                    t->setImage(im);
                    t->create();
                    return KWindowShadowTile::Ptr(t);
                };
                // 9 parça: köşeler GxG, kenarlar 1xG / Gx1
                g->setTopLeftTile(tile(parca(G, G, 0, 0)));
                g->setTopTile(tile(parca(1, G, G, 0)));
                g->setTopRightTile(tile(parca(G, G, G + 1, 0)));
                g->setRightTile(tile(parca(G, 1, G + 1, G)));
                g->setBottomRightTile(tile(parca(G, G, G + 1, G + 1)));
                g->setBottomTile(tile(parca(1, G, G, G + 1)));
                g->setBottomLeftTile(tile(parca(G, G, 0, G + 1)));
                g->setLeftTile(tile(parca(G, 1, 0, G)));
                // Windows 8 menü gölgesi sağ ve alta kaymış
                g->setPadding(QMargins(G - 2, G - 2, G + 1, G + 1));
            }
            g->setWindow(m->windowHandle());
            g->create();
        }
    };
    static QObject *golgeYonetici()
    {
        static QPointer<QObject> y;
        if (!y)
            y = new GolgeYonetici(qApp);
        return y;
    }
};

class MetroStilEklentisi : public QStylePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QStyleFactoryInterface_iid FILE "metrostil.json")
public:
    QStyle *create(const QString &anahtar) override
    {
        if (anahtar.compare(QLatin1String("metro"), Qt::CaseInsensitive) != 0)
            return nullptr;
        // taban: Kvantum (Metro teması); yoksa Fusion
        QStyle *taban = QStyleFactory::create(QStringLiteral("kvantum"));
        if (!taban)
            taban = QStyleFactory::create(QStringLiteral("Fusion"));
        return new MetroStil(taban);
    }
};

#include "metrostil.moc"
