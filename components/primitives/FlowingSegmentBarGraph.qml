import QtQuick
import "../../js/cpuGraphData.js" as CpuGraphData

// Rolling history renderer. New samples enter from the right while the whole
// strip moves left by exactly one slot, so the graph flows at a steady speed
// instead of jumping one column per daemon update.
Item {
    id: root
    clip: true

    property var values: []
    property int barCount: values && values.length !== undefined ? values.length : 0
    property int spacing: 0
    property real slotWidth: 0
    property real barWidth: 2
    property real barWidthRatio: 0
    property string direction: "up"
    property color barColor: "white"
    property color barBorderColor: barColor
    property int barBorderWidth: 0
    // Adapt each one-slot movement to the actual daemon sample cadence.
    // The small headroom prevents a visible pause between consecutive samples.
    property int flowDuration: 992
    property real lastSampleAt: 0
    property real smoothedSampleInterval: 1000
    property int pendingFlowDuration: 992

    property var displayedValues: []
    property var flowFrame: []
    property var pendingValues: []
    property bool hasInitialValues: false
    property bool isFlowing: false
    property bool hasPendingValues: false

    readonly property real resolvedSlotWidth: root.slotWidth > 0
        ? root.slotWidth
        : Math.max(1, (root.width - Math.max(0, root.barCount - 1) * root.spacing) / Math.max(1, root.barCount))
    readonly property real slotPitch: root.resolvedSlotWidth + root.spacing

    function sameHistory(a, b) {
        if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length)
            return false
        for (var i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                return false
        }
        return true
    }

    // Keep the Repeater backed by one stable 52-row ListModel. Switching its
    // model between 51 and 52 element arrays every second can recreate or
    // rebind delegates at the exact moment the strip is reset, which looks
    // like a tiny hitch even when the geometry is mathematically identical.
    function syncFlowModel(values) {
        if (!Array.isArray(values))
            return

        for (var i = 0; i < values.length; i++) {
            var value = Number(values[i])
            if (i < flowModel.count) {
                if (flowModel.get(i).value !== value)
                    flowModel.setProperty(i, "value", value)
            } else {
                flowModel.append({ value: value })
            }
        }

        while (flowModel.count > values.length)
            flowModel.remove(flowModel.count - 1)
    }

    function restingFrame(values) {
        if (!Array.isArray(values) || values.length < 1)
            return []
        return values.concat([values[values.length - 1]])
    }

    function rotateFlowModel(values) {
        if (!Array.isArray(values) || values.length < 1)
            return

        if (flowModel.count === values.length + 1) {
            // Preserve all 52 delegate objects. Move the 51 visible rows as a
            // single model operation, then refresh only the off-screen tail.
            flowModel.move(1, 0, values.length)
            flowModel.setProperty(values.length, "value", Number(values[values.length - 1]))
        } else {
            root.syncFlowModel(root.restingFrame(values))
        }
    }

    function beginFlow(next, duration) {
        if (sameHistory(root.displayedValues, next))
            return

        var frame = CpuGraphData.buildFlowFrame(root.displayedValues, next)
        if (frame === null) {
            // A daemon restart or a discontinuous snapshot is a rebase, not a
            // real one-sample advance. Avoid scrolling unrelated history.
            root.displayedValues = next
            root.flowFrame = root.restingFrame(next)
            root.syncFlowModel(root.flowFrame)
            strip.x = 0
            return
        }

        root.flowFrame = frame
        // At rest, the 52nd bar is just beyond the clipped viewport. Only
        // update that one off-screen row when a new sample arrives.
        if (flowModel.count === frame.length)
            flowModel.setProperty(frame.length - 1, "value", Number(frame[frame.length - 1]))
        else
            root.syncFlowModel(frame)
        root.flowDuration = duration
        root.isFlowing = true
        strip.x = 0
        flowAnimation.restart()
    }

    function acceptValues(incoming) {
        var next = CpuGraphData.normalizeHistory(incoming, root.barCount)
        if (next === null)
            return

        // Measure when samples actually reach this renderer rather than
        // assuming that `sleep 1` means an exact 1000 ms cadence.
        var sampleAt = Date.now()
        var sampleInterval = root.lastSampleAt > 0 ? sampleAt - root.lastSampleAt : 1000
        root.lastSampleAt = sampleAt
        root.smoothedSampleInterval = CpuGraphData.smoothSampleInterval(
            root.smoothedSampleInterval, sampleInterval)
        var nextFlowDuration = CpuGraphData.resolveFlowDuration(root.smoothedSampleInterval)

        if (!root.hasInitialValues) {
            root.displayedValues = next
            root.flowFrame = root.restingFrame(next)
            root.syncFlowModel(root.flowFrame)
            root.hasInitialValues = true
            return
        }

        if (root.isFlowing) {
            root.pendingValues = next
            root.pendingFlowDuration = nextFlowDuration
            root.hasPendingValues = true
            return
        }

        root.beginFlow(next, nextFlowDuration)
    }

    function finishFlow() {
        var settled = CpuGraphData.settleFlowFrame(root.flowFrame)
        if (settled !== null)
            root.displayedValues = settled
        else
            settled = root.displayedValues

        // Rotate existing ListModel rows before resetting x. This is a single
        // model move plus one off-screen value update, not 52 role changes or
        // a Repeater rebuild at the end of every sample animation.
        root.flowFrame = root.restingFrame(settled)
        root.rotateFlowModel(settled)
        strip.x = 0
        root.isFlowing = false

        if (root.hasPendingValues) {
            var pending = root.pendingValues
            var pendingDuration = root.pendingFlowDuration
            root.pendingValues = []
            root.hasPendingValues = false
            root.beginFlow(pending, pendingDuration)
        }
    }

    onValuesChanged: root.acceptValues(root.values)

    Component.onCompleted: root.acceptValues(root.values)

    ListModel {
        id: flowModel
    }

    Row {
        id: strip
        height: root.height
        spacing: root.spacing
        // Keep one extra slot permanently beyond the clipping edge.
        width: root.resolvedSlotWidth * (root.barCount + 1) + root.spacing * root.barCount

        Repeater {
            model: flowModel

            delegate: Item {
                required property var value
                width: root.resolvedSlotWidth
                height: strip.height

                Rectangle {
                    width: root.barWidthRatio > 0
                        ? Math.max(1, Math.round(parent.width * root.barWidthRatio))
                        : root.barWidth
                    height: Math.max(1, Math.min(parent.height, Number(value) * parent.height / 100))
                    x: (parent.width - width) / 2
                    y: root.direction === "up" ? parent.height - height : 0
                    color: root.barColor
                    border.color: root.barBorderColor
                    border.width: root.barBorderWidth
                }
            }
        }
    }

    NumberAnimation {
        id: flowAnimation
        target: strip
        property: "x"
        from: 0
        to: -root.slotPitch
        duration: Math.max(1, root.flowDuration)
        easing.type: Easing.Linear
        onFinished: root.finishFlow()
    }
}
