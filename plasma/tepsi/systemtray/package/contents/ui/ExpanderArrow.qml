/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg as KSvg

PlasmaCore.ToolTipArea {
    id: tooltip

    readonly property int arrowAnimationDuration: Kirigami.Units.shortDuration
    property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property int iconSize: Kirigami.Units.smallMedium
    property int expanderSize: Kirigami.Units.iconSizes.smallMedium - Kirigami.Units.smallSpacing / 2
    implicitWidth: expanderSize+1
    implicitHeight: expanderSize
    activeFocusOnTab: true

    Accessible.name: subText
    Accessible.description: "Bildirim alanındaki bütün simgeleri gösterir"
    Accessible.role: Accessible.Button
    Accessible.onPressAction: systemTrayState.expanded = !systemTrayState.expanded

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            systemTrayState.expanded = !systemTrayState.expanded;
        }
    }

    subText: systemTrayState.expanded ? "Kapat" : "Gizli simgeleri göster"

    property bool wasExpanded

    property bool flyoutExpanded: systemTrayState.expanded
    onFlyoutExpandedChanged: {
        if(flyoutExpanded) {
            tooltip.hideImmediately();
        }
    }

    TapHandler {
        onTapped: {
            systemTrayState.expanded = !systemTrayState.expanded;
            //systemTrayState.expanded = !tooltip.wasExpanded;
            expandedRepresentation.hiddenLayout.currentIndex = -1;
        }
    }

    // Windows 8: koyu görev çubuğunda küçük beyaz üçgen; üzerindeyken ve açıkken düz açık zemin
    Rectangle {
        id: arrow
        z: -1
        anchors.centerIn: parent
        width: expanderSize + 1
        height: Math.min(tooltip.height, 38)
        readonly property bool acik: systemTrayState.expanded && expandedRepresentation.hiddenLayout.visible
        color: tooltip.containsPress || acik ? Qt.rgba(1, 1, 1, 0.22) : (tooltip.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
        border.color: tooltip.containsMouse || acik ? Qt.rgba(1, 1, 1, 0.25) : "transparent"
        Canvas {
            anchors.centerIn: parent
            width: 9; height: 5
            readonly property string yon: Plasmoid.location === PlasmaCore.Types.TopEdge ? "asagi"
                                         : (Plasmoid.location === PlasmaCore.Types.LeftEdge ? "sag"
                                         : (Plasmoid.location === PlasmaCore.Types.RightEdge ? "sol" : "yukari"))
            rotation: yon === "asagi" ? 180 : (yon === "sag" ? 90 : (yon === "sol" ? -90 : 0))
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.fillStyle = "white"
                c.beginPath(); c.moveTo(0, 5); c.lineTo(4.5, 0.5); c.lineTo(9, 5); c.closePath(); c.fill()
            }
        }
    }
}
