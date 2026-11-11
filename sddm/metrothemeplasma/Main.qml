/*
    MetroThemePlasma — Windows 8.1 oturum açma ekranı (SDDM)

    1) Kilit perdesi: kilit ekranı resmi, sol altta saat ve tarih; tıkla, yukarı sürükle ya da tuşa bas.
    2) Oturum açma: Başlangıç zemin rengi; ortada hesap resmi, yanında ad, parola kutusu (göster + ok).
       Birden çok kullanıcı varsa sol üstte geri oku → kullanıcı listesi. Sağ altta güç, sol altta
       erişim kolaylığı; Windows'ta olmayan tek öğe sol alttaki küçük oturum türü seçicisidir.
    Renkler ve resimler theme.conf'tan (sudo kur.sh --sistem kullanıcının renklerini ve kendi Windows 8.1
    kopyasındaki resimleri metro/ altına kopyalar).
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.arkaPlan || "#180053"
    readonly property color vurgu: config.vurgu || "#4617b4"

    property bool perdeAcik: false
    property bool hata: false
    property bool bekliyor: false
    property bool liste: false               // kullanıcı listesi görünümü
    property int secili: Math.max(0, userModel.lastIndex)
    property int sessionIndex: sessionModel.lastIndex
    property date simdi: new Date()
    property string seciliAd: ""
    property string seciliGercekAd: ""
    property string seciliResim: ""

    function v(ad) { return Qt.resolvedUrl("metro/" + ad) }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.simdi = new Date() }

    function perdeyiKaldir() {
        if (root.perdeAcik) return
        root.perdeAcik = true
        perdeAnim.to = -root.height
        perdeAnim.restart()
        parola.forceActiveFocus()
    }
    function perdeyiIndir() {
        root.perdeAcik = false
        root.hata = false
        parola.text = ""
        perdeAnim.to = 0
        perdeAnim.restart()
        root.forceActiveFocus()
    }
    function gonder() {
        if (root.seciliAd === "") return
        root.bekliyor = true
        sddm.login(root.seciliAd, parola.text, root.sessionIndex)
    }
    function kullaniciSec(i, ad, gercek, resim) {
        root.secili = i
        root.seciliAd = ad
        root.seciliGercekAd = gercek
        root.seciliResim = resim
        root.liste = false
        root.hata = false
        parola.text = ""
        parola.forceActiveFocus()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.bekliyor = false
            root.hata = true
            parola.text = ""
            tamam.forceActiveFocus()
        }
        function onLoginSucceeded() { root.bekliyor = true }
    }

    // seçili kullanıcının bilgileri (model verisine temsilci üzerinden erişilir)
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            Component.onCompleted: if (index === root.secili) { root.seciliAd = name; root.seciliGercekAd = realName; root.seciliResim = icon }
        }
    }

    focus: true
    Keys.onPressed: event => {
        if (!root.perdeAcik) {
            root.perdeyiKaldir()
            if (event.text.length === 1 && event.text.charCodeAt(0) > 32) parola.text += event.text
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            if (root.liste) root.liste = false
            else root.perdeyiIndir()
            event.accepted = true
        }
    }

    component Halka: Item {
        id: h
        property real boyut: 40
        property bool calisiyor: true
        width: boyut; height: boyut
        property real zaman: 0
        NumberAnimation on zaman { from: 0; to: 4.4; duration: 4400; loops: Animation.Infinite; running: h.calisiyor && h.visible }
        readonly property var kareler: [[0.000, -110, null], [0.433, 10, [0.02, 0.33, 0.38, 0.77]], [1.200, 93, null],
            [1.617, 205, [0.57, 0.17, 0.95, 0.75]], [2.017, 357, [0, 0.19, 0.07, 0.72]], [2.783, 439, null], [3.217, 585, [0, 0, 0.95, 0.37]]]
        function bezier(p, x) {
            var lo = 0, hi = 1, t = x
            for (var i = 0; i < 20; i++) {
                t = (lo + hi) / 2
                var bx = 3 * (1 - t) * (1 - t) * t * p[0] + 3 * (1 - t) * t * t * p[2] + t * t * t
                if (bx < x) lo = t; else hi = t
            }
            return 3 * (1 - t) * (1 - t) * t * p[1] + 3 * (1 - t) * t * t * p[3] + t * t * t
        }
        function aci(u) {
            var k = kareler
            if (u <= 0) return k[0][1]
            for (var i = 1; i < k.length; i++) {
                if (u <= k[i][0]) {
                    var x = (u - k[i - 1][0]) / (k[i][0] - k[i - 1][0])
                    return k[i - 1][1] + (k[i][1] - k[i - 1][1]) * (k[i][2] ? bezier(k[i][2], x) : x)
                }
            }
            return k[k.length - 1][1]
        }
        Repeater {
            model: 5
            delegate: Item {
                required property int index
                anchors.fill: parent
                readonly property real u: h.zaman - index * 0.167
                visible: u >= 0 && u < 3.217
                rotation: h.aci(u) - 52
                Rectangle { width: h.boyut / 9; height: width; radius: width / 2; color: "white"; x: h.boyut / 2 - width / 2; y: 0 }
            }
        }
    }

    // ------------------------------------------------------------------ oturum açma
    Item {
        id: giris
        anchors.fill: parent
        opacity: root.perdeAcik ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // geri oku: kullanıcı listesi (birden çok kullanıcı varsa)
        Item {
            visible: userModel.count > 1 && !root.liste
            x: 40; y: 40; width: 44; height: 44
            Rectangle {
                anchors.fill: parent; radius: 22; color: geriMa.pressed ? "white" : "transparent"
                border.color: "white"; border.width: 2
                Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 22; color: geriMa.pressed ? root.color : "white" }
            }
            MouseArea { id: geriMa; anchors.fill: parent; onClicked: root.liste = true }
        }

        // tek kullanıcı görünümü
        Row {
            visible: !root.liste
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
                    readonly property bool varsayilan: root.seciliResim.length === 0 || root.seciliResim.indexOf("/sddm/faces/") >= 0
                                                       || root.seciliResim.indexOf("default") >= 0
                    source: varsayilan ? root.v("user-200.png") : root.seciliResim
                    onStatusChanged: if (status === Image.Error) source = root.v("user-200.png")
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                width: 340
                Text {
                    text: root.seciliGercekAd.length > 0 ? root.seciliGercekAd : root.seciliAd
                    color: "white"
                    font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 36
                }
                Row {
                    visible: !root.hata && !root.bekliyor
                    Rectangle {
                        width: 270; height: 32
                        color: "white"
                        TextInput {
                            id: parola
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 34
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: goster.pressed ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "●"
                            font.family: "Segoe UI"; font.pixelSize: 16
                            color: "black"
                            clip: true
                            Keys.onReturnPressed: root.gonder()
                            Keys.onEnterPressed: root.gonder()
                            Keys.onEscapePressed: root.perdeyiIndir()
                        }
                        Text {
                            visible: parola.text === ""
                            anchors.verticalCenter: parent.verticalCenter; x: 8
                            text: "Parola"; color: "#7a7a7a"; font.family: "Segoe UI"; font.pixelSize: 16
                        }
                        Rectangle {
                            visible: parola.text !== ""
                            anchors.right: parent.right; anchors.rightMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30; height: 30
                            color: goster.pressed ? "#333" : (goster.containsMouse ? "#ddd" : "transparent")
                            Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 15; color: goster.pressed ? "white" : "#333" }
                            MouseArea { id: goster; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                    Rectangle {
                        width: 32; height: 32
                        color: gonderMa.pressed ? "white" : (gonderMa.containsMouse ? Qt.lighter(root.vurgu, 1.3) : root.vurgu)
                        Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: gonderMa.pressed ? root.vurgu : "white" }
                        MouseArea { id: gonderMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.gonder() }
                    }
                }
                Text {
                    visible: keyboard.capsLock && !root.hata && !root.bekliyor
                    text: "Caps Lock açık"
                    color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
                }
                Column {
                    visible: root.hata
                    spacing: 16
                    Text { text: "Parola yanlış. Yeniden deneyin."; color: "white"; font.family: "Segoe UI"; font.pixelSize: 18 }
                    Rectangle {
                        id: tamam
                        width: 100; height: 32
                        color: tamamMa.pressed ? "white" : (tamamMa.containsMouse || activeFocus ? Qt.rgba(1, 1, 1, 0.2) : "transparent")
                        border.color: "white"; border.width: 2
                        Text { anchors.centerIn: parent; text: "Tamam"; color: tamamMa.pressed ? root.color : "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                        function kapat() { root.hata = false; parola.forceActiveFocus() }
                        Keys.onReturnPressed: kapat()
                        Keys.onEnterPressed: kapat()
                        Keys.onSpacePressed: kapat()
                        MouseArea { id: tamamMa; anchors.fill: parent; hoverEnabled: true; onClicked: tamam.kapat() }
                    }
                }
                Row {
                    visible: root.bekliyor
                    spacing: 12
                    Halka { boyut: 28; calisiyor: root.bekliyor }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Hoş geldiniz"; color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 22 }
                }
            }
        }

        // kullanıcı listesi
        Row {
            visible: root.liste
            anchors.centerIn: parent
            spacing: 30
            Repeater {
                model: userModel
                delegate: Item {
                    id: kt
                    required property int index
                    required property string name
                    required property string realName
                    required property string icon
                    width: 150; height: 200
                    Rectangle {
                        width: 150; height: 150
                        color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: ktMa.containsMouse ? 3 : 0; border.color: "white"
                        Image {
                            anchors.fill: parent; anchors.margins: parent.border.width
                            fillMode: Image.PreserveAspectCrop; sourceSize.width: 300
                            readonly property bool varsayilan: kt.icon.length === 0 || kt.icon.indexOf("/sddm/faces/") >= 0 || kt.icon.indexOf("default") >= 0
                            source: varsayilan ? root.v("user-200.png") : kt.icon
                            onStatusChanged: if (status === Image.Error) source = root.v("user-200.png")
                        }
                    }
                    Text {
                        y: 158; width: parent.width
                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        text: kt.realName.length > 0 ? kt.realName : kt.name
                        color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
                    }
                    MouseArea { id: ktMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.kullaniciSec(kt.index, kt.name, kt.realName, kt.icon) }
                }
            }
        }

        // sol alt: erişim kolaylığı + oturum türü
        Row {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 30
            spacing: 24
            Text { text: "♿"; font.family: "Segoe UI Symbol"; font.pixelSize: 26; color: "white"; opacity: 0.9 }
            Item {
                visible: sessionModel.rowCount() > 1
                width: oturumMetin.width + 24; height: 34
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.15); visible: oturumMa.containsMouse }
                Text {
                    id: oturumMetin
                    anchors.centerIn: parent
                    color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
                    text: ""
                }
                MouseArea { id: oturumMa; anchors.fill: parent; hoverEnabled: true; onClicked: oturumMenu.visible = !oturumMenu.visible }
            }
        }
        Repeater {
            model: sessionModel
            delegate: Item {
                required property int index
                required property string name
                visible: false
                readonly property bool etkin: index === root.sessionIndex
                onEtkinChanged: if (etkin) oturumMetin.text = name
                Component.onCompleted: if (etkin) oturumMetin.text = name
            }
        }
        Rectangle {
            id: oturumMenu
            visible: false
            anchors.left: parent.left; anchors.bottom: parent.bottom
            anchors.leftMargin: 80; anchors.bottomMargin: 72
            width: 280; height: oturumSutun.height + 12
            color: "white"; border.color: "#c8c8c8"
            Column {
                id: oturumSutun
                x: 1; y: 6; width: parent.width - 2
                Repeater {
                    model: sessionModel
                    delegate: Item {
                        required property int index
                        required property string name
                        width: oturumSutun.width; height: 32
                        Rectangle { anchors.fill: parent; color: "#dedede"; visible: sm.containsMouse }
                        Text { x: 8; anchors.verticalCenter: parent.verticalCenter; visible: parent.index === root.sessionIndex; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 11 }
                        Text { x: 26; anchors.verticalCenter: parent.verticalCenter; text: parent.name; font.family: "Segoe UI"; font.pixelSize: 15; color: "black" }
                        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: { root.sessionIndex = parent.index; oturumMenu.visible = false; parola.forceActiveFocus() } }
                    }
                }
            }
        }

        // sağ alt: güç
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
                    model: [["Uyku", 0], ["Kapat", 1], ["Yeniden başlat", 2]]
                    delegate: Item {
                        required property var modelData
                        width: gucSutun.width; height: 32
                        visible: modelData[1] === 0 ? sddm.canSuspend : (modelData[1] === 1 ? sddm.canPowerOff : sddm.canReboot)
                        Rectangle { anchors.fill: parent; color: "#dedede"; visible: gm.containsMouse }
                        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData[0]; font.family: "Segoe UI"; font.pixelSize: 15; color: "black" }
                        MouseArea {
                            id: gm; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                gucMenu.visible = false
                                if (parent.modelData[1] === 0) sddm.suspend()
                                else if (parent.modelData[1] === 1) sddm.powerOff()
                                else sddm.reboot()
                            }
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ perde
    Item {
        id: perde
        width: root.width; height: root.height
        y: 0
        NumberAnimation on y { id: perdeAnim; running: false; duration: 420; easing.type: Easing.OutQuint }
        Rectangle { anchors.fill: parent; color: "#1a1a1a" }
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.v(config.kilitResmi ? String(config.kilitResmi).replace("metro/", "") : "img100.jpg")
        }
        Column {
            x: 46
            anchors.bottom: parent.bottom; anchors.bottomMargin: 96
            Text {
                text: Qt.formatTime(root.simdi, "HH:mm")
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 132
            }
            Text {
                text: root.simdi.getDate() + " " + Qt.locale("tr_TR").standaloneMonthName(root.simdi.getMonth(), Locale.LongFormat)
                      + " " + Qt.locale("tr_TR").dayName(root.simdi.getDay(), Locale.LongFormat)
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 44
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: !root.perdeAcik
            property real basY: 0
            property bool surukle: false
            onPressed: mouse => { basY = mouse.y; surukle = false; perdeAnim.stop() }
            onPositionChanged: mouse => {
                var d = mouse.y - basY
                if (d < -6) surukle = true
                if (surukle) perde.y = Math.min(0, d)
            }
            onReleased: {
                if (!surukle || perde.y < -root.height / 5) root.perdeyiKaldir()
                else { perdeAnim.to = 0; perdeAnim.restart() }
            }
        }
    }

    Component.onCompleted: root.forceActiveFocus()
}
