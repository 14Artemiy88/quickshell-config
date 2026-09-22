import QtQuick
import ".."
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Frame {
    id: root
    property var player: ({})
    property string imagePath: root.player.image || ""

    Process {
        id: proc
        command: [Quickshell.shellDir + "/scripts/player"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.player = JSON.parse(this.text) } catch(e) {}
                proc.running = false
            }
        }
    }
    Timer { interval: 1000; running: Settings.loaded && Settings.player; repeat: true; triggeredOnStart: true; onTriggered: if (Settings.player && !proc.running) proc.running = true }

    Connections {
        target: Settings
        function onPlayerChanged() {
            if (Settings.player && !proc.running) proc.running = true
            else if (!Settings.player && proc.running) proc.running = false
        }
        function onLoadedChanged() {
            if (Settings.loaded && Settings.player && !proc.running) proc.running = true
        }
    }

    Image {
        anchors.fill: parent
        cache: true
        asynchronous: true
        source: root.imagePath !== "" && root.imagePath !== Quickshell.shellDir + "/assets/1px.png" ? "file://" + root.imagePath : ""
        fillMode: Image.PreserveAspectFit
        opacity: 0.9
    }

    Rectangle {
        anchors.fill: parent
        color: Config.playerOverlay
        opacity: 0.9
    }

    // With no cover/track information, keep "silence" exactly in the
    // center of the player rather than inheriting the metadata layout.
    Text {
        id: silenceText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 275
        text: (!root.player.image || root.player.image.endsWith("/assets/1px.png") || root.player.image.endsWith("/album_cover.png"))
              ? (root.player.player ? (root.player.text || Config.playerSilenceText) : Config.playerSilenceText) : ""
        color: Config.text
        font.family: Config.playerFont
        font.pixelSize: root.player.text?.length > 24 ? 25 : 40
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }

    // DeadBeeF data is ordered artist / album / title. The artist is the
    // prominent first line; other players keep their existing first line.
    Text {
        x: 0; y: 120; width: parent.width
        text: root.player.first_line || ""
        color: Config.text
        font.family: Config.playerMetaFont
        font.pixelSize: 14
        font.bold: root.player.player === "deadbeef"
        elide: Text.ElideRight
    }
    Text {
        x: 0; y: 140; width: parent.width
        text: root.player.second_line || ""
        color: Config.text
        font.family: Config.playerMetaFont
        font.pixelSize: 13
        elide: Text.ElideRight
    }
    Text {
        x: 0; y: 160; width: parent.width
        text: root.player.third_line || ""
        color: Config.text
        font.family: Config.playerMetaFont
        font.pixelSize: 13
        elide: Text.ElideRight
    }
    Text {
        id: pauseButton
        x: 5; y: 5; width: 24; height: 24
        text: root.player.status || ""
        color: Config.text
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text { x: parent.width - 60; y: 5; width: 60; horizontalAlignment: Text.AlignRight; text: root.player.timeleft || ""; color: Config.text; font.pixelSize: 11 }

    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "pause", root.player.player || ""]) }
    Text {
        x: 37; y: 5; width: 24; height: 24
        text: "󰒭"
        color: Config.text
        font.pixelSize: 22
        visible: !!root.player.player
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "next", root.player.player || ""]) }
    }
    Slider {
        id: progress
        x: 0; y: 180; width: parent.width; height: 5
        from: 0; to: 100
        value: Number(root.player.position || 0)
        background: Rectangle {
            x: 0
            y: 1
            width: parent.width
            height: 3
            color: Config.playerProgressTrack
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, progress.value)) / 100
                height: parent.height
                color: Config.accent
            }
        }
        handle: Item { implicitWidth: 0; implicitHeight: 0 }
        Binding {
            target: progress
            property: "value"
            value: Number(root.player.position || 0)
            when: !progress.pressed
        }
        onMoved: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "position", String(Math.round(value))])
    }
}
