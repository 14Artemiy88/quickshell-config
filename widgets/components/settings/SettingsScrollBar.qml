import QtQuick
import QtQuick.Controls
import "../.."

ScrollBar {
    id: root

    width: 6
    policy: ScrollBar.AsNeeded

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Rectangle {
        implicitWidth: 6
        radius: 3
        color: root.pressed || root.hovered ? Config.accent : Config.baseColor
        opacity: root.pressed || root.hovered ? 0.9 : 0.65
    }
}
