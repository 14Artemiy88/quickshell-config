import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"

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
            font.family: Config.settingsFont
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
            font.family: Config.settingsFont
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
                    readonly property bool collapsedWithCurrentPage:
                        root.host.settingsNavigationGroupCollapsed(modelData.id)
                        && root.host.settingsNavigationGroupHasCurrentPage(modelData.id)
                    width: mainSettingsGroupsColumn.width
                    spacing: 3

                    Rectangle {
                        id: navigationGroupHeader
                        property bool settingsNavigationFocusTarget: true
                        property string settingsNavigationPageId: modelData.items.length === 1 ? String(modelData.items[0].id) : ""
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.items.length === 1
                            ? modelData.items[0].label : modelData.label
                        Accessible.description: {
                            if (modelData.items.length === 1)
                                return "Открыть страницу «" + modelData.items[0].label + "»."
                            var state = root.host.settingsNavigationGroupCollapsed(modelData.id) ? "свёрнут" : "развёрнут"
                            var active = root.host.settingsNavigationGroupHasCurrentPage(modelData.id)
                                ? " Активная страница: " + root.host.settingsNavigationGroupCurrentPageLabel(modelData.id) + "."
                                : ""
                            return "Раздел " + state + ". Enter — переключить. Стрелки влево и вправо — свернуть или раскрыть." + active
                        }
                        Accessible.onPressAction: navigationGroupHeader.activateGroupHeader()
                        function activateGroupHeader() {
                            if (modelData.items.length === 1)
                                root.host.selectSettingsTab(modelData.items[0].id)
                            else
                                root.host.toggleSettingsNavigationGroup(modelData.id)
                        }
                        width: parent.width
                        height: navigationGroupDelegate.collapsedWithCurrentPage ? 42 : 30
                        radius: 4
                        color: root.host.settingsNavigationGroupCollapsed(modelData.id)
                            ? Config.settingsBackground
                            : Qt.darker(Config.settingsBackground, 1.04)
                        border.width: navigationGroupHeader.activeFocus ? 2
                            : (root.host.settingsSearchNavigationGroupHasMatches(modelData.id)
                                ? Config.settingsSearchHighlightBorderWidth : 1)
                        border.color: navigationGroupHeader.activeFocus ? Config.accent
                            : (root.host.settingsSearchNavigationGroupHasMatches(modelData.id)
                                ? Config.settingsSearchHighlightColor
                                : (root.host.settingsNavigationGroupHasCurrentPage(modelData.id)
                                    ? Config.accent : Config.baseColor))

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: root.compactNavigation ? 5 : 8
                            anchors.rightMargin: root.compactNavigation ? 5 : 8
                            anchors.bottomMargin: navigationGroupDelegate.collapsedWithCurrentPage ? 14 : 0
                            spacing: root.compactNavigation ? 4 : 7

                            Text {
                                width: root.compactNavigation ? 12 : 15
                                height: parent.height
                                text: modelData.symbol
                                color: Config.accent
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 10 : 12)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                id: navigationGroupLabelText
                                width: Math.max(18, parent.width
                                    - (root.compactNavigation ? 12 : 15)
                                    - (root.host.settingsSearchNavigationGroupMatchCount(modelData.id) > 0 ? (root.compactNavigation ? 22 : 28) : 0)
                                    - (modelData.items.length > 1 ? (root.compactNavigation ? 14 : 18) : 0)
                                    - (root.compactNavigation ? 4 : 7) * (1
                                        + (root.host.settingsSearchNavigationGroupMatchCount(modelData.id) > 0 ? 1 : 0)
                                        + (modelData.items.length > 1 ? 1 : 0)))
                                height: parent.height
                                text: modelData.items.length === 1
                                    ? modelData.items[0].label : modelData.label
                                color: root.host.settingsNavigationGroupCollapsed(modelData.id)
                                    ? Config.textMuted : Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 9 : 10)
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: root.host.settingsSearchNavigationGroupMatchCount(modelData.id) > 0
                                width: visible ? (root.compactNavigation ? 22 : 28) : 0
                                height: parent.height
                                text: {
                                    var count = root.host.settingsSearchNavigationGroupMatchCount(modelData.id)
                                    return count > 99 ? "99+" : String(count)
                                }
                                color: Config.settingsSearchHighlightColor
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(root.compactNavigation
                                    ? Math.max(7, Config.settingsSearchMatchCountFontSize - 1)
                                    : Config.settingsSearchMatchCountFontSize)
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                visible: modelData.items.length > 1
                                width: visible ? (root.compactNavigation ? 14 : 18) : 0
                                height: parent.height
                                text: root.host.settingsNavigationGroupCollapsed(modelData.id) ? "⌄" : "⌃"
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 10 : 12)
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            id: navigationGroupActivePageText
                            visible: navigationGroupDelegate.collapsedWithCurrentPage
                            anchors.left: parent.left
                            anchors.leftMargin: 30
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            height: 12
                            text: "Активно: " + root.host.settingsNavigationGroupCurrentPageLabel(modelData.id)
                            color: Config.accent
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(8)
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        HoverHandler {
                            id: navigationGroupSearchHover
                            enabled: true
                        }

                        ToolTip.visible: navigationGroupSearchHover.hovered
                            && (root.host.settingsSearchNavigationGroupMatchHint(modelData.id).length > 0
                                || navigationGroupLabelText.implicitWidth > navigationGroupLabelText.width + 1
                                || (navigationGroupActivePageText.visible
                                    && navigationGroupActivePageText.implicitWidth > navigationGroupActivePageText.width + 1))
                        ToolTip.text: {
                            var matchHint = root.host.settingsSearchNavigationGroupMatchHint(modelData.id)
                            if (matchHint.length > 0) return matchHint
                            var groupLabel = modelData.items.length === 1 ? modelData.items[0].label : modelData.label
                            if (navigationGroupActivePageText.visible)
                                return groupLabel + "\nАктивная страница: " + root.host.settingsNavigationGroupCurrentPageLabel(modelData.id)
                            return groupLabel
                        }
                        ToolTip.delay: 450

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                navigationGroupHeader.activateGroupHeader()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                                if (modelData.items.length > 1) {
                                    var collapsed = root.host.settingsNavigationGroupCollapsed(modelData.id)
                                    if ((event.key === Qt.Key_Left && !collapsed)
                                            || (event.key === Qt.Key_Right && collapsed))
                                        root.host.toggleSettingsNavigationGroup(modelData.id)
                                    event.accepted = true
                                }
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                                root.host.focusAdjacentSettingsNavigationItem(navigationGroupHeader, event.key === Qt.Key_Down)
                                event.accepted = true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                navigationGroupHeader.forceActiveFocus(Qt.MouseFocusReason)
                                navigationGroupHeader.activateGroupHeader()
                            }
                        }
                    }

                    Column {
                        id: navigationGroupItems
                        width: parent.width
                        spacing: 3
                        visible: navigationGroupDelegate.modelData.items.length > 1
                            && !root.host.settingsNavigationGroupCollapsed(navigationGroupDelegate.modelData.id)
                        height: visible ? implicitHeight : 0

                        Repeater {
                            model: navigationGroupDelegate.modelData.items

                            delegate: Item {
                                required property var modelData
                                width: navigationGroupItems.width
                                height: root.compactNavigation ? 36 : 34

                                SettingsSubTab {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    width: parent.width - 8
                                    height: root.compactNavigation ? 36 : 34
                                    settingsNavigationFocusTarget: true
                                    settingsNavigationPageId: String(parent.modelData.id)
                                    settingsNavigationHost: root.host
                                    selected: root.host.isSettingsTabSelected(parent.modelData.id)
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
