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
    enabled: selectedFile !== "" && !closing
    opacity: 0
    scale: 0.97
    transformOrigin: Item.Center
    clip: true

    // The popup surface itself is transparent. Paint the widget background here
    // so it follows the current theme/settings without making the whole popup
    // surface opaque.
    Rectangle {
        anchors.fill: parent
        color: Config.background
        radius: Config.frameRadius
        antialiasing: true
        z: -2
    }

    // Frame border is drawn separately so the popup keeps the same appearance
    // as the other configured widgets.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0)
        border.color: Config.baseColor
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius
        antialiasing: true
        z: -1
    }

    // Do not use Behavior here: a Behavior with a runtime duration of 0 can
    // still produce a visual transition when the popup is created/destroyed.
    // The popup is animated only by these explicit animations.
    property bool closeSignalSent: false
    // Distinguish the initial empty state from a popup that is being dismissed.
    property bool popupHasBeenShown: false

    // Drive whichever visual properties the chosen timer animation style uses
    // through one group so popup lifetime follows actual transition completion.
    transform: Translate {
        id: popupTranslation
        x: 0
        y: 0
    }

    ParallelAnimation {
        id: visualTransition
        NumberAnimation {
            id: showOpacityAnimation
            target: root
            property: "opacity"
            easing.type: Config.easingType()
        }
        NumberAnimation {
            id: showScaleAnimation
            target: root
            property: "scale"
            easing.type: Config.easingType()
        }
        NumberAnimation {
            id: showXAnimation
            target: popupTranslation
            property: "x"
            easing.type: Config.easingType()
        }
        NumberAnimation {
            id: showYAnimation
            target: popupTranslation
            property: "y"
            easing.type: Config.easingType()
        }
        onFinished: root.finishCloseOnce()
    }

    function animationsActive() {
        return Config.animationTimerOptionsVisibilityStyle !== "none"
    }

    function slideOffsetX(style) {
        if (style === "slideLeft") return -root.width
        if (style === "slideRight") return root.width
        return 0
    }

    function slideOffsetY(style) {
        if (style === "slideUp") return -root.height
        if (style === "slideDown") return root.height
        return 0
    }

    function syncVisualState() {
        var hidden = closing || selectedFile === ""
        var style = Config.animationTimerOptionsVisibilityStyle
        var fadeEnabled = style === "fade"
        var targetOpacity = hidden && (fadeEnabled || style === "none") ? 0 : 1
        var targetScale = hidden && fadeEnabled ? 0.97 : 1
        var targetX = hidden ? slideOffsetX(style) : 0
        var targetY = hidden ? slideOffsetY(style) : 0

        visualTransition.stop()

        // An unselected popup is already hidden. Place it at its endpoint
        // directly rather than animating a phantom transition at startup.
        if (!closing && selectedFile === "" && !popupHasBeenShown) {
            opacity = targetOpacity
            scale = targetScale
            popupTranslation.x = targetX
            popupTranslation.y = targetY
            return
        }

        if (!animationsActive()) {
            opacity = targetOpacity
            scale = targetScale
            popupTranslation.x = targetX
            popupTranslation.y = targetY
            finishCloseOnce()
            return
        }

        var baseDuration = Math.max(0, Number(Config.animationTimerOptionsDuration) || 0)
        var duration = Config.animationDuration(baseDuration, "appearance")
        var slideXEnabled = style === "slideLeft" || style === "slideRight"
        var slideYEnabled = style === "slideUp" || style === "slideDown"

        showOpacityAnimation.from = opacity
        showOpacityAnimation.to = targetOpacity
        showOpacityAnimation.duration = fadeEnabled ? duration : 0
        showScaleAnimation.from = scale
        showScaleAnimation.to = targetScale
        showScaleAnimation.duration = fadeEnabled ? duration : 0
        showXAnimation.from = popupTranslation.x
        showXAnimation.to = targetX
        showXAnimation.duration = slideXEnabled ? duration : 0
        showYAnimation.from = popupTranslation.y
        showYAnimation.to = targetY
        showYAnimation.duration = slideYEnabled ? duration : 0

        if (showOpacityAnimation.duration <= 0
                && showScaleAnimation.duration <= 0
                && showXAnimation.duration <= 0
                && showYAnimation.duration <= 0) {
            opacity = targetOpacity
            scale = targetScale
            popupTranslation.x = targetX
            popupTranslation.y = targetY
            finishCloseOnce()
            return
        }
        visualTransition.start()
    }

    Connections {
        target: Config
        function onAnimationTimerOptionsVisibilityStyleChanged() { root.syncVisualState() }
    }

    // Closing on a click outside the mini-window is handled by the
    // fullscreen overlay in shell.qml. This window should only receive
    // clicks meant for its own controls.
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {}
    }

    // Comment editor uses the same popup surface and geometry as the timer
    // options window. This avoids a second xdg-popup with a different anchor
    // coordinate system and gives the input the popup's keyboard focus.
    Item {
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
            font.family: Config.settingsFont
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            x: 7
            y: 28
            width: parent.width - 14
            height: 27
            radius: 4
            color: Config.settingsBackground
            border.color: Config.settingsBorder
            border.width: 1

            TextInput {
                id: commentInput
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                color: Config.text
                selectionColor: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: 11
                verticalAlignment: TextInput.AlignVCenter
                text: root.commentText
                activeFocusOnPress: true
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
            font.family: Config.settingsFont
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            x: 7
            y: 76
            width: parent.width - 14
            height: 14
            text: "Esc — отменить"
            color: Config.textDim
            font.family: Config.settingsFont
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 5
        z: 1
        visible: !root.commentMode

        Text {
            text: root.selected ? (root.selected.time_passed || "") : ""
            color: root.selected && root.selected.color ? root.selected.color : Config.text
            font.family: Config.ledFont
            font.pixelSize: 27
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            x: 5
            width: parent.width - 10
            spacing: 10
            Repeater {
                model: [
                    ["󰃉", "comment"],
                    ["", "refresh"],
                    ["󰏤", "toggle_pause"]
                ]
                delegate: Primitives.HoverIconButton {
                    width: 18
                    height: 24
                    iconText: modelData[0]
                    iconSize: 22
                    baseColor: root.selected && root.selected.color ? root.selected.color : Config.text
                    iconFontFamily: Config.font
                    // Preserve the popup's existing arrow cursor and no-hover styling.
                    hoverMode: "none"
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        if (modelData[1] === "comment") {
                            root.commentFile = root.selectedFile
                            root.commentText = root.selected ? String(root.selected.comment || "") : ""
                            root.commentMode = true
                            Qt.callLater(function() {
                                commentInput.forceActiveFocus()
                                commentInput.selectAll()
                            })
                        } else {
                            Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", modelData[1], root.selectedFile])
                        }
                    }
                }
            }
        }
    }

    onCommentModeChanged: {
        if (commentMode) {
            Qt.callLater(function() {
                commentInput.forceActiveFocus()
                commentInput.selectAll()
            })
        }
    }

    function finishCloseOnce() {
        if (!closing || closeSignalSent) return
        closeSignalSent = true
        popupHasBeenShown = false
        closeFinished()
    }

    function startClose() {
        if (closing) return
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
        updateSelected()
        if (selectedFile !== "") {
            popupHasBeenShown = true
            if (!closing) syncVisualState()
        } else if (!closing && popupHasBeenShown) {
            // A cleared selection after opening is a real close transition,
            // not the initial hidden state at startup.
            startClose()
        } else if (!closing) {
            syncVisualState()
        }
    }
    onTimersChanged: updateSelected()

    Component.onCompleted: {
        if (selectedFile !== "") popupHasBeenShown = true
        syncVisualState()
    }
}
