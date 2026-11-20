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
    readonly property var collapsedSettingsNavigationGroups: Config.settingsNavigationCollapsedGroups || ({ appearance: false, modules: false })
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
        if (key !== "appearance" && key !== "modules") return
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

    function updateSettingsSearchResults(query) {
        settingsSearchController.updateSettingsSearchResults(query)
    }

    function openSettingsSearchResult(entry) {
        settingsSearchController.openSettingsSearchResult(entry)
    }

    function handleSettingsSearchKey(event) {
        settingsSearchController.handleSettingsSearchKey(event)
    }

    Component.onCompleted: {
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

            Flickable {
                id: mainSettingsTabs
                width: 176
                height: parent.height
                contentWidth: width
                contentHeight: mainSettingsGroupsColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height

                Column {
                    id: mainSettingsGroupsColumn
                    width: mainSettingsTabs.width - 10
                    spacing: 8

                    Repeater {
                        model: root.settingsNavigationGroups

                        delegate: Column {
                            id: navigationGroupDelegate
                            required property var modelData
                            width: mainSettingsGroupsColumn.width
                            spacing: 3

                            Rectangle {
                                id: navigationGroupHeader
                                width: parent.width
                                height: 30
                                radius: 4
                                color: root.settingsNavigationGroupCollapsed(modelData.id)
                                    ? Config.settingsBackground
                                    : Qt.darker(Config.settingsBackground, 1.04)
                                border.width: 1
                                border.color: root.settingsNavigationGroupHasCurrentPage(modelData.id)
                                    ? Config.accent
                                    : Config.baseColor

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Text {
                                        width: 15
                                        height: parent.height
                                        text: modelData.symbol
                                        color: Config.accent
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(12)
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        width: parent.width - 15 - (modelData.items.length > 1 ? 18 : 0) - 14
                                        height: parent.height
                                        text: modelData.items.length === 1
                                            ? modelData.items[0].label : modelData.label
                                        color: root.settingsNavigationGroupCollapsed(modelData.id)
                                            ? Config.textMuted : Config.text
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(10)
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: modelData.items.length > 1
                                        width: visible ? 18 : 0
                                        height: parent.height
                                        text: root.settingsNavigationGroupCollapsed(modelData.id) ? "⌄" : "⌃"
                                        color: Config.textMuted
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(12)
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (modelData.items.length === 1)
                                            root.selectSettingsTab(modelData.items[0].id)
                                        else
                                            root.toggleSettingsNavigationGroup(modelData.id)
                                    }
                                }
                            }

                            Column {
                                id: navigationGroupItems
                                width: parent.width
                                spacing: 3
                                visible: navigationGroupDelegate.modelData.items.length > 1
                                    && !root.settingsNavigationGroupCollapsed(navigationGroupDelegate.modelData.id)
                                height: visible ? implicitHeight : 0

                                Repeater {
                                    model: navigationGroupDelegate.modelData.items

                                    delegate: Item {
                                        required property var modelData
                                        width: navigationGroupItems.width
                                        height: 34

                                        SettingsSubTab {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            width: parent.width - 8
                                            height: 34
                                            selected: root.isSettingsTabSelected(parent.modelData.id)
                                            modified: root.settingsTabHasChanges(parent.modelData.id)
                                            text: parent.modelData.label
                                            leftAligned: true
                                            horizontalPadding: 8
                                            onClicked: root.selectSettingsTab(parent.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: SettingsScrollBar {
                    visible: mainSettingsTabs.contentHeight > mainSettingsTabs.height + 1
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
            ScrollBar.vertical: SettingsScrollBar {
                visible: root.settingsSearchResults.length > 7
            }
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
                        text: modelData.navigationGroupLabel + " › " + modelData.pageLabel
                            + (modelData.group ? " · " + modelData.group : "")
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
