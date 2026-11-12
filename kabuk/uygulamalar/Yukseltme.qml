// Windows 8.1'e Yükseltme Yardımcısı — Windows 8.1 Kurulumu'nun (setup.exe) mor sihirbazı gibi:
// Uyumluluk denetleniyor → (gerekirse) kurulum medyası → Neyi saklamak istiyorsunuz? → ek seçenekler →
// Yüklemeye hazır → Windows 8.1 yükleniyor (yüzde, adımlar) → tamamlandı. Metinler ISO'daki w32uires.dll.mui,
// setupplatform.exe.mui ve setup_help_whattokeep.rtf'den. Root adımları tek bir Kullanıcı Hesabı Denetimi
// onayıyla (pkexec kur.sh --yukseltme-sistem).
import QtQuick

Item {
    id: yk
    readonly property string baslik: "Windows 8.1 Kurulumu"
    readonly property color zemin: "#4a2b8c"
    readonly property color cubukRengi: "#3a1f73"
    readonly property var solKomutlar: []
    readonly property var sagKomutlar: []

    readonly property string kaynak: {
        var k = Yardimci.ortamDegeri("METRO_KAYNAK")
        if (!k) k = Dosya.oku(Dosya.ev + "/.local/state/metrothemeplasma/kaynak").trim()
        return k
    }
    readonly property string atpYapilandirma: Dosya.ev + "/.config/plasma-io.gitgud.wackyideas.desktop-appletsrc"
    readonly property bool atpVar: Dosya.var(atpYapilandirma)
    readonly property bool winVar: Dosya.var(Dosya.veri + "/win/Windows/Resources/Themes/aero/aero.msstyles")
    readonly property bool metroVar: Dosya.var(Dosya.ev + "/.config/plasma-io.github.yyozcan.metroshell-appletsrc")

    property string sayfa: "denetim"       // denetim, medya, sakla, secenek, hazir, yukleniyor, bitti, hata
    property string sakla: "hepsi"         // hepsi, dosyalar, hicbiri
    property bool plymouth: true
    property bool sddm: true
    property bool varsayilanOturum: true
    property string iso: ""
    property var eksikler: []
    property var uyarilar: []
    property bool denetimBitti: false

    // ------------------------------------------------------------------ uyumluluk denetimi
    function denetle() {
        var e = [], u = []
        ;["cmake", "ninja", "git", "python3", "pkexec", "kwriteconfig6", "qdbus6"].forEach(function (p) { if (!Yardimci.programVar(p)) e.push(p) })
        if (!winVar && !Yardimci.programVar("7z")) e.push("7z (p7zip)")
        if (!Yardimci.programVar("qmake6")) u.push("qmake6 yok: Windows Hakkında (winver) derlenmeyecek")
        if (!Dosya.var("/usr/lib/libAeroQt.so.0")) u.push("libAeroQt yok (AUR: libaero-qt-git): Dosya Gezgini yerine Dolphin kullanılacak")
        if (!Dosya.var("/usr/lib/qt6/qml/aeroshell/taskmanager")) u.push("AeroThemePlasma'nın görev çubuğu motoru yok: Plasma'nın görev çubuğu kullanılacak")
        if (!Dosya.var(kaynak + "/kur.sh")) e.push("MetroThemePlasma kaynağı (" + (kaynak || "bulunamadı") + ")")
        eksikler = e; uyarilar = u
        if (!winVar) {
            var l = []
            ;[Dosya.ev + "/İndirilenler", Dosya.ev + "/Downloads", Dosya.ev + "/Masaüstü", Dosya.ev].forEach(function (d) {
                Yardimci.dosyalar(d, ["*.iso", "*.ISO"]).forEach(function (f) { if (/8\.1|win.*8|windows/i.test(f.ad)) l.push(f.yol) })
            })
            if (l.length && !iso) iso = l[0]
        }
        denetimBitti = true
    }
    Timer { interval: 900; running: yk.sayfa === "denetim" && !yk.denetimBitti; onTriggered: yk.denetle() }
    // sınama: METRO_SINAMA_KIP=sayfa:<ad> o sayfayı gösterir (kurulum çalıştırmaz)
    Timer { interval: 1500; running: SinamaKip.indexOf("sayfa:") === 0; onTriggered: yk.sayfa = SinamaKip.slice(6) }
    Timer { interval: 1500; running: SinamaKip === "kuru"; onTriggered: { yk.sayfa = "hazir"; yk.ileri() } }

    // ------------------------------------------------------------------ yükleme
    property var adimlar: []        // { ad, program, arg, durum: bekliyor|calisiyor|tamam|hata }
    property int adim: -1
    property int toplamAsama: 30
    property int asama: 0
    property string sonSatir: ""
    property var gunluk: []
    function yuklemeyiBaslat() {
        var k = kaynak + "/kur.sh", l = []
        if (!winVar) l.push({ ad: "Dosyalar kurulum için hazırlanıyor", program: "bash", arg: [k, "--win", iso] })
        else l.push({ ad: "Özellikler yükleniyor", program: "bash", arg: [k] })
        l.push({ ad: "Bilgisayar ayarlarınız uygulanıyor", program: "pkexec", arg: ["bash", k, "--yukseltme-sistem", plymouth ? "1" : "0", sddm ? "1" : "0", varsayilanOturum ? "1" : "0"] })
        if (sakla === "hepsi" && atpVar) l.push({ ad: "Windows Kurulumu öğelerinizi taşıyor", program: Dosya.ev + "/.local/bin/metro-yukselt", arg: ["--zorla"] })
        if (sakla === "hicbiri") l.push({ ad: "Windows 8.1 varsayılanları uygulanıyor", program: "sh", arg: ["-c", "cd \"$HOME/.config/metrothemeplasma\" 2>/dev/null && for f in baslangic.json ayarlar.ini; do [ -f \"$f\" ] && mv \"$f\" \"$f.yedek-$(date +%Y%m%d%H%M)\"; done; true"] })
        // sınama (METRO_SINAMA_KIP=kuru): komutlar yerine zararsız yankı; kurulum ve UAC çalışmaz
        if (SinamaKip === "kuru") l = l.map(function (a) { return { ad: a.ad, program: "sh", arg: ["-c", "echo '==> " + a.ad + "'; sleep 1; echo '==> bitti'"] } })
        adimlar = l.map(function (a) { a.durum = "bekliyor"; return a })
        var t = parseInt(Yardimci.cikti("grep", ["-c", "^echo \"==>", k])) || 25
        toplamAsama = t + 6
        asama = 0; gunluk = []
        sayfa = "yukleniyor"
        sonraki()
    }
    function sonraki() {
        adim++
        if (adim >= adimlar.length) { sayfa = "bitti"; return }
        var a = adimlar.slice(); a[adim].durum = "calisiyor"; adimlar = a
        if (!Yardimci.surecBaslat(adimlar[adim].program, adimlar[adim].arg, kaynak)) { hata("başlatılamadı"); return }
    }
    function hata(neden) {
        var a = adimlar.slice(); if (adim >= 0 && adim < a.length) a[adim].durum = "hata"; adimlar = a
        sonSatir = neden
        sayfa = "hata"
    }
    Connections {
        target: Yardimci
        function onSurecSatiri(s) {
            if (s === "") return
            var g = yk.gunluk.slice(-200); g.push(s); yk.gunluk = g
            if (s.indexOf("==>") === 0) { yk.asama++; yk.sonSatir = s.slice(4) }
        }
        function onSurecBitti(kod) {
            if (yk.sayfa !== "yukleniyor") return
            if (kod !== 0) {
                yk.hata(kod === 126 || kod === 127 ? "Kullanıcı Hesabı Denetimi onayı verilmedi" : "çıkış kodu " + kod)
                return
            }
            var a = yk.adimlar.slice(); a[yk.adim].durum = "tamam"; yk.adimlar = a
            yk.asama += 2
            yk.sonraki()
        }
    }
    readonly property int yuzde: sayfa === "bitti" ? 100 : Math.min(99, Math.round(asama / toplamAsama * 100))

    // ------------------------------------------------------------------ görünüm
    Rectangle { anchors.fill: parent; color: yk.zemin }
    Text { x: 40; y: 24; text: "Windows 8.1 Kurulumu"; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.pixelSize: 15 }

    Item {
        id: govde
        x: 80; y: 80; width: parent.width - 160; height: parent.height - 170

        // ---- uyumluluk
        Column {
            visible: yk.sayfa === "denetim"
            spacing: 14; width: parent.width
            Text { text: yk.denetimBitti ? "Uyumluluk denetimi tamamlandı" : "Uyumluluk denetleniyor"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
            Ilerleme { visible: !yk.denetimBitti }
            Column {
                visible: yk.denetimBitti; spacing: 10; width: parent.width
                Satir { glif: yk.atpVar ? "" : ""; metin: yk.atpVar ? "AeroThemePlasma (Windows 7) bulundu: Windows 8.1'e yükseltilebilir. Windows 7 oturumunuz olduğu gibi kalır."
                                                                          : "AeroThemePlasma bulunamadı: Windows 8.1 temiz olarak yüklenecek." }
                Satir { glif: yk.winVar ? "" : ""; metin: yk.winVar ? "Windows 8.1 dosyaları daha önce içe aktarılmış." : "Windows 8.1 kurulum medyası (ISO) gerekli." }
                Satir { visible: yk.metroVar; glif: ""; metin: "MetroThemePlasma zaten kurulu: güncellenecek, ayarlarınız korunacak." }
                Repeater { model: yk.eksikler; delegate: Satir { required property string modelData; glif: ""; metin: "Eksik: " + modelData } }
                Repeater { model: yk.uyarilar; delegate: Satir { required property string modelData; glif: ""; metin: modelData } }
            }
        }

        // ---- kurulum medyası
        Column {
            visible: yk.sayfa === "medya"
            spacing: 14; width: parent.width
            Text { text: "Windows 8.1 kurulum medyasını seçin"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: "Görseller, sesler ve yazı tipleri kendi Windows 8.1 kopyanızdan alınır; depoda Microsoft dosyası yoktur. ISO dosyasının ya da install.wim'in yolunu yazın."
                   color: Qt.rgba(1, 1, 1, 0.85); font.family: "Segoe UI"; font.pixelSize: 15 }
            Rectangle {
                width: parent.width; height: 34; color: "white"
                TextInput { id: isoKutusu; anchors.fill: parent; anchors.margins: 7; font.family: "Segoe UI"; font.pixelSize: 15; clip: true; text: yk.iso; onTextChanged: yk.iso = text }
            }
            Text { visible: yk.iso !== "" && !Dosya.var(yk.iso); text: "Bu dosya bulunamadı."; color: "#ffd0d0"; font.family: "Segoe UI"; font.pixelSize: 14 }
        }

        // ---- neyi saklamak istiyorsunuz
        Column {
            visible: yk.sayfa === "sakla"
            spacing: 18; width: parent.width
            Text { text: "Neyi saklamak istiyorsunuz?"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
            Secenek { deger: "hepsi"; etkin: yk.atpVar; baslik: "Windows ayarlarını, kişisel dosyaları ve uygulamaları sakla"
                      aciklama: "Görev çubuğuna ve Başlat menüsüne sabitlediğiniz programlar, masaüstü arka planınız ve kişisel dosyalarınız korunur." }
            Secenek { deger: "dosyalar"; baslik: "Yalnızca kişisel dosyaları sakla"
                      aciklama: "Windows 8.1 varsayılan düzeniyle başlar; Belgeler ve Masaüstü gibi Kullanıcı klasörünüzdeki dosyalar korunur." }
            Secenek { deger: "hicbiri"; baslik: "Hiçbir şey"
                      aciklama: "Önceki Metro ayarları yedeklenip Windows 8.1 varsayılanlarına dönülür. Kişisel dosyalarınız silinmez." }
        }

        // ---- ek seçenekler
        Column {
            visible: yk.sayfa === "secenek"
            spacing: 18; width: parent.width
            Text { text: "Ek seçenekler"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
            Onay { secili: yk.varsayilanOturum; onDegisti: d => yk.varsayilanOturum = d; baslik: "Oturum açarken Windows 8.1'i varsayılan yap"
                   aciklama: "Oturum açma ekranında MetroThemePlasma seçili gelir; Windows 7 oturumu listede kalır." }
            Onay { secili: yk.sddm; onDegisti: d => yk.sddm = d; baslik: "Windows 8.1 oturum açma ekranını kullan"
                   aciklama: "Kilit ekranı resmi ve Başlangıç renkleriyle Windows 8.1 oturum açma ekranı." }
            Onay { secili: yk.plymouth; onDegisti: d => yk.plymouth = d; baslik: "Windows 8.1 açılış ekranını kullan"
                   aciklama: "Bilgisayar açılırken Windows logosu ve dönen noktalar (initramfs yeniden oluşturulur, birkaç dakika sürebilir)." }
        }

        // ---- yüklemeye hazır
        Column {
            visible: yk.sayfa === "hazir"
            spacing: 14; width: parent.width
            Text { text: "Yüklemeye hazır"; color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34 }
            Text { text: "Şu seçenekleri yaptınız:"; color: Qt.rgba(1, 1, 1, 0.85); font.family: "Segoe UI"; font.pixelSize: 15 }
            Satir { glif: ""; metin: yk.atpVar ? "Windows 7'den (AeroThemePlasma) Windows 8.1'e yükselt" : "Windows 8.1'i yükle" }
            Satir { glif: ""; metin: ({ hepsi: "Windows ayarlarını, kişisel dosyaları ve uygulamaları sakla", dosyalar: "Yalnızca kişisel dosyaları sakla", hicbiri: "Hiçbir şey saklama" })[yk.sakla] }
            Satir { visible: yk.varsayilanOturum; glif: ""; metin: "Oturum açarken Windows 8.1'i varsayılan yap" }
            Satir { visible: yk.sddm; glif: ""; metin: "Windows 8.1 oturum açma ekranı" }
            Satir { visible: yk.plymouth; glif: ""; metin: "Windows 8.1 açılış ekranı" }
            Satir { glif: "\ue10b"; metin: "Kapatırken konsol duyuruları gizlenir; Plasma güncellendikçe Windows 8.1 de kendiliğinden güncellenir" }
            Text { width: parent.width; wrapMode: Text.WordWrap; topPadding: 10
                   text: "Yükle'ye tıkladığınızda yönetici izni istenir (Kullanıcı Hesabı Denetimi). Kurulum sırasında bilgisayarı kullanmaya devam edebilirsiniz."
                   color: Qt.rgba(1, 1, 1, 0.85); font.family: "Segoe UI"; font.pixelSize: 15 }
        }

        // ---- yükleniyor
        Column {
            visible: yk.sayfa === "yukleniyor" || yk.sayfa === "bitti" || yk.sayfa === "hata"
            spacing: 12; width: parent.width
            Text {
                text: yk.sayfa === "bitti" ? "Windows 8.1 yüklendi" : (yk.sayfa === "hata" ? "Windows 8.1 yüklenemedi" : (yk.atpVar ? "Windows yükseltiliyor" : "Windows yükleniyor"))
                color: "white"; font.family: "Segoe UI"; font.weight: Font.Light; font.pixelSize: 34
            }
            Text { text: yk.sayfa === "yukleniyor" ? "%" + yk.yuzde + " tamamlandı" : ""; visible: text !== ""; color: "white"; font.family: "Segoe UI"; font.pixelSize: 20 }
            Ilerleme { visible: yk.sayfa === "yukleniyor" }
            Item { width: 1; height: 6 }
            Repeater {
                model: yk.adimlar
                delegate: Row {
                    required property var modelData
                    spacing: 12
                    Text { width: 24; text: ({ tamam: "", hata: "", calisiyor: "▸", bekliyor: "" })[modelData.durum]
                           font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: "white" }
                    Text { text: modelData.ad; color: modelData.durum === "bekliyor" ? Qt.rgba(1, 1, 1, 0.55) : "white"
                           font.family: "Segoe UI"; font.weight: modelData.durum === "calisiyor" ? 600 : 400; font.pixelSize: 17 }
                }
            }
            Text {
                visible: yk.sayfa === "yukleniyor"; width: parent.width; elide: Text.ElideRight; topPadding: 8
                text: yk.sonSatir; color: Qt.rgba(1, 1, 1, 0.7); font.family: "Segoe UI"; font.pixelSize: 14
            }
            Text {
                visible: yk.sayfa === "yukleniyor"; width: parent.width; wrapMode: Text.WordWrap; topPadding: 14
                text: "Bilgisayarınızı kapatmayın. Bu işlem biraz zaman alabilir."; color: Qt.rgba(1, 1, 1, 0.85); font.family: "Segoe UI"; font.pixelSize: 15
            }
            Text {
                visible: yk.sayfa === "bitti"; width: parent.width; wrapMode: Text.WordWrap; topPadding: 14
                text: "Oturumu kapatın ve oturum açma ekranında MetroThemePlasma (Wayland) oturumunu seçin. İlk oturum açışınızda Windows 8.1 sizi \"Merhaba\" ile karşılar. Bundan sonra Plasma güncellendikçe Windows 8.1 de kendiliğinden güncellenir."
                color: "white"; font.family: "Segoe UI"; font.pixelSize: 16
            }
            Column {
                visible: yk.sayfa === "hata"; width: parent.width; spacing: 6
                Text { width: parent.width; wrapMode: Text.WordWrap; text: "Neden: " + yk.sonSatir + ". Kurulu sürüm değiştirilmedi; ayrıntılar aşağıda."; color: "white"; font.family: "Segoe UI"; font.pixelSize: 15 }
                Rectangle {
                    width: parent.width; height: 180; color: Qt.rgba(0, 0, 0, 0.3)
                    Text { anchors.fill: parent; anchors.margins: 8; text: yk.gunluk.slice(-10).join("\n"); color: "#e0e0e0"; font.family: "monospace"; font.pixelSize: 12; elide: Text.ElideLeft; clip: true }
                }
            }
        }
    }

    // ------------------------------------------------------------------ alt düğmeler (Geri / İleri / Yükle)
    Row {
        anchors.right: parent.right; anchors.rightMargin: 40
        anchors.bottom: parent.bottom; anchors.bottomMargin: 30
        spacing: 12
        Dugme { metin: "Geri"; visible: ["medya", "sakla", "secenek", "hazir"].indexOf(yk.sayfa) >= 0; onTiklandi: yk.geri() }
        Dugme {
            metin: yk.sayfa === "hazir" ? "Yükle" : (yk.sayfa === "bitti" ? "Oturumu kapat" : (yk.sayfa === "hata" ? "Yeniden dene" : "İleri"))
            visible: yk.sayfa !== "yukleniyor"
            etkin: (yk.sayfa !== "denetim" || (yk.denetimBitti && yk.eksikler.length === 0)) && (yk.sayfa !== "medya" || Dosya.var(yk.iso))
            vurgulu: true
            onTiklandi: yk.ileri()
        }
        Dugme { metin: yk.sayfa === "bitti" ? "Daha sonra" : "İptal"; visible: yk.sayfa !== "yukleniyor"; onTiklandi: Qt.quit() }
    }
    function ileri() {
        switch (sayfa) {
        case "denetim": sayfa = winVar ? "sakla" : "medya"; if (!atpVar) sakla = metroVar ? "dosyalar" : "dosyalar"; break
        case "medya": sayfa = "sakla"; break
        case "sakla": sayfa = "secenek"; break
        case "secenek": sayfa = "hazir"; break
        case "hazir": adim = -1; yuklemeyiBaslat(); break
        case "bitti": Yardimci.calistir("qdbus6", ["org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logout"]); break
        case "hata": adim = -1; yuklemeyiBaslat(); break
        }
    }
    function geri() {
        sayfa = ({ medya: "denetim", sakla: winVar ? "denetim" : "medya", secenek: "sakla", hazir: "secenek" })[sayfa] || sayfa
    }

    // ------------------------------------------------------------------ bileşenler
    component Satir: Row {
        property string glif
        property string metin
        spacing: 12
        Text { width: 24; text: parent.glif; font.family: "Segoe UI Symbol"; font.pixelSize: 15; color: "white" }
        Text { width: govde.width - 40; wrapMode: Text.WordWrap; text: parent.metin; color: "white"; font.family: "Segoe UI"; font.pixelSize: 16 }
    }
    component Secenek: Item {
        id: sc
        property string deger
        property string baslik
        property string aciklama
        property bool etkin: true
        width: govde.width; height: sa.implicitHeight + 8
        opacity: etkin ? 1 : 0.45
        Rectangle {
            y: 3; width: 20; height: 20; radius: 10; color: "transparent"; border.color: "white"; border.width: 2
            Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "white"; visible: yk.sakla === sc.deger }
        }
        Column {
            id: sa
            x: 34; width: parent.width - 34; spacing: 3
            Text { width: parent.width; wrapMode: Text.WordWrap; text: sc.baslik; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 17 }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: sc.aciklama; color: Qt.rgba(1, 1, 1, 0.8); font.family: "Segoe UI"; font.pixelSize: 14 }
        }
        MouseArea { anchors.fill: parent; enabled: sc.etkin; onClicked: yk.sakla = sc.deger }
    }
    component Onay: Item {
        id: on
        property bool secili
        property string baslik
        property string aciklama
        signal degisti(bool d)
        width: govde.width; height: oa.implicitHeight + 8
        Rectangle {
            y: 3; width: 20; height: 20; color: "transparent"; border.color: "white"; border.width: 2
            Text { anchors.centerIn: parent; visible: on.secili; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 13; color: "white" }
        }
        Column {
            id: oa
            x: 34; width: parent.width - 34; spacing: 3
            Text { width: parent.width; wrapMode: Text.WordWrap; text: on.baslik; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 17 }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: on.aciklama; color: Qt.rgba(1, 1, 1, 0.8); font.family: "Segoe UI"; font.pixelSize: 14 }
        }
        MouseArea { anchors.fill: parent; onClicked: on.degisti(!on.secili) }
    }
    component Dugme: Rectangle {
        id: d
        property string metin
        property bool vurgulu: false
        property bool etkin: true
        signal tiklandi()
        width: Math.max(110, dt.implicitWidth + 36); height: 38
        opacity: etkin ? 1 : 0.4
        color: dm.pressed ? "white" : (vurgulu ? Qt.rgba(1, 1, 1, dm.containsMouse ? 0.3 : 0.18) : (dm.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"))
        border.color: "white"; border.width: 2
        Text { id: dt; anchors.centerIn: parent; text: d.metin; color: dm.pressed ? yk.zemin : "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; enabled: d.etkin; onClicked: d.tiklandi() }
    }
    // Windows 8 belirsiz ilerleme: soldan sağa akan beş nokta
    component Ilerleme: Item {
        width: govde.width; height: 10
        Repeater {
            model: 5
            delegate: Rectangle {
                required property int index
                width: 6; height: 6; radius: 3; color: "white"; y: 2
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 160 }
                    NumberAnimation { from: -20; to: govde.width * 0.45; duration: 900; easing.type: Easing.OutCubic }
                    NumberAnimation { to: govde.width * 0.55; duration: 900 }
                    NumberAnimation { to: govde.width + 20; duration: 900; easing.type: Easing.InCubic }
                    PauseAnimation { duration: (4 - index) * 160 + 400 }
                }
            }
        }
    }
}
