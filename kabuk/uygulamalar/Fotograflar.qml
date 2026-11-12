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

    readonly property var solKomutlar: aktarDizin !== "" ? aktarSol : acik < 0 ? [] : [
        { glif: "", metin: "Slayt gösterisi", eylem: function () { f.slayt = true } },
        { glif: "", metin: "Döndür", eylem: function () { var d = Object.assign({}, f.donusler); d[f.resimler[f.acik]] = ((d[f.resimler[f.acik]] || 0) + 90) % 360; f.donusler = d } }
    ]
    readonly property var sagKomutlar: aktarDizin !== "" ? aktarSag : acik < 0
        ? [{ glif: "", metin: "Yenile", eylem: function () { f.yukle() } }]
        : [{ glif: "\ue1f6", metin: "Kilit ekranı yap", eylem: function () { f.kilitEkrani() } },
           { glif: "", metin: "Sil", eylem: function () { f.sil() } }]

    function yukle() {
        var l = Dosya.resimler(Dosya.ev + "/Resimler", 400)
        if (!l.length) l = Dosya.resimler(Dosya.ev + "/Pictures", 400)
        resimler = l
    }
    Component.onCompleted: { yukle(); argumanlariIsle() }

    // ------------------------------------------------------------------ içeri aktar (Otomatik Kullan)
    // Windows 8.1: aygıttaki bütün fotoğraf ve videolar seçili gelir; "İçeri aktar" Resimler altında
    // tarihli bir klasöre kopyalar
    property string aktarDizin: ""
    property var aktarOgeler: []
    property var secim: ({})
    property int seciliSayisi: 0
    property bool aktariliyor: false
    property int aktarN: 0
    property int aktarToplam: 0
    property string aktarSonuc: ""
    property string aktarHedef: ""
    readonly property var aktarSol: aktariliyor || aktarSonuc !== "" ? [] : [
        { glif: "\ue14e", metin: "Tümünü seç", eylem: function () { f.hepsiniSec(true) } },
        { glif: "\ue1c5", metin: "Tümünü temizle", eylem: function () { f.hepsiniSec(false) } }
    ]
    readonly property var aktarSag: aktariliyor || aktarSonuc !== "" ? [] : [
        { glif: "\ue118", metin: "İçeri aktar", etkin: seciliSayisi > 0, eylem: function () { f.iceriAktar() } }
    ]
    // sınama: METRO_SINAMA_KIP=aktar içeri aktarmayı kendisi başlatır
    Timer { interval: 2000; running: SinamaKip === "aktar" && f.aktarDizin !== ""; onTriggered: f.iceriAktar() }
    function argumanlariIsle() {
        var a = Yardimci.argumanlar, i = a.indexOf("--iceri-aktar")
        if (i >= 0 && i + 1 < a.length) aktarBasla(a[i + 1])
    }
    Connections {
        target: Yardimci
        function onArgumanlarDegisti() { f.argumanlariIsle() }
        function onKopyaIlerleme(n, toplam) { f.aktarN = n; f.aktarToplam = toplam }
        function onKopyaBitti(n, hedef) {
            f.aktariliyor = false
            f.aktarHedef = hedef
            f.aktarSonuc = n + " öğe içeri aktarıldı"
            f.yukle()
        }
    }
    function aktarBasla(dizin) {
        acik = -1; slayt = false
        aktarDizin = dizin
        aktarSonuc = ""; aktarHedef = ""
        aktarOgeler = Yardimci.medyaBul(dizin, 2000)
        hepsiniSec(true)
    }
    function hepsiniSec(d) {
        var m = {}
        for (var i = 0; i < aktarOgeler.length; i++) m[i] = d
        secim = m; seciliSayisi = d ? aktarOgeler.length : 0
    }
    function degistir(i) {
        var m = Object.assign({}, secim); m[i] = !m[i]; secim = m
        seciliSayisi += m[i] ? 1 : -1
    }
    function iceriAktar() {
        var l = []
        for (var i = 0; i < aktarOgeler.length; i++) if (secim[i]) l.push(aktarOgeler[i].yol)
        if (!l.length) return
        aktariliyor = true; aktarN = 0; aktarToplam = l.length
        var kok = Dosya.var(Dosya.ev + "/Resimler") ? Dosya.ev + "/Resimler" : Dosya.ev + "/Pictures"
        Yardimci.kopyala(l, kok + "/" + Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }
    Rectangle {
        anchors.fill: parent
        visible: f.aktarDizin !== ""
        color: f.zemin
        z: 5
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton }
        Text {
            x: 120; y: 50
            text: "İçeri aktar"
            color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56
        }
        Text {
            x: 120; y: 128
            text: f.aktarOgeler.length === 0 ? "Bu aygıtta fotoğraf ya da video bulunamadı."
                  : (f.aktariliyor ? f.aktarN + " / " + f.aktarToplam + " öğe içeri aktarılıyor..."
                  : (f.aktarSonuc !== "" ? f.aktarSonuc : f.seciliSayisi + " / " + f.aktarOgeler.length + " öğe seçildi"))
            color: "#d0d0d0"; font.family: "Segoe UI"; font.pixelSize: 20
        }
        // ilerleme çubuğu (Windows 8 belirli ilerleme)
        Rectangle {
            visible: f.aktariliyor
            x: 120; y: 166; width: 400; height: 4; color: "#3a3a3a"
            Rectangle { width: parent.width * (f.aktarToplam ? f.aktarN / f.aktarToplam : 0); height: parent.height; color: "#00a3a3" }
        }
        Row {
            visible: f.aktarSonuc !== ""
            x: 120; y: 180; spacing: 12
            Repeater {
                model: [["Klasörü aç", function () { Qt.openUrlExternally(Dosya.url(f.aktarHedef)) }],
                        ["Fotoğraflara dön", function () { f.aktarDizin = "" }]]
                delegate: Rectangle {
                    required property var modelData
                    width: dm.implicitWidth + 30; height: 36
                    color: da.pressed ? "white" : (da.containsMouse ? "#3a3a3a" : "transparent")
                    border.color: "white"; border.width: 2
                    Text { id: dm; anchors.centerIn: parent; text: modelData[0]; color: da.pressed ? "black" : "white"; font.family: "Segoe UI"; font.weight: Font.DemiBold; font.pixelSize: 15 }
                    MouseArea { id: da; anchors.fill: parent; hoverEnabled: true; onClicked: modelData[1]() }
                }
            }
        }
        GridView {
            id: aktarIzgara
            visible: f.aktarSonuc === ""
            x: 120; y: 190
            width: parent.width - 120; height: parent.height - 230
            flow: GridView.FlowTopToBottom
            cellWidth: 200; cellHeight: 200
            clip: true
            model: f.aktarOgeler
            boundsBehavior: Flickable.StopAtBounds
            MouseArea {
                anchors.fill: parent; acceptedButtons: Qt.NoButton
                onWheel: w => aktarIzgara.contentX = Math.max(0, Math.min(aktarIzgara.contentWidth - aktarIzgara.width, aktarIzgara.contentX - w.angleDelta.y * 1.5))
            }
            delegate: Item {
                required property var modelData
                required property int index
                width: 200; height: 200
                Rectangle {
                    anchors.fill: parent; anchors.margins: 5
                    color: "#2b2b2b"
                    Image {
                        anchors.fill: parent
                        visible: !modelData.video
                        source: modelData.video ? "" : modelData.url
                        sourceSize.width: 380
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Text { visible: modelData.video; anchors.centerIn: parent; text: "\ue116"; font.family: "Segoe UI Symbol"; font.pixelSize: 48; color: "white" }
                    // Windows 8 seçim: kenarlık ve sağ üst köşede onay işareti
                    readonly property bool secili: !!f.secim[index]
                    border.color: secili ? "#00a3a3" : "transparent"; border.width: 4
                    Rectangle {
                        visible: parent.secili
                        anchors.right: parent.right; anchors.top: parent.top
                        width: 34; height: 34; color: "transparent"
                        Canvas {
                            anchors.fill: parent
                            onPaint: { var c = getContext("2d"); c.reset(); c.fillStyle = "#00a3a3"; c.beginPath(); c.moveTo(0, 0); c.lineTo(34, 0); c.lineTo(34, 34); c.closePath(); c.fill() }
                        }
                        Text { x: 17; y: 1; text: "\ue10b"; font.family: "Segoe UI Symbol"; font.pixelSize: 13; color: "white" }
                    }
                    MouseArea { anchors.fill: parent; enabled: !f.aktariliyor; onClicked: f.degistir(index) }
                }
            }
        }
    }
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
