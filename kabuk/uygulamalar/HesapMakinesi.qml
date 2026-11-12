// Windows 8.1 Hesap Makinesi: koyu zemin, sağa yaslı büyük ekran, Standart / Bilimsel (uygulama çubuğu),
// Windows hesap makinesi mantığı (anında işlem: 2 + 3 × 4 = 20), bellek tuşları, klavye.
import QtQuick

Item {
    id: h
    readonly property string baslik: "Hesap Makinesi"
    readonly property color zemin: "#1f1f1f"
    readonly property color cubukRengi: "#2b2b2b"
    property string kip: "standart"
    readonly property var solKomutlar: [
        { glif: "", metin: "Standart", eylem: function () { h.kip = "standart" } },
        { glif: "", metin: "Bilimsel", eylem: function () { h.kip = "bilimsel" } }
    ]
    readonly property var sagKomutlar: []

    // ------------------------------------------------------------------ hesap
    property string ekran: "0"
    property string ifade: ""          // üstteki küçük satır
    property real birikim: 0
    property string bekleyen: ""       // + − × ÷ ^
    property bool yeniSayi: true
    property bool hata: false
    property real bellek: 0
    property bool bellekVar: false

    function bicim(x) {
        if (!isFinite(x)) { hata = true; return isNaN(x) ? "Geçersiz giriş" : "Sıfıra bölünemez" }
        var s = Math.abs(x) >= 1e16 || (Math.abs(x) < 1e-9 && x !== 0) ? x.toExponential(10).replace(/\.?0+e/, "e") : String(parseFloat(x.toPrecision(16)))
        return s.replace(".", ",")
    }
    function deger() { return parseFloat(ekran.replace(/\./g, "").replace(",", ".")) || 0 }
    function binlik(s) {
        // 1234567,5 -> 1.234.567,5 (Türkçe bölge ayarı)
        if (s.indexOf("e") >= 0 || hata) return s
        var e = s.split(","), t = e[0], n = t[0] === "-" ? "-" : ""
        t = t.replace("-", "").replace(/\B(?=(\d{3})+(?!\d))/g, ".")
        return n + t + (e.length > 1 ? "," + e[1] : "")
    }
    function temizle() { ekran = "0"; ifade = ""; birikim = 0; bekleyen = ""; yeniSayi = true; hata = false }
    function rakam(r) {
        if (hata) temizle()
        if (yeniSayi) { ekran = r === "," ? "0," : r; yeniSayi = false; return }
        if (r === "," && ekran.indexOf(",") >= 0) return
        if (ekran.replace(/[-,.]/g, "").length >= 16) return
        ekran = (ekran === "0" && r !== ",") ? r : ekran + r
    }
    function hesapla(a, op, b) {
        switch (op) {
        case "+": return a + b
        case "−": return a - b
        case "×": return a * b
        case "÷": return a / b
        case "^": return Math.pow(a, b)
        case "mod": return a % b
        }
        return b
    }
    function islem(op) {
        if (hata) return
        var d = deger()
        if (bekleyen !== "" && !yeniSayi) d = hesapla(birikim, bekleyen, d)
        else if (bekleyen === "") d = deger()
        else d = birikim
        if (bekleyen !== "" && yeniSayi) ifade = ifade.replace(/ \S+ $/, " " + op + " ")
        else ifade += bicim(deger()) + " " + op + " "
        birikim = d; bekleyen = op; yeniSayi = true
        ekran = bicim(d)
    }
    function esittir() {
        if (hata) { temizle(); return }
        if (bekleyen === "") return
        var d = hesapla(birikim, bekleyen, deger())
        ekran = bicim(d); ifade = ""; bekleyen = ""; yeniSayi = true; birikim = 0
    }
    function tekli(ad) {
        if (hata) return
        var x = deger(), r
        switch (ad) {
        case "√": r = Math.sqrt(x); break
        case "x²": r = x * x; break
        case "x³": r = x * x * x; break
        case "1/x": r = 1 / x; break
        case "%": r = bekleyen !== "" ? birikim * x / 100 : x / 100; break
        case "±": if (!yeniSayi && ekran !== "0") { ekran = ekran[0] === "-" ? ekran.slice(1) : "-" + ekran; return } r = -x; break
        case "sin": r = Math.sin(x * Math.PI / 180); break
        case "cos": r = Math.cos(x * Math.PI / 180); break
        case "tan": r = Math.tan(x * Math.PI / 180); break
        case "ln": r = Math.log(x); break
        case "log": r = Math.log10(x); break
        case "10ˣ": r = Math.pow(10, x); break
        case "eˣ": r = Math.exp(x); break
        case "n!": { r = 1; if (x < 0 || x > 170 || x !== Math.floor(x)) r = NaN; else for (var i = 2; i <= x; i++) r *= i; break }
        case "π": r = Math.PI; break
        case "e": r = Math.E; break
        }
        ekran = bicim(r); yeniSayi = true
    }
    function geri() {
        if (yeniSayi || hata) return
        ekran = ekran.length > 1 && !(ekran.length === 2 && ekran[0] === "-") ? ekran.slice(0, -1) : "0"
    }
    function bellekIslem(m) {
        switch (m) {
        case "MC": bellek = 0; bellekVar = false; break
        case "MR": ekran = bicim(bellek); yeniSayi = true; break
        case "MS": bellek = deger(); bellekVar = true; yeniSayi = true; break
        case "M+": bellek += deger(); bellekVar = true; yeniSayi = true; break
        case "M−": bellek -= deger(); bellekVar = true; yeniSayi = true; break
        }
    }
    function bas(t) {
        if (/^[0-9]$/.test(t) || t === ",") rakam(t)
        else if (["+", "−", "×", "÷", "^", "mod"].indexOf(t) >= 0) islem(t)
        else if (t === "=") esittir()
        else if (t === "C") temizle()
        else if (t === "CE") { ekran = "0"; yeniSayi = true; hata = false }
        else if (t === "⌫") geri()
        else if (t[0] === "M") bellekIslem(t)
        else tekli(t)
    }

    focus: true
    Keys.onPressed: e => {
        var k = e.text
        var esle = { "*": "×", "/": "÷", "-": "−", "+": "+", ".": ",", ",": ",", "=": "=", "%": "%", "^": "^" }
        if (/^[0-9]$/.test(k)) bas(k)
        else if (esle[k]) bas(esle[k])
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) bas("=")
        else if (e.key === Qt.Key_Backspace) bas("⌫")
        else if (e.key === Qt.Key_Escape) bas("C")
        else if (e.key === Qt.Key_Delete) bas("CE")
        else return
        e.accepted = true
    }

    // ------------------------------------------------------------------ görünüm
    readonly property bool bilimsel: kip === "bilimsel"
    // tuşlar ekran yüksekliğini doldurur (Windows 8.1'de tuş takımı ekranın çoğunu kaplar)
    readonly property int satirSayisi: bilimsel ? 5 : 7
    readonly property real tusYuk: Math.max(48, Math.min(120, (height - 260) / satirSayisi - 6))
    readonly property real tusGen: tusYuk * (bilimsel ? 1.7 : 1.75)
    readonly property real sayiAlan: 4 * tusGen + 18
    readonly property real tusAlan: bilimsel ? sayiAlan * 2 + 6 : sayiAlan
    Column {
        id: govde
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(40, (h.height - height) / 2)
        width: h.tusAlan
        spacing: 6

        // ifade ve büyük sayı
        Text {
            width: parent.width; height: 30
            horizontalAlignment: Text.AlignRight
            text: h.ifade.replace(/\./g, ",")
            color: "#a0a0a0"; font.family: "Segoe UI"; font.pixelSize: 22; elide: Text.ElideLeft
        }
        Text {
            width: parent.width; height: 110
            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
            text: h.binlik(h.ekran)
            color: "white"; font.family: "Segoe UI"; font.weight: Font.Light
            font.pixelSize: h.hata ? 50 : Math.min(96, 96 * 13 / Math.max(13, text.length))
        }
        Item { width: 1; height: 14 }
        Row {
            spacing: 6
            // bilimsel tuşlar (sol blok)
            Grid {
                visible: h.bilimsel
                columns: 4; spacing: 6
                Repeater {
                    model: ["sin", "cos", "tan", "π", "ln", "log", "eˣ", "10ˣ", "x²", "x³", "^", "√", "n!", "mod", "1/x", "e",
                            "MC", "MR", "MS", "M+"]
                    delegate: Tus { required property var modelData; etiket: modelData; tur: modelData[0] === "M" ? "bellek" : "islev"; genislik: h.tusGen }
                }
            }
            Grid {
                columns: 4; spacing: 6
                Repeater {
                    model: h.bilimsel
                        ? ["C", "CE", "⌫", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+", "±", "0", ",", "="]
                        : ["MC", "MR", "M+", "M−", "%", "√", "x²", "1/x", "C", "CE", "⌫", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+", "±", "0", ",", "="]
                    delegate: Tus {
                        required property var modelData
                        etiket: modelData
                        genislik: h.tusGen
                        tur: /^[0-9,±]$/.test(modelData) ? "rakam" : (modelData === "=" ? "esit" : (modelData[0] === "M" ? "bellek" : "islev"))
                    }
                }
            }
        }
    }

    component Tus: Rectangle {
        id: t
        property string etiket
        property string tur: "rakam"
        property real genislik: 120
        width: genislik; height: h.tusYuk
        readonly property color temel: tur === "esit" ? pen.vurgu : (tur === "rakam" ? "#3a3a3a" : "#2b2b2b")
        color: tm.pressed ? Qt.lighter(temel, 1.6) : (tm.containsMouse ? Qt.lighter(temel, 1.25) : temel)
        opacity: (etiket === "MC" || etiket === "MR") && !h.bellekVar ? 0.5 : 1
        Text {
            anchors.centerIn: parent
            text: t.etiket
            color: "white"
            font.family: "Segoe UI"; font.pixelSize: t.tur === "rakam" ? Math.round(h.tusYuk * 0.36) : Math.round(h.tusYuk * 0.27)
            font.weight: t.tur === "rakam" ? Font.Normal : Font.Light
        }
        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; onClicked: { h.bas(t.etiket); h.forceActiveFocus() } }
    }
}
