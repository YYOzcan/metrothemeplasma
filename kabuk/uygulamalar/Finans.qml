// Windows 8.1 Finans (Bing Finans): solda öne çıkan kur (USD/TRY) büyük değer, değişim ve 30 günlük grafik;
// sağında döviz tablosu (TCMB gösterge kurları) ve ekonomi haberleri. Veriler: tcmb.gov.tr, frankfurter.dev,
// TRT Haber ekonomi akışı.
import QtQuick

Item {
    id: f
    readonly property string baslik: "Finans"
    readonly property color renk: "#00843f"
    readonly property color zemin: "#f2f2f2"
    readonly property color cubukRengi: "#005a2b"
    readonly property var solKomutlar: [{ glif: "", metin: "Ana Sayfa", eylem: function () { kaydir.contentX = 0 } }]
    readonly property var sagKomutlar: [{ glif: "", metin: "Yenile", eylem: function () { f.yukle() } }]

    property var kurlar: []          // { kod, ad, alis, satis }
    property string tarih: ""
    property var gecmis: []          // [{ t, d }] USD/TRY
    property string secili: "USD"
    property var haberler: []
    property bool hata: false

    function sayi(x, b) { return Number(x).toLocaleString(Qt.locale("tr_TR"), "f", b === undefined ? 4 : b) }
    function yukle() {
        hata = false
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) { f.hata = true; return }
            var t = x.responseText, l = []
            var m = /Tarih="([^"]+)"/.exec(t); f.tarih = m ? m[1] : ""
            var parcalar = t.split("<Currency ")
            for (var i = 1; i < parcalar.length; i++) {
                var p = parcalar[i]
                function al(ad) { var r = new RegExp("<" + ad + ">([^<]*)</" + ad + ">").exec(p); return r ? r[1] : "" }
                var kod = (/Kod="([^"]+)"/.exec(p) || [])[1]
                var alis = parseFloat(al("ForexBuying")), satis = parseFloat(al("ForexSelling")), birim = parseInt(al("Unit")) || 1
                if (!kod || isNaN(satis)) continue
                var ad = al("Isim").toLocaleLowerCase(Qt.locale("tr_TR")).replace(/(^|\s)(\S)/g, function (a, b, c) { return b + c.toLocaleUpperCase(Qt.locale("tr_TR")) })
                ad = ad.replace(/^Abd /, "ABD ").replace(/^Sdr /, "SDR ")
                l.push({ kod: kod, ad: ad, alis: alis / birim, satis: satis / birim })
            }
            f.kurlar = l
        }
        x.open("GET", "https://www.tcmb.gov.tr/kurlar/today.xml"); x.send()
        gecmisYukle()
        var h = new XMLHttpRequest()
        h.onreadystatechange = function () {
            if (h.readyState !== XMLHttpRequest.DONE || h.status !== 200) return
            var l = [], o = h.responseText.split("<item>")
            for (var i = 1; i < o.length && l.length < 8; i++) {
                var bm = /<title>([\s\S]*?)<\/title>/.exec(o[i]), lm = /<link>([\s\S]*?)<\/link>/.exec(o[i])
                l.push({ baslik: (bm ? bm[1] : "").replace(/<!\[CDATA\[|\]\]>/g, "").trim(), link: (lm ? lm[1] : "").trim() })
            }
            f.haberler = l
        }
        h.open("GET", "https://www.trthaber.com/ekonomi_articles.rss"); h.send()
    }
    function gecmisYukle() {
        var bas = new Date(Date.now() - 31 * 86400000)
        var g = new XMLHttpRequest()
        g.onreadystatechange = function () {
            if (g.readyState !== XMLHttpRequest.DONE || g.status !== 200) return
            try {
                var d = JSON.parse(g.responseText), l = []
                Object.keys(d.rates).sort().forEach(function (k) { l.push({ t: k, d: d.rates[k].TRY }) })
                f.gecmis = l
            } catch (e) {}
        }
        g.open("GET", "https://api.frankfurter.dev/v1/" + new Date(bas).toLocaleDateString(Qt.locale("tr_TR"), "yyyy-MM-dd") + "..?from=" + secili + "&symbols=TRY"); g.send()
    }
    onSeciliChanged: { gecmis = []; gecmisYukle() }
    Component.onCompleted: yukle()

    readonly property var kur: { for (var i = 0; i < kurlar.length; i++) if (kurlar[i].kod === secili) return kurlar[i]; return null }
    readonly property real degisim: gecmis.length > 1 ? (gecmis[gecmis.length - 1].d - gecmis[gecmis.length - 2].d) / gecmis[gecmis.length - 2].d * 100 : 0

    Rectangle { anchors.fill: parent; color: f.zemin }
    Text {
        visible: f.hata
        anchors.centerIn: parent
        text: "Piyasa verileri alınamadı. İnternet bağlantınızı denetleyin."
        color: "#555"; font.family: "Segoe UI"; font.pixelSize: 22
    }

    Flickable {
        id: kaydir
        anchors.fill: parent
        contentWidth: panorama.width + 240; contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        MouseArea {
            width: kaydir.contentWidth; height: kaydir.height
            acceptedButtons: Qt.NoButton
            onWheel: w => kaydir.contentX = Math.max(0, Math.min(kaydir.contentWidth - kaydir.width, kaydir.contentX - w.angleDelta.y * 1.5))
        }
        Row {
            id: panorama
            x: 120; height: kaydir.height
            spacing: 100
            // ---- öne çıkan kur
            Item {
                width: 700; height: parent.height
                Text { y: 50; text: "Finans"; color: f.renk; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56 }
                Column {
                    y: 160; spacing: 6
                    Text { text: f.secili + "/TRY"; color: "#222"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
                    Text { text: f.kur ? f.kur.ad : ""; color: "#666"; font.family: "Segoe UI"; font.pixelSize: 16 }
                    Row {
                        spacing: 20
                        Text { text: f.kur ? f.sayi(f.kur.satis) : "—"; color: "#111"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 96 }
                        Text {
                            anchors.baseline: parent.children[0].baseline
                            visible: f.gecmis.length > 1
                            text: (f.degisim >= 0 ? "▲ " : "▼ ") + "%" + f.sayi(Math.abs(f.degisim), 2)
                            color: f.degisim >= 0 ? "#00843f" : "#c41b2c"; font.family: "Segoe UI"; font.pixelSize: 26
                        }
                    }
                    Text { text: f.tarih ? "TCMB gösterge kuru (döviz satış) · " + f.tarih : ""; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 14 }
                    Item { width: 1; height: 20 }
                    // 30 günlük grafik
                    Canvas {
                        id: grafik
                        width: 680; height: 300
                        property var veri: f.gecmis
                        onVeriChanged: requestPaint()
                        onPaint: {
                            var c = getContext("2d"); c.reset()
                            var v = veri; if (!v || v.length < 2) return
                            var en = 1e9, eb = -1e9
                            v.forEach(function (p) { en = Math.min(en, p.d); eb = Math.max(eb, p.d) })
                            var pay = (eb - en) * 0.1 || 0.01; en -= pay; eb += pay
                            c.strokeStyle = "#d0d0d0"; c.lineWidth = 1
                            for (var i = 0; i <= 4; i++) { var y = 10 + i * (height - 40) / 4; c.beginPath(); c.moveTo(0, y); c.lineTo(width - 70, y); c.stroke()
                                c.fillStyle = "#777"; c.font = "13px 'Segoe UI'"; c.fillText((eb - i * (eb - en) / 4).toFixed(2).replace(".", ","), width - 62, y + 4) }
                            function nx(i) { return i / (v.length - 1) * (width - 80) }
                            function ny(d) { return 10 + (eb - d) / (eb - en) * (height - 40) }
                            c.beginPath(); c.moveTo(nx(0), ny(v[0].d))
                            for (var j = 1; j < v.length; j++) c.lineTo(nx(j), ny(v[j].d))
                            c.lineTo(nx(v.length - 1), height - 30); c.lineTo(0, height - 30); c.closePath()
                            c.fillStyle = Qt.rgba(0, 0.52, 0.25, 0.15); c.fill()
                            c.beginPath(); c.moveTo(nx(0), ny(v[0].d))
                            for (var k = 1; k < v.length; k++) c.lineTo(nx(k), ny(v[k].d))
                            c.strokeStyle = "#00843f"; c.lineWidth = 2.5; c.stroke()
                            c.fillStyle = "#777"
                            c.fillText(v[0].t.slice(8, 10) + "." + v[0].t.slice(5, 7), 0, height - 8)
                            c.fillText(v[v.length - 1].t.slice(8, 10) + "." + v[v.length - 1].t.slice(5, 7), width - 120, height - 8)
                        }
                    }
                    Text { text: "Son 30 gün"; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 14 }
                }
            }
            // ---- döviz tablosu
            Item {
                width: 560; height: parent.height
                Text { y: 80; text: "Döviz ›"; color: "#222"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
                Column {
                    y: 150
                    Row {
                        height: 32
                        Text { width: 90; text: "Kod"; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 14 }
                        Text { width: 230; text: "Ad"; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 14 }
                        Text { width: 110; text: "Alış"; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 14; horizontalAlignment: Text.AlignRight }
                        Text { width: 110; text: "Satış"; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 14; horizontalAlignment: Text.AlignRight }
                    }
                    Repeater {
                        model: f.kurlar.filter(function (k) { return !isNaN(k.alis) }).slice(0, 14)
                        delegate: Rectangle {
                            required property var modelData
                            width: 540; height: 40
                            color: modelData.kod === f.secili ? Qt.rgba(0, 0.52, 0.25, 0.15) : (km.containsMouse ? "#e6e6e6" : "transparent")
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { width: 90; text: modelData.kod; color: "#111"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 16 }
                                Text { width: 230; text: modelData.ad; elide: Text.ElideRight; color: "#333"; font.family: "Segoe UI"; font.pixelSize: 16 }
                                Text { width: 110; text: f.sayi(modelData.alis); color: "#111"; font.family: "Segoe UI"; font.pixelSize: 16; horizontalAlignment: Text.AlignRight }
                                Text { width: 110; text: f.sayi(modelData.satis); color: "#111"; font.family: "Segoe UI"; font.pixelSize: 16; horizontalAlignment: Text.AlignRight }
                            }
                            MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; onClicked: f.secili = modelData.kod }
                        }
                    }
                }
            }
            // ---- ekonomi haberleri
            Item {
                width: 480; height: parent.height
                visible: f.haberler.length > 0
                Text { y: 80; text: "Haberler ›"; color: "#222"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
                Column {
                    y: 150; spacing: 4
                    Repeater {
                        model: f.haberler
                        delegate: Rectangle {
                            required property var modelData
                            width: 470; height: 62
                            color: hm.containsMouse ? "#e6e6e6" : "transparent"
                            Text { x: 6; width: parent.width - 12; anchors.verticalCenter: parent.verticalCenter; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                                   text: modelData.baslik; color: "#111"; font.family: "Segoe UI"; font.pixelSize: 16 }
                            MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally(modelData.link) }
                        }
                    }
                }
            }
        }
    }
}
