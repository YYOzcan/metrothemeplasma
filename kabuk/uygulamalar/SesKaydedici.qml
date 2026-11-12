// Windows 8.1 Ses Kaydedici: ortada büyük mikrofon düğmesi ve süre; solda kayıtlar listesi
// (oynat, yeniden adlandırma yerine sil). Kayıtlar ~/Belgeler/Ses Kayıtları altına .m4a/.ogg.
import QtQuick
import QtMultimedia

Item {
    id: s
    readonly property string baslik: "Ses Kaydedici"
    readonly property color zemin: "#1d1d1d"
    readonly property color cubukRengi: "#2b2b2b"
    readonly property color turuncu: "#d24726"
    readonly property string dizin: Dosya.ev + "/Belgeler/Ses Kayıtları"
    property var kayitlar: []
    property int secili: -1
    readonly property var solKomutlar: []
    readonly property var sagKomutlar: secili >= 0 ? [{ glif: "", metin: "Sil", eylem: function () { s.sil() } }] : []

    function yukle() { kayitlar = Yardimci.dosyalar(dizin, ["*.m4a", "*.ogg", "*.wav", "*.mp3", "*.mka"]) }
    Component.onCompleted: { Yardimci.dizinOlustur(dizin); yukle() }
    function sil() {
        if (secili < 0) return
        oynatici.stop()
        Yardimci.calistir("gio", ["trash", kayitlar[secili].yol])
        var l = kayitlar.slice(); l.splice(secili, 1); kayitlar = l; secili = -1
    }
    function sure(ms) {
        var t = Math.floor(ms / 1000)
        return Math.floor(t / 60) + ":" + (t % 60 < 10 ? "0" : "") + t % 60
    }

    CaptureSession {
        id: oturum
        audioInput: AudioInput {}
        recorder: MediaRecorder {
            id: kaydedici
            mediaFormat { fileFormat: MediaFormat.Mpeg4Audio; audioCodec: MediaFormat.AudioCodec.AAC }
            quality: MediaRecorder.HighQuality
            onRecorderStateChanged: if (recorderState === MediaRecorder.StoppedState) Qt.callLater(s.yukle)
        }
    }
    readonly property bool kaydediyor: kaydedici.recorderState === MediaRecorder.RecordingState
    function kaydet() {
        if (kaydediyor) { kaydedici.stop(); return }
        oynatici.stop()
        var n = new Date()
        kaydedici.outputLocation = Dosya.url(dizin + "/Kayıt " + Qt.formatDateTime(n, "yyyy-MM-dd HH.mm.ss"))
        kaydedici.record()
    }

    MediaPlayer { id: oynatici; audioOutput: AudioOutput {} }

    // ------------------------------------------------------------------ kayıtlar (sol)
    Text {
        x: 120; y: 50
        text: "Ses Kaydedici"
        color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42
    }
    ListView {
        x: 120; y: 140
        width: 420; height: parent.height - 180
        clip: true
        model: s.kayitlar
        spacing: 4
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: 420; height: 64
            readonly property bool oynuyor: oynatici.source.toString() === Dosya.url(modelData.yol) && oynatici.playbackState === MediaPlayer.PlayingState
            color: s.secili === index ? s.turuncu : (km.containsMouse ? "#333333" : "#262626")
            Column {
                x: 14; anchors.verticalCenter: parent.verticalCenter
                Text { width: 330; text: modelData.ad; elide: Text.ElideRight; color: "white"; font.family: "Segoe UI"; font.pixelSize: 17 }
                Text { text: Qt.formatDateTime(modelData.tarih, "d MMMM yyyy HH:mm"); color: Qt.rgba(1, 1, 1, 0.7); font.family: "Segoe UI"; font.pixelSize: 13 }
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                text: parent.oynuyor ? "" : ""; font.family: "Segoe UI Symbol"; font.pixelSize: 20; color: "white"
            }
            MouseArea {
                id: km; anchors.fill: parent; hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: m => {
                    s.secili = index
                    if (m.button === Qt.RightButton) return
                    if (parent.oynuyor) { oynatici.pause(); return }
                    if (oynatici.source.toString() !== Dosya.url(modelData.yol)) oynatici.source = Dosya.url(modelData.yol)
                    oynatici.play()
                }
            }
        }
    }

    // ------------------------------------------------------------------ büyük kayıt düğmesi
    Item {
        x: 540 + (parent.width - 540 - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 300; height: 360
        Rectangle {
            id: dugme
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220; height: 220; radius: 110
            color: dm.pressed ? Qt.darker(s.turuncu, 1.2) : (s.kaydediyor ? s.turuncu : (dm.containsMouse ? "#3a3a3a" : "transparent"))
            border.color: s.kaydediyor ? s.turuncu : "white"; border.width: 6
            Text {
                anchors.centerIn: parent
                text: s.kaydediyor ? "" : ""
                font.family: "Segoe UI Symbol"; font.pixelSize: 90; color: "white"
            }
            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: s.kaydet() }
            SequentialAnimation on scale {
                running: s.kaydediyor; loops: Animation.Infinite
                NumberAnimation { to: 1.04; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dugme.bottom; anchors.topMargin: 30
            text: s.kaydediyor ? s.sure(kaydedici.duration) : (kaydedici.errorString !== "" ? kaydedici.errorString : "Kaydetmek için dokunun")
            color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: s.kaydediyor ? 56 : 22
        }
    }
}
