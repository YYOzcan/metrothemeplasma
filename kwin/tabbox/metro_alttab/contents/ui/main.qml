/*
    MetroThemePlasma — Windows 8.1 Alt+Tab: pencere renginde düz panel, üstte seçili pencerenin adı,
    küçük resim ızgarası (sağ altta uygulama simgesi), seçili öğede açık renkli çerçeve.
    SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org> (KWin değiştirici iskeleti)
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtCore
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox
    currentIndex: grid.currentIndex

    readonly property int hucreG: 214
    readonly property int hucreY: 158
    readonly property int enFazlaSutun: Math.max(1, Math.floor((tabBox.screenGeometry.width - 160) / hucreG))
    readonly property int sutun: Math.max(1, Math.min(enFazlaSutun, grid.count))
    readonly property int satir: Math.max(1, Math.ceil(grid.count / enFazlaSutun))

    Settings {
        id: pencere
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/metrothemeplasma/ayarlar.ini"
        category: "Pencere"
        property string cerceve: "#6cb4e4"
    }

    PlasmaCore.Dialog {
        id: dialog
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        backgroundHints: PlasmaCore.Dialog.NoBackground
        flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + (tabBox.screenGeometry.width - main.width) / 2
        y: tabBox.screenGeometry.y + (tabBox.screenGeometry.height - main.height) / 2

        mainItem: Rectangle {
            id: main
            width: tabBox.sutun * tabBox.hucreG + 40
            height: tabBox.satir * tabBox.hucreY + 74
            color: pencere.cerceve
            border.color: Qt.darker(pencere.cerceve, 1.35)
            border.width: 1

            Text {
                id: baslik
                x: 20; y: 14
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "black"
                font.family: "Segoe UI"; font.pixelSize: 15
                text: grid.currentItem ? grid.currentItem.ad : ""
            }

            GridView {
                id: grid
                x: 20; y: 48
                width: tabBox.sutun * tabBox.hucreG
                height: tabBox.satir * tabBox.hucreY
                cellWidth: tabBox.hucreG
                cellHeight: tabBox.hucreY
                interactive: false
                focus: true
                model: tabBox.model
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0
                highlight: Item {
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 3
                        color: Qt.rgba(1, 1, 1, 0.25)
                        border.color: Qt.rgba(1, 1, 1, 0.9)
                        border.width: 2
                    }
                }
                delegate: Item {
                    id: oge
                    readonly property string ad: model.caption
                    width: tabBox.hucreG
                    height: tabBox.hucreY
                    Item {
                        id: kutu
                        anchors.fill: parent; anchors.margins: 14
                        KWin.WindowThumbnail {
                            anchors.fill: parent
                            wId: model.windowId
                        }
                    }
                    Kirigami.Icon {
                        anchors.right: kutu.right; anchors.bottom: kutu.bottom
                        anchors.rightMargin: -4; anchors.bottomMargin: -4
                        width: 32; height: 32
                        source: model.icon
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            grid.currentIndex = index
                            tabBox.model.activate(index)
                        }
                    }
                }
                onCountChanged: if (count === 0) tabBox.visible = false
            }
        }
    }

    onCurrentIndexChanged: grid.currentIndex = currentIndex
}
