// Windows 8.1 Modern uygulama çerçevesi: açılış ekranı (kutucuk rengi + logo), sayfa giriş animasyonu
// (PVL eğrisi), fare üst kenara gelince beliren 8.1 Update başlık çubuğu, üstten aşağı sürükleyerek kapatma,
// sağ tıkla alttan açılan uygulama çubuğu.
import QtQuick
import QtQuick.Window
import QtCore

Window {
    id: pen
    // kayıtta "pencere": [g, y] varsa normal pencere (masaüstü sihirbazı), yoksa tam ekran Modern uygulama
    readonly property var pencereBoyutu: bilgi.pencere || null
    visibility: pencereBoyutu ? Window.Windowed : Window.FullScreen
    width: pencereBoyutu ? pencereBoyutu[0] : Screen.width
    height: pencereBoyutu ? pencereBoyutu[1] : Screen.height
    visible: true
    color: "black"
    title: uygulama.item ? uygulama.item.baslik : ""

    // uygulama kaydı (ad, renk, glif, QML dosyası): uygulamalar.json — kurulum ve simgelerle aynı kaynak
    readonly property var bilgi: {
        var yol = String(Qt.resolvedUrl("uygulamalar.json")).replace(/^file:\/\//, "")
        try {
            var l = JSON.parse(Dosya.oku(decodeURIComponent(yol)))
            for (var i = 0; i < l.length; i++) if (l[i].ad === UygulamaAdi) return l[i]
        } catch (e) {}
        return { kaynak: "", renk: "#333333", glif: "" }
    }
    readonly property var pvl: [0.1, 0.9, 0.2, 1, 1, 1]
    readonly property string yazi: "Segoe UI"
    readonly property string sembol: "Segoe UI Symbol"
    readonly property string medya: "file://" + Dosya.veri + "/win/Windows/Media/"

    // sistem vurgu rengi (Başlangıç ekranının rengi): Kişiselleştir ayarlarından
    Settings {
        id: renkAyari
        location: "file://" + Dosya.yapilandirma + "/ayarlar.ini"
        category: "Renk"
        property string arkaPlan: "#180053"
        property string vurgu: "#4617b4"
    }
    readonly property color vurgu: renkAyari.vurgu

    // ------------------------------------------------------------------ içerik
    Item {
        id: sahne
        anchors.fill: parent
        // üstten sürükleyip kapatma: pencere küçülüp imleci izler
        property real kucul: 0
        transformOrigin: Item.Top
        scale: 1 - kucul * 0.6
        y: kucul * pen.height * 0.55
        opacity: 1 - Math.max(0, kucul - 0.7) * 2

        Rectangle { anchors.fill: parent; color: uygulama.item ? uygulama.item.zemin : pen.bilgi.renk }

        Loader {
            id: uygulama
            anchors.fill: parent
            source: pen.bilgi.kaynak
            asynchronous: true
            opacity: 0
            transform: Translate { id: girisKayma; x: 80 }
            onLoaded: acilisBitis.start()
            onStatusChanged: if (status === Loader.Error) acilis.visible = false
        }

        // açılış ekranı: kutucuk rengi, ortada logo (Windows 8.1 splash screen 620×300)
        Rectangle {
            id: acilis
            anchors.fill: parent
            color: pen.bilgi.renk
            Text {
                anchors.centerIn: parent
                text: pen.bilgi.glif
                font.family: pen.sembol; font.pixelSize: 150
                color: "white"
            }
        }
        SequentialAnimation {
            id: acilisBitis
            PauseAnimation { duration: pen.pencereBoyutu ? 0 : 650 }
            NumberAnimation { target: acilis; property: "opacity"; to: 0; duration: 250 }
            PropertyAction { target: acilis; property: "visible"; value: false }
            // sayfa girişi (enterPage): sağdan kayarak
            ParallelAnimation {
                NumberAnimation { target: uygulama; property: "opacity"; to: 1; duration: 333 }
                NumberAnimation { target: girisKayma; property: "x"; to: 0; duration: 500; easing.type: Easing.Bezier; easing.bezierCurve: pen.pvl }
            }
        }

        // sağ tık: uygulama çubuğu
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton
            onClicked: cubuk.ac = !cubuk.ac
        }

        // ------------------------------------------------------------------ uygulama çubuğu (alt)
        Item {
            id: cubuk
            property bool ac: false
            readonly property var sol: uygulama.item && uygulama.item.solKomutlar ? uygulama.item.solKomutlar : []
            readonly property var sag: uygulama.item && uygulama.item.sagKomutlar ? uygulama.item.sagKomutlar : []
            visible: y < pen.height
            width: parent.width; height: 88
            y: ac && (sol.length + sag.length) > 0 ? pen.height - height : pen.height
            Behavior on y { NumberAnimation { duration: 367; easing.type: Easing.Bezier; easing.bezierCurve: pen.pvl } }
            z: 10
            Rectangle { anchors.fill: parent; color: uygulama.item ? uygulama.item.cubukRengi : "#1d1d1d" }
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton }
            Row {
                x: 20; y: 6; spacing: 0
                Repeater { model: cubuk.sol; delegate: CubukDugmesi { required property var modelData; komut: modelData; onCalistir: cubuk.ac = false } }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 20; y: 6; spacing: 0
                Repeater { model: cubuk.sag; delegate: CubukDugmesi { required property var modelData; komut: modelData; onCalistir: cubuk.ac = false } }
            }
        }
    }
    // çubuk açıkken içeriğe tık onu kapatır (Windows'ta "hafif kapatma")
    MouseArea {
        anchors.fill: parent; anchors.bottomMargin: cubuk.height
        visible: cubuk.ac
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: cubuk.ac = false
    }

    // ------------------------------------------------------------------ 8.1 Update başlık çubuğu
    // fare üst kenarda kısa bir süre durunca kayarak iner: solda uygulama simgesi, sağda simge durumu ve kapat
    Item {
        id: baslikCubugu
        visible: !pen.pencereBoyutu
        width: parent.width; height: 32
        property bool goster: false
        y: goster ? 0 : -height
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        z: 20
        Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.85 }
        Rectangle {
            x: 8; anchors.verticalCenter: parent.verticalCenter
            width: 22; height: 22; color: pen.bilgi.renk
            Text { anchors.centerIn: parent; text: pen.bilgi.glif; font.family: pen.sembol; font.pixelSize: 13; color: "white" }
        }
        Row {
            anchors.right: parent.right
            height: parent.height
            Repeater {
                model: [{ glif: "", eylem: "kucult" }, { glif: "", eylem: "kapat" }]
                delegate: Rectangle {
                    required property var modelData
                    width: 46; height: 32
                    color: bm.containsMouse ? (modelData.eylem === "kapat" ? "#e81123" : Qt.rgba(1, 1, 1, 0.2)) : "transparent"
                    Text { anchors.centerIn: parent; text: modelData.glif; font.family: pen.sembol; font.pixelSize: 11; color: "white" }
                    MouseArea {
                        id: bm; anchors.fill: parent; hoverEnabled: true
                        onClicked: modelData.eylem === "kapat" ? Qt.quit() : pen.showMinimized()
                    }
                }
            }
        }
        HoverHandler { id: baslikUzerinde }
    }
    Timer { id: baslikGecikme; interval: 450; onTriggered: baslikCubugu.goster = true }
    Timer { id: baslikGizle; interval: 700; onTriggered: if (!baslikUzerinde.hovered && !ustKenar.containsMouse) baslikCubugu.goster = false }

    // üst kenar: başlık çubuğu ipucu ve aşağı sürükleyerek kapatma
    MouseArea {
        id: ustKenar
        enabled: !pen.pencereBoyutu   // pencereli sihirbazda gerçek pencere çerçevesi var
        width: parent.width; height: 3
        z: 30
        hoverEnabled: true
        property real basY: 0
        onContainsMouseChanged: { if (containsMouse) baslikGecikme.restart(); else { baslikGecikme.stop(); baslikGizle.restart() } }
        onPressed: m => { basY = m.y; baslikGecikme.stop() }
        onPositionChanged: m => { if (pressed) sahne.kucul = Math.max(0, Math.min(1, (m.y - basY) / (pen.height * 0.6))) }
        onReleased: {
            if (sahne.kucul > 0.6) kapanis.start()
            else geriDon.start()
        }
    }
    NumberAnimation { id: geriDon; target: sahne; property: "kucul"; to: 0; duration: 250; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: kapanis
        NumberAnimation { target: sahne; property: "kucul"; to: 1.2; duration: 200 }
        ScriptAction { script: Qt.quit() }
    }
    onActiveChanged: if (!active) { baslikCubugu.goster = false; cubuk.ac = false }

    // Esc / Alt+F4 Windows'taki gibi; Ctrl+Z vb. uygulamalar kendisi
    Shortcut { sequence: "Meta+Z"; onActivated: cubuk.ac = !cubuk.ac }
}
