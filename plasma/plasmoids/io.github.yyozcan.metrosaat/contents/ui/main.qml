// Windows 8.1 görev çubuğu saati: iki satır (saat / tarih), Segoe UI 9 pt, beyaz.
// Tıklayınca Windows'un tarih-saat açılır penceresi: uzun tarih, ay takvimi, büyük saat ve
// "Tarih ve saat ayarlarını değiştir..." bağlantısı.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.calendar as PlasmaCalendar

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

    fullRepresentation: Item {
        Layout.minimumWidth: 360; Layout.preferredWidth: 360; Layout.maximumWidth: 360
        Layout.minimumHeight: 330; Layout.preferredHeight: 330; Layout.maximumHeight: 330
        Text {
            id: uzunTarih
            x: 12; y: 10
            text: kok.simdi.getDate() + " " + kok.tr.standaloneMonthName(kok.simdi.getMonth(), Locale.LongFormat) + " "
                  + kok.simdi.getFullYear() + " " + kok.tr.dayName(kok.simdi.getDay(), Locale.LongFormat)
            color: "#0066cc"; font.family: "Segoe UI"; font.pixelSize: 15
        }
        PlasmaCalendar.MonthView {
            x: 8; y: 40
            width: 210; height: 220
            today: kok.simdi
            borderOpacity: 0
        }
        Column {
            x: 232; y: 110
            width: 120
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(kok.simdi, "HH:mm:ss")
                color: "black"; font.family: "Segoe UI"; font.weight: 300; font.pixelSize: 26
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: kok.tr.dayName(kok.simdi.getDay(), Locale.LongFormat)
                color: "#444"; font.family: "Segoe UI"; font.pixelSize: 12
            }
        }
        Rectangle { x: 0; y: parent.height - 44; width: parent.width; height: 1; color: "#dcdcdc" }
        Rectangle {
            x: 0; y: parent.height - 43; width: parent.width; height: 43
            color: "#f0f0f0"
            Text {
                anchors.centerIn: parent
                text: "Tarih ve saat ayarlarını değiştir..."
                color: baglantiMa.containsMouse ? "#3399ff" : "#0066cc"
                font.family: "Segoe UI"; font.pixelSize: 12
                MouseArea {
                    id: baglantiMa
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: { kok.expanded = false; komut.connectSource("systemsettings kcm_clock") }
                }
            }
        }
    }
}
