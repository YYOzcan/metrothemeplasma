// Windows 8.1 Başlangıç ekranı ve Uygulamalar görünümü (tam ekran, layer-shell üst katman)
import QtQuick
import QtQuick.Window

Window {
    id: pen
    property var tema
    property var ana
    property bool acik: false
    property int sayfa: 0                 // 0 Başlangıç, 1 Uygulamalar
    property bool ozellestir: false
    property string duvarKagidi: ""
    title: "Başlangıç"
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint

    // ölçüler (100 % ölçek, Windows 8.1)
    readonly property int hucre: 70
    readonly property int aralik: 10
    readonly property int adim: hucre + aralik
    readonly property int solBosluk: 120
    readonly property int ustBosluk: 180
    readonly property int grupAraligi: 56
    readonly property int satir: Math.max(4, Math.floor((height - ustBosluk - 60) / adim) & ~1)

    width: Screen.width
    height: Screen.height
    Component.onCompleted: {
        KatmanYardimci.ayarla(pen, 3, 15, 1, -1, "metro-baslangic")
        duzenYukle()
    }

    // ------------------------------------------------------------------ aç / kapat
    function ac(uygulamalar) {
        if (acik && !kapanis.running) {
            if (uygulamalar) sayfa = 1
            return
        }
        kapanis.stop()
        duvarKagidiOku()
        sayfa = (uygulamalar || tema.baslangic.uygulamalarOtomatik) ? 1 : 0
        uygulamalarGorunumu.sifirla()
        acik = true
        icerik.opacity = 0
        icerik.scale = 1
        visible = true
        requestActivate()
        acilis.restart()
        icerik.forceActiveFocus()
    }
    function kapat() {
        if (!acik) return
        acik = false
        menu.kapat()
        secimiTemizle()
        ozellestir = false
        acilis.stop()
        kapanis.restart()
    }
    function degistir() { if (acik) kapat(); else ac(false) }

    SequentialAnimation {
        id: acilis
        ParallelAnimation {
            NumberAnimation { target: icerik; property: "opacity"; from: 0; to: 1; duration: 160 }
            NumberAnimation { target: pen; property: "girisIlerleme"; from: 0; to: 1; duration: 700; easing.type: Easing.Linear }
        }
    }
    SequentialAnimation {
        id: kapanis
        ParallelAnimation {
            NumberAnimation { target: icerik; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InQuad }
            NumberAnimation { target: icerik; property: "scale"; to: 0.94; duration: 180; easing.type: Easing.InQuad }
        }
        ScriptAction { script: { pen.visible = false; icerik.scale = 1 } }
    }
    // kutucuklar sütun sütun, soldan sağa gecikmeyle gelir
    property real girisIlerleme: 1
    function girisDegeri(x) {
        var gecikme = Math.min(0.45, (x / 1600) * 0.45)
        var t = Math.max(0, Math.min(1, (girisIlerleme - gecikme) / 0.55))
        return 1 - Math.pow(1 - t, 4)
    }

    // ------------------------------------------------------------------ masaüstü duvar kağıdı (Masaüstü kutucuğu ve "masaüstü arka planını göster")
    function duvarKagidiOku() {
        var dosyalar = ["plasma-io.github.yyozcan.metroshell-appletsrc"]
        for (var i = 0; i < dosyalar.length; i++) {
            var m = Dosya.oku(Dosya.yapilandirma + "/../" + dosyalar[i]).match(/\[Wallpaper\]\[org\.kde\.image\]\[General\][^\[]*?Image=([^\n]+)/)
            if (m) {
                var y = m[1].trim()
                if (!y.startsWith("file://")) y = "file://" + y
                if (y.endsWith("/")) {
                    // paket dizini: contents/images içindeki en büyük resim
                    var l = Dosya.resimler(y.replace("file://", "") + "contents/images", 30)
                    y = l.length ? l[l.length - 1] : ""
                }
                duvarKagidi = y
                return
            }
        }
        duvarKagidi = tema.win + "Web/Wallpaper/Windows/img0.jpg"
    }

    // ------------------------------------------------------------------ kutucuk düzeni (JSON)
    readonly property string duzenDosyasi: Dosya.yapilandirma + "/baslangic.json"
    property var grupAdlari: []
    ListModel { id: kutucuklar }     // uid, grup, tur, kimlik, boyut, canli, x, y, w, h, gx
    property int sonUid: 0
    property var grupGenislik: []    // piksel cinsinden grup başlangıçları/genişlikleri
    property real toplamGenislik: 0

    function boyutBirim(b) {
        return ({ "kucuk": [1, 1], "orta": [2, 2], "genis": [4, 2], "buyuk": [4, 4] })[b] || [2, 2]
    }
    function varsayilanDuzen() {
        function u(adaylar, boyut) {
            var id = Uygulamalar.bul(adaylar)
            return id ? { tur: "uygulama", kimlik: id, boyut: boyut || "orta" } : null
        }
        var g1 = [
            { tur: "masaustu", boyut: "genis" },
            u(["firefox.desktop", "google-chrome.desktop", "chromium.desktop", "org.kde.falkon.desktop"]),
            { tur: "ayarlar", boyut: "orta" },
            { tur: "hava", boyut: "genis" },
            { tur: "takvim", boyut: "orta" },
            u(["org.kde.dolphin.desktop", "org.gnome.Nautilus.desktop", "thunar.desktop"]),
            { tur: "fotograflar", boyut: "genis" },
            u(["org.kde.discover.desktop", "octopi.desktop", "org.manjaro.pamac.manager.desktop", "pamac-manager.desktop"]),
            u(["steam.desktop"]),
        ]
        var g2 = [
            u(["org.kde.kwrite.desktop", "org.kde.kate.desktop", "org.gnome.TextEditor.desktop"]),
            u(["org.kde.kcalc.desktop", "org.gnome.Calculator.desktop", "qalculate-gtk.desktop"]),
            u(["org.kde.konsole.desktop", "org.gnome.Console.desktop", "kitty.desktop", "alacritty.desktop"]),
            u(["org.kde.plasma-systemmonitor.desktop", "org.kde.ksysguard.desktop"]),
            u(["org.kde.spectacle.desktop"], "kucuk"),
            u(["org.kde.kolourpaint.desktop", "gimp.desktop", "org.kde.krita.desktop"], "kucuk"),
            u(["org.kde.gwenview.desktop"], "kucuk"),
            u(["org.kde.okular.desktop"], "kucuk"),
            u(["vlc.desktop", "mpv.desktop", "org.kde.haruna.desktop", "org.kde.dragonplayer.desktop"]),
            u(["org.kde.elisa.desktop", "strawberry.desktop", "audacious.desktop"]),
        ]
        return { gruplar: [{ ad: "", kutucuklar: g1.filter(Boolean) }, { ad: "", kutucuklar: g2.filter(Boolean) }] }
    }
    function duzenYukle() {
        var d = null
        try { d = JSON.parse(Dosya.oku(duzenDosyasi)) } catch (e) { d = null }
        if (!d || !d.gruplar) d = varsayilanDuzen()
        kutucuklar.clear()
        var adlar = []
        for (var g = 0; g < d.gruplar.length; g++) {
            adlar.push(d.gruplar[g].ad || "")
            var l = d.gruplar[g].kutucuklar || []
            for (var i = 0; i < l.length; i++) {
                var t = l[i]
                if (t.tur === "uygulama" && !Uygulamalar.var(t.kimlik)) continue
                kutucuklar.append({ uid: ++sonUid, grup: g, tur: t.tur, kimlik: t.kimlik || "", boyut: t.boyut || "orta",
                                    canli: t.canli !== false, x: 0, y: 0, w: 150, h: 150, secili: false })
            }
        }
        grupAdlari = adlar
        yerlestir()
    }
    function duzenKaydet() {
        var gruplar = []
        for (var g = 0; g < grupAdlari.length; g++) gruplar.push({ ad: grupAdlari[g], kutucuklar: [] })
        for (var i = 0; i < kutucuklar.count; i++) {
            var t = kutucuklar.get(i)
            while (gruplar.length <= t.grup) gruplar.push({ ad: "", kutucuklar: [] })
            var o = { tur: t.tur, boyut: t.boyut }
            if (t.kimlik) o.kimlik = t.kimlik
            if (!t.canli) o.canli = false
            gruplar[t.grup].kutucuklar.push(o)
        }
        gruplar = gruplar.filter(function (g) { return g.kutucuklar.length > 0 })
        Dosya.yaz(duzenDosyasi, JSON.stringify({ gruplar: gruplar }, null, 1))
    }
    // boş grupları at, grup numaralarını sıkıştır
    function gruplariSikistir() {
        var kullanilan = {}
        for (var i = 0; i < kutucuklar.count; i++) kullanilan[kutucuklar.get(i).grup] = true
        var esle = {}, yeniAd = [], n = 0
        var enBuyuk = grupAdlari.length
        for (var j = 0; j < kutucuklar.count; j++) enBuyuk = Math.max(enBuyuk, kutucuklar.get(j).grup + 1)
        for (var g = 0; g < enBuyuk; g++) {
            if (kullanilan[g]) { esle[g] = n++; yeniAd.push(grupAdlari[g] || "") }
        }
        for (var k = 0; k < kutucuklar.count; k++) kutucuklar.setProperty(k, "grup", esle[kutucuklar.get(k).grup])
        grupAdlari = yeniAd
    }
    // Windows 8 yerleşimi: grup = 4 birim genişliğinde bloklar; bloğun içinde orta kutucuklar satır satır,
    // küçük kutucuklar bir orta hücrenin 2x2'sine dolar; blok dolunca sağdaki bloğa geçilir
    function yerlestir() {
        var R = satir
        var x0 = 0
        var genislikler = []
        // grupları sırayla, model sırasına göre
        var gruplar = {}
        var enBuyuk = -1
        for (var i = 0; i < kutucuklar.count; i++) {
            var gi = kutucuklar.get(i).grup
            if (!gruplar[gi]) gruplar[gi] = []
            gruplar[gi].push(i)
            enBuyuk = Math.max(enBuyuk, gi)
        }
        for (var g = 0; g <= enBuyuk; g++) {
            var liste = gruplar[g] || []
            var dolu = {}
            function bos(c, r, w, h) {
                for (var a = 0; a < w; a++) for (var b = 0; b < h; b++) if (dolu[(c + a) + "," + (r + b)]) return false
                return true
            }
            function isaretle(c, r, w, h) {
                for (var a = 0; a < w; a++) for (var b = 0; b < h; b++) dolu[(c + a) + "," + (r + b)] = true
            }
            var enSagBlok = 0
            for (var t = 0; t < liste.length; t++) {
                var m = kutucuklar.get(liste[t])
                var wh = boyutBirim(m.boyut)
                var w = wh[0], h = wh[1]
                var yer = null
                for (var blok = 0; !yer && blok < 200; blok++) {
                    for (var r2 = 0; !yer && r2 + Math.max(2, h) <= R; r2 += 2) {
                        for (var c2 = 0; !yer && c2 < 4; c2 += 2) {
                            var cc = blok * 4 + c2
                            if (w === 4 && c2 !== 0) continue
                            if (w === 1) {
                                var alt = [[0, 0], [1, 0], [0, 1], [1, 1]]
                                for (var s = 0; s < 4 && !yer; s++)
                                    if (bos(cc + alt[s][0], r2 + alt[s][1], 1, 1)) yer = [cc + alt[s][0], r2 + alt[s][1]]
                            } else if (bos(cc, r2, w, h)) {
                                yer = [cc, r2]
                            }
                        }
                    }
                }
                if (!yer) yer = [0, 0]
                isaretle(yer[0], yer[1], w, h)
                enSagBlok = Math.max(enSagBlok, Math.floor((yer[0] + w - 1) / 4))
                kutucuklar.setProperty(liste[t], "x", x0 + yer[0] * adim)
                kutucuklar.setProperty(liste[t], "y", yer[1] * adim)
                kutucuklar.setProperty(liste[t], "w", w * adim - aralik)
                kutucuklar.setProperty(liste[t], "h", h * adim - aralik)
            }
            var gen = liste.length ? (enSagBlok + 1) * 4 * adim - aralik : 0
            // yalnızca küçük/orta kutucuklarla yarım dolu blok daralır
            if (liste.length) {
                var enSagSutun = 0
                for (var q = 0; q < liste.length; q++) {
                    var mm = kutucuklar.get(liste[q])
                    enSagSutun = Math.max(enSagSutun, (mm.x - x0) + mm.w)
                }
                gen = enSagSutun
            }
            genislikler.push({ x: x0, w: gen })
            x0 += gen + (liste.length ? grupAraligi + aralik : 0)
        }
        grupGenislik = genislikler
        toplamGenislik = x0
    }
    onSatirChanged: if (kutucuklar.count) yerlestir()

    function secimiTemizle() {
        for (var i = 0; i < kutucuklar.count; i++) if (kutucuklar.get(i).secili) kutucuklar.setProperty(i, "secili", false)
    }
    function kutucukBul(tur, kimlik) {
        for (var i = 0; i < kutucuklar.count; i++) {
            var t = kutucuklar.get(i)
            if (t.tur === tur && (tur !== "uygulama" || t.kimlik === kimlik)) return i
        }
        return -1
    }
    function sabitle(kimlik) {
        if (kutucukBul("uygulama", kimlik) >= 0) return
        var son = 0
        for (var i = 0; i < kutucuklar.count; i++) son = Math.max(son, kutucuklar.get(i).grup)
        kutucuklar.append({ uid: ++sonUid, grup: son, tur: "uygulama", kimlik: kimlik, boyut: "orta", canli: true,
                            x: 0, y: 0, w: 150, h: 150, secili: false })
        yerlestir(); duzenKaydet()
    }
    function ayir(i) {
        kutucuklar.remove(i)
        gruplariSikistir(); yerlestir(); duzenKaydet()
    }
    function yenidenBoyutlandir(i, b) {
        kutucuklar.setProperty(i, "boyut", b)
        yerlestir(); duzenKaydet()
    }

    // ------------------------------------------------------------------ sürükle-bırak
    property int suruklenen: -1
    property point surukleKonum
    property point surukleFark
    function surukleBasla(i, gx, gy) {
        menu.kapat()
        suruklenen = i
        var t = kutucuklar.get(i)
        var p = izgara.mapFromItem(null, gx, gy)
        surukleFark = Qt.point(p.x - t.x, p.y - t.y)
        surukleKonum = Qt.point(t.x, t.y)
    }
    function surukle(gx, gy) {
        if (suruklenen < 0) return
        var p = izgara.mapFromItem(null, gx, gy)
        surukleKonum = Qt.point(p.x - surukleFark.x, p.y - surukleFark.y)
        // hedef: imlecin altındaki başka kutucuk
        var t = kutucuklar.get(suruklenen)
        for (var i = 0; i < kutucuklar.count; i++) {
            if (i === suruklenen) continue
            var o = kutucuklar.get(i)
            if (p.x >= o.x && p.x < o.x + o.w && p.y >= o.y && p.y < o.y + o.h) {
                var hedefGrup = o.grup
                kutucuklar.setProperty(suruklenen, "grup", hedefGrup)
                kutucuklar.move(suruklenen, i, 1)
                suruklenen = i
                yerlestir()
                return
            }
        }
        // grupların arasındaki boşluk ya da son grubun sağı: yeni grup
        var gg = grupGenislik
        if (gg.length && p.x > gg[gg.length - 1].x + gg[gg.length - 1].w + 40 && kutucuklar.count > 1) {
            var tek = true
            for (var j = 0; j < kutucuklar.count; j++) if (j !== suruklenen && kutucuklar.get(j).grup === t.grup) tek = false
            if (!tek) {
                kutucuklar.setProperty(suruklenen, "grup", gg.length)
                kutucuklar.move(suruklenen, kutucuklar.count - 1, 1)
                suruklenen = kutucuklar.count - 1
                grupAdlari = grupAdlari.concat([""])
                yerlestir()
            }
            return
        }
        for (var g = 0; g + 1 < gg.length; g++) {
            var bosBas = gg[g].x + gg[g].w + 8, bosSon = gg[g + 1].x - 8
            if (p.x > bosBas && p.x < bosSon) {
                // g ile g+1 arasına yeni grup
                for (var k = 0; k < kutucuklar.count; k++) if (kutucuklar.get(k).grup > g) kutucuklar.setProperty(k, "grup", kutucuklar.get(k).grup + 1)
                kutucuklar.setProperty(suruklenen, "grup", g + 1)
                var adlar = grupAdlari.slice(); adlar.splice(g + 1, 0, ""); grupAdlari = adlar
                gruplariSikistir()
                yerlestir()
                return
            }
        }
    }
    function surukleBitir() {
        suruklenen = -1
        gruplariSikistir()
        yerlestir()
        duzenKaydet()
    }

    // ------------------------------------------------------------------ içerik
    Item {
        id: icerik
        width: pen.width; height: pen.height
        focus: true
        transformOrigin: Item.Center

        DesenArkaPlan {
            anchors.fill: parent
            tema: pen.tema
            duvarKagidi: tema.renk.masaustuArkaPlani ? pen.duvarKagidi : ""
            kaydirma: kaydirici.contentX
            dikey: pen.sayfaKonum
        }

        // Başlangıç / Uygulamalar dikey geçişi
        Item {
            id: baslangicSayfasi
            width: pen.width; height: pen.height
            y: -pen.sayfaKonum * pen.height

            Text {
                x: pen.solBosluk; y: 42
                text: "Başlangıç"
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 56
                opacity: pen.girisDegeri(0)
            }
            // sağ üst: kullanıcı, güç, ara (8.1 Update)
            Row {
                anchors.right: parent.right; anchors.rightMargin: 40
                y: 52
                spacing: 18
                Item {
                    width: kullaniciSatir.width; height: 40
                    Row {
                        id: kullaniciSatir
                        spacing: 12
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Sistem.adSoyad; color: "white"
                            font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 26
                        }
                        Rectangle {
                            width: 40; height: 40; color: Qt.rgba(1, 1, 1, 0.15)
                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Sistem.avatar !== "" ? Sistem.avatar : tema.varlik + "user-40.png"
                                sourceSize.width: 80
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var p = mapToItem(icerik, 0, height + 4)
                            menu.ac(p.x, p.y, [
                                { metin: "Hesap resmini değiştir", eylem: function () { pen.kapat(); Sistem.ayarAc("kcm_users") } },
                                { metin: "Kilitle", eylem: function () { pen.kapat(); Sistem.kilitle() } },
                                { metin: "Oturumu kapat", eylem: function () { pen.kapat(); Sistem.oturumuKapat() } }
                            ])
                        }
                    }
                }
                DaireDugme {
                    anchors.verticalCenter: parent.verticalCenter
                    boyut: 30; glif: ""; glifOlcek: 0.5
                    onTiklandi: {
                        var p = mapToItem(icerik, -170, height + 4)
                        menu.ac(p.x, p.y, ana.gucOgeleri())
                    }
                }
                DaireDugme {
                    anchors.verticalCenter: parent.verticalCenter
                    boyut: 30; glif: ""; glifOlcek: 0.5
                    onTiklandi: ana.aramaAc("", "")
                }
            }

            Flickable {
                id: kaydirici
                x: 0; y: pen.ustBosluk - 40
                width: pen.width; height: pen.height - y
                contentWidth: Math.max(width, pen.solBosluk + pen.toplamGenislik + 200)
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                interactive: pen.suruklenen < 0
                Behavior on contentX { enabled: !kaydirici.flicking && !kaydirici.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                MouseArea {
                    // boş alan: sağ tık "Özelleştir", sol tık seçimi kaldırır
                    width: kaydirici.contentWidth; height: kaydirici.height
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        pen.secimiTemizle()
                        if (mouse.button === Qt.RightButton) {
                            var p = mapToItem(icerik, mouse.x, mouse.y)
                            menu.ac(p.x, p.y, [{ metin: pen.ozellestir ? "Özelleştirmeyi bitir" : "Özelleştir", eylem: function () { pen.ozellestir = !pen.ozellestir } }])
                        } else if (pen.ozellestir) {
                            pen.ozellestir = false
                        }
                    }
                    onWheel: wheel => {
                        var d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                        kaydirici.contentX = Math.max(0, Math.min(kaydirici.contentWidth - kaydirici.width, kaydirici.contentX - d * 1.6))
                    }
                }

                Item {
                    id: izgara
                    x: pen.solBosluk; y: 40
                    width: pen.toplamGenislik; height: pen.satir * pen.adim

                    // grup adları (özelleştir kipinde düzenlenebilir)
                    Repeater {
                        model: pen.grupGenislik.length
                        delegate: Item {
                            required property int index
                            x: pen.grupGenislik[index].x; y: -40
                            width: pen.grupGenislik[index].w; height: 34
                            visible: pen.ozellestir || (pen.grupAdlari[index] || "") !== ""
                            Text {
                                id: grupAdi
                                visible: !pen.ozellestir
                                anchors.verticalCenter: parent.verticalCenter
                                text: pen.grupAdlari[index] || ""
                                color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
                            }
                            Rectangle {
                                visible: pen.ozellestir
                                anchors.fill: parent
                                color: girdi.activeFocus ? "white" : Qt.rgba(1, 1, 1, 0.18)
                                TextInput {
                                    id: girdi
                                    anchors.fill: parent; anchors.leftMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: pen.grupAdlari[index] || ""
                                    color: activeFocus ? "black" : "white"
                                    font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
                                    onEditingFinished: {
                                        var a = pen.grupAdlari.slice(); a[index] = text; pen.grupAdlari = a; pen.duzenKaydet()
                                    }
                                }
                                Text {
                                    visible: girdi.text === "" && !girdi.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter; x: 8
                                    text: "Grubu adlandırın"; color: Qt.rgba(1, 1, 1, 0.7)
                                    font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
                                }
                            }
                        }
                    }

                    Repeater {
                        model: kutucuklar
                        delegate: Kutucuk {
                            id: kd
                            required property int index
                            required property var model
                            tema: pen.tema
                            tur: model.tur; kimlik: model.kimlik; boyut: model.boyut; canli: model.canli
                            secili: model.secili
                            duvarKagidi: pen.duvarKagidi
                            surukleniyor: pen.suruklenen === index
                            z: surukleniyor ? 10 : 0
                            x: surukleniyor ? pen.surukleKonum.x : model.x
                            y: surukleniyor ? pen.surukleKonum.y : model.y
                            width: model.w; height: model.h
                            giris: pen.girisDegeri(model.x - kaydirici.contentX)
                            Behavior on x { enabled: !kd.surukleniyor; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                            Behavior on y { enabled: !kd.surukleniyor; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                            onTiklandi: {
                                if (pen.ozellestir) return
                                pen.secimiTemizle()
                                ana.kutucukCalistir(model.tur, model.kimlik)
                            }
                            onSagTiklandi: (gx, gy) => {
                                pen.secimiTemizle()
                                kutucuklar.setProperty(index, "secili", true)
                                var p = icerik.mapFromItem(null, gx, gy)
                                menu.ac(p.x, p.y, pen.kutucukMenusu(index))
                            }
                            onSurukleBasla: (gx, gy) => pen.surukleBasla(index, gx, gy)
                            onSurukle: (gx, gy) => pen.surukle(gx, gy)
                            onSurukleBitti: pen.surukleBitir()
                        }
                    }
                }
            }

            // Uygulamalar görünümü düğmesi (fare kıpırdayınca belirir)
            DaireDugme {
                id: asagiDugme
                x: pen.solBosluk
                y: pen.ustBosluk + pen.satir * pen.adim + 4
                boyut: 34; glif: ""; donus: 90; glifOlcek: 0.42
                opacity: fareHareket.running ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
                onTiklandi: pen.sayfa = 1
            }
            Text {
                visible: Uygulamalar.yeniSayisi > 0 && asagiDugme.visible
                anchors.left: asagiDugme.right; anchors.leftMargin: 10
                anchors.verticalCenter: asagiDugme.verticalCenter
                text: Uygulamalar.yeniSayisi + " yeni uygulama"
                color: "white"; font.family: "Segoe UI"; font.pixelSize: 15
            }
        }

        UygulamalarGorunumu {
            id: uygulamalarGorunumu
            width: pen.width; height: pen.height
            y: (1 - pen.sayfaKonum) * pen.height
            tema: pen.tema
            ana: pen.ana
            baslangic: pen
            visible: pen.sayfaKonum > 0.001
        }

        MouseArea {
            // fare hareketini izle (aşağı ok düğmesi)
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            onPositionChanged: fareHareket.restart()
        }
        Timer { id: fareHareket; interval: 2500 }

        MetroMenu { id: menu }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (menu.acik) menu.kapat()
                else if (pen.ozellestir) pen.ozellestir = false
                else if (pen.sayfa === 1) pen.sayfa = 0
                else ana.baslangicKapat()
                event.accepted = true
            } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
                pen.sayfa = pen.sayfa ? 0 : 1
                event.accepted = true
            } else if (event.text.length === 1 && event.text.charCodeAt(0) > 32 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                if (pen.sayfa === 1) uygulamalarGorunumu.yaz(event.text)
                else ana.aramaAc(event.text, "")
                event.accepted = true
            }
        }
    }

    property real sayfaKonum: sayfa
    Behavior on sayfaKonum { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

    // ------------------------------------------------------------------ menüler
    function kutucukMenusu(i) {
        var t = kutucuklar.get(i)
        var l = [{ metin: "Başlangıç ekranından ayır", eylem: function () { pen.ayir(i) } }]
        if (t.tur === "uygulama") {
            var sabit = ana.gorevCubugundaMi(t.kimlik)
            l.push({ metin: sabit ? "Görev çubuğundan ayır" : "Görev çubuğuna sabitle", eylem: function () { ana.gorevCubugunaSabitle(t.kimlik, !sabit) } })
            l.push({ metin: "Kaldır", eylem: function () { ana.kaldir(t.kimlik) } })
        }
        var boyutlar = t.tur === "uygulama" ? [["kucuk", "Küçük"], ["orta", "Orta"]]
                     : [["kucuk", "Küçük"], ["orta", "Orta"], ["genis", "Geniş"], ["buyuk", "Büyük"]]
        if (t.tur === "ayarlar") boyutlar = [["kucuk", "Küçük"], ["orta", "Orta"]]
        l.push({ metin: "Yeniden boyutlandır", alt: boyutlar.map(function (b) {
            return { metin: b[1], isaretli: t.boyut === b[0], eylem: function () { pen.yenidenBoyutlandir(i, b[0]) } }
        }) })
        if (["hava", "takvim", "fotograflar"].indexOf(t.tur) >= 0)
            l.push({ metin: t.canli ? "Canlı kutucuğu kapat" : "Canlı kutucuğu aç", eylem: function () { kutucuklar.setProperty(i, "canli", !t.canli); pen.duzenKaydet() } })
        if (t.tur === "uygulama") {
            l.push({ metin: "Yeni pencere aç", eylem: function () { ana.kutucukCalistir("uygulama", t.kimlik) } })
            var ey = Uygulamalar.eylemler(t.kimlik)
            if (ey.length) {
                l.push({ ayirici: true })
                for (var e = 0; e < Math.min(ey.length, 5); e++) {
                    (function (a) { l.push({ metin: a.metin, eylem: function () { pen.kapat(); Uygulamalar.eylemCalistir(t.kimlik, a.ad) } }) })(ey[e])
                }
                l.push({ ayirici: true })
            }
            l.push({ metin: "Dosya konumunu aç", eylem: function () { pen.kapat(); Uygulamalar.dosyaKonumunuAc(t.kimlik) } })
        }
        return l
    }

}
