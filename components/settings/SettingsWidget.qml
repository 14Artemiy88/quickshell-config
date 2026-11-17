import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"
import "../../js/settings/SettingsPageRegistry.js" as SettingsPageRegistry

Item {
    id: root
    objectName: "quickshellSettingsWidget"

    function wheelDelta(wheel, step) {
        var direction = wheel.angleDelta.y > 0 ? 1 : -1
        var multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
        return direction * step * multiplier
    }
    property var settings: Settings
    property bool settingsMoveMode: false
    property alias profileController: settingsProfileController
    readonly property bool quickSaveProfileAvailable: profileController.canSaveScope("all")
    readonly property string currentPageSaveScope: SettingsPageRegistry.saveScopeForPageId(
        root.currentPageId, root.currentPageSubTabIndex)
    readonly property bool quickSavePageAvailable: profileController.canSaveScope(root.currentPageSaveScope)
    readonly property bool currentPageResetAvailable: !(root.currentPageId === "general" && (root.currentPageSubTabIndex === 1 || root.currentPageSubTabIndex === 2)) && profileController.canResetScope(root.currentPageSaveScope)
    // Search state is owned by a dedicated controller; aliases keep the
    // existing SettingsWidget-facing API used by the search UI.
    property alias settingsSearchIndex: settingsSearchController.settingsSearchIndex
    property alias settingsSearchResults: settingsSearchController.settingsSearchResults
    property alias settingsSearchQuery: settingsSearchController.settingsSearchQuery
    property alias settingsSearchSelectedIndex: settingsSearchController.settingsSearchSelectedIndex
    property alias settingsSearchCandidateSubTab: settingsSearchController.settingsSearchCandidateSubTab
    signal layoutEditRequested()
    signal settingsMoveRequested()
    signal closeRequested()
    clip: true

    Shortcut {
        sequence: "Esc"
        enabled: !root.settingsMoveMode
        onActivated: root.closeRequested()
    }

    SettingsProfileController {
        id: settingsProfileController
        settings: root.settings
    }

    SettingsSearchController {
        id: settingsSearchController
        host: root
        searchRoot: root
        searchInput: settingsSearchInput
        highlight: settingsSearchHighlight
        highlightTimer: settingsSearchHighlightTimer
    }

    function clearSettingsFocus() {
        root.forceActiveFocus()
    }

    function resetSettingsPageScroll() {
        if (settingsPageContent) settingsPageContent.resetScroll()
    }

    function openWeatherSettings() {
        root.currentPageId = "weather"
        root.currentPageSubTabIndex = 0
        root.clearSettingsFocus()
    }

    // Background click catcher. It stays behind the settings content,
    // so controls and tabs keep receiving their own mouse events.
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton
        onClicked: root.clearSettingsFocus()
    }

    SettingsNavigationController {
        id: settingsNavigationController
        host: root
        settings: root.settings
    }

    property alias currentPageId: settingsNavigationController.currentPageId
    property alias currentPageSubTabIndex: settingsNavigationController.currentPageSubTabIndex
    readonly property var settingsTabDefinitions: settingsNavigationController.settingsTabDefinitions
    readonly property var settingsNavigationItems: settingsNavigationController.settingsNavigationItems
    readonly property var currentPageSubTabs: settingsNavigationController.currentPageSubTabs
    readonly property string currentPageTitle: settingsNavigationController.currentPageTitle

    function defaultSettingsTabLabel(id) { return settingsNavigationController.defaultSettingsTabLabel(id) }
    function settingsTabLabelForId(id) { return settingsNavigationController.settingsTabLabelForId(id) }
    function settingsTabOrderNormalized() { return settingsNavigationController.settingsTabOrderNormalized() }
    function isSettingsTabSelected(id) { return settingsNavigationController.isSettingsTabSelected(id) }
    function settingsSubTabChangeSpec(pageId, sub) { return settingsNavigationController.settingsSubTabChangeSpec(pageId, sub) }
    function settingsSubTabHasChanges(pageId, sub) { return settingsNavigationController.settingsSubTabHasChanges(pageId, sub) }
    function settingsTabHasChanges(id) { return settingsNavigationController.settingsTabHasChanges(id) }
    function selectSettingsTab(id) { return settingsNavigationController.selectSettingsTab(id) }
    function resetCurrentSettingsPage() { return settingsNavigationController.resetCurrentSettingsPage() }
    function setSettingsTabLabel(id, value) { return settingsNavigationController.setSettingsTabLabel(id, value) }
    function moveSettingsTab(id, delta) { return settingsNavigationController.moveSettingsTab(id, delta) }

    function rebuildSettingsSearchIndex() {
        settingsSearchController.rebuildSettingsSearchIndex()
    }

    function updateSettingsSearchResults(query) {
        settingsSearchController.updateSettingsSearchResults(query)
    }

    function openSettingsSearchResult(entry) {
        settingsSearchController.openSettingsSearchResult(entry)
    }

    function handleSettingsSearchKey(event) {
        settingsSearchController.handleSettingsSearchKey(event)
    }

    Component.onCompleted: Qt.callLater(root.rebuildSettingsSearchIndex)

    Rectangle {
        anchors.fill: parent
        color: Config.settingsBackground
        border.color: Config.settingsBorder
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius
        antialiasing: true
    }

    Column {
        anchors.fill: parent
        anchors.margins: Config.settingsPadding
        spacing: Config.settingsSpacing

        Row {
            width: parent.width
            height: 28
            Text {
                width: Math.max(70, parent.width - settingsSearchInput.width - 260)
                text: "НАСТРОЙКИ"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(20)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsInputField {
                id: settingsSearchInput
                width: Math.min(220, Math.max(145, parent.width * 0.30))
                height: 28
                placeholderText: "Поиск настроек…"
                selectByMouse: true
                activeFocusOnTab: true
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                onTextChanged: root.updateSettingsSearchResults(text)
                onActiveFocusChanged: if (activeFocus) Qt.callLater(root.rebuildSettingsSearchIndex)
                Keys.onPressed: event => root.handleSettingsSearchKey(event)
            }
            Text {
                id: resetIndicator
                width: 140
                text: "Сначала сохраните профиль"
                color: Config.accent
                opacity: 0
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: saveIndicator
                width: 120
                text: "✓ сохранено"
                color: Config.accent
                opacity: 0
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
        SequentialAnimation {
            id: savePulse
            PropertyAnimation { target: saveIndicator; property: "opacity"; to: 0.9; duration: Config.animationDuration(100, "appearance"); easing.type: Config.easingType() }
            PauseAnimation { duration: Config.animationDuration(500, "appearance") }
            PropertyAnimation { target: saveIndicator; property: "opacity"; to: 0; duration: Config.animationDuration(350, "appearance"); easing.type: Config.easingType() }
        }
        Connections { target: settings; function onSaved() { savePulse.restart() } }
        SequentialAnimation {
            id: resetPulse
            PropertyAnimation { target: resetIndicator; property: "opacity"; to: 1; duration: Config.animationDuration(100, "appearance"); easing.type: Config.easingType() }
            PauseAnimation { duration: Config.animationDuration(1300, "appearance") }
            PropertyAnimation { target: resetIndicator; property: "opacity"; to: 0; duration: Config.animationDuration(250, "appearance"); easing.type: Config.easingType() }
        }
        Connections { target: settings; function onResetUnavailable(message) { resetIndicator.text = message; resetPulse.restart() } }

        Row {
            id: settingsBody
            width: parent.width
            height: parent.height - y
            // Keep the settings text visually separated from the sidebar tabs.
            spacing: 16

            Column {
                id: mainSettingsTabs
                width: 128
                height: parent.height
                spacing: 5

                Repeater {
                    model: root.settingsNavigationItems

                    delegate: SettingsSubTab {
                        width: mainSettingsTabs.width
                        selected: root.isSettingsTabSelected(modelData.id)
                        modified: root.settingsTabHasChanges(modelData.id)
                        text: modelData.label
                        leftAligned: true
                        horizontalPadding: 8
                        onClicked: root.selectSettingsTab(modelData.id)
                    }
                }
            }

            SettingsPageContent {
                id: settingsPageContent
                width: parent.width - mainSettingsTabs.width - 16
                height: parent.height
                host: root
                settings: root.settings
            }
        }
    }

    // Search results are rendered above the settings pages so they remain
    // usable regardless of the active page's own Flickable/scroll container.
    Rectangle {
        id: settingsSearchPopup
        z: 1000
        visible: settingsSearchInput.activeFocus && root.settingsSearchQuery.trim().length > 0
        x: {
            var inputPosition = settingsSearchInput.mapToItem(root, 0, 0)
            return Math.max(8, Math.min(root.width - width - 8, inputPosition.x + settingsSearchInput.width - width))
        }
        y: settingsSearchInput.mapToItem(root, 0, 0).y + settingsSearchInput.height + 4
        width: Math.min(360, root.width - 16)
        height: Math.min(7 * 46 + 8, Math.max(42, root.settingsSearchResults.length * 46 + 8))
        color: Config.settingsBackground
        border.color: Config.accent
        border.width: 1
        radius: Config.frameRadius
        clip: true

        ListView {
            id: settingsSearchList
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            spacing: 2
            model: root.settingsSearchResults
            visible: root.settingsSearchResults.length > 0
            currentIndex: root.settingsSearchSelectedIndex

            delegate: Item {
                id: searchResultDelegate
                required property var modelData
                required property int index
                width: settingsSearchList.width
                height: 44

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: index === root.settingsSearchSelectedIndex ? Config.accent : "transparent"
                    border.width: index === root.settingsSearchSelectedIndex ? 1 : 0
                    border.color: Config.accent
                }

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 1

                    Text {
                        width: parent.width
                        height: 17
                        text: modelData.label
                        color: index === root.settingsSearchSelectedIndex ? Config.black : Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        font.bold: index === root.settingsSearchSelectedIndex
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        height: 15
                        text: modelData.pageLabel + (modelData.group ? " · " + modelData.group : "")
                        color: index === root.settingsSearchSelectedIndex ? Config.black : Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(9)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.settingsSearchSelectedIndex = index
                    onClicked: root.openSettingsSearchResult(modelData)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.settingsSearchResults.length === 0
            text: "Ничего не найдено"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
    }

    Rectangle {
        id: settingsSearchHighlight
        z: 1100
        visible: false
        color: "transparent"
        border.color: Config.accent
        border.width: 2
        radius: 4
        antialiasing: true
    }

    Timer {
        id: settingsSearchHighlightTimer
        interval: 1600
        repeat: false
        onTriggered: settingsSearchHighlight.visible = false
    }

}
