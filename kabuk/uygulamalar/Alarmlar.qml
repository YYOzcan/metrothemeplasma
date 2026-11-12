// Windows 8.1 Alarmlar: üstte "Alarm  Zamanlayıcı  Kronometre" başlıkları (pivot), koyu zemin.
// Alarmlar ~/.config/metrothemeplasma/alarmlar.json'a yazılır; uygulama kapalıyken de metro-kabuk çalar
// (Windows bildirimi + ses). Zamanlayıcı daire üzerinde geri sayar; kronometre tur kaydeder.
import QtQuick
import QtMultimedia

Item {
    id: a
    readonly property string baslik: "Alarmlar"
    readonly property color zemin: "#1d1d1d"
    readonly property color cubukRengi: "#2b2b2b"
    readonly property color kirmizi: "#ac193d"
    property int sayfa: 0
    readonly property var solKomutlar: []
    readonly property var sagKomutlar: sayfa === 0 ? [{ glif: "", metin: "Yeni", eylem: function () { a.duzenle(-1) } }] : []
    readonly property string dosya: Dosya.yapilandirma + "/alarmlar.json"
    readonly property var gunAdlari: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
    readonly property var sesler: [["Alarm01.wav", "Alarmlar"], ["Alarm02.wav", "Xylophone"], ["Alarm03.wav", "Akorlar"],
        ["Alarm04.wav", "Tıkırtı"], ["Alarm05.wav", "Darbe"], ["Alarm06.wav", "Zil"], ["Alarm07.wav", "Teyp"],
        ["Alarm08.wav", "Şelale"], ["Alarm09.wav", "Yükselen"], ["Alarm10.wav", "Kanal"]]

    // ------------------------------------------------------------------ alarm verisi
    ListModel { id: alarmlar }    // ad, saat, dakika, gunler (0-6 dizisi JSON), acik, ses
    function yukle() {
        alarmlar.clear()
        var l = []
        try { l = JSON.parse(Dosya.oku(dosya)) || [] } catch (e) { l = [] }
        if (!l.length && !Dosya.var(dosya)) l = [{ ad: "Alarm", saat: 7, dakika: 0, gunler: [], acik: false, ses: "Alarm01.wav" }]
        l.forEach(function (x) { alarmlar.append({ ad: x.ad, saat: x.saat, dakika: x.dakika, gunler: JSON.stringify(x.gunler || []), acik: !!x.acik, ses: x.ses || "Alarm01.wav" }) })
    }
    function kaydet() {
        var l = []
        for (var i = 0; i < alarmlar.count; i++) {
            var x = alarmlar.get(i)
            l.push({ ad: x.ad, saat: x.saat, dakika: x.dakika, gunler: JSON.parse(x.gunler), acik: x.acik, ses: x.ses })
        }
        Dosya.yaz(dosya, JSON.stringify(l, null, 1))
    }
    Component.onCompleted: yukle()
    function iki(n) { return (n < 10 ? "0" : "") + n }
    function gunMetni(g) {
        if (!g.length) return "Bir kez"
        if (g.length === 7) return "Her gün"
        if (g.length === 5 && g.indexOf(5) < 0 && g.indexOf(6) < 0) return "Hafta içi"
        return g.map(function (i) { return a.gunAdlari[i] }).join(", ")
    }

    // ------------------------------------------------------------------ başlıklar (pivot)
    Row {
        x: 120; y: 50
        spacing: 40
        Repeater {
            model: ["Alarm", "Zamanlayıcı", "Kronometre"]
            delegate: Text {
                required property int index
                required property string modelData
                text: modelData
                color: a.sayfa === index ? "white" : Qt.rgba(1, 1, 1, 0.4)
                font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42
                MouseArea { anchors.fill: parent; onClicked: { a.sayfa = index; duzenleyici.visible = false } }
            }
        }
    }

    // ------------------------------------------------------------------ Alarm
    Flickable {
        visible: a.sayfa === 0 && !duzenleyici.visible
        x: 120; y: 150
        width: parent.width - 120; height: parent.height - 150
        contentWidth: alarmSatir.width + 120; contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        clip: true
        Flow {
            id: alarmSatir
            flow: Flow.TopToBottom
            height: parent.height - 40
            spacing: 20
            Repeater {
                model: alarmlar
                delegate: Rectangle {
                    id: kart
                    required property int index
                    required property var model
                    width: 400; height: 150
                    color: km.containsMouse ? "#2f2f2f" : "#262626"
                    Column {
                        x: 20; y: 12; spacing: 2
                        Text { text: a.iki(kart.model.saat) + ":" + a.iki(kart.model.dakika); color: kart.model.acik ? "white" : "#8a8a8a"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 64 }
                        Text { text: kart.model.ad; color: "white"; font.family: "Segoe UI"; font.pixelSize: 18 }
                        Text { text: a.gunMetni(JSON.parse(kart.model.gunler)); color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 14 }
                    }
                    MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; onClicked: a.duzenle(kart.index) }
                    // açık/kapalı anahtarı
                    Anahtar {
                        anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                        acik: kart.model.acik
                        onDegisti: d => { alarmlar.setProperty(kart.index, "acik", d); a.kaydet() }
                    }
                }
            }
        }
    }

    // alarm düzenleme sayfası
    property int duzenlenen: -1
    function duzenle(i) {
        duzenlenen = i
        var x = i >= 0 ? alarmlar.get(i) : { ad: "Alarm", saat: 7, dakika: 0, gunler: "[]", ses: "Alarm01.wav" }
        adGirdi.text = x.ad; saatSec.deger = x.saat; dakikaSec.deger = x.dakika
        duzenleyici.gunler = JSON.parse(x.gunler); duzenleyici.ses = x.ses
        duzenleyici.visible = true
    }
    Item {
        id: duzenleyici
        visible: false
        property var gunler: []
        property string ses: "Alarm01.wav"
        x: 120; y: 150; width: parent.width - 240; height: parent.height - 150
        Column {
            spacing: 22
            Row {
                spacing: 12
                Secici { id: saatSec; enFazla: 23 }
                Text { text: ":"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 80; anchors.verticalCenter: parent.verticalCenter }
                Secici { id: dakikaSec; enFazla: 59 }
            }
            Column {
                spacing: 6
                Text { text: "Ad"; color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 15 }
                Rectangle {
                    width: 400; height: 34; color: adGirdi.activeFocus ? "white" : "#e6e6e6"
                    TextInput { id: adGirdi; anchors.fill: parent; anchors.margins: 6; font.family: "Segoe UI"; font.pixelSize: 16; color: "black"; verticalAlignment: TextInput.AlignVCenter; clip: true }
                }
            }
            Column {
                spacing: 6
                Text { text: "Tekrar"; color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 15 }
                Row {
                    spacing: 6
                    Repeater {
                        model: 7
                        delegate: Rectangle {
                            required property int index
                            readonly property bool secili: duzenleyici.gunler.indexOf(index) >= 0
                            width: 54; height: 34
                            color: secili ? a.kirmizi : "transparent"; border.color: secili ? a.kirmizi : "#7a7a7a"; border.width: 2
                            Text { anchors.centerIn: parent; text: a.gunAdlari[index]; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var g = duzenleyici.gunler.slice(), k = g.indexOf(index)
                                    if (k >= 0) g.splice(k, 1); else g.push(index)
                                    g.sort(); duzenleyici.gunler = g
                                }
                            }
                        }
                    }
                }
            }
            Column {
                spacing: 6
                Text { text: "Ses"; color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 15 }
                Flow {
                    width: 760; spacing: 6
                    Repeater {
                        model: a.sesler
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool secili: duzenleyici.ses === modelData[0]
                            width: sm.implicitWidth + 24; height: 34
                            color: secili ? a.kirmizi : "transparent"; border.color: secili ? a.kirmizi : "#7a7a7a"; border.width: 2
                            Text { id: sm; anchors.centerIn: parent; text: modelData[1]; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; onClicked: { duzenleyici.ses = modelData[0]; onizleme.source = pen.medya + modelData[0]; onizleme.play() } }
                        }
                    }
                }
            }
            Row {
                spacing: 10
                Dugme { metin: "Kaydet"; vurgulu: true; onTiklandi: {
                    var x = { ad: adGirdi.text || "Alarm", saat: saatSec.deger, dakika: dakikaSec.deger, gunler: JSON.stringify(duzenleyici.gunler), acik: true, ses: duzenleyici.ses }
                    if (a.duzenlenen >= 0) alarmlar.set(a.duzenlenen, x); else alarmlar.append(x)
                    a.kaydet(); onizleme.stop(); duzenleyici.visible = false
                } }
                Dugme { metin: "İptal"; onTiklandi: { onizleme.stop(); duzenleyici.visible = false } }
                Dugme { metin: "Sil"; visible: a.duzenlenen >= 0; onTiklandi: { alarmlar.remove(a.duzenlenen); a.kaydet(); onizleme.stop(); duzenleyici.visible = false } }
            }
        }
    }
    MediaPlayer { id: onizleme; audioOutput: AudioOutput {} }

    // ------------------------------------------------------------------ Zamanlayıcı
    property int zSure: 5 * 60          // saniye
    property real zKalan: zSure
    property bool zCalisiyor: false
    property bool zBitti: false
    Timer {
        id: zSaat
        interval: 100; repeat: true; running: a.zCalisiyor
        property double son: 0
        onRunningChanged: son = Date.now()
        onTriggered: {
            var s = Date.now(); a.zKalan = Math.max(0, a.zKalan - (s - son) / 1000); son = s
            if (a.zKalan <= 0) { a.zCalisiyor = false; a.zBitti = true; zil.source = pen.medya + "Alarm01.wav"; zil.loops = MediaPlayer.Infinite; zil.play() }
        }
    }
    MediaPlayer { id: zil; audioOutput: AudioOutput {} }
    function sureMetni(s, kesir) {
        var t = Math.ceil(s - 1e-6)
        if (kesir) t = Math.floor(s)
        var sa = Math.floor(t / 3600), d = Math.floor(t % 3600 / 60), sn = t % 60
        var m = iki(sa) + ":" + iki(d) + ":" + iki(sn)
        if (kesir) m += "," + iki(Math.floor((s - Math.floor(s)) * 100))
        return m
    }
    Item {
        visible: a.sayfa === 1
        anchors.fill: parent
        Canvas {
            id: halka
            width: 420; height: 420
            anchors.centerIn: parent; anchors.verticalCenterOffset: 30
            property real oran: a.zSure > 0 ? a.zKalan / a.zSure : 0
            onOranChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.lineWidth = 10
                c.strokeStyle = "#3a3a3a"; c.beginPath(); c.arc(210, 210, 195, 0, Math.PI * 2); c.stroke()
                c.strokeStyle = a.kirmizi; c.beginPath(); c.arc(210, 210, 195, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * oran); c.stroke()
            }
        }
        Text {
            anchors.centerIn: halka; anchors.verticalCenterOffset: -20
            text: a.zBitti ? "Süre doldu" : a.sureMetni(a.zKalan)
            color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: a.zBitti ? 44 : 64
        }
        Row {
            anchors.horizontalCenter: halka.horizontalCenter; anchors.top: halka.verticalCenter; anchors.topMargin: 40
            spacing: 16
            visible: !a.zCalisiyor && !a.zBitti && a.zKalan === a.zSure
            Repeater {
                model: [["−1 dk", -60], ["+1 dk", 60], ["+5 dk", 300]]
                delegate: Dugme { required property var modelData; metin: modelData[0]; onTiklandi: { a.zSure = Math.max(60, Math.min(99 * 3600, a.zSure + modelData[1])); a.zKalan = a.zSure } }
            }
        }
        Row {
            anchors.horizontalCenter: halka.horizontalCenter; anchors.top: halka.bottom; anchors.topMargin: 30
            spacing: 30
            DaireDugmesi { glif: a.zCalisiyor ? "" : ""; visible: !a.zBitti; onTiklandi: a.zCalisiyor = !a.zCalisiyor }
            DaireDugmesi { glif: ""; onTiklandi: { a.zCalisiyor = false; a.zBitti = false; zil.stop(); a.zKalan = a.zSure } }
        }
    }

    // ------------------------------------------------------------------ Kronometre
    property real kGecen: 0
    property bool kCalisiyor: false
    ListModel { id: turlar }
    Timer {
        interval: 30; repeat: true; running: a.kCalisiyor
        property double son: 0
        onRunningChanged: son = Date.now()
        onTriggered: { var s = Date.now(); a.kGecen += (s - son) / 1000; son = s }
    }
    Item {
        visible: a.sayfa === 2
        anchors.fill: parent
        Text {
            id: kSaat
            x: 120; y: 170
            text: a.sureMetni(a.kGecen, true)
            color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 110
        }
        Row {
            x: 120; anchors.top: kSaat.bottom; anchors.topMargin: 20
            spacing: 30
            DaireDugmesi { glif: a.kCalisiyor ? "" : ""; onTiklandi: a.kCalisiyor = !a.kCalisiyor }
            DaireDugmesi { glif: ""; etkin: a.kCalisiyor; onTiklandi: { var onceki = turlar.count ? turlar.get(0).toplam : 0; turlar.insert(0, { no: turlar.count + 1, tur: a.kGecen - onceki, toplam: a.kGecen }) } }
            DaireDugmesi { glif: ""; etkin: !a.kCalisiyor && a.kGecen > 0; onTiklandi: { a.kGecen = 0; turlar.clear() } }
        }
        ListView {
            x: parent.width / 2 + 60; y: 190
            width: 520; height: parent.height - 260
            clip: true
            model: turlar
            delegate: Item {
                required property var model
                width: 520; height: 40
                Text { text: "Tur " + model.no; color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 20 }
                Text { x: 140; text: a.sureMetni(model.tur, true); color: "white"; font.family: "Segoe UI"; font.pixelSize: 20 }
                Text { x: 330; text: a.sureMetni(model.toplam, true); color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 20 }
            }
        }
    }

    // ------------------------------------------------------------------ bileşenler
    component Dugme: Rectangle {
        id: dg
        property string metin
        property bool vurgulu: false
        signal tiklandi()
        width: Math.max(100, dm.implicitWidth + 30); height: 36
        color: dma.pressed ? "white" : (vurgulu ? a.kirmizi : (dma.containsMouse ? "#3a3a3a" : "transparent"))
        border.color: vurgulu ? a.kirmizi : "white"; border.width: 2
        Text { id: dm; anchors.centerIn: parent; text: dg.metin; color: dma.pressed ? "black" : "white"; font.family: "Segoe UI"; font.weight: Font.DemiBold; font.pixelSize: 15 }
        MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; onClicked: dg.tiklandi() }
    }
    component DaireDugmesi: Rectangle {
        id: dd
        property string glif
        property bool etkin: true
        signal tiklandi()
        width: 72; height: 72; radius: 36
        opacity: etkin ? 1 : 0.35
        color: ddm.pressed ? "white" : (ddm.containsMouse ? "#3a3a3a" : "transparent")
        border.color: "white"; border.width: 3
        Text { anchors.centerIn: parent; text: dd.glif; font.family: "Segoe UI Symbol"; font.pixelSize: 28; color: ddm.pressed ? "black" : "white" }
        MouseArea { id: ddm; anchors.fill: parent; hoverEnabled: true; enabled: dd.etkin; onClicked: dd.tiklandi() }
    }
    component Anahtar: Item {
        id: an
        property bool acik: false
        signal degisti(bool d)
        width: 50; height: 20
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "white"; border.width: 2 }
        Rectangle { x: 4; y: 4; width: an.acik ? parent.width - 22 : 0; height: parent.height - 8; color: a.kirmizi }
        Rectangle { x: an.acik ? parent.width - 12 : 0; width: 12; height: parent.height; color: "white"
                    Behavior on x { NumberAnimation { duration: 150 } } }
        MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: an.degisti(!an.acik) }
    }
    // saat/dakika seçici (Windows 8.1 döngüsel liste; tekerlek ya da sürükleme)
    component Secici: Rectangle {
        id: sc
        property int deger: 0
        property int enFazla: 59
        width: 130; height: 120
        color: scm.containsMouse ? "#3a3a3a" : "#2b2b2b"
        Text { anchors.centerIn: parent; text: a.iki(sc.deger); color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 80 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 2; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 12; color: "#a0a0a0"; visible: scm.containsMouse }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 2; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 12; color: "#a0a0a0"; visible: scm.containsMouse }
        MouseArea {
            id: scm; anchors.fill: parent; hoverEnabled: true
            onWheel: w => sc.deger = (sc.deger + (w.angleDelta.y > 0 ? 1 : -1) + sc.enFazla + 1) % (sc.enFazla + 1)
            onClicked: m => sc.deger = (sc.deger + (m.y < height / 2 ? 1 : -1) + sc.enFazla + 1) % (sc.enFazla + 1)
        }
    }
}
