import QtQuick
import "../../.."
import "../sections/mopidy" as MopidySettings

// Mopidy is composed from focused sections, one for each registered subtab.
// This page root supplies the single stable search identity for the group.
Column {
    id: root

    objectName: "settings-search-page:mopidy"
    property var host: null
    property var settings: Settings

    visible: host && host.currentPageId === "mopidy"
    width: parent ? parent.width : 0
    spacing: 10

    MopidySettings.SettingsMopidySection {
        host: root.host
        settings: root.settings
    }
    MopidySettings.SettingsMopidyTimeSection {
        host: root.host
        settings: root.settings
    }
    MopidySettings.SettingsMopidyIconsSection {
        host: root.host
        settings: root.settings
    }
    MopidySettings.SettingsMopidyStatusSection {
        host: root.host
        settings: root.settings
    }
    MopidySettings.SettingsMopidyAnimationSection {
        host: root.host
        settings: root.settings
    }
}
