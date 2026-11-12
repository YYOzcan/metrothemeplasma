// Windows 8.1 Görev Yöneticisi — "daha az ayrıntı" görünümü (Ctrl+Shift+Esc, Win+X):
// çalışan uygulamalar, "Görevi sonlandır" ve "Diğer ayrıntılar" (Plasma Sistem İzleyicisi).
// Metinler Taskmgr.exe.mui'den (37199, 38001, 32420).
import QtQuick
import QtQuick.Window
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

Window {
    id: pen
    property var ana
    title: "Görev Yöneticisi"
    color: "white"
    visible: false
    width: 380; height: 330
    minimumWidth: 300; minimumHeight: 220
    property int secim: -1

    function ac() {
        secim = gorevler.count ? 0 : -1
        show(); raise(); requestActivate()
        liste.forceActiveFocus()
    }

    TaskManager.TasksModel {
        id: gorevler
        sortMode: TaskManager.TasksModel.SortAlpha
        groupMode: TaskManager.TasksModel.GroupApplications
        filterByVirtualDesktop: false
        filterByScreen: false
        filterNotMinimized: false
    }
    function sonlandir() {
        if (secim < 0 || secim >= gorevler.count) return
        gorevler.requestClose(gorevler.makeModelIndex(secim))
    }

    ListView {
        id: liste
        x: 0; y: 4
        width: parent.width; height: parent.height - alt.height - 4
        clip: true
        model: gorevler
        currentIndex: pen.secim
        keyNavigationEnabled: true
        focus: true
        Keys.onUpPressed: if (pen.secim > 0) pen.secim--
        Keys.onDownPressed: if (pen.secim < gorevler.count - 1) pen.secim++
        Keys.onDeletePressed: pen.sonlandir()
        Keys.onReturnPressed: if (pen.secim >= 0) gorevler.requestActivate(gorevler.makeModelIndex(pen.secim))
        delegate: Rectangle {
            id: og
            required property int index
            required property var model
            width: liste.width; height: 24
            readonly property bool secili: pen.secim === index
            // metro-kabuk'un pencereleri (bu pencere): Windows'taki gibi "Görev Yöneticisi"
            readonly property bool kendi: (og.model.AppId || "") === "metro-kabuk"
            color: secili ? "#cce8ff" : (oma.containsMouse ? "#e5f3ff" : "transparent")
            border.color: secili ? "#99d1ff" : "transparent"
            Kirigami.Icon {
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 16; height: 16
                source: og.kendi ? "utilities-system-monitor" : og.model.decoration
            }
            Text {
                x: 34; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 44; elide: Text.ElideRight
                text: (og.kendi ? "Görev Yöneticisi" : (og.model.AppName || og.model.display)) + (og.model.IsGroupParent && !og.kendi ? " (" + og.model.ChildCount + ")" : "")
                color: "black"; font.family: "Segoe UI"; font.pixelSize: 12
            }
            MouseArea {
                id: oma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: pen.secim = og.index
                onDoubleClicked: gorevler.requestActivate(gorevler.makeModelIndex(og.index))
            }
        }
    }

    // alt şerit: Diğer ayrıntılar / Görevi sonlandır
    Rectangle {
        id: alt
        anchors.bottom: parent.bottom
        width: parent.width; height: 46
        color: "#f0f0f0"
        Rectangle { width: parent.width; height: 1; color: "#dfdfdf" }
        Row {
            x: 10; anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Rectangle {
                width: 16; height: 16; radius: 8
                anchors.verticalCenter: parent.verticalCenter
                color: dma.containsMouse ? "#e5f3ff" : "transparent"
                border.color: dma.containsMouse ? "#3399ff" : "#7a7a7a"
                Canvas {
                    anchors.centerIn: parent; width: 8; height: 5
                    onPaint: { var c = getContext("2d"); c.reset(); c.strokeStyle = "#333"; c.lineWidth = 1.2
                               c.beginPath(); c.moveTo(0.5, 0.5); c.lineTo(4, 4); c.lineTo(7.5, 0.5); c.stroke() }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Diğer ayrıntılar"
                color: dma.containsMouse ? "#3399ff" : "#000"
                font.family: "Segoe UI"; font.pixelSize: 12
            }
        }
        MouseArea {
            id: dma
            x: 6; width: 130; height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { pen.close(); pen.ana.hizliEylem("gorevAyrinti") }
        }
        // Windows 8 düğmesi (aero.msstyles Button renkleri)
        Rectangle {
            id: dugme
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(96, dy.implicitWidth + 24); height: 23
            readonly property bool etkin: pen.secim >= 0 && pen.secim < gorevler.count
            border.color: !etkin ? "#bfbfbf" : (bma.pressed ? "#569de5" : (bma.containsMouse ? "#7eb4ea" : "#acacac"))
            gradient: Gradient {
                GradientStop { position: 0; color: !dugme.etkin ? "#f4f4f4" : (bma.pressed ? "#daecfc" : (bma.containsMouse ? "#ecf4fc" : "#f0f0f0")) }
                GradientStop { position: 1; color: !dugme.etkin ? "#f4f4f4" : (bma.pressed ? "#c4e0fc" : (bma.containsMouse ? "#dcecfc" : "#e5e5e5")) }
            }
            Text {
                id: dy
                anchors.centerIn: parent
                textFormat: Text.StyledText
                text: "G<u>ö</u>revi sonlandır"
                color: dugme.etkin ? "black" : "#838383"
                font.family: "Segoe UI"; font.pixelSize: 12
            }
            MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true; enabled: dugme.etkin; onClicked: pen.sonlandir() }
        }
    }
}
