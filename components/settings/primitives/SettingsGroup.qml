import QtQuick
import QtQuick.Controls
import "../../.."

Item {
    id: root

    property bool showFrame: false
    property bool settingsSearchHighlighted: false
    property string settingsSearchMatchHint: ""
    property int settingsSearchSubTabIndex: -1
    property real padding: showFrame ? 10 : 0
    property real contentSpacing: 5
    // Additional content offset below a frame legend; can be tightened for compact groups.
    property real headingContentGap: 8
    // Explicit frame legend; avoids relying on child order or visibility.
    property string heading: ""
    // Optional compact actions aligned with the frame legend. They are
    // overlaid in the heading lane and do not reserve a full content row.
    property Component headingActions: null
    readonly property string renderedHeading: root.heading.trim().length > 0
        ? root.heading
        : (root.headingSource ? String(root.headingSource.text || "") : "")
    // Section frames are outlines only; avoid repeating a filled surface behind every group.
    property color backgroundColor: Config.transparent
    property color headingBackgroundColor: root.backgroundColor.a > 0
        ? root.backgroundColor : Config.settingsBackground
    property color borderColor: Config.baseColor
    property int borderWidth: 1
    property real radius: Config.frameRadius
    // The first direct Text child is promoted to a consistent fieldset legend.
    property var headingSource: null
    property bool adoptingHeading: false
    // Optional precise change selector. Frames without a selector remain unchanged.
    property var settings: Settings
    property var changeKeys: null
    readonly property bool modified: root.changeKeys !== null
        && root.settings !== null && root.settings !== undefined
        && root.settings.hasResetChanges("keys", root.changeKeys)
    property color modifiedColor: Config.accent

    default property alias contentData: contentColumn.data

    // Hidden or empty heading Text nodes must not create a notch or vertical gap.
    readonly property bool hasHeading: root.showFrame
        && root.renderedHeading.trim().length > 0
        && (root.heading.trim().length > 0
            || (root.headingSource !== null && root.headingSource.visible))

    implicitHeight: contentColumn.implicitHeight + root.padding * 2 + (root.hasHeading ? root.headingContentGap : 0)
    height: implicitHeight

    function adoptHeading() {
        if (root.heading.trim().length > 0)
            return
        if (!root.showFrame || root.headingSource || root.adoptingHeading)
            return

        var items = contentColumn.children
        if (!items || items.length === 0)
            return

        var candidate = items[0]
        if (!candidate || candidate.text === undefined || candidate.font === undefined)
            return

        root.adoptingHeading = true
        root.headingSource = candidate
        // Keep the original Text only as a reactive source for its text and
        // visibility. Rendering a separate legend avoids reparenting its
        // original geometry/bindings into the frame's layout.
        candidate.parent = root
        candidate.opacity = 0
        candidate.x = 0
        candidate.y = 0
        candidate.width = 0
        candidate.height = 0
        candidate.z = -1
        root.adoptingHeading = false
    }

    onShowFrameChanged: {
        if (showFrame)
            Qt.callLater(root.adoptHeading)
    }

    Component.onCompleted: Qt.callLater(root.adoptHeading)

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.hasHeading ? 8 : 0
        visible: root.showFrame
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: Config.cardBordersEnabled ? root.borderWidth : 0
        radius: Config.scaledCornerRadius(root.radius)
        z: -1
    }

    SettingsSearchHighlight {
        anchors.fill: parent
        overlayZ: 4
        highlighted: root.settingsSearchHighlighted
        cornerRadius: Config.scaledCornerRadius(root.radius)
    }

    Loader {
        id: headingActionsLoader
        y: 0
        z: 5
        sourceComponent: root.headingActions
        anchors.right: parent.right
        anchors.rightMargin: root.padding
    }

    TextMetrics {
        id: headingMetrics
        font.family: Config.settingsFontFamily
        font.pixelSize: Config.settingsUiSize(11)
        font.bold: false
        text: root.renderedHeading
    }

    Rectangle {
        id: headingBorderCutout
        visible: root.hasHeading && Config.cardBordersEnabled
        x: headingLabel.x - 5
        y: 8 - root.borderWidth
        width: headingLabel.width + 10 + (root.modified ? 10 : 0)
        height: Math.max(3, root.borderWidth * 2 + 1)
        color: root.headingBackgroundColor
        border.width: 0
        z: 1
    }

    Text {
        id: headingLabel
        visible: root.hasHeading
        x: root.padding + 8
        // Center the caption on the top edge of the frame, like a fieldset legend.
        y: 2
        width: Math.max(0, Math.min(headingMetrics.advanceWidth,
                                    root.width - root.padding * 2 - 16 - (root.modified ? 10 : 0)
                                    - (headingActionsLoader.item ? headingActionsLoader.width + 8 : 0)))
        height: Config.settingsUiSize(14)
        text: root.renderedHeading
        color: Config.settingsSubheading
        font.family: Config.settingsFontFamily
        font.pixelSize: Config.settingsUiSize(11)
        font.bold: false
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        z: 2

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            ToolTip.visible: root.settingsSearchHighlighted
                && root.settingsSearchMatchHint.length > 0 && containsMouse
            ToolTip.text: root.settingsSearchMatchHint
            ToolTip.delay: 450
        }
    }

    Rectangle {
        visible: root.hasHeading && root.modified
        width: 5
        height: 5
        radius: width / 2
        x: headingLabel.x + headingLabel.width + 5
        y: headingLabel.y + Math.max(0, (headingLabel.height - height) / 2)
        color: root.modifiedColor
        border.width: 0
        antialiasing: true
        z: 3
    }

    // Frames without an adoptable legend still need a visible dirty marker.
    // Some older groups start with a Row/Column instead of a Text heading.
    Rectangle {
        visible: root.showFrame && root.modified && !root.hasHeading
        width: 6
        height: 6
        radius: width / 2
        x: Math.max(4, root.width - Math.max(10, root.padding + 4) - width)
        y: 3
        color: root.modifiedColor
        border.width: 0
        antialiasing: true
        z: 3
    }

    Column {
        id: contentColumn
        x: root.padding
        y: root.padding + (root.hasHeading ? root.headingContentGap : 0)
        width: Math.max(0, root.width - root.padding * 2)
        spacing: root.contentSpacing
        onChildrenChanged: Qt.callLater(root.adoptHeading)
    }
}
