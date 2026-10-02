import QtQuick
import "." as Widgets
import ".."
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Widgets.Frame {
    id: root
    moduleName: "player"
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
        style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
        styleColor: Config.playerTextOutlineColor
    }

    // Metadata is anchored to the bottom: one visible line occupies the bottom row,
    // two lines occupy the two bottom rows, and three lines occupy all rows.
    Column {
        x: Config.playerMetadataXPadding
        width: parent.width - Config.playerMetadataXPadding * 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.playerMetadataY
        spacing: Math.max(0, Config.playerMetaLineSpacing - Config.playerMetaSecondaryFontSize)

        Text {
            visible: !!root.player.first_line
            width: parent.width
            height: Config.playerMetaFontSize
            text: root.player.first_line || ""
            color: Config.text
            font.family: Config.playerMetaFont
            font.pixelSize: Config.playerMetaFontSize
            font.bold: Config.playerBoldArtist || !!root.player.first_line
            elide: Text.ElideRight
            style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
            styleColor: Config.playerTextOutlineColor
        }
        Text {
            visible: !!root.player.second_line
            width: parent.width
            height: Config.playerMetaSecondaryFontSize
            text: root.player.second_line || ""
            color: Config.text
            font.family: Config.playerMetaFont
            font.pixelSize: Config.playerMetaSecondaryFontSize
            elide: Text.ElideRight
            style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
            styleColor: Config.playerTextOutlineColor
        }
        Text {
            visible: !!root.player.third_line
            width: parent.width
            height: Config.playerMetaSecondaryFontSize
            text: root.player.third_line || ""
            color: Config.text
            font.family: Config.playerMetaFont
            font.pixelSize: Config.playerMetaSecondaryFontSize
            elide: Text.ElideRight
            style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
            styleColor: Config.playerTextOutlineColor
        }
    }
    Text {
        id: pauseButton
        x: Config.playerControlTopMargin; y: Config.playerControlTopMargin + (root.player.status === "\uF04C" ? Config.playerPlayingIconY : Config.playerPausedIconY); width: (root.player.status === "\uF04C" ? Config.playerPlayingIconSize : Config.playerPausedIconSize) + 2; height: (root.player.status === "\uF04C" ? Config.playerPlayingIconSize : Config.playerPausedIconSize) + 2
        text: root.player.status === "\uF04C" ? Config.playerPlayingIcon : (root.player.status === "\uF04B" ? Config.playerPausedIcon : (root.player.status || ""))
        color: Config.text
        font.pixelSize: root.player.status === "\uF04C" ? Config.playerPlayingIconSize : Config.playerPausedIconSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        x: 0; y: Config.playerControlTopMargin
        width: parent.width - Config.playerTimeRightPadding
        horizontalAlignment: Text.AlignRight
        text: root.player.timeleft || ""
        color: Config.text
        font.family: Config.playerTimeFont
        font.pixelSize: Config.playerTimeFontSize
        style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
        styleColor: Config.playerTextOutlineColor
    }

    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "pause", root.player.player || ""]) }
    Text {
        x: Config.playerControlTopMargin + Math.max(Config.playerPlayingIconSize, Config.playerPausedIconSize) + Config.playerControlGap; y: Config.playerControlTopMargin + Config.playerNextIconY; width: Config.playerNextIconSize + 2; height: Config.playerNextIconSize + 2
        text: Config.playerNextIcon
        color: Config.text
        font.pixelSize: Config.playerNextIconSize
        visible: !!root.player.player
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "next", root.player.player || ""]) }
    }
    Slider {
        visible: Config.playerShowProgress
        id: progress
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.playerProgressY
        x: 0
        width: parent.width
        height: Math.max(1, Config.playerProgressTrackHeight)
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
