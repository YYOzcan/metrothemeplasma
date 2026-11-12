// metro-kabuk kökü: pencereleri oluşturur, DBus/kısayol isteklerini dağıtır
import QtQuick

QtObject {
    id: ana

    property Tema tema: Tema {}

    property BaslangicEkrani baslangic: BaslangicEkrani { tema: ana.tema; ana: ana }
    property Tilsimlar tilsimlar: Tilsimlar { tema: ana.tema; ana: ana }
    property SaatPaneli saat: SaatPaneli { tema: ana.tema }
    property BolmePenceresi bolme: BolmePenceresi { tema: ana.tema; ana: ana }
    property GucMenusu hizliMenu: GucMenusu { ana: ana }
    property SolGecis gecis: SolGecis { ana: ana }
    property EkranFlasi flas: EkranFlasi {}
    property BilgisayarAyarlari pcAyarlar: BilgisayarAyarlari { tema: ana.tema; ana: ana }
    property GorevYoneticisi gorevYoneticisi: GorevYoneticisi { ana: ana }

    // ------------------------------------------------------------------ Başlangıç
    function baslangicAc(uygulamalar, giris) {
        tilsimKapat(); bolmeKapat(); hizliMenu.kapat()
        baslangic.ac(uygulamalar, giris)
        Kabuk.setBaslangicAcik(true)
    }
    function baslangicKapat(hemen) {
        baslangic.kapat(hemen)
        Kabuk.setBaslangicAcik(false)
    }
    function baslangicDegistir() {
        if (bolme.acik || tilsimlar.acik) { hepsiniKapat(); if (!baslangic.acik) return }
        if (baslangic.acik) baslangicKapat(); else baslangicAc(false)
    }

    // ------------------------------------------------------------------ tılsımlar
    function tilsimAc() {
        if (bolme.acik) bolmeKapat()
        hizliMenu.kapat()
        tilsimlar.tamAc()
        saat.goster()
    }
    function tilsimIpucu(kose) {
        if (bolme.acik || tilsimlar.acik) return
        if (!tema.baslangic.koseIpucu) return
        tilsimlar.goster(true, kose)
    }
    function tilsimKapat() {
        tilsimlar.kapat()
        saat.kapat()
    }
    function tilsimEylem(e) {
        switch (e) {
        case "baslangic":
            tilsimKapat()
            baslangicDegistir()
            break
        case "ara": aramaAc("", ""); break
        case "paylas": bolmeAc("paylas"); break
        case "aygitlar": bolmeAc("aygitlar"); break
        case "ayarlar": bolmeAc("ayarlar"); break
        }
    }

    // ------------------------------------------------------------------ bölmeler
    function bolmeAc(t) {
        tilsimKapat()
        hizliMenu.kapat()
        bolme.ac(t, baslangic.acik ? "baslangic" : "masaustu")
        if (t === "ayarlar") saat.kapat()
    }
    function bolmeKapat() {
        bolme.kapat()
        tilsimKapat()
        if (baslangic.acik) baslangic.requestActivate()
    }
    function aramaAc(metin, kapsam) {
        bolme.aramaMetni = metin
        bolme.aramaKapsami = kapsam || ""
        bolmeAc("ara")
    }
    function hepsiniKapat() {
        bolme.kapat()
        tilsimKapat()
        hizliMenu.kapat()
        baslangicKapat()
    }

    // ------------------------------------------------------------------ eylemler
    function gucOgeleri() {
        return [
            { metin: "Uyku", eylem: function () { ana.hepsiniKapat(); Sistem.uyku() } },
            { metin: "Kapat", eylem: function () { ana.hepsiniKapat(); Sistem.kapat() } },
            { metin: "Yeniden başlat", eylem: function () { ana.hepsiniKapat(); Sistem.yenidenBaslat() } }
        ]
    }
    function ilkProgram(adaylar) {
        for (var i = 0; i < adaylar.length; i++) if (Sistem.programVar(adaylar[i].split(" ")[0])) return adaylar[i]
        return ""
    }
    function kutucukCalistir(tur, kimlik) {
        switch (tur) {
        case "uygulama": Uygulamalar.baslat(kimlik); break
        case "masaustu": break
        case "ayarlar": bilgisayarAyarlari(""); break
        case "takvim": {
            var t = Uygulamalar.bul(["org.kde.merkuro.calendar.desktop", "org.kde.korganizer.desktop", "org.gnome.Calendar.desktop"])
            if (t) Uygulamalar.baslat(t); else Sistem.ayarAc("kcm_clock")
            break
        }
        case "hava": Sistem.ac("https://wttr.in/?lang=tr"); break
        case "fotograflar": {
            var g = Uygulamalar.bul(["org.kde.gwenview.desktop", "org.gnome.Loupe.desktop", "ristretto.desktop"])
            if (g) Uygulamalar.dosyaIleBaslat(g, [Dosya.ev + "/Resimler"]); else Sistem.ac(Dosya.ev + "/Resimler")
            break
        }
        case "saat": Sistem.ayarAc("kcm_clock"); break
        }
        baslangicKapat()
    }
    // baslangictan: Başlangıç ekranı açılış ekranı geçişini bitirince kendisi kapanır
    function bilgisayarAyarlari(sayfa, baslangictan) {
        if (baslangictan) { bolme.kapat(); tilsimKapat(); hizliMenu.kapat() }
        else hepsiniKapat()
        pcAyarlar.ac(sayfa || "")
    }
    function ayarEylem(a) {
        switch (a) {
        case "denetim": hepsiniKapat(); Sistem.calistir(ilkProgram(["metro-denetim", "systemsettings"])); break
        case "kisisellestirme": bilgisayarAyarlari("renk"); break
        case "bilgi": hepsiniKapat(); Sistem.calistir(ilkProgram(["kinfocenter kcm_about-distro", "systemsettings kcm_about-distro"])); break
        case "yardim": hepsiniKapat(); Sistem.calistir(ilkProgram(["khelpcenter", "xdg-open https://userbase.kde.org"])); break
        case "kisisellestir": bolme.ac("kisisellestir"); break
        case "kutucuklar": bolme.ac("kutucuklar"); break
        }
    }
    function hizliEylem(e) {
        hepsiniKapat()
        var konsol = ilkProgram(["konsole", "kgx", "kitty", "alacritty", "xterm"])
        switch (e) {
        case "programlar": Sistem.calistir(ilkProgram(["plasma-discover --mode installed", "octopi", "pamac-manager", "systemsettings"])); break
        case "mobility": Sistem.ayarAc("kcm_powerdevilprofilesconfig"); break
        case "guc": Sistem.ayarAc("kcm_powerdevilprofilesconfig"); break
        case "olay": Sistem.calistir(ilkProgram(["ksystemlog", "gnome-logs", konsol + " -e journalctl -b"])); break
        case "sistem": Sistem.calistir(ilkProgram(["kinfocenter kcm_about-distro", "systemsettings kcm_about-distro"])); break
        case "aygit": Sistem.calistir(ilkProgram(["kinfocenter kcm_pci", "systemsettings"])); break
        case "ag": Sistem.ayarAc("kcm_networkmanagement"); break
        case "disk": Sistem.calistir(ilkProgram(["partitionmanager", "gnome-disks", "gparted"])); break
        case "bilgisayar": Sistem.calistir(ilkProgram(["plasma-systemmonitor", "kinfocenter"])); break
        case "komut": Sistem.calistir(konsol); break
        case "komutYonetici": Sistem.calistir(konsol + " -e sudo -i"); break
        case "gorev": gorevYoneticisi.ac(); break
        case "gorevAyrinti": Sistem.calistir(ilkProgram(["plasma-systemmonitor", "ksysguard"])); break
        case "denetim": Sistem.calistir(ilkProgram(["metro-denetim", "systemsettings"])); break
        case "gezgin": Sistem.calistir(ilkProgram(["dolphin", "nautilus", "thunar"])); break
        case "ara": aramaAc("", ""); break
        case "calistir": Sistem.calistir(ilkProgram(["metro-calistir", "krunner"])); break
        case "oturum": Sistem.oturumuKapat(); break
        case "uyku": Sistem.uyku(); break
        case "kapat": Sistem.kapat(); break
        case "yeniden": Sistem.yenidenBaslat(); break
        case "masaustu": Sistem.komutCiktisi("qdbus6", ["org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component.invokeShortcut", "Show Desktop"]); break
        }
    }
    function yansit(kip) {
        var j = null
        try { j = JSON.parse(Sistem.komutCiktisi("kscreen-doctor", ["-j"], 4000)) } catch (e) { return }
        var cikislar = (j.outputs || []).filter(function (o) { return o.connected })
        if (cikislar.length < 2) return
        var birincil = cikislar.filter(function (o) { return o.priority === 1 })[0] || cikislar[0]
        var diger = cikislar.filter(function (o) { return o !== birincil })
        var a = []
        if (kip === "bilgisayar") {
            a.push("output." + birincil.name + ".enable")
            diger.forEach(function (o) { a.push("output." + o.name + ".disable") })
        } else if (kip === "ikinci") {
            diger.forEach(function (o) { a.push("output." + o.name + ".enable") })
            a.push("output." + birincil.name + ".disable")
        } else if (kip === "yinele") {
            a.push("output." + birincil.name + ".enable")
            diger.forEach(function (o) { a.push("output." + o.name + ".enable"); a.push("output." + o.name + ".mirror." + birincil.name) })
        } else {
            var x = 0
            cikislar.forEach(function (o) {
                a.push("output." + o.name + ".enable")
                a.push("output." + o.name + ".mirror.none")
                a.push("output." + o.name + ".position." + x + ",0")
                var m = (o.modes || []).filter(function (md) { return md.id === o.currentModeId })[0]
                x += m ? Math.round(m.size.width / (o.scale || 1)) : 1920
            })
        }
        Sistem.komutCiktisi("kscreen-doctor", a, 8000)
    }

    // görev çubuğu sabitleme: Plasma kabuğundaki görev yöneticisinin "launchers" ayarı
    function gorevCubuguBetik(govde) {
        return "var sonuc = [];" +
               "panels().forEach(function (p) { p.widgets().forEach(function (w) {" +
               " if (w.type.indexOf('taskmanager') >= 0 || w.type.indexOf('seventasks') >= 0 || w.type.indexOf('icontasks') >= 0 || w.type.indexOf('metrogorevler') >= 0) {" +
               "  w.currentConfigGroup = ['General']; var l = w.readConfig('launchers', ''); if (typeof l === 'string') l = l === '' ? [] : l.split(',');" +
               govde + " } }) }); print(sonuc.join('|'));"
    }
    function gorevCubugundaMi(kimlik) {
        var c = Sistem.komutCiktisi("qdbus6", ["org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript",
                                               gorevCubuguBetik("sonuc.push(l.join(','));")], 2000)
        return c.indexOf("applications:" + kimlik) >= 0
    }
    function gorevCubugunaSabitle(kimlik, sabitle) {
        var oge = "applications:" + kimlik
        var govde = sabitle
            ? "if (l.indexOf('" + oge + "') < 0) { l.push('" + oge + "'); w.writeConfig('launchers', l); }"
            : "l = l.filter(function (x) { return x !== '" + oge + "' }); w.writeConfig('launchers', l);"
        Sistem.komutCiktisi("qdbus6", ["org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", gorevCubuguBetik(govde)], 3000)
    }
    function kaldir(kimlik) {
        hepsiniKapat()
        Sistem.calistir(ilkProgram(["plasma-discover --mode installed", "octopi", "pamac-manager", "systemsettings"]))
    }
    function renkDegisti() {
        // kilit ekranı, oturum açma ve pencere renklerini güncelle
        if (Sistem.programVar("metro-renk")) Sistem.calistir("metro-renk uygula")
    }
    function ekranGoruntusu() {
        flas.parla()
        var dizin = Dosya.ev + "/Resimler/Ekran Görüntüleri"
        var n = 1
        while (Dosya.var(dizin + "/Ekran Görüntüsü (" + n + ").png")) n++
        Sistem.komutCiktisi("mkdir", ["-p", dizin])
        Sistem.calistir("spectacle -b -n -f -o \"" + dizin + "/Ekran Görüntüsü (" + n + ").png\"")
    }

    // ------------------------------------------------------------------ DBus / kısayollar
    property Connections kabukBaglanti: Connections {
        target: Kabuk
        function onBaslangicIste(kip) {
            if (kip === 0) ana.baslangicDegistir()
            else if (kip === 1) ana.baslangicAc(false)
            else if (kip === 2) ana.baslangicKapat()
            else ana.baslangicAc(true)
        }
        function onTilsimIste() { if (ana.tilsimlar.acik && !ana.tilsimlar.ipucu) ana.tilsimKapat(); else ana.tilsimAc() }
        function onTilsimIpucuIste(kose) { ana.tilsimIpucu(kose) }
        function onAraIste(kapsam) { ana.aramaAc("", kapsam) }
        function onAyarlarIste() { ana.bolmeAc("ayarlar") }
        function onAygitlarIste() { ana.bolmeAc("aygitlar") }
        function onPaylasIste() { ana.bolmeAc("paylas") }
        function onGucMenusuIste(x, y) {
            if (ana.hizliMenu.acik) { ana.hizliMenu.kapat(); return }
            ana.bolme.kapat(); ana.tilsimKapat()
            ana.hizliMenu.ac(x, y)
        }
        function onGecisIste() { if (ana.gecis.acik) ana.gecis.ileri(); else ana.gecis.ac() }
        function onSolUstKoseIste() { if (ana.tema.baslangic.solUstGecis) ana.gecis.ac(true) }
        function onSolAltKoseIste() { ana.baslangicDegistir() }
        function onEkranGoruntusuIste() { ana.ekranGoruntusu() }
        function onKisisellestirIste() { ana.bolme.ac("kisisellestir", "baslangic") }
        function onBilgisayarAyarlariIste(sayfa) { ana.bilgisayarAyarlari(sayfa) }
        function onCalistirIste() { ana.hizliEylem("calistir") }
        function onAraMetinIste(metin) { ana.aramaAc(metin, "") }
        function onGorevYoneticisiIste() { ana.hizliEylem("gorev") }
        function onSabitleIste(yol) {
            // kurulu uygulamanın .desktop'ı ise kimliğiyle, değilse yoluyla (masaüstündeki bağlantılar)
            var b = Uygulamalar.bilgi(yol)
            if (!b.kimlik) return
            var kimlik = b.kimlik
            // masaüstündeki kopya (ör. ~/Masaüstü/steam.desktop): aynı adla kurulu uygulama varsa onu sabitle
            if (kimlik.indexOf("/") >= 0) {
                var kurulu = Uygulamalar.bul([kimlik.substring(kimlik.lastIndexOf("/") + 1)])
                if (kurulu) kimlik = kurulu
            }
            ana.baslangic.sabitle(kimlik)
        }
        function onBolmeIste(tur) {
            // aynı bölme açıkken yeniden istenirse kapat (tepsi simgesine ikinci tıklama)
            if (ana.bolme.acik && ana.bolme.tur === tur) ana.bolmeKapat()
            else ana.bolmeAc(tur)
        }
    }

    property Timer girisBekle: Timer {
        property int sayac: 0
        interval: 250; repeat: true
        onTriggered: {
            sayac++
            var acilisVar = Sistem.komutCiktisi("pgrep", ["-u", Sistem.kullanici, "-x", "ksplashqml"], 1000).trim() !== ""
            if (!acilisVar || sayac > 60) {
                stop()
                if (!ana.baslangic.acik) ana.baslangicAc(false, true)
            }
        }
    }
    Component.onCompleted: {
        // oturum açılışında Başlangıç ekranı (Windows 8.1)
        // (OturumGirisi: bu oturumda ilk çalıştırma; çökme sonrası yeniden başlatmada yeniden açılmaz)
        // açılış ekranı ("Hoş geldiniz", ksplashqml) kapanana kadar bekle; yoksa animasyon arkada kalır
        if (OturumGirisi && tema.baslangic.giristeBaslangic) girisBekle.start()
    }
}
