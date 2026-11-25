import QtQuick
import QtQuick.Controls
import "../../.."

// Shared large page title and profile actions used by every settings page.
// Modules and Themes opt into explicit scopes because they are custom pages.
Row {
    id: root

    property var host: null
    property string saveScope: ""
    property bool showResetButton: false
    property string resetTooltip: "Сбросить текущую вкладку"
    signal resetRequested()

    readonly property string resolvedSaveScope: root.saveScope.length > 0
        ? root.saveScope : (root.host ? root.host.currentPageSaveScope : "")
    readonly property bool canSaveAll: root.host && root.host.profileController
        && root.host.profileController.canSaveScope("all")
    readonly property bool canSavePage: root.host && root.host.profileController
        && root.resolvedSaveScope.length > 0
        && root.host.profileController.canSaveScope(root.resolvedSaveScope)
    readonly property bool canResetPage: root.showResetButton && root.host
        && root.host.profileController && root.resolvedSaveScope.length > 0
        && root.host.profileController.canResetScope(root.resolvedSaveScope)

    width: parent ? parent.width : 0
    height: 30

    Text {
        width: Math.max(0, parent.width
            - (root.canSaveAll ? 38 : 0)
            - (root.canSavePage ? 38 : 0)
            - (root.canResetPage ? 38 : 0))
        text: root.host ? root.host.currentPageTitle : ""
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(15)
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    SettingsSaveButton {
        actionAvailable: root.canSaveAll
        iconText: "󰆔"
        tooltip: "Сохранить всё в активный профиль"
        onClicked: root.host.profileController.saveAll()
    }

    SettingsSaveButton {
        actionAvailable: root.canSavePage
        tooltip: "Сохранить изменения этого раздела в активный профиль"
        onClicked: root.host.profileController.saveScope(root.resolvedSaveScope)
    }

    SettingsResetButton {
        enabled: root.host && root.host.profileController.hasActiveProfile
        visible: root.canResetPage
        actionAvailable: root.canResetPage
        tooltip: root.resetTooltip
        onClicked: root.resetRequested()
    }
}
