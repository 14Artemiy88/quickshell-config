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

    // Instantiate only the selected layout. Previously all three mode layouts
    // existed at once, so their hidden Repeaters also allocated bar delegates.
    Loader {
        anchors.fill: parent
        sourceComponent: Config.cpuGraphMode === "both" ? bothModeComponent
            : Config.cpuGraphMode === "top" ? topModeComponent
            : Config.cpuGraphMode === "bottom" ? bottomModeComponent
            : bothModeComponent
    }

    Component {
        id: bothModeComponent

        // Both halves retain the mirrored graph with its baseline in the center.
        Column {
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
    }

    Component {
        id: topModeComponent

        // Upper-only mode: use full graph height and grow upward from bottom.
        Item {
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
    }

    Component {
        id: bottomModeComponent

        // Lower-only mode: use full graph height and grow downward from top.
        Item {
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
}
