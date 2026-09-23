import QtQuick
import ".."
import Quickshell
import Quickshell.Io

Frame {
    id: root
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
    readonly property int streamCount: streamRepeater.count
    readonly property int effectiveStreamCount: Config.volumeShowStreams ? streamCount : 0
    readonly property int effectiveStreamRowHeight: Math.max(Config.volumeStreamRowHeight, Config.volumeStreamTrackHeight)
    // Exact vertical footprint of the content: configurable top/bottom padding,
    // configurable main row, and one label + one track row per extra stream.
    readonly property int adaptiveHeight: Math.min(
        Config.volumeMaxHeight,
        Math.max(
            Config.volumeMinHeight,
            2 * Config.volumeVerticalPadding + Config.volumeMainRowHeight + effectiveStreamCount * (20 + effectiveStreamRowHeight + Config.volumeStreamSpacing)
        )
    )

    function acceptBackendVolume(v, muted) {
        if (!isFinite(v)) return
        mainBackendValue = clampVolume(v)
        if (muted !== undefined && isFinite(Number(muted)))
            mainBackendMuted = Number(muted) !== 0
        if (mainDragging) return
        if (mainHasPending) {
            if (Math.abs(mainBackendValue - mainPendingValue) <= 0.5 || Date.now() >= mainPendingUntil)
                mainHasPending = false
            else
                return
        }
        mainDisplayedValue = mainBackendValue
        mainMuted = mainBackendMuted
    }

    function clampVolume(v) { return Math.max(0, Math.min(100, Number(v) || 0)) }
    function setMainFromX(x) {
        const next = clampVolume((x / mainTrack.width) * 100)
        mainDragValue = next
        return next
    }
    function applyMainVolume(v) {
        const next = Math.round(clampVolume(v))
        mainDragValue = next
        mainDisplayedValue = next
        mainPendingValue = next
        mainHasPending = true
        mainPendingUntil = Date.now() + 700
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/set_volume", "main", String(next)])
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
            }
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

    Connections {
        target: root.monitor
        function onDataChanged() {
            root.acceptBackendVolume(
                Number(root.monitor?.data?.current_volume ?? NaN),
                root.monitor?.data?.current_muted ?? undefined
            )
        }
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: Config.volumeHorizontalPadding
        anchors.rightMargin: Config.volumeHorizontalPadding
        anchors.topMargin: Config.volumeVerticalPadding
        anchors.bottomMargin: Config.volumeVerticalPadding
        spacing: 7

        Row {
            width: parent.width
            height: Config.volumeMainRowHeight

            Text {
                id: mainVolumeIcon
                width: Config.volumeMainIconWidth
                text: root.mainDragging ? ((root.mainMuted || root.mainDragValue <= 0) ? "󰖁" : "󰕾") : ((root.mainMuted || root.mainDisplayedValue <= 0) ? "󰖁" : "󰕾")
                color: Config.text
                font.pixelSize: Config.uiFontSize(16)
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached([Quickshell.shellDir + "/scripts/toggle_mute"])
                        root.mainMuted = !root.mainMuted
                        root.mainBackendMuted = root.mainMuted
                        volumePoll.running = false
                        volumePoll.running = true
                    }
                }
            }

            Item {
                id: mainTrack
                width: Config.volumeMainTrackWidth
                height: 32
                property real shownValue: root.mainDragging ? root.mainDragValue : root.mainDisplayedValue

                Rectangle {
                    id: mainBackground
                    x: 0
                    y: (parent.height - Config.volumeMainTrackHeight) / 2 + Config.volumeMainTrackOffsetY
                    width: parent.width
                    height: Config.volumeMainTrackHeight
                    radius: Config.volumeTrackRadius
                    color: Config.volumeTrack

                    Rectangle {
                        width: parent.width * root.clampVolume(parent.parent.shownValue) / 100
                        height: parent.height
                        radius: Config.volumeTrackRadius
                        color: Config.volumeFill
                    }
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
                        root.applyMainVolume(root.mainDragValue)
                    }
                    onWheel: wheel => {
                        const step = wheel.angleDelta.y > 0 ? 1 : -1
                        const next = root.clampVolume((root.mainDragging ? root.mainDragValue : root.mainDisplayedValue) + step)
                        root.mainDragging = false
                        root.applyMainVolume(next)
                    }
                }
            }
        }

        Repeater {
            id: streamRepeater
            visible: Config.volumeShowStreams
            model: root.monitor?.data?.volumes ?? []

            delegate: Column {
                id: streamColumn
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

                    Rectangle {
                        x: 0
                        y: Math.max(0, (parent.height - Config.volumeStreamTrackHeight) / 2 + Config.volumeStreamTrackOffsetY)
                        width: parent.width
                        height: Config.volumeStreamTrackHeight
                        radius: Config.volumeTrackRadius
                        color: Config.volumeTrack

                        Rectangle {
                            width: parent.width * root.clampVolume(streamColumn.dragging ? streamColumn.dragValue : streamColumn.backendValue) / 100
                            height: parent.height
                            radius: Config.volumeTrackRadius
                            color: Config.volumeFill
                        }
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

    Rectangle {
        anchors.fill: parent
        color: Config.transparent
        border.color: Config.baseColor
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius
        z: 100
    }
}
