import QtQuick
import "primitives" as Primitives
import ".."
import "../js/cava/GraphValuesModel.js" as CavaGraphValuesModel
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
    id: root
    moduleName: "cava"
    width: 300
    height: 80
    // Keep the latest raw snapshot for signal detection, while graph delegates
    // consume one shared ListModel with per-row change notifications.
    property var values: []
    property bool soundActive: true
    readonly property bool graphShouldBeVisible: !Config.cavaHideWhenSilent || root.soundActive
    property real graphVisibilityProgress: graphShouldBeVisible ? 1 : 0

    Behavior on graphVisibilityProgress {
        NumberAnimation {
            duration: Config.animationDurationForProfile(true, Config.animationCavaMorphProfile, Config.animationCavaMorphDuration, "appearance")
            easing.type: Config.animationEasingType(Config.animationCavaMorphProfile, root.graphShouldBeVisible ? "enter" : "exit")
            easing.bezierCurve: Config.animationBezierCurve(Config.animationCavaMorphProfile, root.graphShouldBeVisible ? "enter" : "exit")
        }
    }

    signal playbackToggleRequested()
    signal mopidyToggleRequested()

    // Keep the last visible bars briefly through short gaps in the signal.
    Timer {
        id: silenceTimer
        interval: 450
        repeat: false
        onTriggered: {
            if (Config.cavaHideWhenSilent) root.soundActive = false
        }
    }

    ListModel { id: cavaValuesModel }

    Component.onCompleted: root.syncGraphValues([])

    Process {
        id: cavaProc
        command: [Quickshell.shellDir + "/scripts/cava", String(Config.cavaBars), String(Config.cavaFramerate)]
        running: Settings.loaded && Settings.cava
        stdout: SplitParser {
            onRead: line => {
                try {
                    var sample = JSON.parse(line.trim())
                    var update = root.syncGraphValues(sample)
                    root.values = sample
                    root.updateSignalState(sample, update.peak)
                } catch(e) {}
            }
        }
    }

    // Update a stable model in place. ListModel emits dataChanged only for a
    // row whose value actually changed, so unchanged bars do not re-evaluate
    // their height/visibility bindings on every audio frame. Both mirrored
    // graph regions share this model rather than maintaining duplicate arrays.
    function syncGraphValues(samples) {
        return CavaGraphValuesModel.sync(cavaValuesModel, samples, Config.cavaBars)
    }

    function updateSignalState(samples, knownPeak) {
        if (!Config.cavaHideWhenSilent) {
            silenceTimer.stop()
            soundActive = true
            return
        }

        var peak = typeof knownPeak === "number" && isFinite(knownPeak) ? knownPeak : 0
        if (knownPeak === undefined && samples && samples.length) {
            for (var i = 0; i < samples.length; ++i) {
                var value = Number(samples[i])
                if (isFinite(value) && value > peak) peak = value
            }
        }

        // Ignore tiny noise-floor values; show bars only for a real signal.
        if (peak > 1.0) {
            silenceTimer.stop()
            soundActive = true
        } else if (soundActive && !silenceTimer.running) {
            silenceTimer.start()
        }
    }

    function restartCava() {
        if (!Settings.loaded || !Settings.cava) return
        root.values = []
        root.syncGraphValues([])
        cavaProc.running = false
        Qt.callLater(function() {
            if (Settings.loaded && Settings.cava) cavaProc.running = true
        })
    }

    Connections {
        target: Config
        function onCavaBarsChanged() { root.restartCava() }
        function onCavaFramerateChanged() { root.restartCava() }
        function onCavaHideWhenSilentChanged() { root.updateSignalState(root.values) }
    }

    Primitives.MorphGeometry {
        id: cavaGraphMorph
        fromGeometry: Qt.rect(0, 0, parent.width, parent.height)
        toGeometry: fromGeometry
        progress: root.graphVisibilityProgress
        visible: root.graphShouldBeVisible || normalizedProgress > 0.001

        Item {
            anchors.fill: parent
            opacity: cavaGraphMorph.normalizedProgress
            scale: 0.96 + 0.04 * cavaGraphMorph.normalizedProgress
            transformOrigin: Item.Center

            // Keep graph delegates alive through the complete exit transition,
            // then release them to preserve the silent-state allocation savings.
            Loader {
                anchors.fill: parent
                active: root.graphShouldBeVisible || cavaGraphMorph.normalizedProgress > 0.001
                sourceComponent: Config.cavaMode === "both" ? bothModeComponent
                    : Config.cavaMode === "top" ? topModeComponent
                    : Config.cavaMode === "bottom" ? bottomModeComponent
                    : bothModeComponent
            }
        }
    }

    Component {
        id: bothModeComponent

        // Mirrored mode: preserve the original CAVA layout.
        Item {
            anchors.fill: parent

            Item {
                width: parent.width
                height: parent.height / 2
                Primitives.SegmentBarGraph {
                    anchors.fill: parent
                    valuesModel: cavaValuesModel
                    barCount: Config.cavaBars
                    spacing: Config.cavaRowSpacing
                    barWidthRatio: Config.cavaBarWidthRatio
                    hideZeroBars: Config.cavaHideWhenSilent && Config.cavaHideZeroBars
                    barColor: Config.baseColor
                    direction: "up"
                }
            }

            Item {
                y: parent.height / 2
                width: parent.width
                height: parent.height / 2
                Primitives.SegmentBarGraph {
                    anchors.fill: parent
                    valuesModel: cavaValuesModel
                    barCount: Config.cavaBars
                    spacing: Config.cavaRowSpacing
                    barWidthRatio: Config.cavaBarWidthRatio
                    hideZeroBars: Config.cavaHideWhenSilent && Config.cavaHideZeroBars
                    barColor: Config.baseColor
                    direction: "down"
                }
            }
        }
    }

    Component {
        id: topModeComponent

        // Upper-only mode: bars use full widget height and grow upward.
        Primitives.SegmentBarGraph {
            anchors.fill: parent
            valuesModel: cavaValuesModel
            barCount: Config.cavaBars
            spacing: Config.cavaRowSpacing
            barWidthRatio: Config.cavaBarWidthRatio
            hideZeroBars: Config.cavaHideWhenSilent && Config.cavaHideZeroBars
            barColor: Config.baseColor
            direction: "up"
        }
    }

    Component {
        id: bottomModeComponent

        // Lower-only mode: bars use full widget height and grow downward.
        Primitives.SegmentBarGraph {
            anchors.fill: parent
            valuesModel: cavaValuesModel
            barCount: Config.cavaBars
            spacing: Config.cavaRowSpacing
            barWidthRatio: Config.cavaBarWidthRatio
            hideZeroBars: Config.cavaHideWhenSilent && Config.cavaHideZeroBars
            barColor: Config.baseColor
            direction: "down"
        }
    }

    // Match Player interaction: left-click toggles the active backend,
    // right-click toggles Mopidy when that behavior is enabled.
    MouseArea {
        id: cavaClickArea
        anchors.fill: parent
        z: 1000
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton)
                root.playbackToggleRequested()
            else if (mouse.button === Qt.RightButton)
                root.mopidyToggleRequested()
        }
    }

}
