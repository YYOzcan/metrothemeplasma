// Windows 8.1 Otomatik Kullan seçim paneli: toast'a tıklanınca sağ üstte Başlangıç rengiyle açılır.
// Başlık sürücü adı (20 pt Light), altında "Çıkarılabilir sürücüler ile ne yapmak istediğinizi seçin."
// (twinui 9978 + shell32 17489), seçenekler simge + kalın eylem + soluk program adı (11 pt Semibold / Semilight;
// twinui 10001–10003). Seçilen eylem o medya türünün varsayılanı olur (Windows 8.1 davranışı).
import QtQuick
import QtQuick.Window

Window {
    id: pen
    property var tema
    property var aygit: ({})
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Otomatik Kullan"
    width: Screen.width; height: Screen.height

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 15, 1, -1, "metro-otomatik-kullan")

    readonly property bool kart: aygit.tur === "bellekKarti"
    readonly property var secenekler: {
        var l = []
        if (Uygulamalar.var("metro-fotograflar.desktop"))
            l.push({ eylem: "fotograf", baslik: "Fotoğrafları ve videoları içeri aktar", program: "Fotoğraflar",
                     simge: "file://" + Dosya.veri + "/varlik/uygulama-fotograflar.png" })
        if (OtomatikKullan.programVar("deja-dup"))
            l.push({ eylem: "yedek", baslik: "Bu sürücüyü yedekleme için yapılandır", program: "Dosya Geçmişi",
                     simge: "image://simge/deja-dup" })
        l.push({ eylem: "klasor", baslik: "Dosyaları görüntülemek için klasörü aç", program: "Dosya Gezgini",
                 simge: "image://simge/system-file-manager" })
        l.push({ eylem: "hicbir", baslik: "Hiçbir şey yapma", program: "", simge: "" })
        return l
    }

    function ac(a) {
        aygit = a
        visible = true
        requestActivate()
        panel.forceActiveFocus()
        giris.restart()
    }
    function kapat() { cikis.restart() }
    function sec(e) {
        if (aygit.tur) OtomatikKullan.varsayilanYap(aygit.tur, e)
        OtomatikKullan.eylemYap(aygit.udi || "", aygit.yol || "", e)
        kapat()
    }

    // dışarı tıklayınca kapanır (hafif kapatma)
    MouseArea { anchors.fill: parent; onClicked: pen.kapat() }

    Rectangle {
        id: panel
        width: 400
        height: icerik.implicitHeight + 50
        x: pen.width - width - 20; y: 40
        color: pen.tema.arkaPlan
        border.color: pen.tema.vurgu; border.width: 2
        focus: true
        Keys.onEscapePressed: pen.kapat()
        transform: Translate { id: kayma }
        MouseArea { anchors.fill: parent }   // panelin içi kapatmasın

        Column {
            id: icerik
            x: 24; y: 22
            width: parent.width - 48
            spacing: 4
            Text {
                width: parent.width; elide: Text.ElideRight
                text: pen.aygit.ad || ""
                color: "white"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 27
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: (pen.kart ? "Bellek kartları" : "Çıkarılabilir sürücüler") + " ile ne yapmak istediğinizi seçin."
                color: Qt.rgba(1, 1, 1, 0.8); font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 15
                bottomPadding: 14
            }
            Repeater {
                model: pen.secenekler
                delegate: Rectangle {
                    id: og
                    required property var modelData
                    width: icerik.width + 24; x: -12
                    height: 60
                    color: om.pressed ? Qt.rgba(1, 1, 1, 0.3) : (om.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
                    Item {
                        id: simgeAlani
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        width: 40; height: 40
                        Image {
                            anchors.fill: parent
                            visible: og.modelData.simge !== ""
                            source: og.modelData.simge
                            sourceSize.width: 80
                        }
                    }
                    Column {
                        x: 64; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 76
                        Text { width: parent.width; elide: Text.ElideRight; text: og.modelData.baslik; color: "white"; font.family: "Segoe UI"; font.weight: 600; font.pixelSize: 15 }
                        Text { visible: text !== ""; text: og.modelData.program; color: Qt.rgba(1, 1, 1, 0.75); font.family: "Segoe UI"; font.weight: 350; font.pixelSize: 15 }
                    }
                    MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; onClicked: pen.sec(og.modelData.eylem) }
                }
            }
        }
    }

    ParallelAnimation {
        id: giris
        NumberAnimation { target: kayma; property: "x"; from: 60; to: 0; duration: 367; easing.type: Easing.Bezier; easing.bezierCurve: pen.tema.pvl }
        NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 167 }
    }
    SequentialAnimation {
        id: cikis
        ParallelAnimation {
            NumberAnimation { target: kayma; property: "x"; to: 60; duration: 167 }
            NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 167 }
        }
        ScriptAction { script: pen.visible = false }
    }
}
