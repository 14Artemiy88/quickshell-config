import QtQuick
import "../../.."

Item {
    id: root

    property string text: ""
    property bool selected: false
    property real cornerRadius: 4
    property int fontPixelSize: 10
    property bool leftAligned: false
    property int horizontalPadding: 6
    property bool boldWhenSelected: true
    property color selectedBackground: Config.accent
    property color normalBackground: Config.settingsBackground
    property color selectedTextColor: Config.black
    property color normalTextColor: Config.text
    property color normalBorderColor: Config.baseColor
    property color hoverBorderColor: Config.accent
    property bool hovered: false
    property bool modified: false
    property color modifiedColor: Config.accent

    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.selected ? root.selectedBackground : root.normalBackground
        border.color: root.hovered ? root.hoverBorderColor : root.normalBorderColor
        border.width: 1
        antialiasing: true

        Text {
            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding + (root.modified ? 10 : 0)
            text: root.text
            color: root.selected ? root.selectedTextColor : root.normalTextColor
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fontPixelSize)
            font.bold: root.selected && root.boldWhenSelected
            horizontalAlignment: root.leftAligned ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Rectangle {
            visible: root.modified
            width: 5
            height: 5
            radius: width / 2
            x: parent.width - width - 5
            y: 5
            color: root.selected ? root.selectedTextColor : root.modifiedColor
            border.width: 0
            antialiasing: true
        }

        HoverHandler {
            onHoveredChanged: root.hovered = hovered
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.clicked()
        }
    }
}
