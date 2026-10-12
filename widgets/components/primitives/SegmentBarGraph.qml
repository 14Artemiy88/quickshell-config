import QtQuick

// Shared renderer for compact horizontal strips of percentage bars.
// direction "up" anchors bar bottoms; "down" anchors bar tops.
Item {
    id: root

    property var values: []
    property int barCount: values && values.length !== undefined ? values.length : 0
    property int spacing: 0
    // Set slotWidth > 0 for fixed-width slots; otherwise slots share available width.
    property real slotWidth: 0
    // barWidthRatio > 0 opts into a proportional width; otherwise use barWidth.
    property real barWidth: 2
    property real barWidthRatio: 0
    property string direction: "up"
    property color barColor: "white"
    property color barBorderColor: barColor
    property int barBorderWidth: 0

    function barHeightFor(value, availableHeight) {
        var percent = Number(value)
        if (!isFinite(percent)) percent = 0
        return Math.max(1, Math.min(availableHeight, percent * availableHeight / 100))
    }

    Row {
        id: barRow
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: Math.max(0, root.barCount)

            delegate: Item {
                width: root.slotWidth > 0
                    ? root.slotWidth
                    : (root.values && root.values.length > 0
                        ? (barRow.width - (root.values.length - 1) * root.spacing) / root.values.length
                        : 0)
                height: barRow.height

                Rectangle {
                    width: root.barWidthRatio > 0
                        ? Math.max(1, Math.round(parent.width * root.barWidthRatio))
                        : root.barWidth
                    height: root.barHeightFor(root.values && root.values.length > index ? root.values[index] : 0, parent.height)
                    x: (parent.width - width) / 2
                    y: root.direction === "up" ? parent.height - height : 0
                    color: root.barColor
                    border.color: root.barBorderColor
                    border.width: root.barBorderWidth
                }
            }
        }
    }
}
