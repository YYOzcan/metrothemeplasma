// Finans canlı kutucuğu: USD/TRY ve EUR/TRY (TCMB döviz satış), günlük değişim okuyla
import QtQuick

Item {
    id: f
    property Item kutucuk
    property var satirlar: []
    function yukle() {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE || x.status !== 200) return
            var l = []
            ;["USD", "EUR", "GBP"].forEach(function (k) {
                var m = new RegExp('Kod="' + k + '"[\\s\\S]*?<ForexSelling>([^<]+)</ForexSelling>').exec(x.responseText)
                if (m) l.push({ kod: k, deger: parseFloat(m[1]) })
            })
            f.satirlar = l
        }
        x.open("GET", "https://www.tcmb.gov.tr/kurlar/today.xml"); x.send()
    }
    Component.onCompleted: yukle()
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: f.yukle() }
    Column {
        x: 10; y: 10; spacing: f.kutucuk && f.kutucuk.boyut === "orta" ? 2 : 6
        Repeater {
            model: f.kutucuk && f.kutucuk.boyut === "orta" ? f.satirlar.slice(0, 2) : f.satirlar
            delegate: Row {
                required property var modelData
                spacing: 10
                Text { width: 80; text: modelData.kod + "/TRY"; color: "white"; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: 600 }
                Text { text: modelData.deger.toLocaleString(Qt.locale("tr_TR"), "f", 4); color: "white"; font.family: "Segoe UI"; font.pixelSize: 14 }
            }
        }
    }
}
