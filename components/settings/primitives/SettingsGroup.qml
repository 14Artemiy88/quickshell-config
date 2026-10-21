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

    default property alias contentData: contentColumn.data

    implicitHeight: contentColumn.implicitHeight + root.padding * 2
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        visible: root.showFrame
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.radius
        z: -1
    }

    Column {
        id: contentColumn
        x: root.padding
        y: root.padding
        width: Math.max(0, root.width - root.padding * 2)
        spacing: root.contentSpacing
    }
}
