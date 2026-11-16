/*
    SPDX-FileCopyrightText: 2014 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class QAction;
class QActionGroup;
class QMenu;

class ViewPropertiesMenu : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *menu READ menu CONSTANT)
    Q_PROPERTY(QObject *sortMenu READ sortMenu CONSTANT)

    Q_PROPERTY(bool showLayoutActions READ showLayoutActions WRITE setShowLayoutActions NOTIFY showLayoutActionsChanged)
    Q_PROPERTY(bool showLockAction READ showLockAction WRITE setShowLockAction NOTIFY showLockActionChanged)
    Q_PROPERTY(bool showIconSizeActions READ showIconSizeActions WRITE setShowIconSizeActions NOTIFY showIconSizeActionsChanged)

    Q_PROPERTY(int arrangement READ arrangement WRITE setArrangement NOTIFY arrangementChanged)
    Q_PROPERTY(int alignment READ alignment WRITE setAlignment NOTIFY alignmentChanged)
    Q_PROPERTY(bool previews READ previews WRITE setPreviews NOTIFY previewsChanged)
    Q_PROPERTY(bool locked READ locked WRITE setLocked NOTIFY lockedChanged)
    Q_PROPERTY(bool lockedEnabled READ lockedEnabled WRITE setLockedEnabled NOTIFY lockedEnabledChanged)
    Q_PROPERTY(int sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(bool sortDesc READ sortDesc WRITE setSortDesc NOTIFY sortDescChanged)
    Q_PROPERTY(bool sortDirsFirst READ sortDirsFirst WRITE setSortDirsFirst NOTIFY sortDirsFirstChanged)
    Q_PROPERTY(int iconSize READ iconSize WRITE setIconSize NOTIFY iconSizeChanged)
    Q_PROPERTY(bool showIcons READ showIcons WRITE setShowIcons NOTIFY showIconsChanged)

public:
    explicit ViewPropertiesMenu(QObject *parent = nullptr);
    ~ViewPropertiesMenu() override;

    QObject *menu() const;
    QObject *sortMenu() const;

    bool showLayoutActions() const;
    void setShowLayoutActions(bool show);

    bool showLockAction() const;
    void setShowLockAction(bool show);

    bool showIconSizeActions() const;
    void setShowIconSizeActions(bool show);

    int arrangement() const;
    void setArrangement(int arrangement);

    int alignment() const;
    void setAlignment(int alignment);

    bool previews() const;
    void setPreviews(bool previews);

    bool locked() const;
    void setLocked(bool locked);

    bool lockedEnabled() const;
    void setLockedEnabled(bool lockedEnabled);

    int sortMode() const;
    void setSortMode(int sortMode);

    bool sortDesc() const;
    void setSortDesc(bool sortDesc);

    bool sortDirsFirst() const;
    void setSortDirsFirst(bool sortDirsFirst);

    int iconSize() const;
    void setIconSize(int iconSize);

    bool showIcons() const;
    void setShowIcons(bool show);

Q_SIGNALS:
    void showLayoutActionsChanged() const;
    void showLockActionChanged() const;
    void showIconSizeActionsChanged();
    void arrangementChanged() const;
    void alignmentChanged() const;
    void previewsChanged() const;
    void lockedChanged() const;
    void lockedEnabledChanged() const;
    void sortModeChanged() const;
    void sortDescChanged() const;
    void sortDirsFirstChanged() const;
    void iconSizeChanged();
    void showIconsChanged();
    void sortRequested(int mode);

private:
    QMenu *m_sortMenu;
    QMenu *m_menu;
    QActionGroup *m_iconSize;
    QAction *m_otomatik;
    QAction *m_kilavuz;
    QAction *m_simgeler;
    bool m_showLayout = true;
    bool m_showLock = true;
    bool m_showIconSize = true;
    bool m_lockedEnabled = true;
    int m_arrangementValue = 0;
    int m_alignmentValue = 0;
    bool m_previewsValue = true;
    bool m_lockedValue = false;
    int m_sortModeValue = -1;
    bool m_sortDescValue = false;
    bool m_sortDirsFirstValue = true;
    int m_iconSizeValue = 2;
};
