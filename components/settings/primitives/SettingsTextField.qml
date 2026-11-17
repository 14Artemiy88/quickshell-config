import QtQuick
import QtQuick.Controls

SettingsInputField {
    id: root

    property bool settingsSearchable: true
    property string settingsSearchId: ""
    property string settingsSearchLabel: ""
    property string settingsSearchKeywords: ""
    property bool settingsSearchUseSiblingLabel: true
}
