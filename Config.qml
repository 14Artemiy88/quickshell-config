pragma Singleton
import QtQuick
import "js/settings/SettingsLauncherProjects.js" as LauncherProjects

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
    // Keep Mopidy background as a plain string so its exact #AARRGGBB value
    // survives JSON snapshots, profile copies and reloads without QColor conversion.
    property string mopidyBackground: "#cc000000"
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
    property string calendarAdjacentDaysColor: "#777777"
    property string calendarWeekendColor: "#d98282"
    property bool calendarPastDaysColorEnabled: false
    property bool calendarAlwaysVisible: false
    property string calendarPastDaysColor: "#888888"
    property string calendarNoteMarkerStyle: "dot"
    property string calendarNoteMarkerPosition: "bottomCenter"
    property color calendarNoteFrameColor: "#00cccc"
    property color volumeTrack: "#99006666"
    property color volumeFill: "#006666"
    property color settingsBackground: "#e6000000"
    property color settingsBorder: "#00cccc"
    property color settingsSubheading: "#00cccc"
    // Customizable Settings sidebar names/order. Stable IDs keep internal section routing unchanged.
    property var settingsTabOrder: ["modules", "themes", "general", "timers", "player", "mopidy", "weather", "cava", "cpuRam", "network", "volume", "calendar", "launcher", "settingsWindow"]
    property var settingsTabLabels: ({
        modules: "Модули", themes: "Темы", general: "Общие", timers: "Таймеры",
        player: "Плеер", mopidy: "Mopidy", weather: "Погода", cava: "CAVA",
        cpuRam: "CPU/RAM", network: "Сеть", volume: "Громкость", calendar: "Календарь",
        launcher: "Лаунчер", settingsWindow: "Окно настроек"
    })
    // Shared compositor blur radius used by every independently enabled module.
    property int backgroundBlurRadius: 10

    // Launcher layout and dedicated window background; text, accent, and borders use the shared theme.
    property bool launcherEnabled: true
    property int launcherWidth: 720
    property int launcherHeight: 640
    property int launcherItemHeight: 56
    property int launcherItemRadius: 11
    property int launcherRadius: 22
    property real launcherBackdropOpacity: 0.55
    property color launcherBackground: "#e6000000"
    property string launcherTitleText: "LAUNCHER"
    property string launcherTitleFont: ""
    property int launcherTitleFontSize: 13
    property int launcherTitleY: 0
    property color launcherTitleColor: "#ffffff"
    property int launcherTitleLetterSpacing: 2
    property bool launcherTitleBold: true
    property string launcherSearchFont: ""
    property string launcherSearchPlaceholder: "Search..."
    property int launcherSearchFontSize: 17
    property int launcherSearchHeight: 58
    property int launcherSearchRadius: 14
    property color launcherSearchBackground: "transparent"
    property int launcherDefaultMode: 0
    property bool launcherShowResultCount: true
    property bool launcherCrossSearchProjects: true
    property bool launcherCrossSearchRunHistory: true
    property bool launcherCrossSearchCalculator: true
    property var launcherTabOrder: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    property var launcherTabVisible: [true, true, true, true, true, true, true, true, true, true]
    property var launcherTabLabels: ["Apps", "Run", "Windows", "Clipboard", "Power", "Network", "Packages", "Pass", "Projects", "Calculator"]
    property var launcherTabIcons: ["󰀻", "", "󰖯", "󰅇", "", "󰖩", "󱄅", "󰌋", "", "󰃬"]
    property var launcherProjects: LauncherProjects.defaults()

    // Adaptive module minimum heights
    property int timerMinHeight: 72
    property int volumeMinHeight: 85
    property int volumeMaxHeight: 1200
    property int cavaBars: 75
    property int cavaFramerate: 30
    property int cavaRowSpacing: 1
    property real cavaBarWidthRatio: 0.45
    property string cavaMode: "both"
    property bool cavaHideWhenSilent: false
    property bool cavaHideZeroBars: false

    // Module-specific appearance/disappearance settings. Shared global animation toggles were removed.
    // Per-module appearance/disappearance styles.
    property string animationCalendarVisibilityStyle: "fade"
    property string animationMopidyVisibilityStyle: "fade"
    property string animationTimerVisibilityStyle: "fade"
    property string animationTimerOptionsVisibilityStyle: "fade"
    property string animationSettingsVisibilityStyle: "fade"
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
    property bool timerCommentAlignFurthest: false
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
    property string cpuBarDirection: "leftToRight"
    property int cpuGraphSegmentSlotWidth: 6
    property int cpuGraphBarWidth: 2
    property string cpuGraphMode: "both"
    property bool cpuShowRam: true
    // Top Apps presentation
    property bool topAppsShowHeaders: true
    property string topAppsCpuHeaderTitle: "CPU"
    property string topAppsCpuHeaderSubtitle: "ДОЛЯ ОТ ВСЕГО CPU"
    property string topAppsRamHeaderTitle: "ПАМЯТЬ"
    property string topAppsRamHeaderSubtitle: "ТОП ПРОЦЕССОВ"
    property int topAppsHeaderTitleFontSize: 10
    property int topAppsHeaderSubtitleFontSize: 9
    property bool topAppsShowBars: true
    // Bar geometry is measured within each Top Apps row. X is row-relative;
    // Y is an offset from vertical center, keeping the default precisely aligned.
    property int topAppsBarX: 103
    property int topAppsBarY: 0
    property int topAppsBarHeight: 6
    property int topAppsBarWidth: 115
    property bool topAppsShowSystemRemainder: true
    property string topAppsSystemRemainderLabel: "Система/прочее"
    property string topAppsFont: "" // Empty means use the application font, preserving the previous default.
    property int topAppsFontSize: 12
    property int topAppsRowSpacing: 1
    property int topAppsTopOffset: 3
    property color topAppsCpuBarColor: "#00cccc"
    property color topAppsRamBarColor: "#3daee9"
    property color topAppsCpuBarTrackColor: "#4d006666"
    property color topAppsRamBarTrackColor: "#4d006666"

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
    property int playerPlayingIconSize: 22
    property int playerPausedIconSize: 22
    property int playerNextIconSize: 22
    property int playerPlayingIconY: 0
    property int playerPausedIconY: 0
    property int playerNextIconY: 0
    property string playerPlayingIcon: "\uF04C"
    property string playerPausedIcon: "\uF04B"
    property string playerNextIcon: "󰒭"
    // Legacy fields retained only to migrate older settings files. Runtime blur
    // enablement now lives in Settings.moduleBlurEnabled; the radius is shared.
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
    property int playerTimeY: 0
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
    property int mopidyTrackRowHeight: 38
    property string mopidyArtistFont: "JetBrainsMono Nerd Font"
    property int mopidyArtistFontSize: 10
    property bool mopidyArtistBold: false
    property bool mopidyArtistItalic: false
    property string mopidyTrackArtistDisplayMode: "two-lines" // "two-lines" or "one-line"
    property string mopidyTrackArtistSeparator: " · "
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
    property string mopidyQueueDurationAlignment: "right"
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
    property int weatherIconX: 113
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
    property string weatherComfortOutlineColor: "#000000"
    property int weatherComfortOutlineWidth: 1
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
    // Direction-specific wind glyphs avoid glyph-bearing shifts caused by rotating one asymmetric icon.
    property string weatherWindCalmIcon: ""
    property string weatherWindCalmFont: "JetBrainsMono Nerd Font"
    property string weatherWindNIcon: "↑"
    property string weatherWindNFont: "JetBrainsMono Nerd Font"
    property string weatherWindNEIcon: "↗"
    property string weatherWindNEFont: "JetBrainsMono Nerd Font"
    property string weatherWindEIcon: "→"
    property string weatherWindEFont: "JetBrainsMono Nerd Font"
    property string weatherWindSEIcon: "↘"
    property string weatherWindSEFont: "JetBrainsMono Nerd Font"
    property string weatherWindSIcon: "↓"
    property string weatherWindSFont: "JetBrainsMono Nerd Font"
    property string weatherWindSWIcon: "↙"
    property string weatherWindSWFont: "JetBrainsMono Nerd Font"
    property string weatherWindWIcon: "←"
    property string weatherWindWFont: "JetBrainsMono Nerd Font"
    property string weatherWindNWIcon: "↖"
    property string weatherWindNWFont: "JetBrainsMono Nerd Font"
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

    // Durations are controlled by each module's own animation settings.
    // The optional category argument remains accepted for existing call sites,
    // but no global category switch is allowed to override module choices.
    function animationDuration(baseMs, category) {
        var ms = Number(baseMs)
        if (!isFinite(ms) || ms < 0) ms = 0
        return Math.max(0, Math.round(ms))
    }

    function easingType() { return Easing.OutCubic }

    property string monitorName: "LCD195VXM+"
}
