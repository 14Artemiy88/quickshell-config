import QtQuick
import ".."
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

    function animationsActive() {
        return Config.animationsEnabled && Config.animationExpansionEnabled
    }

    function syncVisualState() {
        var targetOpacity = (closing || selectedFile === "") ? 0 : 1
        var targetScale = (closing || selectedFile === "") ? 0.97 : 1

        showOpacityAnimation.stop()
        showScaleAnimation.stop()

        if (!animationsActive()) {
            opacity = targetOpacity
            scale = targetScale
            return
        }

        var duration = Config.animationDuration(Config.animationTimerOptionsDuration, "expansion")
        showOpacityAnimation.from = opacity
        showOpacityAnimation.to = targetOpacity
        showOpacityAnimation.duration = duration
        showScaleAnimation.from = scale
        showScaleAnimation.to = targetScale
        showScaleAnimation.duration = duration
        showOpacityAnimation.start()
        showScaleAnimation.start()
    }

    Connections {
        target: Config
        function onAnimationsEnabledChanged() { root.syncVisualState() }
        function onAnimationExpansionEnabledChanged() { root.syncVisualState() }
    }

    Timer {
        id: closeTimer
        interval: Config.animationDuration(Config.animationTimerOptionsDuration, "expansion")
        repeat: false
        onTriggered: {
            root.closeFinished()
        }
    }

    // Closing on a click outside the mini-window is handled by the
    // fullscreen overlay in shell.qml. This window should only receive
    // clicks meant for its own controls.
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {}
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 5
        z: 1

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
                delegate: Item {
                    width: 18
                    height: 24
                    Text {
                        anchors.fill: parent
                        text: modelData[0]
                        color: root.selected && root.selected.color ? root.selected.color : Config.text
                        font.pixelSize: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/timer", modelData[1], root.selectedFile])
                    }
                }
            }
        }
    }

    function startClose() {
        if (closing) return
        closing = true
        syncVisualState()
        if (!animationsActive()) {
            closeFinished()
            return
        }
        closeTimer.restart()
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
        if (!closing) syncVisualState()
    }
    onTimersChanged: updateSelected()

    Component.onCompleted: syncVisualState()
}
