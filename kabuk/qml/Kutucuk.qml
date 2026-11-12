// Başlangıç ekranı kutucuğu: masaüstü uygulaması, Masaüstü, Bilgisayar ayarları ve canlı kutucuklar
import QtQuick

Item {
    id: k
    property var tema
    property string tur: "uygulama"     // uygulama, masaustu, ayarlar, takvim, hava, fotograflar, saat
    property string kimlik: ""
    property string boyut: "orta"        // kucuk, orta, genis, buyuk
    property bool canli: true
    property bool secili: false
    property bool surukleniyor: false
    property string duvarKagidi: ""
    property real giris: 1               // açılış animasyonu: doğrusal yerel ilerleme (0 -> 1)
    property real girisMesafe: 120       // sağdan kayma mesafesi (px)
    property real girisAci: 0            // oturum açılışında döner kapı açısı (derece)
    readonly property real girisE: tema.pvlDeger(giris)
    signal tiklandi()
    signal sagTiklandi(real x, real y)
    signal surukleBasla(real x, real y)
    signal surukle(real x, real y)
    signal surukleBitti()

    readonly property var bilgi: tur === "uygulama" ? Uygulamalar.bilgi(kimlik) : ({})
    readonly property string ad: {
        switch (tur) {
        case "masaustu": return "Masaüstü"
        case "ayarlar": return "Bilgisayar ayarları"
        case "takvim": return "Takvim"
        case "hava": return "Hava Durumu"
        case "fotograflar": return "Fotoğraflar"
        case "saat": return "Alarmlar"
        }
        return bilgi.ad || ""
    }
    readonly property color zemin: {
        switch (tur) {
        case "ayarlar": return tema.vurgu
        case "takvim": return "#5133ab"
        case "hava": return "#1b6ec2"
        case "fotograflar": return "#00a3a3"
        case "saat": return "#ac193d"
        case "masaustu": return "#2b5797"
        }
        if (bilgi.renk) return bilgi.renk
        return SimgeRengi.renk(bilgi.simge || "", Qt.darker(tema.vurgu, 1.0))
    }
    readonly property bool kucuk: boyut === "kucuk"
    // canlı kutucuğu olan Metro uygulamaları
    readonly property string canliTur: tur !== "uygulama" ? "" : (({ "metro-haberler.desktop": "haber", "metro-spor.desktop": "haber", "metro-finans.desktop": "finans" })[kimlik] || "")

    // açılışta kutucuklar sağdan kayarak gelir (saydamlık ilk üçte birde tamamlanır)
    opacity: Math.min(1, giris * 3)
    transform: [
        Translate { x: (1 - k.girisE) * k.girisMesafe },
        Rotation {
            origin.x: 0; origin.y: k.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: (1 - k.girisE) * k.girisAci
        },
        // basınca eğilme (PVL pointerDown/pointerUp: 167 ms)
        Rotation {
            id: egim
            origin.x: k.width / 2; origin.y: k.height / 2
            axis { x: 0; y: 0; z: 0 }
            angle: 0
            Behavior on angle { NumberAnimation { duration: 167; easing.type: Easing.Bezier; easing.bezierCurve: k.tema.pvl } }
        },
        Scale {
            id: olcek
            origin.x: k.width / 2; origin.y: k.height / 2
            xScale: 1; yScale: xScale
            Behavior on xScale { NumberAnimation { duration: 167; easing.type: Easing.Bezier; easing.bezierCurve: k.tema.pvl } }
        }
    ]

    Rectangle {
        id: yuz
        anchors.fill: parent
        color: k.zemin
        clip: true

        Loader {
            anchors.fill: parent
            sourceComponent: {
                switch (k.tur) {
                case "masaustu": return masaustuYuz
                case "ayarlar": return ayarlarYuz
                case "takvim": return k.canli ? takvimYuz : simgeYuz
                case "hava": return k.canli ? havaYuz : simgeYuz
                case "fotograflar": return k.canli ? fotoYuz : simgeYuz
                case "saat": return simgeYuz
                }
                // Metro uygulamalarının canlı kutucukları (küçük boyutta yalnız simge)
                if (k.canli && !k.kucuk && k.canliTur !== "") return ({ haber: haberYuz, finans: finansYuz })[k.canliTur]
                return uygulamaYuz
            }
        }

        // ad (küçük kutucukta yok)
        Text {
            visible: !k.kucuk && k.ad !== "" && k.tur !== "hava"
            anchors.left: parent.left; anchors.leftMargin: 8
            anchors.bottom: parent.bottom; anchors.bottomMargin: 5
            width: parent.width - 16
            elide: Text.ElideRight
            text: k.ad
            color: "white"
            font.family: "Segoe UI"; font.pixelSize: 14
            style: k.tur === "masaustu" || k.tur === "fotograflar" ? Text.Raised : Text.Normal
            styleColor: "#60000000"
        }
    }

    // fare üzerindeyken açık kenarlık; seçiliyken kalın kenarlık ve köşede onay işareti
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: k.secili ? 3 : 2
        border.color: k.secili ? "white" : Qt.rgba(1, 1, 1, 0.45)
        visible: k.secili || (ma.containsMouse && !ma.pressed)
    }
    Canvas {
        visible: k.secili
        anchors.top: parent.top; anchors.right: parent.right
        width: 32; height: 32
        onPaint: {
            var c = getContext("2d"); c.reset()
            c.fillStyle = "white"; c.beginPath(); c.moveTo(0, 0); c.lineTo(32, 0); c.lineTo(32, 32); c.closePath(); c.fill()
        }
        Text {
            x: 17; y: 1; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 12; color: k.zemin
        }
    }

    // ---------------- yüzler
    Component {
        id: uygulamaYuz
        Item {
            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: k.kucuk ? 0 : -8
                // Metro uygulaması simgesi kutucuk rengiyle aynı kare + glif: Windows 8.1 logosu boyutunda çizilir
                width: k.bilgi.renk ? (k.kucuk ? 60 : (k.boyut === "buyuk" ? 170 : 100)) : (k.kucuk ? 32 : (k.boyut === "buyuk" ? 96 : 48)); height: width
                sourceSize.width: width * 2; sourceSize.height: height * 2
                source: k.bilgi.simge ? (k.bilgi.simge.startsWith("/") ? "file://" + k.bilgi.simge : "image://simge/" + k.bilgi.simge) : ""
                smooth: true
            }
        }
    }
    Component {
        id: simgeYuz
        Item {
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: k.kucuk ? 0 : -8
                font.family: "Segoe UI Symbol"
                font.pixelSize: k.kucuk ? 30 : 52
                color: "white"
                text: ({ "takvim": "", "hava": "", "fotograflar": "", "saat": "" })[k.tur] || ""
            }
        }
    }
    Component {
        id: ayarlarYuz
        Item {
            Image {
                anchors.centerIn: parent
                width: k.kucuk ? 70 : 150; height: width
                source: tema.win + "ImmersiveControlPanel/images/" + (k.kucuk ? "TinyTile.scale-100.png" : "TileSmall.scale-100.png")
            }
        }
    }
    Component {
        id: masaustuYuz
        Item {
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: k.duvarKagidi !== "" ? k.duvarKagidi : tema.varlik + "masaustu-" + ({ "kucuk": "kucuk", "orta": "orta", "genis": "genis", "buyuk": "buyuk" })[k.boyut] + ".png"
                sourceSize.width: 620
                asynchronous: true
            }
        }
    }
    Component {
        id: takvimYuz
        Item {
            id: ty
            property date bugun: new Date()
            Timer { interval: 60000; running: true; repeat: true; onTriggered: ty.bugun = new Date() }
            Text {
                x: k.kucuk ? 0 : 12; y: k.kucuk ? 0 : 6
                width: k.kucuk ? parent.width : implicitWidth
                height: k.kucuk ? parent.height : implicitHeight
                horizontalAlignment: k.kucuk ? Text.AlignHCenter : Text.AlignLeft
                verticalAlignment: k.kucuk ? Text.AlignVCenter : Text.AlignTop
                text: ty.bugun.getDate()
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: k.kucuk ? 36 : 64
            }
            Text {
                visible: !k.kucuk
                x: 14; y: 84
                text: Qt.locale("tr_TR").dayName(ty.bugun.getDay(), Locale.LongFormat)
                color: "white"
                font.family: "Segoe UI"; font.pixelSize: 15
            }
        }
    }
    Component {
        id: havaYuz
        HavaKutucugu { kutucuk: k }
    }
    Component {
        id: haberYuz
        HaberKutucugu { kutucuk: k; kaynak: k.kimlik === "metro-spor.desktop" ? "https://www.ntvspor.net/rss/anasayfa" : "https://www.trthaber.com/manset_articles.rss" }
    }
    Component {
        id: finansYuz
        FinansKutucugu { kutucuk: k }
    }
    Component {
        id: fotoYuz
        FotoKutucugu { kutucuk: k }
    }

    // ---------------- etkileşim (bas: eğilme, sürükle: yeniden düzenle)
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property point bas
        property bool tasindi: false
        onPressed: mouse => {
            bas = Qt.point(mouse.x, mouse.y)
            tasindi = false
            if (mouse.button === Qt.LeftButton) {
                var dx = mouse.x / width - 0.5, dy = mouse.y / height - 0.5
                if (Math.abs(dx) < 0.22 && Math.abs(dy) < 0.22) {
                    olcek.xScale = 0.975
                } else {
                    egim.axis.x = -dy; egim.axis.y = dx; egim.axis.z = 0
                    egim.angle = 9 * Math.min(1, Math.max(Math.abs(dx), Math.abs(dy)) * 2)
                }
            }
        }
        onPositionChanged: mouse => {
            if (!pressed || mouse.buttons !== Qt.LeftButton) return
            if (!tasindi && (Math.abs(mouse.x - bas.x) > 8 || Math.abs(mouse.y - bas.y) > 8)) {
                tasindi = true
                egim.angle = 0; olcek.xScale = 1
                var p = mapToItem(null, mouse.x, mouse.y)
                k.surukleBasla(p.x, p.y)
            }
            if (tasindi) {
                var q = mapToItem(null, mouse.x, mouse.y)
                k.surukle(q.x, q.y)
            }
        }
        onReleased: mouse => {
            egim.angle = 0; olcek.xScale = 1
            if (tasindi) { k.surukleBitti(); tasindi = false; return }
            if (mouse.button === Qt.RightButton) {
                var p = mapToItem(null, mouse.x, mouse.y)
                k.sagTiklandi(p.x, p.y)
            } else if (containsMouse) {
                k.tiklandi()
            }
        }
        onCanceled: { egim.angle = 0; olcek.xScale = 1 }
    }
}
