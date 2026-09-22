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
    property real mainDisplayedValue: Number(root.monitor?.data?.current_volume ?? 0)
    property real mainDragValue: mainDisplayedValue
    property bool mainDragging: false
    property bool mainHasPending: false
    property real mainPendingValue: mainDisplayedValue
    property double mainPendingUntil: 0
    readonly property int streamCount: streamRepeater.count
    // Exact vertical footprint of the content: 12px top + 12px bottom,
    // 32px main row, 7px gaps, and 35px per additional stream row.
    readonly property int adaptiveHeight: Math.max(
        Config.volumeMinHeight,
        56 + streamCount * 42
    )

    function acceptBackendVolume(v) {
        if (!isFinite(v)) return
        mainBackendValue = clampVolume(v)
        if (mainDragging) return
        if (mainHasPending) {
            if (Math.abs(mainBackendValue - mainPendingValue) <= 0.5 || Date.now() >= mainPendingUntil)
                mainHasPending = false
            else
                return
        }
        mainDisplayedValue = mainBackendValue
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
                root.acceptBackendVolume(Number(this.text.trim()))
                volumePoll.running = false
            }
        }
    }

    Timer {
        interval: 200
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
            root.acceptBackendVolume(Number(root.monitor?.data?.current_volume ?? NaN))
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        Row {
            width: parent.width
            height: 32

            Text {
                id: mainVolumeIcon
                width: 25
                text: root.mainDragging ? (root.mainDragValue > 0 ? "󰕾" : "󰖁") : (root.mainDisplayedValue > 0 ? "󰕾" : "󰖁")
                color: Config.text
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/toggle_mute"])
                }
            }

            Item {
                id: mainTrack
                width: 220
                height: 32
                property real shownValue: root.mainDragging ? root.mainDragValue : root.mainDisplayedValue

                Rectangle {
                    id: mainBackground
                    x: 0
                    y: (parent.height - 8) / 2 - 3
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Config.volumeTrack

                    Rectangle {
                        width: parent.width * root.clampVolume(parent.parent.shownValue) / 100
                        height: parent.height
                        radius: 4
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
            model: root.monitor?.data?.volumes ?? []

            delegate: Column {
                id: streamColumn
                width: parent.width
                spacing: 1
                property real backendValue: Number(modelData.value ?? 0)
                property real dragValue: backendValue
                property bool dragging: false

                Text {
                    text: modelData.name
                    color: Config.text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: parent.width
                }

                Item {
                    id: streamTrack
                    width: parent.width
                    height: 20

                    Rectangle {
                        x: 0
                        y: (parent.height - 8) / 2
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Config.volumeTrack

                        Rectangle {
                            width: parent.width * root.clampVolume(streamColumn.dragging ? streamColumn.dragValue : streamColumn.backendValue) / 100
                            height: parent.height
                            radius: 4
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
