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

    property var geometry: ({
        time: [3,5,315,55], cpu: [5,65,315,170], cpuGraph: [5,235,315,82],
        topApps: [5,322,315,198], networkStat: [5,526,313,55], weatherNow: [3,585,315,80],
        weatherHourly: [3,665,335,125], weatherDaily: [3,795,325,125], timer: [3,930,315,145],
        timerOptions: [325,888,90,95], calendar: [5,65,315,285], volumes: [331,72,275,210],
        player: [330,405,300,320], cava: [325,578,300,80], networks: [331,675,300,180]
    })
    // Geometry of the settings window itself: X, Y, Width, Height.
    property var settingsGeometry: [640, 40, 560, 850]
    readonly property var moduleNames: ["time","cpu","cpuGraph","topApps","networkStat","weatherNow","weatherHourly","weatherDaily","timer","volumes","player","cava","networks","calendar"]
    readonly property var moduleLabels: ({time:"Часы",cpu:"CPU",cpuGraph:"График CPU",topApps:"Top Apps",networkStat:"Сеть",weatherNow:"Погода сейчас",weatherHourly:"Погода по часам",weatherDaily:"Погода по дням",timer:"Таймеры",volumes:"Громкость",player:"Плеер",cava:"CAVA",networks:"Networks",calendar:"Календарь"})
    readonly property var colorNames: ["baseColor","accent","currentWeather","background","text","textMuted","textDim","textDisabled","calendarBackground","settingsBackground","settingsBorder","playerOverlay","playerProgressTrack","activeNetworkBackground","volumeTrack","volumeFill","cpu1","cpu2","cpu3","cpu4","cpu5","cpu6","cpu7","cpu8","ram","metricTrack","ramTrack","networkUpload","networkDownload","tempHot","tempWarm","tempMild","tempCool","tempZero","tempCold","tempVeryCold","tempFreezing"]
    signal changed()

    function applyObject(o) {
        if (!o) return
        if (o.weatherToken !== undefined) weatherToken = String(o.weatherToken)
        if (o.font !== undefined) Config.font = String(o.font)
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
            ["playerMetaLineSpacing", 0, 100], ["playerControlIconSize", 8, 64]
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

        // Weather tuning
        var weatherNumberFields = [
            ["weatherIconSize", 16, 128], ["weatherArrowSize", 8, 64],
            ["weatherArrowYOffset", -40, 40], ["weatherWindArrowGap", -20, 40],
            ["weatherHourlyCount", 1, 12], ["weatherDailyCount", 1, 10],
            ["weatherListTopPadding", 0, 40]
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
        loaded = true
        changed()
    }

    property var loader: null
    property var writer: null

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
            property string payload: "{}"
            command: [Quickshell.shellDir + "/scripts/settings", "set-json", payload]
        }
    }

    Component.onCompleted: {
        loader = loaderComponent.createObject(root)
        writer = writerComponent.createObject(root)
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

    function save() {
        var modules = {}
        for (var i=0; i<moduleNames.length; ++i) modules[moduleNames[i]] = root[moduleNames[i]]
        var colors = {}
        for (var j=0; j<colorNames.length; ++j) colors[colorNames[j]] = Config[colorNames[j]]
        var payload = JSON.stringify({
            weatherToken: weatherToken,
            font: Config.font, ledFont: Config.ledFont,
            playerFont: Config.playerFont, playerMetaFont: Config.playerMetaFont, playerSilenceText: Config.playerSilenceText,
            animationsEnabled: Config.animationsEnabled, animationSpeed: Config.animationSpeed,
            systemMonitorInterval: Config.systemMonitorInterval, cpuUpdateInterval: Config.cpuUpdateInterval, playerUpdateInterval: Config.playerUpdateInterval,
            weatherNowIntervalMinutes: Config.weatherNowIntervalMinutes, weatherHourlyIntervalMinutes: Config.weatherHourlyIntervalMinutes, weatherDailyIntervalMinutes: Config.weatherDailyIntervalMinutes,
            timerMinHeight: Config.timerMinHeight, volumeMinHeight: Config.volumeMinHeight, volumeMaxHeight: Config.volumeMaxHeight,
            timerWheelStep: Config.timerWheelStep, timerCommentWidth: Config.timerCommentWidth, timerCommentMaxLength: Config.timerCommentMaxLength, timerCommentGap: Config.timerCommentGap,
            timerRowTopMargin: Config.timerRowTopMargin, timerRowRightMargin: Config.timerRowRightMargin,
            timerButtonFadeDuration: Config.timerButtonFadeDuration, timerButtonSlideDuration: Config.timerButtonSlideDuration, timerButtonIconFadeDuration: Config.timerButtonIconFadeDuration,
            playerSilenceFontSize: Config.playerSilenceFontSize, playerSilenceLongFontSize: Config.playerSilenceLongFontSize, playerMetaFontSize: Config.playerMetaFontSize,
            playerMetaSecondaryFontSize: Config.playerMetaSecondaryFontSize, playerMetaLineSpacing: Config.playerMetaLineSpacing, playerBoldArtist: Config.playerBoldArtist,
            playerShowProgress: Config.playerShowProgress, playerControlIconSize: Config.playerControlIconSize,
            weatherIconSize: Config.weatherIconSize, weatherArrowSize: Config.weatherArrowSize, weatherArrowYOffset: Config.weatherArrowYOffset, weatherWindArrowGap: Config.weatherWindArrowGap,
            weatherHourlyCount: Config.weatherHourlyCount, weatherDailyCount: Config.weatherDailyCount, weatherListTopPadding: Config.weatherListTopPadding,
            cavaBars: Config.cavaBars, cavaFramerate: Config.cavaFramerate, frameBorderWidth: Config.frameBorderWidth, frameRadius: Config.frameRadius,
            timerPresets: timerPresetDefaults, timerPresetDefaults: timerPresetDefaults, modules: modules, geometry: geometry, settingsGeometry: settingsGeometry, colors: colors
        })
        if (!writer) writer = writerComponent.createObject(root)
        writer.payload = payload
        writer.running = false
        writer.running = true
    }
}
