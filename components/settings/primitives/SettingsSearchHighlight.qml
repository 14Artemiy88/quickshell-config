import QtQuick
import QtQuick.Controls

import "../../.."

Item {
    id: root

    property bool highlighted: false
    property bool currentMatch: false
    property string matchHint: ""
    property real cornerRadius: 4
    property int overlayZ: 5

    z: root.overlayZ
    visible: root.highlighted

    HoverHandler {
        id: matchHover
        enabled: root.highlighted && root.matchHint.length > 0
    }

    ToolTip.visible: matchHover.hovered
        && root.highlighted && root.matchHint.length > 0
    ToolTip.text: root.matchHint
    ToolTip.delay: 450

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.currentMatch
            ? Config.accent
            : Config.settingsSearchHighlightColor
        border.width: Config.settingsSearchHighlightBorderWidth
            + (root.currentMatch ? 1 : 0)
        radius: root.cornerRadius
    }
}
