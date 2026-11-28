import QtQuick
import "../../.."

// Optional explanatory copy for settings. The global user preference hides
// only these helper paragraphs; labels, field values, errors and tooltips stay visible.
Text {
    id: root

    property bool descriptionConditionVisible: true

    visible: Config.settingsShowDescriptions && root.descriptionConditionVisible
    color: Config.textMuted
    font.family: Config.settingsFontFamily
    font.pixelSize: Config.settingsUiSize(9)
    wrapMode: Text.WordWrap
}
