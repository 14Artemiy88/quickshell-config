import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
    id: root
    moduleName: "cpu"
    width: 315
    height: compactPresentation ? 190 : widePresentation ? 225 : 215
    property var stats: ({ cpu: [], ram: 0 })
    property real ramValue: 0
    property var colors: [Config.cpu1, Config.cpu2, Config.cpu3, Config.cpu4, Config.cpu5, Config.cpu6, Config.cpu7, Config.cpu8]
    property var trackColors: [Config.cpu1Track, Config.cpu2Track, Config.cpu3Track, Config.cpu4Track, Config.cpu5Track, Config.cpu6Track, Config.cpu7Track, Config.cpu8Track]
    readonly property real cpuPresentationScale: compactPresentation ? 0.9 : widePresentation ? 1.05 : 1
    readonly property int effectiveCpuRowHeight: compactPresentation ? Math.max(14, Math.round(Config.cpuRowHeight * cpuPresentationScale)) : widePresentation ? Math.round(Config.cpuRowHeight * cpuPresentationScale) : Config.cpuRowHeight
    readonly property int effectiveCpuLabelFontSize: compactPresentation ? 11 : 12
    readonly property int effectiveCpuHorizontalMargin: compactPresentation ? 7 : 5
    readonly property int effectiveCpuBarRightSafety: compactPresentation ? 8 : 5
    readonly property int effectiveCpuBarOffset: compactPresentation
        ? Math.min(Config.cpuBarLeftOffset, Math.max(24, Math.round(widthBudget * 0.13)))
        : Config.cpuBarLeftOffset
    readonly property int effectiveCpuBarWidth: compactPresentation
        ? Math.max(1, Math.min(Config.cpuBarWidth, Math.floor(
            widthBudget - 2 * effectiveCpuHorizontalMargin - effectiveCpuBarOffset - effectiveCpuBarRightSafety)))
        : widePresentation
            ? Math.max(Config.cpuBarWidth, Math.floor(widthBudget - 10 - effectiveCpuBarOffset - 5))
            : Config.cpuBarWidth
    readonly property int effectiveCpuLabelPadding: compactPresentation ? Math.min(Config.cpuLabelLeftPadding, 7) : Config.cpuLabelLeftPadding
    // CPU core bars use the shared module animation profile. RAM stays immediate,
    // and the independent module entrance/exit animation is not affected.
    readonly property int cpuBarAdaptiveDuration: Math.max(
        80, Math.min(260, Math.round(Number(Config.cpuUpdateInterval || 1000) * 0.25)))
    readonly property int cpuBarAnimationDuration: Config.animationDurationForProfile(
        true, Config.animationCpuMorphProfile,
        Math.min(cpuBarAdaptiveDuration, Number(Config.animationCpuMorphDuration) || 0), "appearance")

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
            anchors.margins: root.effectiveCpuHorizontalMargin
            spacing: Config.cpuRowSpacing
            clip: true

            Repeater {
                model: Config.cpuShowRam ? 9 : 8
                delegate: MetricBar {
                    label: index === 8 ? " " : " "
                    value: index === 8 ? root.ramValue : Number(root.stats.cpu && root.stats.cpu.length > index ? root.stats.cpu[index] : 0)
                    valueAnimationDuration: index === 8 ? 0 : root.cpuBarAnimationDuration
                    valueAnimationProfile: Config.animationCpuMorphProfile
                    fillColor: index === 8 ? Config.ram : root.colors[index % root.colors.length]
                    trackColor: index === 8 ? Config.ramTrack : root.trackColors[index % root.trackColors.length]
                    rowHeight: root.effectiveCpuRowHeight
                    labelFontSize: root.effectiveCpuLabelFontSize
                    barOffset: root.effectiveCpuBarOffset
                    barWidth: root.effectiveCpuBarWidth
                    labelPadding: root.effectiveCpuLabelPadding
                    fillAvailableWidth: true
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
                    valueAnimationDuration: index === 8 ? 0 : root.cpuBarAnimationDuration
                    valueAnimationProfile: Config.animationCpuMorphProfile
                    fillColor: index === 8 ? Config.ram : root.colors[index % root.colors.length]
                    trackColor: index === 8 ? Config.ramTrack : root.trackColors[index % root.trackColors.length]
                    rowHeight: root.effectiveCpuRowHeight
                    labelFontSize: root.effectiveCpuLabelFontSize
                    barOffset: root.effectiveCpuBarOffset
                    barWidth: root.effectiveCpuBarWidth
                    labelPadding: root.effectiveCpuLabelPadding
                    fillAvailableWidth: true
                }
            }
        }
    }

}
