import QtQuick
import ".."
import Quickshell
import Quickshell.Io

Frame {
    id: root
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

    Rectangle {
        anchors.fill: parent
        color: Config.background
        radius: Config.frameRadius
        z: 0
    }

    Column {
        anchors.fill: parent
        spacing: 0
        z: 1

        Item {
            width: parent.width
            height: Config.cavaRowHeight
            Row {
                anchors.fill: parent
                spacing: Config.cavaRowSpacing
                Repeater {
                    model: Config.cavaBars
                    delegate: Item {
                        width: root.values.length > 0 ? (parent.width - (root.values.length - 1)) / root.values.length : 0
                        height: parent.height
                        Rectangle {
                            width: Math.max(1, Math.round(parent.width * Config.cavaBarWidthRatio))
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            height: Math.max(Config.cavaBarMinHeight, Math.min(parent.height, Number(root.values[index] || 0) * Config.cavaBarHeightScale))
                            color: Config.baseColor
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: Config.cavaRowHeight
            Row {
                anchors.fill: parent
                spacing: Config.cavaRowSpacing
                Repeater {
                    model: Config.cavaBars
                    delegate: Item {
                        width: root.values.length > 0 ? (parent.width - (root.values.length - 1)) / root.values.length : 0
                        height: parent.height
                        Rectangle {
                            width: Math.max(1, Math.round(parent.width * Config.cavaBarWidthRatio))
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            height: Math.max(Config.cavaBarMinHeight, Math.min(parent.height, Number(root.values[index] || 0) * Config.cavaBarHeightScale))
                            color: Config.baseColor
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Config.transparent
        border.color: Config.baseColor
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius
        z: 100
    }
}
