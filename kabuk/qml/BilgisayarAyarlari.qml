// Windows 8.1 "Bilgisayar ayarları": solda Başlangıç renginde gezinti bölmesi, sağda beyaz içerik.
// Metro'ya ait ayarlar (kilit ekranı resmi, köşeler, Başlangıç, pencere rengi) burada yapılır;
// diğerleri ilgili KDE ayar modülünü açar.
import QtQuick
import QtQuick.Window
import QtQuick.Dialogs

Window {
    id: pen
    property var tema
    property var ana
    title: "Bilgisayar ayarları"
    color: "white"
    visible: false
    width: Screen.width; height: Screen.height
    property string kategori: ""        // "" = giriş sayfası
    property string sayfa: ""

    function ac(s) {
        kategori = ""
        sayfa = ""
        if (s) {
            for (var i = 0; i < kategoriler.length; i++)
                for (var j = 0; j < kategoriler[i].sayfalar.length; j++)
                    if (kategoriler[i].sayfalar[j][1] === s) { kategori = kategoriler[i].kimlik; sayfa = s }
        }
        showFullScreen()
        raise()
        requestActivate()
        sayfaGirisi.restart()
    }
    // Windows 8 sayfa girişi (enterPage): içerik sağdan kayarak ve belirerek gelir; gezinti listesi de
    property real girisT: 1
    NumberAnimation { id: sayfaGirisi; target: pen; property: "girisT"; from: 0; to: 1; duration: 700 }
    readonly property real girisKayma: (1 - tema.pvlDeger(Math.min(1, girisT / 0.8))) * 80
    onSayfaChanged: sayfaGirisi.restart()
    onKategoriChanged: sayfaGirisi.restart()

    // [ad, kimlik, kcm (Metro sayfası değilse)]
    readonly property var kategoriler: [
        { ad: "Bilgisayar ve aygıtlar", kimlik: "aygitlar", sayfalar: [
            ["Kilit ekranı", "kilit"], ["Ekran", "ekran", "kcm_kscreen"], ["Bluetooth", "bluetooth", "kcm_bluetooth"],
            ["Aygıtlar", "aygitlist", "kcm_printer_manager"], ["Fare ve dokunmatik yüzey", "fare", "kcm_mouse"],
            ["Yazma", "yazma", "kcm_keyboard"], ["Köşeler ve kenarlar", "koseler"], ["Güç ve uyku", "guc", "kcm_powerdevilprofilesconfig"],
            ["Otomatik Kullan", "otomatik"], ["Bilgisayar bilgileri", "bilgi", "kcm_about-distro"] ] },
        { ad: "Hesaplar", kimlik: "hesaplar", sayfalar: [["Hesabınız", "hesap"], ["Oturum açma seçenekleri", "oturumacma", "kcm_users"], ["Diğer hesaplar", "digerhesap", "kcm_users"]] },
        { ad: "Kişiselleştir", kimlik: "kisisel", sayfalar: [["Başlangıç", "baslangic"], ["Renk ve görünüm", "renk"], ["Gezinti", "gezinti"]] },
        { ad: "Arama ve uygulamalar", kimlik: "arama", sayfalar: [["Ara", "ara", "kcm_plasmasearch"], ["Varsayılanlar", "varsayilan", "kcm_componentchooser"], ["Bildirimler", "bildirim", "kcm_notifications"]] },
        { ad: "Gizlilik", kimlik: "gizlilik", sayfalar: [["Genel", "gizlilikgenel", "kcm_recentFiles"]] },
        { ad: "Ağ", kimlik: "ag", sayfalar: [["Bağlantılar", "baglanti", "kcm_networkmanagement"], ["Proxy", "proxy", "kcm_proxy"]] },
        { ad: "Saat ve dil", kimlik: "saat", sayfalar: [["Tarih ve saat", "tarih", "kcm_clock"], ["Bölge ve dil", "bolge", "kcm_regionandlang"]] },
        { ad: "Erişim Kolaylığı", kimlik: "erisim", sayfalar: [["Erişim kolaylığı", "erisimgenel", "kcm_access"]] },
        { ad: "Güncelleştir ve kurtar", kimlik: "guncel", sayfalar: [["Windows Update", "update"]] }
    ]
    function kategoriNesnesi() {
        for (var i = 0; i < kategoriler.length; i++) if (kategoriler[i].kimlik === kategori) return kategoriler[i]
        return null
    }

    // ---------------------------------------------------------------- sol gezinti bölmesi
    Rectangle {
        id: sol
        width: Math.max(380, pen.width * 0.27); height: pen.height
        color: pen.tema.arkaPlan
        Row {
            x: 40; y: 46
            spacing: 14
            DaireDugme {
                visible: pen.kategori !== ""
                anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: 3
                boyut: 34; glif: ""; glifOlcek: 0.5
                onTiklandi: { if (pen.sayfa !== "" && pen.kategori !== "") { pen.kategori = ""; pen.sayfa = "" } else pen.kategori = "" }
            }
            Text {
                text: pen.kategori === "" ? "Bilgisayar ayarları" : pen.kategoriNesnesi().ad
                color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: pen.kategori === "" ? 42 : 34
                width: sol.width - 120; elide: Text.ElideRight
            }
        }
        Column {
            x: 40; y: 150
            width: sol.width - 80
            opacity: Math.min(1, pen.girisT * 4)
            transform: Translate { x: pen.girisKayma * 0.6 }
            spacing: 4
            Repeater {
                model: pen.kategori === "" ? pen.kategoriler : pen.kategoriNesnesi().sayfalar
                delegate: Item {
                    id: og
                    required property var modelData
                    readonly property bool kat: pen.kategori === ""
                    readonly property string kimlik: kat ? modelData.kimlik : modelData[1]
                    readonly property bool secili: !kat && pen.sayfa === kimlik
                    width: parent.width; height: 44
                    Rectangle { anchors.fill: parent; anchors.leftMargin: -12; color: og.secili ? Qt.lighter(pen.tema.arkaPlan, 1.6) : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.12 : 0) }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: og.kat ? og.modelData.ad : og.modelData[0]
                        color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
                    }
                    MouseArea {
                        id: ma; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (og.kat) { pen.kategori = og.kimlik; var s0 = og.modelData.sayfalar[0]; if (!s0[2]) pen.sayfa = s0[1]; else pen.sayfa = "" }
                            else if (og.modelData[2]) { Sistem.ayarAc(og.modelData[2]) }
                            else pen.sayfa = og.kimlik
                        }
                    }
                }
            }
        }
        Text {
            visible: pen.kategori === ""
            x: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 30
            text: "Denetim Masası"
            color: dm.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.85)
            font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; onClicked: pen.ana.ayarEylem("denetim") }
        }
    }

    // ---------------------------------------------------------------- sağ içerik
    Flickable {
        x: sol.width + 60; y: 46
        opacity: Math.min(1, pen.girisT * 4)
        transform: Translate { x: pen.girisKayma }
        width: pen.width - x - 60; height: pen.height - y
        contentHeight: icerik.item ? icerik.item.height + 60 : 0
        clip: true
        Loader {
            id: icerik
            width: Math.min(parent.width, 720)
            sourceComponent: {
                if (pen.kategori === "" && pen.sayfa === "") return girisSayfasi
                return ({ kilit: kilitSayfasi, koseler: koselerSayfasi, hesap: hesapSayfasi, baslangic: baslangicSayfasi,
                          renk: renkSayfasi, gezinti: gezintiSayfasi, update: guncelSayfasi, otomatik: otomatikSayfasi })[pen.sayfa] || bosSayfa
            }
        }
    }
    // 8.1 Update: Mağaza uygulamasının başlık çubuğu — fare üst kenara gelince kayarak iner
    // (solda simge ve uygulama adı, sağda küçült ve kapat); fare aşağı inince geri çekilir
    MouseArea {
        id: ustKenar
        width: parent.width; height: 4
        hoverEnabled: true
        onEntered: baslikCubugu.goster = true
    }
    Rectangle {
        id: baslikCubugu
        property bool goster: false
        width: parent.width; height: 32
        y: goster ? 0 : -height
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl } }
        color: "#f0f0f0"
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#d9d9d9" }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onExited: if (mouseY > height - 2) baslikCubugu.goster = false
        }
        Rectangle {
            id: baslikSimge
            x: 8; anchors.verticalCenter: parent.verticalCenter
            width: 20; height: 20; color: pen.tema.vurgu
            Image { anchors.fill: parent; source: pen.tema.win + "ImmersiveControlPanel/images/logo.scale-100.png"; sourceSize.width: 40 }
        }
        Text {
            anchors.left: baslikSimge.right; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            text: "Bilgisayar ayarları"; color: "black"; font.family: "Segoe UI"; font.pixelSize: 12
        }
        Row {
            anchors.right: parent.right; height: parent.height - 1
            Rectangle {
                width: 46; height: parent.height
                color: kucultMa.pressed ? "#cccccc" : (kucultMa.containsMouse ? "#e5e5e5" : "transparent")
                Text { anchors.centerIn: parent; text: "─"; font.pixelSize: 10; color: "#333" }
                MouseArea { id: kucultMa; anchors.fill: parent; hoverEnabled: true; onClicked: { baslikCubugu.goster = false; pen.showMinimized() } }
            }
            Rectangle {
                width: 46; height: parent.height
                color: kapatMa.pressed ? "#f1707a" : (kapatMa.containsMouse ? "#e81123" : "transparent")
                Text { anchors.centerIn: parent; text: "✕"; font.family: "Segoe UI Symbol"; font.pixelSize: 12; color: kapatMa.containsMouse ? "white" : "#333" }
                MouseArea { id: kapatMa; anchors.fill: parent; hoverEnabled: true; onClicked: { baslikCubugu.goster = false; pen.close() } }
            }
        }
    }

    component Baslik: Text { color: "black"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 34; bottomPadding: 18 }
    component Bolum: Text { color: "black"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15; topPadding: 18; bottomPadding: 6 }
    component Aciklama: Text { color: "#333"; font.family: "Segoe UI"; font.pixelSize: 15; wrapMode: Text.WordWrap }
    component Baglanti: Text {
        signal tiklandi()
        color: lm.containsMouse ? Qt.lighter(pen.tema.vurgu, 1.4) : pen.tema.vurgu
        font.family: "Segoe UI"; font.pixelSize: 15
        MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; onClicked: parent.tiklandi() }
    }
    component Dugme: Rectangle {
        id: dg
        property string metin
        signal tiklandi()
        width: Math.max(110, dmetin.implicitWidth + 30); height: 34
        color: dgm.pressed ? "black" : (dgm.containsMouse ? "#e5e5e5" : "#cccccc")
        border.color: dgm.containsMouse ? "#999" : "#cccccc"
        Text { id: dmetin; anchors.centerIn: parent; text: dg.metin; color: dgm.pressed ? "white" : "black"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
        MouseArea { id: dgm; anchors.fill: parent; hoverEnabled: true; onClicked: dg.tiklandi() }
    }

    // ---- giriş: Windows 8.1'deki gibi kilit ekranı ve hesap resmi önizlemesi
    Component {
        id: girisSayfasi
        Column {
            spacing: 14
            Item { width: 1; height: 100 }
            Row {
                spacing: 30
                Rectangle {
                    width: 420; height: 236; color: "#ddd"; clip: true
                    Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 840; source: pen.kilitResmi() }
                    Text { x: 14; y: 150; text: new Date(new Date()).toLocaleTimeString(Qt.locale("tr_TR"), "HH:mm"); color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 56 }
                    MouseArea { anchors.fill: parent; onClicked: { pen.kategori = "aygitlar"; pen.sayfa = "kilit" } }
                }
                Rectangle {
                    width: 236; height: 236; color: "#ddd"
                    Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 472; source: Sistem.avatar !== "" ? Sistem.avatar : pen.tema.varlik + "user-200.png" }
                    MouseArea { anchors.fill: parent; onClicked: { pen.kategori = "hesaplar"; pen.sayfa = "hesap" } }
                }
            }
            Baglanti { text: "Kilit ekranını, hesap resmini ve renkleri değiştirin"; onTiklandi: { pen.kategori = "kisisel"; pen.sayfa = "baslangic" } }
        }
    }

    // ---- kilit ekranı
    function kilitResmi() {
        var r = kilitAyar.resim
        return r !== "" ? r : pen.tema.win + "Web/Screen/img100.jpg"
    }
    property var kilitAyar: QtObject {
        property string resim: ""
        Component.onCompleted: {
            var m = Dosya.oku(Dosya.yapilandirma + "/ayarlar.ini").match(/\[Kilit\][^\[]*?resim=([^\n]*)/)
            if (m) resim = m[1].replace(/^"|"$/g, "")
        }
    }
    function kilitResmiYaz(url) {
        kilitAyar.resim = url
        var yol = Dosya.yapilandirma + "/ayarlar.ini"
        var s = Dosya.oku(yol)
        if (/\[Kilit\]/.test(s)) {
            if (/\[Kilit\][^\[]*?resim=/.test(s)) s = s.replace(/(\[Kilit\][^\[]*?resim=)[^\n]*/, "$1" + url)
            else s = s.replace(/\[Kilit\]\n/, "[Kilit]\nresim=" + url + "\n")
        } else s = s.replace(/\s*$/, "\n\n[Kilit]\nresim=" + url + "\n")
        Dosya.yaz(yol, s)
    }
    Component {
        id: kilitSayfasi
        Column {
            spacing: 10
            Baslik { text: "Kilit ekranı" }
            Rectangle {
                width: 560; height: 315; clip: true; color: "#ddd"
                Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 1120; source: pen.kilitResmi() }
                Column {
                    x: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 26
                    Text { text: new Date(new Date()).toLocaleTimeString(Qt.locale("tr_TR"), "HH:mm"); color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 64 }
                    Text { text: new Date().toLocaleDateString(Qt.locale("tr_TR"), "d MMMM dddd"); color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 22 }
                }
            }
            Row {
                spacing: 8
                Repeater {
                    model: ["img100.jpg", "img101.png", "img102.jpg", "img103.png", "img104.jpg", "img105.jpg"]
                    delegate: Rectangle {
                        required property string modelData
                        width: 86; height: 86; color: "#ddd"
                        border.width: pen.kilitResmi().indexOf(modelData) >= 0 ? 3 : 0; border.color: pen.tema.vurgu
                        Image { anchors.fill: parent; anchors.margins: parent.border.width; fillMode: Image.PreserveAspectCrop; sourceSize.width: 172; source: pen.tema.win + "Web/Screen/" + modelData }
                        MouseArea { anchors.fill: parent; onClicked: pen.kilitResmiYaz(modelData === "img100.jpg" ? "" : pen.tema.win + "Web/Screen/" + modelData) }
                    }
                }
            }
            Dugme { metin: "Gözat"; onTiklandi: dosyaSec.open() }
            FileDialog {
                id: dosyaSec
                title: "Resim seçin"
                nameFilters: ["Resimler (*.jpg *.jpeg *.png *.webp *.bmp)"]
                onAccepted: pen.kilitResmiYaz(String(selectedFile))
            }
            Bolum { text: "Ekran kapatıldığında" }
            Baglanti { text: "Güç ve uyku ayarları"; onTiklandi: Sistem.ayarAc("kcm_powerdevilprofilesconfig") }
            Baglanti { text: "Ekran kilidi zamanlaması"; onTiklandi: Sistem.ayarAc("kcm_screenlocker") }
        }
    }

    // ---- köşeler ve kenarlar
    Component {
        id: koselerSayfasi
        Column {
            spacing: 6
            Baslik { text: "Köşeler ve kenarlar" }
            Bolum { text: "Uygulama geçişi" }
            Aciklama { width: 640; text: "Son kullandığım uygulamalar arasında sol üst köşeye dokunarak geçiş yapmama izin ver" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: pen.tema.baslangic.solUstGecis; onDegisti: d => pen.tema.baslangic.solUstGecis = d }
            Bolum { text: "Sağ köşeler" }
            Aciklama { width: 640; text: "Sağ üst ve sağ alt köşeye geldiğimde tılsımları göster" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: pen.tema.baslangic.koseIpucu; onDegisti: d => pen.tema.baslangic.koseIpucu = d }
        }
    }

    // ---- hesap
    Component {
        id: hesapSayfasi
        Column {
            spacing: 10
            Baslik { text: "Hesabınız" }
            Row {
                spacing: 20
                Rectangle {
                    width: 190; height: 190; color: "#ddd"
                    Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize.width: 380; source: Sistem.avatar !== "" ? Sistem.avatar : pen.tema.varlik + "user-200.png" }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text { text: Sistem.adSoyad; color: "black"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 28 }
                    Aciklama { text: Sistem.kullanici + " · Yerel hesap" }
                }
            }
            Bolum { text: "Hesap resmi oluşturun" }
            Dugme { metin: "Gözat"; onTiklandi: Sistem.ayarAc("kcm_users") }
        }
    }

    // ---- Başlangıç (renkler ve desen: Kişiselleştir bölmesindekiyle aynı)
    Component {
        id: baslangicSayfasi
        Column {
            spacing: 8
            Baslik { text: "Başlangıç" }
            Rectangle {
                width: 560; height: 315; clip: true
                DesenArkaPlan { anchors.fill: parent; tema: pen.tema; scale: 1; kaydirma: 0 }
                Text { x: 24; y: 18; text: "Başlangıç"; color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 30 }
            }
            Bolum { text: "Arka plan" }
            Grid {
                columns: 10; spacing: 6
                Repeater {
                    model: [0, 20200, 20300, 20400, 20500, 20600, 20700, 20800, 21000, 21100, 21200, 21300, 21400, 21500, 21600, 21700, 21900, 22000, 22100]
                    delegate: Rectangle {
                        required property int modelData
                        width: 56; height: 56; color: pen.tema.arkaPlan
                        border.width: pen.tema.renk.desen === modelData ? 3 : 0; border.color: "black"
                        Image { anchors.fill: parent; anchors.margins: parent.border.width; visible: modelData > 0; fillMode: Image.PreserveAspectCrop; source: modelData > 0 ? pen.tema.varlik + "desen-kucuk/" + modelData + ".png" : "" }
                        MouseArea { anchors.fill: parent; onClicked: { pen.tema.renk.masaustuArkaPlani = false; pen.tema.renk.desen = modelData } }
                    }
                }
            }
            Bolum { text: "Arka plan rengi" }
            Grid {
                columns: 13; spacing: 4
                Repeater {
                    model: pen.tema.zeminRenkleri
                    delegate: Rectangle {
                        required property string modelData
                        width: 32; height: 32; color: modelData
                        border.width: pen.tema.renk.arkaPlan.toLowerCase() === modelData ? 3 : 0; border.color: "black"
                        MouseArea { anchors.fill: parent; onClicked: pen.tema.renk.arkaPlan = modelData }
                    }
                }
            }
            Bolum { text: "Vurgu rengi" }
            Grid {
                columns: 13; spacing: 4
                Repeater {
                    model: pen.tema.vurguRenkleri
                    delegate: Rectangle {
                        required property string modelData
                        width: 32; height: 32; color: modelData
                        border.width: pen.tema.renk.vurgu.toLowerCase() === modelData ? 3 : 0; border.color: "black"
                        MouseArea { anchors.fill: parent; onClicked: pen.tema.renk.vurgu = modelData }
                    }
                }
            }
            Bolum { text: "Masaüstü arka planını Başlangıç'ta göster" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: pen.tema.renk.masaustuArkaPlani; onDegisti: d => pen.tema.renk.masaustuArkaPlani = d }
        }
    }

    // ---- Renk ve görünüm (pencere çerçevesi ve görev çubuğu rengi)
    Component {
        id: renkSayfasi
        Column {
            id: rs
            spacing: 8
            property string secili: "otomatik"
            property int yogunluk: 55
            Component.onCompleted: {
                var s = Dosya.oku(Dosya.yapilandirma + "/ayarlar.ini")
                var m = s.match(/\[Pencere\][^\[]*?renk=([^\n]*)/); if (m) secili = m[1].replace(/"/g, "")
                var y = s.match(/\[Pencere\][^\[]*?yogunluk=([^\n]*)/); if (y) yogunluk = parseInt(y[1])
            }
            function uygula() { Sistem.calistir("metro-renk renk " + secili + " " + yogunluk) }
            Baslik { text: "Renk ve görünüm" }
            Aciklama { width: 640; text: "Pencere kenarlıklarınızın ve görev çubuğunuzun rengini değiştirin." }
            Grid {
                columns: 8; spacing: 8
                Repeater {
                    model: ["otomatik", "#6b6b6b", "#2f4f8f", "#0f6fbf", "#2aa1d8", "#109a9a", "#2e8b3f", "#86b72f",
                            "#d6a700", "#e3780c", "#d03d16", "#c41f3a", "#c4207e", "#8e3db9", "#5a42b5", "#ffd8e5"]
                    delegate: Rectangle {
                        required property string modelData
                        width: 64; height: 64
                        color: modelData === "otomatik" ? "#cccccc" : modelData
                        border.width: rs.secili === modelData ? 3 : 1; border.color: rs.secili === modelData ? "black" : "#aaa"
                        Text { visible: modelData === "otomatik"; anchors.centerIn: parent; text: "Otomatik"; font.family: "Segoe UI"; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; onClicked: { rs.secili = modelData; rs.uygula() } }
                    }
                }
            }
            Bolum { text: "Renk yoğunluğu" }
            Rectangle {
                id: ray
                width: 400; height: 8; color: "#ccc"
                Rectangle { width: parent.width * rs.yogunluk / 100; height: parent.height; color: pen.tema.vurgu }
                Rectangle { x: parent.width * rs.yogunluk / 100 - 6; y: -8; width: 12; height: 24; color: "black" }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -10
                    function ayar(mx) { rs.yogunluk = Math.round(Math.max(0, Math.min(1, (mx - 10) / ray.width)) * 100) }
                    onPressed: mouse => ayar(mouse.x)
                    onPositionChanged: mouse => ayar(mouse.x)
                    onReleased: rs.uygula()
                }
            }
            Item { width: 1; height: 10 }
            Baglanti { text: "Gelişmiş görünüm ayarları"; onTiklandi: Sistem.ayarAc("kcm_colors") }
        }
    }

    // ---- Gezinti (Görev Çubuğu ve Gezinti Özellikleri > Gezinti)
    Component {
        id: gezintiSayfasi
        Column {
            spacing: 6
            Baslik { text: "Gezinti" }
            Bolum { text: "Başlangıç ekranı" }
            Aciklama { width: 640; text: "Oturum açtığımda Başlangıç yerine masaüstüne git" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: !pen.tema.baslangic.giristeBaslangic; onDegisti: d => pen.tema.baslangic.giristeBaslangic = !d }
            Aciklama { width: 640; text: "Başlangıç'a gittiğimde Uygulamalar görünümünü otomatik olarak göster" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: pen.tema.baslangic.uygulamalarOtomatik; onDegisti: d => pen.tema.baslangic.uygulamalarOtomatik = d }
            Aciklama { width: 640; text: "Uygulamalar görünümü kategoriye göre sıralandığında önce masaüstü uygulamalarını listele" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: pen.tema.baslangic.masaustuUygulamalariOnce; onDegisti: d => pen.tema.baslangic.masaustuUygulamalariOnce = d }
        }
    }

    // ---- Otomatik Kullan (Bilgisayar ve aygıtlar > Otomatik Kullan); metinler shell32/autoplay.dll.mui
    Component {
        id: otomatikSayfasi
        Column {
            spacing: 6
            readonly property var secenekler: {
                var l = [["sor", "Her seferinde bana sor"], ["klasor", "Dosyaları görüntülemek için klasörü aç (Dosya Gezgini)"]]
                if (Uygulamalar.var("metro-fotograflar.desktop")) l.push(["fotograf", "Fotoğrafları ve videoları içeri aktar (Fotoğraflar)"])
                if (OtomatikKullan.programVar("deja-dup")) l.push(["yedek", "Bu sürücüyü yedekleme için yapılandır (Dosya Geçmişi)"])
                l.push(["hicbir", "Eylem yok"])
                return l
            }
            Baslik { text: "Otomatik Kullan" }
            Aciklama { width: 640; text: "Tüm medya ve aygıtlar için Otomatik Kullan'ı kullan" }
            MetroAnahtar { renk: "black"; vurgu: pen.tema.vurgu; acik: pen.tema.otomatik.etkin; onDegisti: d => pen.tema.otomatik.etkin = d }
            Bolum { text: "Otomatik Kullan varsayılanlarını seçin" }
            Aciklama { text: "Çıkarılabilir sürücü" }
            Secim {
                etkin: pen.tema.otomatik.etkin
                secenekler: parent.secenekler; deger: pen.tema.otomatik.cikarilabilir
                onSecildi: d => pen.tema.otomatik.cikarilabilir = d
            }
            Item { width: 1; height: 8 }
            Aciklama { text: "Bellek kartı" }
            Secim {
                etkin: pen.tema.otomatik.etkin
                secenekler: parent.secenekler; deger: pen.tema.otomatik.bellekKarti
                onSecildi: d => pen.tema.otomatik.bellekKarti = d
            }
        }
    }
    // Windows 8.1 açılır liste (Modern): beyaz kutu, sağda ok; açılınca seçenekler kutunun üstünde,
    // seçili olan vurgu renginde
    component Secim: Item {
        id: sc
        property var secenekler: []
        property string deger: ""
        property bool etkin: true
        signal secildi(string d)
        width: 440; height: 32
        z: liste.visible ? 10 : 0
        opacity: etkin ? 1 : 0.45
        function metin() { for (var i = 0; i < secenekler.length; i++) if (secenekler[i][0] === deger) return secenekler[i][1]; return "" }
        Rectangle {
            anchors.fill: parent
            color: sm.containsMouse ? "#f4f4f4" : "white"
            border.color: sm.containsMouse ? "#8a8a8a" : "#bababa"; border.width: 2
            Text { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 44; elide: Text.ElideRight
                   text: sc.metin(); color: "black"; font.family: "Segoe UI"; font.pixelSize: 15 }
            Canvas {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                width: 12; height: 7
                onPaint: { var c = getContext("2d"); c.reset(); c.strokeStyle = "#333"; c.lineWidth = 1.5
                           c.beginPath(); c.moveTo(0.5, 0.5); c.lineTo(6, 6); c.lineTo(11.5, 0.5); c.stroke() }
            }
            MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; enabled: sc.etkin; onClicked: liste.visible = !liste.visible }
        }
        Rectangle {
            id: liste
            visible: false
            y: parent.height
            width: parent.width; height: sutun.height + 4
            color: "white"; border.color: "#bababa"; border.width: 2
            Column {
                id: sutun
                x: 2; y: 2; width: parent.width - 4
                Repeater {
                    model: sc.secenekler
                    delegate: Rectangle {
                        required property var modelData
                        width: sutun.width; height: 34
                        color: modelData[0] === sc.deger ? pen.tema.vurgu : (lm.containsMouse ? "#e5e5e5" : "white")
                        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 20; elide: Text.ElideRight
                               text: modelData[1]; color: modelData[0] === sc.deger ? "white" : "black"; font.family: "Segoe UI"; font.pixelSize: 15 }
                        MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; onClicked: { liste.visible = false; sc.secildi(modelData[0]) } }
                    }
                }
            }
        }
    }

    // ---- güncelleştirme
    Component {
        id: guncelSayfasi
        Column {
            spacing: 10
            Baslik { text: "Windows Update" }
            Aciklama { width: 640; text: "Güncelleştirmeler sistem paket yöneticisiyle yüklenir." }
            Dugme { metin: "Şimdi denetle"; onTiklandi: Sistem.calistir(pen.ana.ilkProgram(["plasma-discover --mode update", "octopi", "pamac-manager", "konsole -e sudo pacman -Syu"])) }
        }
    }
    Component { id: bosSayfa; Item { width: 1; height: 1 } }
}
