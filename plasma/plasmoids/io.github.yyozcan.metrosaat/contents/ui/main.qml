// Windows 8.1 görev çubuğu saati: iki satır (saat / tarih), Segoe UI 9 pt, beyaz.
// Tıklayınca Windows'un tarih-saat açılır penceresi: uzun tarih, ay takvimi, büyük saat ve
// "Tarih ve saat ayarlarını değiştir..." bağlantısı.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import QtCore

PlasmoidItem {
    id: kok
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    property date simdi: new Date()
    readonly property var tr: Qt.locale("tr_TR")
    Timer { interval: 1000; running: true; repeat: true; onTriggered: kok.simdi = new Date() }

    toolTipMainText: kok.simdi.getDate() + " " + tr.standaloneMonthName(kok.simdi.getMonth(), Locale.LongFormat) + " "
                     + kok.simdi.getFullYear() + " " + tr.dayName(kok.simdi.getDay(), Locale.LongFormat)
    toolTipSubText: ""

    P5Support.DataSource {
        id: komut
        engine: "executable"
        connectedSources: []
        onNewData: src => disconnectSource(src)
    }

    compactRepresentation: Item {
        Layout.minimumWidth: sutun.implicitWidth + 16
        Layout.preferredWidth: sutun.implicitWidth + 16
        Layout.maximumWidth: sutun.implicitWidth + 16
        Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, ma.pressed ? 0.25 : 0.12); visible: ma.containsMouse || kok.expanded }
        Column {
            id: sutun
            anchors.centerIn: parent
            spacing: 1
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(kok.simdi, "HH:mm")
                color: "white"; font.family: "Segoe UI"; font.pixelSize: 12
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(kok.simdi, "dd.MM.yyyy")
                color: "white"; font.family: "Segoe UI"; font.pixelSize: 12
            }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: kok.expanded = !kok.expanded }
    }

    readonly property string varlik: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/metrothemeplasma/varlik/"

    // Windows 7/8 tarih-saat açılır penceresi: üstte uzun tarih (bağlantı), solda ay takvimi,
    // sağda analog saat (timedate.cpl kadranı) ve dijital saat, altta ayarlar bağlantısı
    fullRepresentation: Item {
        id: acilir
        Layout.minimumWidth: 372; Layout.preferredWidth: 372; Layout.maximumWidth: 372
        Layout.minimumHeight: 290; Layout.preferredHeight: 290; Layout.maximumHeight: 290
        property int ay: kok.simdi.getMonth()
        property int yil: kok.simdi.getFullYear()
        Connections { target: kok; function onExpandedChanged() { if (kok.expanded) { acilir.ay = kok.simdi.getMonth(); acilir.yil = kok.simdi.getFullYear() } } }
        function ayDegistir(d) {
            var a = ay + d, y = yil
            if (a < 0) { a = 11; y-- } else if (a > 11) { a = 0; y++ }
            ay = a; yil = y
        }

        Text {
            x: 14; y: 10
            text: kok.simdi.getDate() + " " + kok.tr.standaloneMonthName(kok.simdi.getMonth(), Locale.LongFormat) + " "
                  + kok.simdi.getFullYear() + " " + kok.tr.dayName(kok.simdi.getDay(), Locale.LongFormat)
            color: uzunMa.containsMouse ? "#3399ff" : "#0066cc"; font.family: "Segoe UI"; font.pixelSize: 15
            MouseArea { id: uzunMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { acilir.ay = kok.simdi.getMonth(); acilir.yil = kok.simdi.getFullYear() } }
        }

        // ---- ay takvimi
        Item {
            id: takvim
            x: 12; y: 42; width: 196; height: 186
            Row {
                id: baslik
                width: parent.width; height: 24
                Text {
                    width: 24; height: 24; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: "\u25C0"; font.pixelSize: 9; color: solMa.containsMouse ? "#3399ff" : "#555"
                    MouseArea { id: solMa; anchors.fill: parent; hoverEnabled: true; onClicked: acilir.ayDegistir(-1) }
                }
                Text {
                    width: parent.width - 48; height: 24; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: kok.tr.standaloneMonthName(acilir.ay, Locale.LongFormat) + " " + acilir.yil
                    color: "#1e395b"; font.family: "Segoe UI"; font.pixelSize: 13
                }
                Text {
                    width: 24; height: 24; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: "\u25B6"; font.pixelSize: 9; color: sagMa.containsMouse ? "#3399ff" : "#555"
                    MouseArea { id: sagMa; anchors.fill: parent; hoverEnabled: true; onClicked: acilir.ayDegistir(1) }
                }
            }
            Grid {
                id: izgara
                y: 28
                columns: 7
                readonly property int hg: 28
                readonly property int hy: 22
                // Windows (Türkçe) gün kısaltmaları, Pazartesi'den
                Repeater {
                    model: ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
                    delegate: Text {
                        required property var modelData
                        width: izgara.hg; height: izgara.hy
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        text: modelData; color: "#1e395b"; font.family: "Segoe UI"; font.pixelSize: 12
                    }
                }
                Repeater {
                    model: 42
                    delegate: Rectangle {
                        required property int index
                        readonly property date ilk: new Date(acilir.yil, acilir.ay, 1)
                        readonly property int kayma: (ilk.getDay() + 6) % 7
                        readonly property date gun: new Date(acilir.yil, acilir.ay, 1 + index - kayma)
                        readonly property bool buAy: gun.getMonth() === acilir.ay
                        readonly property bool bugun: gun.getDate() === kok.simdi.getDate() && gun.getMonth() === kok.simdi.getMonth()
                                                      && gun.getFullYear() === kok.simdi.getFullYear()
                        width: izgara.hg; height: izgara.hy
                        color: gma.containsMouse ? "#e5f3ff" : (bugun ? "#dcebfc" : "transparent")
                        border.color: bugun ? "#0066cc" : (gma.containsMouse ? "#cce8ff" : "transparent")
                        Text {
                            anchors.centerIn: parent
                            text: parent.gun.getDate()
                            color: parent.buAy ? "#000000" : "#8d8d8d"
                            font.family: "Segoe UI"; font.pixelSize: 12
                        }
                        MouseArea { id: gma; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }

        // ---- analog saat
        Item {
            id: analog
            x: 226; y: 46; width: 130; height: 130
            Image { anchors.fill: parent; source: kok.varlik + "saat-kadran.png" }
            Canvas {
                id: ibreler
                anchors.fill: parent
                property date t: kok.simdi
                onTChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"); c.reset()
                    var m = width / 2
                    var sa = t.getHours() % 12, dk = t.getMinutes(), sn = t.getSeconds()
                    function ibre(aci, boy, kalin, renk) {
                        c.save(); c.translate(m, m); c.rotate(aci)
                        c.beginPath(); c.moveTo(0, boy * 0.16); c.lineTo(0, -boy)
                        c.lineWidth = kalin; c.lineCap = "round"; c.strokeStyle = renk; c.stroke(); c.restore()
                    }
                    ibre((sa + dk / 60) / 12 * 2 * Math.PI, m * 0.48, 4, "#1b2a38")
                    ibre((dk + sn / 60) / 60 * 2 * Math.PI, m * 0.68, 3, "#1b2a38")
                    ibre(sn / 60 * 2 * Math.PI, m * 0.74, 1, "#4a5b6c")
                }
            }
            Image { anchors.fill: parent; source: kok.varlik + "saat-ust.png" }
        }
        Text {
            anchors.horizontalCenter: analog.horizontalCenter
            y: analog.y + analog.height + 8
            text: Qt.formatTime(kok.simdi, "HH:mm:ss")
            color: "#1e395b"; font.family: "Segoe UI"; font.pixelSize: 20
        }
        Text {
            anchors.horizontalCenter: analog.horizontalCenter
            y: analog.y + analog.height + 36
            text: kok.tr.dayName(kok.simdi.getDay(), Locale.LongFormat)
            color: "#1e395b"; font.family: "Segoe UI"; font.pixelSize: 12
        }

        Rectangle { x: 0; y: parent.height - 41; width: parent.width; height: 1; color: "#dfdfdf" }
        Rectangle {
            x: 0; y: parent.height - 40; width: parent.width; height: 40
            color: "#f0f0f0"
            Text {
                anchors.centerIn: parent
                text: "Tarih ve saat ayarlarını değiştir..."
                color: baglantiMa.containsMouse ? "#3399ff" : "#0066cc"
                font.family: "Segoe UI"; font.pixelSize: 12
                font.underline: baglantiMa.containsMouse
                MouseArea {
                    id: baglantiMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { kok.expanded = false; komut.connectSource("systemsettings kcm_clock") }
                }
            }
        }
    }
}
