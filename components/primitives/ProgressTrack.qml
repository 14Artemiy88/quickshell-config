import QtQuick

// Shared filled-track renderer used by CPU/RAM gauges and Top Apps.
// value is expressed as a percentage (0..100); direction controls the edge
// from which the fill grows without changing the measured value.
Item {
    id: root

    property real value: 0
    property color fillColor: "white"
    property color trackColor: "transparent"
    property real radius: 0
    property string direction: "leftToRight"
    readonly property real normalizedValue: {
        const v = Number(value)
        return isFinite(v) ? Math.max(0, Math.min(100, v)) : 0
    }
    readonly property bool vertical: direction === "topToBottom" || direction === "bottomToTop"

    Rectangle {
        id: track
        anchors.fill: parent
        radius: root.radius
        color: root.trackColor
        clip: true

        Rectangle {
            width: root.vertical ? parent.width : parent.width * root.normalizedValue / 100
            height: root.vertical ? parent.height * root.normalizedValue / 100 : parent.height
            x: root.vertical ? 0 : (root.direction === "rightToLeft" ? parent.width - width : 0)
            y: root.direction === "bottomToTop" ? parent.height - height : 0
            radius: root.radius
            color: root.fillColor
        }
    }
}
