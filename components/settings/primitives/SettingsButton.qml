import QtQuick
import QtQuick.Controls
import "../../.."

Item {
    id: root

    property string text: ""
    property bool emphasized: false
    property bool fillOnHover: true
    property bool borderOnHover: true
    property color accentColor: Config.accent
    property color backgroundColor: "transparent"
    property color hoverBackgroundColor: root.accentColor
    property color textColor: Config.text
    property color hoverTextColor: Config.black
    property color disabledTextColor: Config.textMuted
    property real radius: Config.radius
    property real borderWidth: Math.max(1, Config.frameBorderWidth)
    property real fontSize: 10
    property bool fontBold: false
    property alias hovered: mouse.containsMouse
    property alias mouseArea: mouse
    property int cursorShape: Qt.PointingHandCursor
    property string tooltip: ""
    property int tooltipDelay: 500

    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: !root.enabled
            ? root.backgroundColor
            : (root.fillOnHover && mouse.containsMouse
                ? root.hoverBackgroundColor
                : root.backgroundColor)
        border.color: !root.enabled
            ? Config.baseColor
            : (root.borderOnHover || root.emphasized
                ? root.accentColor
                : Config.baseColor)
        border.width: root.borderWidth

        Text {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            text: root.text
            color: !root.enabled
                ? root.disabledTextColor
                : (root.fillOnHover && mouse.containsMouse
                    ? root.hoverTextColor
                    : (root.emphasized ? root.accentColor : root.textColor))
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fontSize)
            font.bold: root.fontBold || root.emphasized
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.cursorShape
        onClicked: root.clicked()
    }

    ToolTip.visible: root.tooltip.length > 0 && mouse.containsMouse
    ToolTip.text: root.tooltip
    ToolTip.delay: root.tooltipDelay
}
