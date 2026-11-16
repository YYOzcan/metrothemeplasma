// MetroThemePlasma masaüstü sağ tık eylemi: menüde yalnız kapsayıcının kendi öğeleri (Windows 8.1 masaüstü
// menüsü io.github.yyozcan.metrokapsayici'de kurulur). Plasma'nın standart menüsündeki "Düzenleme Kipine Gir",
// "Görüntü Yapılandırması", oturum/kilit öğeleri Windows'ta yoktur.
#include <Plasma/Containment>
#include <Plasma/ContainmentActions>

#include <KPluginFactory>

class MetroBaglam : public Plasma::ContainmentActions
{
    Q_OBJECT
public:
    using Plasma::ContainmentActions::ContainmentActions;

    QList<QAction *> contextualActions() override
    {
        Plasma::Containment *c = containment();
        return c ? c->contextualActions() : QList<QAction *>();
    }
};

K_PLUGIN_CLASS_WITH_JSON(MetroBaglam, "metrobaglam.json")

#include "metrobaglam.moc"
