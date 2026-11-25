import QtQuick
import "primitives" as Primitives
import "../js/player/PlayerImage.js" as PlayerImage
import ".."
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Primitives.ModuleFrame {
    id: root
    moduleName: "player"
    signal mopidyToggleRequested()
    property var player: ({})
    property string imagePath: root.player.image || ""

    // Share the exact local-path/URL normalization used by Dashboard artwork.
    function imageSourceForPath(value) {
        return PlayerImage.imageSourceForPath(value, Quickshell.shellDir)
    }

    Process {
        id: proc
        command: {
            var args = [Quickshell.shellDir + "/scripts/player", "--priority"]
            var priority = Config.playerPriority || []
            for (var i = 0; i < priority.length; ++i) {
                var item = priority[i]
                if (!item || item.enabled === false)
                    continue
                var backendId = String(item.id || "")
                if (backendId !== "")
                    args.push(backendId)
            }
            return args
        }
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
        source: root.imageSourceForPath(root.imagePath)
        fillMode: Image.PreserveAspectFit
        opacity: Config.playerCoverOpacity
    }

    Rectangle {
        anchors.fill: parent
        color: Config.playerOverlay
        opacity: Config.playerCoverOpacity
    }

    // Measure fallback labels at the smallest supported size. Short labels
    // keep their one-line HorizontalFit behavior; labels that still exceed the
    // configured width switch to a small, bounded multiline layout.
    TextMetrics {
        id: silenceMetrics
        font.family: Config.playerFont
        font.pixelSize: Config.playerSilenceLongFontSize
        text: silenceText.text
    }

    // With no cover/track information, keep "silence" exactly in the
    // center of the player rather than inheriting the metadata layout.
    Text {
        id: silenceText
        property bool needsMultiline: text.length > 0 && silenceMetrics.advanceWidth > width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Config.playerSilenceWidth
        maximumLineCount: needsMultiline ? 3 : 1
        // A stale/unreadable path used to suppress the fallback text even when
        // QtQuick could not load the cover. Use the actual Image status too.
        text: (!root.player.image || root.player.image.endsWith("/assets/1px.png") || root.player.image.endsWith("/album_cover.png") || coverImage.status === Image.Error || coverImage.status === Image.Null)
              ? (root.player.player ? (root.player.text || Config.playerSilenceText) : Config.playerSilenceText) : ""
        color: Config.text
        font.family: Config.playerFont
        font.pixelSize: needsMultiline ? Config.playerSilenceLongFontSize : Config.playerSilenceFontSize
        fontSizeMode: needsMultiline ? Text.FixedSize : Text.HorizontalFit
        minimumPixelSize: Config.playerSilenceLongFontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: needsMultiline ? Text.Wrap : Text.NoWrap
        elide: Text.ElideRight
        style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
        styleColor: Config.playerTextOutlineColor
    }

    // Metadata grows upward from a fixed bottom edge. The progress value is the
    // desired content height divided by the maximum three-line height, so changes
    // between one, two and three lines share the same geometry animation.
    readonly property real playerMetadataSpacing: Math.max(0, Config.playerMetaLineSpacing - Config.playerMetaSecondaryFontSize)
    readonly property int playerMetadataLineCount: (root.player.first_line ? 1 : 0)
                                                   + (root.player.second_line ? 1 : 0)
                                                   + (root.player.third_line ? 1 : 0)
    readonly property real playerMetadataTargetHeight: (root.player.first_line ? Math.max(0, Config.playerMetaFontSize) : 0)
                                                      + ((root.player.second_line ? 1 : 0) + (root.player.third_line ? 1 : 0)) * Math.max(0, Config.playerMetaSecondaryFontSize)
                                                      + Math.max(0, playerMetadataLineCount - 1) * playerMetadataSpacing
    readonly property real playerMetadataMaxHeight: Math.max(0, Config.playerMetaFontSize)
                                                    + 2 * Math.max(0, Config.playerMetaSecondaryFontSize)
                                                    + 2 * playerMetadataSpacing
    // Text glyphs (especially font descenders and Text.Outline) can paint a few
    // pixels below their nominal item height. Keep a small trailing clip buffer
    // so the last metadata row is not cut while preserving its original baseline.
    readonly property real playerMetadataClipSafety: 3
    property bool playerMetadataExpanding: true
    property real playerMetadataPreviousTargetHeight: playerMetadataTargetHeight
    onPlayerMetadataTargetHeightChanged: {
        playerMetadataExpanding = playerMetadataTargetHeight >= playerMetadataPreviousTargetHeight
        playerMetadataPreviousTargetHeight = playerMetadataTargetHeight
    }

    Primitives.MorphGeometry {
        id: playerMetadataMorph
        clip: true
        visible: root.playerMetadataTargetHeight > 0 || normalizedProgress > 0.001
        fromGeometry: Qt.rect(
            Config.playerMetadataXPadding,
            parent.height - Config.playerMetadataY,
            Math.max(0, parent.width - Config.playerMetadataXPadding * 2),
            0)
        toGeometry: Qt.rect(
            Config.playerMetadataXPadding,
            parent.height - Config.playerMetadataY - root.playerMetadataMaxHeight,
            Math.max(0, parent.width - Config.playerMetadataXPadding * 2),
            root.playerMetadataMaxHeight + root.playerMetadataClipSafety)
        progress: root.playerMetadataMaxHeight > 0 ? root.playerMetadataTargetHeight / root.playerMetadataMaxHeight : 0
        animationDuration: Config.animationDurationForProfile(Config.animationPlayerMorphEnabled, Config.animationPlayerMorphProfile, Config.animationPlayerMorphDuration, "appearance")
        animationProfile: Config.animationPlayerMorphProfile
        animationPhase: root.playerMetadataExpanding ? "enter" : "exit"
        animationEasing: Config.animationEasingType(Config.animationPlayerMorphProfile, root.playerMetadataExpanding ? "enter" : "exit")

        Column {
            anchors.fill: parent
            spacing: root.playerMetadataSpacing

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
        x: 0; y: Config.playerControlTopMargin + Config.playerTimeY
        width: parent.width - Config.playerTimeRightPadding
        horizontalAlignment: Text.AlignRight
        text: root.player.timeleft || ""
        color: Config.text
        font.family: Config.playerTimeFont
        font.pixelSize: Config.playerTimeFontSize
        style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
        styleColor: Config.playerTextOutlineColor
    }

    MouseArea {
        id: playbackToggleMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        // Keep this as the background click target: the Next button and progress
        // slider are later/higher interactive children, while plain metadata and
        // cover areas still toggle play/pause.
        onClicked: {
            var backend = String(root.player.player || "").trim().toLowerCase()
            if (backend !== "")
                Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "pause", backend])
        }
    }
    readonly property bool playerNextSupported: ["deadbeef", "mopidy", "spotify"].indexOf(String(root.player.player || "").toLowerCase()) !== -1
    property bool playerNextMorphInitialized: false
    property real playerNextMorphProgress: 0

    onPlayerNextSupportedChanged: {
        if (playerNextMorphInitialized)
            playerNextMorphProgress = playerNextSupported ? 1 : 0
    }

    Component.onCompleted: Qt.callLater(function() {
        root.playerNextMorphInitialized = true
        root.playerNextMorphProgress = root.playerNextSupported ? 1 : 0
    })

    Primitives.MorphGeometry {
        id: playerNextMorph
        fromGeometry: Qt.rect(
            Config.playerControlTopMargin + Math.max(Config.playerPlayingIconSize, Config.playerPausedIconSize) + Config.playerControlGap + 1,
            Config.playerControlTopMargin + Config.playerNextIconY + 1,
            Math.max(0, Config.playerNextIconSize),
            Math.max(0, Config.playerNextIconSize))
        toGeometry: Qt.rect(
            Config.playerControlTopMargin + Math.max(Config.playerPlayingIconSize, Config.playerPausedIconSize) + Config.playerControlGap,
            Config.playerControlTopMargin + Config.playerNextIconY,
            Config.playerNextIconSize + 2,
            Config.playerNextIconSize + 2)
        progress: root.playerNextMorphProgress
        visible: root.playerNextSupported || normalizedProgress > 0.001
        animationDuration: Config.animationDurationForProfile(Config.animationPlayerMorphEnabled, Config.animationPlayerMorphProfile, Config.animationPlayerMorphDuration, "appearance")
        animationProfile: Config.animationPlayerMorphProfile
        animationPhase: root.playerNextSupported ? "enter" : "exit"
        animationEasing: Config.animationEasingType(Config.animationPlayerMorphProfile, root.playerNextSupported ? "enter" : "exit")

        Primitives.HoverIconButton {
            anchors.fill: parent
            opacity: playerNextMorph.normalizedProgress
            scale: 0.96 + 0.04 * playerNextMorph.normalizedProgress
            transformOrigin: Item.Center
            iconText: Config.playerNextIcon
            iconSize: Config.playerNextIconSize
            baseColor: Config.text
            iconFontFamily: Config.font
            hoverMode: "none"
            cursorShape: Qt.PointingHandCursor
            interactionEnabled: root.playerNextSupported
            // Next is supported only by backends with an implemented next action.
            onClicked: Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "next", root.player.player || ""])
        }
    }
    property real pendingSeekPercent: -1
    property real pendingSeekDuration: -1
    property string pendingSeekPlayer: ""

    Timer {
        id: pendingSeekTimeout
        interval: 1000
        repeat: false
        onTriggered: root.clearPendingSeek()
    }

    function clearPendingSeek() {
        root.pendingSeekPercent = -1
        root.pendingSeekDuration = -1
        root.pendingSeekPlayer = ""
        pendingSeekTimeout.stop()
    }

    Connections {
        target: root
        function onPlayerChanged() {
            var pending = Number(root.pendingSeekPercent)
            if (pending < 0)
                return

            var current = Number(root.player.position || 0)
            var duration = Number(root.player.duration || 0)
            var player = root.player.player || ""

            if (
                player !== root.pendingSeekPlayer ||
                duration !== root.pendingSeekDuration ||
                Math.abs(current - pending) <= 0.5
            ) {
                root.clearPendingSeek()
            }
        }
    }

    function requestSeek(percent) {
        var target = Math.max(0, Math.min(100, Number(percent)))
        root.pendingSeekPercent = target
        root.pendingSeekDuration = Number(root.player.duration || 0)
        root.pendingSeekPlayer = root.player.player || ""
        pendingSeekTimeout.restart()
        // Do not assign to progress.value here: it has a declarative binding
        // to the live backend position. Assigning it imperatively destroys that
        // binding, leaving the bar stuck at the last seek target until QS restarts.
        // pendingSeekPercent already drives the optimistic value through the binding.

        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/player_pausing",
            "position",
            String(Math.round(target)),
            root.pendingSeekPlayer,
            String(root.pendingSeekDuration || "")
        ])
    }

    readonly property real playerProgressHeight: Math.max(1, Config.playerProgressTrackHeight)
    Primitives.MorphGeometry {
        id: playerProgressMorph
        // The outer slot remains fixed; only the live slider content scales and
        // fades with the shared transition progress, so the player layout never shifts.
        z: 1
        fromGeometry: Qt.rect(0, root.height - Config.playerProgressY - root.playerProgressHeight, root.width, root.playerProgressHeight)
        toGeometry: fromGeometry
        progress: Config.playerShowProgress ? 1 : 0
        visible: Config.playerShowProgress || normalizedProgress > 0.001
        enabled: Config.playerShowProgress
        animationDuration: Config.animationDurationForProfile(Config.animationPlayerMorphEnabled, Config.animationPlayerMorphProfile, Config.animationPlayerMorphDuration, "appearance")
        animationProfile: Config.animationPlayerMorphProfile
        animationPhase: Config.playerShowProgress ? "enter" : "exit"
        animationEasing: Config.animationEasingType(Config.animationPlayerMorphProfile, Config.playerShowProgress ? "enter" : "exit")

        Item {
            anchors.fill: parent
            opacity: playerProgressMorph.normalizedProgress
            scale: 0.96 + 0.04 * playerProgressMorph.normalizedProgress
            transformOrigin: Item.Center

            Slider {
                id: progress
                anchors.fill: parent
                from: 0; to: 100
                value: {
                    var current = Number(root.player.position || 0)
                    var duration = Number(root.player.duration || 0)
                    var player = root.player.player || ""
                    var pending = Number(root.pendingSeekPercent)

                    if (
                        pending >= 0 &&
                        root.pendingSeekPlayer === player &&
                        root.pendingSeekDuration === duration
                    ) {
                        return pending
                    }

                    return current
                }
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
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: function(eventPoint) {
                        var ratio = Math.max(0, Math.min(1, eventPoint.position.x / progress.width))
                        var target = progress.from + (progress.to - progress.from) * ratio
                        root.requestSeek(target)
                    }
                }
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
                onMoved: root.requestSeek(value)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.mopidyToggleRequested()
    }
}
