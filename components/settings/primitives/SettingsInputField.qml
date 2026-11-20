import QtQuick
import QtQuick.Controls
import "../../.."

TextField {
    id: root

    property bool pointerHovered: hoverArea.containsMouse
    // Optional validation state shared by text fields across settings pages.
    property bool validationFailed: false
    property bool settingsSearchHighlighted: false
    property bool settingsSearchCurrentMatch: false
    property string settingsSearchMatchHint: ""
    // Optional inline clear affordance for compact search fields.
    property bool clearButtonEnabled: false

    rightPadding: root.clearButtonEnabled ? 30 : 8

    function clearSettingsFocus() {
        var item = parent
        while (item) {
            if (
                item.objectName === "quickshellSettingsWidget" &&
                item.forceActiveFocus
            ) {
                item.forceActiveFocus()
                return
            }
            item = item.parent
        }

        root.focus = false
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    onAccepted: root.clearSettingsFocus()

    ToolTip.visible: root.settingsSearchHighlighted
        && root.settingsSearchMatchHint.length > 0 && root.pointerHovered
    ToolTip.text: root.settingsSearchMatchHint
    ToolTip.delay: 450


    ToolButton {
        id: clearButton
        visible: root.clearButtonEnabled && root.text.length > 0
        enabled: visible
        width: 22
        height: 22
        z: 2
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        padding: 0
        focusPolicy: Qt.NoFocus
        onClicked: {
            root.clear()
            root.forceActiveFocus()
        }
        contentItem: Text {
            text: "×"
            color: clearButton.hovered ? Config.accent : Config.baseColor
            font.family: root.font.family
            font.pixelSize: Math.max(14, root.font.pixelSize + 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: clearButton.hovered ? Config.settingsBorder : "transparent"
            radius: 4
        }
    }

    background: Rectangle {
        color: Config.settingsBackground
        border.color: root.settingsSearchCurrentMatch ? Config.accent
            : (root.settingsSearchHighlighted ? Config.settingsSearchHighlightColor
            : (root.validationFailed
                ? ((root.activeFocus || root.pointerHovered) ? "#ff6666" : "#ff9999")
                : ((root.activeFocus || root.pointerHovered) ? Config.accent : Config.baseColor)))
        border.width: root.settingsSearchCurrentMatch ? Config.settingsSearchHighlightBorderWidth + 1
            : (root.settingsSearchHighlighted ? Config.settingsSearchHighlightBorderWidth : (root.validationFailed ? Math.max(1, Config.frameBorderWidth) : 1))
        radius: 4
    }
}
