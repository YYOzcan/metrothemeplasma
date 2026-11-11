// Windows 8.1 yuvarlak glif düğmesi (Uygulamalar oku, güç, ara, bölme geri düğmesi)
import QtQuick

Item {
    id: d
    property string glif: ""
    property real boyut: 32
    property color renk: "white"
    property color basiliRenk: "black"
    property real glifOlcek: 0.5
    property real donus: 0
    property bool halka: true
    signal tiklandi()
    width: boyut; height: boyut
    readonly property bool uzerinde: ma.containsMouse
    readonly property bool basili: ma.pressed

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: d.basili ? d.renk : (d.uzerinde ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
        border.width: d.halka ? Math.max(1.5, d.boyut / 16) : 0
        border.color: d.renk
    }
    Text {
        anchors.centerIn: parent
        text: d.glif
        font.family: "Segoe UI Symbol"
        font.pixelSize: d.boyut * d.glifOlcek
        color: d.basili ? d.basiliRenk : d.renk
        rotation: d.donus
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: d.tiklandi()
    }
}
