// Windows 8 ilerleme halkası (dönen 5 nokta) — WinRT ProgressRing film şeridinin anahtar kareleri:
// her nokta 0.167 sn arayla başlar, 4.4 sn'lik döngüde iki tur atıp kaybolur.
import QtQuick

Item {
    id: h
    property color renk: "white"
    property real boyut: 40
    property bool calisiyor: true
    width: boyut; height: boyut

    property real zaman: 0
    NumberAnimation on zaman {
        from: 0; to: 4.4; duration: 4400
        loops: Animation.Infinite
        running: h.calisiyor && h.visible
    }

    // [zaman, açı, kontrol noktaları (bu kareye giden parça için)]
    readonly property var kareler: [
        [0.000, -110, null],
        [0.433, 10, [0.02, 0.33, 0.38, 0.77]],
        [1.200, 93, null],
        [1.617, 205, [0.57, 0.17, 0.95, 0.75]],
        [2.017, 357, [0, 0.19, 0.07, 0.72]],
        [2.783, 439, null],
        [3.217, 585, [0, 0, 0.95, 0.37]]
    ]
    function bezier(p, x) {
        // x'e karşılık gelen y (kübik Bezier, p = [x1, y1, x2, y2])
        var lo = 0, hi = 1, t = x
        for (var i = 0; i < 20; i++) {
            t = (lo + hi) / 2
            var bx = 3 * (1 - t) * (1 - t) * t * p[0] + 3 * (1 - t) * t * t * p[2] + t * t * t
            if (bx < x) lo = t; else hi = t
        }
        return 3 * (1 - t) * (1 - t) * t * p[1] + 3 * (1 - t) * t * t * p[3] + t * t * t
    }
    function aci(u) {
        var k = kareler
        if (u <= 0) return k[0][1]
        for (var i = 1; i < k.length; i++) {
            if (u <= k[i][0]) {
                var x = (u - k[i - 1][0]) / (k[i][0] - k[i - 1][0])
                var y = k[i][2] ? bezier(k[i][2], x) : x
                return k[i - 1][1] + (k[i][1] - k[i - 1][1]) * y
            }
        }
        return k[k.length - 1][1]
    }

    Repeater {
        model: 5
        delegate: Item {
            id: nokta
            required property int index
            anchors.fill: parent
            readonly property real u: h.zaman - index * 0.167
            visible: u >= 0 && u < 3.217
            rotation: h.aci(u) - 52     // yavaşlama bölgesi tepeye ortalanır: noktalar alttan doğar
            Rectangle {
                width: h.boyut / 9; height: width; radius: width / 2
                color: h.renk
                x: h.boyut / 2 - width / 2
                y: 0
            }
        }
    }
}
