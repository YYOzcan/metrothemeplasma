// Windows 8.1 Update açılır menüsü (Başlangıç'ta sağ tık, kullanıcı/güç menüleri, Win+X)
// ogeler: [{metin, eylem: function, ayirici, alt: [...], devreDisi, isaretli}]
import QtQuick

Item {
    id: menu
    property var ogeler: []
    property bool acik: false
    property real menuX: 0
    property real menuY: 0
    property bool yukari: false        // menüyü noktanın üstüne aç
    property bool koyu: false          // Win+X menüsü koyu zeminli değil; Başlangıç menüsü açık zeminli
    property Item altMenu: null
    anchors.fill: parent
    visible: acik
    z: 1000

    function ac(x, y, liste, yukariAc) {
        ogeler = liste
        yukari = !!yukariAc
        menuX = Math.min(x, width - kutu.width - 4)
        var yy = yukari ? y - kutu.height : y
        menuY = Math.max(4, Math.min(yy, height - kutu.height - 4))
        acik = true
        kutu.forceActiveFocus()
    }
    function kapat() { acik = false; alt.acik = false }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: menu.kapat()
    }
    Rectangle {
        id: kutu
        x: menu.menuX; y: menu.menuY
        width: Math.max(220, sutun.implicitWidth + 2)
        height: sutun.implicitHeight + 12
        color: menu.koyu ? "#2b2b2b" : "white"
        border.color: menu.koyu ? "#444" : "#c8c8c8"
        border.width: 1
        focus: true
        Keys.onEscapePressed: menu.kapat()
        Column {
            id: sutun
            x: 1; y: 6
            width: kutu.width - 2
            Repeater {
                model: menu.ogeler
                delegate: Item {
                    id: og
                    required property var modelData
                    width: sutun.width
                    height: modelData.ayirici ? 9 : 30
                    Rectangle {
                        visible: !!og.modelData.ayirici
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10; width: parent.width - 20; height: 1
                        color: menu.koyu ? "#555" : "#d4d4d4"
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: !og.modelData.ayirici && oma.containsMouse && !og.modelData.devreDisi
                        color: menu.koyu ? "#404040" : "#dedede"
                    }
                    Text {
                        visible: !og.modelData.ayirici
                        x: 26; anchors.verticalCenter: parent.verticalCenter
                        text: og.modelData.metin || ""
                        font.family: "Segoe UI"; font.pixelSize: 15
                        color: og.modelData.devreDisi ? "#999" : (menu.koyu ? "white" : "black")
                        rightPadding: 40
                    }
                    Text {
                        visible: !!og.modelData.isaretli
                        x: 7; anchors.verticalCenter: parent.verticalCenter
                        text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 12
                        color: menu.koyu ? "white" : "black"
                    }
                    Text {
                        visible: !!og.modelData.alt
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 11
                        color: menu.koyu ? "white" : "black"
                    }
                    MouseArea {
                        id: oma
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !og.modelData.ayirici && !og.modelData.devreDisi
                        onEntered: {
                            if (og.modelData.alt) {
                                var p = og.mapToItem(menu, og.width - 2, -6)
                                alt.ac(p.x, p.y, og.modelData.alt)
                            } else if (alt.acik) {
                                alt.acik = false
                            }
                        }
                        onClicked: {
                            if (og.modelData.alt) return
                            var e = og.modelData.eylem
                            menu.kapat()
                            if (e) e()
                        }
                    }
                }
            }
        }
    }
    // tek düzey alt menü (Yeniden boyutlandır ▸)
    Rectangle {
        id: alt
        property bool acik: false
        property var liste: []
        function ac(x, y, l) { liste = l; alt.x = Math.min(x, menu.width - width - 4); alt.y = Math.min(y, menu.height - height - 4); acik = true }
        visible: acik && menu.acik
        width: 170; height: altSutun.implicitHeight + 12
        color: menu.koyu ? "#2b2b2b" : "white"
        border.color: menu.koyu ? "#444" : "#c8c8c8"
        Column {
            id: altSutun
            x: 1; y: 6; width: alt.width - 2
            Repeater {
                model: alt.liste
                delegate: Item {
                    required property var modelData
                    width: altSutun.width; height: 30
                    Rectangle { anchors.fill: parent; visible: ama.containsMouse; color: menu.koyu ? "#404040" : "#dedede" }
                    Text {
                        visible: !!parent.modelData.isaretli
                        x: 7; anchors.verticalCenter: parent.verticalCenter
                        text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 12
                        color: menu.koyu ? "white" : "black"
                    }
                    Text {
                        x: 26; anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.metin; font.family: "Segoe UI"; font.pixelSize: 15
                        color: menu.koyu ? "white" : "black"
                    }
                    MouseArea {
                        id: ama; anchors.fill: parent; hoverEnabled: true
                        onClicked: { var e = parent.modelData.eylem; menu.kapat(); if (e) e() }
                    }
                }
            }
        }
    }
}
