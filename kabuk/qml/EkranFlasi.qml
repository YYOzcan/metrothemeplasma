// Win+PrtSc: ekran kısa bir an kararır (Windows 8 ekran görüntüsü geri bildirimi)
import QtQuick
import QtQuick.Window

Window {
    id: pen
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput
    width: Screen.width; height: Screen.height
    title: "Ekran görüntüsü"
    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 15, 0, -1, "metro-flas")
    function parla() { visible = true; anim.restart() }
    Rectangle { id: perde; anchors.fill: parent; color: "black"; opacity: 0 }
    SequentialAnimation {
        id: anim
        PauseAnimation { duration: 250 }
        NumberAnimation { target: perde; property: "opacity"; from: 0; to: 0.5; duration: 60 }
        NumberAnimation { target: perde; property: "opacity"; to: 0; duration: 220 }
        ScriptAction { script: pen.visible = false }
    }
}
