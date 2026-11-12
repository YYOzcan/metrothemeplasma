// Haberler / Spor canlı kutucuğu: resimli manşetler, birkaç saniyede bir yukarı kayarak değişir
// (Windows 8.1 Bing Haberler kutucuğu). Akış: TRT Haber (Haberler), NTV Spor (Spor).
import QtQuick

Item {
    id: h
    property Item kutucuk
    property string kaynak: ""
    property var ogeler: []
    property int sira: 0
    clip: true

    function yukle() {
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE || x.status !== 200) return
            var t = x.responseText, atom = t.indexOf("<item>") < 0, p = t.split(atom ? "<entry>" : "<item>"), l = []
            for (var i = 1; i < p.length && l.length < 8; i++) {
                var b = /<title[^>]*>([\s\S]*?)<\/title>/.exec(p[i])
                var r = (/<media:content[^>]*url="([^"]+)"/.exec(p[i]) || /<img[^>]*src="([^"]+)"/.exec(p[i]) || [])[1] || ""
                l.push({ baslik: (b ? b[1] : "").replace(/<!\[CDATA\[|\]\]>/g, "").replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&").trim(),
                         resim: r })
            }
            h.ogeler = l
        }
        x.open("GET", kaynak); x.send()
    }
    Component.onCompleted: yukle()
    Timer { interval: 20 * 60 * 1000; running: true; repeat: true; onTriggered: h.yukle() }
    Timer {
        interval: 6000 + Math.random() * 3000; running: h.ogeler.length > 1; repeat: true
        onTriggered: gecis.restart()
    }
    SequentialAnimation {
        id: gecis
        NumberAnimation { target: icerik; property: "y"; to: -h.height; duration: 400; easing.type: Easing.InCubic }
        ScriptAction { script: { h.sira = (h.sira + 1) % h.ogeler.length; icerik.y = h.height } }
        NumberAnimation { target: icerik; property: "y"; to: 0; duration: 500; easing.type: Easing.Bezier; easing.bezierCurve: [0.1, 0.9, 0.2, 1, 1, 1] }
    }
    readonly property var oge: ogeler.length ? ogeler[sira % ogeler.length] : null

    Item {
        id: icerik
        width: h.width; height: h.height
        visible: h.oge !== null
        Image {
            anchors.fill: parent
            source: h.oge ? h.oge.resim : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 620
            asynchronous: true
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: baslik.implicitHeight + 34
            gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0.65) } GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.8) } }
        }
        Text {
            id: baslik
            x: 8; width: parent.width - 16
            anchors.bottom: parent.bottom; anchors.bottomMargin: 26
            wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight
            text: h.oge ? h.oge.baslik : ""
            color: "white"; font.family: "Segoe UI"; font.pixelSize: h.kutucuk && h.kutucuk.boyut === "orta" ? 13 : 16; font.weight: 600
        }
    }
}
