import QtQuick
import ".."

Item {
    id: root
    property string label: ""
    property real value: 0
    property color fillColor: Config.accent
    property color trackColor: Config.metricTrack
    height: 17
    width: 303

    Text {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Config.text
        font.family: Config.font
        font.pixelSize: 12
    }

    Rectangle {
        x: 35
        y: 4
        width: 267
        height: 8
        radius: 8
        color: root.trackColor
        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
            height: parent.height
            radius: 8
            color: root.fillColor
        }
    }
}
