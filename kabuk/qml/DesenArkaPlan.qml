// Başlangıç ekranı arka planı: düz renk, Windows 8.1 desenleri (paralaks katmanlar) ya da masaüstü duvar kağıdı.
// Desen sahneleri kurulumda imageres.dll'den çıkarılır: varlik/desen/<kimlik>/sahne.json + katman resimleri.
import QtQuick

Rectangle {
    id: a
    property var tema
    property string duvarKagidi: ""
    property real kayma: 0          // 0..1 yatay kaydırma (paralaks)
    property real dikey: 0          // 0 Başlangıç, 1 Uygulamalar
    color: tema.arkaPlan
    clip: true

    readonly property string dizin: tema.varlik + "desen/" + tema.renk.desen + "/"
    property var sahne: null
    function yukle() {
        sahne = null
        if (duvarKagidi !== "" || tema.renk.desen <= 0) return
        try { sahne = JSON.parse(Dosya.oku(Dosya.veri + "/varlik/desen/" + tema.renk.desen + "/sahne.json")) } catch (e) { sahne = null }
    }
    Component.onCompleted: yukle()
    Connections { target: a.tema.renk; function onDesenChanged() { a.yukle() } }
    onDuvarKagidiChanged: yukle()

    // masaüstü arka planı Başlangıç'ta (8.1: koyulaştırılmadan, hafif bulanık değil)
    Image {
        anchors.fill: parent
        visible: a.duvarKagidi !== ""
        source: a.duvarKagidi
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: a.width
    }

    // desen: her katman kendi paralaks oranıyla kayar; sahne ekran yüksekliğine ölçeklenir
    Item {
        id: sahneKok
        visible: a.sahne !== null
        readonly property real olcek: a.sahne ? a.height / a.sahne.yukseklik : 1
        width: a.width; height: a.height
        y: -a.dikey * a.height * 0.15
        Repeater {
            model: a.sahne ? a.sahne.katmanlar : []
            delegate: Item {
                id: katman
                required property var modelData
                readonly property real kgen: modelData.genislik * sahneKok.olcek
                x: -a.kayma * Math.max(0, kgen - a.width) * (modelData.paralaks !== undefined ? modelData.paralaks * 8 : 1)
                width: kgen; height: a.height
                Repeater {
                    model: katman.modelData.ogeler
                    delegate: Image {
                        required property var modelData
                        source: a.dizin + modelData.resim
                        x: modelData.x * sahneKok.olcek
                        y: (modelData.alttan ? a.height / sahneKok.olcek + modelData.y : modelData.y) * sahneKok.olcek
                        width: modelData.w * sahneKok.olcek
                        height: modelData.h * sahneKok.olcek
                        opacity: modelData.opaklik !== undefined ? modelData.opaklik : 1
                        rotation: modelData.aci || 0
                        smooth: true
                        asynchronous: true
                    }
                }
            }
        }
    }
}
