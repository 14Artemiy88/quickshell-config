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
    signal mediaTrackChanged(var snapshot)
    property var player: ({})
    property bool mediaOsdSnapshotInitialized: false
    property string mediaOsdTrackSignature: ""

    function mediaOsdSignature(snapshot) {
        var data = snapshot && typeof snapshot === "object" ? snapshot : ({})
        var backend = String(data.player || "").trim().toLowerCase()
        if (!backend)
            return ""
        var title = backend === "deadbeef"
            ? String(data.third_line || data.first_line || "")
            : String(data.first_line || "")
        if (!title.trim())
            return ""
        var artist = (backend === "deadbeef" || backend === "mopidy")
            ? String(data.text || "") : String(data.second_line || "")
        var album = (backend === "deadbeef" || backend === "mopidy")
            ? String(data.second_line || "") : ""
        return [backend, title, artist, album].join("\u001f")
    }

    function acceptPlayerSnapshot(snapshot) {
        var data = snapshot && typeof snapshot === "object" ? snapshot : ({})
        var previousSignature = root.mediaOsdTrackSignature
        var nextSignature = root.mediaOsdSignature(data)
        var wasInitialized = root.mediaOsdSnapshotInitialized
        root.player = data
        root.mediaOsdSnapshotInitialized = true
        if (!nextSignature)
            return
        root.mediaOsdTrackSignature = nextSignature
        if (wasInitialized && nextSignature !== previousSignature)
            root.mediaTrackChanged(data)
    }
    property string imagePath: root.player.image || ""

    // Preserve the configured 315 px regular composition. Compact surfaces
    // scale the visual metrics down to fit; wide surfaces use spare width for
    // slightly larger typography and controls without changing backend state
    // or the user's saved geometry values.
    readonly property real playerPresentationScale: root.compactPresentation
        ? Math.max(0.72, Math.min(1, Number(root.width) / 315))
        : root.widePresentation ? Math.min(1.16, Math.max(1, Number(root.width) / 420)) : 1

    function scaledPlayerSize(value, minimumValue) {
        var raw = Number(value)
        if (!isFinite(raw) || raw <= 0)
            return isFinite(raw) ? raw : 0
        var minimum = minimumValue === undefined ? 1 : Number(minimumValue)
        return Math.max(minimum, Math.round(raw * root.playerPresentationScale))
    }

    function scaledPlayerOffset(value) {
        var raw = Number(value)
        return isFinite(raw) ? Math.round(raw * root.playerPresentationScale) : 0
    }

    readonly property int effectivePlayerSilenceFontSize: root.scaledPlayerSize(Config.playerSilenceFontSize, 8)
    readonly property int effectivePlayerSilenceLongFontSize: root.scaledPlayerSize(Config.playerSilenceLongFontSize, 8)
    readonly property int effectivePlayerMetaFontSize: root.scaledPlayerSize(Config.playerMetaFontSize, 8)
    readonly property int effectivePlayerMetaSecondaryFontSize: root.scaledPlayerSize(Config.playerMetaSecondaryFontSize, 8)
    readonly property int effectivePlayerMetaLineSpacing: root.scaledPlayerSize(Config.playerMetaLineSpacing, 1)
    readonly property int effectivePlayerPlayingIconSize: root.scaledPlayerSize(Config.playerPlayingIconSize, 8)
    readonly property int effectivePlayerPausedIconSize: root.scaledPlayerSize(Config.playerPausedIconSize, 8)
    readonly property int effectivePlayerNextIconSize: root.scaledPlayerSize(Config.playerNextIconSize, 8)
    readonly property int effectivePlayerTimeFontSize: root.scaledPlayerSize(Config.playerTimeFontSize, 8)
    readonly property int effectivePlayerMetadataXPadding: root.scaledPlayerSize(Config.playerMetadataXPadding, 0)
    readonly property int effectivePlayerMetadataY: root.scaledPlayerOffset(Config.playerMetadataY)
    readonly property int effectivePlayerProgressY: root.scaledPlayerOffset(Config.playerProgressY)
    readonly property int effectivePlayerProgressTrackHeight: root.scaledPlayerSize(Config.playerProgressTrackHeight, 1)
    readonly property int effectivePlayerProgressTrackOffsetY: root.scaledPlayerOffset(Config.playerProgressTrackOffsetY)
    readonly property int effectivePlayerControlTopMargin: root.scaledPlayerOffset(Config.playerControlTopMargin)
    readonly property int effectivePlayerControlGap: root.scaledPlayerSize(Config.playerControlGap, 0)
    readonly property int effectivePlayerTimeY: root.scaledPlayerOffset(Config.playerTimeY)
    readonly property int effectivePlayerTimeRightPadding: root.scaledPlayerSize(Config.playerTimeRightPadding, 0)
    readonly property int effectivePlayerPlayingIconY: root.scaledPlayerOffset(Config.playerPlayingIconY)
    readonly property int effectivePlayerPausedIconY: root.scaledPlayerOffset(Config.playerPausedIconY)
    readonly property int effectivePlayerNextIconY: root.scaledPlayerOffset(Config.playerNextIconY)
    readonly property int effectivePlayerSilenceWidth: {
        var configured = root.scaledPlayerSize(Config.playerSilenceWidth, 1)
        return root.compactPresentation ? Math.min(configured, Math.max(1, root.width - 12)) : configured
    }

    // The Dashboard can inspect every currently usable backend while it is
    // open and select one independently of the main Player widget's priority.
    property bool dashboardActive: false
    property var dashboardPlayers: []
    property string dashboardSelectedBackend: ""
    property var dashboardSelectedSnapshot: null
    property int dashboardSelectedMissingPolls: 0
    readonly property var dashboardPlayer: {
        var sources = Array.isArray(root.dashboardPlayers) ? root.dashboardPlayers : []
        var wanted = String(root.dashboardSelectedBackend || "").trim().toLowerCase()
        var current = String(root.player.player || "").trim().toLowerCase()
        for (var i = 0; i < sources.length; ++i) {
            var id = String(sources[i] && sources[i].player || "").trim().toLowerCase()
            if (wanted !== "" && id === wanted)
                return sources[i]
        }
        if (wanted === "") {
            for (var j = 0; j < sources.length; ++j) {
                var sourceId = String(sources[j] && sources[j].player || "").trim().toLowerCase()
                if (current !== "" && sourceId === current)
                    return sources[j]
            }
            if (sources.length > 0)
                return sources[0]
            return root.player
        }
        return root.player
    }
    readonly property int dashboardPlayerCount: Array.isArray(root.dashboardPlayers)
        ? root.dashboardPlayers.length : 0

    function setDashboardPlayers(value) {
        var incoming = Array.isArray(value) ? value : []
        var cleaned = []
        var seen = ({})
        for (var i = 0; i < incoming.length; ++i) {
            var item = incoming[i]
            var backend = String(item && item.player || "").trim().toLowerCase()
            if (!item || backend === "" || seen[backend])
                continue
            seen[backend] = true
            cleaned.push(item)
        }
        var selected = String(root.dashboardSelectedBackend || "").trim().toLowerCase()
        if (selected !== "" && seen[selected]) {
            for (var j = 0; j < cleaned.length; ++j) {
                if (String(cleaned[j].player || "").trim().toLowerCase() === selected) {
                    root.dashboardSelectedSnapshot = cleaned[j]
                    break
                }
            }
            root.dashboardSelectedMissingPolls = 0
        } else if (selected !== "" && root.dashboardSelectedSnapshot) {
            // A single backend probe can fail transiently (e.g. playerctl or
            // a CLI request races a track transition). Keep the last selected
            // payload for one scan so the selector and transport controls do
            // not disappear immediately after a successful switch.
            root.dashboardSelectedMissingPolls += 1
            if (root.dashboardSelectedMissingPolls <= 1) {
                cleaned.push(root.dashboardSelectedSnapshot)
                seen[selected] = true
            } else {
                root.dashboardSelectedBackend = ""
                root.dashboardSelectedSnapshot = null
                root.dashboardSelectedMissingPolls = 0
            }
        }
        root.dashboardPlayers = cleaned
    }

    function selectDashboardPlayer(backendValue) {
        var target = String(backendValue || "").trim().toLowerCase()
        if (target === "")
            return false
        for (var i = 0; i < root.dashboardPlayers.length; ++i) {
            if (String(root.dashboardPlayers[i].player || "").trim().toLowerCase() === target) {
                root.dashboardSelectedBackend = target
                root.dashboardSelectedSnapshot = root.dashboardPlayers[i]
                root.dashboardSelectedMissingPolls = 0
                return true
            }
        }
        return false
    }

    // Share the exact local-path/URL normalization used by Dashboard artwork.
    function imageSourceForPath(value) {
        return PlayerImage.imageSourceForPath(value, Quickshell.shellDir)
    }

    // Expose the same selected-backend play/pause action to Dashboard without
    // duplicating backend routing or bypassing this shared Player source.
    function togglePlayback() {
        return root.togglePlaybackForBackend(root.player.player)
    }

    function togglePlaybackForBackend(backendValue) {
        var backend = String(backendValue || "").trim().toLowerCase()
        if (backend === "")
            return false
        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/player_pausing",
            "pause",
            backend
        ])
        return true
    }

    function seekToPercentForBackend(backendValue, percent, durationValue) {
        var backend = String(backendValue || "").trim().toLowerCase()
        var target = Number(percent)
        var duration = Number(durationValue)
        if (backend === "" || !isFinite(target) || !isFinite(duration) || duration <= 0)
            return false
        target = Math.max(0, Math.min(100, target))
        // Retain the established optimistic seek path when the Dashboard is
        // controlling the same source as the main Player widget. Other active
        // sources are addressed explicitly and refreshed by the Dashboard scan.
        if (backend === String(root.player.player || "").trim().toLowerCase())
            return root.seekToPercent(target)
        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/player_pausing",
            "position",
            String(Math.round(target)),
            backend,
            String(duration)
        ])
        return true
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
                try { root.acceptPlayerSnapshot(JSON.parse(this.text)) } catch(e) {}
                proc.running = false
            }
        }
    }
    Timer { interval: Config.playerUpdateInterval; running: Settings.loaded && Settings.player; repeat: true; triggeredOnStart: true; onTriggered: if (Settings.player && !proc.running) proc.running = true }

    Process {
        id: dashboardPlayersProc
        command: {
            var args = [Quickshell.shellDir + "/scripts/player", "--all", "--priority"]
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
                try {
                    if (root.dashboardActive && Settings.player)
                        root.setDashboardPlayers(JSON.parse(this.text))
                } catch (e) {
                    // Retain the previous usable snapshot if a backend emits
                    // malformed output during a transient service transition.
                }
                dashboardPlayersProc.running = false
            }
        }
    }
    Timer {
        interval: Math.max(1600, Number(Config.playerUpdateInterval || 1000) * 2)
        running: Settings.loaded && Settings.player && root.dashboardActive
        repeat: true
        triggeredOnStart: true
        onTriggered: if (Settings.player && root.dashboardActive && !dashboardPlayersProc.running)
                         dashboardPlayersProc.running = true
    }
    onDashboardActiveChanged: {
        if (!root.dashboardActive) {
            root.dashboardPlayers = []
            root.dashboardSelectedBackend = ""
            root.dashboardSelectedSnapshot = null
            root.dashboardSelectedMissingPolls = 0
        } else if (Settings.player && !dashboardPlayersProc.running) {
            dashboardPlayersProc.running = true
        }
    }

    Connections {
        target: Settings
        function onPlayerChanged() {
            if (Settings.player && !proc.running) proc.running = true
            else if (!Settings.player && proc.running) proc.running = false
            if (!Settings.player) {
                root.mediaOsdSnapshotInitialized = false
                root.mediaOsdTrackSignature = ""
                root.dashboardPlayers = []
                root.dashboardSelectedBackend = ""
                root.dashboardSelectedSnapshot = null
                root.dashboardSelectedMissingPolls = 0
            } else if (root.dashboardActive && !dashboardPlayersProc.running) {
                dashboardPlayersProc.running = true
            }
        }
        function onLoadedChanged() {
            if (Settings.loaded && Settings.player && !proc.running) proc.running = true
            if (Settings.loaded && Settings.player && root.dashboardActive && !dashboardPlayersProc.running)
                dashboardPlayersProc.running = true
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
        font.pixelSize: Config.uiFontSize(root.effectivePlayerSilenceLongFontSize)
        text: silenceText.text
    }

    // Give the player fallback/status label an independently configurable
    // outline. Render small offset copies behind the fill so the stroke width
    // is controllable (QtQuick Text.Outline does not expose a stroke width).
    readonly property var silenceOutlineOffsets: {
        var offsets = []
        var thickness = Math.max(0, Math.min(4, Math.round(Number(Config.playerSilenceOutlineWidth) || 0)))
        if (thickness <= 0)
            return offsets
        var radius = thickness * 0.5
        var sampleCount = 8
        for (var i = 0; i < sampleCount; ++i) {
            var angle = (Math.PI * 2 * i) / sampleCount
            offsets.push({ x: Math.cos(angle) * radius, y: Math.sin(angle) * radius })
        }
        return offsets
    }

    Repeater {
        model: root.silenceOutlineOffsets
        delegate: Text {
            z: 0
            x: silenceText.x + modelData.x
            y: silenceText.y + modelData.y
            width: silenceText.width
            height: silenceText.height
            text: silenceText.text
            color: Config.playerSilenceOutlineColor
            font.family: Config.playerFont
            font.pixelSize: Config.uiFontSize(silenceText.needsMultiline ? root.effectivePlayerSilenceLongFontSize : root.effectivePlayerSilenceFontSize)
            fontSizeMode: silenceText.needsMultiline ? Text.FixedSize : Text.HorizontalFit
            minimumPixelSize: root.effectivePlayerSilenceLongFontSize
            maximumLineCount: silenceText.needsMultiline ? 3 : 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: silenceText.needsMultiline ? Text.Wrap : Text.NoWrap
            elide: Text.ElideRight
        }
    }

    // With no cover/track information, keep "silence" exactly in the
    // center of the player rather than inheriting the metadata layout.
    Text {
        id: silenceText
        property bool needsMultiline: text.length > 0 && silenceMetrics.advanceWidth > width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: root.effectivePlayerSilenceWidth
        maximumLineCount: needsMultiline ? 3 : 1
        // A stale/unreadable path used to suppress the fallback text even when
        // QtQuick could not load the cover. Use the actual Image status too.
        text: (!root.player.image || root.player.image.endsWith("/assets/1px.png") || root.player.image.endsWith("/album_cover.png") || coverImage.status === Image.Error || coverImage.status === Image.Null)
              ? (root.player.player ? (root.player.text || Config.playerSilenceText) : Config.playerSilenceText) : ""
        color: Config.text
        font.family: Config.playerFont
        font.pixelSize: Config.uiFontSize(needsMultiline ? root.effectivePlayerSilenceLongFontSize : root.effectivePlayerSilenceFontSize)
        fontSizeMode: needsMultiline ? Text.FixedSize : Text.HorizontalFit
        minimumPixelSize: root.effectivePlayerSilenceLongFontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: needsMultiline ? Text.Wrap : Text.NoWrap
        elide: Text.ElideRight
        style: Text.Normal
    }

    // Metadata grows upward from a fixed bottom edge. The progress value is the
    // desired content height divided by the maximum three-line height, so changes
    // between one, two and three lines share the same geometry animation.
    readonly property real playerMetadataSpacing: Math.max(0, root.effectivePlayerMetaLineSpacing - root.effectivePlayerMetaSecondaryFontSize)
    readonly property int playerMetadataLineCount: (root.player.first_line ? 1 : 0)
                                                   + (root.player.second_line ? 1 : 0)
                                                   + (root.player.third_line ? 1 : 0)
    readonly property real playerMetadataTargetHeight: (root.player.first_line ? Math.max(0, root.effectivePlayerMetaFontSize) : 0)
                                                      + ((root.player.second_line ? 1 : 0) + (root.player.third_line ? 1 : 0)) * Math.max(0, root.effectivePlayerMetaSecondaryFontSize)
                                                      + Math.max(0, playerMetadataLineCount - 1) * playerMetadataSpacing
    readonly property real playerMetadataMaxHeight: Math.max(0, root.effectivePlayerMetaFontSize)
                                                    + 2 * Math.max(0, root.effectivePlayerMetaSecondaryFontSize)
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
            root.effectivePlayerMetadataXPadding,
            parent.height - root.effectivePlayerMetadataY,
            Math.max(0, parent.width - root.effectivePlayerMetadataXPadding * 2),
            0)
        toGeometry: Qt.rect(
            root.effectivePlayerMetadataXPadding,
            parent.height - root.effectivePlayerMetadataY - root.playerMetadataMaxHeight,
            Math.max(0, parent.width - root.effectivePlayerMetadataXPadding * 2),
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
                height: root.effectivePlayerMetaFontSize
                text: root.player.first_line || ""
                color: Config.text
                font.family: Config.playerMetaFont
                font.pixelSize: Config.uiFontSize(root.effectivePlayerMetaFontSize)
                font.bold: Config.playerBoldArtist || !!root.player.first_line
                elide: Text.ElideRight
                style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
                styleColor: Config.playerTextOutlineColor
            }
            Text {
                visible: !!root.player.second_line
                width: parent.width
                height: root.effectivePlayerMetaSecondaryFontSize
                text: root.player.second_line || ""
                color: Config.text
                font.family: Config.playerMetaFont
                font.pixelSize: Config.uiFontSize(root.effectivePlayerMetaSecondaryFontSize)
                elide: Text.ElideRight
                style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
                styleColor: Config.playerTextOutlineColor
            }
            Text {
                visible: !!root.player.third_line
                width: parent.width
                height: root.effectivePlayerMetaSecondaryFontSize
                text: root.player.third_line || ""
                color: Config.text
                font.family: Config.playerMetaFont
                font.pixelSize: Config.uiFontSize(root.effectivePlayerMetaSecondaryFontSize)
                elide: Text.ElideRight
                style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal
                styleColor: Config.playerTextOutlineColor
            }
        }
    }
    Text {
        id: pauseButton
        x: root.effectivePlayerControlTopMargin; y: root.effectivePlayerControlTopMargin + (root.player.status === "\uF04C" ? root.effectivePlayerPlayingIconY : root.effectivePlayerPausedIconY); width: (root.player.status === "\uF04C" ? root.effectivePlayerPlayingIconSize : root.effectivePlayerPausedIconSize) + 2; height: (root.player.status === "\uF04C" ? root.effectivePlayerPlayingIconSize : root.effectivePlayerPausedIconSize) + 2
        text: root.player.status === "\uF04C" ? Config.playerPlayingIcon : (root.player.status === "\uF04B" ? Config.playerPausedIcon : (root.player.status || ""))
        color: Config.text
        font.pixelSize: Config.uiFontSize(root.player.status === "\uF04C" ? root.effectivePlayerPlayingIconSize : root.effectivePlayerPausedIconSize)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        x: 0; y: root.effectivePlayerControlTopMargin + root.effectivePlayerTimeY
        width: parent.width - root.effectivePlayerTimeRightPadding
        horizontalAlignment: Text.AlignRight
        text: root.player.timeleft || ""
        color: Config.text
        font.family: Config.playerTimeFont
        font.pixelSize: Config.uiFontSize(root.effectivePlayerTimeFontSize)
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
            root.togglePlayback()
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
            root.effectivePlayerControlTopMargin + Math.max(root.effectivePlayerPlayingIconSize, root.effectivePlayerPausedIconSize) + root.effectivePlayerControlGap + 1,
            root.effectivePlayerControlTopMargin + root.effectivePlayerNextIconY + 1,
            Math.max(0, root.effectivePlayerNextIconSize),
            Math.max(0, root.effectivePlayerNextIconSize))
        toGeometry: Qt.rect(
            root.effectivePlayerControlTopMargin + Math.max(root.effectivePlayerPlayingIconSize, root.effectivePlayerPausedIconSize) + root.effectivePlayerControlGap,
            root.effectivePlayerControlTopMargin + root.effectivePlayerNextIconY,
            root.effectivePlayerNextIconSize + 2,
            root.effectivePlayerNextIconSize + 2)
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
            iconSize: root.effectivePlayerNextIconSize
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

    // Public seek entry point shared with Dashboard. Keep all optimistic
    // position state and backend routing inside the owning Player module.
    function seekToPercent(percent) {
        var duration = Number(root.player.duration || 0)
        var backend = String(root.player.player || "").trim()
        var target = Number(percent)
        if (backend === "" || !isFinite(duration) || duration <= 0 || !isFinite(target))
            return false
        root.requestSeek(Math.max(0, Math.min(100, target)))
        return true
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

    readonly property real playerProgressHeight: root.effectivePlayerProgressTrackHeight
    Primitives.MorphGeometry {
        id: playerProgressMorph
        // The outer slot remains fixed; only the live slider content scales and
        // fades with the shared transition progress, so the player layout never shifts.
        z: 1
        fromGeometry: Qt.rect(0, root.height - root.effectivePlayerProgressY - root.playerProgressHeight, root.width, root.playerProgressHeight)
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
                    y: root.effectivePlayerProgressTrackOffsetY
                    width: parent.width
                    height: root.effectivePlayerProgressTrackHeight
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
