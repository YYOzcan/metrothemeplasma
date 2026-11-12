// MetroThemePlasma — Windows 8 ekran göstergesi (ses, parlaklık …).
// Plasma 6.8 OSD'yi org.kde.plasma.workspace.osd modülünden yükler; bu dizin yalnızca Metro oturumunda
// QML_IMPORT_PATH'in başına eklenir (metro-oturum), böylece diğer oturumlar etkilenmez.
// Windows 8: sol üst köşede koyu, dikey kutu; üstte değer, ortada vurgu renginde dolan çubuk, altta simge.
import QtQuick
import QtQuick.Window
import QtCore
import org.kde.layershell as LayerShell

Window {
    id: pen

    // plasmashell'in ayarladığı özellikler
    property int timeout: 1800
    property var osdValue
    property int osdMaxValue: 100
    property string osdAdditionalText: ""
    property string icon: ""
    property bool showingProgress: false
    property bool animateOpacity: false

    flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
    color: "transparent"
    title: "Metro OSD"
    // sol üstten 54 piksel içeride (QMargins QML'den yazılamadığı için pencere kenar boşluğunu kapsar)
    readonly property int bosluk: 54
    width: bosluk + (showingProgress ? kutu.width : serit.width)
    height: bosluk + (showingProgress ? kutu.height : serit.height)

    LayerShell.Window.scope: "metro-osd"
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorLeft
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.activateOnShow: false

    Settings {
        id: renk
        location: "file://" + StandardPaths.writableLocation(StandardPaths.ConfigLocation).toString().replace("file://", "") + "/metrothemeplasma/ayarlar.ini"
        category: "Renk"
        property string vurgu: "#4617b4"
    }

    readonly property real oran: showingProgress && osdMaxValue > 0 ? Math.max(0, Math.min(1, Number(osdValue) / osdMaxValue)) : 0
    readonly property bool sessiz: icon.indexOf("muted") >= 0 || icon.indexOf("-off") >= 0
    readonly property bool parlaklik: icon.indexOf("brightness") >= 0 || icon.indexOf("display") >= 0
    // Segoe UI Symbol (Windows 8 uygulama çubuğu simgeleri): Volume E15D, Mute E198
    readonly property string glif: parlaklik ? "\u2600\uFE0E" : (sessiz ? "\uE198" : "\uE15D")

    Rectangle {
        id: kutu
        x: pen.bosluk; y: pen.bosluk
        visible: pen.showingProgress
        width: 66; height: 186
        color: "#1d1d1d"
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            text: pen.showingProgress ? Math.round(Number(pen.osdValue)) : ""
            color: "white"
            font.family: "Segoe UI"; font.pixelSize: 17
        }
        // dikey çubuk
        Rectangle {
            id: iz
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40; width: 8; height: 100
            color: "#4b4b4b"
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: parent.height * pen.oran
                color: pen.sessiz ? "#8a8a8a" : renk.vurgu
            }
            // başparmak
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * (1 - pen.oran) - height / 2
                width: 22; height: 8
                color: "white"
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 150
            text: pen.glif
            color: "white"
            font.family: "Segoe UI Symbol"; font.pixelSize: 20
        }
    }

    // ilerleme göstermeyen bildirimler (ör. "Mikrofon kapatıldı", klavye düzeni): koyu şerit
    Rectangle {
        id: serit
        x: pen.bosluk; y: pen.bosluk
        visible: !pen.showingProgress
        width: Math.max(180, yazi.implicitWidth + 36); height: 54
        color: "#1d1d1d"
        Text {
            id: yazi
            anchors.centerIn: parent
            text: pen.showingProgress ? "" : String(pen.osdValue === undefined ? "" : pen.osdValue)
            color: "white"
            font.family: "Segoe UI"; font.pixelSize: 17
        }
    }
}
