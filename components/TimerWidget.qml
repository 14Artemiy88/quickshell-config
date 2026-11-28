import QtQuick
import QtQuick.Controls
import "primitives" as Primitives
import ".."
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
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
            if (timerModel.get(i).file === selectedFile && !timerModel.get(i).removing) return i
        }
        return -1
    }
    // Vertical anchor for the shared options surface. Read the live delegate
    // geometry so adaptive row heights, spacing and in-flight row morphs are
    // reflected without estimating from the timer's index.
    readonly property real selectedTimerRowCenterY: {
        const index = root.selectedIndex
        if (index < 0)
            return root.height / 2
        const row = timerRowsRepeater.itemAt(index)
        if (!row)
            return root.height / 2
        return timerList.y + timerRowsColumn.y + row.y + row.height / 2
    }
    readonly property int visibleTimerCount: Math.min((timers || []).length, 5)
    // Include outgoing delegates until their MorphGeometry collapse finishes;
    // shell.qml uses adaptiveHeight as the timer surface's content height.
    readonly property int layoutTimerCount: Math.min(5, Math.max(visibleTimerCount, timerModel.count))
    readonly property real timerPresentationScale: root.compactPresentation ? 0.9
        : root.widePresentation ? 1.05 : 1
    readonly property int timerRowHeight: Math.max(22, Math.round((visibleTimerCount >= 5 ? 26 : 30) * timerPresentationScale))
    readonly property int effectiveTimerRowSpacing: root.compactPresentation
        ? Math.max(0, Math.round(Config.timerRowSpacing * 0.75))
        : root.widePresentation ? Math.round(Config.timerRowSpacing * 1.15) : Config.timerRowSpacing
    readonly property int effectiveTimerTopMargin: root.compactPresentation
        ? Math.max(4, Math.round(Config.timerRowTopMargin * 0.7)) : Config.timerRowTopMargin
    readonly property int effectiveTimerRightMargin: root.compactPresentation
        ? Math.max(4, Math.round(Config.timerRowRightMargin * 0.7)) : Config.timerRowRightMargin
    readonly property int effectiveTimerCommentGap: root.compactPresentation
        ? Math.max(5, Math.round(Config.timerCommentGap * 0.7))
        : root.widePresentation ? Math.round(Config.timerCommentGap * 1.1) : Config.timerCommentGap
    readonly property int effectiveTimerCommentWidth: root.compactPresentation
        ? Math.min(Config.timerCommentWidth, Math.max(34, Math.round((root.width - 150) * 0.42)))
        : Config.timerCommentWidth
    readonly property int timerRowMorphDuration: Config.animationDurationForProfile(
        Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile,
        Config.animationTimerMorphDuration, "appearance")
    // Preserve the existing density-based scaling while exposing a configurable base size.
    readonly property int elapsedTimeDisplaySize: {
        const baseSize = Number(Config.timerElapsedFontSize)
        const safeBase = isFinite(baseSize) ? Math.max(8, Math.min(60, baseSize)) : 35
        const densityScale = root.timers.length >= 5 ? 25 / 35 : (root.timers.length >= 4 ? 30 / 35 : 1)
        return Math.max(8, Config.uiFontSize(safeBase * densityScale * root.timerPresentationScale))
    }
    // The timer module Height setting is the minimum height. It is not a cap;
    // the block grows automatically when more timers need to be displayed.
    readonly property int configuredMinHeight: {
        const h = Number(Settings.geometry.timer && Settings.geometry.timer[3])
        return isFinite(h) && h > 0 ? Math.round(h) : Config.timerMinHeight
    }
    readonly property int adaptiveHeight: Math.max(
        configuredMinHeight,
        14 + layoutTimerCount * timerRowHeight + Math.max(0, layoutTimerCount - 1) * effectiveTimerRowSpacing
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
        // Disabled icons also disable their preset/alarm interaction zone.
        // Buttons stay active while the pointer is over their own row.
        if (Config.timerAlarmIconEnabled && (alarmButtonsHovered || alarmIconHovered)) controlsMode = 2
        else if (Config.timerIconEnabled && (timerButtonsHovered || timerIconHovered)) controlsMode = 1
        else controlsMode = 0
    }
    property string alarmTargetText: {
        const h = alarmTarget.getHours().toString().padStart(2, "0")
        const m = alarmTarget.getMinutes().toString().padStart(2, "0")
        return h + ":" + m
    }

    function scheduleAlarmTarget() {
        const now = new Date()
        const target = new Date(root.alarmTarget.getTime())
        target.setSeconds(0, 0)
        if (target.getTime() <= now.getTime())
            target.setDate(target.getDate() + 1)
        const hh = target.getHours().toString().padStart(2, "0")
        const mm = target.getMinutes().toString().padStart(2, "0")
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "add_at", hh + ":" + mm, Config.timerRandomColorMode, String(Config.timerRandomColorMin), String(Config.timerRandomColorMax)])
        root.alarmTargetAdjusted = false
        root.alarmTarget = new Date()
    }

    function adjustAlarmTarget(unit, wheelEvent) {
        const direction = wheelEvent.angleDelta.y > 0 ? 1 : -1
        const multiplier = (wheelEvent.modifiers & Qt.ShiftModifier) ? 10 : 1
        const target = new Date(root.alarmTarget.getTime())
        if (unit === "hours")
            target.setHours(target.getHours() + direction * multiplier)
        else
            target.setMinutes(target.getMinutes() + direction * multiplier)
        target.setSeconds(0, 0)
        root.alarmTarget = target
        root.alarmTargetAdjusted = true
        wheelEvent.accepted = true
    }

    function resetAlarmTargetMinutes() {
        const target = new Date(root.alarmTarget.getTime())
        target.setMinutes(0, 0, 0)
        root.alarmTarget = target
        root.alarmTargetAdjusted = true
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
        target: Config
        function onTimerIconEnabledChanged() {
            if (!Config.timerIconEnabled && root.controlsMode === 1) {
                root.controlsMode = 0
                iconInteraction.hoverZone = 0
            }
        }
        function onTimerAlarmIconEnabledChanged() {
            if (!Config.timerAlarmIconEnabled && root.controlsMode === 2) {
                root.controlsMode = 0
                iconInteraction.hoverZone = 0
            }
        }
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
            if (timerModel.get(i).file === file && !timerModel.get(i).removing)
                return String(timerModel.get(i).comment || "")
        }
        return ""
    }

    function syncTimerModel(items) {
        const visible = (items || []).slice(0, 5)

        // Mark disappeared timers as outgoing rather than removing their rows
        // immediately. If a timer reappears during the transition, its shared
        // progress reverses back toward the expanded geometry.
        for (let i = timerModel.count - 1; i >= 0; --i) {
            let exists = false
            for (let j = 0; j < visible.length; ++j) {
                if (timerModel.get(i).file === visible[j].file) { exists = true; break }
            }
            if (!exists && !timerModel.get(i).removing)
                timerModel.setProperty(i, "removing", true)
            else if (exists && timerModel.get(i).removing)
                timerModel.setProperty(i, "removing", false)
        }

        // Update existing delegates in place and append new timers. This keeps
        // the + outline stable instead of recreating the delegate every second.
        for (let j = 0; j < visible.length; ++j) {
            const item = visible[j]
            let found = -1
            for (let i = 0; i < timerModel.count; ++i) {
                if (timerModel.get(i).file === item.file) { found = i; break }
            }
            if (found < 0) {
                const inserted = {}
                for (const key in item) inserted[key] = item[key]
                inserted.removing = false
                inserted.appearing = true
                timerModel.append(inserted)
            }
            else {
                const current = timerModel.get(found)
                for (const key of ["file", "comment", "timer", "color", "sign", "time_passed", "duration_minutes", "ding"]) {
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

        // Keep server order. While an outgoing row is still collapsing, do not
        // move active rows across it: ListModel.move() would carry the tombstone
        // along and make a middle timer jump to the end before its exit finishes.
        let hasOutgoingRows = false
        for (let i = 0; i < timerModel.count; ++i) {
            if (timerModel.get(i).removing) {
                hasOutgoingRows = true
                break
            }
        }
        if (!hasOutgoingRows) {
            // Reorder only when the file sequence actually changed.
            for (let target = 0; target < visible.length; ++target) {
                if (timerModel.get(target).file === visible[target].file) continue
                let source = -1
                for (let i = target + 1; i < timerModel.count; ++i) {
                    if (timerModel.get(i).file === visible[target].file) { source = i; break }
                }
                if (source >= 0) timerModel.move(source, target, 1)
            }
        }
    }

    function finishTimerRowAppearance(file) {
        for (let i = 0; i < timerModel.count; ++i) {
            const item = timerModel.get(i)
            if (item.file === file && item.appearing && !item.removing) {
                timerModel.setProperty(i, "appearing", false)
                return
            }
        }
    }

    function finishTimerRowRemoval(file) {
        for (let i = timerModel.count - 1; i >= 0; --i) {
            const item = timerModel.get(i)
            if (item.file === file && item.removing) {
                timerModel.remove(i)
                if (root.selectedFile === file) root.selectedFile = ""
                return
            }
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
            property bool hasAnyIcon: Config.timerIconEnabled || Config.timerAlarmIconEnabled
            property int minX: Config.timerIconEnabled && Config.timerAlarmIconEnabled
                ? Math.min(Config.timerIconX, Config.timerAlarmIconX)
                : (Config.timerIconEnabled ? Config.timerIconX : Config.timerAlarmIconEnabled ? Config.timerAlarmIconX : 0)
            property int maxX: Config.timerIconEnabled && Config.timerAlarmIconEnabled
                ? Math.max(Config.timerIconX + 30, Config.timerAlarmIconX + 30)
                : (Config.timerIconEnabled ? Config.timerIconX + 30 : Config.timerAlarmIconEnabled ? Config.timerAlarmIconX + 30 : 0)
            property int minY: Config.timerIconEnabled && Config.timerAlarmIconEnabled
                ? Math.min(Config.timerIconY, Config.timerAlarmIconY)
                : (Config.timerIconEnabled ? Config.timerIconY : Config.timerAlarmIconEnabled ? Config.timerAlarmIconY : 0)
            property int maxY: Config.timerIconEnabled && Config.timerAlarmIconEnabled
                ? Math.max(Config.timerIconY, Config.timerAlarmIconY)
                : (Config.timerIconEnabled ? Config.timerIconY : Config.timerAlarmIconEnabled ? Config.timerAlarmIconY : 0)
            x: hasAnyIcon ? minX : 0
            y: (parent.height - height) / 2 + (hasAnyIcon ? minY : 0)
            width: hasAnyIcon ? Math.max(30, maxX - minX) : 0
            height: hasAnyIcon ? 33 + maxY - minY : 0
            enabled: hasAnyIcon
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            property int hoverZone: 0 // 0 = none, 1 = timer, 2 = alarm

            function zoneAt(localX, localY) {
                const timerStartX = Config.timerIconX - minX
                const alarmStartX = Config.timerAlarmIconX - minX
                const timerStartY = Config.timerIconY - minY
                const alarmStartY = Config.timerAlarmIconY - minY
                const inTimer = Config.timerIconEnabled
                    && localX >= timerStartX && localX < timerStartX + 30
                    && localY >= timerStartY && localY < timerStartY + 33
                const inAlarm = Config.timerAlarmIconEnabled
                    && localX >= alarmStartX && localX < alarmStartX + 30
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
                root.scheduleAlarmTarget()
            }

            onWheel: wheel => {
                if (hoverZone !== 2) {
                    wheel.accepted = false
                    return
                }
                root.adjustAlarmTarget("minutes", wheel)
            }
        }

        Primitives.MorphGeometry {
            id: timerIconMorph
            fromGeometry: Qt.rect(Config.timerIconX + 1,
                (parent.height - 33) / 2 + Config.timerIconY + 1, 28, 31)
            toGeometry: Qt.rect(Config.timerIconX,
                (parent.height - 33) / 2 + Config.timerIconY, 30, 33)
            progress: Config.timerIconEnabled && root.controlsMode === 0 ? 1 : 0
            visible: (Config.timerIconEnabled && root.controlsMode === 0) || normalizedProgress > 0.001
            animationDuration: !Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile)
                ? 0 : Config.animationDuration(Config.timerButtonIconFadeDuration, "appearance")
            animationProfile: Config.animationTimerMorphProfile
            animationPhase: Config.timerIconEnabled && root.controlsMode === 0 ? "enter" : "exit"
            animationEasing: Config.animationEasingType(Config.animationTimerMorphProfile, Config.timerIconEnabled && root.controlsMode === 0 ? "enter" : "exit")

            Text {
                anchors.fill: parent
                text: Config.timerIcon
                color: Config.text
                font.pixelSize: Config.uiFontSize(Config.timerIconSize)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: timerIconMorph.normalizedProgress
            }
        }

        Primitives.MorphGeometry {
            id: alarmIconMorph
            fromGeometry: Qt.rect(Config.timerAlarmIconX + 1,
                (parent.height - 33) / 2 + Config.timerAlarmIconY + 1, 28, 31)
            toGeometry: Qt.rect(Config.timerAlarmIconX,
                (parent.height - 33) / 2 + Config.timerAlarmIconY, 30, 33)
            progress: Config.timerAlarmIconEnabled && root.controlsMode === 0 ? 1 : 0
            visible: (Config.timerAlarmIconEnabled && root.controlsMode === 0) || normalizedProgress > 0.001
            animationDuration: !Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile)
                ? 0 : Config.animationDuration(Config.timerButtonIconFadeDuration, "appearance")
            animationProfile: Config.animationTimerMorphProfile
            animationPhase: Config.timerAlarmIconEnabled && root.controlsMode === 0 ? "enter" : "exit"
            animationEasing: Config.animationEasingType(Config.animationTimerMorphProfile, Config.timerAlarmIconEnabled && root.controlsMode === 0 ? "enter" : "exit")

            Text {
                anchors.fill: parent
                text: Config.timerAlarmIcon
                color: Config.text
                font.pixelSize: Config.uiFontSize(Config.timerAlarmIconSize)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: alarmIconMorph.normalizedProgress
            }
        }

        Primitives.AnimatedVisibility {
            id: timerButtonsVisibility
            z: 20
            x: 8
            width: parent.width - 16
            height: 33
            anchors.verticalCenter: parent.verticalCenter
            shown: root.controlsMode === 1
            animationStyle: Config.animationTimerVisibilityStyle
            animationProfile: Config.animationTimerVisibilityProfile
            duration: Config.animationTimerVisibilityStyle === "none" ? 0 : Config.animationDuration(Config.animationTimerVisibilityStyle === "fade" ? Config.timerButtonFadeDuration : Config.timerButtonSlideDuration, "appearance")

            Flickable {
                id: timerButtons
                anchors.fill: parent
                enabled: true
            contentWidth: Math.max(width, 8 + Settings.timerPresets.length * 33 + Math.max(0, Settings.timerPresets.length - 1) * 7)
            contentHeight: 33
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            HoverHandler {
                enabled: root.controlsMode === 1
                onHoveredChanged: if (!hovered && root.controlsMode === 1) root.controlsMode = 0
            }
            Row {
                spacing: 7
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: Settings.timerPresets
                    delegate: TimerPresetButton {
                        width: 33
                        height: 33
                        label: String(modelData)
                        onButtonClicked: button => {
                            if (button === Qt.MiddleButton) {
                                Settings.resetTimerPreset(index)
                                return
                            }
                            if (button === Qt.LeftButton)
                                Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "add", String(modelData), "", Config.timerRandomColorMode, String(Config.timerRandomColorMin), String(Config.timerRandomColorMax)])
                        }
                        onWheelAdjusted: (direction, accelerated) => {
                            const multiplier = accelerated ? 10 : 1
                            Settings.adjustTimerPreset(index, direction * Config.timerWheelStep * multiplier)
                        }
                    }
                }
            }
        }
        }

        Primitives.AnimatedVisibility {
            id: alarmButtonsVisibility
            z: 20
            x: 8
            width: parent.width - 16
            height: 33
            anchors.verticalCenter: parent.verticalCenter
            shown: root.controlsMode === 2
            animationStyle: Config.animationTimerVisibilityStyle
            animationProfile: Config.animationTimerVisibilityProfile
            duration: Config.animationTimerVisibilityStyle === "none" ? 0 : Config.animationDuration(Config.animationTimerVisibilityStyle === "fade" ? Config.timerButtonFadeDuration : Config.timerButtonSlideDuration, "appearance")

            Item {
                id: alarmButtons
                anchors.fill: parent
                enabled: true
            HoverHandler {
                enabled: root.controlsMode === 2
                onHoveredChanged: if (!hovered && root.controlsMode === 2) root.controlsMode = 0
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                TimerAlarmTimeButton {
                    id: alarmHourBox
                    width: 33
                    height: 33
                    displayText: root.alarmTarget.getHours().toString().padStart(2, "0")
                    acceptedButtons: Qt.LeftButton
                    wheelEnabled: true

                    onButtonClicked: button => {
                        if (button === Qt.LeftButton)
                            root.scheduleAlarmTarget()
                    }
                    onWheelRequested: wheelEvent => root.adjustAlarmTarget("hours", wheelEvent)
                }

                Text {
                    width: 8
                    height: 33
                    text: ":"
                    color: Config.textDim
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.uiFontSize(13)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                TimerAlarmTimeButton {
                    id: alarmMinuteBox
                    width: 33
                    height: 33
                    displayText: root.alarmTarget.getMinutes().toString().padStart(2, "0")
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    wheelEnabled: true

                    onButtonClicked: button => {
                        if (button === Qt.MiddleButton) {
                            root.resetAlarmTargetMinutes()
                            return
                        }
                        if (button === Qt.LeftButton)
                            root.scheduleAlarmTarget()
                    }
                    onWheelRequested: wheelEvent => root.adjustAlarmTarget("minutes", wheelEvent)
                }
            }
        }
        }
    }

    readonly property int widestTimerTextWidth: {
        var maxWidth = 0
        for (var i = 0; i < timerWidthMeasurer.count; ++i) {
            var measured = timerWidthMeasurer.itemAt(i)
            if (measured) maxWidth = Math.max(maxWidth, measured.measuredWidth)
        }
        return maxWidth
    }

    Item {
        id: timerList
        x: 0
        y: 0
        width: parent.width
        height: parent.height
        clip: true

        // Keep metrics delegates separate from the visible rows so the optional
        // alignment can use the widest countdown without changing timer ordering.
        Repeater {
            id: timerWidthMeasurer
            model: timerModel
            delegate: Item {
                id: measuredTimerItem
                visible: false
                width: 0
                height: 0
                property var timerData: model
                property string displayText: String(timerData.sign || "") + String(timerData.timer || "")
                property int displaySize: root.elapsedTimeDisplaySize
                property int measuredWidth: Math.ceil(measuredTextMetrics.advanceWidth) + 2
                TextMetrics {
                    id: measuredTextMetrics
                    font.family: Config.timerElapsedFont
                    font.pixelSize: measuredTimerItem.displaySize
                    text: measuredTimerItem.displayText
                }
            }
        }

        Column {
            id: timerRowsColumn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: root.effectiveTimerTopMargin
            anchors.rightMargin: root.effectiveTimerRightMargin
            width: parent.width - anchors.leftMargin - anchors.rightMargin
            spacing: root.effectiveTimerRowSpacing

            Repeater {
                id: timerRowsRepeater
                model: timerModel
                delegate: Item {
                    id: timerRowSlot
                    // With required delegate properties Qt no longer injects the
                    // legacy `model` context object. Declare every role used by
                    // this delegate explicitly so outgoing tombstones retain data.
                    required property string file
                    required property string comment
                    required property string timer
                    required property string color
                    required property string sign
                    required property bool removing
                    required property bool appearing
                    width: parent.width
                    height: timerRowMorph.geometryHeight
                    clip: true
                    property var timerData: ({
                        file: timerRowSlot.file,
                        comment: timerRowSlot.comment,
                        timer: timerRowSlot.timer,
                        color: timerRowSlot.color,
                        sign: timerRowSlot.sign
                    })
                    // The model keeps a tombstone, but this delegate owns the
                    // actual animated progress. This avoids starting an exit
                    // from zero when a delegate is (re)created while removing.
                    property real rowProgress: 0
                    property bool transitionInitialized: false
                    property bool removalSignalSent: false
                    readonly property int rowTransitionDuration: root.timerRowMorphDuration

                    function finishExitTransition() {
                        if (!timerRowSlot.removing || timerRowSlot.removalSignalSent)
                            return
                        timerRowSlot.rowProgress = 0
                        timerRowSlot.removalSignalSent = true
                        root.finishTimerRowRemoval(String(timerRowSlot.file || ""))
                    }

                    function startEntryTransition() {
                        timerExitAnimation.stop()
                        timerEntryAnimation.stop()
                        timerRowSlot.removalSignalSent = false
                        if (timerRowSlot.rowTransitionDuration <= 0 || timerRowSlot.rowProgress >= 0.999) {
                            timerRowSlot.rowProgress = 1
                            root.finishTimerRowAppearance(String(timerRowSlot.file || ""))
                            return
                        }
                        timerEntryAnimation.start()
                    }

                    function startExitTransition() {
                        timerEntryAnimation.stop()
                        timerExitAnimation.stop()
                        if (timerRowSlot.rowTransitionDuration <= 0 || timerRowSlot.rowProgress <= 0.001) {
                            timerRowSlot.finishExitTransition()
                            return
                        }
                        timerExitAnimation.start()
                    }

                    onRemovingChanged: {
                        if (!timerRowSlot.transitionInitialized)
                            return
                        if (timerRowSlot.removing)
                            timerRowSlot.startExitTransition()
                        else
                            timerRowSlot.startEntryTransition()
                    }

                    Component.onCompleted: {
                        timerRowSlot.transitionInitialized = true
                        if (timerRowSlot.removing) {
                            // A tombstone whose delegate appears late still
                            // receives a full visible exit transition.
                            timerRowSlot.rowProgress = 1
                            timerRowSlot.startExitTransition()
                        } else if (timerRowSlot.appearing) {
                            timerRowSlot.rowProgress = 0
                            timerRowSlot.startEntryTransition()
                        } else {
                            timerRowSlot.rowProgress = 1
                        }
                    }

                    NumberAnimation {
                        id: timerEntryAnimation
                        target: timerRowSlot
                        property: "rowProgress"
                        to: 1
                        duration: timerRowSlot.rowTransitionDuration
                        easing.type: Config.animationEasingType(Config.animationTimerMorphProfile, "enter")
                        easing.bezierCurve: Config.animationBezierCurve(Config.animationTimerMorphProfile, "enter")
                        onFinished: root.finishTimerRowAppearance(String(timerRowSlot.file || ""))
                    }

                    NumberAnimation {
                        id: timerExitAnimation
                        target: timerRowSlot
                        property: "rowProgress"
                        to: 0
                        duration: timerRowSlot.rowTransitionDuration
                        easing.type: Config.animationEasingType(Config.animationTimerMorphProfile, "exit")
                        easing.bezierCurve: Config.animationBezierCurve(Config.animationTimerMorphProfile, "exit")
                        onFinished: timerRowSlot.finishExitTransition()
                    }

                    Primitives.MorphGeometry {
                        id: timerRowMorph
                        fromGeometry: Qt.rect(0, 0, parent.width, 0)
                        toGeometry: Qt.rect(0, 0, parent.width, root.timerRowHeight)
                        progress: timerRowSlot.rowProgress
                        // Progress is animated by the delegate so that a late
                        // tombstone can initialize at full size before exiting.
                        animationDuration: 0
                        animationProfile: Config.animationTimerMorphProfile
                        clip: true

                        Item {
                            x: 0
                            y: (timerRowMorph.height - height) / 2
                            width: parent.width
                            height: root.timerRowHeight

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 0
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: root.effectiveTimerCommentGap
                                height: parent.height

                                Text {
                                    // Keep the original timer value/comment directly next
                                    // to the live countdown. Limit it to 10 characters so
                                    // long timers can never collide with the countdown.
                                    width: root.effectiveTimerCommentWidth
                                    height: parent.height
                                    text: String(timerData.comment || "").slice(0, Config.timerCommentMaxLength)
                                    color: timerData.color || Config.text
                                    font.family: "Pixel LCD7"
                                    font.pixelSize: Config.uiFontSize(15 * root.timerPresentationScale)
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Item {
                                    id: timerDisplay
                                    // Size the countdown column to the rendered text instead of
                                    // reserving a fixed 100 px. This keeps the comment gap visually
                                    // constant for both short and long timers.
                                    width: Config.timerCommentAlignFurthest && root.widestTimerTextWidth > 0
                                        ? root.widestTimerTextWidth
                                        : Math.ceil(textMetrics.advanceWidth) + 2
                                    height: parent.height
                                    property string displayText: (timerData.sign || "") + (timerData.timer || "")
                                    property color outlineColor: timerData.color || Config.text
                                    property int displaySize: root.elapsedTimeDisplaySize
                                    property var outlineOffsets: [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]]
                                    property bool hasSign: String(timerData.sign || "") !== ""

                                    TextMetrics {
                                        id: textMetrics
                                        font.family: Config.timerElapsedFont
                                        font.pixelSize: timerDisplay.displaySize
                                        text: timerDisplay.displayText
                                    }

                                    Repeater {
                                        model: timerDisplay.hasSign ? timerDisplay.outlineOffsets.length : 0
                                        delegate: Text {
                                            x: timerDisplay.outlineOffsets[index][0]
                                            y: timerDisplay.outlineOffsets[index][1]
                                            width: timerDisplay.width
                                            height: timerDisplay.height
                                            text: timerDisplay.displayText
                                            color: timerDisplay.outlineColor
                                            font.family: Config.timerElapsedFont
                                            font.pixelSize: timerDisplay.displaySize
                                            horizontalAlignment: Text.AlignRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        text: timerDisplay.displayText
                                        color: timerDisplay.hasSign ? Config.black : timerDisplay.outlineColor
                                        font.family: Config.timerElapsedFont
                                        font.pixelSize: timerDisplay.displaySize
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !timerRowSlot.removing
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                hoverEnabled: false
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        root.selectedFile = root.selectedFile === timerData.file ? "" : timerData.file
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "delete", timerData.file])
                                        if (root.selectedFile === timerData.file) root.selectedFile = ""
                                    } else if (mouse.button === Qt.RightButton) {
                                        Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", "update_color", timerData.file, Config.timerRandomColorMode, String(Config.timerRandomColorMin), String(Config.timerRandomColorMax)])
                                    }
                                }
                                onWheel: wheel => {
                                    const step = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
                                    Quickshell.execDetached([
                                        Quickshell.shellDir + "/scripts/timer",
                                        wheel.angleDelta.y > 0 ? "up" : "down", timerData.file, String(step)
                                    ])
                                    wheel.accepted = true
                                }
                            }
                        }
                    }

                }
            }
        }
    }

}
