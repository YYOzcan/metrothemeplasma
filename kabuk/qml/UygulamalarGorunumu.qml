// Windows 8.1 Update "Uygulamalar" görünümü: sütunlara akan, harf/kategori gruplu uygulama listesi
import QtQuick

Item {
    id: g
    property var tema
    property var ana
    property var baslangic
    property string filtre: ""
    property var ogeler: []          // {baslik} veya uygulama
    property var yerler: []          // {x, y, oge}
    property real genislik: 0
    readonly property int sutunGenislik: 284
    readonly property int ogeYukseklik: 50
    readonly property int ust: 180
    readonly property int satirSayisi: Math.max(3, Math.floor((height - ust - 80) / ogeYukseklik))

    // semantik yakınlaştırma: başlığa tıklayınca / Ctrl+tekerlekle harf (kategori) ızgarası
    property bool uzak: false
    property real uzakT: uzak ? 1 : 0
    Behavior on uzakT { NumberAnimation { duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: g.tema.pvl } }
    readonly property var basliklar: {
        var l = []
        for (var i = 0; i < yerler.length; i++) if (yerler[i].oge.baslik !== undefined) l.push({ ad: yerler[i].oge.baslik, x: yerler[i].x })
        return l
    }
    function basligaGit(x) {
        uzak = false
        kaydirici.contentX = Math.max(0, Math.min(kaydirici.contentWidth - kaydirici.width, x))
    }

    function sifirla() {
        uzak = false
        filtre = ""
        aramaGirdi.text = ""
        kaydirici.contentX = 0
        yenile()
    }
    function yaz(metin) {
        aramaGirdi.forceActiveFocus()
        aramaGirdi.text += metin
    }

    readonly property var siralamaAdlari: ({ "ad": "ada göre", "tarih": "yükleme tarihine göre", "kullanim": "en çok kullanılana göre", "kategori": "kategoriye göre" })

    function yenile() {
        var l = Uygulamalar.hepsi()
        var s = tema.baslangic.siralama
        var cikti = []
        if (filtre !== "") {
            var f = filtre.toLocaleLowerCase(Qt.locale("tr_TR"))
            l = l.filter(function (a) { return a.anahtar.indexOf(f) >= 0 })
            cikti = l
        } else if (s === "kullanim") {
            l.sort(function (a, b) { return b.kullanim - a.kullanim || a.ad.localeCompare(b.ad, "tr") })
            cikti = l
        } else if (s === "tarih") {
            l.sort(function (a, b) { return b.kurulum - a.kurulum })
            var sonAy = ""
            for (var i = 0; i < l.length; i++) {
                var d = new Date(l[i].kurulum)
                var ay = Qt.locale("tr_TR").standaloneMonthName(d.getMonth(), Locale.LongFormat) + " " + d.getFullYear()
                if (ay !== sonAy) { cikti.push({ baslik: ay }); sonAy = ay }
                cikti.push(l[i])
            }
        } else {
            var anahtar = s === "kategori" ? "kategori" : "harf"
            if (s === "kategori") l.sort(function (a, b) { return a.kategori.localeCompare(b.kategori, "tr") || a.ad.localeCompare(b.ad, "tr") })
            var son = null
            for (var j = 0; j < l.length; j++) {
                if (l[j][anahtar] !== son) { son = l[j][anahtar]; cikti.push({ baslik: son }) }
                cikti.push(l[j])
            }
        }
        ogeler = cikti
        yerlestir()
    }
    // Windows 8.1: öğeler (başlıklar dahil) sütunlara kesintisiz akar; başlık sütunun sonunda yalnız kalmaz
    function yerlestir() {
        var R = satirSayisi
        var y = [], sutun = 0, sira = 0
        for (var i = 0; i < ogeler.length; i++) {
            var o = ogeler[i]
            if (o.baslik !== undefined && sira > 0) {
                if (sira + 2 > R) { sutun++; sira = 0 }
                else sira++          // gruplar arasında bir satırlık boşluk
            }
            if (sira >= R) { sutun++; sira = 0 }
            y.push({ x: sutun * sutunGenislik, y: sira * ogeYukseklik, oge: o })
            sira++
        }
        yerler = y
        genislik = ogeler.length ? (sutun + 1) * sutunGenislik : 0
    }
    onSatirSayisiChanged: yerlestir()
    Connections { target: Uygulamalar; function onSayiDegisti() { if (g.visible) g.yenile() } }

    Text {
        id: baslik
        x: 120; y: 42
        text: "Uygulamalar"
        color: "white"
        font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 56
    }
    // sıralama seçici
    Item {
        x: baslik.x + baslik.width + 24
        y: baslik.y + baslik.baselineOffset - siralamaMetin.baselineOffset
        width: siralamaMetin.width + 30; height: 36
        Row {
            spacing: 8
            Text {
                id: siralamaMetin
                text: g.siralamaAdlari[g.tema.baslangic.siralama] || "ada göre"
                color: siralamaMa.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.85)
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 28
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 3
                text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: "white"
            }
        }
        MouseArea {
            id: siralamaMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                var p = mapToItem(g, 0, height + 6)
                var l = []
                var anahtarlar = ["ad", "tarih", "kullanim", "kategori"]
                for (var i = 0; i < anahtarlar.length; i++) {
                    (function (a) {
                        l.push({ metin: g.siralamaAdlari[a], isaretli: g.tema.baslangic.siralama === a,
                                 eylem: function () { g.tema.baslangic.siralama = a; g.yenile() } })
                    })(anahtarlar[i])
                }
                menu.ac(p.x, p.y, l)
            }
        }
    }
    // arama kutusu
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 40
        y: 58
        width: 280; height: 32
        color: aramaGirdi.activeFocus || aramaGirdi.text !== "" ? "white" : Qt.rgba(1, 1, 1, 0.85)
        TextInput {
            id: aramaGirdi
            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 36
            verticalAlignment: TextInput.AlignVCenter
            font.family: "Segoe UI"; font.pixelSize: 15
            color: "black"
            clip: true
            onTextChanged: { g.filtre = text; g.yenile(); kaydirici.contentX = 0 }
            Keys.onEscapePressed: { if (text !== "") text = ""; else g.baslangic.sayfa = 0 }
            Keys.onReturnPressed: {
                for (var i = 0; i < g.ogeler.length; i++) if (g.ogeler[i].kimlik) { g.ana.kutucukCalistir("uygulama", g.ogeler[i].kimlik); return }
            }
        }
        Text {
            visible: aramaGirdi.text === ""
            anchors.verticalCenter: parent.verticalCenter; x: 8
            text: "Ara"; color: "#666"; font.family: "Segoe UI"; font.pixelSize: 15
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 15; color: "#333"
        }
    }

    Flickable {
        id: kaydirici
        y: g.ust - 20
        // uzaklaşırken liste küçülerek kaybolur
        opacity: 1 - g.uzakT
        visible: opacity > 0.01
        scale: 1 - 0.3 * g.uzakT
        transformOrigin: Item.Left
        width: g.width; height: g.height - y
        contentWidth: Math.max(width, 120 + g.genislik + 120)
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: false
        Behavior on contentX { enabled: !kaydirici.flicking && !kaydirici.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        MouseArea {
            width: kaydirici.contentWidth; height: kaydirici.height
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                var d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                if (wheel.modifiers & Qt.ControlModifier) { if (d < 0 && g.basliklar.length) g.uzak = true; return }
                kaydirici.contentX = Math.max(0, Math.min(kaydirici.contentWidth - kaydirici.width, kaydirici.contentX - d * 1.6))
            }
        }
        Item {
            x: 120; y: 20
            Repeater {
                model: g.yerler
                delegate: Item {
                    id: og
                    required property var modelData
                    readonly property var o: modelData.oge
                    x: modelData.x; y: modelData.y
                    width: g.sutunGenislik - 14; height: g.ogeYukseklik - 6
                    // harf / kategori başlığı (tıklayınca harf ızgarası)
                    MouseArea {
                        anchors.fill: parent
                        enabled: og.o.baslik !== undefined
                        hoverEnabled: true
                        onClicked: g.uzak = true
                        Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.12); visible: parent.containsMouse }
                    }
                    Text {
                        visible: og.o.baslik !== undefined
                        anchors.verticalCenter: parent.verticalCenter
                        text: og.o.baslik !== undefined ? og.o.baslik : ""
                        color: "white"
                        font.family: "Segoe UI"; font.weight: og.o.baslik && og.o.baslik.length === 1 ? 300 : 350
                        font.pixelSize: og.o.baslik && og.o.baslik.length === 1 ? 32 : 22
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: og.o.kimlik !== undefined && (uma.containsMouse)
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    Rectangle {
                        id: kare
                        visible: og.o.kimlik !== undefined
                        width: 40; height: 40
                        anchors.verticalCenter: parent.verticalCenter
                        color: og.o.kimlik ? (og.o.renk || SimgeRengi.renk(og.o.simge, g.tema.vurgu)) : "transparent"
                        Image {
                            anchors.centerIn: parent
                            // Metro uygulaması simgesi zaten kutucuk renginde kare: kareyi doldurur
                            readonly property bool metro: (og.o.simge || "").indexOf("/varlik/uygulama-") >= 0
                            width: metro ? 40 : 30; height: width
                            sourceSize.width: 60; sourceSize.height: 60
                            source: og.o.simge ? (og.o.simge.startsWith("/") ? "file://" + og.o.simge : "image://simge/" + og.o.simge) : ""
                        }
                    }
                    Column {
                        visible: og.o.kimlik !== undefined
                        anchors.left: kare.right; anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            width: parent.width
                            text: og.o.ad || ""
                            color: "white"; elide: Text.ElideRight
                            font.family: "Segoe UI"; font.pixelSize: 15
                        }
                        Text {
                            visible: !!og.o.yeni
                            text: "Yeni"
                            color: Qt.lighter(g.tema.vurgu, 1.9)
                            font.family: "Segoe UI"; font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        id: uma
                        anchors.fill: parent
                        enabled: og.o.kimlik !== undefined
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                var p = mapToItem(g, mouse.x, mouse.y)
                                menu.ac(p.x, p.y, g.uygulamaMenusu(og.o.kimlik))
                            } else {
                                g.ana.kutucukCalistir("uygulama", og.o.kimlik)
                            }
                        }
                    }
                }
            }
        }
    }

    // harf / kategori ızgarası (uzaklaşmış görünüm)
    Item {
        id: izgara
        x: 120; y: g.ust
        width: g.width - 240; height: g.height - y - 90
        opacity: g.uzakT
        visible: opacity > 0.01
        scale: 1.3 - 0.3 * g.uzakT
        transformOrigin: Item.TopLeft
        readonly property bool harfler: g.basliklar.length && g.basliklar[0].ad.length <= 2
        readonly property int hucreG: harfler ? 96 : 260
        readonly property int hucreY: harfler ? 96 : 64
        Grid {
            flow: Grid.TopToBottom
            rows: Math.max(1, Math.floor(izgara.height / (izgara.hucreY + 10)))
            rowSpacing: 10; columnSpacing: 10
            Repeater {
                model: g.basliklar
                delegate: Rectangle {
                    required property var modelData
                    width: izgara.hucreG; height: izgara.hucreY
                    color: hma.pressed ? Qt.rgba(1, 1, 1, 0.3) : (hma.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08))
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: izgara.harfler ? 0 : 14
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: izgara.harfler ? Text.AlignHCenter : Text.AlignLeft
                        text: modelData.ad
                        elide: Text.ElideRight
                        color: "white"
                        font.family: "Segoe UI"; font.weight: 300; font.pixelSize: izgara.harfler ? 44 : 22
                    }
                    MouseArea { id: hma; anchors.fill: parent; hoverEnabled: true; onClicked: g.basligaGit(modelData.x) }
                }
            }
        }
        MouseArea {
            z: -1
            anchors.fill: parent
            onClicked: g.uzak = false
            onWheel: wheel => { if ((wheel.modifiers & Qt.ControlModifier) && wheel.angleDelta.y > 0) g.uzak = false }
        }
    }

    Text {
        visible: g.filtre !== "" && g.ogeler.length === 0
        x: 120; y: g.ust + 10
        text: "Bu aramayla eşleşen bir uygulama bulunamadı."
        color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 22
    }

    // Başlangıç'a dönüş oku
    DaireDugme {
        x: 120; y: g.height - 70
        boyut: 34; glif: ""; donus: -90; glifOlcek: 0.42
        onTiklandi: g.baslangic.sayfa = 0
    }

    function uygulamaMenusu(kimlik) {
        var sabit = baslangic.kutucukBul("uygulama", kimlik) >= 0
        var gorev = ana.gorevCubugundaMi(kimlik)
        return [
            { metin: sabit ? "Başlangıç ekranından ayır" : "Başlangıç ekranına sabitle",
              eylem: function () { if (sabit) baslangic.ayir(baslangic.kutucukBul("uygulama", kimlik)); else baslangic.sabitle(kimlik) } },
            { metin: gorev ? "Görev çubuğundan ayır" : "Görev çubuğuna sabitle", eylem: function () { ana.gorevCubugunaSabitle(kimlik, !gorev) } },
            { metin: "Kaldır", eylem: function () { ana.kaldir(kimlik) } },
            { metin: "Dosya konumunu aç", eylem: function () { ana.baslangicKapat(); Uygulamalar.dosyaKonumunuAc(kimlik) } }
        ]
    }

    MetroMenu { id: menu }
}
