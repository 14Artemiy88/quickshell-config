import QtQuick
import "../.."
import QtQuick.Controls

Item {
    id: root
    property string label: "↺"
    property string tooltip: "Сбросить"
    property bool emphasized: false
    property bool emphasizedHoverOnly: false
    property color emphasizedColor: Config.accent
    signal clicked()

    width: 30
    height: 30

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.emphasized && (mouse.containsMouse || !root.emphasizedHoverOnly) ? root.emphasizedColor : Config.settingsBackground
        border.color: root.emphasized ? root.emphasizedColor : Config.baseColor
        border.width: 1

        Text {
            anchors.fill: parent
            text: root.label
            color: root.emphasized && mouse.containsMouse ? Config.black : (root.emphasized ? root.emphasizedColor : Config.text)
            font.bold: root.emphasized
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    ToolTip.visible: mouse.containsMouse
    ToolTip.text: root.tooltip
    ToolTip.delay: 500
}
