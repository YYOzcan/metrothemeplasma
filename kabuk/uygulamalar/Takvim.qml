// Windows 8.1 Takvim: beyaz zemin, üstte "Kasım 2026" ve oklar, aylık ızgara (bugün vurgulu), etkinlikler
// ve Türkiye'nin resmi tatilleri; bir güne tıklayınca sağda gün ayrıntısı ve yeni etkinlik. Uygulama çubuğu:
// Gün / Ay görünümü, Bugün, Yeni. Etkinlikler ~/.config/metrothemeplasma/takvim.json.
import QtQuick

Item {
    id: t
    readonly property string baslik: "Takvim"
    readonly property color renk: "#5133ab"
    readonly property color zemin: "white"
    readonly property color cubukRengi: "#3b2580"
    readonly property var solKomutlar: [
        { glif: "\ue163", metin: "Ay", eylem: function () { t.gunGorunumu = false } },
        { glif: "\ue161", metin: "Gün", eylem: function () { t.gunGorunumu = true } }
    ]
    readonly property var sagKomutlar: [
        { glif: "\ue121", metin: "Bugün", eylem: function () { t.ay = new Date(); t.secili = new Date() } },
        { glif: "\ue109", metin: "Yeni", eylem: function () { t.yeniAc() } }
    ]
    readonly property var ayAdlari: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
    readonly property var gunAdlari: ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
    property date ay: new Date()
    property date secili: new Date()
    property bool gunGorunumu: false
    property var etkinlikler: []     // { tarih: "yyyy-MM-dd", saat: "HH:mm", ad }
    readonly property string dosya: Dosya.yapilandirma + "/takvim.json"

    function anahtar(d) { return new Date(d).toLocaleDateString(Qt.locale("tr_TR"), "yyyy-MM-dd") }
    function yukle() { try { etkinlikler = JSON.parse(Dosya.oku(dosya)) || [] } catch (e) { etkinlikler = [] } }
    function kaydet() { Dosya.yaz(dosya, JSON.stringify(etkinlikler, null, 1)) }
    Component.onCompleted: yukle()

    // Türkiye resmi tatilleri: sabit günler + dini bayramlar (2025–2026 Diyanet; 2027–2030 hesaplanmış, ±1 gün)
    readonly property var sabitTatiller: ({ "01-01": "Yılbaşı", "04-23": "Ulusal Egemenlik ve Çocuk Bayramı", "05-01": "Emek ve Dayanışma Günü",
        "05-19": "Atatürk'ü Anma, Gençlik ve Spor Bayramı", "07-15": "Demokrasi ve Millî Birlik Günü", "08-30": "Zafer Bayramı",
        "10-29": "Cumhuriyet Bayramı" })
    readonly property var bayramlar: ({ "2025": [["03-30", 3, "Ramazan Bayramı"], ["06-06", 4, "Kurban Bayramı"]],
        "2026": [["03-20", 3, "Ramazan Bayramı"], ["05-27", 4, "Kurban Bayramı"]],
        "2027": [["03-10", 3, "Ramazan Bayramı"], ["05-16", 4, "Kurban Bayramı"]],
        "2028": [["02-27", 3, "Ramazan Bayramı"], ["05-05", 4, "Kurban Bayramı"]],
        "2029": [["02-15", 3, "Ramazan Bayramı"], ["04-24", 4, "Kurban Bayramı"]],
        "2030": [["02-05", 3, "Ramazan Bayramı"], ["04-13", 4, "Kurban Bayramı"]] })
    function tatil(d) {
        var a = new Date(d).toLocaleDateString(Qt.locale("tr_TR"), "MM-dd")
        if (sabitTatiller[a]) return sabitTatiller[a]
        var l = bayramlar[String(d.getFullYear())] || []
        for (var i = 0; i < l.length; i++) {
            var b = new Date(d.getFullYear() + "-" + l[i][0] + "T12:00:00"), fark = Math.round((d - b) / 86400000)
            if (fark >= 0 && fark < l[i][1]) return l[i][2] + " (" + (fark + 1) + ". gün)"
            if (fark === -1) return l[i][2] + " Arifesi"
        }
        return ""
    }
    function gunEtkinlikleri(d) {
        var k = anahtar(d)
        return etkinlikler.filter(function (e) { return e.tarih === k }).sort(function (a, b) { return a.saat.localeCompare(b.saat) })
    }

    // ---------------- başlık
    Row {
        x: 120; y: 40
        spacing: 24
        Text {
            text: t.gunGorunumu ? t.secili.getDate() + " " + t.ayAdlari[t.secili.getMonth()] + " " + t.secili.getFullYear()
                                : t.ayAdlari[t.ay.getMonth()] + " " + t.ay.getFullYear()
            color: "#222"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56
        }
        Repeater {
            model: [["\ue112", -1], ["\ue111", 1]]
            delegate: Rectangle {
                required property var modelData
                y: 22; width: 38; height: 38; radius: 19
                color: om.containsMouse ? "#e6e6e6" : "transparent"; border.color: "#444"; border.width: 2
                Text { anchors.centerIn: parent; text: modelData[0]; font.family: "Segoe UI Symbol"; font.pixelSize: 14; color: "#444" }
                MouseArea {
                    id: om; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (t.gunGorunumu) { var s = new Date(t.secili); s.setDate(s.getDate() + modelData[1]); t.secili = s; t.ay = s }
                        else { var a = new Date(t.ay); a.setDate(1); a.setMonth(a.getMonth() + modelData[1]); t.ay = a }
                    }
                }
            }
        }
    }

    // ---------------- ay görünümü
    Item {
        visible: !t.gunGorunumu
        x: 120; y: 140
        width: parent.width - 240 - (gunPanel.visible ? gunPanel.width + 30 : 0); height: parent.height - 180
        Row {
            Repeater {
                model: t.gunAdlari
                delegate: Text {
                    required property string modelData
                    width: (parent.parent.width) / 7; height: 34
                    text: modelData; color: "#666"; font.family: "Segoe UI"; font.pixelSize: 15
                }
            }
        }
        Grid {
            id: izgara
            y: 34; columns: 7
            readonly property date ilk: { var d = new Date(t.ay.getFullYear(), t.ay.getMonth(), 1); d.setDate(1 - (d.getDay() + 6) % 7); return d }
            Repeater {
                model: 42
                delegate: Rectangle {
                    id: hucre
                    required property int index
                    readonly property date gun: { var d = new Date(izgara.ilk); d.setDate(d.getDate() + index); return d }
                    readonly property bool buAy: gun.getMonth() === t.ay.getMonth()
                    readonly property bool bugun: t.anahtar(gun) === t.anahtar(new Date())
                    readonly property bool seciliMi: t.anahtar(gun) === t.anahtar(t.secili)
                    readonly property string tatilAdi: t.tatil(gun)
                    readonly property var liste: (t.etkinlikler, t.gunEtkinlikleri(gun))
                    width: (izgara.parent.width) / 7; height: (izgara.parent.height - 34) / 6
                    color: seciliMi ? "#ede8f8" : (hm.containsMouse ? "#f4f4f4" : "white")
                    border.color: "#e0e0e0"; border.width: 1
                    Rectangle { visible: hucre.bugun; anchors.fill: parent; color: "transparent"; border.color: t.renk; border.width: 3 }
                    Text {
                        x: 8; y: 4; text: hucre.gun.getDate()
                        color: hucre.bugun ? t.renk : (hucre.buAy ? "#222" : "#b0b0b0")
                        font.family: "Segoe UI"; font.weight: hucre.bugun ? 600 : Font.Light; font.pixelSize: 26
                    }
                    Column {
                        x: 8; y: 40; width: parent.width - 16; spacing: 2
                        Text { visible: hucre.tatilAdi !== ""; width: parent.width; elide: Text.ElideRight; text: hucre.tatilAdi; color: "#c41b2c"; font.family: "Segoe UI"; font.pixelSize: 12 }
                        Repeater {
                            model: hucre.liste.slice(0, 3)
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width; height: 18; color: t.renk
                                Text { x: 4; width: parent.width - 8; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                                       text: (modelData.saat ? modelData.saat + " " : "") + modelData.ad; color: "white"; font.family: "Segoe UI"; font.pixelSize: 12 }
                            }
                        }
                    }
                    MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; onClicked: { t.secili = hucre.gun; gunPanel.visible = true }
                                    onDoubleClicked: { t.secili = hucre.gun; t.yeniAc() } }
                }
            }
        }
    }

    // ---------------- gün ayrıntısı (sağ bölme / gün görünümü)
    Rectangle {
        id: gunPanel
        visible: false
        readonly property bool genis: t.gunGorunumu
        x: genis ? 120 : parent.width - width - 120; y: 140
        width: genis ? parent.width - 240 : 380; height: parent.height - 180
        color: "#f7f7f7"
        Column {
            x: 20; y: 16; width: parent.width - 40; spacing: 10
            Text { text: t.gunAdlari[(t.secili.getDay() + 6) % 7] + ", " + t.secili.getDate() + " " + t.ayAdlari[t.secili.getMonth()]; color: "#222"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 28 }
            Text { visible: text !== ""; text: t.tatil(t.secili); color: "#c41b2c"; font.family: "Segoe UI"; font.pixelSize: 16 }
            Text { visible: (t.etkinlikler, t.gunEtkinlikleri(t.secili).length === 0) && t.tatil(t.secili) === ""; text: "Etkinlik yok"; color: "#777"; font.family: "Segoe UI"; font.pixelSize: 16 }
            Repeater {
                model: (t.etkinlikler, t.gunEtkinlikleri(t.secili))
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width; height: 50; color: "white"; border.color: "#e0e0e0"
                    Rectangle { width: 6; height: parent.height; color: t.renk }
                    Text { x: 18; y: 6; text: modelData.saat || "Tüm gün"; color: "#666"; font.family: "Segoe UI"; font.pixelSize: 13 }
                    Text { x: 18; y: 24; width: parent.width - 70; elide: Text.ElideRight; text: modelData.ad; color: "#111"; font.family: "Segoe UI"; font.pixelSize: 16 }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                        text: "\ue107"; font.family: "Segoe UI Symbol"; font.pixelSize: 15; color: sm.containsMouse ? "#c41b2c" : "#888"
                        MouseArea { id: sm; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true
                            onClicked: { var e = modelData; t.etkinlikler = t.etkinlikler.filter(function (x) { return x !== e && !(x.tarih === e.tarih && x.saat === e.saat && x.ad === e.ad) }); t.kaydet() } }
                    }
                }
            }
            Text {
                text: "+ Yeni etkinlik"; color: am.containsMouse ? Qt.lighter(t.renk, 1.3) : t.renk; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 16
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.yeniAc() }
            }
        }
    }
    onGunGorunumuChanged: if (gunGorunumu) gunPanel.visible = true

    // ---------------- yeni etkinlik
    function yeniAc() { adGirdi.text = ""; saatGirdi.text = ""; yeni.visible = true; adGirdi.forceActiveFocus() }
    Rectangle {
        id: yeni
        visible: false
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        MouseArea { anchors.fill: parent; onClicked: yeni.visible = false }
        Rectangle {
            width: parent.width; height: 300; anchors.verticalCenter: parent.verticalCenter
            color: t.renk
            MouseArea { anchors.fill: parent }
            Column {
                x: (parent.width - 600) / 2; y: 30; width: 600; spacing: 14
                Text { text: "Yeni etkinlik · " + t.secili.getDate() + " " + t.ayAdlari[t.secili.getMonth()] + " " + t.secili.getFullYear(); color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 30 }
                Rectangle { width: 600; height: 34; color: "white"
                    TextInput { id: adGirdi; anchors.fill: parent; anchors.margins: 7; font.family: "Segoe UI"; font.pixelSize: 16; clip: true; onAccepted: kaydetDugme.kaydet() }
                    Text { visible: adGirdi.text === ""; x: 7; anchors.verticalCenter: parent.verticalCenter; text: "Etkinlik adı"; color: "#888"; font.family: "Segoe UI"; font.pixelSize: 16 } }
                Rectangle { width: 160; height: 34; color: "white"
                    TextInput { id: saatGirdi; anchors.fill: parent; anchors.margins: 7; font.family: "Segoe UI"; font.pixelSize: 16; inputMask: "99:99;_"; onAccepted: kaydetDugme.kaydet() }
                    Text { visible: saatGirdi.text === ":"; x: 7; anchors.verticalCenter: parent.verticalCenter; text: "Saat (boş: tüm gün)"; color: "#888"; font.family: "Segoe UI"; font.pixelSize: 13 } }
                Row {
                    spacing: 10
                    Rectangle {
                        id: kaydetDugme
                        function kaydet() {
                            if (adGirdi.text.trim() === "") return
                            var s = /^\d\d:\d\d$/.test(saatGirdi.text) ? saatGirdi.text : ""
                            t.etkinlikler = t.etkinlikler.concat([{ tarih: t.anahtar(t.secili), saat: s, ad: adGirdi.text.trim() }])
                            t.kaydet(); yeni.visible = false; gunPanel.visible = true
                        }
                        width: 110; height: 36; color: km.pressed ? "#ddd" : "white"
                        Text { anchors.centerIn: parent; text: "Kaydet"; color: t.renk; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                        MouseArea { id: km; anchors.fill: parent; onClicked: kaydetDugme.kaydet() }
                    }
                    Rectangle {
                        width: 110; height: 36; color: "transparent"; border.color: "white"; border.width: 2
                        Text { anchors.centerIn: parent; text: "İptal"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; onClicked: yeni.visible = false }
                    }
                }
            }
        }
    }
    focus: true
    Keys.onEscapePressed: { if (yeni.visible) yeni.visible = false; else gunPanel.visible = false }
}
