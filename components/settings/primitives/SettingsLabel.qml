import QtQuick
import "../../.."

// Shared label primitive for standard settings rows.
// Callers only specify layout and text; typography stays consistent.
Text {
    id: root

    property real settingsFontSize: 11

    color: Config.text
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(root.settingsFontSize)
    verticalAlignment: Text.AlignVCenter
}
