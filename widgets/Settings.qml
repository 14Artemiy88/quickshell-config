pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

QtObject {
    id: root
    property bool loaded: false
    property string weatherToken: ""
    property var timerPresets: [5, 7, 15]
    property var timerPresetDefaults: [5, 7, 15]
    property bool time: true
    property bool cpu: true
    property bool cpuGraph: true
    property bool topApps: true
    property bool networkStat: true
    property bool weatherNow: true
    property bool weatherHourly: true
    property bool weatherDaily: true
    property bool timer: true
    property bool volumes: true
    property bool player: true
    property bool cava: true
    property bool networks: true
    property bool calendar: true
    // Temporary geometry used while dragging modules in layout-edit mode.
    // It is never persisted until the mouse button is released.
    property var layoutEditGeometry: ({})

    property var geometry: ({
        time: [3,5,315,55], cpu: [5,65,315,170], cpuGraph: [5,235,315,82],
        topApps: [5,322,315,198], networkStat: [5,526,313,55], weatherNow: [3,585,315,80],
        weatherHourly: [3,665,335,125], weatherDaily: [3,795,325,125], timer: [3,930,315,145],
        timerOptions: [325,888,90,95], calendar: [5,65,315,285], volumes: [331,72,275,210],
        player: [330,405,300,320], cava: [325,578,300,80], networks: [331,675,300,180]
    })
    // Geometry of the settings window itself: X, Y, Width, Height.
    property var settingsGeometry: [640, 40, 560, 850]
    // Named configuration profiles (first feature outside the original layout).
    property var profiles: ({})
    property var profileList: []
    property string activeProfile: ""
    property int profilesRevision: 0
    property var customThemes: ({})
    property string activeTheme: "14 Theme"
    property var themeDraft: ({})
    property string themeDraftSource: ""
    property int themeDraftRevision: 0
    readonly property var moduleNames: ["time","cpu","cpuGraph","topApps","networkStat","weatherNow","weatherHourly","weatherDaily","timer","volumes","player","cava","networks","calendar"]
    readonly property var moduleLabels: ({time:"Часы",cpu:"CPU",cpuGraph:"График CPU",topApps:"Top Apps",networkStat:"Сеть",weatherNow:"Погода сейчас",weatherHourly:"Погода по часам",weatherDaily:"Погода по дням",timer:"Таймеры",volumes:"Громкость",player:"Плеер",cava:"CAVA",networks:"Networks",calendar:"Календарь"})
    readonly property var colorNames: ["baseColor","accent","currentWeather","background","text","textMuted","textDim","textDisabled","calendarBackground","settingsBackground","settingsBorder","playerOverlay","playerProgressTrack","playerProgressFill","activeNetworkBackground","volumeTrack","volumeFill","cpu1","cpu2","cpu3","cpu4","cpu5","cpu6","cpu7","cpu8","ram","metricTrack","ramTrack","networkUpload","networkDownload","tempHot","tempWarm","tempMild","tempCool","tempZero","tempCold","tempVeryCold","tempFreezing"]
    // Built-in defaults used by the reset controls in the settings UI.
    // These values are intentionally taken from the current settings.json baseline.
    readonly property var defaultConfig: ({
        font: "JetBrainsMono Nerd Font",
        fontSize: 12,
        settingsFont: "JetBrainsMono Nerd Font",
        settingsFontSize: 13,
        settingsPadding: 15,
        settingsSpacing: 6,
        ledFont: "LED",
        playerFont: "HARDBOR",
        playerMetaFont: "Ubuntu Mono Nerd Font",
        playerSilenceText: "silence",
        animationsEnabled: true,
        animationSpeed: 1,
        animationTimerOptionsDuration: 280,
        animationCalendarSlideDuration: 350,
        animationCalendarFadeDuration: 250,
        systemMonitorInterval: 2000,
        cpuUpdateInterval: 1000,
        playerUpdateInterval: 1000,
        weatherNowIntervalMinutes: 20,
        weatherHourlyIntervalMinutes: 60,
        weatherDailyIntervalMinutes: 60,
        weatherRetryDelayMinutes: 10,
        weatherManualRefreshCooldownSeconds: 30,
        timerMinHeight: 72,
        volumeMinHeight: 85,
        volumeMaxHeight: 1200,
        timerWheelStep: 1,
        timerCommentWidth: 90,
        timerCommentMaxLength: 10,
        timerCommentGap: 18,
        timerRowTopMargin: 10,
        timerRowRightMargin: 10,
        timerButtonFadeDuration: 450,
        timerButtonSlideDuration: 700,
        timerButtonIconFadeDuration: 550,
        playerSilenceFontSize: 57,
        playerSilenceLongFontSize: 25,
        playerMetaFontSize: 12,
        playerMetaSecondaryFontSize: 11,
        playerMetaLineSpacing: 18,
        playerBoldArtist: true,
        playerShowProgress: true,
        playerControlIconSize: 16,
        playerBlurEnabled: true,
        playerBlurRadius: 10,
        playerMetadataXPadding: 0,
        playerMetadataY: 120,
        playerProgressY: 180,
        playerProgressHeight: 5,
        playerProgressTrackHeight: 3,
        playerControlTopMargin: 5,
        playerControlGap: 8,
        playerTimeFontSize: 11,
        playerTimeRightPadding: 0,
        playerCoverOpacity: 0.9,
        playerSilenceWidth: 275,
        playerProgressTrackOffsetY: 1,
        weatherIconSize: 55,
        weatherArrowSize: 20,
        weatherArrowYOffset: -3,
        weatherWindArrowGap: 22,
        weatherHourlyCount: 5,
        weatherDailyCount: 4,
        weatherListTopPadding: 10,
        weatherIconY: 13,
        weatherWindColumnX: 180,
        weatherWindSpeedFontSize: 25,
        weatherWindUnitFontSize: 15,
        weatherPressureY: 33,
        weatherDescriptionY: 58,
        weatherDescriptionFontSize: 12,
        weatherTempFontSize: 55,
        weatherComfortFontSize: 35,
        weatherTempColumnWidth: 100,
        weatherTempX: 10,
        weatherTempWidth: 90,
        weatherComfortY: 39,
        weatherComfortHeight: 35,
        weatherWindColumnWidth: 120,
        weatherWindArrowWidth: 17,
        weatherWindArrowHeight: 35,
        weatherWindSpeedX: 36,
        weatherWindSpeedY: 4,
        weatherWindSpeedWidth: 47,
        weatherWindUnitX: 86,
        weatherWindUnitY: 9,
        weatherWindUnitWidth: 34,
        weatherPressureValueWidth: 74,
        weatherPressureFontSize: 20,
        weatherPressureUnitX: 74,
        weatherPressureUnitY: 9,
        weatherPressureUnitFontSize: 10,
        weatherDescriptionHeight: 16,
        weatherListDayHeight: 16,
        weatherListIconWidth: 35,
        weatherListIconHeight: 45,
        weatherListIconY: 20,
        weatherListHourlyTempY: 65,
        weatherListDailyTempY: 66,
        weatherListLowTempY: 85,
        weatherListTempHeight: 18,
        weatherListDayFontSize: 12,
        weatherListHourlyTempFontSize: 12,
        weatherListDailyTempFontSize: 11,
        weatherListLowTempFontSize: 11,
        cavaBars: 50,
        cavaFramerate: 30,
        cavaRowHeight: 39,
        cavaRowSpacing: 1,
        cavaBarWidthRatio: 0.45,
        cavaBarHeightScale: 0.39,
        cavaBarMinHeight: 1,
        frameBorderWidth: 1,
        frameRadius: 5,
        cpuBarThickness: 8,
        cpuBarWidth: 267,
        cpuRowHeight: 17,
        cpuRowSpacing: 0,
        cpuLabelLeftPadding: 10,
        cpuBarLeftOffset: 35,
        cpuBarRadius: 8,
        cpuGraphSegmentSlotWidth: 6,
        cpuGraphBarWidth: 2,
        cpuGraphScale: 0.35,
        cpuShowRam: true,
        networkShowUpload: true,
        networkShowDownload: true,
        networkRowHeight: 22,
        networkRowSpacing: 0,
        networkIconSize: 16,
        networkValueFontSize: 13,
        networkRightPadding: 5,
        networkHorizontalPadding: 5,
        networkIconLeftPadding: 10,
        networkIconColumnWidth: 28,
        volumeUpdateInterval: 200,
        volumeMainRowHeight: 20,
        volumeStreamRowHeight: 18,
        volumeStreamSpacing: 1,
        volumeShowStreams: true,
        volumeHorizontalPadding: 12,
        volumeVerticalPadding: 12,
        volumeMainTrackWidth: 225,
        volumeMainTrackHeight: 8,
        volumeStreamTrackHeight: 6,
        volumeMainTrackOffsetY: -4,
        volumeStreamTrackOffsetY: 1,
        volumeMainIconWidth: 25,
        volumeStreamLabelFontSize: 11,
        volumeTrackRadius: 6,
        baseColor: "#ff006666",
        accent: "#ff00cccc",
        currentWeather: "#ff00cccc",
        background: "#4d000000",
        text: "#ffffffff",
        textMuted: "#ffdddddd",
        textDim: "#ffcccccc",
        textDisabled: "#ff999999",
        calendarBackground: "#cc000000",
        settingsBackground: "#e6000000",
        settingsBorder: "#ff00cccc",
        playerOverlay: "#18000000",
        playerProgressTrack: "#33ffffff",
        playerProgressFill: "#ff00cccc",
        activeNetworkBackground: "#1a323232",
        volumeTrack: "#99006666",
        volumeFill: "#ff006666",
        cpu1: "#ffffb4bb",
        cpu2: "#ffffe0ba",
        cpu3: "#fffffebb",
        cpu4: "#ffbaffc9",
        cpu5: "#ffbae1ff",
        cpu6: "#ffaedfdb",
        cpu7: "#ff75c8cc",
        cpu8: "#ffead1f5",
        ram: "#ff3daee9",
        metricTrack: "#4d006666",
        ramTrack: "#4d3daee9",
        networkUpload: "#ffbaffc9",
        networkDownload: "#ffffb4bb",
        tempHot: "#ffff8989",
        tempWarm: "#ffffb4bb",
        tempMild: "#ffffe0ba",
        tempCool: "#fffce3c4",
        tempZero: "#ffffffff",
        tempCold: "#ffbae1ff",
        tempVeryCold: "#ff0ad1f3",
        tempFreezing: "#ff3c82e2"
    })
    readonly property string defaultWeatherToken: "61f2622cb1aab8.95463029"
    readonly property var defaultTimerPresetDefaults: [5, 7, 15]
    readonly property var defaultGeometry: {"time":[3,6,315,58],"cpu":[5,70,315,170],"cpuGraph":[5,245,315,78],"topApps":[5,329,315,198],"networkStat":[5,527,313,55],"weatherNow":[3,587,315,80],"weatherHourly":[5,672,314,106],"weatherDaily":[5,784,314,117],"timer":[3,907,316,50],"timerOptions":[325,888,90,95],"calendar":[5,65,316,286],"volumes":[331,72,275,152],"player":[330,380,300,200],"cava":[330,588,300,80],"networks":[330,675,300,171]}
    readonly property var defaultSettingsGeometry: [615,71,656,850]
    readonly property var defaultModules: {"time":true,"cpu":true,"cpuGraph":true,"topApps":true,"networkStat":true,"weatherNow":true,"weatherHourly":true,"weatherDaily":true,"timer":true,"volumes":true,"player":true,"cava":true,"networks":true,"calendar":true}
    signal changed()
    signal saved()

    function applyObject(o) {
        if (!o) return
        if (o.weatherToken !== undefined) weatherToken = String(o.weatherToken)
        if (o.font !== undefined) Config.font = String(o.font)
        if (o.fontSize !== undefined) {
            var fs = Number(o.fontSize)
            if (isFinite(fs)) Config.fontSize = Math.max(6, Math.min(32, Math.round(fs)))
        }
        if (o.settingsFont !== undefined) Config.settingsFont = String(o.settingsFont)
        if (o.settingsFontSize !== undefined) {
            var sfs = Number(o.settingsFontSize)
            if (isFinite(sfs)) Config.settingsFontSize = Math.max(6, Math.min(32, Math.round(sfs)))
        }
        if (o.settingsPadding !== undefined) {
            var sp = Number(o.settingsPadding)
            if (isFinite(sp)) Config.settingsPadding = Math.max(0, Math.min(40, Math.round(sp)))
        }
        if (o.settingsSpacing !== undefined) {
            var ss = Number(o.settingsSpacing)
            if (isFinite(ss)) Config.settingsSpacing = Math.max(0, Math.min(40, Math.round(ss)))
        }
        if (o.ledFont !== undefined) Config.ledFont = String(o.ledFont)
        if (o.playerFont !== undefined) Config.playerFont = String(o.playerFont)
        if (o.playerMetaFont !== undefined) Config.playerMetaFont = String(o.playerMetaFont)
        if (o.playerSilenceText !== undefined) Config.playerSilenceText = String(o.playerSilenceText)

        // General behaviour / update intervals
        if (o.animationsEnabled !== undefined) Config.animationsEnabled = !!o.animationsEnabled
        if (o.animationSpeed !== undefined) {
            var as = Number(o.animationSpeed)
            if (isFinite(as)) Config.animationSpeed = Math.max(0.25, Math.min(4.0, as))
        }
        var animationNumberFields = [
            ["animationTimerOptionsDuration", 0, 5000],
            ["animationCalendarSlideDuration", 0, 5000],
            ["animationCalendarFadeDuration", 0, 5000]
        ]
        for (var af = 0; af < animationNumberFields.length; ++af) {
            var aname = animationNumberFields[af][0]
            if (o[aname] !== undefined) {
                var av = Number(o[aname])
                if (isFinite(av)) Config[aname] = Math.max(animationNumberFields[af][1], Math.min(animationNumberFields[af][2], Math.round(av)))
            }
        }
        if (o.systemMonitorInterval !== undefined) {
            var smi = Number(o.systemMonitorInterval)
            if (isFinite(smi)) Config.systemMonitorInterval = Math.max(200, Math.min(10000, Math.round(smi)))
        }
        if (o.cpuUpdateInterval !== undefined) {
            var cui = Number(o.cpuUpdateInterval)
            if (isFinite(cui)) Config.cpuUpdateInterval = Math.max(200, Math.min(10000, Math.round(cui)))
        }
        if (o.playerUpdateInterval !== undefined) {
            var pui = Number(o.playerUpdateInterval)
            if (isFinite(pui)) Config.playerUpdateInterval = Math.max(200, Math.min(10000, Math.round(pui)))
        }
        if (o.weatherNowIntervalMinutes !== undefined) {
            var wni = Number(o.weatherNowIntervalMinutes)
            if (isFinite(wni)) Config.weatherNowIntervalMinutes = Math.max(1, Math.min(1440, Math.round(wni)))
        }
        if (o.weatherHourlyIntervalMinutes !== undefined) {
            var whi = Number(o.weatherHourlyIntervalMinutes)
            if (isFinite(whi)) Config.weatherHourlyIntervalMinutes = Math.max(1, Math.min(1440, Math.round(whi)))
        }
        if (o.weatherDailyIntervalMinutes !== undefined) {
            var wdi = Number(o.weatherDailyIntervalMinutes)
            if (isFinite(wdi)) Config.weatherDailyIntervalMinutes = Math.max(1, Math.min(1440, Math.round(wdi)))
        }
        if (o.weatherRetryDelayMinutes !== undefined) {
            var wrd = Number(o.weatherRetryDelayMinutes)
            if (isFinite(wrd)) Config.weatherRetryDelayMinutes = Math.max(1, Math.min(1440, Math.round(wrd)))
        }
        if (o.weatherManualRefreshCooldownSeconds !== undefined) {
            var wrc = Number(o.weatherManualRefreshCooldownSeconds)
            if (isFinite(wrc)) Config.weatherManualRefreshCooldownSeconds = Math.max(5, Math.min(3600, Math.round(wrc)))
        }

        if (o.timerMinHeight !== undefined) {
            var tmh = Number(o.timerMinHeight)
            if (isFinite(tmh)) Config.timerMinHeight = Math.max(30, Math.min(1000, Math.round(tmh)))
        }
        if (o.volumeMinHeight !== undefined) {
            var vmh = Number(o.volumeMinHeight)
            if (isFinite(vmh)) Config.volumeMinHeight = Math.max(30, Math.min(1000, Math.round(vmh)))
        }
        if (o.volumeMaxHeight !== undefined) {
            var vxh = Number(o.volumeMaxHeight)
            if (isFinite(vxh)) Config.volumeMaxHeight = Math.max(100, Math.min(2000, Math.round(vxh)))
        }

        // CPU / RAM tuning
        var cpuNumberFields = [
            ["cpuBarThickness", 1, 30], ["cpuBarWidth", 40, 1000],
            ["cpuRowHeight", 10, 60], ["cpuRowSpacing", 0, 30],
            ["cpuLabelLeftPadding", 0, 40], ["cpuBarLeftOffset", 0, 200],
            ["cpuBarRadius", 0, 40], ["cpuGraphSegmentSlotWidth", 1, 20],
            ["cpuGraphBarWidth", 1, 10]
        ]
        for (var cf = 0; cf < cpuNumberFields.length; ++cf) {
            var cname = cpuNumberFields[cf][0]
            if (o[cname] !== undefined) {
                var cv = Number(o[cname])
                if (isFinite(cv)) Config[cname] = Math.max(cpuNumberFields[cf][1], Math.min(cpuNumberFields[cf][2], Math.round(cv)))
            }
        }
        if (o.cpuGraphScale !== undefined) {
            var cgs = Number(o.cpuGraphScale)
            if (isFinite(cgs)) Config.cpuGraphScale = Math.max(0.05, Math.min(2.0, cgs))
        }
        if (o.cpuShowRam !== undefined) Config.cpuShowRam = !!o.cpuShowRam

        // Network display tuning
        var networkNumberFields = [
            ["networkRowHeight", 12, 60], ["networkRowSpacing", 0, 30],
            ["networkIconSize", 8, 40], ["networkValueFontSize", 8, 32],
            ["networkRightPadding", 0, 40], ["networkHorizontalPadding", 0, 40],
            ["networkIconLeftPadding", 0, 40], ["networkIconColumnWidth", 16, 80]
        ]
        for (var nf = 0; nf < networkNumberFields.length; ++nf) {
            var nname = networkNumberFields[nf][0]
            if (o[nname] !== undefined) {
                var nv = Number(o[nname])
                if (isFinite(nv)) Config[nname] = Math.max(networkNumberFields[nf][1], Math.min(networkNumberFields[nf][2], Math.round(nv)))
            }
        }
        if (o.networkShowUpload !== undefined) Config.networkShowUpload = !!o.networkShowUpload
        if (o.networkShowDownload !== undefined) Config.networkShowDownload = !!o.networkShowDownload

        // Volume tuning
        var volumeNumberFields = [
            ["volumeUpdateInterval", 50, 5000], ["volumeMainRowHeight", 20, 80],
            ["volumeStreamRowHeight", 12, 60], ["volumeStreamSpacing", 0, 20],
            ["volumeHorizontalPadding", 0, 40], ["volumeVerticalPadding", 0, 40],
            ["volumeMainTrackWidth", 40, 1000], ["volumeMainTrackHeight", 1, 30],
            ["volumeStreamTrackHeight", 1, 20], ["volumeMainTrackOffsetY", -30, 30],
            ["volumeStreamTrackOffsetY", -20, 20], ["volumeMainIconWidth", 16, 80],
            ["volumeStreamLabelFontSize", 8, 32], ["volumeTrackRadius", 0, 20]
        ]
        for (var vf = 0; vf < volumeNumberFields.length; ++vf) {
            var vname = volumeNumberFields[vf][0]
            if (o[vname] !== undefined) {
                var vv = Number(o[vname])
                if (isFinite(vv)) Config[vname] = Math.max(volumeNumberFields[vf][1], Math.min(volumeNumberFields[vf][2], Math.round(vv)))
            }
        }
        if (o.volumeShowStreams !== undefined) Config.volumeShowStreams = !!o.volumeShowStreams

        // Timer tuning
        var timerNumberFields = [
            ["timerWheelStep", 1, 60], ["timerCommentWidth", 40, 300],
            ["timerCommentMaxLength", 1, 30], ["timerCommentGap", 0, 40],
            ["timerRowTopMargin", 0, 50], ["timerRowRightMargin", 0, 50],
            ["timerButtonFadeDuration", 0, 5000], ["timerButtonSlideDuration", 0, 5000],
            ["timerButtonIconFadeDuration", 0, 5000]
        ]
        for (var tf = 0; tf < timerNumberFields.length; ++tf) {
            var tname = timerNumberFields[tf][0]
            if (o[tname] !== undefined) {
                var tv = Number(o[tname])
                if (isFinite(tv)) Config[tname] = Math.max(timerNumberFields[tf][1], Math.min(timerNumberFields[tf][2], Math.round(tv)))
            }
        }

        // Player tuning
        var playerNumberFields = [
            ["playerSilenceFontSize", 8, 100], ["playerSilenceLongFontSize", 8, 100],
            ["playerMetaFontSize", 8, 48], ["playerMetaSecondaryFontSize", 8, 48],
            ["playerMetaLineSpacing", 0, 100], ["playerControlIconSize", 8, 64],
            ["playerMetadataXPadding", 0, 100], ["playerMetadataY", 0, 1000],
            ["playerProgressY", 0, 1000], ["playerProgressHeight", 1, 30],
            ["playerProgressTrackHeight", 1, 20], ["playerControlTopMargin", 0, 100],
            ["playerControlGap", 0, 100], ["playerTimeFontSize", 8, 48],
            ["playerTimeRightPadding", 0, 100], ["playerSilenceWidth", 100, 600],
            ["playerProgressTrackOffsetY", -10, 20]
        ]
        for (var pf = 0; pf < playerNumberFields.length; ++pf) {
            var pname = playerNumberFields[pf][0]
            if (o[pname] !== undefined) {
                var pv = Number(o[pname])
                if (isFinite(pv)) Config[pname] = Math.max(playerNumberFields[pf][1], Math.min(playerNumberFields[pf][2], Math.round(pv)))
            }
        }
        if (o.playerBoldArtist !== undefined) Config.playerBoldArtist = !!o.playerBoldArtist
        if (o.playerShowProgress !== undefined) Config.playerShowProgress = !!o.playerShowProgress
        if (o.playerBlurEnabled !== undefined) Config.playerBlurEnabled = !!o.playerBlurEnabled
        if (o.playerBlurRadius !== undefined) {
            var pbr = Number(o.playerBlurRadius)
            if (isFinite(pbr)) Config.playerBlurRadius = Math.max(0, Math.min(40, Math.round(pbr)))
        }
        if (o.playerCoverOpacity !== undefined) {
            var pco = Number(o.playerCoverOpacity)
            if (isFinite(pco)) Config.playerCoverOpacity = Math.max(0, Math.min(1, pco))
        }

        // Weather tuning
        var weatherNumberFields = [
            ["weatherIconSize", 16, 128], ["weatherArrowSize", 8, 64],
            ["weatherArrowYOffset", -40, 40], ["weatherWindArrowGap", -20, 40],
            ["weatherHourlyCount", 1, 12], ["weatherDailyCount", 1, 10],
            ["weatherListTopPadding", 0, 40], ["weatherIconY", -100, 100],
            ["weatherWindColumnX", 0, 500], ["weatherWindSpeedFontSize", 8, 64],
            ["weatherWindUnitFontSize", 6, 48], ["weatherPressureY", 0, 100],
            ["weatherDescriptionY", 0, 120], ["weatherDescriptionFontSize", 6, 48],
            ["weatherTempFontSize", 12, 96], ["weatherComfortFontSize", 8, 72],
            ["weatherTempColumnWidth", 40, 200], ["weatherTempX", 0, 200], ["weatherTempWidth", 20, 200],
            ["weatherComfortY", -20, 100], ["weatherComfortHeight", 10, 100], ["weatherWindColumnWidth", 60, 300],
            ["weatherWindArrowWidth", 8, 50], ["weatherWindArrowHeight", 15, 80],
            ["weatherWindSpeedX", 0, 250], ["weatherWindSpeedY", -20, 80], ["weatherWindSpeedWidth", 20, 150],
            ["weatherWindUnitX", 0, 300], ["weatherWindUnitY", -20, 80], ["weatherWindUnitWidth", 10, 120],
            ["weatherPressureValueWidth", 20, 180], ["weatherPressureFontSize", 8, 48],
            ["weatherPressureUnitX", 0, 300], ["weatherPressureUnitY", -20, 80], ["weatherPressureUnitFontSize", 6, 30],
            ["weatherDescriptionHeight", 8, 40],
            ["weatherListDayHeight", 10, 40], ["weatherListIconWidth", 16, 90], ["weatherListIconHeight", 16, 100],
            ["weatherListIconY", 0, 120], ["weatherListHourlyTempY", 0, 150], ["weatherListDailyTempY", 0, 150],
            ["weatherListLowTempY", 0, 180], ["weatherListTempHeight", 10, 50],
            ["weatherListDayFontSize", 6, 32], ["weatherListHourlyTempFontSize", 6, 32],
            ["weatherListDailyTempFontSize", 6, 32], ["weatherListLowTempFontSize", 6, 32]
        ]
        for (var wf = 0; wf < weatherNumberFields.length; ++wf) {
            var wname = weatherNumberFields[wf][0]
            if (o[wname] !== undefined) {
                var wv = Number(o[wname])
                if (isFinite(wv)) Config[wname] = Math.max(weatherNumberFields[wf][1], Math.min(weatherNumberFields[wf][2], Math.round(wv)))
            }
        }

        if (o.cavaBars !== undefined) Config.cavaBars = Math.max(8, Number(o.cavaBars) || Config.cavaBars)
        if (o.cavaFramerate !== undefined) Config.cavaFramerate = Math.max(1, Math.min(120, Math.round(Number(o.cavaFramerate) || Config.cavaFramerate)))
        if (o.cavaRowHeight !== undefined) Config.cavaRowHeight = Math.max(10, Math.min(200, Math.round(Number(o.cavaRowHeight) || Config.cavaRowHeight)))
        if (o.cavaRowSpacing !== undefined) Config.cavaRowSpacing = Math.max(0, Math.min(20, Math.round(Number(o.cavaRowSpacing) || Config.cavaRowSpacing)))
        if (o.cavaBarWidthRatio !== undefined) { var cbwr=Number(o.cavaBarWidthRatio); if (isFinite(cbwr)) Config.cavaBarWidthRatio=Math.max(0.05,Math.min(1,cbwr)) }
        if (o.cavaBarHeightScale !== undefined) { var cbhs=Number(o.cavaBarHeightScale); if (isFinite(cbhs)) Config.cavaBarHeightScale=Math.max(0.01,Math.min(2,cbhs)) }
        if (o.cavaBarMinHeight !== undefined) Config.cavaBarMinHeight=Math.max(1,Math.min(20,Math.round(Number(o.cavaBarMinHeight) || Config.cavaBarMinHeight)))
        if (o.frameBorderWidth !== undefined) {
            var bw = Number(o.frameBorderWidth)
            if (isFinite(bw)) Config.frameBorderWidth = Math.max(0, Math.min(20, Math.round(bw)))
        }
        if (o.frameRadius !== undefined) {
            var fr = Number(o.frameRadius)
            if (isFinite(fr)) Config.frameRadius = Math.max(0, Math.min(50, Math.round(fr)))
        }
        var presetSource = o.timerPresetDefaults instanceof Array ? o.timerPresetDefaults : o.timerPresets
        if (presetSource instanceof Array) {
            var presets = []
            for (var p = 0; p < presetSource.length; ++p) {
                var value = Number(presetSource[p])
                if (isFinite(value)) presets.push(Math.max(0, Math.round(value)))
            }
            timerPresetDefaults = presets
            timerPresets = presets.slice()
        }
        var modules = o.modules || {}
        for (var i=0; i<moduleNames.length; ++i) if (modules[moduleNames[i]] !== undefined) root[moduleNames[i]] = !!modules[moduleNames[i]]
        if (o.geometry) {
            var g = Object.assign({}, root.geometry)
            for (var k in o.geometry) if (o.geometry[k] && o.geometry[k].length === 4) g[k] = o.geometry[k].map(Number)
            geometry = g
        }
        if (o.settingsGeometry && o.settingsGeometry.length === 4) {
            settingsGeometry = o.settingsGeometry.map(Number)
        }
        var colors = o.colors || {}
        for (var j=0; j<colorNames.length; ++j) {
            var name = colorNames[j]
            if (colors[name] !== undefined) Config[name] = colors[name]
        }
        if (o.profiles !== undefined && o.profiles && typeof o.profiles === "object") {
            profiles = o.profiles
            rebuildProfileList()
        }
        if (o.customThemes !== undefined && o.customThemes && typeof o.customThemes === "object")
            customThemes = o.customThemes
        if (o.activeProfile !== undefined) activeProfile = String(o.activeProfile)
        if (o.activeTheme !== undefined) activeTheme = String(o.activeTheme)
        rebuildProfileList()
        loaded = true
        changed()
    }

    property var loader: null
    property var writer: null
    property string pendingWritePayload: ""

    property Component loaderComponent: Component {
        Process {
            command: [Quickshell.shellDir + "/scripts/settings", "get"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    try { root.applyObject(JSON.parse(this.text)) }
                    catch (e) { root.loaded = true; root.changed() }
                }
            }
        }
    }

    property Component writerComponent: Component {
        Process {
            id: writeProc
            property string payload: "{}"
            command: [Quickshell.shellDir + "/scripts/settings", "set-json", payload]
            stdout: StdioCollector {}
            onRunningChanged: {
                if (!running && root.pendingWritePayload !== "") {
                    payload = root.pendingWritePayload
                    root.pendingWritePayload = ""
                    Qt.callLater(function() { writeProc.running = true })
                }
            }
        }
    }

    Component.onCompleted: {
        loader = loaderComponent.createObject(root)
        writer = writerComponent.createObject(root)
    }

    function geometryForLayout(moduleName) {
        var live = root.layoutEditGeometry[moduleName]
        if (live && live.length === 4)
            return live
        return root.geometry[moduleName] || [0, 0, 100, 100]
    }

    function beginGeometryDrag(moduleName) {
        var source = root.geometry[moduleName] || [0, 0, 100, 100]
        var live = Object.assign({}, root.layoutEditGeometry)
        live[moduleName] = source.slice()
        root.layoutEditGeometry = live
    }

    function updateGeometryDrag(moduleName, x, y) {
        var source = root.geometry[moduleName] || [0, 0, 100, 100]
        var live = Object.assign({}, root.layoutEditGeometry)
        var a = (live[moduleName] || source).slice()
        a[0] = Math.round(Number(x))
        a[1] = Math.round(Number(y))
        live[moduleName] = a
        root.layoutEditGeometry = live
    }

    function endGeometryDrag(moduleName) {
        var live = root.layoutEditGeometry[moduleName]
        if (!live || live.length !== 4)
            return

        var g = Object.assign({}, root.geometry)
        var a = (g[moduleName] || [0, 0, 100, 100]).slice()
        a[0] = Math.round(Number(live[0]))
        a[1] = Math.round(Number(live[1]))
        g[moduleName] = a
        root.geometry = g

        var overrides = Object.assign({}, root.layoutEditGeometry)
        delete overrides[moduleName]
        root.layoutEditGeometry = overrides

        root.save()
    }

    function cancelGeometryDrag(moduleName) {
        var overrides = Object.assign({}, root.layoutEditGeometry)
        delete overrides[moduleName]
        root.layoutEditGeometry = overrides
    }

    function adjustGeometry(moduleName, index, delta) {
        var g = Object.assign({}, root.geometry)
        var a = (g[moduleName] || [0, 0, 100, 100]).slice()
        var current = Number(a[index])
        if (!isFinite(current)) current = index < 2 ? 0 : 100
        var next = current + Number(delta)
        if (index >= 2) next = Math.max(1, next)
        a[index] = next
        g[moduleName] = a
        root.geometry = g
        root.save()
    }

    function adjustSettingsGeometry(index, delta) {
        var a = (root.settingsGeometry || [640, 40, 560, 850]).slice()
        var current = Number(a[index])
        if (!isFinite(current)) current = index < 2 ? 0 : 560
        var next = current + Number(delta)
        if (index >= 2) {
            next = Math.max(index === 2 ? 320 : 240, next)
        }
        a[index] = next
        root.settingsGeometry = a
        root.save()
    }

    function updateTimerPreset(index, value) {
        setTimerPresetDefault(index, value)
    }

    function setTimerPresetDefault(index, value) {
        var defaults = (root.timerPresetDefaults || []).slice()
        if (index < 0 || index >= defaults.length) return
        var n = Number(value)
        if (!isFinite(n)) return
        n = Math.max(0, Math.round(n))
        defaults[index] = n
        root.timerPresetDefaults = defaults
        root.timerPresets = defaults.slice()
        root.save()
    }

    // Wheel changes are temporary runtime values; middle click restores the
    // configured default for the clicked preset button.
    function adjustTimerPreset(index, delta) {
        var a = (root.timerPresets || []).slice()
        if (index < 0 || index >= a.length) return
        var current = Number(a[index])
        if (!isFinite(current)) current = 0
        a[index] = Math.max(0, Math.round(current + Number(delta)))
        root.timerPresets = a
    }

    function adjustTimerPresetDefault(index, delta) {
        var defaults = (root.timerPresetDefaults || []).slice()
        if (index < 0 || index >= defaults.length) return
        var current = Number(defaults[index])
        if (!isFinite(current)) current = 0
        defaults[index] = Math.max(0, Math.round(current + Number(delta)))
        root.timerPresetDefaults = defaults
        root.timerPresets = defaults.slice()
        root.save()
    }

    function resetTimerPreset(index) {
        var defaults = root.timerPresetDefaults || []
        if (index < 0 || index >= defaults.length) return
        var a = (root.timerPresets || []).slice()
        a[index] = Number(defaults[index])
        root.timerPresets = a
    }

    function addTimerPreset(value) {
        var defaults = (root.timerPresetDefaults || []).slice()
        var n = Number(value)
        if (!isFinite(n)) n = 5
        n = Math.max(0, Math.round(n))
        defaults.push(n)
        root.timerPresetDefaults = defaults
        root.timerPresets = defaults.slice()
        root.save()
    }

    function removeTimerPreset(index) {
        var defaults = (root.timerPresetDefaults || []).slice()
        if (index < 0 || index >= defaults.length) return
        defaults.splice(index, 1)
        root.timerPresetDefaults = defaults
        root.timerPresets = defaults.slice()
        root.save()
    }

    function resetConfigKeys(names) {
        if (!(names instanceof Array)) return
        for (var i = 0; i < names.length; ++i) {
            var name = names[i]
            if (defaultConfig[name] !== undefined) Config[name] = defaultConfig[name]
        }
    }

    function resetModules() {
        for (var i = 0; i < moduleNames.length; ++i) root[moduleNames[i]] = !!defaultModules[moduleNames[i]]
        geometry = JSON.parse(JSON.stringify(defaultGeometry))
        save()
    }

    function resetColors(names) {
        resetConfigKeys(names)
        save()
    }

    function resetCpuSettings() {
        resetConfigKeys(["cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing", "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuGraphScale", "cpuShowRam"])
        save()
    }

    function resetNetworkSettings() {
        resetConfigKeys(["systemMonitorInterval", "networkShowUpload", "networkShowDownload", "networkRowHeight", "networkRowSpacing", "networkIconSize", "networkValueFontSize", "networkRightPadding", "networkHorizontalPadding", "networkIconLeftPadding", "networkIconColumnWidth"])
        save()
    }

    function resetVolumeSettings() {
        resetConfigKeys(["volumeUpdateInterval", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeShowStreams", "volumeHorizontalPadding", "volumeVerticalPadding", "volumeMainTrackWidth", "volumeMainTrackHeight", "volumeStreamTrackHeight", "volumeMainTrackOffsetY", "volumeStreamTrackOffsetY", "volumeMainIconWidth", "volumeStreamLabelFontSize", "volumeTrackRadius", "volumeMinHeight", "volumeMaxHeight"])
        save()
    }

    function resetTimerSettings() {
        resetConfigKeys([
            "timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap",
            "timerRowTopMargin", "timerRowRightMargin", "timerButtonFadeDuration",
            "timerButtonSlideDuration", "timerButtonIconFadeDuration", "timerMinHeight"
        ])
        timerPresetDefaults = defaultTimerPresetDefaults.slice()
        timerPresets = timerPresetDefaults.slice()
        save()
    }

    function resetPlayerSettings() {
        resetConfigKeys([
            "playerSilenceText", "playerFont", "playerMetaFont", "playerSilenceFontSize",
            "playerSilenceLongFontSize", "playerMetaFontSize", "playerMetaSecondaryFontSize",
            "playerMetaLineSpacing", "playerBoldArtist", "playerShowProgress", "playerControlIconSize",
            "playerBlurEnabled", "playerBlurRadius", "playerMetadataXPadding", "playerMetadataY",
            "playerProgressY", "playerProgressHeight", "playerProgressTrackHeight", "playerControlTopMargin",
            "playerControlGap", "playerTimeFontSize", "playerTimeRightPadding", "playerCoverOpacity",
            "playerSilenceWidth", "playerProgressTrackOffsetY", "playerUpdateInterval"
        ])
        save()
    }

    function resetWeatherSettings() {
        resetConfigKeys([
            "weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes",
            "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds",
            "weatherIconSize", "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap",
            "weatherHourlyCount", "weatherDailyCount", "weatherListTopPadding", "weatherIconY",
            "weatherWindColumnX", "weatherWindSpeedFontSize", "weatherWindUnitFontSize", "weatherPressureY",
            "weatherDescriptionY", "weatherDescriptionFontSize", "weatherTempFontSize", "weatherComfortFontSize",
            "weatherTempColumnWidth", "weatherTempX", "weatherTempWidth", "weatherComfortY", "weatherComfortHeight",
            "weatherWindColumnWidth", "weatherWindArrowWidth", "weatherWindArrowHeight", "weatherWindSpeedX", "weatherWindSpeedY",
            "weatherWindSpeedWidth", "weatherWindUnitX", "weatherWindUnitY", "weatherWindUnitWidth",
            "weatherPressureValueWidth", "weatherPressureFontSize", "weatherPressureUnitX", "weatherPressureUnitY",
            "weatherPressureUnitFontSize", "weatherDescriptionHeight", "weatherListDayHeight", "weatherListIconWidth",
            "weatherListIconHeight", "weatherListIconY", "weatherListHourlyTempY", "weatherListDailyTempY",
            "weatherListLowTempY", "weatherListTempHeight", "weatherListDayFontSize", "weatherListHourlyTempFontSize",
            "weatherListDailyTempFontSize", "weatherListLowTempFontSize"
        ])
        weatherToken = defaultWeatherToken
        save()
    }

    function resetCavaSettings() {
        resetConfigKeys(["cavaBars", "cavaFramerate", "cavaRowHeight", "cavaRowSpacing", "cavaBarWidthRatio", "cavaBarHeightScale", "cavaBarMinHeight"])
        save()
    }

    function resetGeneralSettings() {
        resetConfigKeys([
            "font", "fontSize", "ledFont",
            "frameBorderWidth", "frameRadius"
        ])
        save()
    }

    function resetAnimationSettings() {
        resetConfigKeys([
            "animationsEnabled", "animationSpeed",
            "animationTimerOptionsDuration", "animationCalendarSlideDuration",
            "animationCalendarFadeDuration"
        ])
        save()
    }

    function resetSettingsWindow() {
        resetConfigKeys(["settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing"])
        settingsGeometry = defaultSettingsGeometry.slice()
        save()
    }

    function resetAllSettings() {
        resetConfigKeys(Object.keys(defaultConfig))
        for (var i = 0; i < moduleNames.length; ++i) root[moduleNames[i]] = !!defaultModules[moduleNames[i]]
        geometry = JSON.parse(JSON.stringify(defaultGeometry))
        settingsGeometry = defaultSettingsGeometry.slice()
        timerPresetDefaults = defaultTimerPresetDefaults.slice()
        timerPresets = timerPresetDefaults.slice()
        weatherToken = defaultWeatherToken
        activeTheme = "14 Theme"
        save()
    }

    function snapshotObject() {
        var modules = {}
        for (var i=0; i<moduleNames.length; ++i) modules[moduleNames[i]] = root[moduleNames[i]]
        var colors = {}
        for (var j=0; j<colorNames.length; ++j) colors[colorNames[j]] = Config[colorNames[j]]
        return {
            weatherToken: weatherToken,
            font: Config.font, fontSize: Config.fontSize,
            settingsFont: Config.settingsFont, settingsFontSize: Config.settingsFontSize,
            settingsPadding: Config.settingsPadding, settingsSpacing: Config.settingsSpacing,
            ledFont: Config.ledFont,
            playerFont: Config.playerFont, playerMetaFont: Config.playerMetaFont, playerSilenceText: Config.playerSilenceText,
            animationsEnabled: Config.animationsEnabled, animationSpeed: Config.animationSpeed,
            animationTimerOptionsDuration: Config.animationTimerOptionsDuration, animationCalendarSlideDuration: Config.animationCalendarSlideDuration, animationCalendarFadeDuration: Config.animationCalendarFadeDuration,
            systemMonitorInterval: Config.systemMonitorInterval, cpuUpdateInterval: Config.cpuUpdateInterval, playerUpdateInterval: Config.playerUpdateInterval,
            weatherNowIntervalMinutes: Config.weatherNowIntervalMinutes, weatherHourlyIntervalMinutes: Config.weatherHourlyIntervalMinutes, weatherDailyIntervalMinutes: Config.weatherDailyIntervalMinutes, weatherRetryDelayMinutes: Config.weatherRetryDelayMinutes, weatherManualRefreshCooldownSeconds: Config.weatherManualRefreshCooldownSeconds,
            timerMinHeight: Config.timerMinHeight, volumeMinHeight: Config.volumeMinHeight, volumeMaxHeight: Config.volumeMaxHeight,
            timerWheelStep: Config.timerWheelStep, timerCommentWidth: Config.timerCommentWidth, timerCommentMaxLength: Config.timerCommentMaxLength, timerCommentGap: Config.timerCommentGap,
            timerRowTopMargin: Config.timerRowTopMargin, timerRowRightMargin: Config.timerRowRightMargin,
            timerButtonFadeDuration: Config.timerButtonFadeDuration, timerButtonSlideDuration: Config.timerButtonSlideDuration, timerButtonIconFadeDuration: Config.timerButtonIconFadeDuration,
            playerSilenceFontSize: Config.playerSilenceFontSize, playerSilenceLongFontSize: Config.playerSilenceLongFontSize, playerMetaFontSize: Config.playerMetaFontSize,
            playerMetaSecondaryFontSize: Config.playerMetaSecondaryFontSize, playerMetaLineSpacing: Config.playerMetaLineSpacing, playerBoldArtist: Config.playerBoldArtist,
            playerShowProgress: Config.playerShowProgress, playerControlIconSize: Config.playerControlIconSize,
            playerBlurEnabled: Config.playerBlurEnabled, playerBlurRadius: Config.playerBlurRadius,
            playerMetadataXPadding: Config.playerMetadataXPadding, playerMetadataY: Config.playerMetadataY,
            playerProgressY: Config.playerProgressY, playerProgressHeight: Config.playerProgressHeight, playerProgressTrackHeight: Config.playerProgressTrackHeight,
            playerControlTopMargin: Config.playerControlTopMargin, playerControlGap: Config.playerControlGap,
            playerTimeFontSize: Config.playerTimeFontSize, playerTimeRightPadding: Config.playerTimeRightPadding, playerCoverOpacity: Config.playerCoverOpacity,
            playerSilenceWidth: Config.playerSilenceWidth, playerProgressTrackOffsetY: Config.playerProgressTrackOffsetY,
            weatherIconSize: Config.weatherIconSize, weatherArrowSize: Config.weatherArrowSize, weatherArrowYOffset: Config.weatherArrowYOffset, weatherWindArrowGap: Config.weatherWindArrowGap,
            weatherHourlyCount: Config.weatherHourlyCount, weatherDailyCount: Config.weatherDailyCount, weatherListTopPadding: Config.weatherListTopPadding,
            weatherIconY: Config.weatherIconY, weatherWindColumnX: Config.weatherWindColumnX, weatherWindSpeedFontSize: Config.weatherWindSpeedFontSize, weatherWindUnitFontSize: Config.weatherWindUnitFontSize,
            weatherPressureY: Config.weatherPressureY, weatherDescriptionY: Config.weatherDescriptionY, weatherDescriptionFontSize: Config.weatherDescriptionFontSize, weatherTempFontSize: Config.weatherTempFontSize, weatherComfortFontSize: Config.weatherComfortFontSize,
            weatherTempColumnWidth: Config.weatherTempColumnWidth, weatherTempX: Config.weatherTempX, weatherTempWidth: Config.weatherTempWidth, weatherComfortY: Config.weatherComfortY, weatherComfortHeight: Config.weatherComfortHeight,
            weatherWindColumnWidth: Config.weatherWindColumnWidth, weatherWindArrowWidth: Config.weatherWindArrowWidth, weatherWindArrowHeight: Config.weatherWindArrowHeight, weatherWindSpeedX: Config.weatherWindSpeedX, weatherWindSpeedY: Config.weatherWindSpeedY, weatherWindSpeedWidth: Config.weatherWindSpeedWidth,
            weatherWindUnitX: Config.weatherWindUnitX, weatherWindUnitY: Config.weatherWindUnitY, weatherWindUnitWidth: Config.weatherWindUnitWidth, weatherPressureValueWidth: Config.weatherPressureValueWidth, weatherPressureFontSize: Config.weatherPressureFontSize,
            weatherPressureUnitX: Config.weatherPressureUnitX, weatherPressureUnitY: Config.weatherPressureUnitY, weatherPressureUnitFontSize: Config.weatherPressureUnitFontSize, weatherDescriptionHeight: Config.weatherDescriptionHeight,
            weatherListDayHeight: Config.weatherListDayHeight, weatherListIconWidth: Config.weatherListIconWidth, weatherListIconHeight: Config.weatherListIconHeight, weatherListIconY: Config.weatherListIconY,
            weatherListHourlyTempY: Config.weatherListHourlyTempY, weatherListDailyTempY: Config.weatherListDailyTempY, weatherListLowTempY: Config.weatherListLowTempY, weatherListTempHeight: Config.weatherListTempHeight,
            weatherListDayFontSize: Config.weatherListDayFontSize, weatherListHourlyTempFontSize: Config.weatherListHourlyTempFontSize, weatherListDailyTempFontSize: Config.weatherListDailyTempFontSize, weatherListLowTempFontSize: Config.weatherListLowTempFontSize,
            cavaBars: Config.cavaBars, cavaFramerate: Config.cavaFramerate, cavaRowHeight: Config.cavaRowHeight, cavaRowSpacing: Config.cavaRowSpacing, cavaBarWidthRatio: Config.cavaBarWidthRatio, cavaBarHeightScale: Config.cavaBarHeightScale, cavaBarMinHeight: Config.cavaBarMinHeight, frameBorderWidth: Config.frameBorderWidth, frameRadius: Config.frameRadius,
            cpuBarThickness: Config.cpuBarThickness, cpuBarWidth: Config.cpuBarWidth, cpuRowHeight: Config.cpuRowHeight, cpuRowSpacing: Config.cpuRowSpacing, cpuLabelLeftPadding: Config.cpuLabelLeftPadding, cpuBarLeftOffset: Config.cpuBarLeftOffset, cpuBarRadius: Config.cpuBarRadius, cpuGraphSegmentSlotWidth: Config.cpuGraphSegmentSlotWidth, cpuGraphBarWidth: Config.cpuGraphBarWidth, cpuGraphScale: Config.cpuGraphScale, cpuShowRam: Config.cpuShowRam,
            networkShowUpload: Config.networkShowUpload, networkShowDownload: Config.networkShowDownload, networkRowHeight: Config.networkRowHeight, networkRowSpacing: Config.networkRowSpacing, networkIconSize: Config.networkIconSize, networkValueFontSize: Config.networkValueFontSize, networkRightPadding: Config.networkRightPadding, networkHorizontalPadding: Config.networkHorizontalPadding, networkIconLeftPadding: Config.networkIconLeftPadding, networkIconColumnWidth: Config.networkIconColumnWidth,
            volumeUpdateInterval: Config.volumeUpdateInterval, volumeMainRowHeight: Config.volumeMainRowHeight, volumeStreamRowHeight: Config.volumeStreamRowHeight, volumeStreamSpacing: Config.volumeStreamSpacing, volumeShowStreams: Config.volumeShowStreams, volumeHorizontalPadding: Config.volumeHorizontalPadding, volumeVerticalPadding: Config.volumeVerticalPadding, volumeMainTrackWidth: Config.volumeMainTrackWidth, volumeMainTrackHeight: Config.volumeMainTrackHeight, volumeStreamTrackHeight: Config.volumeStreamTrackHeight, volumeMainTrackOffsetY: Config.volumeMainTrackOffsetY, volumeStreamTrackOffsetY: Config.volumeStreamTrackOffsetY, volumeMainIconWidth: Config.volumeMainIconWidth, volumeStreamLabelFontSize: Config.volumeStreamLabelFontSize, volumeTrackRadius: Config.volumeTrackRadius,
            timerPresets: timerPresetDefaults, timerPresetDefaults: timerPresetDefaults, modules: modules, geometry: geometry, settingsGeometry: settingsGeometry, colors: colors
        }
    }

    function save() {
        var payloadObject = snapshotObject()
        payloadObject.profiles = profiles
        payloadObject.activeProfile = activeProfile
        payloadObject.customThemes = customThemes
        payloadObject.activeTheme = activeTheme
        var payload = JSON.stringify(payloadObject)

        if (!writer)
            writer = writerComponent.createObject(root)

        if (writer.running) {
            // Keep only the newest snapshot. This prevents a burst of UI changes
            // from creating a growing list of Process objects.
            pendingWritePayload = payload
        } else {
            writer.payload = payload
            writer.running = true
        }
        saved()
    }

    function rebuildProfileList() {
        var names = Object.keys(profiles || {}).sort(function(a, b) { return a.localeCompare(b) })
        profileList = names
        profilesRevision++
    }

    function profileNames() {
        return profileList
    }

    readonly property var builtinThemeNames: ["14 Theme", "Catppuccin Mocha", "Tokyo Night", "Dracula", "Nord", "Gruvbox Dark", "One Dark", "Amber", "Purple", "Ice", "Mono"]
    readonly property var themeNames: builtinThemeNames.concat(Object.keys(customThemes || {}).sort(function(a, b) { return a.localeCompare(b) }))

    function themePalette(name) {
        var palettes = {
            "14 Theme": {
                baseColor: "#006666", accent: "#00cccc", currentWeather: "#00cccc", background: "#4d000000",
                text: "#ffffff", textMuted: "#dddddd", textDim: "#cccccc", textDisabled: "#999999", black: "#000000",
                calendarBackground: "#cc000000", settingsBackground: "#e6000000", settingsBorder: "#00cccc",
                playerOverlay: "#18000000", playerProgressTrack: "#33ffffff", playerProgressFill: "#00cccc", activeNetworkBackground: "#1a323232",
                volumeTrack: "#99006666", volumeFill: "#006666", networkUpload: "#baffc9", networkDownload: "#ffb4bb",
                cpu1: "#ffb4bb", cpu2: "#ffe0ba", cpu3: "#fffebb", cpu4: "#baffc9", cpu5: "#bae1ff", cpu6: "#aedfdb", cpu7: "#75c8cc", cpu8: "#ead1f5", ram: "#3daee9", metricTrack: "#4d006666", ramTrack: "#4d3daee9",
                tempHot: "#ff8989", tempWarm: "#ffb4bb", tempMild: "#ffe0ba", tempCool: "#fce3c4", tempZero: "#ffffff", tempCold: "#bae1ff", tempVeryCold: "#0ad1f3", tempFreezing: "#3c82e2"
            },
            "Catppuccin Mocha": {
                baseColor: "#585b70", accent: "#89b4fa", currentWeather: "#74c7ec", background: "#4d1e1e2e", text: "#cdd6f4", textMuted: "#bac2de", textDim: "#a6adc8", textDisabled: "#6c7086", black: "#11111b",
                calendarBackground: "#cc181825", settingsBackground: "#e61e1e2e", settingsBorder: "#89b4fa", playerOverlay: "#262c2c3a", playerProgressTrack: "#33585b70", playerProgressFill: "#89b4fa", activeNetworkBackground: "#1a313244", volumeTrack: "#99585b70", volumeFill: "#89b4fa", networkUpload: "#a6e3a1", networkDownload: "#f38ba8",
                cpu1: "#f38ba8", cpu2: "#fab387", cpu3: "#f9e2af", cpu4: "#a6e3a1", cpu5: "#89dceb", cpu6: "#94e2d5", cpu7: "#74c7ec", cpu8: "#cba6f7", ram: "#89b4fa", metricTrack: "#4d45475a", ramTrack: "#4d89b4fa", tempHot: "#f38ba8", tempWarm: "#eba0ac", tempMild: "#fab387", tempCool: "#89dceb", tempZero: "#cdd6f4", tempCold: "#74c7ec", tempVeryCold: "#89b4fa", tempFreezing: "#7287fd"
            },
            "Tokyo Night": {
                baseColor: "#3b4261", accent: "#7aa2f7", currentWeather: "#7dcfff", background: "#4d16161e", text: "#c0caf5", textMuted: "#a9b1d6", textDim: "#9aa5ce", textDisabled: "#565f89", black: "#15161e",
                calendarBackground: "#cc1a1b26", settingsBackground: "#e61a1b26", settingsBorder: "#7aa2f7", playerOverlay: "#26242a3d", playerProgressTrack: "#334147bb", playerProgressFill: "#7aa2f7", activeNetworkBackground: "#1a24283b", volumeTrack: "#993b4261", volumeFill: "#7aa2f7", networkUpload: "#9ece6a", networkDownload: "#f7768e",
                cpu1: "#f7768e", cpu2: "#ff9e64", cpu3: "#e0af68", cpu4: "#9ece6a", cpu5: "#7dcfff", cpu6: "#73daca", cpu7: "#2ac3de", cpu8: "#bb9af7", ram: "#7aa2f7", metricTrack: "#4d3b4261", ramTrack: "#4d7aa2f7", tempHot: "#f7768e", tempWarm: "#ff9e64", tempMild: "#e0af68", tempCool: "#7dcfff", tempZero: "#c0caf5", tempCold: "#7aa2f7", tempVeryCold: "#2ac3de", tempFreezing: "#5d7bd2"
            },
            "Dracula": {
                baseColor: "#6272a4", accent: "#bd93f9", currentWeather: "#8be9fd", background: "#4d282a36", text: "#f8f8f2", textMuted: "#d6d6cf", textDim: "#bfbfb7", textDisabled: "#6272a4", black: "#282a36",
                calendarBackground: "#cc21222c", settingsBackground: "#e621222c", settingsBorder: "#bd93f9", playerOverlay: "#26282a36", playerProgressTrack: "#336272a4", playerProgressFill: "#bd93f9", activeNetworkBackground: "#1a343746", volumeTrack: "#996272a4", volumeFill: "#bd93f9", networkUpload: "#50fa7b", networkDownload: "#ff5555",
                cpu1: "#ff79c6", cpu2: "#ffb86c", cpu3: "#f1fa8c", cpu4: "#50fa7b", cpu5: "#8be9fd", cpu6: "#8be9fd", cpu7: "#bd93f9", cpu8: "#ff79c6", ram: "#8be9fd", metricTrack: "#4d6272a4", ramTrack: "#4d8be9fd", tempHot: "#ff5555", tempWarm: "#ff79c6", tempMild: "#ffb86c", tempCool: "#8be9fd", tempZero: "#f8f8f2", tempCold: "#6272a4", tempVeryCold: "#8be9fd", tempFreezing: "#6c63ff"
            },
            "Nord": {
                baseColor: "#4c566a", accent: "#88c0d0", currentWeather: "#8fbcbb", background: "#4d2e3440", text: "#eceff4", textMuted: "#d8dee9", textDim: "#c4cad4", textDisabled: "#616e82", black: "#2e3440",
                calendarBackground: "#cc2e3440", settingsBackground: "#e62e3440", settingsBorder: "#88c0d0", playerOverlay: "#262e3440", playerProgressTrack: "#334c566a", playerProgressFill: "#88c0d0", activeNetworkBackground: "#1a3b4450", volumeTrack: "#994c566a", volumeFill: "#88c0d0", networkUpload: "#a3be8c", networkDownload: "#bf616a",
                cpu1: "#bf616a", cpu2: "#d08770", cpu3: "#ebcb8b", cpu4: "#a3be8c", cpu5: "#88c0d0", cpu6: "#8fbcbb", cpu7: "#5e81ac", cpu8: "#b48ead", ram: "#81a1c1", metricTrack: "#4d4c566a", ramTrack: "#4d81a1c1", tempHot: "#bf616a", tempWarm: "#d08770", tempMild: "#ebcb8b", tempCool: "#8fbcbb", tempZero: "#eceff4", tempCold: "#81a1c1", tempVeryCold: "#88c0d0", tempFreezing: "#5e81ac"
            },
            "Gruvbox Dark": {
                baseColor: "#665c54", accent: "#fabd2f", currentWeather: "#83a598", background: "#4d1d2021", text: "#ebdbb2", textMuted: "#d5c4a1", textDim: "#bdae93", textDisabled: "#7c6f64", black: "#1d2021",
                calendarBackground: "#cc282828", settingsBackground: "#e61d2021", settingsBorder: "#fabd2f", playerOverlay: "#26232220", playerProgressTrack: "#33665c54", playerProgressFill: "#fabd2f", activeNetworkBackground: "#1a3c3836", volumeTrack: "#99665c54", volumeFill: "#fabd2f", networkUpload: "#b8bb26", networkDownload: "#fb4934",
                cpu1: "#fb4934", cpu2: "#fe8019", cpu3: "#fabd2f", cpu4: "#b8bb26", cpu5: "#83a598", cpu6: "#8ec07c", cpu7: "#458588", cpu8: "#d3869b", ram: "#83a598", metricTrack: "#4d665c54", ramTrack: "#4d83a598", tempHot: "#fb4934", tempWarm: "#fe8019", tempMild: "#fabd2f", tempCool: "#83a598", tempZero: "#ebdbb2", tempCold: "#83a598", tempVeryCold: "#8ec07c", tempFreezing: "#458588"
            },
            "One Dark": {
                baseColor: "#4b5263", accent: "#61afef", currentWeather: "#56b6c2", background: "#4d21252b", text: "#abb2bf", textMuted: "#9da5b4", textDim: "#828997", textDisabled: "#5c6370", black: "#282c34",
                calendarBackground: "#cc282c34", settingsBackground: "#e621252b", settingsBorder: "#61afef", playerOverlay: "#2621252b", playerProgressTrack: "#334b5263", playerProgressFill: "#61afef", activeNetworkBackground: "#1a354052", volumeTrack: "#994b5263", volumeFill: "#61afef", networkUpload: "#98c379", networkDownload: "#e06c75",
                cpu1: "#e06c75", cpu2: "#d19a66", cpu3: "#e5c07b", cpu4: "#98c379", cpu5: "#56b6c2", cpu6: "#61afef", cpu7: "#528bff", cpu8: "#c678dd", ram: "#61afef", metricTrack: "#4d4b5263", ramTrack: "#4d61afef", tempHot: "#e06c75", tempWarm: "#d19a66", tempMild: "#e5c07b", tempCool: "#56b6c2", tempZero: "#abb2bf", tempCold: "#61afef", tempVeryCold: "#56b6c2", tempFreezing: "#528bff"
            },
            Amber: {
                baseColor: "#704800", accent: "#ffb52e", currentWeather: "#ffd166", background: "#4d0a0800",
                text: "#fff6e0", textMuted: "#e0d1b5", textDim: "#c7b895", textDisabled: "#8e826c", black: "#000000",
                calendarBackground: "#cc100c06", settingsBackground: "#e60e0a05", settingsBorder: "#ffb52e",
                playerOverlay: "#28160a00", playerProgressTrack: "#33fff0c2", activeNetworkBackground: "#1a3a2b10",
                volumeTrack: "#99704b00", volumeFill: "#ffb52e", networkUpload: "#a7f3d0", networkDownload: "#ffb4b4",
                cpu1: "#ffb4b4", cpu2: "#ffd8a8", cpu3: "#fff1a8", cpu4: "#c6f6d5", cpu5: "#bde3ff", cpu6: "#c6e8df", cpu7: "#87c9c4", cpu8: "#e7cff3", ram: "#5eb3e7", metricTrack: "#4d704b00", ramTrack: "#4d5eb3e7",
                tempHot: "#ff6b57", tempWarm: "#ff9f66", tempMild: "#ffd166", tempCool: "#f5d6a1", tempZero: "#fff6e0", tempCold: "#a8d8ff", tempVeryCold: "#72d2ef", tempFreezing: "#5e93d9"
            },
            Purple: {
                baseColor: "#5b3f7a", accent: "#c77dff", currentWeather: "#e0aaff", background: "#4d08050d",
                text: "#f7f0ff", textMuted: "#d8cae6", textDim: "#c2b2d6", textDisabled: "#8e809b", black: "#000000",
                calendarBackground: "#cc0d0714", settingsBackground: "#e60b0610", settingsBorder: "#c77dff",
                playerOverlay: "#2613072e", playerProgressTrack: "#33e5cfff", activeNetworkBackground: "#1a352040",
                volumeTrack: "#995b3f7a", volumeFill: "#c77dff", networkUpload: "#b7efc5", networkDownload: "#ffb4cf",
                cpu1: "#ffb4c9", cpu2: "#ffd0b7", cpu3: "#fff5b7", cpu4: "#bfeecb", cpu5: "#c1ddff", cpu6: "#b9dcd7", cpu7: "#7cc9c9", cpu8: "#dcb7ff", ram: "#6fb9ef", metricTrack: "#4d5b3f7a", ramTrack: "#4d6fb9ef",
                tempHot: "#ff7a8f", tempWarm: "#ffb0c2", tempMild: "#ffd3a8", tempCool: "#e9d5ff", tempZero: "#f7f0ff", tempCold: "#b9d8ff", tempVeryCold: "#86dbf4", tempFreezing: "#7e9ee8"
            },
            Ice: {
                baseColor: "#2a5f78", accent: "#5ee7ff", currentWeather: "#9be7ff", background: "#4d001018",
                text: "#f1fbff", textMuted: "#cbe4eb", textDim: "#b8d2db", textDisabled: "#76909a", black: "#000000",
                calendarBackground: "#cc00131a", settingsBackground: "#e6001620", settingsBorder: "#5ee7ff",
                playerOverlay: "#1820363d", playerProgressTrack: "#334ee7ff", activeNetworkBackground: "#1a183945",
                volumeTrack: "#992a5f78", volumeFill: "#5ee7ff", networkUpload: "#b7f0d2", networkDownload: "#ffb8c8",
                cpu1: "#ffb8c8", cpu2: "#ffe0b8", cpu3: "#fffbb8", cpu4: "#b8ffd0", cpu5: "#b8ddff", cpu6: "#b8e4df", cpu7: "#77d7df", cpu8: "#e2ccff", ram: "#69d6ff", metricTrack: "#4d2a5f78", ramTrack: "#4d69d6ff",
                tempHot: "#ff8b8b", tempWarm: "#ffb8c8", tempMild: "#ffe0b8", tempCool: "#c9edff", tempZero: "#f1fbff", tempCold: "#a9dcff", tempVeryCold: "#5ee7ff", tempFreezing: "#5d9de8"
            },
            Mono: {
                baseColor: "#777777", accent: "#dddddd", currentWeather: "#ffffff", background: "#55000000",
                text: "#ffffff", textMuted: "#cccccc", textDim: "#aaaaaa", textDisabled: "#777777", black: "#000000",
                calendarBackground: "#cc000000", settingsBackground: "#e6000000", settingsBorder: "#dddddd",
                playerOverlay: "#22000000", playerProgressTrack: "#33ffffff", activeNetworkBackground: "#1a2d2d2d",
                volumeTrack: "#99555555", volumeFill: "#dddddd", networkUpload: "#bbbbbb", networkDownload: "#eeeeee",
                cpu1: "#d0d0d0", cpu2: "#c6c6c6", cpu3: "#bcbcbc", cpu4: "#d8d8d8", cpu5: "#b2b2b2", cpu6: "#cacaca", cpu7: "#a0a0a0", cpu8: "#e0e0e0", ram: "#b8b8b8", metricTrack: "#4d555555", ramTrack: "#4d888888",
                tempHot: "#ffffff", tempWarm: "#eeeeee", tempMild: "#dddddd", tempCool: "#cccccc", tempZero: "#bbbbbb", tempCold: "#aaaaaa", tempVeryCold: "#999999", tempFreezing: "#888888"
            }
        }
        var n = String(name)
        if (customThemes && customThemes[n] !== undefined)
            return customThemes[n]
        return palettes[n] || palettes["14 Theme"]
    }

    function currentThemeColors() {
        var result = {}
        for (var i = 0; i < colorNames.length; ++i) {
            var key = colorNames[i]
            result[key] = String(Config[key])
        }
        return result
    }

    function isCurrentThemeModified() {
        var palette = themePalette(activeTheme)
        for (var i = 0; i < colorNames.length; ++i) {
            var key = colorNames[i]
            if (String(Config[key]) !== String(palette[key] !== undefined ? palette[key] : Config[key]))
                return true
        }
        return false
    }

    function saveCurrentTheme(name) {
        var n = String(name || "").trim().slice(0, 32)
        if (!n) return false
        var next = Object.assign({}, customThemes || {})
        next[n] = currentThemeColors()
        customThemes = next
        activeTheme = n
        themeDraftSource = n
        themeDraft = JSON.parse(JSON.stringify(next[n]))
        themeDraftRevision++
        save()
        return true
    }

    function applyTheme(name) {
        var n = String(name)
        var palette = themePalette(n)
        for (var key in palette) Config[key] = palette[key]
        activeTheme = n
        themeDraftSource = n
        themeDraft = JSON.parse(JSON.stringify(palette))
        themeDraftRevision++
        save()
    }

    function themePreview(name) {
        var p = themePalette(String(name))
        return [p.baseColor, p.accent, p.background, p.currentWeather, p.volumeFill, p.ram]
    }

    function themeDescription(name) {
        var descriptions = {
            "14 Theme": "Основная бирюзовая тема",
            "Catppuccin Mocha": "Catppuccin Mocha",
            "Tokyo Night": "Tokyo Night",
            "Dracula": "Dracula",
            "Nord": "Nord",
            "Gruvbox Dark": "Gruvbox Dark",
            "One Dark": "One Dark",
            Amber: "Тёплая янтарная палитра",
            Purple: "Фиолетовая палитра",
            Ice: "Холодная сине-бирюзовая палитра",
            Mono: "Нейтральная монохромная палитра"
        }
        return descriptions[name] || "Готовая цветовая тема"
    }

    function isCustomTheme(name) {
        return !!(customThemes && customThemes[String(name)] !== undefined)
    }

    function beginThemeEdit(name) {
        var n = String(name)
        themeDraft = JSON.parse(JSON.stringify(themePalette(n)))
        themeDraftSource = n
        themeDraftRevision++
    }

    function themeDraftValue(name) {
        var n = String(name)
        return themeDraft && themeDraft[n] !== undefined ? String(themeDraft[n]) : String(Config[n])
    }

    function setThemeDraftColor(name, value) {
        var v = String(value)
        if (!(/^#[0-9a-fA-F]{6,8}$/.test(v) || v === "transparent")) return false
        var next = Object.assign({}, themeDraft || {})
        next[String(name)] = v
        themeDraft = next
        themeDraftRevision++
        return true
    }

    function saveCustomTheme(name) {
        var n = String(name || "").trim().slice(0, 32)
        if (!n || builtinThemeNames.indexOf(n) >= 0 || !themeDraft) return false
        var next = Object.assign({}, customThemes || {})
        next[n] = JSON.parse(JSON.stringify(themeDraft))
        customThemes = next
        activeTheme = n
        themeDraftSource = n
        themeDraft = JSON.parse(JSON.stringify(next[n]))
        themeDraftRevision++
        for (var key in next[n]) Config[key] = next[n][key]
        save()
        return true
    }

    function deleteCustomTheme(name) {
        var n = String(name || "")
        if (!isCustomTheme(n)) return false
        var next = Object.assign({}, customThemes || {})
        delete next[n]
        customThemes = next
        if (activeTheme === n) {
            activeTheme = "14 Theme"
            var p = themePalette(activeTheme)
            for (var key in p) Config[key] = p[key]
        }
        save()
        return true
    }

    function saveProfile(name) {
        var n = String(name || "").trim()
        if (!n) return false
        n = n.slice(0, 32)
        var next = Object.assign({}, profiles || {})
        next[n] = JSON.parse(JSON.stringify(snapshotObject()))
        profiles = next
        activeProfile = n
        rebuildProfileList()
        save()
        return true
    }

    function loadProfile(name) {
        var n = String(name || "")
        var profile = profiles ? profiles[n] : null
        if (!profile) return false
        applyObject(JSON.parse(JSON.stringify(profile)))
        activeProfile = n
        rebuildProfileList()
        save()
        return true
    }

    function deleteProfile(name) {
        var n = String(name || "")
        if (!profiles || profiles[n] === undefined) return false
        var next = Object.assign({}, profiles)
        delete next[n]
        profiles = next
        if (activeProfile === n) activeProfile = ""
        rebuildProfileList()
        save()
        return true
    }

}
