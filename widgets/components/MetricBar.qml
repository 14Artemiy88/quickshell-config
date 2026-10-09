import QtQuick
import ".."

Item {
    id: root
    property string label: ""
    property real value: 0
    property color fillColor: Config.accent
    property color trackColor: Config.metricTrack
    property bool verticalGauge: false
    property string direction: Config.cpuBarDirection
    readonly property bool verticalDirection: direction === "topToBottom" || direction === "bottomToTop"
    height: verticalGauge ? (parent ? parent.height : 200) : Config.cpuRowHeight
    width: verticalGauge ? (parent ? parent.width : 32) : 303

    Text {
        visible: !root.verticalGauge
        x: Config.cpuLabelLeftPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Config.text
        font.family: Config.font
        font.pixelSize: Config.uiFontSize(12)
    }

    // Horizontal modes retain the existing track layout. The fill grows from
    // the selected edge without changing the measured percentage.
    Rectangle {
        id: horizontalTrack
        visible: !root.verticalGauge
        x: Config.cpuBarLeftOffset
        y: (parent.height - Config.cpuBarThickness) / 2
        width: Config.cpuBarWidth
        height: Config.cpuBarThickness
        radius: Config.cpuBarRadius
        color: root.trackColor
        clip: true

        Rectangle {
            readonly property real fillWidth: parent.width * Math.max(0, Math.min(100, root.value)) / 100
            width: fillWidth
            height: parent.height
            x: root.direction === "rightToLeft" ? parent.width - width : 0
            radius: Config.cpuBarRadius
            color: root.fillColor
        }
    }

    // Vertical modes switch the CPU/RAM widget to a set of vertical meters.
    // The available height is used as the track length so the bars fit the
    // module instead of overlapping neighboring rows.
    Rectangle {
        id: verticalTrack
        visible: root.verticalGauge
        width: Math.min(Config.cpuBarThickness, Math.max(4, parent.width - 4))
        height: Math.max(20, Math.min(Config.cpuBarWidth, parent.height - 30))
        x: (parent.width - width) / 2
        y: 4
        radius: Math.min(Config.cpuBarRadius, width / 2)
        color: root.trackColor
        clip: true

        Rectangle {
            readonly property real fillHeight: parent.height * Math.max(0, Math.min(100, root.value)) / 100
            width: parent.width
            height: fillHeight
            x: 0
            y: root.direction === "bottomToTop" ? parent.height - height : 0
            radius: Math.min(Config.cpuBarRadius, width / 2)
            color: root.fillColor
        }
    }

    Text {
        visible: root.verticalGauge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        color: Config.text
        font.family: Config.font
        font.pixelSize: Config.uiFontSize(12)
        elide: Text.ElideNone
    }
}
