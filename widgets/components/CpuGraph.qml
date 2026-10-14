import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell
import Quickshell.Io
import "../js/cpuGraphData.js" as CpuGraphData

Primitives.ModuleFrame {
    id: root
    moduleName: "cpuGraph"
    width: 315
    height: 82
    property var values: []
    property var flippedValues: []

    Process {
        id: proc
        command: [Quickshell.shellDir + "/scripts/cpu_graph_daemon"]
        running: Settings.loaded && Settings.cpuGraph
        stdout: SplitParser {
            onRead: line => {
                try {
                    var parsed = JSON.parse(line.trim())
                    var normalized = CpuGraphData.normalizeHistory(parsed, 51)
                    if (normalized !== null)
                        root.values = normalized
                } catch (e) {}
            }
        }
    }

    // Both halves retain the mirrored graph with its baseline in the center.
    Column {
        visible: Config.cpuGraphMode === "both"
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0

        Item {
            width: parent.width
            height: parent.height / 2
            Primitives.SegmentBarGraph {
                anchors.fill: parent
                values: root.values
                barCount: 51
                slotWidth: Config.cpuGraphSegmentSlotWidth
                barWidth: Config.cpuGraphBarWidth
                barColor: Config.baseColor
                barBorderColor: Config.baseColor
                barBorderWidth: 1
                direction: "up"
            }
        }

        Item {
            width: parent.width
            height: parent.height / 2
            Primitives.SegmentBarGraph {
                anchors.fill: parent
                values: root.values
                barCount: 51
                slotWidth: Config.cpuGraphSegmentSlotWidth
                barWidth: Config.cpuGraphBarWidth
                barColor: Config.baseColor
                barBorderColor: Config.baseColor
                barBorderWidth: 1
                direction: "down"
            }
        }
    }

    // Upper-only mode: use the full graph height and grow upward from the bottom edge.
    Item {
        visible: Config.cpuGraphMode === "top"
        anchors.fill: parent
        anchors.margins: 3

        Primitives.SegmentBarGraph {
            anchors.fill: parent
            values: root.values
            barCount: 51
            slotWidth: Config.cpuGraphSegmentSlotWidth
            barWidth: Config.cpuGraphBarWidth
            barColor: Config.baseColor
            barBorderColor: Config.baseColor
            barBorderWidth: 1
            direction: "up"
        }
    }

    // Lower-only mode: use the full graph height and grow downward from the top edge.
    Item {
        visible: Config.cpuGraphMode === "bottom"
        anchors.fill: parent
        anchors.margins: 3

        Primitives.SegmentBarGraph {
            anchors.fill: parent
            values: root.values
            barCount: 51
            slotWidth: Config.cpuGraphSegmentSlotWidth
            barWidth: Config.cpuGraphBarWidth
            barColor: Config.baseColor
            barBorderColor: Config.baseColor
            barBorderWidth: 1
            direction: "down"
        }
    }
}
