pragma Singleton
import QtQuick

QtObject {
    // Core palette
    property color baseColor: "#006666"
    property color accent: "#00cccc"
    property color currentWeather: "#00cccc"
    property color background: "#4d000000"
    property color text: "#ffffff"
    property color textMuted: "#dddddd"
    property color textDim: "#cccccc"
    property color textDisabled: "#999999"
    property color black: "#000000"
    property color transparent: "transparent"

    // Surfaces / overlays
    property color playerOverlay: "#18000000"
    property color playerProgressTrack: "#33ffffff"
    property color playerProgressFill: "#00cccc"
    property color activeNetworkBackground: "#1a323232"
    property color calendarBackground: "#cc000000"
    property color mopidyBackground: "#cc000000"
    // Calendar appearance / navigation
    property string calendarPreviousIcon: "←"
    property string calendarNextIcon: "→"
    property int calendarPreviousSize: 18
    property int calendarNextSize: 18
    property int calendarArrowY: 0
    property int calendarPreviousX: 0
    property int calendarNextX: 0
    property int calendarTitleFontSize: 20
    property int calendarTitleY: 0
    property string calendarTitleFont: "LED"
    property int calendarWeekdayFontSize: 12
    property int calendarWeekdayY: 0
    property string calendarWeekdayFont: "JetBrainsMono Nerd Font"
    property int calendarDayFontSize: 14
    property int calendarDayY: 0
    property string calendarDayFont: "JetBrainsMono Nerd Font"
    property string calendarNoteMarkerStyle: "dot"
    property string calendarNoteMarkerPosition: "bottomCenter"
    property color calendarNoteFrameColor: "#00cccc"
    property color volumeTrack: "#99006666"
    property color volumeFill: "#006666"
    property color settingsBackground: "#e6000000"
    property color settingsBorder: "#00cccc"
    property color settingsSubheading: "#00cccc"

    // Adaptive module minimum heights
    property int timerMinHeight: 72
    property int volumeMinHeight: 85
    property int volumeMaxHeight: 1200
    property int cavaBars: 75
    property int cavaFramerate: 30
    property int cavaRowSpacing: 1
    property real cavaBarWidthRatio: 0.45
    property string cavaMode: "both"

    // General behaviour / update intervals
    property bool animationsEnabled: true
    property real animationSpeed: 1.0
    property string animationEasing: "OutCubic"
    // Per-module appearance/disappearance styles.
    property string animationCalendarVisibilityStyle: "fade"
    property string animationMopidyVisibilityStyle: "fade"
    property string animationTimerVisibilityStyle: "fade"
    property string animationSettingsVisibilityStyle: "fade"
    property bool animationAppearanceEnabled: true
    property bool animationMovementEnabled: true
    property bool animationSizeEnabled: true
    property bool animationExpansionEnabled: true
    property int animationTimerOptionsDuration: 280
    property int animationCalendarSlideDuration: 350
    property int animationCalendarFadeDuration: 250
    property int systemMonitorInterval: 1000
    property int cpuUpdateInterval: 1000
    property int playerUpdateInterval: 1000
    property int weatherNowIntervalMinutes: 20
    property int weatherHourlyIntervalMinutes: 60
    property int weatherDailyIntervalMinutes: 60
    property int weatherRetryDelayMinutes: 10
    property int weatherManualRefreshCooldownSeconds: 30

    // Timer tuning
    property int timerWheelStep: 1
    property int timerCommentWidth: 90
    property int timerCommentMaxLength: 10
    property int timerCommentGap: 14
    property int timerRowSpacing: 0
    property int timerRowTopMargin: 10
    property int timerRowRightMargin: 10
    property int timerButtonFadeDuration: 450
    property int timerButtonSlideDuration: 700
    property int timerButtonIconFadeDuration: 550
    property string timerIcon: "󰁫"
    property string timerIconOrder: "alarm-left"
    property int timerIconSize: 27
    property int timerIconX: 45
    property int timerIconY: 0
    property string timerAlarmIcon: "󰀠"
    property int timerAlarmIconSize: 23
    property int timerAlarmIconX: 8
    property int timerAlarmIconY: 0
    property bool timerFinishedImageEnabled: false
    property string timerFinishedImagePath: ""
    property bool timerFinishedBorderUsesTimerColor: true
    property bool timerFinishedBackgroundUsesTimerColor: false
    property color timerFinishedBackgroundColor: "#4d000000"
    property int timerFinishedImageWidth: 280
    property int timerFinishedImageMargin: 10
    // Legacy aliases kept for settings/profile compatibility.
    property int timerFinishedImageTopMargin: 10
    property int timerFinishedImageBottomMargin: 10
    property bool timerFinishedTitleUsesTimerColor: true
    property color timerFinishedTitleColor: "#ffffff"
    property int timerFinishedTitleFontSize: 18
    property string timerFinishedTitleFont: "JetBrainsMono Nerd Font"
    property int timerFinishedTitleAlignment: 1

    // CPU / RAM tuning
    property int cpuBarThickness: 8
    property int cpuBarWidth: 267
    property int cpuRowHeight: 17
    property int cpuRowSpacing: 0
    property int cpuLabelLeftPadding: 10
    property int cpuBarLeftOffset: 35
    property int cpuBarRadius: 8
    property int cpuGraphSegmentSlotWidth: 6
    property int cpuGraphBarWidth: 2
    property bool cpuShowRam: true

    // Network display tuning
    property bool networkShowUpload: true
    property bool networkShowDownload: true
    property int networkRowHeight: 22
    property int networkRowSpacing: 0
    property int networkIconSize: 16
    property int networkValueFontSize: 13
    property int networkRightPadding: 5
    property int networkHorizontalPadding: 5
    property int networkIconLeftPadding: 10
    property int networkIconColumnWidth: 28

    // Volume tuning
    property int volumeUpdateInterval: 500
    property int volumeMainRowHeight: 32
    property int volumeStreamRowHeight: 20
    property int volumeStreamSpacing: 1
    property bool volumeShowStreams: true
    property int volumeHorizontalPadding: 12
    property int volumeVerticalPadding: 12
    property int volumeMainTrackWidth: 220
    property int volumeMainTrackHeight: 8
    property int volumeStreamTrackHeight: 8
    property int volumeMainTrackOffsetY: -3
    property int volumeStreamTrackOffsetY: 0
    property int volumeMainIconWidth: 25
    property string volumeIcon: "󰕾"
    property string volumeMutedIcon: "󰖁"
    property int volumeStreamLabelFontSize: 12
    property int volumeTrackRadius: 4

    // Player tuning
    property int playerSilenceFontSize: 40
    property bool playerTextOutlineEnabled: false
    property string playerTextOutlineColor: "#000000"
    property int playerSilenceLongFontSize: 25
    property int playerMetaFontSize: 14
    property int playerMetaSecondaryFontSize: 13
    property int playerMetaLineSpacing: 20
    property bool playerBoldArtist: true
    property bool playerShowProgress: true
    property int playerControlIconSize: 22
    property int playerPlayingIconSize: 22
    property int playerPausedIconSize: 22
    property int playerNextIconSize: 22
    property int playerPlayingIconY: 0
    property int playerPausedIconY: 0
    property int playerNextIconY: 0
    property string playerPlayingIcon: "\uF04C"
    property string playerPausedIcon: "\uF04B"
    property string playerNextIcon: "󰒭"
    property bool playerBlurEnabled: false
    property int playerBlurRadius: 10
    property int playerMetadataXPadding: 0
    property int playerMetadataY: 0
    property int playerProgressY: 0
    property int playerProgressTrackHeight: 3
    property int playerControlTopMargin: 5
    property int playerControlGap: 8
    property int playerTimeFontSize: 11
    property string playerTimeFont: "Ubuntu Mono Nerd Font"
    property int playerTimeRightPadding: 0
    property real playerCoverOpacity: 0.9
    property int playerSilenceWidth: 275
    property int playerProgressTrackOffsetY: 1
    property var playerPriority: ([
        { id: "deadbeef", enabled: true },
        { id: "mopidy", enabled: true },
        { id: "mpv", enabled: true },
        { id: "spotify", enabled: true },
        { id: "plasma-browser-integration", enabled: true },
        { id: "org.telegram.desktop", enabled: true }
    ])
    // Mopidy module queue presentation
    property bool mopidyShowTrackNumbers: true
    property bool mopidyShowMoveButtons: true
    property string mopidyMoveUpIcon: "↑"
    property int mopidyMoveUpIconSize: 16
    property int mopidyMoveUpIconX: 0
    property int mopidyMoveUpIconY: 0
    property bool mopidyShowMoveUpIcon: true
    property string mopidyMoveDownIcon: "↓"
    property int mopidyMoveDownIconSize: 16
    property int mopidyMoveDownIconX: 0
    property int mopidyMoveDownIconY: 0
    property bool mopidyShowMoveDownIcon: true
    property bool mopidyGroupAlbums: true
    property string mopidyAlbumFont: "JetBrainsMono Nerd Font"
    property int mopidyAlbumFontSize: 10
    property string mopidyTrackFont: "JetBrainsMono Nerd Font"
    property int mopidyTrackFontSize: 12
    property string mopidyArtistFont: "JetBrainsMono Nerd Font"
    property int mopidyArtistFontSize: 10
    property string mopidyDurationFont: "Ubuntu Mono Nerd Font"
    property int mopidyDurationFontSize: 11
    property string mopidyAlbumSeparator: "between-line"
    property bool mopidyAlbumBold: true
    property bool mopidyToggleWithPlayerRightClick: true
    property bool mopidyHideTopPanel: false
    property int mopidyTopPanelHoverHeight: 6
    property int mopidyTopPanelOffsetY: 6
    property string mopidyTopPanelBackground: "#cc000000"
    property string mopidyTopIconOrder: "stop,shuffle,repeat,volume,refresh,openAdd,clear"
    property string mopidyHoverMode: "background"
    property string mopidyHoverColor: "#1a323232"
    property string mopidyStopIcon: ""
    property int mopidyStopIconSize: 16
    property int mopidyStopIconX: 0
    property int mopidyStopIconY: 0
    property string mopidyRefreshIcon: ""
    property int mopidyRefreshIconSize: 16
    property int mopidyRefreshIconX: 0
    property int mopidyRefreshIconY: 0
    property string mopidyClearIcon: ""
    property int mopidyClearIconSize: 16
    property int mopidyClearIconX: 0
    property int mopidyClearIconY: 0
    property string mopidyControlIconColor: "#00cccc"
    property bool mopidyShowStopIcon: true
    property bool mopidyShowRefreshIcon: true
    property bool mopidyShowClearIcon: true
    property bool mopidyShowQueueTotalDuration: true
    property string mopidyQueueDurationMode: "total"
    property string mopidyQueueDurationFont: "Ubuntu Mono Nerd Font"
    property int mopidyQueueDurationFontSize: 11
    property string mopidyQueueDurationColor: "#aaaaaa"
    property int mopidyQueueDurationX: 0
    property int mopidyQueueDurationY: 0
    property bool mopidyShowAlbumRemaining: false
    property bool mopidyShowTrackRemaining: false
    property string mopidyShuffleIcon: ""
    property int mopidyShuffleIconSize: 16
    property int mopidyShuffleIconX: 0
    property int mopidyShuffleIconY: 0
    property bool mopidyShowShuffleIcon: true
    property string mopidyRepeatIcon: ""
    property int mopidyRepeatIconSize: 16
    property int mopidyRepeatIconX: 0
    property int mopidyRepeatIconY: 0
    property bool mopidyShowRepeatIcon: true
    property string mopidyOpenAddIcon: ""
    property int mopidyOpenAddIconSize: 16
    property int mopidyOpenAddIconX: 0
    property int mopidyOpenAddIconY: 0
    property bool mopidyShowOpenAddIcon: true
    property string mopidyAddIcon: ""
    property int mopidyAddIconSize: 16
    property int mopidyAddIconX: 0
    property int mopidyAddIconY: 0
    property bool mopidyShowAddIcon: true
    property string mopidySwitchPlaylistIcon: ""
    property int mopidySwitchPlaylistIconSize: 16
    property int mopidySwitchPlaylistIconX: 0
    property int mopidySwitchPlaylistIconY: 0
    property bool mopidyShowSwitchPlaylistIcon: true
    property string mopidyPlaylistDeleteIcon: ""
    property int mopidyPlaylistDeleteIconSize: 16
    property int mopidyPlaylistDeleteIconX: 0
    property int mopidyPlaylistDeleteIconY: 0
    property bool mopidyShowPlaylistDeleteIcon: true
    property string mopidyVolumeIcon: "󰕾"
    property string mopidyMutedIcon: "󰖁"
    property int mopidyVolumeIconSize: 16
    property int mopidyVolumeIconX: 0
    property int mopidyVolumeIconY: 0
    property int mopidyMutedIconSize: 16
    property int mopidyMutedIconX: 0
    property int mopidyMutedIconY: 0
    property bool mopidyShowVolumeIcon: true
    property bool mopidyShowVolumePercent: true
    property int mopidyVolumeStep: 5
    property string mopidyEmptyQueueText: "Очередь пуста"
    property string mopidyUnavailableText: "Недоступен"
    property string mopidyStatusFont: "JetBrainsMono Nerd Font"
    property int mopidyStatusFontSize: 16
    property int mopidyStatusLongFontSize: 11
    property int mopidyStatusWidth: 280

    // Weather tuning
    property int weatherIconSize: 55
    property int weatherArrowSize: 22
    property int weatherArrowYOffset: -8
    property int weatherWindArrowGap: 2
    property int weatherHourlyCount: 5
    property int weatherDailyCount: 4
    property int weatherIconY: 13
    property int weatherWindColumnX: 180
    property int weatherWindSpeedFontSize: 25
    property int weatherWindUnitFontSize: 15
    property int weatherPressureY: 33
    property int weatherDescriptionY: 58
    property int weatherDescriptionFontSize: 12
    property int weatherTempFontSize: 55
    property int weatherComfortFontSize: 35
    property bool weatherShowComfort: true
    property int weatherTempColumnWidth: 100
    property int weatherTempX: 10
    property int weatherTempWidth: 90
    property int weatherTempOffsetX: 0
    property int weatherTempOffsetY: 0
    property int weatherComfortY: 39
    property int weatherComfortOffsetX: 0
    property int weatherComfortOffsetY: 0
    property int weatherComfortHeight: 35
    property int weatherWindColumnWidth: 120
    property int weatherWindArrowWidth: 17
    property string weatherWindIcon: "\uF124"
    property int weatherWindArrowHeight: 35
    property int weatherWindSpeedX: 36
    property int weatherWindSpeedY: 4
    property int weatherWindSpeedWidth: 47
    property int weatherWindUnitX: 86
    property int weatherWindUnitY: 9
    property int weatherWindUnitWidth: 34
    property int weatherPressureValueWidth: 74
    property int weatherPressureFontSize: 20
    property int weatherPressureUnitX: 74
    property int weatherPressureUnitY: 9
    property int weatherPressureUnitFontSize: 10
    property int weatherDescriptionHeight: 16

    // Weather list geometry / typography
    // Weather hourly list
    property int weatherHourlyTopPadding: 8
    property int weatherHourlyDayY: 16
    property int weatherHourlyDayFontSize: 12
    property int weatherHourlyIconWidth: 35
    property int weatherHourlyIconY: 20
    property int weatherHourlyTempY: 65
    property int weatherHourlyTempHeight: 18
    property int weatherHourlyTempFontSize: 12

    // Weather daily list (maximum 4 columns)
    property int weatherDailyTopPadding: 8
    property int weatherDailyDayY: 16
    property int weatherDailyDayFontSize: 12
    property int weatherDailyIconWidth: 35
    property int weatherDailyIconY: 20
    property int weatherDailyHighTempX: 10
    property int weatherDailyHighTempY: 66
    property int weatherDailyHighTempFontSize: 11
    property int weatherDailyLowTempX: 5
    property int weatherDailyLowTempY: 86
    property int weatherDailyLowTempFontSize: 11

    // CPU / system metrics
    property color cpu1: "#ffb4bb"
    property color cpu2: "#ffe0ba"
    property color cpu3: "#fffebb"
    property color cpu4: "#baffc9"
    property color cpu5: "#bae1ff"
    property color cpu6: "#aedfdb"
    property color cpu7: "#75c8cc"
    property color cpu8: "#ead1f5"
    property color ram: "#3daee9"
    property color metricTrack: "#4d006666"
    property color ramTrack: "#4d3daee9"
    property color networkUpload: "#baffc9"
    property color networkDownload: "#ffb4bb"

    // Weather temperature palette
    property color tempHot: "#ff8989"
    property color tempWarm: "#ffb4bb"
    property color tempMild: "#ffe0ba"
    property color tempCool: "#fce3c4"
    property color tempZero: "#ffffff"
    property color tempCold: "#bae1ff"
    property color tempVeryCold: "#0ad1f3"
    property color tempFreezing: "#3c82e2"

    property string font: "JetBrainsMono Nerd Font"
    // Base size for ordinary interface text; specialized widgets keep their own sizes.
    property int fontSize: 12
    property string settingsFont: "JetBrainsMono Nerd Font"
    property int settingsFontSize: 12
    property int settingsPadding: 10
    property int settingsSpacing: 8
    property string ledFont: "LED"
    property string playerFont: "HARDBOR"
    property string playerMetaFont: "Ubuntu Mono Nerd Font"
    property string playerSilenceText: "silence"
    // Outer frame appearance
    property int frameBorderWidth: 1
    property int frameRadius: 7

    // Legacy/general corner radius used by small controls
    property int radius: 7

    function uiFontSize(baseSize) {
        var base = Number(baseSize)
        if (!isFinite(base) || base <= 0) base = 12
        var size = Number(fontSize)
        if (!isFinite(size) || size <= 0) size = 12
        return Math.max(6, Math.round(base * size / 12))
    }

    function settingsUiSize(baseSize) {
        var base = Number(baseSize)
        if (!isFinite(base) || base <= 0) base = 12
        var size = Number(settingsFontSize)
        if (!isFinite(size) || size <= 0) size = 12
        return Math.max(6, Math.round(base * size / 12))
    }

    function animationDuration(baseMs, category) {
        if (!animationsEnabled) return 0
        category = category || "appearance"
        if (category === "appearance" && !animationAppearanceEnabled) return 0
        if (category === "movement" && !animationMovementEnabled) return 0
        if (category === "size" && !animationSizeEnabled) return 0
        if (category === "expansion" && !animationExpansionEnabled) return 0
        var speed = Number(animationSpeed)
        if (!isFinite(speed) || speed <= 0) speed = 1
        var ms = Number(baseMs)
        if (!isFinite(ms) || ms < 0) ms = 0
        return Math.max(0, Math.round(ms / speed))
    }

    function easingType() {
        switch (animationEasing) {
        case "Linear": return Easing.Linear
        case "InOutQuad": return Easing.InOutQuad
        case "OutQuad": return Easing.OutQuad
        case "InOutCubic": return Easing.InOutCubic
        case "InCubic": return Easing.InCubic
        case "OutCubic": return Easing.OutCubic
        case "OutBack": return Easing.OutBack
        case "InOutBack": return Easing.InOutBack
        default: return Easing.OutCubic
        }
    }

    property string monitorName: "LCD195VXM+"
}
