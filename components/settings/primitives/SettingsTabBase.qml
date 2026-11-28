import QtQuick
import QtQuick.Controls
import "../../.."

Item {
    id: root

    property string text: ""
    property bool selected: false
    property real cornerRadius: 4
    property int fontPixelSize: 10
    property bool leftAligned: false
    property int horizontalPadding: 6
    // Selection should read as a subtle state change, not a filled button.
    property bool boldWhenSelected: false
    // Horizontal page subtabs retain a distinct selected treatment even after
    // focus moves to the sidebar. Focus remains a separate keyboard indicator.
    property bool persistentSelectionHighlight: false
    property color persistentSelectedBackground: "transparent"
    property color persistentSelectedTextColor: Config.accent
    property color persistentSelectedBorderColor: Config.accent
    readonly property bool persistentSelectionActive: root.persistentSelectionHighlight && root.selected
    readonly property color effectiveSelectedTextColor: root.persistentSelectionActive
        ? root.persistentSelectedTextColor : root.selectedTextColor
    property color selectedBackground: "transparent"
    property color normalBackground: "transparent"
    property color selectedTextColor: Config.text
    property color normalTextColor: Config.text
    property color normalBorderColor: Config.baseColor
    property color hoverBorderColor: Config.accent
    property bool hovered: false
    property bool modified: false
    property bool settingsSearchMatched: false
    property string settingsSearchMatchHint: ""
    property int settingsSearchMatchCount: 0
    property color modifiedColor: Config.accent
    property bool settingsNavigationFocusTarget: false
    property string settingsNavigationPageId: ""
    property var settingsNavigationHost: null

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.description: {
        var details = root.selected ? "Текущая выбранная страница. " : "Открыть страницу настроек. "
        if (root.modified) details += "Есть несохранённые изменения. "
        if (root.settingsSearchMatchCount > 0)
            details += "Совпадений поиска: " + String(root.settingsSearchMatchCount) + ". "
        return details
    }
    Accessible.onPressAction: root.clicked()

    signal clicked()

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked()
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            if (root.settingsNavigationFocusTarget && root.settingsNavigationHost
                    && root.settingsNavigationHost.focusAdjacentSettingsNavigationItem) {
                root.settingsNavigationHost.focusAdjacentSettingsNavigationItem(root, event.key === Qt.Key_Down)
                event.accepted = true
            }
        }
    }

    ToolTip.visible: root.hovered && (
        (root.settingsSearchMatched && root.settingsSearchMatchHint.length > 0)
        || tabLabel.implicitWidth > tabLabel.width + 1)
    ToolTip.text: root.settingsSearchMatched && root.settingsSearchMatchHint.length > 0
        ? root.settingsSearchMatchHint : root.text
    ToolTip.delay: 450


    readonly property real visualBorderWidth: root.activeFocus ? 1
        : (root.settingsSearchMatched ? Config.settingsSearchHighlightBorderWidth
            : (Config.buttonBordersEnabled ? 1 : 0))

    // The selected fill sits inside the frame, but stays translucent so the
    // active tab has roughly the same visual weight as a simple outlined tab.
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.selected ? root.visualBorderWidth : 0
        radius: Math.max(0, Config.scaledCornerRadius(root.cornerRadius) - (root.selected ? root.visualBorderWidth : 0))
        color: root.persistentSelectionActive ? root.persistentSelectedBackground
            : (root.selected ? root.selectedBackground : root.normalBackground)
        border.width: 0
        antialiasing: true
    }

    Rectangle {
        anchors.fill: parent
        radius: Config.scaledCornerRadius(root.cornerRadius)
        color: "transparent"
        border.color: root.activeFocus ? Config.accent
            : (root.hovered ? root.hoverBorderColor
                : (root.settingsSearchMatched ? Config.settingsSearchHighlightColor
                    : (root.persistentSelectionActive
                        ? root.persistentSelectedBorderColor : root.normalBorderColor)))
        border.width: root.visualBorderWidth
        antialiasing: true

        Text {
            id: tabLabel
            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
                + (root.modified ? 10 : 0)
                + (root.settingsSearchMatchCount > 0 ? 30 : 0)
            text: root.text
            color: root.selected ? root.effectiveSelectedTextColor : root.normalTextColor
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(root.fontPixelSize)
            font.bold: root.selected && root.boldWhenSelected
            horizontalAlignment: root.leftAligned ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Text {
            visible: root.settingsSearchMatchCount > 0
            anchors.right: parent.right
            anchors.rightMargin: root.horizontalPadding + (root.modified ? 10 : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 14
            text: root.settingsSearchMatchCount > 99 ? "99+" : String(root.settingsSearchMatchCount)
            color: root.selected ? root.effectiveSelectedTextColor : Config.settingsSearchHighlightColor
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(Config.settingsSearchMatchCountFontSize)
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            visible: root.modified
            width: 5
            height: 5
            radius: width / 2
            x: parent.width - width - 5
            y: 5
            color: root.selected ? root.effectiveSelectedTextColor : root.modifiedColor
            border.width: 0
            antialiasing: true
        }

        HoverHandler {
            onHoveredChanged: root.hovered = hovered
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.forceActiveFocus(Qt.MouseFocusReason)
                root.clicked()
            }
        }
    }
}
