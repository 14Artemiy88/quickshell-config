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
    height: compactPresentation ? 70 : widePresentation ? 94 : 82
    property var values: []
    readonly property real effectiveGraphSlotWidth: {
        var available = Math.max(51, widthBudget - 6)
        var configured = Math.max(1, Number(Config.cpuGraphSegmentSlotWidth) || 1)
        if (compactPresentation)
            return Math.max(1, Math.min(configured, available / 51))
        // Keep the legacy 315px baseline, but distribute all 51 slots across
        // any wider regular or wide surface instead of leaving a trailing gap.
        if (widthBudget > 315 || widePresentation)
            return Math.max(1, available / 51)
        return configured
    }
    readonly property real effectiveGraphBarWidth: {
        var configuredSlot = Math.max(1, Number(Config.cpuGraphSegmentSlotWidth) || 1)
        var configuredBar = Math.max(1, Number(Config.cpuGraphBarWidth) || 1)
        // Keep the configured density at the 315px baseline, then grow each
        // visible bar in proportion to its slot as the host gets wider.
        var widthScale = Math.max(1, effectiveGraphSlotWidth / configuredSlot)
        return Math.max(1, Math.min(effectiveGraphSlotWidth, configuredBar * widthScale))
    }

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
                Primitives.FlowingSegmentBarGraph {
                    anchors.fill: parent
                    values: root.values
                    barCount: 51
                    slotWidth: root.effectiveGraphSlotWidth
                    barWidth: root.effectiveGraphBarWidth
                    barColor: Config.baseColor
                    barBorderColor: Config.baseColor
                    barBorderWidth: 1
                    direction: "up"
                }
            }

            Item {
                width: parent.width
                height: parent.height / 2
                Primitives.FlowingSegmentBarGraph {
                    anchors.fill: parent
                    values: root.values
                    barCount: 51
                    slotWidth: root.effectiveGraphSlotWidth
                    barWidth: root.effectiveGraphBarWidth
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
            Primitives.FlowingSegmentBarGraph {
                anchors.fill: parent
                values: root.values
                barCount: 51
                slotWidth: root.effectiveGraphSlotWidth
                barWidth: root.effectiveGraphBarWidth
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
            Primitives.FlowingSegmentBarGraph {
                anchors.fill: parent
                values: root.values
                barCount: 51
                slotWidth: root.effectiveGraphSlotWidth
                barWidth: root.effectiveGraphBarWidth
                barColor: Config.baseColor
                barBorderColor: Config.baseColor
                barBorderWidth: 1
                direction: "down"
            }
        }
    }
}
