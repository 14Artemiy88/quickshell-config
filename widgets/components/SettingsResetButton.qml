import QtQuick
import ".."
import QtQuick.Controls

Item {
    id: root
    property string label: "↺"
    property string tooltip: "Сбросить"
    signal clicked()

    width: 30
    height: 28

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: mouse.containsMouse ? Config.accent : Config.background
        border.color: Config.baseColor
        border.width: 1

        Text {
            anchors.fill: parent
            text: root.label
            color: mouse.containsMouse ? Config.black : Config.text
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
