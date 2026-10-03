import QtQuick
import QtQuick.Controls
import "../.."

TextField {
    id: root

    property bool pointerHovered: hoverArea.containsMouse

    function clearSettingsFocus() {
        var item = parent
        while (item) {
            if (item.objectName === "quickshellSettingsWidget" && item.forceActiveFocus) {
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

    onAccepted: clearSettingsFocus()

    background: Rectangle {
        color: Config.settingsBackground
        border.color: (root.activeFocus || root.pointerHovered) ? Config.accent : Config.baseColor
        border.width: 1
        radius: 4
    }
}
