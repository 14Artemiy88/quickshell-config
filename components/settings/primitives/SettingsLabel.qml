import QtQuick
import "../../.."

// Shared label primitive for standard settings rows.
// Callers only specify layout and text; typography stays consistent.
Text {
    id: root

    property real settingsFontSize: 11

    color: root.enabled ? Config.text : Config.textMuted
    font.family: Config.settingsFontFamily
    font.pixelSize: Config.settingsUiSize(root.settingsFontSize)
    verticalAlignment: Text.AlignVCenter
}
