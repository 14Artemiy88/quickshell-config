import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"

// Shared renderer for settings pages other than Modules and Themes.
// Page sections are supplied by SettingsWidget through the default content alias,
// keeping page ownership and stable-ID routing in the parent while this component
// owns the common scroll, heading, save/reset actions and subtab navigation.
Item {
    id: root

    property var host: null
    property var settings: Settings
    default property alias pageContent: otherColumn.data

    function resetScroll() {
        otherFlick.contentY = 0
    }

    Flickable {
        id: otherFlick
        anchors.fill: parent
        contentWidth: Math.max(width, otherColumn.width)
        contentHeight: otherColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton
            onClicked: if (root.host) root.host.clearSettingsFocus()
        }

        ScrollBar.vertical: SettingsScrollBar {
            visible: otherFlick.contentHeight > otherFlick.height + 1
        }

        Column {
            id: otherColumn
            width: otherFlick.width - 12
            spacing: 10

            Row {
                width: parent.width
                height: 30

                Text {
                    width: parent.width
                        - (root.host && root.host.quickSaveProfileAvailable ? 38 : 0)
                        - (root.host && root.host.quickSavePageAvailable ? 38 : 0)
                        - (root.host && root.host.currentPageResetAvailable ? 38 : 0)
                    text: root.host ? root.host.currentPageTitle : ""
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(15)
                    verticalAlignment: Text.AlignVCenter
                }

                SettingsSaveButton {
                    actionAvailable: root.host && root.host.quickSaveProfileAvailable
                    iconText: "󰆔"
                    tooltip: "Сохранить всё в активный профиль"
                    onClicked: root.host.profileController.saveAll()
                }

                SettingsSaveButton {
                    actionAvailable: root.host && root.host.quickSavePageAvailable
                    tooltip: "Сохранить изменения этого раздела в активный профиль"
                    onClicked: root.host.profileController.saveScope(root.host.currentPageSaveScope)
                }

                SettingsResetButton {
                    enabled: root.host && root.host.profileController.hasActiveProfile
                    visible: root.host && root.host.currentPageResetAvailable
                    actionAvailable: root.host
                        && root.host.currentPageSaveScope !== ""
                        && root.host.profileController.canResetScope(root.host.currentPageSaveScope)
                    tooltip: "Сбросить текущую вкладку"
                    onClicked: if (root.host) root.host.resetCurrentSettingsPage()
                }
            }

            Row {
                visible: root.host && root.host.currentPageSubTabs.length > 0
                width: parent.width
                height: 34
                spacing: 5

                Repeater {
                    model: root.host ? root.host.currentPageSubTabs : []

                    delegate: SettingsSubTab {
                        width: root.host && root.host.currentPageSubTabs.length > 0
                            ? (parent.width - (root.host.currentPageSubTabs.length - 1) * 5) / root.host.currentPageSubTabs.length
                            : parent.width
                        selected: root.host && root.host.currentPageSubTabIndex === index
                        modified: root.host && root.host.settingsSubTabHasChanges(root.host.currentPageId, index)
                        settingsSearchMatched: root.host && root.host.settingsSearchSubTabHasMatches(root.host.currentPageId, index)
                        settingsSearchMatchHint: root.host
                            ? root.host.settingsSearchSubTabMatchHint(root.host.currentPageId, index) : ""
                        settingsSearchMatchCount: root.host
                            ? root.host.settingsSearchSubTabMatchCount(root.host.currentPageId, index) : 0
                        text: modelData
                        onClicked: {
                            if (!root.host) return
                            // SettingsSubTab has already received focus from the
                            // mouse or keyboard activation; retain it while the
                            // selected subtab's content is replaced.
                            root.host.currentPageSubTabIndex = index
                            root.resetScroll()
                        }
                    }
                }
            }
        }
    }
}
