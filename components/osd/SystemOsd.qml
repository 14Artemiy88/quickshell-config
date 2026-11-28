import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../primitives" as Primitives
import "../../js/player/PlayerImage.js" as PlayerImage
import "../../js/NotificationsGeometry.js" as NotificationsGeometry
import "../../js/notifications/NotificationAnimation.js" as NotificationAnimation
import "../.."

// Shared click-through shell OSD for PipeWire volume, media and DND state changes.
// Volume uses PipeWire notifications; media reuses the selected Player snapshot.
// DND observes the persisted Config property and primes its state after Settings loads.
PanelWindow {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property bool audioStateReady: false
    property int trackedSinkId: -1
    property real volume: 0
    property bool muted: false
    property bool osdVisible: false
    property bool windowActive: false
    property string presentationMode: "volume"
    property bool dndStateInitialized: false
    property bool dndEnabled: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaBackend: ""
    property string mediaImagePath: ""

    readonly property bool notificationIntegrationEnabled: Config.osdIntegrateWithNotifications === true
    readonly property real notificationUiScale: Config.moduleUiScale()
    readonly property var notificationTargetScreen: {
        var wanted = String((Settings.moduleMonitors || {}).notifications || Config.monitorName || "").trim().toLowerCase()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var candidate = Quickshell.screens[i]
            if (!candidate) continue
            if (wanted && (String(candidate.name || "").trim().toLowerCase() === wanted
                    || String(candidate.model || "").trim().toLowerCase() === wanted
                    || String(candidate).trim().toLowerCase() === wanted))
                return candidate
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }
    readonly property var notificationGeometry: Settings.geometryForLayout
        ? Settings.geometryForLayout("notifications")
        : ((Settings.geometry || {}).notifications || [-999999, 16, Config.notificationsCardWidth, 0])
    readonly property int notificationCardBaseWidth: Math.max(280, Math.min(600,
        Number(root.notificationGeometry && root.notificationGeometry[2]) || Number(Config.notificationsCardWidth) || 380))
    readonly property int notificationCardWidth: Math.round(root.notificationCardBaseWidth * root.notificationUiScale)
    readonly property int notificationCardPadding: Math.round(Math.max(0, Math.min(32, Number(Config.notificationsCardPadding))) * root.notificationUiScale)
    readonly property int notificationLeadingVisualSize: Math.round(Math.max(24, Math.min(72, Number(Config.notificationsLeadingVisualSize) || 48)) * root.notificationUiScale)
    readonly property int notificationLeadingVisualRadius: Math.max(0, Math.min(root.notificationLeadingVisualSize / 2,
        Math.round(Number(Config.notificationsLeadingVisualRadius) * root.notificationUiScale)))
    readonly property int notificationFrameRadius: Math.max(0,
        Math.round(Config.scaledCornerRadius(Config.frameRadius) * root.notificationUiScale))
    readonly property int notificationFrameBorderWidth: Settings.moduleFrames.notifications !== false && Config.cardBordersEnabled
        ? Math.max(1, Math.round(Config.frameBorderWidth * root.notificationUiScale)) : 0
    readonly property int notificationStackHeight: Math.max(0, Number(Settings.notificationsWindowHeight) || 0)
    readonly property int notificationStackGap: Math.round(12 * root.notificationUiScale)
    readonly property int integratedTextGap: Math.round(3 * root.notificationUiScale)
    readonly property int integratedAppNameLineHeight: Config.uiFontSize(Math.max(8, Math.min(24, Number(Config.notificationsAppNameFontSize) || 11))) + Math.round(2 * root.notificationUiScale)
    readonly property int integratedSummaryLineHeight: Config.uiFontSize(Math.max(8, Math.min(32, Number(Config.notificationsSummaryFontSize) || 14))) + Math.round(2 * root.notificationUiScale)
    readonly property int integratedBodyLineHeight: Config.uiFontSize(Math.max(8, Math.min(32, Number(Config.notificationsBodyFontSize) || 12))) + Math.round(2 * root.notificationUiScale)
    readonly property int integratedVolumeLineHeight: Math.max(Config.uiFontSize(14), Math.round(8 * root.notificationUiScale)) + Math.round(2 * root.notificationUiScale)
    readonly property int integratedTextBlockHeight: root.integratedAppNameLineHeight + root.integratedTextGap
        + root.integratedSummaryLineHeight + root.integratedTextGap
        + (root.presentationMode === "volume" ? root.integratedVolumeLineHeight : root.integratedBodyLineHeight)
    readonly property int notificationLeft: NotificationsGeometry.resolvedCoordinate(
        root.notificationGeometry, 0,
        root.notificationTargetScreen ? root.notificationTargetScreen.width : 1920,
        root.notificationCardWidth, 16)
    readonly property int notificationVerticalOffset: NotificationsGeometry.resolvedCoordinate(
        root.notificationGeometry, 1,
        root.notificationTargetScreen ? root.notificationTargetScreen.width : 1920,
        root.notificationCardWidth, 16)
    readonly property bool notificationBottomAnchored: String(Config.notificationsVerticalAnchor || "top") === "bottom"
    // Keep the familiar compact OSD proportions, but let the card grow when
    // font scale, module scale or notification padding would otherwise clip it.
    readonly property int integratedCardHeight: Math.max(
        Math.round((root.presentationMode === "media" ? 80 : 72) * root.notificationUiScale),
        Math.max(root.notificationLeadingVisualSize, root.integratedTextBlockHeight)
            + root.notificationCardPadding * 2 + Math.round(2 * root.notificationUiScale))
    readonly property string integratedAppName: root.presentationMode === "media" ? "Плеер" : "Система"
    readonly property string integratedSummary: root.presentationMode === "media" ? root.mediaTitle
        : (root.presentationMode === "dnd"
            ? (root.dndEnabled ? "Не беспокоить включён" : "Не беспокоить выключен")
            : "Громкость")
    readonly property string integratedDescription: root.presentationMode === "media"
        ? [root.mediaArtist, root.mediaBackend].filter(function(value) { return String(value || "").trim() !== "" }).join(" · ")
        : (root.presentationMode === "dnd"
            ? (root.dndEnabled ? "Всплывающие уведомления фильтруются" : "Обычный показ уведомлений")
            : (root.muted ? "Без звука" : "Уровень системного выхода"))

    readonly property string activeAnimationProfile: root.notificationIntegrationEnabled
        ? Config.animationNotificationsVisibilityProfile
        : (root.presentationMode === "media" ? Config.animationPlayerOsdMorphProfile
            : (root.presentationMode === "dnd" ? Config.animationNotificationsDndOsdMorphProfile : Config.animationVolumeOsdMorphProfile))
    readonly property int animationDuration: root.notificationIntegrationEnabled
        ? Config.animationDuration(Config.animationNotificationsMorphDuration, "appearance")
        : Config.animationDurationForProfile(
            true, root.activeAnimationProfile,
            root.presentationMode === "media" ? Config.playerOsdAnimationDuration
                : (root.presentationMode === "dnd" ? Config.notificationsDndOsdAnimationDuration : Config.volumeOsdAnimationDuration),
            "appearance")

    visible: root.windowActive
    screen: root.notificationIntegrationEnabled ? root.notificationTargetScreen : Quickshell.screens[0]
    implicitWidth: root.notificationIntegrationEnabled ? root.notificationCardWidth : 1
    implicitHeight: root.notificationIntegrationEnabled
        ? root.integratedCardHeight
        : Math.round((root.presentationMode === "media" ? 112 : 82) * Config.moduleUiScale())
    color: Config.transparent
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.right: !root.notificationIntegrationEnabled
    anchors.top: !root.notificationIntegrationEnabled || !root.notificationBottomAnchored
    anchors.bottom: root.notificationIntegrationEnabled && root.notificationBottomAnchored
    margins.left: root.notificationIntegrationEnabled ? root.notificationLeft : 0
    margins.top: root.notificationIntegrationEnabled
        ? (root.notificationBottomAnchored ? 0 : root.notificationVerticalOffset
            + (root.notificationStackHeight > 0 ? root.notificationStackHeight + root.notificationStackGap : 0))
        : (screen ? Math.round(screen.height * 0.10) : 64)
    margins.bottom: root.notificationIntegrationEnabled && root.notificationBottomAnchored
        ? root.notificationVerticalOffset
            + (root.notificationStackHeight > 0 ? root.notificationStackHeight + root.notificationStackGap : 0)
        : 0
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    function normalizedVolume(value) {
        var number = Number(value)
        if (!isFinite(number)) number = 0
        return Math.max(0, Math.min(100, number * 100))
    }

    function backendLabel(backend) {
        var id = String(backend || "").trim().toLowerCase()
        var labels = ({
            deadbeef: "DeaDBeeF",
            mopidy: "Mopidy",
            mpv: "mpv",
            spotify: "Spotify",
            "plasma-browser-integration": "Браузер",
            "org.telegram.desktop": "Telegram"
        })
        return labels[id] || id
    }

    function extractMediaTitle(snapshot) {
        var data = snapshot || ({})
        var backend = String(data.player || "").trim().toLowerCase()
        return String(backend === "deadbeef" ? (data.third_line || data.first_line || "") : (data.first_line || "")).trim()
    }

    function extractMediaArtist(snapshot) {
        var data = snapshot || ({})
        var backend = String(data.player || "").trim().toLowerCase()
        if (backend === "deadbeef" || backend === "mopidy")
            return String(data.text || "").trim()
        return String(data.second_line || "").trim()
    }

    function showMediaOsd(snapshot) {
        var data = snapshot && typeof snapshot === "object" ? snapshot : ({})
        var title = root.extractMediaTitle(data)
        if (!Config.playerOsdEnabled || !title)
            return false

        root.mediaTitle = title
        root.mediaArtist = root.extractMediaArtist(data)
        root.mediaBackend = root.backendLabel(data.player)
        var rawImage = String(data.image || "")
        if (rawImage.endsWith("/assets/1px.png") || rawImage.endsWith("/album_cover.png"))
            rawImage = ""
        root.mediaImagePath = rawImage ? PlayerImage.imageSourceForPath(rawImage, Quickshell.shellDir) : ""
        root.presentationMode = "media"
        root.windowActive = true
        root.osdVisible = true
        hideTimer.restart()
        unloadTimer.stop()
        return true
    }

    function showVolumeOsd() {
        if (!Config.volumeOsdEnabled)
            return false
        root.presentationMode = "volume"
        root.windowActive = true
        root.osdVisible = true
        hideTimer.restart()
        unloadTimer.stop()
        return true
    }

    function showDndOsd(enabled) {
        if (!Settings.notifications || !Config.notificationsDndOsdEnabled)
            return false
        root.dndEnabled = enabled === true
        root.presentationMode = "dnd"
        root.windowActive = true
        root.osdVisible = true
        hideTimer.restart()
        unloadTimer.stop()
        return true
    }

    function syncDndState() {
        var nextEnabled = Config.notificationsDoNotDisturb === true
        // Profile restoration and initial settings migration must not look like
        // user actions. Only compare DND after Settings reports that loading ended.
        if (!Settings.loaded) {
            root.dndEnabled = nextEnabled
            root.dndStateInitialized = false
            return
        }
        if (!root.dndStateInitialized) {
            root.dndEnabled = nextEnabled
            root.dndStateInitialized = true
            return
        }
        if (nextEnabled === root.dndEnabled)
            return
        root.dndEnabled = nextEnabled
        root.showDndOsd(nextEnabled)
    }

    function syncAudioState() {
        var currentSink = root.sink
        if (!currentSink || !currentSink.ready || !currentSink.audio) {
            root.audioStateReady = false
            root.trackedSinkId = -1
            return
        }

        var nextId = Number(currentSink.id)
        var nextVolume = root.normalizedVolume(currentSink.audio.volume)
        var nextMuted = Boolean(currentSink.audio.muted)

        // The initial bind and output-device changes only prime the snapshot;
        // they must not flash an OSD merely because the shell was started.
        if (!root.audioStateReady || root.trackedSinkId !== nextId) {
            root.trackedSinkId = nextId
            root.volume = nextVolume
            root.muted = nextMuted
            root.audioStateReady = true
            return
        }

        var volumeChanged = Math.abs(nextVolume - root.volume) >= 0.5
        var muteChanged = nextMuted !== root.muted
        root.volume = nextVolume
        root.muted = nextMuted
        if (volumeChanged || muteChanged)
            root.showVolumeOsd()
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: root.sink
        function onReadyChanged() { root.syncAudioState() }
    }

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { root.syncAudioState() }
        function onMutedChanged() { root.syncAudioState() }
    }

    onSinkChanged: {
        root.audioStateReady = false
        root.trackedSinkId = -1
        Qt.callLater(root.syncAudioState)
    }

    Connections {
        target: Config
        function onVolumeOsdEnabledChanged() {
            if (!Config.volumeOsdEnabled && root.presentationMode === "volume") {
                hideTimer.stop()
                root.osdVisible = false
                unloadTimer.restart()
            }
        }
        function onPlayerOsdEnabledChanged() {
            if (!Config.playerOsdEnabled && root.presentationMode === "media") {
                hideTimer.stop()
                root.osdVisible = false
                unloadTimer.restart()
            }
        }
        function onNotificationsDndOsdEnabledChanged() {
            if (!Config.notificationsDndOsdEnabled && root.presentationMode === "dnd") {
                hideTimer.stop()
                root.osdVisible = false
                unloadTimer.restart()
            }
        }
        function onNotificationsDoNotDisturbChanged() { root.syncDndState() }
    }

    Connections {
        target: Settings
        function onLoadedChanged() {
            if (Settings.loaded) root.syncDndState()
        }
    }

    Timer {
        id: hideTimer
        interval: Math.max(250, Number(root.presentationMode === "media" ? Config.playerOsdHideDelay
            : (root.presentationMode === "dnd" ? Config.notificationsDndOsdHideDelay : Config.volumeOsdHideDelay)) || 1400)
        repeat: false
        onTriggered: {
            root.osdVisible = false
            unloadTimer.restart()
        }
    }

    Timer {
        id: unloadTimer
        interval: Math.max(40, root.animationDuration + 40)
        repeat: false
        onTriggered: {
            if (!root.osdVisible)
                root.windowActive = false
        }
    }

    Primitives.AnimatedVisibility {
        anchors.fill: parent
        shown: root.osdVisible
        animationStyle: root.notificationIntegrationEnabled
            ? NotificationAnimation.effectiveStyle(Config.animationNotificationsVisibilityProfile, Config.animationNotificationsVisibilityStyle)
            : "fade"
        animationProfile: root.activeAnimationProfile
        duration: root.animationDuration

        Rectangle {
            anchors.centerIn: parent
            width: root.notificationIntegrationEnabled
                ? root.notificationCardWidth
                : (root.presentationMode === "media" ? 440 : (root.presentationMode === "dnd" ? 360 : 310))
            height: root.notificationIntegrationEnabled
                ? root.integratedCardHeight
                : (root.presentationMode === "media" ? 92 : (root.presentationMode === "dnd" ? 72 : 64))
            scale: root.notificationIntegrationEnabled ? 1 : Config.moduleUiScale()
            color: root.notificationIntegrationEnabled
                ? (Settings.moduleBackgrounds.notifications !== false ? Config.notificationsBackgroundColor : Config.transparent)
                : Config.background
            border.color: Config.baseColor
            border.width: root.notificationIntegrationEnabled
                ? root.notificationFrameBorderWidth
                : (Config.popupBordersEnabled ? Config.frameBorderWidth : 0)
            radius: root.notificationIntegrationEnabled
                ? root.notificationFrameRadius
                : Config.scaledCornerRadius(Config.frameRadius)
            antialiasing: true

            RowLayout {
                visible: root.notificationIntegrationEnabled
                anchors.fill: parent
                anchors.margins: root.notificationCardPadding
                spacing: Math.round(12 * root.notificationUiScale)

                Rectangle {
                    Layout.preferredWidth: root.notificationLeadingVisualSize
                    Layout.preferredHeight: root.notificationLeadingVisualSize
                    radius: root.notificationLeadingVisualRadius
                    color: Config.notificationsShowAppIconBackground ? Config.baseColor : Config.transparent
                    clip: true

                    Image {
                        id: integratedMediaCover
                        anchors.fill: parent
                        source: root.presentationMode === "media" ? root.mediaImagePath : ""
                        visible: root.presentationMode === "media" && status === Image.Ready
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                    }
                    Text {
                        anchors.fill: parent
                        visible: root.presentationMode !== "media" || integratedMediaCover.status !== Image.Ready
                        text: root.presentationMode === "volume"
                            ? (root.muted || root.volume <= 0 ? Config.volumeMutedIcon : Config.volumeIcon)
                            : (root.presentationMode === "dnd" ? "DND" : "")
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.uiFontSize(root.presentationMode === "dnd" ? 13 : 23)
                        font.bold: root.presentationMode === "dnd"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: root.integratedTextGap

                    Text {
                        Layout.fillWidth: true
                        text: root.integratedAppName
                        color: Config.notificationsAppNameColor || Config.text
                        font.family: Config.resolveFontFamily(Config.notificationsAppNameFont)
                        font.pixelSize: Config.uiFontSize(Math.max(8, Math.min(24, Number(Config.notificationsAppNameFontSize) || 11)))
                        font.bold: Config.notificationsAppNameBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.integratedSummary
                        color: Config.notificationsSummaryColor || Config.text
                        font.family: Config.resolveFontFamily(Config.notificationsSummaryFont)
                        font.pixelSize: Config.uiFontSize(Math.max(8, Math.min(32, Number(Config.notificationsSummaryFontSize) || 14)))
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.presentationMode !== "volume" && root.integratedDescription !== ""
                        text: root.integratedDescription
                        color: Config.notificationsBodyColor || Config.textMuted
                        font.family: Config.resolveFontFamily(Config.notificationsBodyFont)
                        font.pixelSize: Config.uiFontSize(Math.max(8, Math.min(32, Number(Config.notificationsBodyFontSize) || 12)))
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.presentationMode === "volume"
                        spacing: Math.round(8 * root.notificationUiScale)

                        Primitives.ProgressTrack {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(4, Math.round(6 * root.notificationUiScale))
                            value: root.muted ? 0 : root.volume
                            valueAnimationDuration: 110
                            valueAnimationProfile: Config.animationVolumeOsdMorphProfile
                            fillColor: Config.volumeFill
                            trackColor: Config.volumeTrack
                            radius: Config.volumeTrackRadius
                        }
                        Text {
                            Layout.preferredWidth: Math.round(54 * root.notificationUiScale)
                            text: root.muted ? "Mute" : String(Math.round(root.volume)) + "%"
                            color: Config.notificationsBodyColor || Config.textMuted
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.uiFontSize(14)
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            RowLayout {
                visible: !root.notificationIntegrationEnabled && root.presentationMode === "media"
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    radius: Math.max(0, Config.scaledCornerRadius(Config.frameRadius - 2))
                    color: Config.baseColor
                    clip: true

                    Image {
                        id: mediaCover
                        anchors.fill: parent
                        visible: status === Image.Ready
                        source: root.mediaImagePath
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                    }
                    Text {
                        anchors.fill: parent
                        visible: mediaCover.status !== Image.Ready
                        text: "\uF001"
                        color: Config.textMuted
                        font.family: Config.font
                        font.pixelSize: Config.uiFontSize(28)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.mediaBackend
                        color: Config.textMuted
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.uiFontSize(9)
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.mediaTitle
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.uiFontSize(14)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.mediaArtist !== ""
                        text: root.mediaArtist
                        color: Config.textMuted
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.uiFontSize(11)
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                visible: !root.notificationIntegrationEnabled && root.presentationMode === "dnd"
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 13

                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: Math.max(0, Config.scaledCornerRadius(Config.frameRadius - 2))
                    color: root.dndEnabled ? Config.accent : Config.baseColor
                    Text {
                        anchors.fill: parent
                        text: "DND"
                        color: root.dndEnabled ? Config.black : Config.text
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.uiFontSize(13)
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.dndEnabled ? "Не беспокоить включён" : "Не беспокоить выключен"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.uiFontSize(14)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.dndEnabled ? "Всплывающие уведомления фильтруются" : "Обычный показ уведомлений"
                        color: Config.textMuted
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.uiFontSize(10)
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            RowLayout {
                visible: !root.notificationIntegrationEnabled && root.presentationMode === "volume"
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 12

                Text {
                    Layout.preferredWidth: 27
                    Layout.fillHeight: true
                    text: root.muted || root.volume <= 0 ? Config.volumeMutedIcon : Config.volumeIcon
                    color: Config.text
                    font.pixelSize: Config.uiFontSize(23)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Primitives.ProgressTrack {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    value: root.muted ? 0 : root.volume
                    valueAnimationDuration: 110
                    valueAnimationProfile: Config.animationVolumeOsdMorphProfile
                    fillColor: Config.volumeFill
                    trackColor: Config.volumeTrack
                    radius: Config.volumeTrackRadius
                }

                Text {
                    Layout.preferredWidth: root.muted ? 62 : 40
                    Layout.fillHeight: true
                    text: root.muted ? "Без звука" : String(Math.round(root.volume)) + "%"
                    color: Config.text
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.uiFontSize(12)
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(root.syncAudioState)
        Qt.callLater(root.syncDndState)
    }
}
