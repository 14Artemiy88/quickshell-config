import QtQuick
import ".."

Item {
    id: root
    property string label: ""
    property real value: 0
    property color fillColor: Config.accent
    property color trackColor: Config.metricTrack
    height: Config.cpuRowHeight
    width: 303

    Text {
        x: Config.cpuLabelLeftPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Config.text
        font.family: Config.font
        font.pixelSize: Config.uiFontSize(12)
    }

    Rectangle {
        x: Config.cpuBarLeftOffset
        y: (parent.height - Config.cpuBarThickness) / 2
        width: Config.cpuBarWidth
        height: Config.cpuBarThickness
        radius: Config.cpuBarRadius
        color: root.trackColor
        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
            height: parent.height
            radius: Config.cpuBarRadius
            color: root.fillColor
        }
    }
}
