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
    property color volumeTrack: "#99006666"
    property color volumeFill: "#006666"
    property color settingsBackground: "#e6000000"
    property color settingsBorder: "#00cccc"

    // Adaptive module minimum heights
    property int timerMinHeight: 72
    property int volumeMinHeight: 85
    property int volumeMaxHeight: 1200
    property int cavaBars: 75
    property int cavaFramerate: 30
    property int cavaRowHeight: 39
    property int cavaRowSpacing: 1
    property real cavaBarWidthRatio: 0.45
    property real cavaBarHeightScale: 0.39
    property int cavaBarMinHeight: 1

    // General behaviour / update intervals
    property bool animationsEnabled: true
    property real animationSpeed: 1.0
    property string animationEasing: "OutCubic"
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
    property int weatherRequestTimeoutSeconds: 10
    property int weatherManualRefreshCooldownSeconds: 30

    // Timer tuning
    property int timerWheelStep: 1
    property int timerCommentWidth: 90
    property int timerCommentMaxLength: 10
    property int timerCommentGap: 14
    property int timerRowTopMargin: 10
    property int timerRowRightMargin: 10
    property int timerButtonFadeDuration: 450
    property int timerButtonSlideDuration: 700
    property int timerButtonIconFadeDuration: 550

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
    property real cpuGraphScale: 0.35
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
    property int volumeStreamLabelFontSize: 12
    property int volumeTrackRadius: 4

    // Player tuning
    property int playerSilenceFontSize: 40
    property int playerSilenceLongFontSize: 25
    property int playerMetaFontSize: 14
    property int playerMetaSecondaryFontSize: 13
    property int playerMetaLineSpacing: 20
    property bool playerBoldArtist: true
    property bool playerShowProgress: true
    property int playerControlIconSize: 22
    property bool playerBlurEnabled: false
    property int playerBlurRadius: 10
    property int playerMetadataXPadding: 0
    property int playerMetadataY: 120
    property int playerProgressY: 180
    property int playerProgressHeight: 5
    property int playerProgressTrackHeight: 3
    property int playerControlTopMargin: 5
    property int playerControlGap: 8
    property int playerTimeFontSize: 11
    property int playerTimeRightPadding: 0
    property real playerCoverOpacity: 0.9
    property int playerSilenceWidth: 275
    property int playerProgressTrackOffsetY: 1

    // Weather tuning
    property int weatherIconSize: 55
    property int weatherArrowSize: 22
    property int weatherArrowYOffset: -8
    property int weatherWindArrowGap: 2
    property int weatherHourlyCount: 5
    property int weatherDailyCount: 4
    property int weatherListTopPadding: 8
    property int weatherIconY: 13
    property int weatherWindColumnX: 180
    property int weatherWindSpeedFontSize: 25
    property int weatherWindUnitFontSize: 15
    property int weatherPressureY: 33
    property int weatherDescriptionY: 58
    property int weatherDescriptionFontSize: 12
    property int weatherTempFontSize: 55
    property int weatherComfortFontSize: 35
    property int weatherTempColumnWidth: 100
    property int weatherTempX: 10
    property int weatherTempWidth: 90
    property int weatherComfortY: 39
    property int weatherComfortHeight: 35
    property int weatherWindColumnWidth: 120
    property int weatherWindArrowWidth: 17
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
    property int weatherListDayHeight: 16
    property int weatherListIconWidth: 35
    property int weatherListIconHeight: 45
    property int weatherListIconY: 20
    property int weatherListHourlyTempY: 65
    property int weatherListDailyTempY: 66
    property int weatherListLowTempY: 85
    property int weatherListTempHeight: 18
    property int weatherListDayFontSize: 12
    property int weatherListHourlyTempFontSize: 12
    property int weatherListDailyTempFontSize: 11
    property int weatherListLowTempFontSize: 11

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
    property string monitorNameMode: "name-or-model"
}
