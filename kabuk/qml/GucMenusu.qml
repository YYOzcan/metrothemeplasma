// Hızlı bağlantı menüsü (Win+X / Başlat düğmesine sağ tık) — Windows 8.1 Update öğeleri, twinui.dll metinleri
import QtQuick
import QtQuick.Window

Window {
    id: pen
    property var ana
    property bool acik: false
    property real menuX: 0
    property real menuY: -1
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Hızlı bağlantı menüsü"
    width: Screen.width; height: Screen.height

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 15, 1, -1, "metro-hizli-menu")

    function ac(x, y) {
        menuX = x < 0 ? 0 : x
        menuY = y
        alt.acik = false
        secim = -1
        acik = true
        visible = true
        requestActivate()
        kok.forceActiveFocus()
    }
    function kapat() { acik = false; visible = false; alt.acik = false }
    property int secim: -1

    function calistir(e) {
        kapat()
        pen.ana.hizliEylem(e)
    }

    // öğeler: [metin (& = kısayol harfi), eylem]; "-" ayırıcı
    readonly property var ogeler: [
        ["Programlar &ve Özellikler", "programlar"], ["Mo&bility Center", "mobility"], ["Güç &Seçenekleri", "guc"],
        ["&Olay Görüntüleyicisi", "olay"], ["S&istem", "sistem"], ["Aygıt &Yöneticisi", "aygit"],
        ["&Ağ Bağlantıları", "ag"], ["&Disk Yönetimi", "disk"], ["Bi&lgisayar Yönetimi", "bilgisayar"],
        ["Komu&t İstemi", "komut"], ["Komut İstemi (Yö&netici)", "komutYonetici"], "-",
        ["&Görev Yöneticisi", "gorev"], ["D&enetim Masası", "denetim"], ["Dosya Ge&zgini", "gezgin"],
        ["A&ra", "ara"], ["&Çalıştır", "calistir"], "-",
        ["&Kapatın veya oturumu kapatın", "kapat-alt"], ["&Masaüstü", "masaustu"]
    ]
    readonly property var kapatOgeleri: [
        ["&Oturumu kapatın", "oturum"], ["&Uyku", "uyku"], ["&Kapatın", "kapat"], ["&Yeniden başlatın", "yeniden"]
    ]
    function duz(m) { return m.replace("&", "") }
    function zengin(m) {
        var i = m.indexOf("&")
        if (i < 0) return m
        return m.substring(0, i) + "<u>" + m.charAt(i + 1) + "</u>" + m.substring(i + 2)
    }
    function harf(m) { var i = m.indexOf("&"); return i < 0 ? "" : m.charAt(i + 1).toLocaleLowerCase(Qt.locale("tr_TR")) }

    Item {
        id: kok
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: { if (alt.acik) alt.acik = false; else pen.kapat() }
        Keys.onUpPressed: { do { pen.secim = (pen.secim + pen.ogeler.length - 1) % pen.ogeler.length } while (pen.ogeler[pen.secim] === "-") }
        Keys.onDownPressed: { do { pen.secim = (pen.secim + 1) % pen.ogeler.length } while (pen.ogeler[pen.secim] === "-") }
        Keys.onRightPressed: if (pen.secim >= 0 && pen.ogeler[pen.secim][1] === "kapat-alt") alt.acik = true
        Keys.onLeftPressed: alt.acik = false
        Keys.onReturnPressed: {
            if (pen.secim < 0) return
            var o = pen.ogeler[pen.secim]
            if (o[1] === "kapat-alt") alt.acik = true
            else pen.calistir(o[1])
        }
        Keys.onPressed: event => {
            var t = event.text.toLocaleLowerCase(Qt.locale("tr_TR"))
            if (t === "") return
            var liste = alt.acik ? pen.kapatOgeleri : pen.ogeler
            for (var i = 0; i < liste.length; i++) {
                if (liste[i] !== "-" && pen.harf(liste[i][0]) === t) {
                    if (liste[i][1] === "kapat-alt") alt.acik = true
                    else pen.calistir(liste[i][1])
                    event.accepted = true
                    return
                }
            }
        }

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: pen.kapat() }

        Rectangle {
            id: kutu
            x: pen.menuX
            y: pen.menuY < 0 ? pen.height - 40 - height : Math.min(pen.menuY, pen.height - height)
            width: 260
            height: sutun.height + 6
            color: "#f0f0f0"
            border.color: "#979797"
            MouseArea { anchors.fill: parent }
            Column {
                id: sutun
                x: 3; y: 3
                width: kutu.width - 6
                Repeater {
                    model: pen.ogeler
                    delegate: Item {
                        id: og
                        required property var modelData
                        required property int index
                        readonly property bool ayirici: modelData === "-"
                        width: sutun.width
                        height: ayirici ? 9 : 26
                        Rectangle {
                            visible: og.ayirici
                            x: 30; y: 4; width: parent.width - 32; height: 1; color: "#d7d7d7"
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: !og.ayirici && pen.secim === og.index
                            color: "#d1e2f2"; border.color: "#78aee5"
                        }
                        Text {
                            visible: !og.ayirici
                            x: 32; anchors.verticalCenter: parent.verticalCenter
                            textFormat: Text.StyledText
                            text: og.ayirici ? "" : pen.zengin(og.modelData[0])
                            font.family: "Segoe UI"; font.pixelSize: 12
                            color: "black"
                        }
                        Text {
                            visible: !og.ayirici && og.modelData[1] === "kapat-alt"
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▶"; font.pixelSize: 8; color: "black"
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !og.ayirici
                            hoverEnabled: true
                            onEntered: {
                                pen.secim = og.index
                                if (og.modelData[1] === "kapat-alt") { alt.y = og.y; alt.acik = true }
                                else alt.acik = false
                            }
                            onClicked: {
                                if (og.modelData[1] === "kapat-alt") alt.acik = true
                                else pen.calistir(og.modelData[1])
                            }
                        }
                    }
                }
            }
            // alt menü
            Rectangle {
                id: alt
                property bool acik: false
                property int secim: -1
                visible: acik
                x: kutu.width - 4
                width: 200; height: altSutun.height + 6
                color: "#f0f0f0"; border.color: "#979797"
                Column {
                    id: altSutun
                    x: 3; y: 3; width: alt.width - 6
                    Repeater {
                        model: pen.kapatOgeleri
                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: altSutun.width; height: 26
                            Rectangle { anchors.fill: parent; visible: aam.containsMouse; color: "#d1e2f2"; border.color: "#78aee5" }
                            Text {
                                x: 32; anchors.verticalCenter: parent.verticalCenter
                                textFormat: Text.StyledText
                                text: pen.zengin(modelData[0])
                                font.family: "Segoe UI"; font.pixelSize: 12; color: "black"
                            }
                            MouseArea { id: aam; anchors.fill: parent; hoverEnabled: true; onClicked: pen.calistir(modelData[1]) }
                        }
                    }
                }
            }
        }
    }
}
