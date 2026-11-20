import QtQuick
import QtQuick.Controls
import "../../.."

TextField {
    id: root

    property bool pointerHovered: hoverArea.containsMouse
    // Optional validation state shared by text fields across settings pages.
    property bool validationFailed: false

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

    background: Rectangle {
        color: Config.settingsBackground
        border.color: root.validationFailed
            ? ((root.activeFocus || root.pointerHovered) ? "#ff6666" : "#ff9999")
            : ((root.activeFocus || root.pointerHovered) ? Config.accent : Config.baseColor)
        border.width: root.validationFailed ? Math.max(1, Config.frameBorderWidth) : 1
        radius: 4
    }
}
