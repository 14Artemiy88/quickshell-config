import QtQuick
import QtQuick.Controls
import ".."
import "../.."

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
    readonly property bool isHovered: mouseArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.isHovered && root.hoverMode === "background" ? root.hoverColor : Config.transparent
        border.width: root.isHovered && root.hoverMode === "frame" ? 1 : 0
        border.color: root.hoverColor
    }

    Text {
        anchors.fill: parent
        text: root.iconText
        color: root.isHovered && root.hoverMode === "text" ? root.hoverColor : root.baseColor
        font.family: Config.font
        font.pixelSize: root.iconSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactionEnabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ToolTip.visible: root.toolTipText.length > 0 && root.isHovered
    ToolTip.text: root.toolTipText
}
