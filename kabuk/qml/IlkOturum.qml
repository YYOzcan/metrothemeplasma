// Windows 8.1 ilk oturum animasyonu (FirstLogonAnim): "Merhaba", "Sizin için ayarları yapıyoruz",
// fare öğreticisi (köşeye giden imleç, beliren tılsımlar), renk döngüsü eşliğinde mesajlar, "Başlayabilirsiniz".
// Metinler ve renk döngüsü kurulumda kendi Windows 8.1 kopyandan çıkarılır (varlik/ilk-oturum.json).
import QtQuick
import QtQuick.Window

Window {
    id: pen
    property var tema
    property var sonra: null           // bitince çağrılır (Başlangıç ekranı)
    property bool oynuyor: false
    property var veri: ({ metin: {}, renkler: ["#008a00", "#2671eb", "#8c0095", "#ac193d", "#ff8f32", "#00aaaa"], adim: 240 })
    color: "black"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Merhaba"
    width: Screen.width; height: Screen.height

    Component.onCompleted: {
        KatmanYardimci.ayarla(pen, 3, 15, 1, -1, "metro-ilk-oturum")
        try { veri = JSON.parse(Dosya.oku(Dosya.veri + "/varlik/ilk-oturum.json")) } catch (e) {}
    }
    function m(k, yedek) { return (veri.metin && veri.metin[k]) ? veri.metin[k] : yedek }

    function oynat(fn) {
        sonra = fn || null
        oynuyor = true
        zemin.color = "black"
        zemin.opacity = 1
        buyuk.opacity = 0; kucuk.opacity = 0; ogretici.opacity = 0; alt.opacity = 0
        visible = true
        requestActivate()
        sira.restart()
    }
    function bitir() {
        sira.stop(); renkDongusu.stop()
        visible = false
        oynuyor = false
        if (sonra) sonra()
    }

    // zemin: kullanıcının rengi; mesaj bölümünde FirstLogonAnim.html'deki altı renk arasında yumuşak döngü
    Rectangle {
        id: zemin
        anchors.fill: parent
        color: "black"
    }
    property int renkNo: 0
    SequentialAnimation {
        id: renkDongusu
        loops: Animation.Infinite
        ColorAnimation {
            id: renkGecisi
            target: zemin; property: "color"
            // 240 adım, her üç karede bir boyama: yaklaşık 4 saniye
            duration: Math.round(pen.veri.adim / 60 * 1000)
        }
        ScriptAction { script: { pen.renkNo = (pen.renkNo + 1) % pen.veri.renkler.length; renkGecisi.to = pen.veri.renkler[(pen.renkNo + 1) % pen.veri.renkler.length] } }
    }

    // ana metin (42 pt Segoe UI Light) ve altındaki küçük metin (20 pt)
    Text {
        id: buyuk
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: "white"
        font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 56
        opacity: 0
    }
    Text {
        id: kucuk
        anchors.top: buyuk.bottom; anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        color: "white"
        font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 26
        opacity: 0
    }
    Text {
        id: alt
        anchors.bottom: parent.bottom; anchors.bottomMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter
        color: "white"
        font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 26
        opacity: 0
    }

    // fare öğreticisi: küçültülmüş ekran, sağ kenarda tılsım çubuğu, köşeye giden imleç
    Item {
        id: ogretici
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: kucuk.bottom; anchors.topMargin: 50
        width: 378; height: 213
        opacity: 0
        Rectangle { anchors.fill: parent; color: Qt.darker(pen.tema.arkaPlan, 1.6); border.color: Qt.rgba(1, 1, 1, 0.5) }
        Item {
            anchors.fill: parent; clip: true
            Rectangle {
                id: mockTilsim
                x: parent.width; width: 35; height: parent.height
                color: "#1A1A1A"
                Column {
                    anchors.centerIn: parent; spacing: 14
                    Repeater {
                        model: ["ara", "paylas", "baslangic", "aygitlar", "ayarlar"]
                        Image { required property var modelData; width: 18; height: 18; source: pen.tema.varlik + "tilsim-" + modelData + ".png" }
                    }
                }
            }
        }
        Canvas {
            id: imlec
            width: 14; height: 21
            x: 182; y: 100
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.fillStyle = "white"; c.strokeStyle = "black"; c.lineWidth = 1
                c.beginPath(); c.moveTo(1, 1); c.lineTo(1, 17); c.lineTo(5, 13); c.lineTo(8, 20); c.lineTo(10, 19)
                c.lineTo(7, 12); c.lineTo(12, 12); c.closePath(); c.fill(); c.stroke()
            }
        }
    }

    SequentialAnimation {
        id: sira
        // siyahtan kullanıcı rengine
        ColorAnimation { target: zemin; property: "color"; to: pen.tema.arkaPlan; duration: 1200 }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1021", "Merhaba") }
        NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
        PauseAnimation { duration: 2600 }
        NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 700 }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1022", "Sizin için ayarları yapıyoruz") }
        NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
        PauseAnimation { duration: 3000 }
        NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 700 }
        // öğretici
        PropertyAction { target: buyuk; property: "anchors.verticalCenterOffset"; value: -200 }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1008", "Farenizi herhangi bir köşeye götürün") }
        PropertyAction { target: kucuk; property: "text"; value: pen.m("1024", "Bilgisayarınız hazır olduktan sonra") }
        ParallelAnimation {
            NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: kucuk; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: ogretici; property: "opacity"; to: 1; duration: 800 }
        }
        SequentialAnimation {
            loops: 2
            PauseAnimation { duration: 700 }
            ParallelAnimation {
                NumberAnimation { target: imlec; property: "x"; to: 372; duration: 1100; easing.type: Easing.InOutCubic }
                NumberAnimation { target: imlec; property: "y"; to: 0; duration: 1100; easing.type: Easing.InOutCubic }
            }
            NumberAnimation { target: mockTilsim; property: "x"; to: 343; duration: 450; easing.type: Easing.Bezier; easing.bezierCurve: [0.1, 0.9, 0.2, 1, 1, 1] }
            PauseAnimation { duration: 1400 }
            NumberAnimation { target: mockTilsim; property: "x"; to: 378; duration: 300 }
            ParallelAnimation {
                NumberAnimation { target: imlec; property: "x"; to: 182; duration: 900; easing.type: Easing.InOutCubic }
                NumberAnimation { target: imlec; property: "y"; to: 100; duration: 900; easing.type: Easing.InOutCubic }
            }
        }
        ParallelAnimation {
            NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 700 }
            NumberAnimation { target: kucuk; property: "opacity"; to: 0; duration: 700 }
            NumberAnimation { target: ogretici; property: "opacity"; to: 0; duration: 700 }
        }
        PropertyAction { target: buyuk; property: "anchors.verticalCenterOffset"; value: -20 }
        // renk döngüsü ve mesajlar
        ScriptAction { script: { pen.renkNo = 0; renkGecisi.to = pen.veri.renkler[0]; renkDongusu.restart() } }
        PropertyAction { target: alt; property: "text"; value: pen.m("1111", "Bilgisayarınızı kapatmayın") }
        NumberAnimation { target: alt; property: "opacity"; to: 1; duration: 800 }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1101", "Uygulamalarınız hazırlanıyor") }
        NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
        PauseAnimation { duration: 4200 }
        NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 700 }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1102", "Birkaç işlem tamamlanıyor") }
        NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
        PauseAnimation { duration: 4200 }
        NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 700 }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1103", "Neredeyse hazır") }
        NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
        PauseAnimation { duration: 3600 }
        ParallelAnimation {
            NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 700 }
            NumberAnimation { target: alt; property: "opacity"; to: 0; duration: 700 }
        }
        PropertyAction { target: buyuk; property: "text"; value: pen.m("1025", "Başlayabilirsiniz") }
        NumberAnimation { target: buyuk; property: "opacity"; to: 1; duration: 800 }
        PauseAnimation { duration: 2200 }
        ScriptAction { script: renkDongusu.stop() }
        ParallelAnimation {
            NumberAnimation { target: buyuk; property: "opacity"; to: 0; duration: 600 }
            ColorAnimation { target: zemin; property: "color"; to: pen.tema.arkaPlan; duration: 600 }
        }
        ScriptAction { script: pen.bitir() }
    }

    // Windows'ta atlanamaz; sınama için Esc
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: if (SinamaDondur >= 0) pen.bitir() }
}
