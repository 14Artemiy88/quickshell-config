import QtQuick
import "../../.."
import "../primitives"
import "../sections"

// Composite page for the Player settings. The page root owns its stable search
// identity; individual controls and subtabs remain implemented by the section.
Column {
    id: root

    objectName: "settings-search-page:player"
    property var host: null
    property var settings: Settings

    visible: host && host.currentPageId === "player"
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
                visible: root.host && root.host.currentPageId === "player" && root.host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        SettingsNumberField {
            visible: root.host && root.host.currentPageId === "player" && root.host.currentPageSubTabIndex === 0
            width: parent.width
            label: "Плеер (мс)"
            value: Config.playerUpdateInterval
            minimum: 50
            maximum: 5000
            step: 50
            wheelStep: 50
            onValueEdited: value => { Config.playerUpdateInterval = value; root.settings.save() }
        }
    }

    SettingsPlayerSection {
        width: parent.width
        host: root.host
        settings: root.settings
    }
    SettingsPlayerAnimationSection {
        width: parent.width
        host: root.host
        settings: root.settings
    }
}
