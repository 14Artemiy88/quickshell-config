import QtQuick
import QtQuick.Controls
import "../../.."

// Reusable sidebar folder primitive. It owns the folder header, its
// collapsed/expanded state presentation, search/accessibility feedback and
// the content slot for the page tabs inside the folder.
Item {
    id: root

    property string groupId: ""
    property string groupLabel: ""
    property string groupSymbol: ""
    property bool collapsed: true
    property bool compactNavigation: false
    property bool emptyFolder: false
    property bool collapsedWithCurrentPage: false
    property string currentPageLabel: ""
    property int searchMatchCount: 0
    property string searchMatchHint: ""
    property var navigationHost: null
    property int expandedCardInset: 4
    property int childContentInset: 6

    readonly property real expandedContentWidth: Math.max(0, width - expandedCardInset * 2)

    default property alias contentData: navigationItems.data
    signal toggleRequested()

    implicitHeight: folderLayout.implicitHeight
    height: implicitHeight

    // Expanded groups keep a light outline, not a filled surface. The sidebar
    // remains visually open; only the selected page gets a filled tab.
    Rectangle {
        anchors.fill: parent
        visible: !root.collapsed || navigationItems.height > 0.5
        z: -1
        radius: Config.scaledCornerRadius(Config.frameRadius)
        color: Config.transparent
        border.width: Config.cardBordersEnabled ? 1 : 0
        border.color: Config.baseColor
        antialiasing: true
    }

    Column {
        id: folderLayout
        width: root.width
        height: implicitHeight
        // Keep layout spacing stable across the state change; changing it at the
        // same instant as the reveal made the nested rows appear to shift late.
        spacing: 2

    Item {
        id: headerHost
        x: root.collapsed ? 0 : root.expandedCardInset
        width: root.collapsed ? root.width : root.expandedContentWidth
        height: root.collapsedWithCurrentPage ? 42 : 30
        Behavior on height {
            NumberAnimation {
                duration: root.collapsed ? 150 : 190
                easing.type: root.collapsed ? Easing.InCubic : Easing.OutCubic
            }
        }

        Rectangle {
            id: folderHeader
            anchors.fill: parent
            anchors.topMargin: root.collapsed ? 0 : 4
            radius: Config.scaledCornerRadius(Config.radius)
            color: Config.transparent
            border.width: root.searchMatchCount > 0
                ? Config.settingsSearchHighlightBorderWidth
                : (folderHeader.activeFocus || (Config.cardBordersEnabled && folderHover.hovered) ? 1 : 0)
            border.color: root.searchMatchCount > 0
                ? Config.settingsSearchHighlightColor
                : (folderHeader.activeFocus ? Config.textMuted : Config.baseColor)

            property bool settingsNavigationFocusTarget: true
            property string settingsNavigationPageId: ""
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: root.groupLabel
            Accessible.description: {
                var state = root.collapsed ? "свёрнут" : "развёрнут"
                var active = root.currentPageLabel.length > 0
                    ? " Страница: " + root.currentPageLabel + "." : ""
                return "Раздел " + state + ". Enter — переключить. Стрелки влево и вправо — свернуть или раскрыть." + active
            }
            Accessible.onPressAction: root.toggleRequested()

            Row {
                anchors.fill: parent
                anchors.leftMargin: root.compactNavigation ? 5 : 8
                anchors.rightMargin: root.compactNavigation ? 5 : 8
                anchors.bottomMargin: root.collapsedWithCurrentPage ? 14 : 0
                spacing: root.compactNavigation ? 4 : 7

                Text {
                    width: root.compactNavigation ? 12 : 15
                    height: parent.height
                    text: root.groupSymbol
                    color: Config.accent
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 10 : 12)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: groupLabelText
                    width: Math.max(18, parent.width
                        - (root.compactNavigation ? 12 : 15)
                        - (root.searchMatchCount > 0 ? (root.compactNavigation ? 22 : 28) : 0)
                        - (root.compactNavigation ? 14 : 18)
                        - (root.compactNavigation ? 4 : 7) * (2
                            + (root.searchMatchCount > 0 ? 1 : 0)))
                    height: parent.height
                    text: root.groupLabel
                    color: root.collapsed ? Config.textMuted : Config.accent
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 9 : 10)
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.searchMatchCount > 0
                    width: visible ? (root.compactNavigation ? 22 : 28) : 0
                    height: parent.height
                    text: root.searchMatchCount > 99 ? "99+" : String(root.searchMatchCount)
                    color: Config.settingsSearchHighlightColor
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(root.compactNavigation
                        ? Math.max(7, Config.settingsSearchMatchCountFontSize - 1)
                        : Config.settingsSearchMatchCountFontSize)
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: root.compactNavigation ? 14 : 18
                    height: parent.height
                    text: root.collapsed ? "⌄" : "⌃"
                    color: Config.textMuted
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(root.compactNavigation ? 10 : 12)
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                id: currentPageHint
                visible: root.collapsedWithCurrentPage
                anchors.left: parent.left
                anchors.leftMargin: 30
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                height: 12
                text: "Страница: " + root.currentPageLabel
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(8)
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            HoverHandler {
                id: folderHover
                enabled: true
            }

            ToolTip.visible: folderHover.hovered
                && (root.searchMatchHint.length > 0
                    || groupLabelText.implicitWidth > groupLabelText.width + 1
                    || (currentPageHint.visible && currentPageHint.implicitWidth > currentPageHint.width + 1))
            ToolTip.text: {
                if (root.searchMatchHint.length > 0) return root.searchMatchHint
                if (currentPageHint.visible)
                    return root.groupLabel + "\nАктивная страница: " + root.currentPageLabel
                return root.groupLabel
            }
            ToolTip.delay: 450

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.toggleRequested()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                    if ((event.key === Qt.Key_Left && !root.collapsed)
                            || (event.key === Qt.Key_Right && root.collapsed))
                        root.toggleRequested()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    if (root.navigationHost && root.navigationHost.focusAdjacentSettingsNavigationItem)
                        root.navigationHost.focusAdjacentSettingsNavigationItem(folderHeader, event.key === Qt.Key_Down)
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Folder expansion is not navigation: do not take or retain focus.
                    folderHeader.focus = false
                    root.toggleRequested()
                }
            }
        }
    }

    Column {
        id: navigationItems
        // The row list is already inset while collapsed (but has zero height),
        // so opening animates only visibility/height and never applies a late x/width jump.
        x: root.expandedCardInset
        width: root.expandedContentWidth
        spacing: 2
        visible: !root.collapsed || height > 0.5
        clip: true
        height: root.collapsed ? 0 : implicitHeight + 4
        opacity: root.collapsed ? 0 : 1

        Behavior on height {
            NumberAnimation {
                duration: root.collapsed ? 150 : 190
                easing.type: root.collapsed ? Easing.InCubic : Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 130
                easing.type: Easing.InOutCubic
            }
        }

        Text {
            visible: root.emptyFolder && !root.collapsed
            width: parent.width - 16
            height: visible ? 24 : 0
            x: 8
            text: "Папка пуста · добавьте вкладку в настройках порядка"
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(8)
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }
    }
    }
}
