import QtQuick
import QtQuick.Controls
import "../../.."

CheckBox {
    id: root

    // Settings search metadata is intentionally independent from displayed labels.
    property bool settingsSearchable: true
    property bool settingsSearchHighlighted: false
    property bool settingsSearchCurrentMatch: false
    property string settingsSearchMatchHint: ""
    property string settingsSearchId: ""
    property string settingsSearchLabel: ""
    property string settingsSearchKeywords: ""
    property int settingsSearchSubTabIndex: -1

    property bool pointerHovered: checkHoverArea.containsMouse
    property bool indicatorOnly: false
    property real labelFontSize: 11
    property real labelLeftPadding: 5
    property bool labelElide: true

    opacity: root.enabled ? 1 : 0.55

    SettingsSearchHighlight {
        anchors.fill: parent
        overlayZ: 2
        highlighted: root.settingsSearchHighlighted
        currentMatch: root.settingsSearchCurrentMatch
        matchHint: root.settingsSearchMatchHint
        cornerRadius: 4
    }

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

    Rectangle {
        anchors.fill: parent
        z: 2
        visible: root.settingsSearchHighlighted
        color: "transparent"
        border.color: root.settingsSearchCurrentMatch ? Config.accent : Config.settingsSearchHighlightColor
        border.width: Config.settingsSearchHighlightBorderWidth + (root.settingsSearchCurrentMatch ? 1 : 0)
        radius: 4
    }

    contentItem: SettingsLabel {
        visible: !root.indicatorOnly
        text: root.text
        color: root.enabled ? Config.text : Config.textMuted
        settingsFontSize: root.labelFontSize
        leftPadding: root.indicator.width + root.labelLeftPadding
        elide: root.labelElide ? Text.ElideRight : Text.ElideNone
    }
}
