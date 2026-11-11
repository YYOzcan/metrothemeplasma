// Fotoğraflar canlı kutucuğu: Resimler klasöründen yavaş kayan slayt gösterisi
import QtQuick

Item {
    id: f
    property Item kutucuk
    property var resimler: []
    property int sira: 0
    clip: true
    Component.onCompleted: {
        var ev = Dosya.ev
        var l = Dosya.resimler(ev + "/Resimler", 80)
        if (l.length === 0) l = Dosya.resimler(ev + "/Pictures", 80)
        resimler = l
        sira = l.length ? Math.floor(Math.random() * l.length) : 0
    }
    Text {
        visible: f.resimler.length === 0
        anchors.centerIn: parent; anchors.verticalCenterOffset: -8
        text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: kutucuk.boyut === "kucuk" ? 30 : 52; color: "white"
    }
    Image {
        id: resim
        visible: f.resimler.length > 0
        width: parent.width * 1.15; height: parent.height * 1.15
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 640
        source: f.resimler.length ? f.resimler[f.sira % f.resimler.length] : ""
        x: 0; y: 0
        SequentialAnimation on x {
            loops: Animation.Infinite; running: f.resimler.length > 0
            NumberAnimation { from: 0; to: -f.width * 0.15; duration: 9000; easing.type: Easing.InOutSine }
            ScriptAction { script: f.sira++ }
            NumberAnimation { from: -f.width * 0.15; to: 0; duration: 9000; easing.type: Easing.InOutSine }
            ScriptAction { script: f.sira++ }
        }
    }
}
