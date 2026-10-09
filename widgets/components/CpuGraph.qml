import QtQuick
import "." as Widgets
import ".."
import Quickshell
import Quickshell.Io

Widgets.Frame {
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
                try { root.values = JSON.parse(line.trim()) } catch (e) {}
            }
        }
    }
    // Both halves: the existing mirrored graph with its baseline at the center.
    Column {
        visible: Config.cpuGraphMode === "both"
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0
        Item {
            width: parent.width; height: parent.height / 2
            Row {
                anchors.fill: parent
                spacing: 0
                Repeater {
                    model: 51
                    delegate: Item {
                        width: Config.cpuGraphSegmentSlotWidth
                        height: parent.height
                        Rectangle {
                            width: Config.cpuGraphBarWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * parent.height / 100))
                            color: Config.baseColor
                            border.color: Config.baseColor
                            border.width: 1
                        }
                    }
                }
            }
        }
        Item {
            width: parent.width; height: parent.height / 2
            Row {
                anchors.fill: parent
                spacing: 0
                Repeater {
                    model: 51
                    delegate: Item {
                        width: Config.cpuGraphSegmentSlotWidth
                        height: parent.height
                        Rectangle {
                            width: Config.cpuGraphBarWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * parent.height / 100))
                            color: Config.baseColor
                            border.color: Config.baseColor
                            border.width: 1
                        }
                    }
                }
            }
        }
    }

    // Upper-only: use the full graph height and grow upward from the bottom edge.
    Item {
        visible: Config.cpuGraphMode === "top"
        anchors.fill: parent
        anchors.margins: 3
        Row {
            anchors.fill: parent
            spacing: 0
            Repeater {
                model: 51
                delegate: Item {
                    width: Config.cpuGraphSegmentSlotWidth
                    height: parent.height
                    Rectangle {
                        width: Config.cpuGraphBarWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * parent.height / 100))
                        color: Config.baseColor
                        border.color: Config.baseColor
                        border.width: 1
                    }
                }
            }
        }
    }

    // Lower-only: use the full graph height and grow downward from the top edge.
    Item {
        visible: Config.cpuGraphMode === "bottom"
        anchors.fill: parent
        anchors.margins: 3
        Row {
            anchors.fill: parent
            spacing: 0
            Repeater {
                model: 51
                delegate: Item {
                    width: Config.cpuGraphSegmentSlotWidth
                    height: parent.height
                    Rectangle {
                        width: Config.cpuGraphBarWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * parent.height / 100))
                        color: Config.baseColor
                        border.color: Config.baseColor
                        border.width: 1
                    }
                }
            }
        }
    }

}
