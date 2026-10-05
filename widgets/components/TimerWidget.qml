import QtQuick
import QtQuick.Controls
import "." as Widgets
import ".."
import Quickshell
import Quickshell.Io

Widgets.Frame {
    id: root
    moduleName: "timer"
    width: 315
    height: 145
    property var timers: []
    property int controlsMode: 0 // 0 = icons, 1 = timer presets, 2 = alarm presets
    property string selectedFile: ""
    property var dingState: ({})
    signal timerFinished(string file, string comment, string color)
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
        14 + visibleTimerCount * timerRowHeight + Math.max(0, visibleTimerCount - 1) * Config.timerRowSpacing
    )

    // Alarm target is kept at minute precision. It starts at the current
    // minute and can be shifted with the mouse wheel before creating the timer.
    property date alarmTarget: new Date()
    property bool alarmTargetAdjusted: false
    property bool timerIconHovered: false
    property bool alarmIconHovered: false
    property bool timerButtonsHovered: false
    property bool alarmButtonsHovered: false
    function updateControlsMode() {
        // The two icon hitboxes are deliberately tiny and mutually exclusive.
        // Buttons stay active while the pointer is over their own row.
        if (alarmButtonsHovered || alarmIconHovered) controlsMode = 2
        else if (timerButtonsHovered || timerIconHovered) controlsMode = 1
        else controlsMode = 0
    }
    property string alarmTargetText: {
        const h = alarmTarget.getHours().toString().padStart(2, "0")
        const m = alarmTarget.getMinutes().toString().padStart(2, "0")
        return h + ":" + m
    }

    function syncAlarmTargetClock() {
        if (!Settings.loaded || !Settings.timer || root.alarmTargetAdjusted) {
            alarmTargetSyncTimer.stop()
            return
        }

        // The displayed alarm target has minute precision, so waking every
        // second is unnecessary. Align the next update to the next minute.
        const now = new Date()
        root.alarmTarget = now
        const msToNextMinute = Math.max(50,
            60000 - now.getSeconds() * 1000 - now.getMilliseconds())
        alarmTargetSyncTimer.interval = msToNextMinute
        alarmTargetSyncTimer.restart()
    }

    Timer {
        id: alarmTargetSyncTimer
        interval: 60000
        running: false
        repeat: false
        onTriggered: root.syncAlarmTargetClock()
    }

    onAlarmTargetAdjustedChanged: {
        if (root.alarmTargetAdjusted)
            alarmTargetSyncTimer.stop()
        else
            root.syncAlarmTargetClock()
    }

    Connections {
        target: Settings
        function onLoadedChanged() {
            if (Settings.loaded)
                root.syncAlarmTargetClock()
            else
                alarmTargetSyncTimer.stop()
        }
        function onTimerChanged() {
            if (Settings.timer)
                root.syncAlarmTargetClock()
            else
                alarmTargetSyncTimer.stop()
        }
    }

    ListModel {
        id: timerModel
    }

    function commentForFile(file) {
        for (let i = 0; i < timerModel.count; ++i) {
            if (timerModel.get(i).file === file)
                return String(timerModel.get(i).comment || "")
        }
        return ""
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
                for (const key of ["file", "comment", "timer", "color", "sign", "time_passed", "ding"]) {
                    if (current[key] !== item[key]) timerModel.setProperty(found, key, item[key])
                }
            }

            // The daemon marks a timer as dinged exactly once. Suppress a
            // notification for timers that were already finished when the
            // widget was started, but notify on a live transition to ding=1.
            const isDing = !!item.ding
            const wasKnown = Object.prototype.hasOwnProperty.call(root.dingState, item.file)
            const wasDing = wasKnown ? !!root.dingState[item.file] : false
            if (isDing && wasKnown && !wasDing) {
                root.timerFinished(item.file, String(item.comment || ""), String(item.color || Config.text))
            }
            root.dingState[item.file] = isDing
        }

        // Drop notification state for timers that no longer exist.
        for (const file in root.dingState) {
            let exists = false
            for (let j = 0; j < visible.length; ++j) {
                if (visible[j].file === file) { exists = true; break }
            }
            if (!exists) delete root.dingState[file]
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
        x: 0
        y: 0
        width: parent.width
        height: parent.height
        clip: true
        z: 20

        // One permanent hover/click area for both icons. The previous versions
        // used two independent MouseAreas/handlers; when the controls replaced
        // the icons, their hover state could conflict and the alarm zone would
        // fall back to timer controls. Here the pointer is classified by X,
        // with the alarm zone taking precedence when the two settings overlap.
        MouseArea {
            id: iconInteraction
            z: 5
            property int minX: Math.min(Config.timerIconX, Config.timerAlarmIconX)
            property int maxX: Math.max(Config.timerIconX + 30, Config.timerAlarmIconX + 30)
            x: minX
            y: (parent.height - height) / 2 + Math.min(Config.timerIconY, Config.timerAlarmIconY)
            width: Math.max(30, maxX - minX)
            height: 33 + Math.abs(Config.timerIconY - Config.timerAlarmIconY)
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            property int hoverZone: 0 // 0 = none, 1 = timer, 2 = alarm

            function zoneAt(localX, localY) {
                const timerStartX = Config.timerIconX - minX
                const alarmStartX = Config.timerAlarmIconX - minX
                const timerStartY = Config.timerIconY - Math.min(Config.timerIconY, Config.timerAlarmIconY)
                const alarmStartY = Config.timerAlarmIconY - Math.min(Config.timerIconY, Config.timerAlarmIconY)
                const inTimer = localX >= timerStartX && localX < timerStartX + 30
                    && localY >= timerStartY && localY < timerStartY + 33
                const inAlarm = localX >= alarmStartX && localX < alarmStartX + 30
                    && localY >= alarmStartY && localY < alarmStartY + 33
                if (inAlarm) return 2
                if (inTimer) return 1
                return 0
            }

            function updateZone(localX, localY) {
                const zone = zoneAt(localX, localY)
                if (zone === hoverZone) return
                hoverZone = zone
                if (zone === 2) root.controlsMode = 2
                else if (zone === 1) root.controlsMode = 1
                else if (root.controlsMode !== 2 && root.controlsMode !== 1) root.controlsMode = 0
            }

            onEntered: updateZone(mouseX, mouseY)
            onPositionChanged: updateZone(mouseX, mouseY)
            onExited: {
                hoverZone = 0
                // Do not immediately hide buttons here: the pointer can move
                // from the icon into the corresponding button row. The row's
                // own HoverHandler will return the controls to icon mode only
                // after the pointer really leaves the controls.
            }

            onClicked: mouse => {
                if (hoverZone !== 2) return
                const now = new Date()
                let target = new Date(root.alarmTarget.getTime())
                target.setSeconds(0, 0)
                if (target.getTime() <= now.getTime())
                    target.setDate(target.getDate() + 1)
                const hh = target.getHours().toString().padStart(2, "0")
                const mm = target.getMinutes().toString().padStart(2, "0")
                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "add_at", hh + ":" + mm])
                root.alarmTargetAdjusted = false
                root.alarmTarget = new Date()
            }

            onWheel: wheel => {
                if (hoverZone !== 2) {
                    wheel.accepted = false
                    return
                }
                const direction = wheel.angleDelta.y > 0 ? 1 : -1
                const multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
                const target = new Date(root.alarmTarget.getTime())
                target.setMinutes(target.getMinutes() + direction * multiplier)
                target.setSeconds(0, 0)
                root.alarmTarget = target
                root.alarmTargetAdjusted = true
                wheel.accepted = true
            }
        }

        Text {
            id: timerIcon
            x: Config.timerIconX
            y: (parent.height - height) / 2 + Config.timerIconY
            width: 30
            height: 33
            text: Config.timerIcon
            color: Config.text
            font.pixelSize: Config.timerIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: root.controlsMode === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.timerButtonIconFadeDuration, "appearance"); easing.type: Config.easingType() } }
        }

        Text {
            id: alarmIcon
            x: Config.timerAlarmIconX
            y: (parent.height - height) / 2 + Config.timerAlarmIconY
            width: 30
            height: 33
            text: Config.timerAlarmIcon
            color: Config.text
            font.pixelSize: Config.timerAlarmIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: root.controlsMode === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.timerButtonIconFadeDuration, "appearance"); easing.type: Config.easingType() } }
        }

        Flickable {
            id: timerButtons
            z: 20
            enabled: root.controlsMode === 1
            x: 8
            width: parent.width - 16
            height: 33
            anchors.verticalCenter: parent.verticalCenter
            contentWidth: Math.max(width, 8 + Settings.timerPresets.length * 33 + Math.max(0, Settings.timerPresets.length - 1) * 7)
            contentHeight: 33
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            opacity: root.controlsMode === 1 ? 1 : 0
            transform: Translate {
                x: root.controlsMode === 1 ? 0 : -18
                Behavior on x { NumberAnimation { duration: Config.animationDuration(Config.timerButtonSlideDuration, "movement"); easing.type: Config.easingType() } }
            }
            Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.timerButtonFadeDuration, "appearance"); easing.type: Config.easingType() } }
            HoverHandler {
                enabled: root.controlsMode === 1
                onHoveredChanged: if (!hovered && root.controlsMode === 1) root.controlsMode = 0
            }
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

        Item {
            id: alarmButtons
            z: 20
            enabled: root.controlsMode === 2
            x: 8
            width: parent.width - 16
            height: 33
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.controlsMode === 2 ? 1 : 0
            transform: Translate {
                x: root.controlsMode === 2 ? 0 : -18
                Behavior on x { NumberAnimation { duration: Config.animationDuration(Config.timerButtonSlideDuration, "movement"); easing.type: Config.easingType() } }
            }
            Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.timerButtonFadeDuration, "appearance"); easing.type: Config.easingType() } }

            HoverHandler {
                enabled: root.controlsMode === 2
                onHoveredChanged: if (!hovered && root.controlsMode === 2) root.controlsMode = 0
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Rectangle {
                    id: alarmHourBox
                    width: 33
                    height: 33
                    radius: 7
                    color: Config.background
                    border.color: Config.baseColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.alarmTarget.getHours().toString().padStart(2, "0")
                        color: Config.textDim
                        font.family: Config.settingsFont
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            const target = new Date(root.alarmTarget.getTime())
                            target.setSeconds(0, 0)
                            const now = new Date()
                            if (target.getTime() <= now.getTime())
                                target.setDate(target.getDate() + 1)
                            const hh = target.getHours().toString().padStart(2, "0")
                            const mm = target.getMinutes().toString().padStart(2, "0")
                            Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "add_at", hh + ":" + mm])
                            root.alarmTargetAdjusted = false
                            root.alarmTarget = new Date()
                        }
                        onWheel: wheel => {
                            const direction = wheel.angleDelta.y > 0 ? 1 : -1
                            const multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
                            const target = new Date(root.alarmTarget.getTime())
                            target.setHours(target.getHours() + direction * multiplier)
                            target.setSeconds(0, 0)
                            root.alarmTarget = target
                            root.alarmTargetAdjusted = true
                            wheel.accepted = true
                        }
                    }
                }

                Text {
                    width: 8
                    height: 33
                    text: ":"
                    color: Config.textDim
                    font.family: Config.settingsFont
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    id: alarmMinuteBox
                    width: 33
                    height: 33
                    radius: 7
                    color: Config.background
                    border.color: Config.baseColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.alarmTarget.getMinutes().toString().padStart(2, "0")
                        color: Config.textDim
                        font.family: Config.settingsFont
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                const target = new Date(root.alarmTarget.getTime())
                                target.setMinutes(0, 0, 0)
                                root.alarmTarget = target
                                root.alarmTargetAdjusted = true
                                return
                            }

                            const target = new Date(root.alarmTarget.getTime())
                            target.setSeconds(0, 0)
                            const now = new Date()
                            if (target.getTime() <= now.getTime())
                                target.setDate(target.getDate() + 1)
                            const hh = target.getHours().toString().padStart(2, "0")
                            const mm = target.getMinutes().toString().padStart(2, "0")
                            Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "add_at", hh + ":" + mm])
                            root.alarmTargetAdjusted = false
                            root.alarmTarget = new Date()
                        }
                        onWheel: wheel => {
                            const direction = wheel.angleDelta.y > 0 ? 1 : -1
                            const multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
                            const target = new Date(root.alarmTarget.getTime())
                            target.setMinutes(target.getMinutes() + direction * multiplier)
                            target.setSeconds(0, 0)
                            root.alarmTarget = target
                            root.alarmTargetAdjusted = true
                            wheel.accepted = true
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
            spacing: Config.timerRowSpacing

            Repeater {
                model: timerModel
                delegate: Item {
                    width: parent.width
                    height: root.timerRowHeight
                    property var timerData: model

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
                            text: String(timerData.comment || "").slice(0, Config.timerCommentMaxLength)
                            color: timerData.color || Config.text
                            font.family: "Pixel LCD7"
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            id: timerDisplay
                            width: 100
                            height: parent.height
                            property string displayText: (timerData.sign || "") + (timerData.timer || "")
                            property color outlineColor: timerData.color || Config.text
                            property int displaySize: root.timers.length >= 5 ? 25 : (root.timers.length >= 4 ? 30 : 35)
                            property var outlineOffsets: [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]]
                            property bool hasSign: String(timerData.sign || "") !== ""

                            Repeater {
                                model: timerDisplay.hasSign ? timerDisplay.outlineOffsets.length : 0
                                delegate: Text {
                                    x: timerDisplay.outlineOffsets[index][0]
                                    y: timerDisplay.outlineOffsets[index][1]
                                    width: timerDisplay.width
                                    height: timerDisplay.height
                                    text: timerDisplay.displayText
                                    color: timerDisplay.outlineColor
                                    font.family: Config.ledFont
                                    font.pixelSize: timerDisplay.displaySize
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Text {
                                anchors.fill: parent
                                text: timerDisplay.displayText
                                color: timerDisplay.hasSign ? Config.black : timerDisplay.outlineColor
                                font.family: Config.ledFont
                                font.pixelSize: timerDisplay.displaySize
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        hoverEnabled: false
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                root.selectedFile = root.selectedFile === timerData.file ? "" : timerData.file
                            } else if (mouse.button === Qt.MiddleButton) {
                                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "delete", timerData.file])
                                if (root.selectedFile === timerData.file) root.selectedFile = ""
                            } else if (mouse.button === Qt.RightButton) {
                                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "update_color", timerData.file])
                            }
                        }
                        onWheel: wheel => Quickshell.execDetached([
                            Quickshell.shellDir + "/scripts/timer",
                            wheel.angleDelta.y > 0 ? "up" : "down", timerData.file
                        ])
                    }
                }
            }
        }
    }

}
