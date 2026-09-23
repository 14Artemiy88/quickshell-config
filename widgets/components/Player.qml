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
    Timer { interval: Config.playerUpdateInterval; running: Settings.loaded && Settings.player; repeat: true; triggeredOnStart: true; onTriggered: if (Settings.player && !proc.running) proc.running = true }

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
        id: coverImage
        anchors.fill: parent
        cache: true
        asynchronous: true
        source: root.imagePath !== "" && root.imagePath !== Quickshell.shellDir + "/assets/1px.png" ? "file://" + root.imagePath : ""
        fillMode: Image.PreserveAspectFit
        opacity: Config.playerCoverOpacity
    }

    Rectangle {
        anchors.fill: parent
        color: Config.playerOverlay
        opacity: Config.playerCoverOpacity
    }

    // With no cover/track information, keep "silence" exactly in the
    // center of the player rather than inheriting the metadata layout.
    Text {
        id: silenceText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Config.playerSilenceWidth
        text: (!root.player.image || root.player.image.endsWith("/assets/1px.png") || root.player.image.endsWith("/album_cover.png"))
              ? (root.player.player ? (root.player.text || Config.playerSilenceText) : Config.playerSilenceText) : ""
        color: Config.text
        font.family: Config.playerFont
        font.pixelSize: root.player.text?.length > 24 ? Config.playerSilenceLongFontSize : Config.playerSilenceFontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }

    // DeadBeeF data is ordered artist / album / title. The artist is the
    // prominent first line; other players keep their existing first line.
    Text {
        x: Config.playerMetadataXPadding; y: Config.playerMetadataY; width: parent.width - Config.playerMetadataXPadding * 2
        text: root.player.first_line || ""
        color: Config.text
        font.family: Config.playerMetaFont
        font.pixelSize: Config.playerMetaFontSize
        font.bold: Config.playerBoldArtist && root.player.player === "deadbeef"
        elide: Text.ElideRight
    }
    Text {
        x: Config.playerMetadataXPadding; y: Config.playerMetadataY + Config.playerMetaLineSpacing; width: parent.width - Config.playerMetadataXPadding * 2
        text: root.player.second_line || ""
        color: Config.text
        font.family: Config.playerMetaFont
        font.pixelSize: Config.playerMetaSecondaryFontSize
        elide: Text.ElideRight
    }
    Text {
        x: Config.playerMetadataXPadding; y: Config.playerMetadataY + Config.playerMetaLineSpacing * 2; width: parent.width - Config.playerMetadataXPadding * 2
        text: root.player.third_line || ""
        color: Config.text
        font.family: Config.playerMetaFont
        font.pixelSize: Config.playerMetaSecondaryFontSize
        elide: Text.ElideRight
    }
    Text {
        id: pauseButton
        x: Config.playerControlTopMargin; y: Config.playerControlTopMargin; width: Config.playerControlIconSize + 2; height: Config.playerControlIconSize + 2
        text: root.player.status || ""
        color: Config.text
        font.pixelSize: Config.playerControlIconSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text { x: 0; y: Config.playerControlTopMargin; width: parent.width - Config.playerTimeRightPadding; horizontalAlignment: Text.AlignRight; text: root.player.timeleft || ""; color: Config.text; font.pixelSize: Config.playerTimeFontSize }

    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "pause", root.player.player || ""]) }
    Text {
        x: Config.playerControlTopMargin + Config.playerControlIconSize + Config.playerControlGap; y: Config.playerControlTopMargin; width: Config.playerControlIconSize + 2; height: Config.playerControlIconSize + 2
        text: "󰒭"
        color: Config.text
        font.pixelSize: Config.playerControlIconSize
        visible: !!root.player.player
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "next", root.player.player || ""]) }
    }
    Slider {
        visible: Config.playerShowProgress
        id: progress
        x: 0; y: Config.playerProgressY; width: parent.width; height: Config.playerProgressHeight
        from: 0; to: 100
        value: Number(root.player.position || 0)
        background: Rectangle {
            x: 0
            y: Config.playerProgressTrackOffsetY
            width: parent.width
            height: Config.playerProgressTrackHeight
            color: Config.playerProgressTrack
            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, progress.value)) / 100
                height: parent.height
                color: Config.playerProgressFill
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
