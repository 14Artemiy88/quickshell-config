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

        // Mirrored mode: preserve the original CAVA layout.
        Item {
            visible: Config.cavaMode === "both"
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
                    barColor: Config.baseColor
                    direction: "down"
                }
            }
        }

        // Upper-only mode: bars use the full widget height and grow upward from the bottom edge.
        Item {
            visible: Config.cavaMode === "top"
            anchors.fill: parent

            Primitives.SegmentBarGraph {
                anchors.fill: parent
                values: root.values
                barCount: Config.cavaBars
                spacing: Config.cavaRowSpacing
                barWidthRatio: Config.cavaBarWidthRatio
                barColor: Config.baseColor
                direction: "up"
            }
        }

        // Lower-only mode: bars use the full widget height and grow downward from the top edge.
        Item {
            visible: Config.cavaMode === "bottom"
            anchors.fill: parent

            Primitives.SegmentBarGraph {
                anchors.fill: parent
                values: root.values
                barCount: Config.cavaBars
                spacing: Config.cavaRowSpacing
                barWidthRatio: Config.cavaBarWidthRatio
                barColor: Config.baseColor
                direction: "down"
            }
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
