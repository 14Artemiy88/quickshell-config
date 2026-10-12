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
    signal clicked()

    implicitWidth: 22
    implicitHeight: 22
    readonly property bool isHovered: hoverButton.hovered

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
