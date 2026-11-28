import QtQuick
import ".."
import "primitives" as Primitives
import Quickshell

Item {
    id: root
    width: 90
    height: 95
    property var timers: []
    property string selectedFile: ""
    property var selected: null
    property bool closing: false
    signal closeRequested()
    signal closeFinished()
    signal commentRequested(string file)
    property bool commentMode: false
    property string commentFile: ""
    property string commentText: ""
    property bool durationMode: false
    property string durationInputText: ""
    property bool colorMode: false
    property string colorInputText: ""
    readonly property var actionIconItems: {
        var definitions = {
            comment: { id: "comment", icon: Config.timerOptionsCommentIcon, enabled: Config.timerOptionsCommentIconEnabled, size: Config.timerOptionsCommentIconSize },
            duration: { id: "duration", icon: Config.timerOptionsDurationIcon, enabled: Config.timerOptionsDurationIconEnabled, size: Config.timerOptionsDurationIconSize },
            refresh: { id: "refresh", icon: Config.timerOptionsRefreshIcon, enabled: Config.timerOptionsRefreshIconEnabled, size: Config.timerOptionsRefreshIconSize },
            toggle_pause: { id: "toggle_pause", icon: Config.timerOptionsPauseIcon, enabled: Config.timerOptionsPauseIconEnabled, size: Config.timerOptionsPauseIconSize },
            color: { id: "color", icon: Config.timerOptionsColorIcon, enabled: Config.timerOptionsColorIconEnabled, size: Config.timerOptionsColorIconSize }
        }
        var defaults = ["comment", "duration", "refresh", "toggle_pause", "color"]
        var source = Config.timerOptionsActionIconOrder
        var order = []
        if (source instanceof Array) {
            for (var i = 0; i < source.length; ++i) {
                var id = String(source[i] || "")
                if (definitions[id] && order.indexOf(id) < 0) order.push(id)
            }
        }
        for (var j = 0; j < defaults.length; ++j)
            if (order.indexOf(defaults[j]) < 0) order.push(defaults[j])
        var result = []
        for (var k = 0; k < order.length; ++k) {
            var item = definitions[order[k]]
            if (item && item.enabled) {
                var safeSize = Number(item.size)
                item.size = isFinite(safeSize) ? Math.max(8, Math.min(40, Math.round(safeSize))) : 22
                result.push(item)
            }
        }
        return result
    }
    enabled: selectedFile !== "" && !closing
    opacity: 0
    scale: 0.97
    transformOrigin: Item.Center
    clip: true

    // Keep the popup's geometry fixed and slide its visual contents inside a
    // clipping viewport. This is a real translation, not a scale/collapse:
    // the card moves in from/out toward the selected edge without travelling
    // across the timer widget or changing its layout geometry.
    property bool closeSignalSent: false
    property bool popupHasBeenShown: false
    property bool popupContentVisible: false
    property real slideOffsetX: 0
    property real slideOffsetY: 0
    visible: popupContentVisible

    Item {
        id: slideClip
        anchors.fill: parent
        clip: true

        Item {
            id: slideContent
            width: root.width
            height: root.height
            transform: Translate {
                id: popupTranslation
                x: root.slideOffsetX
                y: root.slideOffsetY
            }
        }
    }

    // The popup surface itself is transparent. Paint the widget background here
    // so it follows the current theme/settings without making the whole popup
    // surface opaque.
    Rectangle {
        parent: slideContent
        anchors.fill: parent
        color: Config.background
        radius: Config.scaledCornerRadius(Config.frameRadius)
        antialiasing: true
        z: -2
    }

    // Frame border is drawn separately so the popup keeps the same appearance
    // as the other configured widgets.
    Rectangle {
        parent: slideContent
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0)
        border.color: Config.baseColor
        border.width: Config.popupBordersEnabled ? Config.frameBorderWidth : 0
        radius: Config.scaledCornerRadius(Config.frameRadius)
        antialiasing: true
        z: -1
    }

    ParallelAnimation {
        id: visualTransition
        NumberAnimation {
            id: showOpacityAnimation
            target: root
            property: "opacity"
            easing.type: Config.animationEasingType(Config.animationTimerOptionsVisibilityProfile, "enter")
            easing.bezierCurve: Config.animationBezierCurve(Config.animationTimerOptionsVisibilityProfile, "enter")
        }
        NumberAnimation {
            id: showScaleAnimation
            target: root
            property: "scale"
            easing.type: Config.animationEasingType(Config.animationTimerOptionsVisibilityProfile, "enter")
            easing.bezierCurve: Config.animationBezierCurve(Config.animationTimerOptionsVisibilityProfile, "enter")
        }
        NumberAnimation {
            id: slideXAnimation
            target: root
            property: "slideOffsetX"
            easing.type: Config.animationEasingType(Config.animationTimerOptionsVisibilityProfile, "enter")
            easing.bezierCurve: Config.animationBezierCurve(Config.animationTimerOptionsVisibilityProfile, "enter")
        }
        NumberAnimation {
            id: slideYAnimation
            target: root
            property: "slideOffsetY"
            easing.type: Config.animationEasingType(Config.animationTimerOptionsVisibilityProfile, "enter")
            easing.bezierCurve: Config.animationBezierCurve(Config.animationTimerOptionsVisibilityProfile, "enter")
        }
        onFinished: root.finishCloseOnce()
    }

    function animationsActive() {
        return Config.animationTimerOptionsVisibilityStyle !== "none"
    }

    function slideXEnabled(style) {
        return style === "slideLeft" || style === "slideRight"
    }

    function slideYEnabled(style) {
        return style === "slideUp" || style === "slideDown"
    }

    function slideTargetX(hidden, style) {
        if (!hidden) return 0
        if (style === "slideLeft") return -root.width
        if (style === "slideRight") return root.width
        return 0
    }

    function slideTargetY(hidden, style) {
        if (!hidden) return 0
        if (style === "slideUp") return -root.height
        if (style === "slideDown") return root.height
        return 0
    }

    function syncVisualState() {
        var hidden = closing || selectedFile === ""
        var style = Config.animationTimerOptionsVisibilityStyle
        var fadeEnabled = style === "fade"
        var slideX = slideXEnabled(style)
        var slideY = slideYEnabled(style)
        var targetOpacity = hidden && (fadeEnabled || style === "none") ? 0 : 1
        var targetScale = hidden && fadeEnabled ? 0.97 : 1
        var targetSlideX = slideTargetX(hidden, style)
        var targetSlideY = slideTargetY(hidden, style)

        visualTransition.stop()

        // An unselected popup is already hidden. Place its content beyond the
        // clipping viewport directly instead of animating a phantom transition.
        if (!closing && selectedFile === "" && !popupHasBeenShown) {
            opacity = targetOpacity
            scale = targetScale
            slideOffsetX = targetSlideX
            slideOffsetY = targetSlideY
            return
        }

        if (!animationsActive()) {
            opacity = targetOpacity
            scale = targetScale
            slideOffsetX = targetSlideX
            slideOffsetY = targetSlideY
            finishCloseOnce()
            return
        }

        var baseDuration = Math.max(0, Number(Config.animationTimerOptionsDuration) || 0)
        var duration = Config.animationDuration(baseDuration, "appearance")

        showOpacityAnimation.from = opacity
        showOpacityAnimation.to = targetOpacity
        showOpacityAnimation.duration = fadeEnabled ? duration : 0
        showScaleAnimation.from = scale
        showScaleAnimation.to = targetScale
        showScaleAnimation.duration = fadeEnabled ? duration : 0

        slideXAnimation.from = slideOffsetX
        slideXAnimation.to = targetSlideX
        slideXAnimation.duration = slideX ? duration : 0
        slideYAnimation.from = slideOffsetY
        slideYAnimation.to = targetSlideY
        slideYAnimation.duration = slideY ? duration : 0

        if (showOpacityAnimation.duration <= 0
                && showScaleAnimation.duration <= 0
                && slideXAnimation.duration <= 0
                && slideYAnimation.duration <= 0) {
            opacity = targetOpacity
            scale = targetScale
            slideOffsetX = targetSlideX
            slideOffsetY = targetSlideY
            finishCloseOnce()
            return
        }
        visualTransition.start()
    }

    Connections {
        target: Config
        function onAnimationTimerOptionsVisibilityStyleChanged() { root.syncVisualState() }
    }

    // The persistent fullscreen overlay in shell.qml closes the options on an
    // outside click. This card only receives clicks meant for its own controls.
    MouseArea {
        parent: slideContent
        anchors.fill: parent
        z: 0
        onClicked: {}
    }

    // Comment editor uses the same popup surface and geometry as the timer
    // options window. This avoids a second xdg-popup with a different anchor
    // coordinate system and gives the input the popup's keyboard focus.
    Item {
        parent: slideContent
        anchors.fill: parent
        visible: root.commentMode
        z: 10

        Text {
            x: 7
            y: 7
            width: parent.width - 14
            height: 16
            text: "Комментарий"
            color: Config.text
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(11)
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            x: 7
            y: 28
            width: parent.width - 14
            height: 27
            radius: Config.scaledCornerRadius(4)
            color: Config.settingsBackground
            border.color: Config.settingsBorder
            border.width: Config.inputBordersEnabled ? 1 : 0

            TextInput {
                id: commentInput
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                color: Config.text
                selectionColor: Config.accent
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.uiFontSize(11)
                verticalAlignment: TextInput.AlignVCenter
                text: root.commentText
                focus: root.commentMode
                activeFocusOnPress: true
                activeFocusOnTab: true
                selectByMouse: true
                onActiveFocusChanged: {
                    if (activeFocus) selectAll()
                }
                onTextChanged: root.commentText = text
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        Quickshell.execDetached([
                            Quickshell.shellDir + "/scripts/timer",
                            "set_comment",
                            root.commentFile,
                            commentInput.text
                        ])
                        root.commentMode = false
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.commentMode = false
                        event.accepted = true
                    }
                }
            }
        }

        Text {
            x: 7
            y: 61
            width: parent.width - 14
            height: 15
            text: "Enter — сохранить"
            color: Config.textDim
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(9)
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            x: 7
            y: 76
            width: parent.width - 14
            height: 14
            text: "Esc — отменить"
            color: Config.textDim
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(9)
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Duration editor: change the target total duration without restarting
    // the timer. The script preserves the elapsed seconds, including while
    // the timer is paused.
    Item {
        parent: slideContent
        anchors.fill: parent
        visible: root.durationMode
        z: 10

        Text {
            x: 5
            y: 7
            width: parent.width - 10
            height: 15
            text: "Длительность, мин"
            color: Config.text
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(10)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            x: 7
            y: 27
            width: parent.width - 14
            height: 28
            radius: Config.scaledCornerRadius(4)
            color: Config.settingsBackground
            border.color: Config.settingsBorder
            border.width: Config.inputBordersEnabled ? 1 : 0

            TextInput {
                id: durationInput
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                color: Config.text
                selectionColor: Config.accent
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.uiFontSize(13)
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 1; top: 10080 }
                text: root.durationInputText
                focus: root.durationMode
                activeFocusOnPress: true
                activeFocusOnTab: true
                selectByMouse: true
                onActiveFocusChanged: {
                    if (activeFocus) selectAll()
                }
                onTextChanged: root.durationInputText = text
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.saveDuration()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.closeDurationEditor()
                        event.accepted = true
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 63
            spacing: 14

            Primitives.HoverIconButton {
                width: 24
                height: 23
                iconText: "✓"
                iconSize: 17
                baseColor: Config.accent
                iconFontFamily: Config.settingsFont
                hoverMode: "none"
                cursorShape: Qt.ArrowCursor
                toolTipText: "Сохранить"
                onClicked: root.saveDuration()
            }

            Primitives.HoverIconButton {
                width: 24
                height: 23
                iconText: "×"
                iconSize: 17
                baseColor: Config.textDim
                iconFontFamily: Config.settingsFont
                hoverMode: "none"
                cursorShape: Qt.ArrowCursor
                toolTipText: "Отмена"
                onClicked: root.closeDurationEditor()
            }
        }

        Text {
            x: 5
            y: 82
            width: parent.width - 10
            height: 11
            text: "1–10080 мин · Enter — сохранить"
            color: Config.textDim
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(7)
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Manual color editor for the selected timer.
    Item {
        parent: slideContent
        anchors.fill: parent
        visible: root.colorMode
        z: 10

        Text {
            x: 5
            y: 7
            width: parent.width - 10
            height: 15
            text: "Цвет таймера"
            color: Config.text
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(10)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Row {
            x: 7
            y: 29
            width: parent.width - 14
            height: 27
            spacing: 5

            Rectangle {
                width: 23
                height: 23
                anchors.verticalCenter: parent.verticalCenter
                radius: Config.scaledCornerRadius(4)
                color: /^#?[0-9a-fA-F]{6}$/.test(root.colorInputText)
                    ? (root.colorInputText.charAt(0) === "#" ? root.colorInputText : "#" + root.colorInputText)
                    : Config.settingsBackground
                border.color: Config.baseColor
                border.width: Config.inputBordersEnabled ? 1 : 0
            }

            Rectangle {
                width: parent.width - 28
                height: 27
                radius: Config.scaledCornerRadius(4)
                color: Config.settingsBackground
                border.color: colorInput.activeFocus ? Config.accent : Config.settingsBorder
                border.width: colorInput.activeFocus || Config.inputBordersEnabled ? 1 : 0

                TextInput {
                    id: colorInput
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    color: Config.text
                    selectionColor: Config.accent
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.uiFontSize(11)
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.colorInputText
                    Binding {
                        target: colorInput
                        property: "text"
                        value: root.colorInputText
                        when: !colorInput.activeFocus
                    }
                    focus: root.colorMode
                    activeFocusOnPress: true
                    activeFocusOnTab: true
                    selectByMouse: true
                    maximumLength: 7
                    onActiveFocusChanged: if (activeFocus) selectAll()
                    onTextChanged: root.colorInputText = text
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.saveColor()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            root.closeColorEditor()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 63
            spacing: 14

            Primitives.HoverIconButton {
                width: 24
                height: 23
                iconText: "✓"
                iconSize: 17
                baseColor: Config.accent
                iconFontFamily: Config.settingsFont
                hoverMode: "none"
                cursorShape: Qt.ArrowCursor
                toolTipText: "Сохранить"
                onClicked: root.saveColor()
            }

            Primitives.HoverIconButton {
                width: 24
                height: 23
                iconText: "×"
                iconSize: 17
                baseColor: Config.textDim
                iconFontFamily: Config.settingsFont
                hoverMode: "none"
                cursorShape: Qt.ArrowCursor
                toolTipText: "Отмена"
                onClicked: root.closeColorEditor()
            }
        }

        Text {
            x: 5
            y: 84
            width: parent.width - 10
            height: 10
            text: "HEX · #RRGGBB · Enter — сохранить"
            color: Config.textDim
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.uiFontSize(7)
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Column {
        parent: slideContent
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 5
        z: 1
        visible: !root.commentMode && !root.durationMode && !root.colorMode

        Text {
            text: root.selected ? (root.selected.time_passed || "") : ""
            color: root.selected && root.selected.color ? root.selected.color : Config.text
            font.family: Config.ledFont
            font.pixelSize: Config.uiFontSize(27)
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.actionIconItems.length * 18 + Math.max(0, root.actionIconItems.length - 1) * 2
            spacing: 2
            visible: root.actionIconItems.length > 0
            Repeater {
                model: root.actionIconItems
                delegate: Primitives.HoverIconButton {
                    width: 18
                    height: Math.max(24, modelData.size + 2)
                    iconText: modelData.icon
                    iconSize: modelData.size
                    toolTipText: modelData.id === "duration" ? "Изменить длительность" : ""
                    baseColor: root.selected && root.selected.color ? root.selected.color : Config.text
                    iconFontFamily: Config.font
                    // Preserve the popup's existing arrow cursor and no-hover styling.
                    hoverMode: "none"
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        if (modelData.id === "comment") {
                            root.commentFile = root.selectedFile
                            root.commentText = root.selected ? String(root.selected.comment || "") : ""
                            root.commentMode = true
                            root.durationMode = false
                            root.focusCommentInput()
                        } else if (modelData.id === "duration") {
                            root.openDurationEditor()
                        } else if (modelData.id === "color") {
                            root.openColorEditor()
                        } else {
                            Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", modelData.id, root.selectedFile])
                        }
                    }
                }
            }
        }
    }

    function openDurationEditor() {
        var minutes = Number(root.selected && root.selected.duration_minutes)
        if (!isFinite(minutes) || minutes < 1)
            minutes = 1
        root.durationInputText = String(Math.round(minutes))
        root.commentMode = false
        root.durationMode = true
        root.focusDurationInput()
    }

    function saveDuration() {
        var value = String(root.durationInputText || "").trim()
        if (!/^[0-9]{1,5}$/.test(value)) return
        var minutes = Number(value)
        if (!isFinite(minutes) || minutes < 1 || minutes > 10080) return
        if (!root.selectedFile) return
        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/timer",
            "set_duration",
            root.selectedFile,
            String(Math.round(minutes))
        ])
        root.durationMode = false
    }

    function closeDurationEditor() {
        root.durationMode = false
        root.durationInputText = ""
    }

    function openColorEditor() {
        root.commentMode = false
        root.durationMode = false
        root.colorInputText = String(root.selected && root.selected.color ? root.selected.color : "#ffffff")
        root.colorMode = true
        root.focusColorInput()
    }

    function saveColor() {
        var value = String(root.colorInputText || "").trim()
        if (!/^#?[0-9a-fA-F]{6}$/.test(value) || !root.selectedFile) return
        if (value.charAt(0) === "#") value = value.slice(1)
        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/timer",
            "set_color",
            root.selectedFile,
            value.toLowerCase()
        ])
        root.colorMode = false
    }

    function closeColorEditor() {
        root.colorMode = false
        root.colorInputText = ""
    }

    function focusColorInput() {
        Qt.callLater(function() {
            Qt.callLater(function() {
                if (!root.colorMode || root.closing || !root.enabled) return
                colorInput.forceActiveFocus(Qt.OtherFocusReason)
                colorInput.cursorPosition = colorInput.text.length
                colorInput.selectAll()
            })
        })
    }

    function focusDurationInput() {
        // Like the comment editor, wait until the overlay keyboard focus has
        // been enabled before requesting TextInput focus.
        Qt.callLater(function() {
            Qt.callLater(function() {
                if (!root.durationMode || root.closing || !root.enabled) return
                durationInput.forceActiveFocus(Qt.OtherFocusReason)
                durationInput.cursorPosition = durationInput.text.length
                durationInput.selectAll()
            })
        })
    }

    function focusCommentInput() {
        // The owning fullscreen PanelWindow enables layer-shell keyboard
        // interactivity from commentMode. Wait two event-loop turns so the new
        // keyboard-focus state has propagated before focusing the text field.
        Qt.callLater(function() {
            Qt.callLater(function() {
                if (!root.commentMode || root.closing || !root.enabled) return
                commentInput.forceActiveFocus(Qt.OtherFocusReason)
                commentInput.cursorPosition = commentInput.text.length
                commentInput.selectAll()
            })
        })
    }

    onCommentModeChanged: {
        if (commentMode) focusCommentInput()
    }
    onColorModeChanged: {
        if (colorMode) focusColorInput()
    }

    function finishCloseOnce() {
        if (!closing || closeSignalSent) return
        closeSignalSent = true
        popupHasBeenShown = false
        // Once the configured exit transition (clipped slide or fade) has
        // completed, remove the card from the persistent overlay.
        popupContentVisible = false
        commentMode = false
        closeDurationEditor()
        closeColorEditor()
        closeFinished()
    }

    function startClose() {
        if (closing) return
        commentMode = false
        closeDurationEditor()
        closeColorEditor()
        closeSignalSent = false
        closing = true
        syncVisualState()
    }

    function updateSelected() {
        selected = null
        for (let i = 0; i < timers.length; ++i) {
            if (timers[i].file === selectedFile) {
                selected = timers[i]
                break
            }
        }
    }
    onSelectedFileChanged: {
        commentMode = false
        closeDurationEditor()
        closeColorEditor()
        updateSelected()
        if (selectedFile !== "") {
            if (!popupContentVisible) {
                // Start the content just outside the clipping viewport on the
                // configured edge. The fixed popup geometry never moves, so
                // the card cannot travel across the timer or overlap it.
                var style = Config.animationTimerOptionsVisibilityStyle
                slideOffsetX = slideTargetX(true, style)
                slideOffsetY = slideTargetY(true, style)
            }
            popupContentVisible = true
            popupHasBeenShown = true
            if (!closing) syncVisualState()
        } else if (!closing && popupHasBeenShown) {
            // Let the owning PopupWindow release its native grab before running
            // the visual close transition. The host then re-shows only a
            // click-through, non-grabbing surface for the exit animation.
            closeRequested()
        } else if (!closing) {
            syncVisualState()
        }
    }
    onTimersChanged: updateSelected()

    Component.onCompleted: {
        if (selectedFile !== "") {
            popupContentVisible = true
            popupHasBeenShown = true
        } else {
            popupContentVisible = false
        }
        syncVisualState()
    }
}
