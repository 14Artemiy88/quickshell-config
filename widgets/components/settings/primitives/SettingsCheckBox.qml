import QtQuick
import QtQuick.Controls
import "../../.."

CheckBox {
    id: root

    property bool pointerHovered: checkHoverArea.containsMouse
    property bool indicatorOnly: false
    property real labelFontSize: 11
    property real labelLeftPadding: 5
    property bool labelElide: true

    MouseArea {
        id: checkHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        x: root.indicatorOnly ? Math.round((root.width - width) / 2) : 0
        radius: 4
        color: root.checked ? Config.accent : Config.settingsBackground
        border.width: 1
        border.color: root.enabled && (root.pointerHovered || root.activeFocus)
            ? Config.accent : Config.baseColor

        Text {
            anchors.centerIn: parent
            text: "✓"
            visible: root.checked
            color: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            font.bold: true
        }
    }

    contentItem: Text {
        visible: !root.indicatorOnly
        text: root.text
        color: root.enabled ? Config.text : Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(root.labelFontSize)
        leftPadding: root.indicator.width + root.labelLeftPadding
        verticalAlignment: Text.AlignVCenter
        elide: root.labelElide ? Text.ElideRight : Text.ElideNone
    }
}
