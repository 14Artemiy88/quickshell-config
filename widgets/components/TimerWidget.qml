import QtQuick
import ".."
import Quickshell
import Quickshell.Io

Frame {
    id: root
    width: 315
    height: 145
    property var timers: []
    property bool showButtons: false
    property string selectedFile: ""
    readonly property int selectedIndex: {
        if (!selectedFile) return -1
        for (let i = 0; i < timerModel.count; ++i) {
            if (timerModel.get(i).file === selectedFile) return i
        }
        return -1
    }
    readonly property int visibleTimerCount: Math.min((timers || []).length, 5)
    readonly property int timerRowHeight: visibleTimerCount >= 5 ? 26 : 30
    // The timer module Height setting is the minimum height. It is not a cap;
    // the block grows automatically when more timers need to be displayed.
    readonly property int configuredMinHeight: {
        const h = Number(Settings.geometry.timer && Settings.geometry.timer[3])
        return isFinite(h) && h > 0 ? Math.round(h) : Config.timerMinHeight
    }
    readonly property int adaptiveHeight: Math.max(
        configuredMinHeight,
        14 + visibleTimerCount * timerRowHeight
    )

    ListModel {
        id: timerModel
    }

    function syncTimerModel(items) {
        const visible = (items || []).slice(0, 5)

        // Remove timers that disappeared.
        for (let i = timerModel.count - 1; i >= 0; --i) {
            let exists = false
            for (let j = 0; j < visible.length; ++j) {
                if (timerModel.get(i).file === visible[j].file) { exists = true; break }
            }
            if (!exists) timerModel.remove(i)
        }

        // Update existing delegates in place and append new timers. This keeps
        // the + outline stable instead of recreating the delegate every second.
        for (let j = 0; j < visible.length; ++j) {
            const item = visible[j]
            let found = -1
            for (let i = 0; i < timerModel.count; ++i) {
                if (timerModel.get(i).file === item.file) { found = i; break }
            }
            if (found < 0) timerModel.append(item)
            else {
                const current = timerModel.get(found)
                for (const key of ["file", "comment", "timer", "color", "sign", "time_passed"]) {
                    if (current[key] !== item[key]) timerModel.setProperty(found, key, item[key])
                }
            }
        }

        // Keep server order. Reorder only when the file sequence actually changed.
        for (let target = 0; target < visible.length; ++target) {
            if (timerModel.get(target).file === visible[target].file) continue
            let source = -1
            for (let i = target + 1; i < timerModel.count; ++i) {
                if (timerModel.get(i).file === visible[target].file) { source = i; break }
            }
            if (source >= 0) timerModel.move(source, target, 1)
        }
    }

    Process {
        id: daemon
        command: [Quickshell.shellDir + "/scripts/timer"]
        running: Settings.loaded && Settings.timer
        stdout: SplitParser { onRead: line => {
            try {
                const items = JSON.parse(line.trim())
                root.timers = items
                root.syncTimerModel(items)
            } catch (e) {}
        } }
    }

    Item {
        id: setButtons
        // Presets stay at the left; the active
        // timer values remain anchored to the right side independently.
        x: 0
        y: 0
        width: Math.min(parent.width - 100, Math.max(125, 16 + Settings.timerPresets.length * 33 + Math.max(0, Settings.timerPresets.length - 1) * 7))
        height: parent.height
        clip: true
        z: 20

        HoverHandler {
            onHoveredChanged: root.showButtons = hovered
        }

        Text {
            x: 10
            width: 30
            height: 33
            anchors.verticalCenter: parent.verticalCenter
            text: "󰁫"
            color: Config.text
            font.pixelSize: 27
            opacity: root.showButtons ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.timerButtonIconFadeDuration); easing.type: Easing.InOutCubic } }
        }

        Flickable {
            x: 8
            width: parent.width - 16
            height: parent.height
            contentWidth: Math.max(width, 8 + Settings.timerPresets.length * 33 + Math.max(0, Settings.timerPresets.length - 1) * 7)
            contentHeight: parent.height
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            opacity: root.showButtons ? 1 : 0
            transform: Translate {
                id: buttonSlide
                x: root.showButtons ? 0 : -18
                Behavior on x { NumberAnimation { duration: Config.animationDuration(Config.timerButtonSlideDuration); easing.type: Easing.InOutCubic } }
            }
            Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.timerButtonFadeDuration); easing.type: Easing.InOutCubic } }

            Row {
                spacing: 7
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: Settings.timerPresets
                    delegate: Rectangle {
                        width: 33
                        height: 33
                        radius: 7
                        color: Config.background
                        border.color: Config.baseColor
                        border.width: 1
                        Text { anchors.centerIn: parent; text: modelData; color: Config.textDim }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    Settings.resetTimerPreset(index)
                                    return
                                }
                                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "add", String(modelData)])
                            }
                            onWheel: wheel => {
                                const direction = wheel.angleDelta.y > 0 ? 1 : -1
                                const multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
                                Settings.adjustTimerPreset(index, direction * Config.timerWheelStep * multiplier)
                                wheel.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: timerList
        x: 0
        y: 0
        width: parent.width
        height: parent.height
        clip: true

        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Config.timerRowTopMargin
            anchors.rightMargin: Config.timerRowRightMargin
            width: parent.width - anchors.leftMargin - anchors.rightMargin
            spacing: 0

            Repeater {
                model: timerModel
                delegate: Item {
                    width: parent.width
                    height: root.timerRowHeight

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Config.timerCommentGap
                        height: parent.height

                        Text {
                            // Keep the original timer value/comment directly next
                            // to the live countdown. Limit it to 10 characters so
                            // long timers can never collide with the countdown.
                            width: Config.timerCommentWidth
                            height: parent.height
                            text: String(model.comment || "").slice(0, Config.timerCommentMaxLength)
                            color: model.color || Config.text
                            font.family: "Pixel LCD7"
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            width: 100
                            height: parent.height
                            text: (model.sign || "") + (model.timer || "")
                            color: (model.sign || "") !== "" ? Config.black : (model.color || Config.text)
                            style: (model.sign || "") !== "" ? Text.Outline : Text.Normal
                            styleColor: model.color || Config.text
                            font.family: Config.ledFont
                            font.pixelSize: root.timers.length >= 5 ? 25 : (root.timers.length >= 4 ? 30 : 35)
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        hoverEnabled: false
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                root.selectedFile = root.selectedFile === model.file ? "" : model.file
                            } else if (mouse.button === Qt.MiddleButton) {
                                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "delete", model.file])
                                if (root.selectedFile === model.file) root.selectedFile = ""
                            } else if (mouse.button === Qt.RightButton) {
                                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "update_color", model.file])
                            }
                        }
                        onWheel: wheel => Quickshell.execDetached([
                            Quickshell.shellDir + "/scripts/timer",
                            wheel.angleDelta.y > 0 ? "up" : "down", model.file
                        ])
                    }
                }
            }
        }
    }

}
