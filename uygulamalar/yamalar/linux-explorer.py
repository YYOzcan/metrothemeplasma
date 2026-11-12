"""linux-explorer: Windows 8.1 / Türkçe uyarlamaları (sözlükten önce; çalışma dizini = kaynak kopyası).
- Türkçe söz dizimi: "on X" -> "X üzerinde", "Battery on X" -> "X pili" (Aygıt Yöneticisi tarayıcısı)
- Sahte Windows rozeti: "Windows 7 Ultimate"/2009 yerine kendi kopyandaki 8.1 sürümü (varlik/winver.ini)
"""
import re
from pathlib import Path

for p in Path("src").rglob("*.cpp"):
    s = p.read_text()
    y = re.sub(r'"Battery on " \+ ([\w.]+(?:\(\))?)', r'\1 + " pili"', s)
    y = re.sub(r'(?<![\w"])"on " \+ ([\w.]+(?:\(\))?)', r'\1 + " üzerinde"', y)
    y = re.sub(r'" on " \+ ([\w.]+(?:\(\))?)', r'", " + \1 + " üzerinde"', y)
    if y != s:
        p.write_text(y)

p = Path("src/data/control/Branding.cpp")
s = p.read_text()
a = '''    if (fakeBadgeActive())
        return QStringLiteral("Windows 7 Ultimate");
    return realPretty;'''
b = '''    if (fakeBadgeActive()) {
        // MetroThemePlasma: kendi Windows 8.1 kopyandaki sürüm adı (basebrd.dll.mui)
        const QString ini = QStandardPaths::locate(QStandardPaths::GenericDataLocation,
                                                   QStringLiteral("metrothemeplasma/varlik/winver.ini"));
        if (!ini.isEmpty()) {
            QSettings m(ini, QSettings::IniFormat);
            const QString ad = m.value(QStringLiteral("Windows81/ad")).toString();
            if (!ad.isEmpty())
                return ad;
        }
        return QStringLiteral("Windows 8.1");
    }
    return realPretty;'''
assert a in s, "editionName"
s = s.replace(a, b)
a = '''    if (fakeBadgeActive())
        return 2009;'''
assert a in s, "copyrightYear"
s = s.replace(a, '''    if (fakeBadgeActive())
        return 2013;''')
p.write_text(s)

# marka seçicideki "Windows 7" seçeneği Windows 8.1 olur
for p in Path("src").rglob("LinverConfigDialog.cpp"):
    s = p.read_text()
    p.write_text(s.replace('"Windows 7"', '"Windows 8.1"'))

# Sesler: ATP'nin Windows 7 sesleri yerine kendi Windows 8.1 kopyandaki Media klasörü (aynı dosya adları)
MEDYA = ('QStandardPaths::locate(QStandardPaths::GenericDataLocation, '
         'QStringLiteral("metrothemeplasma/win/Windows/Media"), QStandardPaths::LocateDirectory)')
p = Path("src/aero/sounds.cpp")
s = p.read_text()
a = '    static QString path = QStringLiteral("/usr/share/sounds/Windows 7/og");'
assert a in s, "sounds"
s = s.replace(a, '    static QString path = [] { const QString m = ' + MEDYA + ';\n'
                 '        return m.isEmpty() ? QStringLiteral("/usr/share/sounds/Windows 7/og") : m; }();')
s = "#include <QStandardPaths>\n" + s
p.write_text(s)
p = Path("src/ui/MainWindow.cpp")
s = p.read_text()
a = '''    m_navSound.setSource(QUrl::fromLocalFile(
        "/usr/share/sounds/Windows 7/og/Windows Navigation Start.wav"));'''
assert a in s, "navsound"
s = s.replace(a, '''    {
        const QString m = ''' + MEDYA + ''';
        m_navSound.setSource(QUrl::fromLocalFile(m.isEmpty()
            ? QStringLiteral("/usr/share/sounds/Windows 7/og/Windows Navigation Start.wav")
            : m + QStringLiteral("/Windows Navigation Start.wav")));
    }''')
if "#include <QStandardPaths>" not in s:
    s = "#include <QStandardPaths>\n" + s
p.write_text(s)

# Windows 8 gezinti çubuğu: cam alanı yok (Metro'da bulanıklık yok, Windows 8'de bu satır opak),
# Windows 7'nin yuvarlak camlı düğmeleri yerine düz oklar (simge teması: ExplorerFrame.dll), son konumlar ve yukarı
p = Path("src/ui/MainWindow.cpp")
s = p.read_text()
a = '''    setAttribute(Qt::WA_TranslucentBackground, true);
    setAttribute(Qt::WA_NoSystemBackground, true);
    Aero::makeInsetWindow(this, central, m_navBar, nullptr);'''
assert a in s, "inset"
s = s.replace(a, '''    Aero::makeInsetWindow(this, central, m_navBar, nullptr);
    m_navBar->setAutoFillBackground(true);
    {
        QPalette pal = m_navBar->palette();
        pal.setColor(QPalette::Window, Qt::white);
        m_navBar->setPalette(pal);
    }''')
bas = s.index("    auto *navBtns = new Aero::NavButtons(m_navBar);")
son = s.index('    navBtns->menuButton()->setToolTip(tr("Recent locations"));') + len('    navBtns->menuButton()->setToolTip(tr("Recent locations"));')
eski = s[bas:son]
govde = eski[eski.index("    // The chrome reserves the slot"):eski.index("    // Taken by reference")]
yeni = '''    auto *navBtns = new QWidget(m_navBar);
    auto *navLayout = new QHBoxLayout(navBtns);
    navLayout->setContentsMargins(0, 0, 4, 0);
    navLayout->setSpacing(0);
    auto metroDugme = [navBtns](const QString &simge, const QString &ipucu) {
        auto *b = new QPushButton(navBtns);
        b->setFlat(true);
        b->setFocusPolicy(Qt::NoFocus);
        b->setIcon(QIcon::fromTheme(simge));
        b->setIconSize(QSize(16, 16));
        b->setFixedSize(28, 26);
        b->setToolTip(ipucu);
        b->setStyleSheet(QStringLiteral(
            "QPushButton { border: 1px solid transparent; background: transparent; color: #444; }"
            "QPushButton:hover { border-color: #cce8ff; background: #e5f3ff; }"
            "QPushButton:pressed { border-color: #99d1ff; background: #cce8ff; }"));
        return b;
    };
    m_backBtn = metroDugme(QStringLiteral("go-previous"), tr("Back"));
    m_forwardBtn = metroDugme(QStringLiteral("go-next"), tr("Forward"));
    auto *recentBtn = metroDugme(QString(), tr("Recent locations"));
    recentBtn->setText(QStringLiteral("\\u25BE"));
    recentBtn->setFixedWidth(14);
    auto *upBtn = metroDugme(QStringLiteral("go-up"), tr("Up one level"));
    navLayout->addWidget(m_backBtn);
    navLayout->addWidget(m_forwardBtn);
    navLayout->addWidget(recentBtn);
    navLayout->addWidget(upBtn);
    m_backBtn->setEnabled(false);
    m_forwardBtn->setEnabled(false);
    connect(m_backBtn, &QPushButton::clicked, this, &MainWindow::goBack);
    connect(m_forwardBtn, &QPushButton::clicked, this, &MainWindow::goForward);
    connect(upBtn, &QPushButton::clicked, this, &MainWindow::goUp);
    layout->addWidget(navBtns);

''' + govde + '''    connect(recentBtn, &QPushButton::clicked, this, [recentBtn, recentMenu] {
        recentMenu->popup(recentBtn->mapToGlobal(QPoint(0, recentBtn->height())));
    });'''
s = s[:bas] + yeni + s[son:]
p.write_text(s)

# Komut çubuğu: Windows 7'nin mavi geçişi yerine Windows 8 şerit alanının düz açık grisi, düğmelerde açık mavi vurgu
from PIL import Image, ImageDraw


def kutu(w, h, dolgu, kenar):
    im = Image.new("RGBA", (w, h), dolgu)
    ImageDraw.Draw(im).rectangle([0, 0, w - 1, h - 1], outline=kenar)
    return im


cubuk = Image.new("RGBA", (31, 31), (245, 246, 247, 255))
ImageDraw.Draw(cubuk).line([(0, 30), (30, 30)], fill=(218, 219, 220, 255))
cubuk.save("assets/images/commandbar.png")
kutu(11, 24, (229, 243, 255, 255), (204, 232, 255, 255)).save("assets/images/commandhover.png")
kutu(11, 24, (204, 232, 255, 255), (153, 209, 255, 255)).save("assets/images/commandpress.png")
