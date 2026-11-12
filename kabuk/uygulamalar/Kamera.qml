// Windows 8.1 Kamera: tam ekran önizleme, sağ kenarda büyük fotoğraf ve video düğmeleri,
// çekimler ~/Resimler/Film Rulosu (Windows'taki "Camera Roll") klasörüne.
import QtQuick
import QtMultimedia

Item {
    id: k
    readonly property string baslik: "Kamera"
    readonly property color renk: "#603cba"
    readonly property color zemin: "black"
    readonly property color cubukRengi: "#2b2b2b"
    readonly property var solKomutlar: [{ glif: "", metin: "Film rulosu", eylem: function () { Qt.openUrlExternally(Dosya.url(k.rulo)) } }]
    readonly property var sagKomutlar: kameralar.length > 1 ? [{ glif: "", metin: "Kamerayı değiştir", eylem: function () { k.kameraNo = (k.kameraNo + 1) % kameralar.length } }] : []
    readonly property string rulo: Yardimci.kitaplik("resim") + "/Film Rulosu"
    property int kameraNo: 0
    property string son: ""
    property bool video: false

    MediaDevices { id: aygitlar }
    readonly property var kameralar: aygitlar.videoInputs
    Component.onCompleted: Yardimci.dizinOlustur(rulo)

    CaptureSession {
        id: oturum
        camera: Camera { id: kamera; active: k.kameralar.length > 0; cameraDevice: k.kameralar.length ? k.kameralar[k.kameraNo] : aygitlar.defaultVideoInput }
        imageCapture: ImageCapture { id: foto; onImageSaved: (i, yol) => k.son = Dosya.url(yol) }
        recorder: MediaRecorder { id: kayit; quality: MediaRecorder.HighQuality }
        audioInput: k.video ? ses : null
        videoOutput: onizleme
    }
    AudioInput { id: ses }
    VideoOutput { id: onizleme; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }

    Column {
        anchors.centerIn: parent
        visible: k.kameralar.length === 0
        spacing: 14
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 90; color: "#555" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Kameranızı bulamıyoruz"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 40 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Kameranın bağlı ve başka bir uygulama tarafından kullanılmıyor olduğundan emin olun."; color: "#bdbdbd"; font.family: "Segoe UI"; font.pixelSize: 18 }
    }

    // sağ kenar: video / fotoğraf düğmeleri (Windows 8.1 Kamera)
    Column {
        visible: k.kameralar.length > 0
        anchors.right: parent.right; anchors.rightMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        spacing: 30
        Repeater {
            model: [{ glif: "", video: true }, { glif: "", video: false }]
            delegate: Rectangle {
                required property var modelData
                readonly property bool kayitta: modelData.video && kayit.recorderState === MediaRecorder.RecordingState
                width: modelData.video === k.video ? 96 : 64; height: width; radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: kayitta ? "#e51400" : (dm.pressed ? "white" : Qt.rgba(0, 0, 0, 0.45))
                border.color: "white"; border.width: 3
                Text { anchors.centerIn: parent; text: parent.kayitta ? "" : modelData.glif; font.family: "Segoe UI Symbol"; font.pixelSize: parent.width * 0.38; color: dm.pressed ? "black" : "white" }
                MouseArea {
                    id: dm; anchors.fill: parent
                    onClicked: {
                        if (modelData.video !== k.video) { k.video = modelData.video; return }
                        if (!modelData.video) {
                            foto.captureToFile(k.rulo + "/WIN_" + new Date(new Date()).toLocaleString(Qt.locale("tr_TR"), "yyyyMMdd_HHmmss") + ".jpg")
                            flas.restart()
                        } else if (kayit.recorderState === MediaRecorder.RecordingState) kayit.stop()
                        else { kayit.outputLocation = Dosya.url(k.rulo + "/WIN_" + new Date(new Date()).toLocaleString(Qt.locale("tr_TR"), "yyyyMMdd_HHmmss")); kayit.record() }
                    }
                }
            }
        }
    }
    Text {
        visible: kayit.recorderState === MediaRecorder.RecordingState
        anchors.horizontalCenter: parent.horizontalCenter; y: 40
        text: Math.floor(kayit.duration / 60000) + ":" + ("0" + Math.floor(kayit.duration / 1000) % 60).slice(-2)
        color: "white"; font.family: "Segoe UI"; font.pixelSize: 30; style: Text.Outline; styleColor: "#80000000"
    }
    // son çekim (sol alt küçük resim)
    Image {
        visible: k.son !== ""
        anchors.left: parent.left; anchors.leftMargin: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40
        width: 120; height: 90; fillMode: Image.PreserveAspectCrop
        source: k.son
        MouseArea { anchors.fill: parent; onClicked: Qt.openUrlExternally(k.son) }
    }
    Rectangle { id: flasPerde; anchors.fill: parent; color: "white"; opacity: 0 }
    SequentialAnimation { id: flas; NumberAnimation { target: flasPerde; property: "opacity"; to: 0.8; duration: 40 } NumberAnimation { target: flasPerde; property: "opacity"; to: 0; duration: 200 } }
}
