/*
    MetroThemePlasma — kilit ekranı kökü
    Windows 8.1 kilit ekranını (MetroKilit.qml) yükler. Plasma'nın kimlik doğrulama arabirimi
    bu sürümde beklenen biçimde değilse ya da Metro arayüzü yüklenemezse Plasma'nın kendi kilit
    ekranı açılır: KDE güncellemelerinden sonra kilit ekranı asla kilitli kalmaz.
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

Item {
    id: root
    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    // kscreenlocker'ın baktığı özellikler
    property bool viewVisible: false

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    readonly property url stok: "file:///usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml"
    readonly property bool uyumlu: typeof authenticator !== "undefined" && authenticator !== null
                                   && typeof authenticator.respond === "function"
                                   && typeof authenticator.startAuthenticating === "function"
                                   && typeof authenticator.stopAuthenticating === "function"
                                   && typeof kscreenlocker_userName !== "undefined"

    Loader {
        id: arayuz
        anchors.fill: parent
        focus: true
        source: root.uyumlu ? Qt.resolvedUrl("MetroKilit.qml") : root.stok
        onStatusChanged: {
            if (status === Loader.Error && source.toString() !== root.stok.toString()) {
                console.warn("MetroThemePlasma: Metro kilit ekranı yüklenemedi, Plasma'nınki kullanılıyor");
                source = root.stok;
            }
        }
    }
}
