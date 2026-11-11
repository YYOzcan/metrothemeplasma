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

    function ac() {
        if (gorevler.count === 0) return
        kapanis.stop()
        secim = gorevler.count > 1 ? 1 : 0
        if (!acik) { acik = true; visible = true; ilerleme = 0; acilis.restart() }
        requestActivate()
        kok.forceActiveFocus()
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
    NumberAnimation { id: acilis; target: pen; property: "ilerleme"; to: 1; duration: 380; easing.type: Easing.OutQuint }
    SequentialAnimation {
        id: kapanis
        NumberAnimation { target: pen; property: "ilerleme"; to: 0; duration: 160 }
        ScriptAction { script: pen.visible = false }
    }
    onActiveChanged: if (!active && acik) kapat()

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

        Rectangle { anchors.fill: parent; color: "#1d1d1d" }

        ListView {
            id: liste
            anchors.fill: parent
            anchors.topMargin: 20; anchors.bottomMargin: 20
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
