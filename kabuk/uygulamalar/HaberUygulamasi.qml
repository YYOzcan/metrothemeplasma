// Windows 8.1 Bing Haberler / Spor düzeni: yatay panorama. Solda büyük manşet (resim üstünde başlık),
// sağında bölümler (her biri resimli haber kutuları); habere tıklayınca okuma sayfası (başlık, resim,
// özet, "Haberin tamamını oku"). Kaynak: TRT Haber RSS akışları (Türkçe, resimli).
import QtQuick

Item {
    id: h
    property string baslik: "Haberler"
    property color renk: "#ae1f23"
    property var bolumler: []      // [{ ad, url }]
    readonly property color zemin: "#f2f2f2"
    readonly property color cubukRengi: Qt.darker(renk, 1.3)
    readonly property var solKomutlar: [{ glif: "", metin: "Ana Sayfa", eylem: function () { h.acik = null; kaydir.contentX = 0 } }]
    readonly property var sagKomutlar: [{ glif: "", metin: "Yenile", eylem: function () { h.yukle() } }]

    property var haberler: ({})    // bölüm adı -> [{ baslik, ozet, resim, link, tarih }]
    property int yuklenen: 0
    property var acik: null        // okunan haber

    function temizle(t) {
        return String(t || "").replace(/<!\[CDATA\[|\]\]>/g, "").replace(/<[^>]+>/g, "")
               .replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim()
    }
    function ayristir(xml, kaynak) {
        // RSS (<item>) ve Atom (<entry>)
        var atom = xml.indexOf("<item>") < 0 && xml.indexOf("<entry>") >= 0
        var l = [], ogeler = xml.split(atom ? "<entry>" : "<item>")
        for (var i = 1; i < ogeler.length && l.length < 30; i++) {
            var o = ogeler[i]
            function al(ad) { var m = new RegExp("<" + ad + "[^>]*>([\\s\\S]*?)</" + ad + ">").exec(o); return m ? m[1] : "" }
            var resim = (/<media:content[^>]*url="([^"]+)"/.exec(o) || /<media:thumbnail[^>]*url="([^"]+)"/.exec(o)
                         || /<enclosure[^>]*url="([^"]+)"/.exec(o) || /<img[^>]*src="([^"]+)"/.exec(o) || [])[1] || ""
            var link = atom ? ((/<link[^>]*href="([^"]+)"/.exec(o) || [])[1] || "") : (temizle(al("link")) || temizle(al("guid")))
            l.push({ baslik: temizle(al("title")), ozet: temizle(atom ? al("summary") : al("description")), resim: resim, kaynak: kaynak,
                     link: link, tarih: new Date(temizle(atom ? al("published") : al("pubDate"))) })
        }
        return l
    }
    function yukle() {
        yuklenen = 0
        bolumler.forEach(function (b) {
            var x = new XMLHttpRequest()
            x.onreadystatechange = function () {
                if (x.readyState !== XMLHttpRequest.DONE) return
                h.yuklenen++
                if (x.status !== 200) return
                var d = Object.assign({}, h.haberler); d[b.ad] = h.ayristir(x.responseText, b.kaynak || "TRT Haber"); h.haberler = d
            }
            x.open("GET", b.url); x.send()
        })
    }
    Component.onCompleted: yukle()
    function zaman(t) {
        if (!t || isNaN(t.getTime())) return ""
        var dk = Math.round((Date.now() - t.getTime()) / 60000)
        if (dk < 60) return Math.max(1, dk) + " dakika önce"
        if (dk < 24 * 60) return Math.round(dk / 60) + " saat önce"
        return new Date(t).toLocaleDateString(Qt.locale("tr_TR"), "d MMMM")
    }
    readonly property var manset: {
        var b = bolumler.length ? haberler[bolumler[0].ad] : null
        return b && b.length ? b[0] : null
    }

    Rectangle { anchors.fill: parent; color: h.zemin }

    Text {
        visible: h.yuklenen >= h.bolumler.length && !h.manset
        anchors.centerIn: parent
        text: "Haberler alınamadı. İnternet bağlantınızı denetleyin."
        color: "#555"; font.family: "Segoe UI"; font.pixelSize: 22
    }

    Flickable {
        id: kaydir
        anchors.fill: parent
        visible: h.acik === null
        contentWidth: panorama.width + 120; contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        MouseArea {
            width: kaydir.contentWidth; height: kaydir.height
            acceptedButtons: Qt.NoButton
            onWheel: w => kaydir.contentX = Math.max(0, Math.min(kaydir.contentWidth - kaydir.width, kaydir.contentX - w.angleDelta.y * 1.5))
        }
        Row {
            id: panorama
            height: kaydir.height
            spacing: 60
            // manşet: ekran yüksekliğinde büyük resim
            Item {
                width: Math.round(kaydir.height * 1.25); height: kaydir.height
                visible: h.manset !== null
                Rectangle { anchors.fill: parent; color: h.renk }
                Image {
                    anchors.fill: parent
                    source: h.manset ? h.manset.resim : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    height: mansetMetin.implicitHeight + 120
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.85) }
                    }
                }
                Text {
                    x: 120; y: 50
                    text: h.baslik; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56
                    style: Text.Raised; styleColor: "#80000000"
                }
                Column {
                    id: mansetMetin
                    x: 120; width: parent.width - 180
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 60
                    spacing: 8
                    Text { width: parent.width; wrapMode: Text.WordWrap; text: h.manset ? h.manset.baslik : ""; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42 }
                    Text { text: h.manset ? h.manset.kaynak + " · " + h.zaman(h.manset.tarih) : ""; color: Qt.rgba(1, 1, 1, 0.8); font.family: "Segoe UI"; font.pixelSize: 15 }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: h.acik = h.manset }
            }
            // bölümler
            Repeater {
                model: h.bolumler
                delegate: Item {
                    id: bolum
                    required property var modelData
                    required property int index
                    readonly property var liste: (h.haberler[modelData.ad] || []).slice(index === 0 ? 1 : 0, index === 0 ? 9 : 7)
                    width: Math.ceil(liste.length / 3) * 316; height: kaydir.height
                    visible: liste.length > 0
                    Text {
                        y: 60
                        text: bolum.modelData.ad + " ›"
                        color: "#222"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34
                    }
                    Grid {
                        y: 130
                        flow: Grid.TopToBottom
                        rows: 3; spacing: 10
                        Repeater {
                            model: bolum.liste
                            delegate: Rectangle {
                                required property var modelData
                                width: 306; height: Math.floor((kaydir.height - 190) / 3)
                                color: km.containsMouse ? "#ffffff" : "#e8e8e8"
                                clip: true
                                Image {
                                    width: parent.width; height: parent.height - 70
                                    source: modelData.resim
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 612
                                }
                                Text {
                                    x: 10; y: parent.height - 66; width: parent.width - 20; height: 44
                                    wrapMode: Text.WordWrap; elide: Text.ElideRight; maximumLineCount: 2
                                    text: modelData.baslik; color: "#111"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15
                                }
                                Text { x: 10; y: parent.height - 22; text: h.zaman(modelData.tarih); color: "#777"; font.family: "Segoe UI"; font.pixelSize: 12 }
                                MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: h.acik = modelData }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------- okuma sayfası
    Flickable {
        anchors.fill: parent
        visible: h.acik !== null
        contentHeight: makale.height + 120
        clip: true
        Column {
            id: makale
            x: 120; y: 40
            width: Math.min(900, parent.width - 240)
            spacing: 18
            Row {
                spacing: 20
                Rectangle {
                    width: 41; height: 41; radius: 21; y: 10
                    color: gm.containsMouse ? "#e0e0e0" : "transparent"
                    border.color: "#333"; border.width: 2
                    Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: "#333" }
                    MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; onClicked: h.acik = null }
                }
                Text { text: h.baslik; color: h.renk; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42 }
            }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: h.acik ? h.acik.baslik : ""; color: "#111"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 40 }
            Text { text: h.acik ? h.acik.kaynak + " · " + h.zaman(h.acik.tarih) : ""; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 15 }
            Image {
                visible: h.acik && h.acik.resim !== ""
                width: parent.width; height: width * 9 / 16
                source: h.acik ? h.acik.resim : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: h.acik ? h.acik.ozet : ""; color: "#222"; font.family: "Segoe UI"; font.pixelSize: 20; lineHeight: 1.3 }
            Text {
                text: "Haberin tamamını oku ›"
                color: om.containsMouse ? Qt.lighter(h.renk, 1.3) : h.renk; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 18
                MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (h.acik) Qt.openUrlExternally(h.acik.link) }
            }
        }
    }
    focus: true
    Keys.onPressed: e => { if ((e.key === Qt.Key_Escape || e.key === Qt.Key_Backspace) && h.acik) { h.acik = null; e.accepted = true } }
}
