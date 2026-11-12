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
    // WWO hava kodları -> Windows 8.1 Hava Durumu (MSN) Türkçesi; wttr.in'in çevirisi eksik
    readonly property var kodlar: ({
        113: "Güneşli", 116: "Parçalı Bulutlu", 119: "Bulutlu", 122: "Kapalı", 143: "Pus",
        176: "Yer Yer Yağmurlu", 179: "Yer Yer Kar Yağışlı", 182: "Yer Yer Karla Karışık Yağmur", 185: "Yer Yer Donan Çisenti",
        200: "Gök Gürültülü", 227: "Tipi", 230: "Kar Fırtınası", 248: "Sisli", 260: "Dondurucu Sis",
        263: "Yer Yer Çisenti", 266: "Çisenti", 281: "Donan Çisenti", 284: "Yoğun Donan Çisenti",
        293: "Yer Yer Hafif Yağmurlu", 296: "Hafif Yağmurlu", 299: "Zaman Zaman Yağmurlu", 302: "Yağmurlu",
        305: "Zaman Zaman Şiddetli Yağmur", 308: "Şiddetli Yağmur", 311: "Hafif Donan Yağmur", 314: "Donan Yağmur",
        317: "Hafif Karla Karışık Yağmur", 320: "Karla Karışık Yağmur", 323: "Yer Yer Hafif Kar", 326: "Hafif Kar Yağışlı",
        329: "Yer Yer Kar Yağışlı", 332: "Kar Yağışlı", 335: "Yer Yer Yoğun Kar", 338: "Yoğun Kar Yağışlı", 350: "Buz Taneleri",
        353: "Hafif Sağanak", 356: "Sağanak", 359: "Şiddetli Sağanak", 362: "Hafif Karla Karışık Sağanak",
        365: "Karla Karışık Sağanak", 368: "Hafif Kar Sağanağı", 371: "Kar Sağanağı", 374: "Hafif Buz Taneli Sağanak",
        377: "Buz Taneli Sağanak", 386: "Yer Yer Gök Gürültülü Yağmur", 389: "Gök Gürültülü Yağmur",
        392: "Yer Yer Gök Gürültülü Kar", 395: "Gök Gürültülü Kar"
    })
    function aciklama(o) {
        if (!o) return ""
        var k = kodlar[parseInt(o.weatherCode)]
        if (k) {
            // gece açık hava
            if (k === "Güneşli" && o.isdaytime === "no") return "Açık"
            return k
        }
        return o.lang_tr ? o.lang_tr[0].value : o.weatherDesc[0].value
    }
    readonly property string durum: aciklama(simdi)
    function gun(i) { return veri ? veri.weather[i] : null }
    function gunAdi(t) { var d = new Date(t); return Qt.locale("tr_TR").dayName(d.getDay(), Locale.ShortFormat) }

    Column {
        id: icerik
        width: parent.width
        y: -h.sayfa * h.height
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.Bezier; easing.bezierCurve: h.kutucuk.tema.pvl } }
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
                            text: { var g = h.gun(index); if (!g) return ""; return h.aciklama(g.hourly[4]) }
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
