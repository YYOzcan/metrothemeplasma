/*
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2026 MetroThemePlasma

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

// Windows 8.1 bildirimi (toast): sağ üstte, Başlangıç zemin renginde 364 piksellik kutu; solda (varsa) resim,
// başlık (Semibold) ve metin, sağ altta uygulamanın küçük logosu, fare üzerindeyken sağ üstte kapatma düğmesi.
// Sağdan kayarak gelir (PVL eğrisi), süresi dolunca solarak kaybolur.

import QtQuick
import QtCore

import org.kde.kquickcontrolsaddons as KQuickAddons
import org.kde.kirigami as Kirigami

import org.kde.notificationmanager as NotificationManager
import plasma.applet.io.github.yyozcan.metrobildirim as NotificationsApplet

import "components" as Components

NotificationsApplet.NotificationWindow {
    id: notificationPopup

    property int popupWidth

    property alias modelInterface: mi

    property int intendedX
    property int intendedY

    property int modelTimeout
    property int dismissTimeout

    property var defaultActionFallbackWindowIdx

    signal expired
    signal hoverEntered
    signal hoverExited

    property int defaultTimeout: 7000          // Windows 8: 7 sn
    readonly property int effectiveTimeout: {
        if (modelTimeout === -1) {
            return defaultTimeout;
        }
        if (dismissTimeout) {
            return dismissTimeout;
        }
        return modelTimeout;
    }

    takeFocus: false
    visible: false

    width: kok.implicitWidth
    height: kok.implicitHeight

    readonly property bool isJob: mi.notificationType === NotificationManager.Notifications.JobType

    onVisibleChanged: {
        if (visible) {
            kayma.x = kok.implicitWidth;
            kok.opacity = 1;
            giris.restart();
        }
    }

    mainItem: KQuickAddons.MouseEventListener {
        id: kok
        implicitWidth: 364
        implicitHeight: Math.max(kutu.icerikYukseklik, 64)

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        onContainsMouseChanged: containsMouse ? notificationPopup.hoverEntered() : notificationPopup.hoverExited()
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (mi.closable) mi.closeClicked();
            } else if (mi.hasDefaultAction) {
                mi.defaultActionInvoked();
            }
        }

        Components.ModelInterface {
            id: mi
            maximumLineCount: 3
            closable: true
            onTimeChanged: if (zaman.running) zaman.restart()
            timeout: zaman.running ? zaman.interval : 0
            onBodyClicked: if (hasDefaultAction) defaultActionInvoked()
        }

        Settings {
            id: renk
            location: "file://" + StandardPaths.writableLocation(StandardPaths.ConfigLocation).toString().replace("file://", "") + "/metrothemeplasma/ayarlar.ini"
            category: "Renk"
            property string arkaPlan: "#180053"
            property string vurgu: "#4617b4"
        }

        NumberAnimation {
            id: giris
            target: kayma; property: "x"; to: 0
            duration: 500; easing.type: Easing.Bezier; easing.bezierCurve: [0.1, 0.9, 0.2, 1, 1, 1]
        }

        Timer {
            id: zaman
            interval: notificationPopup.effectiveTimeout
            running: notificationPopup.visible && !kok.containsMouse && interval > 0
            onTriggered: {
                if (notificationPopup.dismissTimeout) {
                    mi.dismissClicked();
                } else {
                    notificationPopup.expired();
                }
            }
        }
        NumberAnimation {
            target: mi; property: "remainingTime"
            from: zaman.interval; to: 0; duration: zaman.interval
            running: zaman.running
        }

        Item {
            id: kayma
            width: kok.width; height: kok.height
            // son 600 ms'de solar
            opacity: kok.containsMouse || !zaman.running ? 1 : Math.min(1, mi.remainingTime / 600)

            Rectangle {
                id: kutu
                anchors.fill: parent
                color: renk.arkaPlan
                border.width: 1
                border.color: Qt.lighter(renk.arkaPlan, 1.9)

                // simge adı (ör. -i org.kde.dolphin) Windows 8'deki gibi sağ altta küçük logo olur;
                // yalnızca gerçek resim (QImage, dosya yolu) solda 90x90 gösterilir
                readonly property bool simgeAdi: typeof mi.icon === "string" && !mi.icon.startsWith("/") && !mi.icon.startsWith("file:")
                readonly property bool resimVar: !notificationPopup.isJob && !!mi.icon && mi.icon !== "" && !simgeAdi
                readonly property var logo: mi.applicationIconSource ? mi.applicationIconSource : (simgeAdi ? mi.icon : "")
                readonly property int solBosluk: resimVar ? 90 + 14 : 14
                readonly property int icerikYukseklik: Math.max(resimVar ? 90 : 0, metinler.y + metinler.height + 14)

                // solda bildirim resmi (kişi fotoğrafı, albüm kapağı …)
                Kirigami.Icon {
                    visible: kutu.resimVar
                    x: 0; y: 0; width: 90; height: 90
                    source: kutu.resimVar ? mi.icon : ""
                }

                Column {
                    id: metinler
                    x: kutu.solBosluk; y: 12
                    width: kutu.width - x - 44
                    spacing: 1
                    Text {
                        width: parent.width
                        text: mi.summary !== "" ? mi.summary : mi.applicationName
                        color: "white"
                        font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: text !== "" && !notificationPopup.isJob
                        text: mi.body
                        textFormat: Text.StyledText
                        color: Qt.rgba(1, 1, 1, 0.8)
                        font.family: "Segoe UI"; font.pixelSize: 15
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        linkColor: "white"
                        onLinkActivated: link => mi.openUrl(link)
                    }
                    // iş (dosya kopyalama …): ilerleme çubuğu
                    Item {
                        visible: notificationPopup.isJob
                        width: parent.width; height: 26
                        Rectangle {
                            y: 12; width: parent.width - 48; height: 6
                            color: Qt.rgba(1, 1, 1, 0.2)
                            Rectangle { width: parent.width * Math.max(0, Math.min(1, mi.percentage / 100)); height: parent.height; color: renk.vurgu === renk.arkaPlan ? "white" : Qt.lighter(renk.vurgu, 1.3) }
                        }
                        Text {
                            anchors.right: parent.right; y: 4
                            text: mi.percentage + "%"
                            color: "white"; font.family: "Segoe UI"; font.pixelSize: 13
                        }
                    }
                    // eylemler: Windows 8 düz düğmeleri
                    Flow {
                        visible: (mi.actionLabels || []).length > 0
                        width: parent.width
                        spacing: 8
                        topPadding: 8
                        Repeater {
                            model: mi.actionLabels || []
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: Math.max(80, dt.implicitWidth + 24); height: 30
                                color: dma.pressed ? "white" : (dma.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
                                border.width: 2; border.color: "white"
                                Text {
                                    id: dt
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: dma.pressed ? renk.arkaPlan : "white"
                                    font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 13
                                }
                                MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; onClicked: mi.actionInvoked(mi.actionNames[index]) }
                            }
                        }
                    }
                }

                // sağ altta uygulamanın küçük logosu
                Kirigami.Icon {
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    width: 30; height: 30
                    source: kutu.logo || ""
                    visible: valid
                }

                // kapatma düğmesi (fare üzerindeyken)
                Rectangle {
                    anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 4
                    width: 26; height: 26
                    visible: kok.containsMouse && (mi.closable || mi.dismissable)
                    color: kma.pressed ? Qt.rgba(1, 1, 1, 0.35) : (kma.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent")
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "white"; font.family: "Segoe UI Symbol"; font.pixelSize: 12
                    }
                    MouseArea {
                        id: kma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: mi.dismissable && notificationPopup.isJob ? mi.dismissClicked() : mi.closeClicked()
                    }
                }
            }
        }
    }
}
