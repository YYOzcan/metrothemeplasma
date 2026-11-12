// Windows 8.1 uygulama çubuğu düğmesi: 40 px daire içinde glif, altında etiket
import QtQuick

Item {
    id: d
    property var komut: ({})
    signal calistir()
    width: 100; height: 76
    readonly property bool etkin: komut.etkin !== false
    opacity: etkin ? 1 : 0.4
    Rectangle {
        id: daire
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4; width: 40; height: 40; radius: 20
        color: ma.pressed ? "white" : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
        border.color: "white"; border.width: 2
        Text {
            anchors.centerIn: parent
            text: d.komut.glif || ""
            font.family: "Segoe UI Symbol"; font.pixelSize: 18
            color: ma.pressed ? "black" : "white"
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 50; width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: d.komut.metin || ""
        font.family: "Segoe UI"; font.pixelSize: 12
        color: "white"
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: d.etkin
        onClicked: { if (d.komut.eylem) d.komut.eylem(); d.calistir() }
    }
}
