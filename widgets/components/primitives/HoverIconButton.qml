import QtQuick
import ".."
import "../.."
import "." as Primitives

Item {
    id: root

    property string iconText: ""
    property int iconSize: 16
    property int iconX: 0
    property int iconY: 0
    property color baseColor: Config.textMuted
    property string hoverMode: "none"
    property color hoverColor: Config.accent
    property string toolTipText: ""
    property string iconFontFamily: Config.font
    property bool interactionEnabled: true
    property int cursorShape: Qt.PointingHandCursor
    property real cornerRadius: 4

    signal clicked()

    implicitWidth: 22
    implicitHeight: 22
    readonly property bool hovered: surface.hovered

    Primitives.HoverButtonSurface {
        id: surface
        anchors.fill: parent
        hoverBackgroundEnabled: root.hoverMode === "background"
        hoverBackgroundColor: root.hoverColor
        hoverBorderEnabled: root.hoverMode === "frame"
        hoverBorderColor: root.hoverColor
        hoverBorderWidth: 1
        cornerRadius: root.cornerRadius
        interactionEnabled: root.interactionEnabled
        cursorShape: root.cursorShape
        toolTipText: root.toolTipText
        onClicked: root.clicked()

        Text {
            anchors.fill: parent
            text: root.iconText
            color: root.hovered && root.hoverMode === "text" ? root.hoverColor : root.baseColor
            font.family: root.iconFontFamily
            font.pixelSize: root.iconSize
            y: root.iconY
            transform: Translate { x: root.iconX }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
