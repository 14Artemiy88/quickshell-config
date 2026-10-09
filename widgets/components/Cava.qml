import QtQuick
import "." as Widgets
import ".."
import Quickshell
import Quickshell.Io

Widgets.Frame {
    id: root
    moduleName: "cava"
    width: 300
    height: 80
    property var values: []

    Process {
        id: cavaProc
        command: [Quickshell.shellDir + "/scripts/cava", String(Config.cavaBars), String(Config.cavaFramerate)]
        running: Settings.loaded && Settings.cava
        stdout: SplitParser {
            onRead: line => {
                try { root.values = JSON.parse(line.trim()) } catch(e) {}
            }
        }
    }

    function restartCava() {
        if (!Settings.loaded || !Settings.cava) return
        root.values = []
        cavaProc.running = false
        Qt.callLater(function() {
            if (Settings.loaded && Settings.cava) cavaProc.running = true
        })
    }

    Connections {
        target: Config
        function onCavaBarsChanged() { root.restartCava() }
        function onCavaFramerateChanged() { root.restartCava() }
    }

    function barWidthForSlot(slotWidth) {
        return Math.max(1, Math.round(slotWidth * Config.cavaBarWidthRatio))
    }

    function barHeightFor(percent, availableHeight) {
        return Math.max(1, Math.min(availableHeight, Number(percent || 0) * availableHeight / 100))
    }

    Item {
        anchors.fill: parent

        // Mirrored mode: preserve the original CAVA layout.
        Item {
            visible: Config.cavaMode === "both"
            anchors.fill: parent

            Item {
                width: parent.width
                height: parent.height / 2

                Row {
                    anchors.fill: parent
                    spacing: Config.cavaRowSpacing
                    Repeater {
                        model: Config.cavaBars
                        delegate: Item {
                            width: root.values.length > 0 ? (parent.width - (root.values.length - 1) * Config.cavaRowSpacing) / root.values.length : 0
                            height: parent.height

                            Rectangle {
                                width: Math.max(1, Math.round(parent.width * Config.cavaBarWidthRatio))
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                height: root.barHeightFor(root.values[index], parent.height)
                                color: Config.baseColor
                            }
                        }
                    }
                }
            }

            Item {
                y: parent.height / 2
                width: parent.width
                height: parent.height / 2

                Row {
                    anchors.fill: parent
                    spacing: Config.cavaRowSpacing
                    Repeater {
                        model: Config.cavaBars
                        delegate: Item {
                            width: root.values.length > 0 ? (parent.width - (root.values.length - 1) * Config.cavaRowSpacing) / root.values.length : 0
                            height: parent.height

                            Rectangle {
                                width: Math.max(1, Math.round(parent.width * Config.cavaBarWidthRatio))
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                height: root.barHeightFor(root.values[index], parent.height)
                                color: Config.baseColor
                            }
                        }
                    }
                }
            }
        }

        // Upper-only mode: bars use the full widget height and grow upward from the bottom edge.
        Item {
            visible: Config.cavaMode === "top"
            anchors.fill: parent

            Row {
                anchors.fill: parent
                spacing: Config.cavaRowSpacing
                Repeater {
                    model: Config.cavaBars
                    delegate: Item {
                        width: root.values.length > 0 ? (parent.width - (root.values.length - 1) * Config.cavaRowSpacing) / root.values.length : 0
                        height: parent.height

                        Rectangle {
                            width: Math.max(1, Math.round(parent.width * Config.cavaBarWidthRatio))
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            height: root.barHeightFor(root.values[index], parent.height)
                            color: Config.baseColor
                        }
                    }
                }
            }
        }

        // Lower-only mode: bars use the full widget height and grow downward from the top edge.
        Item {
            visible: Config.cavaMode === "bottom"
            anchors.fill: parent

            Row {
                anchors.fill: parent
                spacing: Config.cavaRowSpacing
                Repeater {
                    model: Config.cavaBars
                    delegate: Item {
                        width: root.values.length > 0 ? (parent.width - (root.values.length - 1) * Config.cavaRowSpacing) / root.values.length : 0
                        height: parent.height

                        Rectangle {
                            width: Math.max(1, Math.round(parent.width * Config.cavaBarWidthRatio))
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            height: root.barHeightFor(root.values[index], parent.height)
                            color: Config.baseColor
                        }
                    }
                }
            }
        }
    }
}
