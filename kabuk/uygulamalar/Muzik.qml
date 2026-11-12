// Windows 8.1 Müzik (Xbox Müzik): solda koyu gezinti bölmesi (Koleksiyon / Şimdi yürütülüyor), sağda
// albümler (klasörler) ve şarkılar; altta yürütme çubuğu. Kitaplık: ~/Müzik.
import QtQuick
import QtMultimedia

Item {
    id: m
    readonly property string baslik: "Müzik"
    readonly property color renk: "#ec4b19"
    readonly property color zemin: "#1f1f1f"
    readonly property color cubukRengi: "#2b2b2b"
    readonly property var solKomutlar: [
        { glif: "", metin: "Karıştır", eylem: function () { m.karistir = !m.karistir } },
        { glif: "", metin: "Yinele", eylem: function () { m.yinele = !m.yinele } }
    ]
    readonly property var sagKomutlar: [{ glif: "", metin: "Yenile", eylem: function () { m.yukle() } }]

    property var sarkilar: []
    property var albumler: []      // { ad, sanatci, kapak, sarkilar: [indis] }
    property var kuyruk: []        // şarkı indisleri
    property int sira: -1
    property bool karistir: false
    property bool yinele: false
    property string gorunum: "koleksiyon"
    property string seciliAlbum: ""

    function yukle() {
        var l = Yardimci.dosyaBul(Yardimci.kitaplik("muzik"), ["mp3", "flac", "ogg", "opus", "m4a", "aac", "wav", "wma"], 10000)
        l.sort(function (a, b) { return (a.klasor + "/" + a.ad).localeCompare(b.klasor + "/" + b.ad, "tr") })
        sarkilar = l
        var al = {}, sira_ = []
        for (var i = 0; i < l.length; i++) {
            var k = l[i].klasor || "Bilinmeyen albüm"
            if (!al[k]) { al[k] = { ad: k, sanatci: l[i].ust || "Bilinmeyen sanatçı", sarkilar: [], kapak: "" }; sira_.push(k) }
            al[k].sarkilar.push(i)
            if (!al[k].kapak) {
                var d = l[i].yol.slice(0, l[i].yol.lastIndexOf("/"))
                var aday = ["cover.jpg", "folder.jpg", "Cover.jpg", "Folder.jpg", "cover.png", "front.jpg"]
                for (var j = 0; j < aday.length; j++) if (Dosya.var(d + "/" + aday[j])) { al[k].kapak = Dosya.url(d + "/" + aday[j]); break }
            }
        }
        albumler = sira_.map(function (k) { return al[k] })
    }
    Component.onCompleted: yukle()

    function cal(liste, i) { kuyruk = liste; sira = i; oynat() }
    function oynat() {
        if (sira < 0 || sira >= kuyruk.length) return
        oynatici.source = sarkilar[kuyruk[sira]].url
        oynatici.play()
    }
    function sonraki() {
        if (!kuyruk.length) return
        if (karistir) sira = Math.floor(Math.random() * kuyruk.length)
        else if (sira + 1 < kuyruk.length) sira++
        else if (yinele) sira = 0
        else { oynatici.stop(); return }
        oynat()
    }
    function onceki() { if (oynatici.position > 3000) { oynatici.position = 0; return } if (sira > 0) { sira--; oynat() } }
    function sure(ms) { var s = Math.floor(ms / 1000); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60 }
    readonly property var calan: sira >= 0 && sira < kuyruk.length ? sarkilar[kuyruk[sira]] : null

    MediaPlayer {
        id: oynatici
        audioOutput: AudioOutput {}
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.EndOfMedia) m.sonraki()
    }

    // ---------------- gezinti bölmesi
    Rectangle {
        id: gezinti
        width: 320; height: parent.height - alt.height
        color: "#141414"
        Column {
            x: 30; y: 50; spacing: 10
            Text { text: "Müzik"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42; bottomPadding: 30 }
            Repeater {
                model: [["koleksiyon", "Koleksiyon"], ["simdi", "Şimdi yürütülüyor"]]
                delegate: Text {
                    required property var modelData
                    text: modelData[1]
                    color: m.gorunum === modelData[0] ? m.renk : (gm.containsMouse ? "white" : "#bdbdbd")
                    font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 22
                    MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; onClicked: { m.gorunum = modelData[0]; m.seciliAlbum = "" } }
                }
            }
        }
    }

    // ---------------- koleksiyon
    Item {
        x: gezinti.width; width: parent.width - x; height: parent.height - alt.height
        visible: m.gorunum === "koleksiyon"
        Text {
            x: 60; y: 50
            text: m.seciliAlbum !== "" ? m.seciliAlbum : "Koleksiyon"
            color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42
            MouseArea { anchors.fill: parent; enabled: m.seciliAlbum !== ""; onClicked: m.seciliAlbum = "" }
        }
        Text {
            x: 60; y: 130; width: parent.width - 120
            visible: m.sarkilar.length === 0
            wrapMode: Text.WordWrap
            text: "Müzik koleksiyonunuz boş. Müzik klasörünüze (" + Yardimci.kitaplik("muzik") + ") şarkı ekleyin; burada albümlere göre listelenir."
            color: "#bdbdbd"; font.family: "Segoe UI"; font.pixelSize: 18
        }
        GridView {
            x: 60; y: 130; width: parent.width - 60; height: parent.height - 150
            visible: m.seciliAlbum === "" && m.sarkilar.length > 0
            clip: true
            cellWidth: 200; cellHeight: 250
            model: m.albumler
            delegate: Item {
                required property var modelData
                width: 200; height: 250
                Rectangle {
                    width: 180; height: 180
                    color: Qt.hsla((modelData.ad.length * 37 % 360) / 360, 0.5, 0.35, 1)
                    Text { visible: modelData.kapak === ""; anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 64; color: "white" }
                    Image { anchors.fill: parent; source: modelData.kapak; fillMode: Image.PreserveAspectCrop; sourceSize.width: 360; asynchronous: true }
                    border.color: am.containsMouse ? "white" : "transparent"; border.width: 2
                }
                Text { y: 188; width: 180; elide: Text.ElideRight; text: modelData.ad; color: "white"; font.family: "Segoe UI"; font.pixelSize: 15 }
                Text { y: 210; width: 180; elide: Text.ElideRight; text: modelData.sanatci; color: "#9a9a9a"; font.family: "Segoe UI"; font.pixelSize: 13 }
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: m.seciliAlbum = modelData.ad; onDoubleClicked: m.cal(modelData.sarkilar, 0) }
            }
        }
        ListView {
            x: 60; y: 130; width: Math.min(900, parent.width - 120); height: parent.height - 150
            visible: m.seciliAlbum !== ""
            clip: true
            model: { for (var i = 0; i < m.albumler.length; i++) if (m.albumler[i].ad === m.seciliAlbum) return m.albumler[i].sarkilar; return [] }
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property var s: m.sarkilar[modelData]
                readonly property bool calan: m.calan === s
                width: ListView.view.width; height: 44
                color: sm.containsMouse ? "#333333" : (index % 2 ? "transparent" : "#262626")
                Text { x: 16; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 120; elide: Text.ElideRight
                       text: (parent.calan ? "▶  " : "") + parent.s.ad; color: parent.calan ? m.renk : "white"; font.family: "Segoe UI"; font.pixelSize: 16 }
                MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: m.cal(parent.ListView.view.model, index) }
            }
        }
    }

    // ---------------- şimdi yürütülüyor
    Item {
        x: gezinti.width; width: parent.width - x; height: parent.height - alt.height
        visible: m.gorunum === "simdi"
        Column {
            anchors.centerIn: parent
            spacing: 12
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 160; color: m.calan ? m.renk : "#444" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: m.calan ? m.calan.ad : "Hiçbir şey yürütülmüyor"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 40 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: m.calan ? (m.calan.ust || "") + (m.calan.ust && m.calan.klasor ? " — " : "") + (m.calan.klasor || "") : ""; color: "#9a9a9a"; font.family: "Segoe UI"; font.pixelSize: 20 }
        }
    }

    // ---------------- yürütme çubuğu
    Rectangle {
        id: alt
        anchors.bottom: parent.bottom
        width: parent.width; height: 90
        color: "#2b2b2b"
        Text {
            x: 30; y: 18; width: 380; elide: Text.ElideRight
            text: m.calan ? m.calan.ad : ""
            color: "white"; font.family: "Segoe UI"; font.pixelSize: 17
        }
        Text { x: 30; y: 44; width: 380; elide: Text.ElideRight; text: m.calan ? (m.calan.klasor || "") : ""; color: "#9a9a9a"; font.family: "Segoe UI"; font.pixelSize: 14 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; y: 8
            spacing: 18
            Repeater {
                model: [["", function () { m.onceki() }], [oynatici.playbackState === MediaPlayer.PlayingState ? "" : "", function () { if (oynatici.playbackState === MediaPlayer.PlayingState) oynatici.pause(); else if (m.calan) oynatici.play(); else if (m.sarkilar.length) m.cal(m.sarkilar.map(function (s, i) { return i }), 0) }], ["", function () { m.sonraki() }]]
                delegate: Rectangle {
                    required property var modelData
                    width: 44; height: 44; radius: 22
                    color: dm.pressed ? "white" : (dm.containsMouse ? "#444" : "transparent")
                    border.color: "white"; border.width: 2
                    Text { anchors.centerIn: parent; text: modelData[0]; font.family: "Segoe UI Symbol"; font.pixelSize: 17; color: dm.pressed ? "black" : "white" }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: modelData[1]() }
                }
            }
        }
        // ilerleme
        Item {
            anchors.horizontalCenter: parent.horizontalCenter; y: 62
            width: Math.min(600, parent.width - 900); height: 20
            Text { anchors.right: parent.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: m.sure(oynatici.position); color: "#bdbdbd"; font.family: "Segoe UI"; font.pixelSize: 13 }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; color: "#555"
                Rectangle { width: oynatici.duration > 0 ? parent.width * oynatici.position / oynatici.duration : 0; height: parent.height; color: m.renk } }
            Text { anchors.left: parent.right; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: m.sure(oynatici.duration); color: "#bdbdbd"; font.family: "Segoe UI"; font.pixelSize: 13 }
            MouseArea { anchors.fill: parent; onClicked: e => { if (oynatici.duration > 0) oynatici.position = e.x / width * oynatici.duration } }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 30; anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Text { text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 18; color: m.karistir ? m.renk : "#9a9a9a"; MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: m.karistir = !m.karistir } }
            Text { text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 18; color: m.yinele ? m.renk : "#9a9a9a"; MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: m.yinele = !m.yinele } }
        }
    }
    focus: true
    Keys.onSpacePressed: { if (oynatici.playbackState === MediaPlayer.PlayingState) oynatici.pause(); else if (m.calan) oynatici.play() }
}
