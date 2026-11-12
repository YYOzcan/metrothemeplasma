// Windows 8.1 Hava Durumu (MSN Hava Durumu): yatay panorama. Solda şehir ve büyük sıcaklık, yanında
// günlük tahmin sütunları; sağa kaydırınca saatlik tahmin ve ayrıntılar. Zemin hava durumuna ve
// gün/geceye göre. Konum ve anlık durum wttr.in'den (kutucukla aynı), 7 günlük/saatlik tahmin open-meteo'dan.
import QtQuick

Item {
    id: h
    readonly property string baslik: "Hava Durumu"
    readonly property color zemin: "#1b6ec2"
    readonly property color cubukRengi: "#0f3e6e"
    readonly property var solKomutlar: [{ glif: "", metin: "Ana Sayfa", eylem: function () { kaydir.contentX = 0 } }]
    readonly property var sagKomutlar: [{ glif: "", metin: "Yenile", eylem: function () { h.yukle() } }]

    property var simdi: null
    property string sehir: ""
    property string ulke: ""
    property var gunluk: []       // {tarih, yuksek, dusuk, kod, yagis}
    property var saatlik: []      // {saat, sicaklik, kod, yagis}
    property bool yukleniyor: true
    property string hata: ""

    readonly property var gunAdlari: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    // WMO kodları -> Windows 8.1 Hava Durumu Türkçesi ve Segoe UI Symbol glifi
    function durum(k) { var d = durum_(k); return [d[0], d[1] + "\ufe0e"] }   // U+FE0E: renkli emoji değil, Segoe UI Symbol glifi
    function durum_(k) {
        if (k === 0) return ["Güneşli", "☀"]
        if (k === 1) return ["Çoğunlukla Güneşli", "⛅"]
        if (k === 2) return ["Parçalı Bulutlu", "⛅"]
        if (k === 3) return ["Bulutlu", "☁"]
        if (k === 45 || k === 48) return ["Sisli", "☁"]
        if (k >= 51 && k <= 57) return ["Çisenti", "☂"]
        if (k >= 61 && k <= 67) return [k >= 65 ? "Şiddetli Yağmur" : "Yağmurlu", "☔"]
        if (k >= 71 && k <= 77) return ["Kar Yağışlı", "❄"]
        if (k >= 80 && k <= 82) return ["Sağanak", "☔"]
        if (k === 85 || k === 86) return ["Kar Sağanağı", "❄"]
        if (k >= 95) return ["Gök Gürültülü", "⚡"]
        return ["", "☁"]
    }
    // pusula yönü: İngilizce kısaltma -> Türkçe (K, D, G, B)
    function yon(y) { return String(y || "").replace(/N/g, "K").replace(/E/g, "D").replace(/S/g, "G").replace(/W/g, "B") }
    // wttr.in (WWO) kodu -> WMO
    function wwo(k) {
        k = parseInt(k)
        var m = { 113: 0, 116: 2, 119: 3, 122: 3, 143: 45, 248: 45, 260: 48, 176: 61, 263: 51, 266: 51, 293: 61, 296: 61, 299: 63, 302: 63,
                  305: 65, 308: 65, 353: 80, 356: 81, 359: 82, 179: 71, 323: 71, 326: 71, 329: 73, 332: 73, 335: 75, 338: 75, 368: 85, 371: 86,
                  200: 95, 386: 95, 389: 95, 392: 95, 395: 95 }
        return m[k] !== undefined ? m[k] : 3
    }

    function al(url, fn) {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status === 200) { try { fn(JSON.parse(x.responseText)) } catch (e) { fn(null) } }
            else fn(null)
        }
        x.open("GET", url); x.send()
    }
    function yukle() {
        yukleniyor = true; hata = ""
        al("https://wttr.in/?format=j1&lang=tr", function (d) {
            if (!d) { yukleniyor = false; hata = "Hava durumu bilgisi alınamadı. İnternet bağlantınızı denetleyin."; return }
            var c = d.current_condition[0], a = d.nearest_area[0]
            sehir = a.areaName[0].value
            ulke = ({ "Turkey": "Türkiye", "Germany": "Almanya", "United Kingdom": "Birleşik Krallık", "United States of America": "ABD",
                      "Netherlands": "Hollanda", "France": "Fransa", "Azerbaijan": "Azerbaycan", "Cyprus": "Kıbrıs" })[a.country[0].value] || a.country[0].value
            simdi = { sicaklik: +c.temp_C, hissedilen: +c.FeelsLikeC, nem: +c.humidity, ruzgar: +c.windspeedKmph, yon: c.winddir16Point,
                      gorus: +c.visibility, basinc: +c.pressure, kod: wwo(c.weatherCode), uv: +c.uvIndex,
                      gunDogumu: d.weather[0].astronomy[0].sunrise, gunBatimi: d.weather[0].astronomy[0].sunset }
            // wttr'nin 3 günü: open-meteo gelmezse bunlar kalır
            gunluk = d.weather.map(function (w) {
                return { tarih: w.date, yuksek: +w.maxtempC, dusuk: +w.mintempC, kod: wwo(w.hourly[4].weatherCode),
                         yagis: Math.max.apply(null, w.hourly.map(function (s) { return +s.chanceofrain })) }
            })
            var enlem = a.latitude, boylam = a.longitude
            al("https://api.open-meteo.com/v1/forecast?latitude=" + enlem + "&longitude=" + boylam
               + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
               + "&hourly=temperature_2m,weather_code,precipitation_probability&forecast_days=7&timezone=auto", function (o) {
                if (o && o.daily) {
                    var g = []
                    for (var i = 0; i < o.daily.time.length; i++)
                        g.push({ tarih: o.daily.time[i], yuksek: Math.round(o.daily.temperature_2m_max[i]), dusuk: Math.round(o.daily.temperature_2m_min[i]),
                                 kod: o.daily.weather_code[i], yagis: o.daily.precipitation_probability_max[i] || 0 })
                    gunluk = g
                    var simdiSaat = new Date(), sl = []
                    for (var j = 0; j < o.hourly.time.length && sl.length < 24; j++) {
                        var t = new Date(o.hourly.time[j])
                        if (t.getTime() + 3600000 < simdiSaat.getTime()) continue
                        sl.push({ saat: t, sicaklik: Math.round(o.hourly.temperature_2m[j]), kod: o.hourly.weather_code[j], yagis: o.hourly.precipitation_probability[j] || 0 })
                    }
                    saatlik = sl
                }
                yukleniyor = false
            })
        })
    }
    Component.onCompleted: yukle()

    // gündüz mü (gün doğumu/batımı)
    function dakika(s) {   // "06:52 AM"
        var m = /(\d+):(\d+)\s*(AM|PM)/.exec(s || ""); if (!m) return -1
        return (+m[1] % 12 + (m[3] === "PM" ? 12 : 0)) * 60 + +m[2]
    }
    readonly property bool gunduz: {
        if (!simdi) return true
        var n = new Date(), d = n.getHours() * 60 + n.getMinutes()
        var a = dakika(simdi.gunDogumu), b = dakika(simdi.gunBatimi)
        return a < 0 || (d >= a && d < b)
    }
    readonly property var renkler: {
        var k = simdi ? simdi.kod : 0
        if (!gunduz) return ["#0b1a3a", "#1f3766"]
        if (k >= 95) return ["#2a2f3d", "#4f5668"]
        if (k >= 51) return ["#3b4d63", "#6f8299"]
        if (k >= 45 || k === 3) return ["#58687a", "#97a6b4"]
        return ["#1a73c9", "#6db3ef"]
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: h.renkler[0] }
            GradientStop { position: 1; color: h.renkler[1] }
        }
    }
    // büyük, soluk durum simgesi (Windows 8.1'deki fotoğraf zemini yerine)
    Text {
        x: parent.width * 0.55 - kaydir.contentX * 0.2; y: -60
        text: h.simdi ? h.durum(h.simdi.kod)[1] : ""
        font.family: "Segoe UI Symbol"; font.pixelSize: 700
        color: "white"; opacity: 0.07
    }

    Text {
        visible: h.hata !== ""
        anchors.centerIn: parent
        text: h.hata; color: "white"; font.family: "Segoe UI"; font.pixelSize: 24
    }
    Text {
        visible: h.yukleniyor && !h.simdi && h.hata === ""
        anchors.centerIn: parent
        text: "Yükleniyor..."; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 30
    }

    Flickable {
        id: kaydir
        anchors.fill: parent
        visible: h.simdi !== null
        contentWidth: panorama.width + 120; contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        MouseArea {
            width: kaydir.contentWidth; height: kaydir.height
            acceptedButtons: Qt.NoButton
            onWheel: w => kaydir.contentX = Math.max(0, Math.min(kaydir.contentWidth - kaydir.width, kaydir.contentX - w.angleDelta.y * 1.5))
        }
        Row {
            id: panorama
            x: 120; y: 0
            height: kaydir.height
            spacing: 120

            // ---- şimdi
            Item {
                width: 480; height: parent.height
                Column {
                    y: 180; spacing: 4
                    Text { text: h.sehir; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 42 }
                    Text { text: h.ulke; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.pixelSize: 18 }
                    Row {
                        spacing: 10
                        Text { text: h.simdi ? h.simdi.sicaklik + "°" : ""; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 150 }
                        Text { y: 30; text: "C"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 40 }
                    }
                    Text { text: h.simdi ? h.durum(h.simdi.kod)[0] : ""; color: "white"; font.family: "Segoe UI"; font.pixelSize: 28 }
                    Item { width: 1; height: 16 }
                    Repeater {
                        model: h.simdi ? [["Hissedilen", h.simdi.hissedilen + "°"], ["Rüzgar", h.simdi.ruzgar + " km/sa " + h.yon(h.simdi.yon)],
                                          ["Görüş Mesafesi", h.simdi.gorus + " km"], ["Nem", "%" + h.simdi.nem],
                                          ["Barometre", h.simdi.basinc + " mb"], ["UV dizini", String(h.simdi.uv)]] : []
                        delegate: Row {
                            required property var modelData
                            spacing: 8
                            Text { width: 150; text: modelData[0]; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.pixelSize: 16 }
                            Text { text: modelData[1]; color: "white"; font.family: "Segoe UI"; font.pixelSize: 16 }
                        }
                    }
                }
            }

            // ---- günlük tahmin
            Item {
                width: gunSatir.width; height: parent.height
                Text { y: 110; text: "Tahmin"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 32 }
                Row {
                    id: gunSatir
                    y: 180; spacing: 4
                    Repeater {
                        model: h.gunluk
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 160; height: 400
                            color: index === 0 ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
                            readonly property date t: new Date(modelData.tarih + "T12:00:00")
                            Column {
                                x: 14; y: 14; spacing: 6
                                Text { text: index === 0 ? "Bugün" : h.gunAdlari[t.getDay()]; color: "white"; font.family: "Segoe UI"; font.pixelSize: 22 }
                                Text { text: t.getDate() + ""; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.pixelSize: 16 }
                                Text { text: h.durum(modelData.kod)[1]; color: "white"; font.family: "Segoe UI Symbol"; font.pixelSize: 64; height: 100; verticalAlignment: Text.AlignVCenter }
                                Text { text: modelData.yuksek + "°/" + modelData.dusuk + "°"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 30 }
                                Text { width: 132; text: h.durum(modelData.kod)[0]; color: "white"; font.family: "Segoe UI"; font.pixelSize: 15; wrapMode: Text.WordWrap }
                                Text { text: "☔ %" + modelData.yagis; color: Qt.rgba(1, 1, 1, 0.8); font.family: "Segoe UI Symbol"; font.pixelSize: 15 }
                            }
                        }
                    }
                }
            }

            // ---- saatlik tahmin
            Item {
                width: 560; height: parent.height
                visible: h.saatlik.length > 0
                Text { y: 110; text: "Saatlik Tahmin"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 32 }
                ListView {
                    y: 180; width: parent.width; height: parent.height - 240
                    clip: true
                    model: h.saatlik
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: 560; height: 44
                        color: index % 2 ? "transparent" : Qt.rgba(0, 0, 0, 0.12)
                        Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: new Date(modelData.saat).toLocaleTimeString(Qt.locale("tr_TR"), "HH:mm"); color: "white"; font.family: "Segoe UI"; font.pixelSize: 18 }
                        Text { x: 100; anchors.verticalCenter: parent.verticalCenter; text: h.durum(modelData.kod)[1]; color: "white"; font.family: "Segoe UI Symbol"; font.pixelSize: 22 }
                        Text { x: 150; anchors.verticalCenter: parent.verticalCenter; text: modelData.sicaklik + "°"; color: "white"; font.family: "Segoe UI"; font.pixelSize: 18 }
                        Text { x: 220; anchors.verticalCenter: parent.verticalCenter; text: h.durum(modelData.kod)[0]; color: Qt.rgba(1, 1, 1, 0.85); font.family: "Segoe UI"; font.pixelSize: 16 }
                        Text { x: 460; anchors.verticalCenter: parent.verticalCenter; text: "%" + modelData.yagis; color: Qt.rgba(1, 1, 1, 0.85); font.family: "Segoe UI"; font.pixelSize: 16 }
                    }
                }
            }

            // ---- gün doğumu / batımı
            Item {
                width: 360; height: parent.height
                Text { y: 110; text: "Ayrıntılar"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 32 }
                Column {
                    y: 180; spacing: 18
                    Repeater {
                        model: h.simdi ? [["Gün doğumu", h.simdi.gunDogumu], ["Gün batımı", h.simdi.gunBatimi]] : []
                        delegate: Column {
                            required property var modelData
                            Text { text: modelData[0]; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.pixelSize: 18 }
                            Text {
                                text: { var d = h.dakika(modelData[1]); return d < 0 ? modelData[1] : (Math.floor(d / 60) < 10 ? "0" : "") + Math.floor(d / 60) + ":" + (d % 60 < 10 ? "0" : "") + d % 60 }
                                color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 48
                            }
                        }
                    }
                }
            }
        }
    }
}
