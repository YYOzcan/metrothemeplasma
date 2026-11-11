// Windows 8.1 Update görev çubuğu Başlat düğmesi
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import QtCore

PlasmoidItem {
    id: kok
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.constraintHints: PlasmaCore.Types.CanFillArea

    readonly property string varlik: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/metrothemeplasma/varlik/"

    P5Support.DataSource {
        id: komut
        engine: "executable"
        connectedSources: []
        onNewData: src => disconnectSource(src)
    }
    function dbus(yontem, arg) {
        komut.connectSource("qdbus6 io.github.yyozcan.MetroKabuk /Kabuk io.github.yyozcan.MetroKabuk." + yontem + (arg ? " " + arg : ""))
    }
    // Meta tuşu / Plasma'nın "başlatıcıyı etkinleştir" isteği
    Plasmoid.onActivated: dbus("Baslangic")

    compactRepresentation: Item {
        id: dugme
        Layout.minimumWidth: 48
        Layout.preferredWidth: 48
        Layout.maximumWidth: 48
        implicitWidth: 48
        Image {
            id: isik
            anchors.centerIn: parent
            width: 64; height: 32
            source: kok.varlik + "baslat-isik-64.png"
            opacity: ma.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        Image {
            anchors.centerIn: parent
            width: 32; height: 32
            source: kok.varlik + (ma.pressed ? "baslat-kontur-32.png" : "baslat-32.png")
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: mouse => mouse.accepted = true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    kok.dbus("GucMenusu", "-1 -1")
                } else {
                    kok.dbus("Baslangic")
                }
            }
        }
    }
}
