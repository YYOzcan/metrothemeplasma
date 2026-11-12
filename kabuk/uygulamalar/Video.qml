// Windows 8.1 Video (Xbox Video): "Kişisel videolar" ızgarası (~/Videolar), tıklayınca siyah zeminde
// tam ekran oynatıcı; fare kıpırdayınca alttan oynatma denetimleri (oynat/duraklat, ilerleme, süre).
import QtQuick
import QtMultimedia

Item {
    id: v
    readonly property string baslik: "Video"
    readonly property color renk: "#b91d47"
    readonly property color zemin: "#1d1d1d"
    readonly property color cubukRengi: "#2b2b2b"
    readonly property var solKomutlar: acik >= 0 ? [{ glif: "", metin: "Geri", eylem: function () { v.kapat() } }] : []
    readonly property var sagKomutlar: acik < 0 ? [{ glif: "", metin: "Yenile", eylem: function () { v.yukle() } }] : []
    property var videolar: []
    property int acik: -1

    function yukle() {
        var l = Yardimci.dosyaBul(Yardimci.kitaplik("video"), ["mp4", "mkv", "avi", "mov", "webm", "wmv", "m4v", "mpg", "mpeg", "3gp", "ts"], 3000)
        l.sort(function (a, b) { return b.tarih - a.tarih })
        videolar = l
    }
    Component.onCompleted: yukle()
    function ac(i) { acik = i; oynatici.source = videolar[i].url; oynatici.play(); denetim.goster() }
    function kapat() { oynatici.stop(); acik = -1 }
    function sure(ms) {
        var s = Math.floor(ms / 1000), sa = Math.floor(s / 3600), d = Math.floor(s % 3600 / 60), sn = s % 60
        return (sa ? sa + ":" + (d < 10 ? "0" : "") : "") + d + ":" + (sn < 10 ? "0" : "") + sn
    }
    function boyut(b) { return b > 1073741824 ? (b / 1073741824).toFixed(1).replace(".", ",") + " GB" : Math.round(b / 1048576) + " MB" }

    Text {
        x: 120; y: 50
        visible: v.acik < 0
        text: "Kişisel videolar"
        color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56
    }
    Text {
        x: 120; y: 150; width: parent.width - 240
        visible: v.acik < 0 && v.videolar.length === 0
        wrapMode: Text.WordWrap
        text: "Videolar klasörünüzde (" + Yardimci.kitaplik("video") + ") video yok."
        color: "#bdbdbd"; font.family: "Segoe UI"; font.pixelSize: 20
    }
    GridView {
        id: izgara
        visible: v.acik < 0
        x: 120; y: 150; width: parent.width - 120; height: parent.height - 190
        flow: GridView.FlowTopToBottom
        cellWidth: 330; cellHeight: 230
        clip: true
        model: v.videolar
        boundsBehavior: Flickable.StopAtBounds
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton
            onWheel: w => izgara.contentX = Math.max(0, Math.min(izgara.contentWidth - izgara.width, izgara.contentX - w.angleDelta.y * 1.5)) }
        delegate: Item {
            required property var modelData
            required property int index
            width: 330; height: 230
            Rectangle {
                width: 320; height: 180
                color: Qt.hsla(0.95, 0.6, 0.18 + (index % 5) * 0.03, 1)
                border.color: om.containsMouse ? "white" : "transparent"; border.width: 2
                Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 56; color: Qt.rgba(1, 1, 1, 0.85) }
            }
            Text { y: 186; width: 320; elide: Text.ElideRight; text: modelData.ad; color: "white"; font.family: "Segoe UI"; font.pixelSize: 15 }
            Text { y: 207; text: new Date(modelData.tarih).toLocaleDateString(Qt.locale("tr_TR"), "d MMMM yyyy") + " · " + v.boyut(modelData.boyut); color: "#9a9a9a"; font.family: "Segoe UI"; font.pixelSize: 13 }
            MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; onClicked: v.ac(index) }
        }
    }

    // ---------------- oynatıcı
    Rectangle {
        anchors.fill: parent
        visible: v.acik >= 0
        color: "black"
        MediaPlayer { id: oynatici; videoOutput: cikis; audioOutput: AudioOutput {} }
        VideoOutput { id: cikis; anchors.fill: parent }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onPositionChanged: denetim.goster()
            onClicked: { if (oynatici.playbackState === MediaPlayer.PlayingState) oynatici.pause(); else oynatici.play(); denetim.goster() }
        }
        Item {
            id: denetim
            anchors.fill: parent
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            function goster() { opacity = 1; gizle.restart() }
            Timer { id: gizle; interval: 2500; onTriggered: if (oynatici.playbackState === MediaPlayer.PlayingState) denetim.opacity = 0 }
            Rectangle {
                x: 39; y: 39; width: 41; height: 41; radius: 21
                color: gm.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.4)
                border.color: "white"; border.width: 2
                Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: "white" }
                MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; onClicked: v.kapat() }
            }
            Rectangle {
                anchors.bottom: parent.bottom; width: parent.width; height: 110
                color: Qt.rgba(0, 0, 0, 0.7)
                Text { x: 40; y: 14; width: parent.width - 80; elide: Text.ElideRight; text: v.acik >= 0 ? v.videolar[v.acik].ad : ""; color: "white"; font.family: "Segoe UI"; font.pixelSize: 20 }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 48
                    width: 50; height: 50; radius: 25
                    color: pm.pressed ? "white" : (pm.containsMouse ? "#444" : "transparent")
                    border.color: "white"; border.width: 2
                    Text { anchors.centerIn: parent; text: oynatici.playbackState === MediaPlayer.PlayingState ? "" : ""; font.family: "Segoe UI Symbol"; font.pixelSize: 20; color: pm.pressed ? "black" : "white" }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: { if (oynatici.playbackState === MediaPlayer.PlayingState) oynatici.pause(); else oynatici.play(); denetim.goster() } }
                }
                Item {
                    x: 120; y: 66; width: parent.width / 2 - 200; height: 16
                    Text { anchors.right: parent.left; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: v.sure(oynatici.position); color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; color: "#666"
                        Rectangle { width: oynatici.duration > 0 ? parent.width * oynatici.position / oynatici.duration : 0; height: parent.height; color: v.renk } }
                    MouseArea { anchors.fill: parent; onClicked: e => { if (oynatici.duration > 0) oynatici.position = e.x / width * oynatici.duration; denetim.goster() } }
                }
                Text { x: parent.width / 2 - 70; y: 64; text: v.sure(oynatici.duration); color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
            }
        }
    }
    focus: true
    Keys.onPressed: e => {
        if (v.acik < 0) return
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Backspace) v.kapat()
        else if (e.key === Qt.Key_Space) { if (oynatici.playbackState === MediaPlayer.PlayingState) oynatici.pause(); else oynatici.play() }
        else if (e.key === Qt.Key_Right) oynatici.position += 10000
        else if (e.key === Qt.Key_Left) oynatici.position = Math.max(0, oynatici.position - 10000)
        else return
        denetim.goster(); e.accepted = true
    }
}
