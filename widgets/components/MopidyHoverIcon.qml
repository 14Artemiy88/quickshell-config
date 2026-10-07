import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root
    property string iconText: ""
    property int iconSize: 16
    property int iconX: 0
    property int iconY: 0
    property color baseColor: Config.mopidyControlIconColor
    property bool enabledState: true
    property bool activeState: false
    property string toolTipText: ""
    signal clicked()
    property alias hovered: mouseArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: mouseArea.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.transparent
        border.width: mouseArea.containsMouse && Config.mopidyHoverMode === "frame" ? 1 : 0
        border.color: Config.mopidyHoverColor
    }

    Text {
        anchors.fill: parent
        text: root.iconText
        color: mouseArea.containsMouse && Config.mopidyHoverMode === "text" ? Config.mopidyHoverColor : root.baseColor
        font.family: Config.font
        font.pixelSize: root.iconSize
        y: root.iconY
        transform: Translate { x: root.iconX }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabledState
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ToolTip.visible: root.toolTipText.length > 0 && mouseArea.containsMouse
    ToolTip.text: root.toolTipText
}
