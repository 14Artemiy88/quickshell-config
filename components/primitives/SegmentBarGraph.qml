import QtQuick

// Shared renderer for compact horizontal strips of percentage bars.
// direction "up" anchors bar bottoms; "down" anchors bar tops.
Item {
    id: root

    // A shared ListModel lets CAVA update only bars whose samples changed.
    property var valuesModel: null
    property int barCount: valuesModel ? valuesModel.count : 0
    property int spacing: 0
    // Set slotWidth > 0 for fixed-width slots; otherwise slots share available width.
    property real slotWidth: 0
    // barWidthRatio > 0 opts into a proportional width; otherwise use barWidth.
    property real barWidth: 2
    property real barWidthRatio: 0
    property string direction: "up"
    // When enabled, zero/invalid samples do not render a 1px minimum bar.
    property bool hideZeroBars: false
    property color barColor: "white"
    property color barBorderColor: barColor
    property int barBorderWidth: 0

    function barHeightFor(value, availableHeight) {
        var percent = Number(value)
        if (!isFinite(percent)) percent = 0
        if (root.hideZeroBars && percent <= 0) return 0
        return Math.max(1, Math.min(availableHeight, percent * availableHeight / 100))
    }

    Row {
        id: barRow
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.valuesModel

            delegate: Item {
                required property real value
                width: root.slotWidth > 0
                    ? root.slotWidth
                    : (root.barCount > 0
                        ? (barRow.width - (root.barCount - 1) * root.spacing) / root.barCount
                        : 0)
                height: barRow.height

                Rectangle {
                    width: root.barWidthRatio > 0
                        ? Math.max(1, Math.round(parent.width * root.barWidthRatio))
                        : root.barWidth
                    height: root.barHeightFor(value, parent.height)
                    visible: !root.hideZeroBars || height > 0
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
