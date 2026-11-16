import QtQuick
import ".."
import "../.."
import "." as Primitives

Item {
    id: root

    property string iconText: ""
    property int iconSize: 16
    property color baseColor: Config.textMuted
    property string hoverMode: "none"
    property color hoverColor: Config.accent
    property string toolTipText: ""
    property bool interactionEnabled: true
    property bool requestedVisible: true
    property bool hideWhenDisabled: true
    // Opt-in visual transition for runtime lists whose boundary arrows appear/disappear.
    // The outer item keeps its assigned slot so list geometry and hit targets stay stable.
    property bool morphVisibility: false
    readonly property real morphVisibilityProgress: root.requestedVisible ? 1 : 0

    // Hide unavailable directions by default. Consumers such as Mopidy can
    // keep an available arrow visible while temporarily disabling interaction.
    visible: root.morphVisibility || root.requestedVisible
    // Keep the layout slot when a direction is unavailable, but do not draw or hit-test it.
    opacity: (!root.hideWhenDisabled || root.interactionEnabled) ? 1 : 0
    enabled: root.requestedVisible && (!root.hideWhenDisabled || root.interactionEnabled)

    signal clicked()

    implicitWidth: 22
    implicitHeight: 22
    readonly property bool isHovered: hoverButton.hovered

    Primitives.MorphGeometry {
        id: visibilityMorph
        fromGeometry: Qt.rect(1, 1, Math.max(0, root.width - 2), Math.max(0, root.height - 2))
        toGeometry: Qt.rect(0, 0, root.width, root.height)
        progress: root.morphVisibility ? root.morphVisibilityProgress : 1
        visible: !root.morphVisibility || root.requestedVisible || normalizedProgress > 0.001
        animationDuration: root.morphVisibility ? Config.animationDuration(180, "appearance") : 0
        animationEasing: Config.animationEasingType("standard", root.requestedVisible ? "enter" : "exit")

        Item {
            anchors.fill: parent
            opacity: root.morphVisibility ? visibilityMorph.normalizedProgress : 1
            scale: root.morphVisibility ? 0.96 + 0.04 * visibilityMorph.normalizedProgress : 1
            transformOrigin: Item.Center

            Primitives.HoverIconButton {
                id: hoverButton
                anchors.fill: parent
                iconText: root.iconText
                iconSize: root.iconSize
                baseColor: root.baseColor
                hoverMode: root.hoverMode
                hoverColor: root.hoverColor
                toolTipText: root.toolTipText
                interactionEnabled: root.interactionEnabled
                onClicked: root.clicked()
            }
        }
    }
}
