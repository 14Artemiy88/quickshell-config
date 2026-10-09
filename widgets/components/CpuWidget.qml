import QtQuick
import "." as Widgets
import ".."
import Quickshell
import Quickshell.Io

Widgets.Frame {
    id: root
    moduleName: "cpu"
    width: 315
    height: 215
    property var stats: ({ cpu: [] })
    property real ramValue: 0
    property var colors: [Config.cpu1, Config.cpu2, Config.cpu3, Config.cpu4, Config.cpu5, Config.cpu6, Config.cpu7, Config.cpu8]

    Process {
        id: cpuProc
        command: ["bash", Quickshell.shellDir + "/scripts/cpu_stats_once"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text.trim())
                    if (parsed && parsed.cpu) root.stats = parsed
                } catch (e) {
                    console.warn("cpu_stats:", e, this.text)
                }
                cpuProc.running = false
            }
        }
    }

    Process {
        id: memProc
        command: ["bash", Quickshell.shellDir + "/scripts/mem_stats_once"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = Number(this.text.trim())
                if (isFinite(v))
                    root.ramValue = Math.max(0, Math.min(100, v))
                memProc.running = false
            }
        }
    }

    Timer {
        interval: Config.cpuUpdateInterval
        running: Settings.loaded && Settings.cpu
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cpuProc.running)
                cpuProc.running = true
            if (!memProc.running)
                memProc.running = true
        }
    }

    // Existing compact row layout for left-to-right / right-to-left fills.
    Column {
        visible: Config.cpuBarDirection === "leftToRight" || Config.cpuBarDirection === "rightToLeft"
        anchors.fill: parent
        anchors.margins: 5
        spacing: Config.cpuRowSpacing

        Repeater {
            model: 8
            delegate: MetricBar {
                label: " "
                value: Number(root.stats.cpu && root.stats.cpu.length > index ? root.stats.cpu[index] : 0)
                fillColor: root.colors[index % root.colors.length]
                trackColor: Qt.rgba(
                    Qt.color(root.colors[index % root.colors.length]).r,
                    Qt.color(root.colors[index % root.colors.length]).g,
                    Qt.color(root.colors[index % root.colors.length]).b,
                    0.3
                )
            }
        }

        MetricBar {
            visible: Config.cpuShowRam
            label: " "
            value: root.ramValue
            fillColor: Config.ram
            trackColor: Config.ramTrack
        }
    }

    // Vertical directions show each CPU core and RAM as its own vertical meter.
    // All meters share the available space so the widget remains within its frame.
    Row {
        visible: Config.cpuBarDirection === "topToBottom" || Config.cpuBarDirection === "bottomToTop"
        anchors.fill: parent
        anchors.margins: 5
        spacing: 1

        Repeater {
            model: Config.cpuShowRam ? 9 : 8
            delegate: MetricBar {
                verticalGauge: true
                width: (parent.width - parent.spacing * ((Config.cpuShowRam ? 9 : 8) - 1)) / (Config.cpuShowRam ? 9 : 8)
                height: parent.height
                label: index === 8 ? "" : ""
                value: index === 8 ? root.ramValue : Number(root.stats.cpu && root.stats.cpu.length > index ? root.stats.cpu[index] : 0)
                fillColor: index === 8 ? Config.ram : root.colors[index % root.colors.length]
                trackColor: index === 8 ? Config.ramTrack : Qt.rgba(
                    Qt.color(root.colors[index % root.colors.length]).r,
                    Qt.color(root.colors[index % root.colors.length]).g,
                    Qt.color(root.colors[index % root.colors.length]).b,
                    0.3
                )
            }
        }
    }

}
