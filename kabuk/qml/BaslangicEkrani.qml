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
    readonly property int grupAraligi: 70        // + aralık = 80 px (Windows 8 grup boşluğu)
    readonly property int satir: Math.max(4, Math.floor((ekranY - ustBosluk - 60) / adim) & ~1)
    // içerik her zaman tam ekran yüksekliğinde; pencere alttan kısalınca (görev çubuğu) yalnız kırpılır
    readonly property int ekranY: Screen.height

    width: Screen.width
    height: Screen.height
    Component.onCompleted: {
        KatmanYardimci.ayarla(pen, 3, 15, 1, -1, "metro-baslangic")
        duzenYukle()
    }

    // ------------------------------------------------------------------ aç / kapat
    // Windows 8.1: masaüstünden gelince zemin hızla belirir, kutucuklar sütun sütun sağdan kayarak gelir
    // (PVL eğrisi). Oturum açılışındaki ilk gösterimde kutucuklar döner kapı gibi (turnstile) daha uzaktan gelir.
    property bool oturumGirisi: false
    function ac(uygulamalar, girisKipi) {
        if (acik && !kapanis.running) {
            if (uygulamalar) sayfa = 1
            return
        }
        kapanis.stop()
        acilisEkrani.sifirla()
        duvarKagidiOku()
        sayfaAnimasyon = false
        sayfa = (uygulamalar || tema.baslangic.uygulamalarOtomatik) ? 1 : 0   // Behavior kapalı: hemen
        sayfaAnimasyon = true
        uygulamalarGorunumu.sifirla()
        gorevCubuguGoster(false)
        uzak = false
        oturumGirisi = !!girisKipi
        acik = true
        icerik.opacity = 1
        icerik.scale = 1
        zemin.opacity = oturumGirisi ? 1 : 0
        girisZaman = 0
        visible = true
        requestActivate()
        acilis.restart()
        icerik.forceActiveFocus()
        if (SinamaDondur > 0) sinamaZamanlayici.restart()
        if (SinamaKip !== "") sinamaKipZamanlayici.restart()
        if (SinamaUzak) Qt.callLater(function () { if (pen.sayfa === 1) uygulamalarGorunumu.uzak = true; else pen.uzaklas(true) })
    }
    Timer { id: sinamaZamanlayici; interval: SinamaDondur; onTriggered: acilis.pause() }
    Timer { id: sinamaBirak; interval: 2500; onTriggered: pen.surukleBitir() }
    Timer {
        id: sinamaKipZamanlayici; interval: 1500
        onTriggered: {
            if (SinamaKip === "ozellestir") pen.ozellestir = true
            else if (SinamaKip === "surukle") {
                // ilk grubun son uygulama kutucuğunu 1. ile 2. grubun arasına sürükle; 2,5 sn sonra bırak
                var si = -1
                for (var q = 0; q < kutucuklar.count; q++) if (kutucuklar.get(q).grup === 0 && kutucuklar.get(q).tur === "uygulama") si = q
                var st = kutucuklar.get(si), gg = pen.grupGenislik
                var bas = izgara.mapToItem(null, st.x + 20, st.y + 20)
                var hedef = izgara.mapToItem(null, gg[0].x + gg[0].w + (pen.grupAraligi + pen.aralik) / 2, st.y + 20)
                pen.surukleBasla(si, bas.x, bas.y)
                pen.surukle(bas.x + 30, bas.y)
                pen.surukle(hedef.x, hedef.y)
                sinamaBirak.restart()
            }
            else if (SinamaKip === "menu" || SinamaKip === "secim") {
                var i = 0
                for (var k = 0; k < kutucuklar.count; k++) if (kutucuklar.get(k).tur === "uygulama") { i = k; break }
                var t = kutucuklar.get(i)
                kutucuklar.setProperty(i, "secili", true)
                if (SinamaKip === "secim" && i + 1 < kutucuklar.count) kutucuklar.setProperty(i + 1, "secili", true)
                if (SinamaKip === "menu") {
                    var p = izgara.mapToItem(icerik, t.x + t.w / 2, t.y + t.h / 2)
                    menu.ac(p.x, p.y, pen.kutucukMenusu(i))
                }
            }
        }
    }
    // hemen: animasyonsuz kapat (uygulama açılış ekranı kendi geçişini yaptıktan sonra)
    function kapat(hemen) {
        if (!acik) return
        acik = false
        menu.kapat()
        secimiTemizle()
        ozellestir = false
        acilis.stop()
        gorevCubuguGoster(false)
        if (hemen) {
            kapanis.stop()
            visible = false
            acilisEkrani.sifirla()
            return
        }
        kapanis.restart()
    }
    function degistir() { if (acik) kapat(); else ac(false) }

    ParallelAnimation {
        id: acilis
        NumberAnimation { target: zemin; property: "opacity"; to: 1; duration: 167 }
        NumberAnimation { target: pen; property: "girisZaman"; from: 0; to: pen.girisToplam; duration: pen.girisToplam; easing.type: Easing.Linear }
    }
    // Başlangıç'tan masaüstüne: içerik küçülerek kaybolur
    SequentialAnimation {
        id: kapanis
        ParallelAnimation {
            NumberAnimation { target: icerik; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { target: icerik; property: "scale"; to: 0.92; duration: 200; easing.type: Easing.InQuad }
        }
        ScriptAction { script: { pen.visible = false; icerik.scale = 1; icerik.opacity = 1 } }
    }

    // kutucuk girişi: her sütun (iki birim) bir öncekinden biraz sonra başlar
    property real girisZaman: 100000                       // ms; büyük değer = bitti
    readonly property int girisSure: oturumGirisi ? 1100 : 600
    readonly property int girisAdim: oturumGirisi ? 70 : 35
    readonly property int girisEnGec: oturumGirisi ? 900 : 350
    readonly property int girisToplam: girisSure + girisEnGec
    // x: kutucuğun ekrandaki sol kenarı; dönüş 0..1 doğrusal yerel ilerleme
    function girisDegeri(x) {
        var sutun = Math.max(0, Math.floor((x - solBosluk + adim / 2) / (adim * 2)))
        var gecikme = Math.min(sutun * girisAdim, girisEnGec)
        return Math.max(0, Math.min(1, (girisZaman - gecikme) / girisSure))
    }

    // ------------------------------------------------------------------ 8.1 Update: Başlangıç'ta görev çubuğu
    // fare ekranın alt kenarına inince görev çubuğu Başlangıç ekranının üstünde görünür
    property bool gorevCubugu: false
    function gorevCubuguGoster(g) {
        if (gorevCubugu === g) return
        gorevCubugu = g
        // pencere alttan görev çubuğu yüksekliği kadar kısalır, Plasma paneli altta görünür;
        // klavye isteğe bağlı olur ki görev düğmesine tıklanınca etkin pencere değişsin (Başlangıç kapanır)
        KatmanYardimci.kenarBosluk(pen, 0, 0, g ? 40 : 0, 0)
        KatmanYardimci.klavyeAyarla(pen, g ? 2 : 1)
    }
    onActiveChanged: if (!active && acik && gorevCubugu) kapat()

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
        // Windows 8.1 varsayılanına benzer: 1) Masaüstü, Takvim, tarayıcı, Fotoğraflar, Hava, Mağaza…
        // 2) Metro uygulamaları (Haberler, Spor, Finans, Müzik, Video…) 3) masaüstü programları
        var g1 = [
            { tur: "masaustu", boyut: "genis" },
            { tur: "takvim", boyut: "orta" },
            u(["firefox.desktop", "google-chrome.desktop", "chromium.desktop", "org.kde.falkon.desktop"]),
            { tur: "fotograflar", boyut: "genis" },
            { tur: "hava", boyut: "genis" },
            { tur: "ayarlar", boyut: "orta" },
            u(["metro-magaza.desktop"]),
            u(["explorer.desktop", "org.kde.dolphin.desktop", "org.gnome.Nautilus.desktop", "thunar.desktop"]),
        ]
        var g2 = [
            u(["metro-haberler.desktop"], "genis"),
            u(["metro-spor.desktop"]),
            u(["metro-finans.desktop"]),
            u(["metro-muzik.desktop"]),
            u(["metro-video.desktop"]),
            u(["metro-kamera.desktop"]),
            u(["metro-yardim.desktop"]),
            u(["metro-hesap-makinesi.desktop"], "kucuk"),
            u(["metro-alarmlar.desktop"], "kucuk"),
            u(["metro-ses-kaydedici.desktop"], "kucuk"),
            u(["steam.desktop"], "kucuk"),
        ]
        var g3 = [
            u(["org.kde.kwrite.desktop", "org.kde.kate.desktop", "org.gnome.TextEditor.desktop"]),
            u(["org.kde.konsole.desktop", "org.gnome.Console.desktop", "kitty.desktop", "alacritty.desktop"]),
            u(["org.kde.plasma-systemmonitor.desktop", "org.kde.ksysguard.desktop"]),
            u(["org.kde.spectacle.desktop"], "kucuk"),
            u(["org.kde.kolourpaint.desktop", "gimp.desktop", "org.kde.krita.desktop"], "kucuk"),
            u(["org.kde.gwenview.desktop"], "kucuk"),
            u(["org.kde.okular.desktop"], "kucuk"),
            u(["vlc.desktop", "mpv.desktop", "org.kde.haruna.desktop", "org.kde.dragonplayer.desktop"]),
        ]
        return { gruplar: [g1, g2, g3].map(function (g) { return { ad: "", kutucuklar: g.filter(Boolean) } })
                                          .filter(function (g) { return g.kutucuklar.length > 0 }) }
    }
    function duzenYukle() {
        var d = null
        try { d = JSON.parse(Dosya.oku(duzenDosyasi)) } catch (e) { d = null }
        if (!d || !d.gruplar) d = varsayilanDuzen()
        // AeroThemePlasma'dan yükseltme (metro-yukselt): Başlat menüsü sabitleri yeni bir kutucuk grubu olur
        var bekleyen = []
        try { bekleyen = JSON.parse(Dosya.oku(Dosya.yapilandirma + "/bekleyen-kutucuklar.json")) || [] } catch (e) { bekleyen = [] }
        if (bekleyen.length) {
            var var_ = {}
            d.gruplar.forEach(function (g) { (g.kutucuklar || []).forEach(function (t) { if (t.kimlik) var_[t.kimlik] = true }) })
            var yeni = bekleyen.filter(function (k) { return !var_[k] && Uygulamalar.var(k) })
                               .map(function (k) { return { tur: "uygulama", kimlik: k, boyut: "orta" } })
            if (yeni.length) d.gruplar.push({ ad: "", kutucuklar: yeni })
            Dosya.yaz(Dosya.yapilandirma + "/bekleyen-kutucuklar.json", "[]")
        }
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
        if (bekleyen.length) duzenKaydet()
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
        // Windows 8.1: imleç iki grubun arasındaki boşlukta ya da son grubun hemen sağındaysa açık renkli
        // dikey çubuk belirir; yeni grup ancak bırakınca oluşur. Grubun boş alanına gelince kutucuk o gruba katılır.
        var gg = grupGenislik
        yeniGrupYeri = -1
        if (!gg.length) return
        var son = gg[gg.length - 1]
        var tek = true
        for (var j = 0; j < kutucuklar.count; j++) if (j !== suruklenen && kutucuklar.get(j).grup === t.grup) tek = false
        if (p.x > son.x + son.w + 8 && p.x < son.x + son.w + grupAraligi + 2 * adim) {
            if (!tek || t.grup !== gg.length - 1) yeniGrupYeri = gg.length - 1
            return
        }
        for (var g = 0; g + 1 < gg.length; g++) {
            if (p.x > gg[g].x + gg[g].w + 8 && p.x < gg[g + 1].x - 8) {
                // kendi tekli grubunun iki yanındaki boşluk bir şey değiştirmez
                if (!(tek && (t.grup === g || t.grup === g + 1))) yeniGrupYeri = g
                return
            }
        }
        for (var h = 0; h < gg.length; h++) {
            if (p.x >= gg[h].x && p.x <= gg[h].x + gg[h].w && t.grup !== h) {
                kutucuklar.setProperty(suruklenen, "grup", h)
                var sonIndis = suruklenen
                for (var m = 0; m < kutucuklar.count; m++) if (m !== suruklenen && kutucuklar.get(m).grup === h) sonIndis = m
                if (sonIndis !== suruklenen) {
                    kutucuklar.move(suruklenen, sonIndis > suruklenen ? sonIndis : sonIndis + 1, 1)
                    suruklenen = sonIndis > suruklenen ? sonIndis : sonIndis + 1
                }
                gruplariSikistir()
                yerlestir()
                return
            }
        }
    }
    property int yeniGrupYeri: -1     // sürüklerken: bu grubun sağına yeni grup (bırakınca)
    function surukleBitir() {
        if (suruklenen >= 0 && yeniGrupYeri >= 0) {
            var g = yeniGrupYeri
            for (var k = 0; k < kutucuklar.count; k++) if (kutucuklar.get(k).grup > g) kutucuklar.setProperty(k, "grup", kutucuklar.get(k).grup + 1)
            kutucuklar.setProperty(suruklenen, "grup", g + 1)
            var adlar = grupAdlari.slice(); adlar.splice(g + 1, 0, ""); grupAdlari = adlar
        }
        yeniGrupYeri = -1
        suruklenen = -1
        gruplariSikistir()
        yerlestir()
        duzenKaydet()
    }

    // ------------------------------------------------------------------ içerik
    Item {
        id: icerik
        width: pen.width; height: pen.ekranY
        focus: true
        transformOrigin: Item.Center

        DesenArkaPlan {
            id: zemin
            anchors.fill: parent
            tema: pen.tema
            duvarKagidi: tema.renk.masaustuArkaPlani ? pen.duvarKagidi : ""
            kaydirma: kaydirici.contentX
            dikey: pen.sayfaKonum
        }

        // Başlangıç / Uygulamalar dikey geçişi
        Item {
            id: baslangicSayfasi
            width: pen.width; height: pen.ekranY
            y: -pen.sayfaKonum * pen.ekranY

            Text {
                id: baslikYazi
                x: pen.solBosluk; y: 42
                text: "Başlangıç"
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 56
                readonly property real g: pen.girisDegeri(pen.solBosluk)
                opacity: Math.min(1, g * 3)
                transform: Translate { x: (1 - pen.tema.pvlDeger(baslikYazi.g)) * (pen.oturumGirisi ? 200 : 60) }
            }
            // sağ üst: kullanıcı, güç, ara (8.1 Update)
            Row {
                anchors.right: parent.right; anchors.rightMargin: 40
                y: 52
                opacity: Math.min(1, pen.girisDegeri(pen.width - 300) * 2.5)
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
                width: pen.width; height: pen.ekranY - y
                contentWidth: pen.uzak ? width : Math.max(width, pen.solBosluk + pen.toplamGenislik + 200)
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
                        // Ctrl+tekerlek: semantik yakınlaştırma
                        if (wheel.modifiers & Qt.ControlModifier) { pen.uzaklas(d < 0); return }
                        kaydirici.contentX = Math.max(0, Math.min(kaydirici.contentWidth - kaydirici.width, kaydirici.contentX - d * 1.6))
                    }
                }

                Item {
                    id: izgara
                    x: pen.solBosluk + pen.uzakKayma; y: 40
                    width: pen.toplamGenislik; height: pen.satir * pen.adim
                    // semantik yakınlaştırma: uzaklaşınca bütün gruplar küçülüp ortalanır
                    transform: Scale { origin.x: 0; origin.y: izgara.height / 2; xScale: pen.olcekDegeri; yScale: pen.olcekDegeri }

                    // yeni grup göstergesi (sürüklerken iki grubun arasında açık renkli dikey çubuk)
                    Rectangle {
                        visible: pen.yeniGrupYeri >= 0 && pen.yeniGrupYeri < pen.grupGenislik.length
                        readonly property var gr: visible ? pen.grupGenislik[pen.yeniGrupYeri] : ({ x: 0, w: 0 })
                        x: gr.x + gr.w + (pen.grupAraligi + pen.aralik) / 2 - width / 2
                        y: 0; width: 6; height: pen.satir * pen.adim - pen.aralik
                        color: Qt.rgba(1, 1, 1, 0.3)
                    }
                    // grup adları (özelleştir kipinde düzenlenebilir)
                    Repeater {
                        model: pen.grupGenislik.length
                        delegate: Item {
                            id: gb
                            required property int index
                            x: pen.grupGenislik[index].x; y: -40
                            width: pen.grupGenislik[index].w; height: 34
                            readonly property real g: pen.girisDegeri(x + pen.solBosluk - kaydirici.contentX)
                            opacity: Math.min(1, g * 3)
                            transform: Translate { x: (1 - pen.tema.pvlDeger(gb.g)) * (pen.oturumGirisi ? 420 : 140) }
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
                                clip: true
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
                            giris: pen.girisDegeri(model.x + pen.solBosluk - kaydirici.contentX)
                            girisMesafe: pen.oturumGirisi ? 420 : 140
                            girisAci: pen.oturumGirisi ? -70 : 0
                            Behavior on x { enabled: !kd.surukleniyor; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                            Behavior on y { enabled: !kd.surukleniyor; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                            onTiklandi: {
                                if (pen.ozellestir) return
                                pen.secimiTemizle()
                                if (model.tur === "ayarlar") {
                                    // Windows Mağazası uygulaması: kutucuk büyüyüp açılış ekranına dönüşür
                                    var r = kd.mapToItem(icerik, 0, 0, kd.width, kd.height)
                                    acilisEkrani.baslat(r, kd.zemin, pen.tema.win + "ImmersiveControlPanel/images/splashscreen.scale-100.png",
                                                        function () { ana.bilgisayarAyarlari("", true) })
                                    return
                                }
                                // Metro uygulaması (Hesap Makinesi, Hava Durumu, Fotoğraflar, Alarmlar…): açılış ekranı
                                var mu = ana.metroUygulamasi(model.tur, model.kimlik)
                                if (mu) {
                                    var r2 = kd.mapToItem(icerik, 0, 0, kd.width, kd.height)
                                    acilisEkrani.baslat(r2, kd.zemin, "file://" + Dosya.veri + "/varlik/uygulama-" + mu.slice(6, -8) + ".png",
                                                        function () { Uygulamalar.baslat(mu) }, true)
                                    return
                                }
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
            width: pen.width; height: pen.ekranY
            y: (1 - pen.sayfaKonum) * pen.ekranY
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
            onPositionChanged: mouse => {
                fareHareket.restart()
                // 8.1 Update: alt kenarda görev çubuğu belirir, yukarı çıkınca gizlenir
                if (pen.acik && !kapanis.running && mouse.y >= pen.ekranY - 2) pen.gorevCubuguGoster(true)
                else if (pen.gorevCubugu && mouse.y < pen.ekranY - 48) pen.gorevCubuguGoster(false)
            }
        }
        Timer { id: fareHareket; interval: 2500 }

        // uzaklaşmış görünümde tıklanan gruba yakınlaş
        MouseArea {
            visible: pen.uzak
            z: 40
            x: 0; y: kaydirici.y; width: pen.width; height: kaydirici.height
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                var p = izgara.mapFromItem(this, mouse.x, mouse.y)
                var gg = pen.grupGenislik, hedef = 0
                for (var g = 0; g < gg.length; g++) if (p.x >= gg[g].x - pen.grupAraligi / 2) hedef = g
                pen.uzaklas(false)
                if (gg.length) kaydirici.contentX = Math.max(0, Math.min(kaydirici.contentWidth - kaydirici.width, gg[hedef].x))
            }
            onWheel: wheel => { if (wheel.angleDelta.y > 0) pen.uzaklas(false) }
        }

        // yatay kaydırma çubuğu (fare kıpırdayınca belirir)
        Item {
            id: kaydirmaCubugu
            readonly property real oran: kaydirici.width / Math.max(1, kaydirici.contentWidth)
            visible: oran < 0.999 && pen.sayfaKonum < 0.5
            x: 0; width: pen.width; height: 14
            y: pen.ekranY - height - 2 - pen.sayfaKonum * pen.ekranY
            opacity: fareHareket.running || cma.pressed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
            Rectangle { anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: 2; color: Qt.rgba(1, 1, 1, 0.12) }
            Rectangle {
                id: tutamak
                y: 2; height: parent.height - 4
                width: Math.max(40, parent.width * kaydirmaCubugu.oran)
                x: (parent.width - width) * (kaydirici.contentX / Math.max(1, kaydirici.contentWidth - kaydirici.width))
                color: cma.pressed ? Qt.rgba(1, 1, 1, 0.75) : (cma.containsMouse ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.42))
            }
            MouseArea {
                id: cma
                anchors.fill: parent
                hoverEnabled: true
                property real fark: 0
                function konum(mx) {
                    var bos = width - tutamak.width
                    var o = Math.max(0, Math.min(1, (mx - fark) / Math.max(1, bos)))
                    kaydirici.contentX = o * (kaydirici.contentWidth - kaydirici.width)
                }
                onPressed: mouse => {
                    fark = (mouse.x >= tutamak.x && mouse.x <= tutamak.x + tutamak.width) ? mouse.x - tutamak.x : tutamak.width / 2
                    konum(mouse.x)
                }
                onPositionChanged: mouse => { fareHareket.restart(); if (pressed) konum(mouse.x) }
            }
        }

        // uygulama açılış ekranı: kutucuk tam ekrana büyür (PVL, 400 ms), uygulama arkasında açılır
        Rectangle {
            id: acilisEkrani
            visible: false
            z: 50
            property var sonra: null
            function sifirla() { buyume.stop(); visible = false; sonra = null }
            // kare: Metro uygulaması simgesi (uygulama-<ad>.png); uygulamanın kendi açılış ekranındaki
            // 150 px glifle aynı boyutta çizilir, süreç açılınca geçiş görünmez
            function baslat(r, renk, simge, fn, kare) {
                menu.kapat()
                sonra = fn
                color = renk
                logo.source = kare ? "" : simge
                logoKare.source = kare ? simge : ""
                x = r.x; y = r.y; width = r.width; height = r.height
                logo.opacity = 0; logoKare.opacity = 0
                visible = true
                buyume.restart()
            }
            Image {
                id: logo
                anchors.centerIn: parent
                width: 620; height: 300
                scale: Math.min(1, acilisEkrani.width / pen.width * 1.6)
            }
            Image {
                id: logoKare
                anchors.centerIn: parent
                width: 291; height: 291
                sourceSize.width: 291
                scale: Math.min(1, acilisEkrani.width / pen.width * 1.6)
            }
            SequentialAnimation {
                id: buyume
                ParallelAnimation {
                    NumberAnimation { target: acilisEkrani; property: "x"; to: 0; duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl }
                    NumberAnimation { target: acilisEkrani; property: "y"; to: 0; duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl }
                    NumberAnimation { target: acilisEkrani; property: "width"; to: pen.width; duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl }
                    NumberAnimation { target: acilisEkrani; property: "height"; to: pen.ekranY; duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl }
                    SequentialAnimation {
                        PauseAnimation { duration: 120 }
                        ParallelAnimation {
                            NumberAnimation { target: logo; property: "opacity"; to: 1; duration: 167 }
                            NumberAnimation { target: logoKare; property: "opacity"; to: 1; duration: 167 }
                        }
                    }
                }
                ScriptAction { script: if (acilisEkrani.sonra) acilisEkrani.sonra() }
                PauseAnimation { duration: 450 }
                ScriptAction { script: { ana.baslangicKapat(true) } }
            }
        }

        MetroMenu { id: menu }

        Keys.onPressed: event => {
            if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Minus || event.key === Qt.Key_Plus || event.key === Qt.Key_Equal)) {
                if (pen.sayfa === 0) pen.uzaklas(event.key === Qt.Key_Minus)
                else uygulamalarGorunumu.uzak = event.key === Qt.Key_Minus && uygulamalarGorunumu.basliklar.length > 0
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Escape) {
                if (menu.acik) menu.kapat()
                else if (pen.uzak) pen.uzaklas(false)
                else if (pen.sayfa === 1 && uygulamalarGorunumu.uzak) uygulamalarGorunumu.uzak = false
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

    // ------------------------------------------------------------------ semantik yakınlaştırma (Ctrl+tekerlek, Ctrl+-)
    property bool uzak: false
    readonly property real uzakOlcek: Math.min(0.42, (width - 2 * solBosluk) / Math.max(1, toplamGenislik))
    property real olcekDegeri: uzak ? uzakOlcek : 1
    Behavior on olcekDegeri { NumberAnimation { duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl } }
    // uzakta gruplar ekranda ortalanır
    property real uzakKayma: uzak ? Math.max(0, (width - toplamGenislik * uzakOlcek) / 2 - solBosluk) : 0
    Behavior on uzakKayma { NumberAnimation { duration: 400; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl } }
    function uzaklas(u) {
        if (u === uzak || ozellestir) return
        menu.kapat()
        secimiTemizle()
        if (u) kaydirici.contentX = 0
        uzak = u
    }

    // Başlangıç <-> Uygulamalar: içerik ve zemin birlikte dikey kayar (PVL eğrisi)
    property bool sayfaAnimasyon: true
    property real sayfaKonum: sayfa
    Behavior on sayfaKonum { enabled: pen.sayfaAnimasyon; NumberAnimation { duration: 600; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl } }

    // ------------------------------------------------------------------ menüler
    function kutucukMenusu(i) {
        var t = kutucuklar.get(i)
        var l = [{ metin: "Başlangıç ekranından ayır", eylem: function () { pen.ayir(i) } }]
        if (t.tur === "uygulama") {
            var sabit = ana.gorevCubugundaMi(t.kimlik)
            l.push({ metin: sabit ? "Görev çubuğundan ayır" : "Görev çubuğuna sabitle", eylem: function () { ana.gorevCubugunaSabitle(t.kimlik, !sabit) } })
            l.push({ metin: "Kaldır", eylem: function () { ana.kaldir(t.kimlik) } })
        }
        var genisOlur = ["metro-haberler.desktop", "metro-spor.desktop", "metro-finans.desktop", "metro-fotograflar.desktop", "metro-hava-durumu.desktop", "metro-takvim.desktop", "metro-muzik.desktop", "metro-video.desktop"].indexOf(t.kimlik) >= 0
        var boyutlar = t.tur === "uygulama" && !genisOlur ? [["kucuk", "Küçük"], ["orta", "Orta"]]
                     : [["kucuk", "Küçük"], ["orta", "Orta"], ["genis", "Geniş"], ["buyuk", "Büyük"]]
        if (t.tur === "ayarlar") boyutlar = [["kucuk", "Küçük"], ["orta", "Orta"]]
        l.push({ metin: "Yeniden boyutlandır", alt: boyutlar.map(function (b) {
            return { metin: b[1], isaretli: t.boyut === b[0], eylem: function () { pen.yenidenBoyutlandir(i, b[0]) } }
        }) })
        if (["hava", "takvim", "fotograflar"].indexOf(t.tur) >= 0 || ["metro-haberler.desktop", "metro-spor.desktop", "metro-finans.desktop"].indexOf(t.kimlik) >= 0)
            l.push({ metin: t.canli ? "Canlı kutucuğu kapat" : "Canlı kutucuğu aç", eylem: function () { kutucuklar.setProperty(i, "canli", !t.canli); pen.duzenKaydet() } })
        // Windows 8.1 Update masaüstü uygulaması kutucuğu: ayır, görev çubuğu, kaldır, boyut, dosya konumu
        // (atlama listesi ve "Yeni pencere" yalnızca görev çubuğunda)
        if (t.tur === "uygulama")
            l.push({ metin: "Dosya konumunu aç", eylem: function () { pen.kapat(); Uygulamalar.dosyaKonumunuAc(t.kimlik) } })
        return l
    }

}
