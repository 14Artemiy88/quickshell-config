import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"
import "../../js/settings/SettingsPageRegistry.js" as SettingsPageRegistry
import "../../js/settings/SettingsSchema.js" as SettingsSchema

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
    property bool settingsNavigationReady: false
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
    signal layoutEditRequested()
    signal settingsMoveRequested()
    signal closeRequested()
    clip: true

    Shortcut {
        sequence: "Esc"
        enabled: !root.settingsMoveMode
        onActivated: root.closeRequested()
    }

    Shortcut {
        sequence: "F3"
        enabled: !root.settingsMoveMode && root.settingsSearchQuery.trim().length > 0
        onActivated: settingsSearchController.cycleSettingsSearchMatch(1)
    }

    Shortcut {
        sequence: "Shift+F3"
        enabled: !root.settingsMoveMode && root.settingsSearchQuery.trim().length > 0
        onActivated: settingsSearchController.cycleSettingsSearchMatch(-1)
    }

    SettingsProfileController {
        id: settingsProfileController
        settings: root.settings
    }

    SettingsSearchController {
        id: settingsSearchController
        host: root
        searchRoot: root
    }

    function clearSettingsFocus() {
        root.forceActiveFocus()
    }

    function resetSettingsPageScroll() {
        if (settingsPageContent) settingsPageContent.resetScroll()
    }

    function openWeatherSettings() {
        root.expandSettingsNavigationGroupForPage("weather")
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
    readonly property var settingsNavigationGroups: {
        var definitions = settingsNavigationController.settingsNavigationGroupDefinitions
        var items = root.settingsNavigationItems
        var groups = []
        for (var i = 0; i < definitions.length; ++i) {
            var definition = definitions[i]
            var groupItems = []
            for (var j = 0; j < items.length; ++j) {
                if (items[j].groupId === definition.id)
                    groupItems.push(items[j])
            }
            groups.push({
                id: definition.id,
                label: definition.label,
                symbol: definition.symbol,
                items: groupItems
            })
        }
        return groups
    }
    readonly property var collapsedSettingsNavigationGroups: Config.settingsNavigationCollapsedGroups || ({ appearance: false, modules: false, launcher: false })
    readonly property var currentPageSubTabs: settingsNavigationController.currentPageSubTabs
    readonly property string currentPageTitle: settingsNavigationController.currentPageTitle

    function defaultSettingsTabLabel(id) { return settingsNavigationController.defaultSettingsTabLabel(id) }
    function settingsTabLabelForId(id) { return settingsNavigationController.settingsTabLabelForId(id) }
    function settingsTabOrderNormalized() { return settingsNavigationController.settingsTabOrderNormalized() }
    function isSettingsTabSelected(id) { return settingsNavigationController.isSettingsTabSelected(id) }
    function settingsSubTabChangeSpec(pageId, sub) { return settingsNavigationController.settingsSubTabChangeSpec(pageId, sub) }
    function settingsSubTabHasChanges(pageId, sub) { return settingsNavigationController.settingsSubTabHasChanges(pageId, sub) }
    function settingsTabHasChanges(id) { return settingsNavigationController.settingsTabHasChanges(id) }
    function selectSettingsTab(id) {
        root.expandSettingsNavigationGroupForPage(id)
        return settingsNavigationController.selectSettingsTab(id)
    }
    function resetCurrentSettingsPage() { return settingsNavigationController.resetCurrentSettingsPage() }
    function setSettingsTabLabel(id, value) { return settingsNavigationController.setSettingsTabLabel(id, value) }
    function moveSettingsTab(id, delta) { return settingsNavigationController.moveSettingsTab(id, delta) }
    function settingsTabCanMove(id, delta) { return settingsNavigationController.settingsTabCanMove(id, delta) }

    function settingsNavigationGroupCollapsed(id) {
        return collapsedSettingsNavigationGroups[String(id)] === true
    }

    function settingsNavigationGroupHasCurrentPage(id) {
        var groups = root.settingsNavigationGroups
        for (var i = 0; i < groups.length; ++i) {
            if (groups[i].id !== String(id)) continue
            for (var j = 0; j < groups[i].items.length; ++j) {
                if (groups[i].items[j].id === root.currentPageId)
                    return true
            }
        }
        return false
    }

    function setSettingsNavigationCollapsedGroups(value) {
        Config.settingsNavigationCollapsedGroups = SettingsSchema.normalizeSettingsNavigationCollapsedGroups(
            value, Config.settingsNavigationCollapsedGroups)
        root.settings.save()
    }

    function toggleSettingsNavigationGroup(id) {
        var key = String(id)
        if (key !== "appearance" && key !== "modules" && key !== "launcher") return
        var next = Object.assign({}, root.collapsedSettingsNavigationGroups || ({}))
        next[key] = next[key] !== true
        root.setSettingsNavigationCollapsedGroups(next)
    }

    function expandSettingsNavigationGroupForPage(pageId) {
        var groupId = SettingsPageRegistry.navigationGroupIdForTabId(pageId)
        if (root.settingsNavigationGroupCollapsed(groupId)) {
            var next = Object.assign({}, root.collapsedSettingsNavigationGroups || ({}))
            next[groupId] = false
            root.setSettingsNavigationCollapsedGroups(next)
        }
    }

    function rebuildSettingsSearchIndex() {
        settingsSearchController.rebuildSettingsSearchIndex()
    }

    function clearSettingsSearchQuery() {
        settingsNavigation.searchInput.text = ""
        root.updateSettingsSearchResults("")
    }

    function updateSettingsSearchResults(query) {
        settingsSearchController.updateSettingsSearchResults(query)
    }

    function openSettingsSearchResult(entry) {
        settingsSearchController.openSettingsSearchResult(entry)
    }

    function settingsSearchPageHasMatches(pageId) {
        return settingsSearchController.settingsSearchPageHasMatches(pageId)
    }

    function settingsSearchPageMatchCount(pageId) {
        return settingsSearchController.settingsSearchPageMatchCount(pageId)
    }

    function settingsSearchNavigationGroupHasMatches(groupId) {
        return settingsSearchController.settingsSearchNavigationGroupHasMatches(groupId)
    }

    function settingsSearchNavigationGroupMatchCount(groupId) {
        return settingsSearchController.settingsSearchNavigationGroupMatchCount(groupId)
    }

    function settingsSearchSubTabHasMatches(pageId, subTabIndex) {
        return settingsSearchController.settingsSearchSubTabHasMatches(pageId, subTabIndex)
    }

    function settingsSearchSubTabMatchCount(pageId, subTabIndex) {
        return settingsSearchController.settingsSearchSubTabMatchCount(pageId, subTabIndex)
    }

    function settingsSearchPageMatchHint(pageId) {
        return settingsSearchController.settingsSearchPageMatchHint(pageId)
    }

    function settingsSearchNavigationGroupMatchHint(groupId) {
        return settingsSearchController.settingsSearchNavigationGroupMatchHint(groupId)
    }

    function settingsSearchSubTabMatchHint(pageId, subTabIndex) {
        return settingsSearchController.settingsSearchSubTabMatchHint(pageId, subTabIndex)
    }

    function handleSettingsSearchKey(event) {
        settingsSearchController.handleSettingsSearchKey(event)
    }

    function cycleSettingsSearchMatch(direction) {
        return settingsSearchController.cycleSettingsSearchMatch(direction)
    }

    Component.onCompleted: {
        settingsSearchController.searchInput = settingsNavigation.searchInput
        root.settingsNavigationReady = true
        Qt.callLater(root.rebuildSettingsSearchIndex)
    }

    onCurrentPageIdChanged: {
        if (root.settingsNavigationReady)
            root.expandSettingsNavigationGroupForPage(root.currentPageId)
    }

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
                width: Math.max(70, parent.width - 260)
                text: "НАСТРОЙКИ"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(20)
                verticalAlignment: Text.AlignVCenter
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

            SettingsNavigation {
                id: settingsNavigation
                width: 176
                height: parent.height
                host: root
                navigationGroups: root.settingsNavigationGroups
                searchQuery: root.settingsSearchQuery
                searchResults: root.settingsSearchResults
                onSearchQueryEdited: query => root.updateSettingsSearchResults(query)
            }

            SettingsPageContent {
                id: settingsPageContent
                width: parent.width - settingsNavigation.width - 16
                height: parent.height
                host: root
                settings: root.settings
            }
        }
    }

    // Search results stay in-place: matching navigation groups, pages,
    // sub-tabs, section frames and setting controls receive the configured outline.

}
