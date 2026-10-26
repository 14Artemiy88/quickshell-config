import QtQuick
import QtQuick.Controls
import "../../.."

Item {
    id: root
    // Disabled actions are omitted from the interface rather than rendered as inert controls.
    visible: enabled

    property string text: ""
    property string iconText: ""
    property string iconFontFamily: "Symbols Nerd Font Mono"
    property bool emphasized: false
    property bool fillOnHover: false
    property bool borderOnHover: true
    property color accentColor: Config.accent
    property color outlineColor: Config.baseColor
    property color backgroundColor: "transparent"
    property color hoverBackgroundColor: root.accentColor
    property color textColor: Config.text
    property color hoverTextColor: Config.black
    property color disabledTextColor: Config.textMuted
    property color disabledBorderColor: Config.baseColor
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
            ? root.disabledBorderColor
            : (root.emphasized || (root.borderOnHover && mouse.containsMouse)
                ? root.accentColor
                : root.outlineColor)
        border.width: root.borderWidth

        Text {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            visible: root.iconText.length === 0
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

        Row {
            visible: root.iconText.length > 0
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: root.iconText
                color: !root.enabled ? root.disabledTextColor
                    : (root.fillOnHover && mouse.containsMouse ? root.hoverTextColor
                       : (root.emphasized ? root.accentColor : root.textColor))
                font.family: root.iconFontFamily
                font.pixelSize: Config.settingsUiSize(root.fontSize + 1)
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                text: root.text
                color: !root.enabled ? root.disabledTextColor
                    : (root.fillOnHover && mouse.containsMouse ? root.hoverTextColor
                       : (root.emphasized ? root.accentColor : root.textColor))
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(root.fontSize)
                font.bold: root.fontBold || root.emphasized
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
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
