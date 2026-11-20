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

    signal searchQueryEdited(string query)

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
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
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
            width: mainSettingsTabs.width - 10
            spacing: 8

            Repeater {
                model: root.navigationGroups

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
                        color: root.host.settingsNavigationGroupCollapsed(modelData.id)
                            ? Config.settingsBackground
                            : Qt.darker(Config.settingsBackground, 1.04)
                        border.width: root.host.settingsSearchNavigationGroupHasMatches(modelData.id)
                            ? Config.settingsSearchHighlightBorderWidth : 1
                        border.color: root.host.settingsSearchNavigationGroupHasMatches(modelData.id)
                            ? Config.settingsSearchHighlightColor
                            : (root.host.settingsNavigationGroupHasCurrentPage(modelData.id)
                                ? Config.accent : Config.baseColor)

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
                                width: parent.width - 15
                                    - (root.host.settingsSearchNavigationGroupMatchCount(modelData.id) > 0 ? 28 : 0)
                                    - (modelData.items.length > 1 ? 18 : 0)
                                    - 7 * (1
                                        + (root.host.settingsSearchNavigationGroupMatchCount(modelData.id) > 0 ? 1 : 0)
                                        + (modelData.items.length > 1 ? 1 : 0))
                                height: parent.height
                                text: modelData.items.length === 1
                                    ? modelData.items[0].label : modelData.label
                                color: root.host.settingsNavigationGroupCollapsed(modelData.id)
                                    ? Config.textMuted : Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: root.host.settingsSearchNavigationGroupMatchCount(modelData.id) > 0
                                width: visible ? 28 : 0
                                height: parent.height
                                text: {
                                    var count = root.host.settingsSearchNavigationGroupMatchCount(modelData.id)
                                    return count > 99 ? "99+" : String(count)
                                }
                                color: Config.settingsSearchHighlightColor
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(Config.settingsSearchMatchCountFontSize)
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                visible: modelData.items.length > 1
                                width: visible ? 18 : 0
                                height: parent.height
                                text: root.host.settingsNavigationGroupCollapsed(modelData.id) ? "⌄" : "⌃"
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(12)
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        HoverHandler {
                            id: navigationGroupSearchHover
                            enabled: root.host.settingsSearchNavigationGroupHasMatches(modelData.id)
                        }

                        ToolTip.visible: navigationGroupSearchHover.hovered
                            && root.host.settingsSearchNavigationGroupMatchHint(modelData.id).length > 0
                        ToolTip.text: root.host.settingsSearchNavigationGroupMatchHint(modelData.id)
                        ToolTip.delay: 450

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.items.length === 1)
                                    root.host.selectSettingsTab(modelData.items[0].id)
                                else
                                    root.host.toggleSettingsNavigationGroup(modelData.id)
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
                                height: 34

                                SettingsSubTab {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    width: parent.width - 8
                                    height: 34
                                    selected: root.host.isSettingsTabSelected(parent.modelData.id)
                                    modified: root.host.settingsTabHasChanges(parent.modelData.id)
                                    settingsSearchMatched: root.host.settingsSearchPageHasMatches(parent.modelData.id)
                                    settingsSearchMatchHint: root.host.settingsSearchPageMatchHint(parent.modelData.id)
                                    settingsSearchMatchCount: root.host.settingsSearchPageMatchCount(parent.modelData.id)
                                    text: parent.modelData.label
                                    leftAligned: true
                                    horizontalPadding: 8
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
