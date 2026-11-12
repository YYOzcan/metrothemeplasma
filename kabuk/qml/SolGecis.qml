// Uygulamalar arasında geçiş (Win+Tab, sol üst köşe): sol kenarda açık pencerelerin küçük resimleri
import QtQuick
import QtQuick.Window
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire
import org.kde.kirigami as Kirigami

Window {
    id: pen
    property var ana
    property bool acik: false
    property int secim: 0
    property real ilerleme: 0
    width: 196
    height: Screen.height
    color: "transparent"
    visible: false
    flags: Qt.FramelessWindowHint
    title: "Uygulamalar arasında geçiş"

    Component.onCompleted: KatmanYardimci.ayarla(pen, 3, 1 | 2 | 4, 1, -1, "metro-gecis")

    TaskManager.TasksModel {
        id: gorevler
        sortMode: TaskManager.TasksModel.SortLastActivated
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByVirtualDesktop: false
        filterByScreen: false
        filterNotMinimized: false
    }

    // Windows 8: sol üst köşede önce yalnız önceki uygulamanın küçük resmi (ipucu) belirir; fare sol kenar
    // boyunca inince siyah geçiş listesi açılır; fareyle açılan liste fare uzaklaşınca kapanır.
    // Win+Tab ile açılan liste Windows tuşu bırakılınca seçileni etkinleştirir.
    property bool ipucu: false
    property bool fareIle: false
    function ac(ipucuKipi) {
        if (gorevler.count === 0) return
        kapanis.stop()
        if (acik && !ipucu && ipucuKipi) return
        secim = gorevler.count > 1 ? 1 : 0
        ipucu = !!ipucuKipi
        if (!acik) { fareIle = !!ipucuKipi; acik = true; visible = true; ilerleme = 0; acilis.restart() }
        liste.positionViewAtIndex(secim, ListView.Beginning)
        if (!ipucu) {
            requestActivate()
            kok.forceActiveFocus()
        }
        cikis.restart()
    }
    function tamAc() {
        if (!ipucu) return
        ipucu = false
        liste.positionViewAtBeginning()
        requestActivate()
        kok.forceActiveFocus()
    }
    Timer {
        id: cikis
        interval: 900
        onTriggered: if ((pen.ipucu || pen.fareIle) && !izleyici.containsMouse) pen.kapat()
    }
    function ileri() { if (gorevler.count) secim = (secim + 1) % gorevler.count }
    function kapat() {
        if (!acik) return
        acik = false
        acilis.stop(); kapanis.restart()
    }
    function etkinlestir(i) {
        var idx = gorevler.makeModelIndex(i)
        gorevler.requestActivate(idx)
        ana.hepsiniKapat()
        kapat()
    }
    NumberAnimation { id: acilis; target: pen; property: "ilerleme"; to: 1; duration: 450; easing.type: Easing.Bezier; easing.bezierCurve: pen.ana.tema.pvl }
    SequentialAnimation {
        id: kapanis
        NumberAnimation { target: pen; property: "ilerleme"; to: 0; duration: 160 }
        ScriptAction { script: pen.visible = false }
    }
    onActiveChanged: if (!active && acik && !ipucu) kapat()

    Item {
        id: kok
        anchors.fill: parent
        focus: true
        transform: Translate { x: -(1 - pen.ilerleme) * pen.width }
        Keys.onEscapePressed: pen.kapat()
        Keys.onTabPressed: pen.ileri()
        Keys.onDownPressed: pen.ileri()
        Keys.onUpPressed: if (gorevler.count) pen.secim = (pen.secim + gorevler.count - 1) % gorevler.count
        Keys.onReturnPressed: pen.etkinlestir(pen.secim)
        Keys.onReleased: event => { if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L) pen.etkinlestir(pen.secim) }

        Rectangle { anchors.fill: parent; color: "#1d1d1d"; opacity: pen.ipucu ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 160 } } }

        // fare izleyici (alt öğelerin üstündeyken de çalışır): ipucundan sol kenar boyunca inince tam liste;
        // pencereden çıkınca kapan
        HoverHandler {
            id: izleyici
            readonly property bool containsMouse: hovered
            onPointChanged: if (hovered && pen.ipucu && point.position.y > 150) pen.tamAc()
            onHoveredChanged: if (!hovered) { if (pen.ipucu) pen.kapat(); else if (pen.fareIle) cikis.restart() }
        }

        ListView {
            id: liste
            anchors.fill: parent
            anchors.topMargin: pen.ipucu ? 0 : 20; anchors.bottomMargin: pen.ipucu ? pen.height - 130 : 20
            interactive: !pen.ipucu
            spacing: 14
            model: gorevler
            currentIndex: pen.secim
            clip: true
            delegate: Item {
                id: og
                required property int index
                required property var model
                width: liste.width; height: 120
                Rectangle {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    color: "transparent"
                    border.width: pen.secim === og.index ? 3 : 0
                    border.color: "white"
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 5
                        color: "#2d2d2d"
                        clip: true
                        PipeWire.PipeWireSourceItem {
                            id: kucukResim
                            anchors.fill: parent
                            visible: waylandItem.nodeId > 0
                            nodeId: waylandItem.nodeId
                            TaskManager.ScreencastingRequest {
                                id: waylandItem
                                uuid: pen.acik ? og.model.WinIdList[0] : ""
                            }
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            visible: !kucukResim.visible
                            width: 48; height: 48
                            source: og.model.decoration
                        }
                        Kirigami.Icon {
                            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 4
                            width: 24; height: 24
                            visible: kucukResim.visible
                            source: og.model.decoration
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: pen.secim = og.index
                    onClicked: pen.etkinlestir(og.index)
                }
            }
        }
    }
}
