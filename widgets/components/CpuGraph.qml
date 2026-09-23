import QtQuick
import ".."
import Quickshell
import Quickshell.Io

Frame {
    id: root
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
    Column {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0
        Item {
            width: parent.width; height: 35
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
                            height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * Config.cpuGraphScale))
                            color: Config.baseColor
                            border.color: Config.baseColor
                            border.width: 1
                        }
                    }
                }
            }
        }
        Item {
            width: parent.width; height: 35
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
                            height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * Config.cpuGraphScale))
                            color: Config.baseColor
                            border.color: Config.baseColor
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}
