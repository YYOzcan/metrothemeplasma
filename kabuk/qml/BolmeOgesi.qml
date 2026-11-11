// Bölmelerdeki metin bağlantısı (Denetim Masası, Kişiselleştirme ...)
import QtQuick

Item {
    id: o
    property string metin
    property string alt: ""
    property int boyut: 20
    signal tiklandi()
    width: parent ? parent.width : 300
    height: Math.max(40, sutun.height + 12)
    Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, ma.pressed ? 0.25 : 0.12); visible: ma.containsMouse }
    Column {
        id: sutun
        x: 0; anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        Text { width: parent.width; text: o.metin; color: "white"; elide: Text.ElideRight; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: o.boyut }
        Text { visible: o.alt !== ""; width: parent.width; text: o.alt; color: Qt.rgba(1, 1, 1, 0.7); elide: Text.ElideRight; font.family: "Segoe UI"; font.pixelSize: 14 }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: o.tiklandi() }
}
