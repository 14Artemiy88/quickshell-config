import QtQuick
import ".."
import Quickshell

Frame {
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
    opacity: closing || selectedFile === "" ? 0 : 1
    scale: closing || selectedFile === "" ? 0.97 : 1
    transformOrigin: Item.Center
    clip: true

    // Use the same small zoom + fade in both directions. Keeping the overlay
    // alive until the animation finishes prevents the popup from jumping.
    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }

    Timer {
        id: closeTimer
        interval: 280
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
    onSelectedFileChanged: updateSelected()
    onTimersChanged: updateSelected()
}
