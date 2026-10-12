import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
    id: root
    moduleName: "volumes"
    width: 275
    height: 210
    property var monitor
    property real mainBackendValue: 0
    property bool mainMuted: Boolean(root.monitor?.data?.current_muted ?? false)
    property bool mainBackendMuted: mainMuted
    property real mainDisplayedValue: Number(root.monitor?.data?.current_volume ?? 0)
    property real mainDragValue: mainDisplayedValue
    property bool mainDragging: false
    property bool mainHasPending: false
    property real mainPendingValue: mainDisplayedValue
    property double mainPendingUntil: 0
    // Keep the requested mute state visible until the backend confirms it.
    // Poll responses can race the async command and briefly report the old state.
    property bool mainMuteHasPending: false
    property bool mainPendingMuted: false
    property double mainMutePendingUntil: 0
    property bool mainMuteRefreshPending: false
    readonly property int streamCount: streamRepeater.count
    readonly property int effectiveStreamCount: Config.volumeShowStreams ? streamCount : 0
    readonly property int effectiveStreamRowHeight: Math.max(Config.volumeStreamRowHeight, Config.volumeStreamTrackHeight)
    // When extra streams are hidden, the widget must collapse to the main row
    // instead of retaining the minimum height/Column spacing reserved for them.
    readonly property int mainContentHeight: 2 * Config.volumeVerticalPadding + Config.volumeMainRowHeight
    readonly property int adaptiveHeight: Config.volumeShowStreams
        ? Math.min(
            Config.volumeMaxHeight,
            Math.max(
                Config.volumeMinHeight,
                mainContentHeight + effectiveStreamCount * (20 + effectiveStreamRowHeight + Config.volumeStreamSpacing)
            )
        )
        : Math.min(Config.volumeMaxHeight, mainContentHeight)
    implicitHeight: adaptiveHeight

    function acceptBackendVolume(v, muted) {
        if (!isFinite(v)) return
        mainBackendValue = clampVolume(v)
        const hasMuteState = muted !== undefined && isFinite(Number(muted))
        if (hasMuteState)
            mainBackendMuted = Number(muted) !== 0
        if (mainDragging) return
        if (mainHasPending) {
            if (Math.abs(mainBackendValue - mainPendingValue) <= 0.5 || Date.now() >= mainPendingUntil)
                mainHasPending = false
            else
                return
        }
        mainDisplayedValue = mainBackendValue
        if (mainMuteHasPending) {
            if (hasMuteState && mainBackendMuted === mainPendingMuted) {
                mainMuteHasPending = false
            } else if (Date.now() < mainMutePendingUntil) {
                // Do not let an older poll undo the optimistic icon/track state.
                mainMuted = mainPendingMuted
                return
            } else {
                // Stop masking the backend if the requested state never arrived.
                mainMuteHasPending = false
            }
        }
        mainMuted = mainBackendMuted
    }

    function clampVolume(v) { return Math.max(0, Math.min(100, Number(v) || 0)) }
    function setMainFromX(x) {
        const next = clampVolume((x / mainTrack.width) * 100)
        mainDragValue = next
        return next
    }
    function expectMainMuteState(muted) {
        mainMuteHasPending = true
        mainPendingMuted = Boolean(muted)
        mainMutePendingUntil = Date.now() + 1800
        mainMuted = mainPendingMuted
    }

    function applyMainVolume(v, unmuteIfMuted = false) {
        const next = Math.round(clampVolume(v))
        const shouldUnmute = unmuteIfMuted && (mainMuted || mainBackendMuted)
        mainDragValue = next
        mainDisplayedValue = next
        mainPendingValue = next
        mainHasPending = true
        mainPendingUntil = Date.now() + 700
        if (shouldUnmute) {
            // Optimistically reveal the chosen level, while ignoring stale mute
            // state from a poll that races the set-volume + unmute command.
            expectMainMuteState(false)
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/set_volume", "main", String(next), "unmute"])
            volumeMuteRefreshTimer.restart()
        } else {
            Quickshell.execDetached([Quickshell.shellDir + "/scripts/set_volume", "main", String(next)])
        }
    }
    function applyStreamVolume(id, v) {
        const next = Math.round(clampVolume(v))
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/set_volume", "stream", String(next), String(id)])
    }

    Process {
        id: volumePoll
        command: ["bash", Quickshell.shellDir + "/scripts/get_volume"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/)
                root.acceptBackendVolume(Number(parts[0]), parts.length > 1 ? Number(parts[1]) : undefined)
                volumePoll.running = false
                if (root.mainMuteRefreshPending && Settings.volumes) {
                    root.mainMuteRefreshPending = false
                    volumeMuteRefreshTimer.restart()
                }
            }
        }
    }

    // Delay the confirmation poll until the explicit mute command has had a
    // chance to reach the audio server. If another poll is still in flight,
    // schedule one more after it completes rather than restarting it instantly.
    Timer {
        id: volumeMuteRefreshTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!Settings.volumes) return
            if (volumePoll.running)
                root.mainMuteRefreshPending = true
            else
                volumePoll.running = true
        }
    }

    Timer {
        interval: Config.volumeUpdateInterval
        running: Settings.loaded && Settings.volumes
        repeat: true
        triggeredOnStart: true
        onTriggered: if (Settings.volumes && !volumePoll.running) volumePoll.running = true
    }

    Connections {
        target: Settings
        function onVolumesChanged() {
            if (Settings.volumes && !volumePoll.running) volumePoll.running = true
            else if (!Settings.volumes && volumePoll.running) volumePoll.running = false
        }
        function onLoadedChanged() {
            if (Settings.loaded && Settings.volumes && !volumePoll.running) volumePoll.running = true
        }
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: Config.volumeHorizontalPadding
        anchors.rightMargin: Config.volumeHorizontalPadding
        anchors.topMargin: Config.volumeVerticalPadding
        anchors.bottomMargin: Config.volumeVerticalPadding
        spacing: Config.volumeShowStreams ? 7 : 0

        Row {
            width: parent.width
            height: Config.volumeMainRowHeight

            Primitives.HoverButtonSurface {
                id: mainVolumeIcon
                width: Config.volumeMainIconWidth
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const currentTarget = root.mainMuteHasPending ? root.mainPendingMuted : root.mainMuted
                    const nextMuted = !currentTarget
                    root.expectMainMuteState(nextMuted)
                    Quickshell.execDetached([Quickshell.shellDir + "/scripts/set_mute", nextMuted ? "1" : "0"])
                    volumeMuteRefreshTimer.restart()
                }

                Text {
                    anchors.fill: parent
                    text: root.mainDragging ? ((root.mainMuted || root.mainDragValue <= 0) ? Config.volumeMutedIcon : Config.volumeIcon) : ((root.mainMuted || root.mainDisplayedValue <= 0) ? Config.volumeMutedIcon : Config.volumeIcon)
                    color: Config.text
                    font.pixelSize: Config.uiFontSize(16)
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                id: mainTrack
                width: Config.volumeMainTrackWidth
                height: 32
                property real shownValue: root.mainDragging ? root.mainDragValue : root.mainDisplayedValue

                Primitives.ProgressTrack {
                    id: mainProgressTrack
                    x: 0
                    y: (parent.height - Config.volumeMainTrackHeight) / 2 + Config.volumeMainTrackOffsetY
                    width: parent.width
                    height: Config.volumeMainTrackHeight
                    radius: Config.volumeTrackRadius
                    value: root.mainMuted && !root.mainDragging ? 0 : root.clampVolume(mainTrack.shownValue)
                    fillColor: Config.volumeFill
                    trackColor: Config.volumeTrack
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => {
                        root.mainDragging = true
                        root.setMainFromX(mouse.x)
                    }
                    onPositionChanged: mouse => {
                        if (pressed) root.setMainFromX(mouse.x)
                    }
                    onReleased: {
                        root.mainDragging = false
                        root.applyMainVolume(root.mainDragValue, true)
                    }
                    onWheel: wheel => {
                        const step = wheel.angleDelta.y > 0 ? 1 : -1
                        const next = root.clampVolume((root.mainDragging ? root.mainDragValue : root.mainDisplayedValue) + step)
                        root.mainDragging = false
                        root.applyMainVolume(next, true)
                    }
                }
            }
        }

        Repeater {
            id: streamRepeater
            model: root.monitor?.data?.volumes ?? []

            delegate: Column {
                id: streamColumn
                visible: Config.volumeShowStreams
                height: visible ? implicitHeight : 0
                width: parent.width
                spacing: Config.volumeStreamSpacing
                property real backendValue: Number(modelData.value ?? 0)
                property real dragValue: backendValue
                property bool dragging: false

                Text {
                    text: modelData.name
                    color: Config.text
                    font.pixelSize: Config.uiFontSize(Config.volumeStreamLabelFontSize)
                    elide: Text.ElideRight
                    width: parent.width
                }

                Item {
                    id: streamTrack
                    width: parent.width
                    height: root.effectiveStreamRowHeight

                    Primitives.ProgressTrack {
                        x: 0
                        y: Math.max(0, (parent.height - Config.volumeStreamTrackHeight) / 2 + Config.volumeStreamTrackOffsetY)
                        width: parent.width
                        height: Config.volumeStreamTrackHeight
                        radius: Config.volumeTrackRadius
                        value: root.clampVolume(streamColumn.dragging ? streamColumn.dragValue : streamColumn.backendValue)
                        fillColor: Config.volumeFill
                        trackColor: Config.volumeTrack
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => {
                            streamColumn.dragging = true
                            streamColumn.dragValue = root.clampVolume((mouse.x / streamTrack.width) * 100)
                        }
                        onPositionChanged: mouse => {
                            if (pressed) streamColumn.dragValue = root.clampVolume((mouse.x / streamTrack.width) * 100)
                        }
                        onReleased: {
                            streamColumn.dragging = false
                            root.applyStreamVolume(modelData.num, streamColumn.dragValue)
                        }
                        onWheel: wheel => {
                            const current = streamColumn.dragging ? streamColumn.dragValue : streamColumn.backendValue
                            const next = root.clampVolume(current + (wheel.angleDelta.y > 0 ? 1 : -1))
                            streamColumn.dragging = false
                            streamColumn.dragValue = next
                            root.applyStreamVolume(modelData.num, next)
                        }
                    }
                }
            }
        }
    }

}
