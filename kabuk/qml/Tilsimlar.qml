// Tılsımlar çubuğu (Win+C, sağ köşeler): Ara, Paylaş, Başlangıç, Aygıtlar, Ayarlar
import QtQuick
import QtQuick.Window

Window {
    id: pen
    property var tema
    property var ana
    property bool acik: false
    property bool ipucu: false      // köşe ipucu: yalnızca simgeler, zemin yok
    property real ilerleme: 0       // kayma animasyonu
    width: 86
    height: Screen.height
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Tılsımlar"

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 1 | 2 | 8, 0, -1, "metro-tilsimlar")

    readonly property var ogeler: [
        { ad: "Ara", simge: "ara", eylem: "ara" },
        { ad: "Paylaş", simge: "paylas", eylem: "paylas" },
        { ad: "Başlangıç", simge: "baslangic", eylem: "baslangic" },
        { ad: "Aygıtlar", simge: "aygitlar", eylem: "aygitlar" },
        { ad: "Ayarlar", simge: "ayarlar", eylem: "ayarlar" }
    ]

    function goster(ipucuKipi) {
        kapanis.stop()
        if (acik && !ipucu) return
        ipucu = ipucuKipi
        if (!acik) {
            acik = true
            visible = true
            ilerleme = 0
            acilis.restart()
        }
        if (!ipucu) {
            KatmanYardimci.klavyeAyarla(pen, 1)
            requestActivate()
            kok.forceActiveFocus()
        }
        cikisZamanlayici.restart()
    }
    function tamAc() { goster(false) }
    function kapat() {
        if (!acik) return
        acik = false
        ipucu = false
        acilis.stop()
        kapanis.restart()
        KatmanYardimci.klavyeAyarla(pen, 0)
    }
    NumberAnimation { id: acilis; target: pen; property: "ilerleme"; to: 1; duration: 420; easing.type: Easing.OutQuint }
    SequentialAnimation {
        id: kapanis
        NumberAnimation { target: pen; property: "ilerleme"; to: 0; duration: 180; easing.type: Easing.InQuad }
        ScriptAction { script: pen.visible = false }
    }
    // ipucu kipinde fare çubuktan uzaklaşırsa kapanır
    Timer {
        id: cikisZamanlayici
        interval: 900
        onTriggered: if (pen.ipucu && !alan.containsMouse) pen.kapat()
    }

    Item {
        id: kok
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: pen.ana.tilsimKapat()
        Keys.onUpPressed: secim = (secim + 4) % 5
        Keys.onDownPressed: secim = (secim + 1) % 5
        Keys.onReturnPressed: pen.ana.tilsimEylem(pen.ogeler[secim].eylem)
        property int secim: -1

        Rectangle {
            anchors.fill: parent
            color: "#111111"
            opacity: pen.ipucu ? 0 : pen.ilerleme
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        MouseArea {
            id: alan
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: mouse => {
                // ipucundan tam çubuğa: fare kenar boyunca orta bölgeye inince
                if (pen.ipucu && mouse.y > pen.height * 0.25 && mouse.y < pen.height * 0.75) pen.tamAc()
            }
            onExited: if (pen.ipucu) pen.kapat(); else cikisZamanlayici.restart()
        }

        Column {
            id: sutun
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 0
            Repeater {
                model: pen.ogeler
                delegate: Item {
                    id: og
                    required property var modelData
                    required property int index
                    width: sutun.width; height: 104
                    // her simge merkezden uzaklığına göre gecikmeyle kayar
                    readonly property real gecikme: Math.abs(index - 2) * 0.12
                    readonly property real t: Math.max(0, Math.min(1, (pen.ilerleme - gecikme) / (1 - 0.24)))
                    transform: Translate { x: (1 - og.t) * 90 }
                    opacity: og.t
                    Rectangle {
                        anchors.fill: parent
                        color: oma.pressed ? "#3a3a3a" : "#2a2a2a"
                        visible: !pen.ipucu && (oma.containsMouse || kok.secim === index)
                    }
                    Image {
                        visible: og.modelData.simge === "baslangic" && !pen.ipucu && oma.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 4
                        source: pen.tema.varlik + "tilsim-baslangic-isik.png"
                        width: 86; height: 50
                    }
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: pen.ipucu ? 28 : 12
                        width: 48; height: 48
                        source: pen.tema.varlik + "tilsim-" + og.modelData.simge + (pen.ipucu ? "-golge" : "") + ".png"
                        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                    }
                    Text {
                        visible: !pen.ipucu
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 66
                        text: og.modelData.ad
                        color: "white"
                        font.family: "Segoe UI"; font.pixelSize: 15
                    }
                    MouseArea {
                        id: oma
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { if (pen.ipucu) pen.tamAc(); kok.secim = index }
                        onClicked: pen.ana.tilsimEylem(og.modelData.eylem)
                    }
                }
            }
        }
    }
}
