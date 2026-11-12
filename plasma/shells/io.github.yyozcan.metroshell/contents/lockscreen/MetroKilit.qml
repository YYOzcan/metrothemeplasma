/*
    MetroThemePlasma — Windows 8.1 kilit ekranı (Windows+L, uyku dönüşü)

    1) Perde: kilit ekranı resmi, sol altta büyük saat ve tarih. Fareyle yukarı sürükle, tıkla ya da
       bir tuşa bas: perde yukarı kalkar.
    2) Oturum açma: Başlangıç ekranı zemin rengi, solda hesap resmi, sağda ad ve parola kutusu
       (göster düğmesi + ok). Yanlışta "Parola yanlış. Yeniden deneyin." ve Tamam (authui.dll metinleri).
    Renkler ve resim ~/.config/metrothemeplasma/ayarlar.ini'den ([Renk], [Kilit]).
    Kimlik doğrulama Plasma 6.8 kscreenlocker arabirimiyle (authenticator.respond / onSucceeded).
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtCore
import org.kde.plasma.private.sessions
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

Rectangle {
    id: ui
    color: renk.arkaPlan

    readonly property string veri: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/metrothemeplasma/"
    Settings {
        id: renk
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/metrothemeplasma/ayarlar.ini"
        category: "Renk"
        property string arkaPlan: "#180053"
        property string vurgu: "#4617b4"
    }
    Settings {
        id: kilit
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/metrothemeplasma/ayarlar.ini"
        category: "Kilit"
        property string resim: ""
    }

    property bool perdeAcik: false
    property bool hata: false
    property bool bekliyor: false
    property string pendingPassword
    property date simdi: new Date()

    readonly property string kullanici: kscreenlocker_userName
    readonly property string resim: kscreenlocker_userImage !== ""
        ? "file://" + kscreenlocker_userImage.split("/").map(encodeURIComponent).join("/") : ""

    Timer { interval: 1000; running: true; repeat: true; onTriggered: ui.simdi = new Date() }

    function perdeyiKaldir() {
        if (ui.perdeAcik) return
        ui.perdeAcik = true
        perdeAnim.to = -ui.height
        perdeAnim.restart()
        authenticator.startAuthenticating()
        parola.forceActiveFocus()
        bosta.restart()
    }
    function perdeyiIndir() {
        ui.perdeAcik = false
        ui.hata = false
        parola.text = ""
        perdeAnim.to = 0
        perdeAnim.restart()
        ui.forceActiveFocus()
    }
    function gonder() {
        ui.bekliyor = true
        if (authenticator.pamTimeout === true) {
            ui.pendingPassword = parola.text
        } else {
            authenticator.respond(parola.text)
        }
    }

    Connections {
        target: root
        function onClearPassword() { parola.text = "" }
    }
    Connections {
        target: authenticator
        ignoreUnknownSignals: true
        function onFailed(kind) {
            if (kind != 0) return
            ui.bekliyor = false
            parola.text = ""
            ui.hata = true
            authenticator.startAuthenticating()
            tamam.forceActiveFocus()
        }
        function onSucceeded() {
            authenticator.stopAuthenticating()
            Qt.quit()
        }
        function onPamTimeoutChanged() {
            if (!authenticator.pamTimeout && ui.pendingPassword.length > 0) {
                authenticator.respond(ui.pendingPassword)
                ui.pendingPassword = ""
            }
        }
    }
    Timer {
        interval: 1000
        running: !authenticator.unlocked
        repeat: true
        onTriggered: authenticator.startAuthenticating()
    }
    // oturum açma ekranında bir süre işlem yapılmazsa perde geri iner
    Timer { id: bosta; interval: 60000; onTriggered: if (parola.text === "" && !ui.hata) ui.perdeyiIndir() }

    SessionManagement { id: oturum }
    KeyboardIndicator.KeyState { id: buyukHarf; key: Qt.Key_CapsLock }

    focus: true
    Keys.onPressed: event => {
        bosta.restart()
        if (!ui.perdeAcik) {
            ui.perdeyiKaldir()
            if (event.text.length === 1 && event.text.charCodeAt(0) > 32) parola.text += event.text
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            ui.perdeyiIndir()
            event.accepted = true
        }
    }

    // ------------------------------------------------------------------ oturum açma
    Item {
        id: girisAlani
        anchors.fill: parent
        opacity: ui.perdeAcik ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Row {
            id: grup
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            spacing: 24
            Rectangle {
                width: 190; height: 190
                color: Qt.rgba(1, 1, 1, 0.15)
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 380
                    source: ui.resim !== "" ? ui.resim : ui.veri + "varlik/user-200.png"
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                width: 340
                Text {
                    text: ui.kullanici
                    color: "white"
                    font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 36
                }
                // parola + göster + ok
                Row {
                    visible: !ui.hata
                    spacing: 0
                    Rectangle {
                        width: 270; height: 32
                        color: "white"
                        border.color: parola.activeFocus ? "white" : "#d0d0d0"
                        TextInput {
                            id: parola
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 34
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: goster.pressed ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "●"
                            font.family: "Segoe UI"; font.pixelSize: 16
                            color: "black"
                            clip: true
                            enabled: !ui.bekliyor
                            onTextChanged: bosta.restart()
                            Keys.onReturnPressed: ui.gonder()
                            Keys.onEnterPressed: ui.gonder()
                            Keys.onEscapePressed: ui.perdeyiIndir()
                        }
                        Text {
                            visible: parola.text === "" && !ui.bekliyor
                            anchors.verticalCenter: parent.verticalCenter; x: 8
                            text: "Parola"
                            color: "#7a7a7a"; font.family: "Segoe UI"; font.pixelSize: 16
                        }
                        // parolayı göster (basılı tutunca)
                        Rectangle {
                            visible: parola.text !== ""
                            anchors.right: parent.right; anchors.rightMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30; height: 30
                            color: goster.pressed ? "#333" : (goster.containsMouse ? "#ddd" : "transparent")
                            Text {
                                anchors.centerIn: parent
                                text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 15
                                color: goster.pressed ? "white" : "#333"
                            }
                            MouseArea { id: goster; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                    Rectangle {
                        width: 32; height: 32
                        color: gonderMa.pressed ? "white" : (gonderMa.containsMouse ? Qt.lighter(renk.vurgu, 1.3) : renk.vurgu)
                        Text {
                            anchors.centerIn: parent
                            text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16
                            color: gonderMa.pressed ? renk.vurgu : "white"
                        }
                        MouseArea { id: gonderMa; anchors.fill: parent; hoverEnabled: true; onClicked: ui.gonder() }
                    }
                }
                Text {
                    visible: buyukHarf.locked && !ui.hata && ui.perdeAcik
                    text: "Caps Lock açık"
                    color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
                }
                // yanlış parola
                Column {
                    visible: ui.hata
                    spacing: 16
                    Text {
                        text: "Parola yanlış. Yeniden deneyin."
                        color: "white"; font.family: "Segoe UI"; font.pixelSize: 18
                    }
                    Rectangle {
                        id: tamam
                        width: 100; height: 32
                        color: tamamMa.pressed ? "white" : (tamamMa.containsMouse || activeFocus ? Qt.rgba(1, 1, 1, 0.2) : "transparent")
                        border.color: "white"; border.width: 2
                        Text {
                            anchors.centerIn: parent; text: "Tamam"
                            color: tamamMa.pressed ? renk.arkaPlan : "white"
                            font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15
                        }
                        Keys.onReturnPressed: { ui.hata = false; parola.forceActiveFocus() }
                        Keys.onEnterPressed: { ui.hata = false; parola.forceActiveFocus() }
                        Keys.onSpacePressed: { ui.hata = false; parola.forceActiveFocus() }
                        MouseArea { id: tamamMa; anchors.fill: parent; hoverEnabled: true; onClicked: { ui.hata = false; parola.forceActiveFocus() } }
                    }
                }
                IlerlemeHalkasi { visible: ui.bekliyor; boyut: 28; calisiyor: ui.bekliyor }
            }
        }

        // sol alt: erişim kolaylığı; sağ alt: güç
        Text {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 30
            text: "♿︎"; font.family: "Segoe UI Symbol"; font.pixelSize: 26; color: "white"
            opacity: 0.9
        }
        Item {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 22
            width: 44; height: 44
            Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.15); visible: gucMa.containsMouse }
            Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 26; color: "white" }
            MouseArea { id: gucMa; anchors.fill: parent; hoverEnabled: true; onClicked: gucMenu.visible = !gucMenu.visible }
        }
        Rectangle {
            id: gucMenu
            visible: false
            anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.rightMargin: 22; anchors.bottomMargin: 70
            width: 200; height: gucSutun.height + 12
            color: "white"; border.color: "#c8c8c8"
            Column {
                id: gucSutun
                x: 1; y: 6; width: parent.width - 2
                Repeater {
                    model: [["Uyku", function () { oturum.suspend() }], ["Kapat", function () { oturum.requestShutdown(0) }],
                            ["Yeniden başlat", function () { oturum.requestReboot(0) }]]
                    delegate: Item {
                        required property var modelData
                        width: gucSutun.width; height: 32
                        visible: modelData[0] !== "Uyku" || oturum.canSuspend
                        Rectangle { anchors.fill: parent; color: "#dedede"; visible: om.containsMouse }
                        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData[0]; font.family: "Segoe UI"; font.pixelSize: 15 }
                        MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; onClicked: { gucMenu.visible = false; parent.modelData[1]() } }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ perde (kilit ekranı resmi + saat)
    Item {
        id: perde
        width: ui.width; height: ui.height
        y: 0
        NumberAnimation on y { id: perdeAnim; running: false; duration: 450; easing.type: Easing.Bezier; easing.bezierCurve: [0.1, 0.9, 0.2, 1, 1, 1] }

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: kilit.resim !== "" ? kilit.resim : ui.veri + "win/Windows/Web/Screen/img100.jpg"
            asynchronous: false
        }
        Column {
            x: 46
            anchors.bottom: parent.bottom; anchors.bottomMargin: 96
            spacing: -18
            Text {
                text: Qt.formatTime(ui.simdi, "HH:mm")
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 132
                style: Text.Raised; styleColor: "#30000000"
            }
            Text {
                text: ui.simdi.getDate() + " " + Qt.locale("tr_TR").standaloneMonthName(ui.simdi.getMonth(), Locale.LongFormat)
                      + " " + Qt.locale("tr_TR").dayName(ui.simdi.getDay(), Locale.LongFormat)
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 44
                style: Text.Raised; styleColor: "#30000000"
                topPadding: 18
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: !ui.perdeAcik
            property real basY: 0
            property bool surukle: false
            onPressed: mouse => { basY = mouse.y; surukle = false; perdeAnim.stop() }
            onPositionChanged: mouse => {
                var d = mouse.y - basY
                if (d < -6) surukle = true
                if (surukle) perde.y = Math.min(0, d)
            }
            onReleased: mouse => {
                if (!surukle || perde.y < -ui.height / 5) ui.perdeyiKaldir()
                else { perdeAnim.to = 0; perdeAnim.restart() }
            }
        }
    }

    Loader {
        z: 30
        active: root.viewVisible
        source: "file:///usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockOsd.qml"
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 20 }
    }

    Component.onCompleted: {
        authenticator.startAuthenticating()
        ui.forceActiveFocus()
    }
}
