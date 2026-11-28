import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"
import "../../js/settings/SettingsNavigationVisualState.js" as SettingsNavigationVisualState

// Owns the complete left navigation surface: search, match status, grouped
// pages, counters, collapse state and the in-place navigation affordances.
// SettingsWidget supplies state and receives query edits through this API.
Column {
    id: root

    property var host: null
    property var navigationGroups: []
    property string searchQuery: ""
    property var searchResults: []
    property alias searchInput: settingsSearchInput
    readonly property bool compactNavigation: width < 148

    signal searchQueryEdited(string query)

    function ensureNavigationItemVisible(item) {
        if (!item || item.visible === false || typeof item.mapToItem !== "function")
            return false
        var position = item.mapToItem(mainSettingsGroupsColumn, 0, 0)
        var top = Number(position.y)
        var bottom = top + Number(item.height || 0)
        var viewTop = mainSettingsTabs.contentY
        var viewBottom = viewTop + mainSettingsTabs.height
        if (top < viewTop) {
            mainSettingsTabs.contentY = Math.max(0, top)
        } else if (bottom > viewBottom) {
            mainSettingsTabs.contentY = Math.min(
                Math.max(0, mainSettingsTabs.contentHeight - mainSettingsTabs.height),
                bottom - mainSettingsTabs.height)
        }
        return true
    }

    width: 176
    height: parent.height
    spacing: Config.settingsSearchVisible ? 8 : 0
    Behavior on spacing {
        NumberAnimation {
            duration: Config.animationDuration(180, "size")
            easing.type: Config.easingType()
        }
    }

    Item {
        id: settingsSearchContainer
        width: parent.width
        height: Config.settingsSearchVisible ? 30 : 0
        opacity: Config.settingsSearchVisible ? 1 : 0
        clip: true
        enabled: Config.settingsSearchVisible

        Behavior on height {
            NumberAnimation {
                duration: Config.animationDuration(180, "size")
                easing.type: Config.easingType()
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Config.animationDuration(140, "appearance")
                easing.type: Config.easingType()
            }
        }

        SettingsInputField {
            id: settingsSearchInput
            anchors.fill: parent
            placeholderText: "Поиск настроек…"
            clearButtonEnabled: text.length > 0
            selectByMouse: true
            activeFocusOnTab: true
            Accessible.name: "Поиск настроек"
            Accessible.description: "Поиск по страницам, подразделам и параметрам. Enter открывает первый результат, Escape очищает поиск."
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 9 : 10)
            onTextChanged: root.searchQueryEdited(text)
            onActiveFocusChanged: if (activeFocus) Qt.callLater(root.host.rebuildSettingsSearchIndex)
            Keys.onPressed: event => root.host.handleSettingsSearchKey(event)
        }
    }

    Item {
        id: settingsSearchStatus
        width: parent.width
        height: Config.settingsSearchVisible && root.searchQuery.trim().length > 0 ? 17 : 0
        opacity: height > 0 ? 1 : 0
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: Config.animationDuration(150, "size")
                easing.type: Config.easingType()
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Config.animationDuration(120, "appearance")
                easing.type: Config.easingType()
            }
        }

        HoverHandler {
            id: settingsSearchStatusHover
            enabled: root.searchQuery.trim().length > 0
        }
        ToolTip.visible: settingsSearchStatusHover.hovered
            && root.searchQuery.trim().length > 0
        ToolTip.text: "F3 — следующее совпадение на открытой странице\nShift+F3 — предыдущее совпадение"
        ToolTip.delay: 350

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(8)
            color: root.searchResults.length > 0 ? Config.textMuted : Config.accent
            text: root.searchResults.length > 0
                ? "Найдено совпадений: " + String(root.searchResults.length)
                : "Совпадений не найдено"
        }
    }

    Flickable {
        id: mainSettingsTabs
        width: parent.width
        height: parent.height - settingsSearchContainer.height - settingsSearchStatus.height - root.spacing
        contentWidth: width
        contentHeight: mainSettingsGroupsColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
            id: mainSettingsGroupsColumn
            width: mainSettingsTabs.width - (root.compactNavigation ? 4 : 10)
            spacing: 8

            Repeater {
                model: root.navigationGroups

                delegate: Column {
                    id: navigationGroupDelegate
                    required property var modelData
                    // Only collapsed multi-page folders may show a current-page hint.
                    readonly property bool collapsedWithCurrentPage:
                        modelData.items.length > 1 && SettingsNavigationVisualState.shouldShowCollapsedPageHint(
                            modelData, root.host.settingsNavigationGroupCollapsed(modelData.id), root.host.currentPageId)
                    width: mainSettingsGroupsColumn.width
                    spacing: 3

                    SettingsSubTab {
                        id: navigationGroupStandaloneTab
                        visible: modelData.items.length === 1
                        width: parent.width
                        height: root.compactNavigation ? 32 : 30
                        settingsNavigationFocusTarget: true
                        settingsNavigationPageId: visible ? String(modelData.items[0].id) : ""
                        settingsNavigationHost: root.host
                        selected: visible && root.host.isSettingsTabSelected(modelData.items[0].id)
                        // Keep the active sidebar page highlighted even when a
                        // horizontal subtab owns keyboard focus.
                        persistentSelectionHighlight: true
                        normalBackground: Config.transparent
                        normalBorderColor: Config.transparent
                        modified: visible && root.host.settingsTabHasChanges(modelData.items[0].id)
                        settingsSearchMatched: visible && root.host.settingsSearchPageHasMatches(modelData.items[0].id)
                        settingsSearchMatchHint: visible
                            ? root.host.settingsSearchPageMatchHint(modelData.items[0].id) : ""
                        settingsSearchMatchCount: visible
                            ? root.host.settingsSearchPageMatchCount(modelData.items[0].id) : 0
                        text: visible ? (modelData.symbol + "  " + modelData.items[0].label) : ""
                        leftAligned: true
                        horizontalPadding: root.compactNavigation ? 5 : 8
                        fontPixelSize: root.compactNavigation ? 9 : 10
                        onClicked: {
                            if (visible)
                                root.host.selectSettingsTab(modelData.items[0].id)
                        }
                    }

                    SettingsNavigationFolder {
                        id: navigationGroupFolder
                        visible: navigationGroupDelegate.modelData.items.length !== 1
                        width: parent.width
                        groupId: navigationGroupDelegate.modelData.id
                        groupLabel: navigationGroupDelegate.modelData.label
                        groupSymbol: navigationGroupDelegate.modelData.symbol
                        collapsed: root.host.settingsNavigationGroupCollapsed(groupId)
                        compactNavigation: root.compactNavigation
                        emptyFolder: navigationGroupDelegate.modelData.items.length === 0
                        collapsedWithCurrentPage: navigationGroupDelegate.collapsedWithCurrentPage
                        currentPageLabel: collapsedWithCurrentPage
                            ? root.host.settingsNavigationGroupCurrentPageLabel(groupId) : ""
                        searchMatchCount: root.host.settingsSearchNavigationGroupMatchCount(groupId)
                        searchMatchHint: root.host.settingsSearchNavigationGroupMatchHint(groupId)
                        navigationHost: root.host
                        onToggleRequested: root.host.toggleSettingsNavigationGroup(groupId)

                        Repeater {
                            model: navigationGroupDelegate.modelData.items

                            delegate: Item {
                                required property var modelData
                                width: navigationGroupFolder.expandedContentWidth
                                height: root.compactNavigation ? 32 : 30

                                SettingsSubTab {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    width: parent.width - navigationGroupFolder.childContentInset
                                    height: root.compactNavigation ? 32 : 30
                                    settingsNavigationFocusTarget: true
                                    settingsNavigationPageId: String(parent.modelData.id)
                                    settingsNavigationHost: root.host
                                    normalBackground: Config.transparent
                                    normalBorderColor: Config.transparent
                                    selected: root.host.isSettingsTabSelected(parent.modelData.id)
                                    // Sidebar page selection and horizontal subtab
                                    // selection are independent visual states.
                                    persistentSelectionHighlight: true
                                    modified: root.host.settingsTabHasChanges(parent.modelData.id)
                                    settingsSearchMatched: root.host.settingsSearchPageHasMatches(parent.modelData.id)
                                    settingsSearchMatchHint: root.host.settingsSearchPageMatchHint(parent.modelData.id)
                                    settingsSearchMatchCount: root.host.settingsSearchPageMatchCount(parent.modelData.id)
                                    text: parent.modelData.label
                                    leftAligned: true
                                    horizontalPadding: root.compactNavigation ? 5 : 8
                                    fontPixelSize: root.compactNavigation ? 9 : 10
                                    onClicked: root.host.selectSettingsTab(parent.modelData.id)
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

}
