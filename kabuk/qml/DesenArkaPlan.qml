// Başlangıç ekranı arka planı: düz renk, Windows 8.1 desenleri ya da masaüstü duvar kağıdı.
// Desen sahneleri kurulumda imageres.dll'den çıkarılır (tools/gen_desen.py): düğüm ağacı + davranışlar.
// Kaydırdıkça sahne paralaksla kayar, bazı düğümler döner (çiçekler, dişliler, kıvrımlar).
import QtQuick

Rectangle {
    id: a
    property var tema
    property string duvarKagidi: ""
    property real kaydirma: 0       // yatay içerik kaydırması (piksel)
    property real dikey: 0          // 0 Başlangıç, 1 Uygulamalar
    color: tema.arkaPlan
    clip: true

    property var sahne: null
    property var sprite: []          // resimli düğümlerin dizinleri
    function yukle() {
        var s = null
        if (duvarKagidi === "" && tema.renk.desen > 0) {
            try { s = JSON.parse(Dosya.oku(Dosya.veri + "/varlik/desen/" + tema.renk.desen + "/sahne.json")) } catch (e) { s = null }
        }
        var l = []
        if (s) for (var i = 0; i < s.dugumler.length; i++) if (s.dugumler[i].r >= 0) l.push(i)
        sprite = []
        sahne = s
        sprite = l
    }
    Component.onCompleted: yukle()
    Connections { target: a.tema.renk; function onDesenChanged() { a.yukle() } }
    onDuvarKagidiChanged: yukle()

    Image {
        anchors.fill: parent
        visible: a.duvarKagidi !== ""
        source: a.duvarKagidi
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: a.width
    }

    // ---- düğümün dünya dönüşümü: T(x,y) · T(eksen) · R·S · T(-eksen), üst düğümlerle çarpılır
    function yerel(i) {
        var n = sahne.dugumler[i]
        var x = n.x + n.ax * width
        var y = n.y + n.ay * height
        if (i === sahne.yatay.dugum)
            x -= Math.min(kaydirma * sahne.yatay.carpan, Math.max(0, sahne.genislik - width))
        if (sahne.dikey && i === sahne.dikey.dugum) {
            var dy = sahne.dikey.carpan * dikey * height
            if (sahne.dikey.min !== null) dy = Math.max(sahne.dikey.min, dy)
            if (sahne.dikey.max !== null) dy = Math.min(sahne.dikey.max, dy)
            y += dy
        }
        if (n.kay) {
            var dx = n.kay.carpan * kaydirma + n.kay.ofset
            if (n.kay.min !== null) dx = Math.max(n.kay.min, dx)
            if (n.kay.max !== null) dx = Math.min(n.kay.max, dx)
            x += dx
        }
        var aci = n.aci
        if (n.don) {
            if (n.don.kip === 1) aci += n.don.ofset - n.don.genlik * (1 - Math.cos(n.don.carpan * kaydirma)) / 2
            else aci += n.don.carpan * kaydirma + n.don.ofset
        }
        var r = aci * Math.PI / 180
        var co = Math.cos(r) * n.olcek, si = Math.sin(r) * n.olcek
        return [co, si, -si, co, x + n.px - (co * n.px - si * n.py), y + n.py - (si * n.px + co * n.py)]
    }
    function dunya(i) {
        var m = yerel(i)
        var u = sahne.dugumler[i].ust
        while (u >= 0) {
            var p = yerel(u)
            m = [p[0] * m[0] + p[2] * m[1], p[1] * m[0] + p[3] * m[1], p[0] * m[2] + p[2] * m[3], p[1] * m[2] + p[3] * m[3],
                 p[0] * m[4] + p[2] * m[5] + p[4], p[1] * m[4] + p[3] * m[5] + p[5]]
            u = sahne.dugumler[u].ust
        }
        return m
    }
    function opaklik(i) {
        var o = 1
        while (i >= 0) { o *= sahne.dugumler[i].opak; i = sahne.dugumler[i].ust }
        return o
    }
    function kaynak(r) {
        var res = sahne.resimler[r]
        var u = "image://desen/" + sahne.kimlik + "/" + res.dosya
        if (res.tur === 1)
            u += "?c1=" + res.c1.substring(1) + "&c2=" + res.c2.substring(1)
               + "&a=" + String(tema.renk.arkaPlan).substring(1) + "&v=" + String(tema.renk.vurgu).substring(1)
        return u
    }

    Repeater {
        model: a.sprite
        delegate: Image {
            required property int modelData
            readonly property var m: a.sahne ? a.dunya(modelData) : [1, 0, 0, 1, 0, 0]
            source: a.sahne ? a.kaynak(a.sahne.dugumler[modelData].r) : ""
            opacity: a.sahne ? a.opaklik(modelData) : 1
            smooth: true
            asynchronous: false
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(m[0], m[2], 0, m[4],
                                     m[1], m[3], 0, m[5],
                                     0, 0, 1, 0,
                                     0, 0, 0, 1)
            }
        }
    }
}
