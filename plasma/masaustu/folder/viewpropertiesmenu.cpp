/*
    SPDX-FileCopyrightText: 2014 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: MetroThemePlasma (Windows 8.1 düzeni)

    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Windows 8.1 masaüstü "Görünüm" ve "Sıralama ölçütü" alt menüleri (shell32.dll.mui MENU 215 ve
// dizeler 31157/31158). Plasma'nın diğer görünüm ayarları (dizilim, hizalama, önizleme, kilit, azalan,
// önce klasörler) menüde gösterilmez; yalnız özellik olarak korunur.

#include "viewpropertiesmenu.h"

#include <QActionGroup>
#include <QApplication>
#include <QMenu>

#include <KDirModel>

ViewPropertiesMenu::ViewPropertiesMenu(QObject *parent)
    : QObject(parent)
{
    m_menu = new QMenu();

    // ---- simge boyutu (Plasma iconSize dizini: 1=32, 2=48, 4=96 px; Windows küçük/orta/büyük)
    m_iconSize = new QActionGroup(this);
    m_iconSize->setExclusive(true);
    const QList<QPair<int, QString>> boyutlar{{4, QStringLiteral("&Büyük simgeler")},
                                              {2, QStringLiteral("O&rta boyutlu simgeler")},
                                              {1, QStringLiteral("&Küçük simgeler")}};
    for (const auto &[deger, ad] : boyutlar) {
        QAction *action = m_menu->addAction(ad);
        action->setCheckable(true);
        action->setData(deger);
        m_iconSize->addAction(action);
    }
    connect(m_iconSize, &QActionGroup::triggered, this, [this](QAction *a) {
        m_iconSizeValue = a->data().toInt();
        Q_EMIT iconSizeChanged();
    });

    m_menu->addSeparator();
    m_otomatik = m_menu->addAction(QStringLiteral("Simgeleri o&tomatik düzenle"));
    m_otomatik->setCheckable(true);
    connect(m_otomatik, &QAction::triggered, this, [this](bool acik) {
        m_sortModeValue = acik ? int(KDirModel::Name) : -1;
        Q_EMIT sortModeChanged();
    });
    // Plasma simgeleri her zaman kılavuza oturtur: Windows'taki gibi işaretli durur
    m_kilavuz = m_menu->addAction(QStringLiteral("Simgeleri kılavuz çizgisine hi&zala"));
    m_kilavuz->setCheckable(true);
    m_kilavuz->setChecked(true);
    connect(m_kilavuz, &QAction::triggered, m_kilavuz, [this] { m_kilavuz->setChecked(true); });

    m_menu->addSeparator();
    m_simgeler = m_menu->addAction(QStringLiteral("&Masaüstü simgelerini göster"));
    m_simgeler->setCheckable(true);
    m_simgeler->setChecked(true);
    connect(m_simgeler, &QAction::triggered, this, &ViewPropertiesMenu::showIconsChanged);

    // ---- Sıralama ölçütü: Windows'ta işaretsiz; otomatik düzen kapalıyken bir kez sıralar
    m_sortMenu = new QMenu(QStringLiteral("Sıralama &ölçütü"));
    const QList<QPair<int, QString>> olcutler{{int(KDirModel::Name), QStringLiteral("&Ad")},
                                              {int(KDirModel::Size), QStringLiteral("&Boyut")},
                                              {int(KDirModel::Type), QStringLiteral("Öğe &türü")},
                                              {int(KDirModel::ModifiedTime), QStringLiteral("&Değiştirme tarihi")}};
    for (const auto &[deger, ad] : olcutler) {
        QAction *action = m_sortMenu->addAction(ad);
        connect(action, &QAction::triggered, this, [this, deger] { Q_EMIT sortRequested(deger); });
    }
}

ViewPropertiesMenu::~ViewPropertiesMenu()
{
    delete m_menu;
    delete m_sortMenu;
}

QObject *ViewPropertiesMenu::menu() const
{
    return m_menu;
}
QObject *ViewPropertiesMenu::sortMenu() const
{
    return m_sortMenu;
}

// Windows menüsünde karşılığı olmayan seçenekler: değerleri korunur, menüde görünmez
bool ViewPropertiesMenu::showLayoutActions() const { return m_showLayout; }
void ViewPropertiesMenu::setShowLayoutActions(bool show)
{
    if (m_showLayout != show) {
        m_showLayout = show;
        Q_EMIT showLayoutActionsChanged();
    }
}
bool ViewPropertiesMenu::showLockAction() const { return m_showLock; }
void ViewPropertiesMenu::setShowLockAction(bool show)
{
    if (m_showLock != show) {
        m_showLock = show;
        Q_EMIT showLockActionChanged();
    }
}
bool ViewPropertiesMenu::showIconSizeActions() const { return m_showIconSize; }
void ViewPropertiesMenu::setShowIconSizeActions(bool show)
{
    if (m_showIconSize != show) {
        m_showIconSize = show;
        for (QAction *a : m_iconSize->actions())
            a->setVisible(show);
        Q_EMIT showIconSizeActionsChanged();
    }
}

int ViewPropertiesMenu::arrangement() const { return m_arrangementValue; }
void ViewPropertiesMenu::setArrangement(int arrangement) { m_arrangementValue = arrangement; }
int ViewPropertiesMenu::alignment() const { return m_alignmentValue; }
void ViewPropertiesMenu::setAlignment(int alignment) { m_alignmentValue = alignment; }
bool ViewPropertiesMenu::previews() const { return m_previewsValue; }
void ViewPropertiesMenu::setPreviews(bool previews) { m_previewsValue = previews; }
bool ViewPropertiesMenu::locked() const { return m_lockedValue; }
void ViewPropertiesMenu::setLocked(bool locked) { m_lockedValue = locked; }
bool ViewPropertiesMenu::lockedEnabled() const { return m_lockedEnabled; }
void ViewPropertiesMenu::setLockedEnabled(bool enabled)
{
    if (m_lockedEnabled != enabled) {
        m_lockedEnabled = enabled;
        Q_EMIT lockedEnabledChanged();
    }
}

int ViewPropertiesMenu::sortMode() const { return m_sortModeValue; }
void ViewPropertiesMenu::setSortMode(int sortMode)
{
    m_sortModeValue = sortMode;
    m_otomatik->setChecked(sortMode != -1);
}
bool ViewPropertiesMenu::sortDesc() const { return m_sortDescValue; }
void ViewPropertiesMenu::setSortDesc(bool sortDesc) { m_sortDescValue = sortDesc; }
bool ViewPropertiesMenu::sortDirsFirst() const { return m_sortDirsFirstValue; }
void ViewPropertiesMenu::setSortDirsFirst(bool sortDirsFirst) { m_sortDirsFirstValue = sortDirsFirst; }

int ViewPropertiesMenu::iconSize() const { return m_iconSizeValue; }
void ViewPropertiesMenu::setIconSize(int iconSize)
{
    m_iconSizeValue = iconSize;
    for (QAction *a : m_iconSize->actions())
        a->setChecked(a->data().toInt() == iconSize);
}

bool ViewPropertiesMenu::showIcons() const { return m_simgeler->isChecked(); }
void ViewPropertiesMenu::setShowIcons(bool show) { m_simgeler->setChecked(show); }

#include "moc_viewpropertiesmenu.cpp"
