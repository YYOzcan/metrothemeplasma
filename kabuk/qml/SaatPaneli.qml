// Tılsımlarla birlikte sol altta açılan saat ve tarih paneli
import QtQuick
import QtQuick.Window
import org.kde.plasma.networkmanagement as PlasmaNM

Window {
    id: pen
    property var tema
    property bool acik: false
    property real ilerleme: 0
    property date simdi: new Date()
    width: kutu.width + 52
    height: kutu.height + 52
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput
    title: "Saat"

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 2 | 4, 0, -1, "metro-saat")

    function goster() {
        simdi = new Date()
        kapanis.stop()
        if (!acik) { acik = true; visible = true; acilis.restart() }
    }
    function kapat() {
        if (!acik) return
        acik = false
        acilis.stop()
        kapanis.restart()
    }
    NumberAnimation { id: acilis; target: pen; property: "ilerleme"; to: 1; duration: 380; easing.type: Easing.OutQuint }
    SequentialAnimation {
        id: kapanis
        NumberAnimation { target: pen; property: "ilerleme"; to: 0; duration: 160 }
        ScriptAction { script: pen.visible = false }
    }
    Timer { interval: 1000; running: pen.acik; repeat: true; onTriggered: pen.simdi = new Date() }

    PlasmaNM.ConnectionIcon { id: ag }

    Rectangle {
        id: kutu
        x: 52; y: 0
        width: satir.width + 60; height: 140
        color: "#111111"
        opacity: pen.ilerleme
        transform: Translate { x: (1 - pen.ilerleme) * -40 }
        Row {
            id: satir
            x: 26
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Image {
                    width: 32; height: 32
                    sourceSize.width: 64; sourceSize.height: 64
                    source: ag.connectionIcon !== "" ? "image://simge/" + ag.connectionIcon : ""
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(pen.simdi, "HH:mm")
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 96
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                Text {
                    text: Qt.locale("tr_TR").dayName(pen.simdi.getDay(), Locale.LongFormat)
                    color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 34
                }
                Text {
                    text: pen.simdi.getDate() + " " + Qt.locale("tr_TR").standaloneMonthName(pen.simdi.getMonth(), Locale.LongFormat)
                    color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 34
                }
            }
        }
    }
}
