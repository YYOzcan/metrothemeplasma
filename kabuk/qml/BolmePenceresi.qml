// Sağdan kayan tılsım bölmeleri: Ayarlar, Ara, Paylaş, Aygıtlar, Kişiselleştir, Kutucuklar, Ağlar, Yansıt
import QtQuick
import QtQuick.Window
import org.kde.plasma.private.volume
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kitemmodels as KItemModels
import Metro

Window {
    id: pen
    property var tema
    property var ana
    property bool acik: false
    property string tur: "ayarlar"
    property string baglam: "masaustu"     // masaustu ya da baslangic (Ayarlar bölmesinin içeriği)
    property var gecmis: []
    property real ilerleme: 0
    readonly property int genislik: 346
    width: genislik
    height: Screen.height
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Bölme"

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 1 | 2 | 8, 1, -1, "metro-bolme")

    function ac(t, baglamAdi) {
        kapanis.stop()
        if (baglamAdi) baglam = baglamAdi
        if (acik && tur !== t) gecmis = gecmis.concat([tur])
        else if (!acik) gecmis = []
        tur = t
        if (!acik) {
            acik = true
            visible = true
            ilerleme = 0
            acilis.restart()
        }
        requestActivate()
        kok.forceActiveFocus()
    }
    function geri() {
        if (gecmis.length) { tur = gecmis[gecmis.length - 1]; gecmis = gecmis.slice(0, -1) }
        else ana.bolmeKapat()
    }
    function kapat() {
        if (!acik) return
        acik = false
        acilis.stop()
        kapanis.restart()
    }
    NumberAnimation { id: acilis; target: pen; property: "ilerleme"; to: 1; duration: 420; easing.type: Easing.OutQuint }
    SequentialAnimation {
        id: kapanis
        NumberAnimation { target: pen; property: "ilerleme"; to: 0; duration: 180; easing.type: Easing.InQuad }
        ScriptAction { script: pen.visible = false }
    }
    onActiveChanged: if (!active && acik && !altMenu.acik) closeTimer.restart()
    Timer { id: closeTimer; interval: 120; onTriggered: if (!pen.active && pen.acik) pen.ana.bolmeKapat() }

    Item {
        id: kok
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: pen.geri()
        transform: Translate { x: (1 - pen.ilerleme) * pen.genislik }

        Rectangle {
            anchors.fill: parent
            color: pen.tema.arkaPlan
            Rectangle { width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.12) }
        }

        // başlık: geri düğmesi + bölme adı
        Row {
            id: baslik
            x: 40; y: 40
            spacing: 14
            DaireDugme {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                boyut: 30; glif: ""; glifOlcek: 0.5
                onTiklandi: pen.geri()
            }
            Text {
                text: ({ ayarlar: "Ayarlar", ara: "Ara", paylas: "Paylaş", aygitlar: "Aygıtlar", kisisellestir: "Kişiselleştir",
                         kutucuklar: "Kutucuklar", aglar: "Ağlar", yansit: "Yansıt", yazdir: "Yazdır", yurut: "Yürüt",
                         yardim: "Yardım", bilgi: "Bilgi" })[pen.tur] || ""
                color: "white"
                font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 38
            }
        }

        Loader {
            id: icerik
            x: 40; y: 120
            width: pen.genislik - 80
            height: pen.height - y - 20
            sourceComponent: ({ ayarlar: ayarlarBolmesi, ara: araBolmesi, paylas: paylasBolmesi, aygitlar: aygitlarBolmesi,
                                kisisellestir: kisisellestirBolmesi, kutucuklar: kutucuklarBolmesi, aglar: aglarBolmesi,
                                yansit: yansitBolmesi, yazdir: mesajBolmesi, yurut: mesajBolmesi })[pen.tur] || null
            opacity: 1
            onSourceComponentChanged: girisAnim.restart()
            NumberAnimation { id: girisAnim; target: icerik; property: "x"; from: 80; to: 40; duration: 320; easing.type: Easing.OutQuint }
        }

        MetroMenu { id: altMenu }
    }

    // ================================================================== Ayarlar
    Component {
        id: ayarlarBolmesi
        Item {
            id: ab
            Column {
                width: parent.width
                spacing: 0
                Text {
                    text: pen.baglam === "baslangic" ? "Başlangıç" : "Masaüstü"
                    color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15
                    bottomPadding: 10
                }
                Repeater {
                    model: pen.baglam === "baslangic"
                        ? [["Kişiselleştir", "kisisellestir"], ["Kutucuklar", "kutucuklar"], ["Yardım", "yardim"]]
                        : [["Denetim Masası", "denetim"], ["Kişiselleştirme", "kisisellestirme"], ["Bilgisayar bilgileri", "bilgi"], ["Yardım", "yardim"]]
                    delegate: BolmeOgesi {
                        required property var modelData
                        metin: modelData[0]
                        onTiklandi: pen.ana.ayarEylem(modelData[1])
                    }
                }
            }

            // alt: altı hızlı ayar düğmesi + "Bilgisayar ayarlarını değiştir"
            Column {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                width: parent.width
                spacing: 18
                Grid {
                    columns: 3
                    columnSpacing: 0; rowSpacing: 14
                    width: parent.width
                    HizliAyar {
                        simge: ag.connectionIcon
                        metin: agDurum.activeConnections !== "" ? agDurum.activeConnections.split("\n")[0].replace(/:.*$/, "") : "Kullanılamıyor"
                        onTiklandi: pen.ac("aglar")
                    }
                    HizliAyar {
                        id: sesDugme
                        glif: !PreferredDevice.sink || PreferredDevice.sink.muted ? "" : ""
                        metin: PreferredDevice.sink ? Math.round(PreferredDevice.sink.volume / PulseAudio.NormalVolume * 100) : "—"
                        onTiklandi: sesKaydirici.visible = !sesKaydirici.visible
                    }
                    HizliAyar {
                        glif: "☼"
                        metin: "Parlaklık"
                        onTiklandi: Sistem.ayarAc("kcm_powerdevilprofilesconfig")
                    }
                    HizliAyar {
                        glif: Sistem.bildirimGizli ? "" : ""
                        uyari: Sistem.bildirimGizli
                        metin: Sistem.bildirimGizli ? Sistem.bildirimBitis + "'a kadar gizli" : "Bildirimler"
                        onTiklandi: {
                            var p = mapToItem(kok, 0, -4)
                            altMenu.ac(p.x, p.y, Sistem.bildirimGizli
                                ? [{ metin: "Göster", eylem: function () { Sistem.bildirimleriGizle(0) } }]
                                : [{ metin: "1 saat için gizle", eylem: function () { Sistem.bildirimleriGizle(1) } },
                                   { metin: "3 saat için gizle", eylem: function () { Sistem.bildirimleriGizle(3) } },
                                   { metin: "8 saat için gizle", eylem: function () { Sistem.bildirimleriGizle(8) } }], true)
                        }
                    }
                    HizliAyar {
                        glif: ""
                        metin: "Güç"
                        onTiklandi: {
                            var p = mapToItem(kok, 0, -4)
                            altMenu.ac(p.x, p.y, pen.ana.gucOgeleri(), true)
                        }
                    }
                    HizliAyar {
                        glif: ""
                        metin: Sistem.klavyeDuzenleri.length ? Sistem.klavyeDuzenleri[Sistem.klavyeDuzeni].kisa : "TUR"
                        onTiklandi: {
                            var p = mapToItem(kok, 0, -4)
                            var l = []
                            for (var i = 0; i < Sistem.klavyeDuzenleri.length; i++)
                                (function (j) { l.push({ metin: Sistem.klavyeDuzenleri[j].uzun || Sistem.klavyeDuzenleri[j].kisa, isaretli: j === Sistem.klavyeDuzeni,
                                                         eylem: function () { Sistem.klavyeSec(j) } }) })(i)
                            l.push({ ayirici: true })
                            l.push({ metin: "Dil tercihleri", eylem: function () { pen.ana.bolmeKapat(); Sistem.ayarAc("kcm_keyboard") } })
                            altMenu.ac(p.x, p.y, l, true)
                        }
                    }
                }
                BolmeOgesi {
                    metin: "Bilgisayar ayarlarını değiştir"
                    boyut: 15
                    onTiklandi: pen.ana.bilgisayarAyarlari("")
                }
            }
            // ses kaydırıcısı (Windows 8: ses simgesinin üstünde dikey)
            Rectangle {
                id: sesKaydirici
                visible: false
                x: sesDugme.x + 12
                anchors.bottom: parent.bottom; anchors.bottomMargin: 190
                width: 60; height: 230
                color: Qt.darker(pen.tema.arkaPlan, 1.3)
                border.color: Qt.rgba(1, 1, 1, 0.3)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 8
                    text: PreferredDevice.sink ? Math.round(PreferredDevice.sink.volume / PulseAudio.NormalVolume * 100) : ""
                    color: "white"; font.family: "Segoe UI"; font.pixelSize: 20
                }
                Item {
                    id: ray
                    x: 22; y: 44; width: 16; height: parent.height - 60
                    readonly property real oran: PreferredDevice.sink ? Math.min(1, PreferredDevice.sink.volume / PulseAudio.NormalVolume) : 0
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 6; height: parent.height; color: Qt.rgba(1, 1, 1, 0.3) }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                        width: 6; height: parent.height * ray.oran; color: pen.tema.vurgu
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (1 - ray.oran) * (parent.height - 10)
                        width: 16; height: 10; color: "white"
                    }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -10
                        function ayarla(my) {
                            if (!PreferredDevice.sink) return
                            var o = 1 - Math.max(0, Math.min(1, (my - 10) / (ray.height)))
                            PreferredDevice.sink.muted = false
                            PreferredDevice.sink.volume = Math.round(o * PulseAudio.NormalVolume)
                        }
                        onPressed: mouse => ayarla(mouse.y)
                        onPositionChanged: mouse => ayarla(mouse.y)
                    }
                }
            }
        }
    }
    PlasmaNM.ConnectionIcon { id: ag }
    PlasmaNM.NetworkStatus { id: agDurum }

    component HizliAyar: Item {
        id: ha
        property string glif
        property string simge: ""
        property string metin
        property bool uyari: false
        signal tiklandi()
        width: (pen.genislik - 80) / 3; height: 78
        Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, hma.pressed ? 0.25 : 0.12); visible: hma.containsMouse }
        Text {
            visible: ha.simge === ""
            anchors.horizontalCenter: parent.horizontalCenter; y: 6
            text: ha.glif; color: "white"; font.family: "Segoe UI Symbol"; font.pixelSize: 30
        }
        Image {
            visible: ha.simge !== ""
            anchors.horizontalCenter: parent.horizontalCenter; y: 8
            width: 32; height: 32; sourceSize.width: 32; sourceSize.height: 32
            source: ha.simge !== "" ? "image://simge/" + ha.simge : ""
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; y: 50
            width: parent.width - 4; horizontalAlignment: Text.AlignHCenter
            text: ha.metin; color: "white"; elide: Text.ElideRight
            font.family: "Segoe UI"; font.pixelSize: 13
        }
        MouseArea { id: hma; anchors.fill: parent; hoverEnabled: true; onClicked: ha.tiklandi() }
    }

    // ================================================================== Ara
    property string aramaMetni: ""
    property string aramaKapsami: ""
    Component {
        id: araBolmesi
        Item {
            id: arb
            Column {
                id: aramaUst
                width: parent.width
                spacing: 12
                // kapsam seçici
                Item {
                    width: parent.width; height: 28
                    Row {
                        spacing: 8
                        Text {
                            text: ({ "": "Her yerde", ayarlar: "Ayarlar", dosyalar: "Dosyalar" })[pen.aramaKapsami] || "Her yerde"
                            color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 13; color: "white" }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var p = mapToItem(kok, 0, height + 4)
                            var k = [["", "Her yerde"], ["ayarlar", "Ayarlar"], ["dosyalar", "Dosyalar"]]
                            altMenu.ac(p.x, p.y, k.map(function (a) {
                                return { metin: a[1], isaretli: pen.aramaKapsami === a[0], eylem: function () { pen.aramaKapsami = a[0]; arb.ara() } }
                            }))
                        }
                    }
                }
                Rectangle {
                    width: parent.width; height: 34
                    color: "white"
                    TextInput {
                        id: girdi
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 38
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "Segoe UI"; font.pixelSize: 16
                        color: "black"; clip: true
                        text: pen.aramaMetni
                        focus: true
                        Component.onCompleted: { forceActiveFocus(); cursorPosition = text.length }
                        onTextChanged: { pen.aramaMetni = text; aramaGecikme.restart() }
                        Keys.onReturnPressed: arb.ilkiniCalistir()
                        Keys.onDownPressed: sonucListesi.forceActiveFocus()
                        Keys.onEscapePressed: pen.ana.bolmeKapat()
                    }
                    Rectangle {
                        anchors.right: parent.right; width: 34; height: parent.height
                        color: bma.pressed ? "#555" : (bma.containsMouse ? "#ddd" : "transparent")
                        Text { anchors.centerIn: parent; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 16; color: bma.pressed ? "white" : "black" }
                        MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true; onClicked: arb.ilkiniCalistir() }
                    }
                }
            }
            Timer { id: aramaGecikme; interval: 120; onTriggered: arb.ara() }
            Component.onCompleted: ara()

            property var uygulamaSonuclari: []
            function ara() {
                var m = pen.aramaMetni.trim()
                uygulamaSonuclari = (m !== "" && pen.aramaKapsami === "") ? Uygulamalar.ara(m, 6) : []
                sonuclar.singleRunner = pen.aramaKapsami === "ayarlar" ? "krunner_systemsettings"
                                      : (pen.aramaKapsami === "dosyalar" ? "baloosearch" : "")
                sonuclar.queryString = m
            }
            function ilkiniCalistir() {
                if (uygulamaSonuclari.length) { pen.ana.kutucukCalistir("uygulama", uygulamaSonuclari[0].kimlik); pen.ana.bolmeKapat(); return }
                if (duz.count > 0) { sonuclar.run(duz.mapToSource(duz.index(0, 0))); pen.ana.hepsiniKapat() }
            }

            AramaModeli {
                id: sonuclar
                limit: 24
                favoriteIds: ["krunner_services", "krunner_systemsettings", "baloosearch", "calculator", "unitconverter", "krunner_webshortcuts"]
            }
            KItemModels.KDescendantsProxyModel {
                id: duz
                model: sonuclar
            }

            ListView {
                id: sonucListesi
                anchors.top: aramaUst.bottom; anchors.topMargin: 18
                width: parent.width
                height: parent.height - y
                clip: true
                spacing: 2
                model: duz
                keyNavigationEnabled: true
                highlight: Rectangle { color: Qt.rgba(1, 1, 1, 0.18) }
                highlightMoveDuration: 0
                Keys.onReturnPressed: { sonuclar.run(duz.mapToSource(duz.index(currentIndex, 0))); pen.ana.hepsiniKapat() }
                header: Column {
                    width: sonucListesi.width
                    Repeater {
                        model: arb.uygulamaSonuclari
                        delegate: Item {
                            required property var modelData
                            width: sonucListesi.width; height: 50
                            Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.15); visible: uma2.containsMouse }
                            Rectangle {
                                id: uk; x: 4; width: 40; height: 40; anchors.verticalCenter: parent.verticalCenter
                                color: SimgeRengi.renk(modelData.simge, pen.tema.vurgu)
                                Image { anchors.centerIn: parent; width: 30; height: 30; sourceSize.width: 60; source: "image://simge/" + modelData.simge }
                            }
                            Column {
                                anchors.left: uk.right; anchors.leftMargin: 10; anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                Text { width: parent.width; text: modelData.ad; color: "white"; elide: Text.ElideRight; font.family: "Segoe UI"; font.pixelSize: 15 }
                                Text { width: parent.width; visible: text !== ""; text: modelData.aciklama || ""; color: Qt.rgba(1, 1, 1, 0.7); elide: Text.ElideRight; font.family: "Segoe UI"; font.pixelSize: 12 }
                            }
                            MouseArea { id: uma2; anchors.fill: parent; hoverEnabled: true; onClicked: { pen.ana.kutucukCalistir("uygulama", modelData.kimlik); pen.ana.bolmeKapat() } }
                        }
                    }
                }
                delegate: Item {
                    id: sd
                    required property int index
                    required property var model
                    readonly property bool kategori: model.kDescendantExpandable === true
                    width: sonucListesi.width
                    height: kategori ? (sd.model.display === "Uygulamalar" && arb.uygulamaSonuclari.length ? 0 : 34) : 46
                    visible: height > 0
                    Text {
                        visible: sd.kategori
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                        text: sd.model.display || ""
                        color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 13
                    }
                    Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.15); visible: !sd.kategori && sma.containsMouse }
                    Image {
                        visible: !sd.kategori
                        x: 8; anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28; sourceSize.width: 56
                        source: sd.model.decoration ? (typeof sd.model.decoration === "string" ? "image://simge/" + sd.model.decoration : "") : ""
                    }
                    Column {
                        visible: !sd.kategori
                        x: 46; width: parent.width - 50
                        anchors.verticalCenter: parent.verticalCenter
                        Text { width: parent.width; text: sd.model.display || ""; color: "white"; elide: Text.ElideRight; font.family: "Segoe UI"; font.pixelSize: 15 }
                        Text { width: parent.width; visible: text !== ""; text: sd.model.subtext || ""; color: Qt.rgba(1, 1, 1, 0.7); elide: Text.ElideRight; font.family: "Segoe UI"; font.pixelSize: 12 }
                    }
                    MouseArea {
                        id: sma
                        anchors.fill: parent; hoverEnabled: true; enabled: !sd.kategori
                        onClicked: { sonuclar.run(duz.mapToSource(duz.index(sd.index, 0))); pen.ana.hepsiniKapat() }
                    }
                }
            }
        }
    }

    // ================================================================== Paylaş
    Component {
        id: paylasBolmesi
        Column {
            spacing: 16
            Item {
                width: parent.width; height: 28
                Row {
                    spacing: 8
                    Text { text: "Masaüstü"; color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 20 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: "Segoe UI Symbol"; font.pixelSize: 13; color: "white" }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var p = mapToItem(kok, 0, height + 4)
                        altMenu.ac(p.x, p.y, [{ metin: "Masaüstü", isaretli: true }, { metin: "Ekran görüntüsü", eylem: function () { pen.ana.hepsiniKapat(); Medya.ekranGoruntusu() } }])
                    }
                }
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: "Masaüstünden paylaşılabilecek bir şey yok."
                color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 18
            }
        }
    }

    // ================================================================== Aygıtlar
    Component {
        id: aygitlarBolmesi
        Column {
            width: parent.width
            BolmeOgesi { metin: "Yürüt"; onTiklandi: pen.ac("yurut") }
            BolmeOgesi { metin: "Yazdır"; onTiklandi: pen.ac("yazdir") }
            BolmeOgesi { metin: "Yansıt"; onTiklandi: pen.ac("yansit") }
        }
    }
    Component {
        id: mesajBolmesi
        Text {
            width: parent.width; wrapMode: Text.WordWrap
            text: pen.tur === "yazdir" ? "Bu uygulama yazdıramıyor." : "Bu uygulama başka aygıtlara içerik gönderemiyor."
            color: "white"; font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 18
        }
    }
    Component {
        id: yansitBolmesi
        Column {
            width: parent.width
            spacing: 6
            Repeater {
                model: [["Yalnızca bilgisayar ekranı", "bilgisayar"], ["Yinele", "yinele"], ["Genişlet", "genislet"], ["Yalnızca ikinci ekran", "ikinci"]]
                delegate: BolmeOgesi {
                    required property var modelData
                    metin: modelData[0]
                    onTiklandi: { pen.ana.yansit(modelData[1]); pen.ana.bolmeKapat() }
                }
            }
        }
    }

    // ================================================================== Ağlar
    Component {
        id: aglarBolmesi
        Item {
            PlasmaNM.Handler { id: nmIsleyici }
            PlasmaNM.EnabledConnections { id: etkin }
            PlasmaNM.NetworkModel { id: agModeli }
            PlasmaNM.AppletProxyModel { id: agListesi; sourceModel: agModeli }
            Column {
                id: ucak
                width: parent.width
                spacing: 6
                Text { text: "Uçak modu"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                MetroAnahtar {
                    vurgu: pen.tema.vurgu
                    acik: PlasmaNM.Configuration.airplaneModeEnabled
                    onDegisti: d => { nmIsleyici.enableAirplaneMode(d); PlasmaNM.Configuration.airplaneModeEnabled = d }
                }
                Item { width: 1; height: 14 }
                Text { text: "Bağlantılar"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
            }
            ListView {
                anchors.top: ucak.bottom; anchors.topMargin: 8
                width: parent.width; height: parent.height - y
                clip: true
                model: agListesi
                delegate: Item {
                    id: ad
                    required property var model
                    width: ListView.view.width; height: 52
                    Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.15); visible: ama.containsMouse }
                    Image {
                        x: 4; anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28; sourceSize.width: 56
                        source: "image://simge/" + ad.model.ConnectionIcon
                    }
                    Column {
                        x: 42; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 46
                        Text { width: parent.width; text: ad.model.ItemUniqueName; color: "white"; elide: Text.ElideRight; font.family: "Segoe UI"; font.pixelSize: 15 }
                        Text {
                            text: ad.model.ConnectionState === 2 ? "Bağlı" : (ad.model.ConnectionState === 1 ? "Bağlanıyor…" : "")
                            visible: text !== ""; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        id: ama; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (ad.model.ConnectionState === 2) nmIsleyici.deactivateConnection(ad.model.ConnectionPath, ad.model.DevicePath)
                            else if (ad.model.Uuid !== "" || !ad.model.SecurityType) nmIsleyici.activateConnection(ad.model.ConnectionPath, ad.model.DevicePath, ad.model.SpecificPath)
                            else { pen.ana.bolmeKapat(); Sistem.ayarAc("kcm_networkmanagement") }
                        }
                    }
                }
            }
        }
    }

    // ================================================================== Kişiselleştir (Başlangıç)
    Component {
        id: kisisellestirBolmesi
        Flickable {
            contentHeight: kc.height
            clip: true
            Column {
                id: kc
                width: parent.width
                spacing: 10
                Text { text: "Arka plan"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                Grid {
                    columns: 4; spacing: 6
                    Repeater {
                        model: [0, 20200, 20300, 20400, 20500, 20600, 20700, 20800, 21000, 21100, 21200, 21300, 21400, 21500, 21600, 21700, 21900, 22000, 22100, -1]
                        delegate: Rectangle {
                            required property int modelData
                            width: 60; height: 60
                            color: pen.tema.arkaPlan
                            border.width: (modelData === -1 ? pen.tema.renk.masaustuArkaPlani : (!pen.tema.renk.masaustuArkaPlani && pen.tema.renk.desen === modelData)) ? 3 : 0
                            border.color: "white"
                            Image {
                                anchors.fill: parent; anchors.margins: parent.border.width
                                visible: modelData > 0
                                source: modelData > 0 ? pen.tema.varlik + "desen-kucuk/" + modelData + ".png" : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Image {
                                anchors.fill: parent; anchors.margins: parent.border.width
                                visible: modelData === -1
                                source: modelData === -1 ? pen.ana.baslangic.duvarKagidi : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 120
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === -1) pen.tema.renk.masaustuArkaPlani = true
                                    else {
                                        pen.tema.renk.masaustuArkaPlani = false
                                        pen.tema.renk.desen = modelData
                                        // Windows 8.1: desen seçilince kendi renk takımı da gelir
                                        if (modelData > 0) {
                                            try {
                                                var s = JSON.parse(Dosya.oku(Dosya.veri + "/varlik/desen/" + modelData + "/sahne.json"))
                                                if (s.arkaPlan) pen.tema.renk.arkaPlan = s.arkaPlan
                                                if (s.vurgu) pen.tema.renk.vurgu = s.vurgu
                                            } catch (e) {}
                                        }
                                    }
                                    pen.ana.renkDegisti()
                                }
                            }
                        }
                    }
                }
                Item { width: 1; height: 8 }
                Text { text: "Arka plan rengi"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                RenkIzgarasi {
                    renkler: pen.tema.zeminRenkleri
                    secili: pen.tema.renk.arkaPlan
                    onSecildi: r => { pen.tema.renk.arkaPlan = r; pen.ana.renkDegisti() }
                }
                Item { width: 1; height: 8 }
                Text { text: "Vurgu rengi"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                RenkIzgarasi {
                    renkler: pen.tema.vurguRenkleri
                    secili: pen.tema.renk.vurgu
                    onSecildi: r => { pen.tema.renk.vurgu = r; pen.ana.renkDegisti() }
                }
            }
        }
    }
    component RenkIzgarasi: Grid {
        id: ri
        property var renkler: []
        property string secili: ""
        signal secildi(string renk)
        columns: 9; spacing: 4
        Repeater {
            model: ri.renkler
            delegate: Rectangle {
                required property string modelData
                width: 26; height: 26
                color: modelData
                border.width: ri.secili.toLowerCase() === modelData.toLowerCase() ? 3 : 1
                border.color: ri.secili.toLowerCase() === modelData.toLowerCase() ? "white" : Qt.rgba(1, 1, 1, 0.3)
                MouseArea { anchors.fill: parent; onClicked: ri.secildi(modelData) }
            }
        }
    }

    // ================================================================== Kutucuklar (Başlangıç)
    Component {
        id: kutucuklarBolmesi
        Column {
            width: parent.width
            spacing: 10
            Text { text: "Daha fazla kutucuk göster"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
            MetroAnahtar {
                vurgu: pen.tema.vurgu
                acik: pen.tema.baslangic.fazlaKutucuk
                acikMetin: "Evet"; kapaliMetin: "Hayır"
                onDegisti: d => pen.tema.baslangic.fazlaKutucuk = d
            }
            Item { width: 1; height: 10 }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: "Kişisel bilgilerimi kutucuklarımdan temizle"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
            Rectangle {
                width: 90; height: 32; color: "transparent"; border.color: "white"; border.width: 2
                Text { anchors.centerIn: parent; text: "Temizle"; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                MouseArea { anchors.fill: parent; onClicked: Dosya.yaz(Dosya.yapilandirma + "/kullanim.json", "{}") }
            }
        }
    }
}
