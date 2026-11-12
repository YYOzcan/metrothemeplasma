// Windows 8.1 Internet Explorer 11 (Modern): sayfa tam ekran; altta koyu adres çubuğu (Geri, adres kutusu,
// Yenile/Durdur, Sekmeler, Sık kullanılanlar, Sayfa araçları, İleri). Sekmeler düğmesi üstte sayfa
// küçük resimlerini açar (yeni sekme, InPrivate). Adres kutusuna tıklayınca "Sık ziyaret edilenler" ve
// "Sık kullanılanlar" kutucukları. Sayfa araçları > "Masaüstünde görüntüle" sayfayı masaüstü tarayıcısında
// (Falkon) açar. Profil kalıcı (çerezler, geçmiş); InPrivate sekmeleri iz bırakmaz.
import QtQuick
import QtWebEngine

Item {
    id: ie
    readonly property string baslik: "Internet Explorer"
    readonly property color zemin: "white"
    readonly property color cubukRengi: "#1f1f1f"
    readonly property var solKomutlar: []
    readonly property var sagKomutlar: []
    readonly property string anaSayfa: "https://www.bing.com/?cc=tr&setlang=tr"
    readonly property color mavi: "#2672ec"

    // ------------------------------------------------------------------ veriler
    readonly property string dosya: Dosya.yapilandirma + "/internet-explorer.json"
    property var sikKullanilanlar: []       // { ad, adres }
    property var ziyaretler: ({})           // alan adı -> { ad, adres, sayi }
    function yukle() {
        try { var d = JSON.parse(Dosya.oku(dosya)); sikKullanilanlar = d.sik || []; ziyaretler = d.ziyaret || {} } catch (e) {}
    }
    function kaydet() { Dosya.yaz(dosya, JSON.stringify({ sik: sikKullanilanlar, ziyaret: ziyaretler })) }
    function alan(u) { var m = /^https?:\/\/(?:www\.)?([^\/?#]+)/.exec(String(u)); return m ? m[1] : "" }
    function ziyaretEt(adres, ad) {
        var a = alan(adres); if (!a) return
        var z = Object.assign({}, ziyaretler)
        z[a] = { ad: ad || a, adres: "https://" + a + "/", sayi: ((z[a] && z[a].sayi) || 0) + 1 }
        ziyaretler = z; kaydet()
    }
    readonly property var enCok: Object.keys(ziyaretler).map(function (k) { return ziyaretler[k] })
                                       .sort(function (a, b) { return b.sayi - a.sayi }).slice(0, 8)
    function adresCoz(t) {
        t = t.trim()
        if (/^[a-z]+:\/\//i.test(t) || /^about:/.test(t)) return t
        if (/^[^\s]+\.[a-z]{2,}(\/.*)?$/i.test(t)) return "https://" + t
        return "https://www.bing.com/search?q=" + encodeURIComponent(t) + "&cc=tr&setlang=tr"
    }

    // ------------------------------------------------------------------ sekmeler
    WebEngineProfile {
        id: profil
        storageName: "metro-internet-explorer"
        offTheRecord: false
        httpAcceptLanguage: "tr-TR,tr;q=0.9,en;q=0.6"
        downloadPath: Yardimci.kitaplik("indirilen")
        onDownloadRequested: d => { d.accept(); ie.indirme = d }
    }
    WebEngineProfile { id: gizliProfil; offTheRecord: true; httpAcceptLanguage: "tr-TR,tr;q=0.9,en;q=0.6" }
    property var indirme: null

    ListModel { id: sekmeler }   // { kimlik, gizli }
    property int etkin: 0
    property int sonKimlik: 0
    property var resimler: ({})  // kimlik -> küçük resim adresi
    function yeniSekme(adres, gizli) {
        sekmeler.append({ kimlik: ++sonKimlik, gizli: !!gizli, ilkAdres: adres || "" })
        etkin = sekmeler.count - 1
        if (!adres) Qt.callLater(function () { adresKutusu.forceActiveFocus(); adresKutusu.selectAll() })
    }
    function sekmeKapat(i) {
        if (sekmeler.count <= 1) { sekmeler.setProperty(0, "ilkAdres", ""); gorunum(0) && gorunum(0).item && (gorunum(0).item.url = anaSayfa); return }
        sekmeler.remove(i)
        etkin = Math.min(etkin, sekmeler.count - 1)
    }
    function gorunum(i) { return sayfalar.itemAt(i) }
    property int surum: 0     // sekme oluştukça/yüklendikçe artar: itemAt bildirim vermez
    readonly property var sayfa: { var s_ = surum, g = sayfalar.itemAt(etkin); return g ? g.item : null }
    Component.onCompleted: {
        yukle()
        var a = Yardimci.argumanlar.filter(function (x) { return /^https?:|^www\.|\.[a-z]{2,}/.test(x) })
        yeniSekme(a.length ? adresCoz(a[0]) : anaSayfa)
    }
    Connections {
        target: Yardimci
        function onArgumanlarDegisti() {
            var a = Yardimci.argumanlar.filter(function (x) { return /^https?:|^www\.|\.[a-z]{2,}/.test(x) })
            if (a.length) ie.yeniSekme(ie.adresCoz(a[0]))
        }
    }

    Repeater {
        id: sayfalar
        model: sekmeler
        onItemAdded: ie.surum++
        onItemRemoved: ie.surum++
        delegate: Loader {
            required property int index
            required property var model
            width: ie.width; height: ie.height
            visible: index === ie.etkin
            onLoaded: ie.surum++
            sourceComponent: WebEngineView {
                profile: model.gizli ? gizliProfil : profil
                url: model.ilkAdres !== "" ? model.ilkAdres : ie.anaSayfa
                settings.fullScreenSupportEnabled: true
                onLoadingChanged: r => {
                    if (r.status === WebEngineView.LoadSucceededStatus) {
                        if (!model.gizli) ie.ziyaretEt(url, title)
                        Qt.callLater(function () { ie.resimAl(model.kimlik, parent) })
                    }
                }
                onNewWindowRequested: istek => { ie.yeniSekme(""); Qt.callLater(function () { var g = ie.sayfa; if (g) istek.openIn(g) }) }
                onFullScreenRequested: istek => istek.accept()
            }
        }
    }
    function resimAl(k, ogeler) {
        if (!ogeler) return
        ogeler.grabToImage(function (s) { var r = Object.assign({}, ie.resimler); r[k] = s.url; ie.resimler = r }, Qt.size(320, 200))
    }

    // ------------------------------------------------------------------ adres çubuğu (alt)
    property bool cubukAcik: true
    Rectangle {
        id: adresCubugu
        width: parent.width; height: 72
        y: ie.cubukAcik || adresKutusu.activeFocus || sekmePaneli.visible ? parent.height - height : parent.height
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: [0.1, 0.9, 0.2, 1, 1, 1] } }
        color: "#1f1f1f"
        z: 20
        // yükleme çizgisi
        Rectangle {
            visible: ie.sayfa && ie.sayfa.loading
            width: parent.width * (ie.sayfa ? ie.sayfa.loadProgress / 100 : 0); height: 3
            color: ie.mavi
        }
        Daire { x: 24; anchors.verticalCenter: parent.verticalCenter; glif: ""; etkin: ie.sayfa && ie.sayfa.canGoBack; onTiklandi: ie.sayfa.goBack() }
        Rectangle {
            id: kutu
            x: 90; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 90 - 340; height: 40
            color: adresKutusu.activeFocus ? "white" : "#f2f2f2"
            Image {
                id: favicon
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 16; height: 16
                source: ie.sayfa ? ie.sayfa.icon : ""
            }
            TextInput {
                id: adresKutusu
                x: 34; width: parent.width - 80; height: parent.height
                verticalAlignment: TextInput.AlignVCenter
                font.family: "Segoe UI"; font.pixelSize: 17
                color: "#111"; clip: true
                selectByMouse: true
                opacity: activeFocus ? 1 : 0
                onActiveFocusChanged: if (activeFocus) { text = ie.sayfa ? ie.sayfa.url.toString() : ""; selectAll() }
                onAccepted: { if (ie.sayfa) ie.sayfa.url = ie.adresCoz(text); ie.forceActiveFocus() }
                Keys.onEscapePressed: ie.forceActiveFocus()
            }
            // odak yokken: adres (alan adı koyu, gerisi soluk — IE11 gibi)
            Text {
                visible: !adresKutusu.activeFocus
                x: 34; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight; textFormat: Text.StyledText
                readonly property string u: ie.sayfa ? ie.sayfa.url.toString() : ""
                readonly property string a: ie.alan(u)
                text: a ? "<font color='#111'>" + a + "</font><font color='#888'>" + u.replace(/^https?:\/\/(www\.)?[^\/?#]+/, "").replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</font>" : ""
                font.family: "Segoe UI"; font.pixelSize: 17
                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: adresKutusu.forceActiveFocus() }
            }
            // yenile / durdur (kutunun içinde, sağda)
            Text {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                text: ie.sayfa && ie.sayfa.loading ? "" : ""
                font.family: "Segoe UI Symbol"; font.pixelSize: 15; color: ym.containsMouse ? ie.mavi : "#333"
                MouseArea { id: ym; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true
                    onClicked: { if (!ie.sayfa) return; if (ie.sayfa.loading) ie.sayfa.stop(); else ie.sayfa.reload() } }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Item {
                width: 44; height: 44
                Daire { anchors.fill: parent; glif: ""; onTiklandi: sekmePaneli.visible = !sekmePaneli.visible }
                Text { anchors.centerIn: parent; anchors.verticalCenterOffset: 1; text: sekmeler.count; color: "white"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: 600 }
            }
            Daire { glif: ""; onTiklandi: { sikPaneli.visible = !sikPaneli.visible } }
            Daire { glif: ""; onTiklandi: araclar.visible = !araclar.visible }
            Daire { glif: ""; etkin: ie.sayfa && ie.sayfa.canGoForward; onTiklandi: ie.sayfa.goForward() }
        }
    }
    // sayfa içine tıklayınca çubuk açık kalır (8.1'de "Adres çubuğunu ve sekmeleri her zaman göster" açık)

    // ------------------------------------------------------------------ adres kutusu odaklıyken: sık ziyaret edilenler
    Rectangle {
        visible: adresKutusu.activeFocus
        width: parent.width; height: 240
        anchors.bottom: adresCubugu.top
        color: "#2b2b2b"
        z: 19
        Text { x: 90; y: 18; text: "Sık ziyaret edilenler"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 22 }
        Row {
            x: 90; y: 62; spacing: 10
            Repeater {
                model: ie.enCok.length ? ie.enCok : [{ ad: "Bing", adres: ie.anaSayfa }, { ad: "TRT Haber", adres: "https://www.trthaber.com/" }]
                delegate: Rectangle {
                    required property var modelData
                    width: 150; height: 150
                    color: Qt.hsla((modelData.adres.length * 53 % 360) / 360, 0.55, 0.38, 1)
                    Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -10; text: ie.alan(modelData.adres).charAt(0).toUpperCase(); color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56 }
                    Text { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; width: parent.width - 16; elide: Text.ElideRight; text: modelData.ad; color: "white"; font.family: "Segoe UI"; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onPressed: { if (ie.sayfa) ie.sayfa.url = modelData.adres; ie.forceActiveFocus() } }
                }
            }
        }
    }

    // ------------------------------------------------------------------ sekmeler (üst)
    Rectangle {
        id: sekmePaneli
        visible: false
        width: parent.width; height: 250
        color: "#1f1f1f"
        z: 21
        ListView {
            x: 40; y: 24; width: parent.width - 260; height: 200
            orientation: ListView.Horizontal; spacing: 14; clip: true
            model: sekmeler
            delegate: Item {
                id: sk
                required property int index
                required property var model
                readonly property var gor: { var s_ = ie.surum, g = sayfalar.itemAt(index); return g ? g.item : null }
                width: 270; height: 200
                Rectangle {
                    width: 270; height: 168
                    color: "white"
                    border.color: sk.index === ie.etkin ? ie.mavi : (tm.containsMouse ? "#888" : "#444"); border.width: 3
                    Image { anchors.fill: parent; anchors.margins: 3; source: ie.resimler[sk.model.kimlik] || ""; fillMode: Image.PreserveAspectCrop }
                    Rectangle { visible: sk.model.gizli; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 6; width: gz.implicitWidth + 12; height: 20; color: ie.mavi
                        Text { id: gz; anchors.centerIn: parent; text: "InPrivate"; color: "white"; font.family: "Segoe UI"; font.pixelSize: 12 } }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; onClicked: { ie.etkin = sk.index; sekmePaneli.visible = false } }
                    Rectangle {
                        anchors.right: parent.right; anchors.top: parent.top
                        width: 30; height: 30; color: km.containsMouse ? "#e81123" : "#1f1f1f"
                        Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 11; color: "white" }
                        MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; onClicked: ie.sekmeKapat(sk.index) }
                    }
                }
                Text { y: 174; width: 270; elide: Text.ElideRight; text: sk.gor ? sk.gor.title : ""; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
            }
        }
        Column {
            anchors.right: parent.right; anchors.rightMargin: 40; y: 40
            spacing: 18
            Daire { glif: ""; onTiklandi: { sekmePaneli.visible = false; ie.yeniSekme("") } }
            Daire { glif: ""; onTiklandi: sekmeMenu.visible = !sekmeMenu.visible }
        }
        Rectangle {
            id: sekmeMenu
            visible: false
            anchors.right: parent.right; anchors.rightMargin: 100; y: 110
            width: 220; height: 80; color: "white"; border.color: "#ccc"
            Column {
                anchors.fill: parent; anchors.margins: 2
                Repeater {
                    model: [["Yeni InPrivate sekmesi", function () { ie.yeniSekme(ie.anaSayfa, true) }], ["Sekmeleri kapat", function () { while (sekmeler.count > 1) sekmeler.remove(1); ie.etkin = 0 }]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 216; height: 38; color: mm.containsMouse ? "#e5e5e5" : "white"
                        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; font.family: "Segoe UI"; font.pixelSize: 15 }
                        MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; onClicked: { sekmeMenu.visible = false; sekmePaneli.visible = false; modelData[1]() } }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ sık kullanılanlar (alttan, çubuğun üstünde)
    Rectangle {
        id: sikPaneli
        visible: false
        width: parent.width; height: 230
        anchors.bottom: adresCubugu.top
        color: "#2b2b2b"
        z: 19
        Text { x: 90; y: 18; text: "Sık kullanılanlar"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 22 }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 40; y: 16
            width: ek.implicitWidth + 30; height: 34
            color: em.pressed ? "white" : (em.containsMouse ? "#444" : "transparent"); border.color: "white"; border.width: 2
            readonly property bool var_: ie.sayfa && ie.sikKullanilanlar.some(function (s) { return s.adres === ie.sayfa.url.toString() })
            Text { id: ek; anchors.centerIn: parent; text: parent.var_ ? "Sık kullanılanlardan kaldır" : "Sık kullanılanlara ekle"; color: em.pressed ? "black" : "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 14 }
            MouseArea {
                id: em; anchors.fill: parent; hoverEnabled: true
                onClicked: {
                    if (!ie.sayfa) return
                    var u = ie.sayfa.url.toString()
                    if (parent.var_) ie.sikKullanilanlar = ie.sikKullanilanlar.filter(function (s) { return s.adres !== u })
                    else ie.sikKullanilanlar = ie.sikKullanilanlar.concat([{ ad: ie.sayfa.title || ie.alan(u), adres: u }])
                    ie.kaydet()
                }
            }
        }
        Text { x: 90; y: 70; visible: ie.sikKullanilanlar.length === 0; text: "Henüz sık kullanılan bir site eklemediniz."; color: "#bdbdbd"; font.family: "Segoe UI"; font.pixelSize: 16 }
        ListView {
            x: 90; y: 62; width: parent.width - 180; height: 150
            orientation: ListView.Horizontal; spacing: 10; clip: true
            model: ie.sikKullanilanlar
            delegate: Rectangle {
                required property var modelData
                width: 150; height: 150
                color: Qt.hsla((modelData.adres.length * 53 % 360) / 360, 0.55, 0.38, 1)
                Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -10; text: ie.alan(modelData.adres).charAt(0).toUpperCase(); color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56 }
                Text { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; width: parent.width - 16; elide: Text.ElideRight; text: modelData.ad; color: "white"; font.family: "Segoe UI"; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; onClicked: { if (ie.sayfa) ie.sayfa.url = modelData.adres; sikPaneli.visible = false } }
            }
        }
    }

    // ------------------------------------------------------------------ sayfa araçları menüsü
    Rectangle {
        id: araclar
        visible: false
        anchors.right: parent.right; anchors.rightMargin: 80
        anchors.bottom: adresCubugu.top; anchors.bottomMargin: 6
        width: 260; height: aracSutun.height + 4
        color: "white"; border.color: "#ccc"
        z: 22
        Column {
            id: aracSutun
            x: 2; y: 2; width: 256
            Repeater {
                model: [
                    ["Sayfada bul", function () { bulCubugu.visible = true; bulKutusu.forceActiveFocus() }],
                    ["Masaüstünde görüntüle", function () { if (ie.sayfa) Yardimci.calistir("falkon", [ie.sayfa.url.toString()]) }],
                    ["Yakınlaştır", function () { if (ie.sayfa) ie.sayfa.zoomFactor = Math.min(3, ie.sayfa.zoomFactor + 0.1) }],
                    ["Uzaklaştır", function () { if (ie.sayfa) ie.sayfa.zoomFactor = Math.max(0.3, ie.sayfa.zoomFactor - 0.1) }],
                    ["Ana sayfa", function () { if (ie.sayfa) ie.sayfa.url = ie.anaSayfa }]
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 256; height: 38; color: am.containsMouse ? "#e5e5e5" : "white"
                    Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; font.family: "Segoe UI"; font.pixelSize: 15 }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: { araclar.visible = false; modelData[1]() } }
                }
            }
        }
    }
    // sayfada bul
    Rectangle {
        id: bulCubugu
        visible: false
        width: parent.width; height: 56
        anchors.bottom: adresCubugu.top
        color: "#2b2b2b"; z: 19
        Rectangle {
            x: 90; anchors.verticalCenter: parent.verticalCenter; width: 420; height: 34; color: "white"
            TextInput { id: bulKutusu; anchors.fill: parent; anchors.margins: 7; font.family: "Segoe UI"; font.pixelSize: 15; clip: true
                onTextChanged: if (ie.sayfa) ie.sayfa.findText(text)
                onAccepted: if (ie.sayfa) ie.sayfa.findText(text)
                Keys.onEscapePressed: { bulCubugu.visible = false; if (ie.sayfa) ie.sayfa.findText("") } }
        }
        Text { x: 530; anchors.verticalCenter: parent.verticalCenter; text: "Kapat"; color: "white"; font.family: "Segoe UI"; font.pixelSize: 15
            MouseArea { anchors.fill: parent; onClicked: { bulCubugu.visible = false; if (ie.sayfa) ie.sayfa.findText("") } } }
    }
    // indirme bildirimi (8.1: alttan "X dosyası indirildi" çubuğu)
    Rectangle {
        visible: ie.indirme !== null
        width: parent.width; height: 64
        anchors.bottom: adresCubugu.top
        color: "#2b2b2b"; z: 19
        Text {
            x: 90; anchors.verticalCenter: parent.verticalCenter
            text: !ie.indirme ? "" : (ie.indirme.isFinished ? ie.indirme.downloadFileName + " indirildi."
                  : ie.indirme.downloadFileName + " indiriliyor... %" + Math.round(ie.indirme.receivedBytes / Math.max(1, ie.indirme.totalBytes) * 100))
            color: "white"; font.family: "Segoe UI"; font.pixelSize: 16
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 40; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Repeater {
                model: [["Aç", function () { Qt.openUrlExternally(Dosya.url(ie.indirme.downloadDirectory + "/" + ie.indirme.downloadFileName)) }],
                        ["Klasörü aç", function () { Qt.openUrlExternally(Dosya.url(ie.indirme.downloadDirectory)) }],
                        ["Kapat", function () { ie.indirme = null }]]
                delegate: Rectangle {
                    required property var modelData
                    width: dt.implicitWidth + 28; height: 34
                    color: dm.containsMouse ? "#444" : "transparent"; border.color: "white"; border.width: 2
                    Text { id: dt; anchors.centerIn: parent; text: modelData[0]; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 14 }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: modelData[1]() }
                }
            }
        }
    }

    component Daire: Rectangle {
        id: d
        property string glif
        property bool etkin: true
        signal tiklandi()
        width: 44; height: 44; radius: 22
        opacity: etkin ? 1 : 0.35
        color: dmx.pressed ? "white" : (dmx.containsMouse ? "#444" : "transparent")
        border.color: "white"; border.width: 2
        Text { anchors.centerIn: parent; text: d.glif; font.family: "Segoe UI Symbol"; font.pixelSize: 17; color: dmx.pressed ? "black" : "white" }
        MouseArea { id: dmx; anchors.fill: parent; hoverEnabled: true; enabled: d.etkin; onClicked: d.tiklandi() }
    }

    // kısayollar (IE11 ile aynı)
    Shortcut { sequence: "Ctrl+T"; onActivated: ie.yeniSekme("") }
    Shortcut { sequence: "Ctrl+W"; onActivated: ie.sekmeKapat(ie.etkin) }
    Shortcut { sequence: "Ctrl+Shift+P"; onActivated: ie.yeniSekme(ie.anaSayfa, true) }
    Shortcut { sequence: "Ctrl+L"; onActivated: { adresKutusu.forceActiveFocus(); adresKutusu.selectAll() } }
    Shortcut { sequence: "Alt+D"; onActivated: { adresKutusu.forceActiveFocus(); adresKutusu.selectAll() } }
    Shortcut { sequence: "F5"; onActivated: if (ie.sayfa) ie.sayfa.reload() }
    Shortcut { sequence: "Ctrl+F"; onActivated: { bulCubugu.visible = true; bulKutusu.forceActiveFocus() } }
    Shortcut { sequence: "Alt+Left"; onActivated: if (ie.sayfa) ie.sayfa.goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: if (ie.sayfa) ie.sayfa.goForward() }
    Shortcut { sequence: "Ctrl+Tab"; onActivated: ie.etkin = (ie.etkin + 1) % sekmeler.count }
}
