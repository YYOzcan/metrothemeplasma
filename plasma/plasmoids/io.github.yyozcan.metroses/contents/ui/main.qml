// Windows 8.1 masaüstü ses açılır penceresi: aygıt simgesi, dikey kaydırıcı (aero.msstyles TrackBar renkleri),
// yüzde, sessiz düğmesi ve "Karıştırıcı" bağlantısı. Ses Plasma'nın PulseAudio modülünden.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: kok
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    preferredRepresentation: compactRepresentation
    // tepsinin geniş açılır kutusu yerine Windows 8'deki dar açılır pencere (kendi Dialog'umuz)
    fullRepresentation: Item {}
    Plasmoid.onActivated: acilir.visible = !acilir.visible

    readonly property var aygit: PreferredDevice.sink
    readonly property int yuzde: aygit ? Math.round(aygit.volume / PulseAudio.NormalVolume * 100) : 0
    readonly property bool sessiz: !aygit || aygit.muted || yuzde === 0
    readonly property string simge: sessiz ? "audio-volume-muted"
                                   : (yuzde <= 33 ? "audio-volume-low" : (yuzde <= 66 ? "audio-volume-medium" : "audio-volume-high"))
    Plasmoid.icon: simge
    toolTipMainText: aygit ? (aygit.description || "Hoparlörler") + ": " + yuzde + "%" : "Ses aygıtı yok"
    toolTipSubText: aygit && aygit.muted ? "Sessiz" : ""

    VolumeFeedback { id: geriBildirim }
    function ayarla(o) {
        if (!aygit) return
        aygit.muted = false
        aygit.volume = Math.round(Math.max(0, Math.min(1, o)) * PulseAudio.NormalVolume)
    }

    P5Support.DataSource {
        id: komut
        engine: "executable"
        connectedSources: []
        onNewData: src => disconnectSource(src)
    }
    function calistir(k) { komut.connectSource(k) }

    property Item simgeOgesi: null
    compactRepresentation: MouseArea {
        id: simgeAlan
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        Component.onCompleted: kok.simgeOgesi = simgeAlan
        onPressed: kok.acikti = acilir.visible
        onClicked: acilir.visible = !kok.acikti
        Kirigami.Icon {
            anchors.fill: parent
            source: kok.simge
            active: parent.containsMouse
        }
    }

    property bool acikti: false
    PlasmaCore.Dialog {
        id: acilir
        visible: false
        visualParent: kok.simgeOgesi
        location: PlasmaCore.Types.BottomEdge
        type: PlasmaCore.Dialog.PopupMenu
        hideOnWindowDeactivate: true
        flags: Qt.WindowStaysOnTopHint
        mainItem: Item {
        width: 84; height: 312

        // aygıt simgesi (Ses ayarları)
        Rectangle {
            id: aygitDugme
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10; width: 44; height: 44
            color: ama.pressed ? "#cce8ff" : (ama.containsMouse ? "#e5f3ff" : "transparent")
            border.color: ama.containsMouse ? "#99d1ff" : "transparent"
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 32; height: 32
                source: "audio-speakers"
            }
            MouseArea {
                id: ama
                anchors.fill: parent
                hoverEnabled: true
                onClicked: { acilir.visible = false; kok.calistir("kcmshell6 kcm_pulseaudio") }
            }
        }

        // dikey kaydırıcı (TrackBar: oluk #e7eaea/#d6d6d6, başparmak gri; üzerindeyken mavi)
        Item {
            id: kaydirici
            anchors.horizontalCenter: parent.horizontalCenter
            y: 66; width: 30; height: 158
            readonly property real oran: kok.aygit ? Math.min(1, kok.aygit.volume / PulseAudio.NormalVolume) : 0
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 5; width: 4; height: parent.height - 10
                color: "#e7eaea"; border.color: "#d6d6d6"
            }
            Rectangle {
                id: basparmak
                anchors.horizontalCenter: parent.horizontalCenter
                width: 21; height: 11
                y: (1 - kaydirici.oran) * (kaydirici.height - height)
                border.color: kma.pressed ? "#569de5" : (kma.containsMouse ? "#7eb4ea" : "#acacac")
                gradient: Gradient {
                    GradientStop { position: 0; color: kma.pressed ? "#daecfc" : (kma.containsMouse ? "#ecf4fc" : "#f0f0f0") }
                    GradientStop { position: 1; color: kma.pressed ? "#c4e0fc" : (kma.containsMouse ? "#dcecfc" : "#e5e5e5") }
                }
            }
            MouseArea {
                id: kma
                anchors.fill: parent
                hoverEnabled: true
                function konum(my) { kok.ayarla(1 - (my - basparmak.height / 2) / (kaydirici.height - basparmak.height)) }
                onPressed: mouse => konum(mouse.y)
                onPositionChanged: mouse => { if (pressed) konum(mouse.y) }
                onReleased: if (kok.aygit) geriBildirim.play(kok.aygit.index)
                onWheel: wheel => kok.ayarla(kaydirici.oran + (wheel.angleDelta.y > 0 ? 0.02 : -0.02))
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 230
            text: kok.yuzde
            color: "#000000"
            font.family: "Segoe UI"; font.pixelSize: 12
        }

        // sessiz düğmesi
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 248; width: 30; height: 26
            color: sma.pressed ? "#cce8ff" : (sma.containsMouse ? "#e5f3ff" : "transparent")
            border.color: sma.containsMouse ? "#99d1ff" : "transparent"
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 16; height: 16
                source: kok.simge
            }
            MouseArea {
                id: sma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: if (kok.aygit) kok.aygit.muted = !kok.aygit.muted
            }
        }

        // alt şerit: Karıştırıcı
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 30
            color: "#f0f0f0"
            Rectangle { width: parent.width; height: 1; color: "#dfdfdf" }
            Text {
                anchors.centerIn: parent
                text: "Karıştırıcı"
                color: kpa.containsMouse ? "#3399ff" : "#0066cc"
                font.family: "Segoe UI"; font.pixelSize: 12
                font.underline: kpa.containsMouse
                MouseArea {
                    id: kpa
                    anchors.fill: parent; anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { acilir.visible = false; kok.calistir("sh -c 'command -v pavucontrol-qt >/dev/null && exec pavucontrol-qt || command -v pavucontrol >/dev/null && exec pavucontrol || exec kcmshell6 kcm_pulseaudio'") }
                }
            }
        }
    }
    }
}
