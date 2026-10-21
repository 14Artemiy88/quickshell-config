import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
    id: root
    moduleName: "cava"
    width: 300
    height: 80
    property var values: []
    property bool soundActive: true

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

    Process {
        id: cavaProc
        command: [Quickshell.shellDir + "/scripts/cava", String(Config.cavaBars), String(Config.cavaFramerate)]
        running: Settings.loaded && Settings.cava
        stdout: SplitParser {
            onRead: line => {
                try {
                    var sample = JSON.parse(line.trim())
                    root.values = sample
                    root.updateSignalState(sample)
                } catch(e) {}
            }
        }
    }

    function updateSignalState(samples) {
        if (!Config.cavaHideWhenSilent) {
            silenceTimer.stop()
            soundActive = true
            return
        }

        var peak = 0
        if (samples && samples.length) {
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

    Item {
        anchors.fill: parent
        visible: !Config.cavaHideWhenSilent || root.soundActive

        // Only the active mode is instantiated. With the previous visibility
        // toggles, hidden mode trees still allocated every bar delegate.
        Loader {
            anchors.fill: parent
            // Release all bar delegates after the silence grace period. The
            // process/filter keep streaming, so the selected graph is recreated
            // with the current sample as soon as sound resumes.
            active: !Config.cavaHideWhenSilent || root.soundActive
            sourceComponent: Config.cavaMode === "both" ? bothModeComponent
                : Config.cavaMode === "top" ? topModeComponent
                : Config.cavaMode === "bottom" ? bottomModeComponent
                : bothModeComponent
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
                    values: root.values
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
                    values: root.values
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
            values: root.values
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
            values: root.values
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
