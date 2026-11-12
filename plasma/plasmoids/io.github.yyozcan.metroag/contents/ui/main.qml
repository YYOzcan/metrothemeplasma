// Windows 8.1 görev çubuğu ağ simgesi: tıklayınca masaüstü penceresi değil, sağdan Ağlar bölmesi
// (metro-kabuk) açılır. Simge ve ipucu Plasma ağ yönetiminden.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: kok
    preferredRepresentation: compactRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Plasmoid.icon: baglanti.connectionIcon

    PlasmaNM.ConnectionIcon { id: baglanti }
    PlasmaNM.NetworkStatus { id: durum }

    toolTipMainText: {
        var t = durum.activeConnections
        if (!t || t === "") return "Bağlı değil"
        // "Wired connection 1: Connected" -> ilk satırın bağlantı adı
        return t.split("\n")[0].split(":")[0]
    }
    toolTipSubText: baglanti.connecting ? "Bağlanılıyor…" : (durum.networkStatus === "Connected" || durum.activeConnections ? "İnternet erişimi" : "Bağlantı yok")

    P5Support.DataSource {
        id: komut
        engine: "executable"
        connectedSources: []
        onNewData: src => disconnectSource(src)
    }
    function aglar() {
        komut.connectSource("qdbus6 io.github.yyozcan.MetroKabuk /Kabuk io.github.yyozcan.MetroKabuk.Bolme aglar")
    }
    Plasmoid.onActivated: aglar()

    compactRepresentation: MouseArea {
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: kok.aglar()
        Kirigami.Icon {
            anchors.fill: parent
            source: baglanti.connectionIcon
            active: parent.containsMouse
        }
    }
    fullRepresentation: Item {}
}
