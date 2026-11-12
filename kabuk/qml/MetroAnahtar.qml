// Windows 8 açma/kapama anahtarı (ToggleSwitch)
import QtQuick

Item {
    id: a
    property bool acik: false
    property color vurgu: "#4617b4"
    property string acikMetin: "Açık"
    property string kapaliMetin: "Kapalı"
    property color renk: "white"
    signal degisti(bool deger)
    width: 140; height: 24
    Row {
        spacing: 12
        Rectangle {
            width: 46; height: 20
            color: "transparent"
            border.color: a.renk; border.width: 2
            Rectangle {
                x: 4; y: 4; height: 12
                width: a.acik ? 38 - 12 : 0
                color: a.vurgu
            }
            Rectangle {
                width: 12; height: 20
                x: a.acik ? parent.width - 12 : 0
                color: a.renk
                Behavior on x { NumberAnimation { duration: 120 } }
            }
        }
        Text {
            text: a.acik ? a.acikMetin : a.kapaliMetin
            color: a.renk; font.family: "Segoe UI"; font.pixelSize: 15
        }
    }
    MouseArea { anchors.fill: parent; onClicked: { a.acik = !a.acik; a.degisti(a.acik) } }
}
