// Hava Durumu canlı kutucuğu (wttr.in; konum IP'den). Sayfalar yukarı kayarak değişir.
import QtQuick

Item {
    id: h
    property Item kutucuk
    property var veri: null
    property int sayfa: 0
    clip: true

    function yukle() {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState === XMLHttpRequest.DONE && x.status === 200) {
                try { h.veri = JSON.parse(x.responseText) } catch (e) {}
            }
        }
        x.open("GET", "https://wttr.in/?format=j1&lang=tr")
        x.send()
    }
    Component.onCompleted: yukle()
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: h.yukle() }
    Timer {
        interval: 7000 + Math.random() * 3000; running: h.veri !== null && kutucuk.boyut !== "kucuk"; repeat: true
        onTriggered: h.sayfa = (h.sayfa + 1) % 2
    }

    readonly property var simdi: veri ? veri.current_condition[0] : null
    readonly property string sehir: veri ? veri.nearest_area[0].areaName[0].value : ""
    readonly property string durum: simdi ? (simdi.lang_tr ? simdi.lang_tr[0].value : simdi.weatherDesc[0].value) : ""
    function gun(i) { return veri ? veri.weather[i] : null }
    function gunAdi(t) { var d = new Date(t); return Qt.locale("tr_TR").dayName(d.getDay(), Locale.ShortFormat) }

    Column {
        id: icerik
        width: parent.width
        y: -h.sayfa * h.height
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
        // 1. sayfa: şimdi
        Item {
            width: h.width; height: h.height
            Text {
                x: 12; y: kutucuk.boyut === "kucuk" ? 8 : 4
                text: h.simdi ? h.simdi.temp_C + "°" : ""
                font.family: h.simdi ? "Segoe UI" : "Segoe UI Symbol"; font.weight: 300
                font.pixelSize: kutucuk.boyut === "kucuk" ? 30 : 56
                color: "white"
            }
            Column {
                visible: kutucuk.boyut !== "kucuk"
                x: kutucuk.boyut === "genis" ? 150 : 12
                y: kutucuk.boyut === "genis" ? 18 : 74
                spacing: 0
                Text { text: h.sehir; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                Text { text: h.durum; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14; width: h.width - parent.x - 8; elide: Text.ElideRight }
                Text {
                    visible: h.gun(0) !== null
                    text: h.gun(0) ? h.gun(0).maxtempC + "° / " + h.gun(0).mintempC + "°" : ""
                    color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
                }
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 8
                anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                visible: kutucuk.boyut !== "kucuk"
                text: "Hava Durumu"; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
            }
        }
        // 2. sayfa: üç günlük tahmin
        Item {
            width: h.width; height: h.height
            Column {
                x: 12; y: 10; spacing: 2
                Repeater {
                    model: 3
                    Row {
                        spacing: 10
                        required property int index
                        Text { width: 46; text: h.gun(index) ? (index === 0 ? "Bugün" : h.gunAdi(h.gun(index).date)) : ""; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 14 }
                        Text { text: h.gun(index) ? h.gun(index).maxtempC + "° / " + h.gun(index).mintempC + "°" : ""; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
                        Text {
                            visible: kutucuk.boyut === "genis"
                            text: { var g = h.gun(index); if (!g) return ""; var hh = g.hourly[4]; return hh.lang_tr ? hh.lang_tr[0].value : hh.weatherDesc[0].value }
                            color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
                        }
                    }
                }
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 8
                anchors.bottom: parent.bottom; anchors.bottomMargin: 5
                text: h.sehir; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14
            }
        }
    }
}
