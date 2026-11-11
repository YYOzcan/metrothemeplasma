// Windows 8.1 "Masaüstünü göster" şeridi: tıklayınca pencereleri gizler/geri getirir,
// üzerinde durunca (Masaüstüne Gözat açıksa) pencereler saydamlaşır
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: kok
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    P5Support.DataSource {
        id: komut
        engine: "executable"
        connectedSources: []
        onNewData: src => disconnectSource(src)
    }
    function kisayol(ad) {
        komut.connectSource("qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut '" + ad + "'")
    }

    compactRepresentation: Item {
        Layout.minimumWidth: 15
        Layout.preferredWidth: 15
        Layout.maximumWidth: 15
        Layout.fillHeight: true
        // sol kenarda ince ayırıcı çizgi
        Rectangle { width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.25) }
        Rectangle { x: 1; width: 1; height: parent.height; color: Qt.rgba(0, 0, 0, 0.25) }
        Rectangle {
            anchors.fill: parent; anchors.leftMargin: 2
            color: Qt.rgba(1, 1, 1, ma.pressed ? 0.35 : (ma.containsMouse ? 0.2 : 0))
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: kok.kisayol("Show Desktop")
        }
    }
}
