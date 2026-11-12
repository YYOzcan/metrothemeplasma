// Windows 8.1 renkleri, yazı tipleri ve ayarlar (~/.config/metrothemeplasma/ayarlar.ini)
import QtQuick
import QtCore

QtObject {
    id: tema

    readonly property string varlik: "file://" + Dosya.veri + "/varlik/"
    readonly property string win: "file://" + Dosya.veri + "/win/Windows/"

    property Settings renk: Settings {
        location: "file://" + Dosya.yapilandirma + "/ayarlar.ini"
        category: "Renk"
        // Windows 8.1 varsayılanı: mor zemin, mor vurgu, mor kıvrımlı desen
        property string arkaPlan: "#180053"
        property string vurgu: "#4617b4"
        property int desen: 22000
        property bool masaustuArkaPlani: false
    }
    // Otomatik Kullan (metro-kabuk'un C++ tarafı da aynı anahtarları okur)
    property Settings otomatik: Settings {
        location: "file://" + Dosya.yapilandirma + "/ayarlar.ini"
        category: "OtomatikKullan"
        property bool etkin: true
        property string cikarilabilir: "sor"     // sor, klasor, fotograf, yedek, hicbir
        property string bellekKarti: "sor"
    }
    property Settings baslangic: Settings {
        location: "file://" + Dosya.yapilandirma + "/ayarlar.ini"
        category: "Baslangic"
        property bool giristeBaslangic: false         // oturum açınca Başlangıç ekranı (kullanıcı isteği: kapalı; Gezinti ayarından açılabilir)
        property bool uygulamalarOtomatik: false      // Başlangıç'a gidince Uygulamalar görünümü
        property bool masaustuUygulamalariOnce: false
        property string siralama: "ad"                 // ad, tarih, kullanim, kategori
        property bool fazlaKutucuk: false
        property bool koseIpucu: true                  // sağ köşe tılsım ipucu
        property bool solUstGecis: true
    }

    readonly property color arkaPlan: renk.arkaPlan
    readonly property color vurgu: renk.vurgu
    // Uygulamalar görünümü / bölmeler: zeminin biraz açığı
    readonly property color arkaPlanAcik: Qt.lighter(arkaPlan, 1.25)
    readonly property color bolmeZemin: arkaPlan
    readonly property color seciliKenar: Qt.lighter(vurgu, 1.5)

    readonly property string yazi: "Segoe UI"
    readonly property string sembol: "Segoe UI Symbol"
    readonly property int ince: 300        // Light
    readonly property int yariInce: 350    // Semilight
    readonly property int normal: 400
    readonly property int yariKalin: 600   // Semibold

    // Windows 8.1 "Kişiselleştir" bölmesindeki renk örnekleri
    readonly property var zeminRenkleri: [
        "#252525", "#2e1700", "#4e0000", "#4e0038", "#2d004e", "#1f0068", "#001e4e", "#004d60", "#004a00",
        "#15992a", "#e56c19", "#b81b1b", "#b81b6c", "#691bb8", "#1b58b8", "#569ce3", "#00aaaa", "#83ba1f",
        "#d39d09", "#e064b7", "#180053", "#003a82", "#007275", "#480091", "#a40000"
    ]
    readonly property var vurguRenkleri: [
        "#4617b4", "#8c0095", "#004b8b", "#008a00", "#5133ab", "#2672ec", "#d24726", "#ac193d", "#00a0b1",
        "#ff2e12", "#ff1d77", "#ff7600", "#91d100", "#e1b700", "#1faeff", "#56c5ff", "#00d8cc", "#78ba00",
        "#ff981d", "#ff76bc", "#7200ac", "#aa40ff", "#b01e00", "#c1004f", "#696969"
    ]
    // Windows 8.1 animasyon eğrisi (PVL: cubic-bezier(0.1, 0.9, 0.2, 1) — hızlı başlayıp yumuşak biten)
    readonly property int egri: Easing.Bezier
    readonly property var pvl: [0.1, 0.9, 0.2, 1, 1, 1]
    // QML dışı hesaplar için aynı eğri (101 noktalı tablo, doğrusal ara değer)
    readonly property var pvlTablo: {
        function b(s, p1, p2) { var u = 1 - s; return 3 * u * u * s * p1 + 3 * u * s * s * p2 + s * s * s }
        var t = []
        for (var i = 0; i <= 100; i++) {
            var x = i / 100, lo = 0, hi = 1
            for (var k = 0; k < 24; k++) { var m = (lo + hi) / 2; if (b(m, 0.1, 0.2) < x) lo = m; else hi = m }
            t.push(b((lo + hi) / 2, 0.9, 1))
        }
        return t
    }
    function pvlDeger(x) {
        if (x <= 0) return 0
        if (x >= 1) return 1
        var f = x * 100, i = Math.floor(f)
        return pvlTablo[i] + (pvlTablo[i + 1] - pvlTablo[i]) * (f - i)
    }
    readonly property int egriKisa: 167
    readonly property int egriOrta: 333
    readonly property int egriUzun: 500
}
