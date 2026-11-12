// Windows 8.1 Fotoğraflar: "Fotoğraflar" başlığı ve Resimler kitaplığının yatay kaydırılan ızgarası;
// tıklayınca siyah zeminde tam ekran görüntüleyici (fare kıpırdayınca kenarlarda oklar), uygulama
// çubuğunda Slayt gösterisi, Döndür, Kilit ekranı yap, Sil.
import QtQuick

Item {
    id: f
    readonly property string baslik: "Fotoğraflar"
    readonly property color zemin: "#1d1d1d"
    readonly property color cubukRengi: "#2b2b2b"
    property var resimler: []      // file:// adresleri
    property int acik: -1          // görüntülenen resim (-1: koleksiyon)
    property bool slayt: false
    property var donusler: ({})

    readonly property var solKomutlar: acik < 0 ? [] : [
        { glif: "", metin: "Slayt gösterisi", eylem: function () { f.slayt = true } },
        { glif: "", metin: "Döndür", eylem: function () { var d = Object.assign({}, f.donusler); d[f.resimler[f.acik]] = ((d[f.resimler[f.acik]] || 0) + 90) % 360; f.donusler = d } }
    ]
    readonly property var sagKomutlar: acik < 0
        ? [{ glif: "", metin: "Yenile", eylem: function () { f.yukle() } }]
        : [{ glif: "\ue1f6", metin: "Kilit ekranı yap", eylem: function () { f.kilitEkrani() } },
           { glif: "", metin: "Sil", eylem: function () { f.sil() } }]

    function yukle() {
        var l = Dosya.resimler(Dosya.ev + "/Resimler", 400)
        if (!l.length) l = Dosya.resimler(Dosya.ev + "/Pictures", 400)
        resimler = l
    }
    Component.onCompleted: yukle()
    function kilitEkrani() {
        // metro kilit ekranı resmi ([Kilit] resim) — Bilgisayar ayarları > Kilit ekranı ile aynı anahtar
        var yol = Dosya.yapilandirma + "/ayarlar.ini", ini = Dosya.oku(yol)
        var satir = "resim=" + resimler[acik]
        if (/\[Kilit\][^\[]*resim=/.test(ini)) ini = ini.replace(/(\[Kilit\][^\[]*?)resim=[^\n]*/, "$1" + satir)
        else ini += "\n[Kilit]\n" + satir + "\n"
        Dosya.yaz(yol, ini)
    }
    function sil() {
        Yardimci.calistir("gio", ["trash", resimler[acik]])     // Geri Dönüşüm Kutusu'na
        var l = resimler.slice(); l.splice(acik, 1); resimler = l
        if (acik >= l.length) acik = l.length - 1
    }

    // ------------------------------------------------------------------ koleksiyon
    Text {
        x: 120; y: 50
        visible: f.acik < 0
        text: "Fotoğraflar"
        color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56
    }
    Text {
        x: 120; y: 160
        visible: f.acik < 0 && f.resimler.length === 0
        text: "Resimler kitaplığınızda fotoğraf yok."
        color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 22
    }
    GridView {
        id: izgara
        visible: f.acik < 0
        x: 120; y: 160
        width: parent.width - 120; height: parent.height - 200
        flow: GridView.FlowTopToBottom
        cellWidth: 250; cellHeight: 250
        clip: true
        model: f.resimler
        boundsBehavior: Flickable.StopAtBounds
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.NoButton
            onWheel: w => izgara.contentX = Math.max(0, Math.min(izgara.contentWidth - izgara.width, izgara.contentX - w.angleDelta.y * 1.5))
        }
        delegate: Item {
            required property string modelData
            required property int index
            width: 250; height: 250
            Rectangle {
                anchors.fill: parent; anchors.margins: 5
                color: "#2b2b2b"
                Image {
                    anchors.fill: parent
                    source: modelData
                    sourceSize.width: 480
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                border.color: im.containsMouse ? "white" : "transparent"; border.width: 2
                MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; onClicked: f.acik = index }
            }
        }
    }

    // ------------------------------------------------------------------ görüntüleyici
    Rectangle {
        anchors.fill: parent
        visible: f.acik >= 0
        color: "black"
        Image {
            id: buyuk
            anchors.fill: parent
            source: f.acik >= 0 ? f.resimler[f.acik] : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            rotation: f.acik >= 0 ? (f.donusler[f.resimler[f.acik]] || 0) : 0
            Behavior on rotation { NumberAnimation { duration: 250 } }
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        // fare kıpırdayınca: geri düğmesi ve kenar okları
        property bool kontroller: false
        Timer { id: gizle; interval: 2500; onTriggered: parent.kontroller = false }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onPositionChanged: { parent.kontroller = true; gizle.restart() }
            onWheel: w => f.git(w.angleDelta.y < 0 ? 1 : -1)
        }
        Repeater {
            model: [[-1, ""], [1, ""]]
            delegate: Rectangle {
                required property var modelData
                visible: parent.kontroller && f.acik + modelData[0] >= 0 && f.acik + modelData[0] < f.resimler.length
                x: modelData[0] < 0 ? 0 : parent.width - width
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 80
                color: om.containsMouse ? "#5a5a5a" : "#333333"; opacity: 0.85
                Text { anchors.centerIn: parent; text: modelData[1]; font.family: "Segoe UI Symbol"; font.pixelSize: 18; color: "white" }
                MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; onClicked: f.git(modelData[0]) }
            }
        }
        Rectangle {
            visible: parent.kontroller
            x: 39; y: 39; width: 41; height: 41; radius: 21
            color: gm.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.4)
            border.color: "white"; border.width: 2
            Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: "white" }
            MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; onClicked: { f.slayt = false; f.acik = -1 } }
        }
    }
    function git(d) { var y = acik + d; if (y >= 0 && y < resimler.length) acik = y }
    Timer { interval: 4000; repeat: true; running: f.slayt && f.acik >= 0; onTriggered: f.acik = (f.acik + 1) % f.resimler.length }

    focus: true
    Keys.onPressed: e => {
        if (acik < 0) return
        if (e.key === Qt.Key_Right) f.git(1)
        else if (e.key === Qt.Key_Left) f.git(-1)
        else if (e.key === Qt.Key_Escape || e.key === Qt.Key_Backspace) { f.slayt = false; f.acik = -1 }
        else if (e.key === Qt.Key_Delete) f.sil()
        else return
        e.accepted = true
    }
}
