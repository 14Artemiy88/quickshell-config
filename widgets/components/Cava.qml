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

    Column {
        anchors.fill: parent
        spacing: 0
        z: 1

        Item {
            width: parent.width
            height: parent.height / 2
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
                            height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * parent.height / 100))
                            color: Config.baseColor
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height / 2
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
                            height: Math.max(1, Math.min(parent.height, Number(root.values[index] || 0) * parent.height / 100))
                            color: Config.baseColor
                        }
                    }
                }
            }
        }
    }

}
