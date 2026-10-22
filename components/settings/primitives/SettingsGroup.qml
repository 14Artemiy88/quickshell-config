import QtQuick
import "../../.."

Item {
    id: root

    property bool showFrame: false
    property real padding: showFrame ? 10 : 0
    property real contentSpacing: 5
    property color backgroundColor: Config.settingsBackground
    property color borderColor: Config.baseColor
    property int borderWidth: 1
    property real radius: Config.frameRadius
    // The first direct Text child is promoted to a consistent fieldset legend.
    property var headingSource: null
    property bool adoptingHeading: false

    default property alias contentData: contentColumn.data

    // Hidden or empty heading Text nodes must not create a notch or vertical gap.
    readonly property bool hasHeading: root.showFrame
        && root.headingSource
        && root.headingSource.visible
        && String(root.headingSource.text || "").trim().length > 0

    implicitHeight: contentColumn.implicitHeight + root.padding * 2 + (root.hasHeading ? 8 : 0)
    height: implicitHeight

    function adoptHeading() {
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
        visible: root.showFrame
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.radius
        z: -1
    }

    Rectangle {
        id: headingBackground
        visible: root.hasHeading
        x: headingLabel.x - 4
        y: headingLabel.y
        width: headingLabel.width + 8
        height: headingLabel.height
        color: root.backgroundColor
        z: 1
    }

    TextMetrics {
        id: headingMetrics
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        font.bold: false
        text: root.headingSource ? String(root.headingSource.text) : ""
    }

    Text {
        id: headingLabel
        visible: root.hasHeading
        x: root.padding + 8
        y: -Math.ceil(Config.settingsUiSize(11) / 2)
        width: Math.max(0, Math.min(headingMetrics.advanceWidth,
                                    root.width - root.padding * 2 - 16))
        height: Config.settingsUiSize(14)
        text: root.headingSource ? String(root.headingSource.text) : ""
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        font.bold: false
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        z: 2
    }

    Column {
        id: contentColumn
        x: root.padding
        y: root.padding + (root.hasHeading ? 8 : 0)
        width: Math.max(0, root.width - root.padding * 2)
        spacing: root.contentSpacing
        onChildrenChanged: Qt.callLater(root.adoptHeading)
    }
}
