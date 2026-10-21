import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
    id: root
    moduleName: "cpu"
    width: 315
    height: 215
    property var stats: ({ cpu: [], ram: 0 })
    property real ramValue: 0
    property var colors: [Config.cpu1, Config.cpu2, Config.cpu3, Config.cpu4, Config.cpu5, Config.cpu6, Config.cpu7, Config.cpu8]

    Process {
        id: cpuProc
        command: [
            "bash",
            Quickshell.shellDir + "/scripts/cpu_stats_once",
            String(Math.max(50, Math.min(250, Math.floor(Number(Config.cpuUpdateInterval || 1000) / 2))))
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text.trim())
                    if (parsed && Array.isArray(parsed.cpu)) {
                        root.stats = parsed
                        var ram = Number(parsed.ram)
                        if (isFinite(ram))
                            root.ramValue = Math.max(0, Math.min(100, ram))
                    }
                } catch (e) {
                    console.warn("cpu_stats:", e, this.text)
                }
                cpuProc.running = false
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
        }
    }

    // Instantiate only the selected orientation. Keeping both layouts under
    // visible:false still created every MetricBar delegate in both Repeaters.
    Loader {
        anchors.fill: parent
        sourceComponent: (Config.cpuBarDirection === "topToBottom" || Config.cpuBarDirection === "bottomToTop")
            ? verticalLayoutComponent
            : horizontalLayoutComponent
    }

    Component {
        id: horizontalLayoutComponent

        // Existing compact row layout for left-to-right / right-to-left fills.
        Column {
            anchors.fill: parent
            anchors.margins: 5
            spacing: Config.cpuRowSpacing

            Repeater {
                model: Config.cpuShowRam ? 9 : 8
                delegate: MetricBar {
                    label: index === 8 ? " " : " "
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

    Component {
        id: verticalLayoutComponent

        // Vertical directions show each CPU core and RAM as its own vertical meter.
        // All meters share available space so the widget remains within its frame.
        Row {
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

}
