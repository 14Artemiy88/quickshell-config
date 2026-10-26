.pragma library

.import "SettingsSchema.js" as Schema

var SETTINGS_TAB_IDS = ["modules", "themes", "general", "timers", "player", "mopidy", "weather", "cava", "cpuRam", "network", "volume", "calendar", "launcher", "settingsWindow"]
var DEFAULT_SETTINGS_TAB_LABELS = ({modules:"Модули", themes:"Темы", general:"Общие", timers:"Таймеры", player:"Плеер", mopidy:"Mopidy", weather:"Погода", cava:"CAVA", cpuRam:"CPU/RAM", network:"Сеть", volume:"Громкость", calendar:"Календарь", launcher:"Лаунчер", settingsWindow:"Окно настроек"})

function normalizeSettingsTabOrder(source) {
    var result = []
    var seen = ({})
    if (source instanceof Array) {
        for (var i = 0; i < source.length; ++i) {
            var id = String(source[i] || "")
            if (SETTINGS_TAB_IDS.indexOf(id) >= 0 && !seen[id]) {
                seen[id] = true
                result.push(id)
            }
        }
    }
    for (var j = 0; j < SETTINGS_TAB_IDS.length; ++j) {
        var fallbackId = SETTINGS_TAB_IDS[j]
        if (!seen[fallbackId]) result.push(fallbackId)
    }
    return result
}

function normalizeSettingsTabLabels(source, current) {
    var result = Object.assign({}, DEFAULT_SETTINGS_TAB_LABELS, current || {})
    if (source && typeof source === "object" && !(source instanceof Array)) {
        for (var i = 0; i < SETTINGS_TAB_IDS.length; ++i) {
            var id = SETTINGS_TAB_IDS[i]
            if (source[id] === undefined) continue
            var label = String(source[id] === null ? "" : source[id]).trim().slice(0, 32)
            result[id] = label || DEFAULT_SETTINGS_TAB_LABELS[id]
        }
    }
    return result
}

function apply(owner, Config, o) {
        if (o.weatherToken !== undefined) owner.weatherToken = String(o.weatherToken).trim()
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
        if (o.settingsTabOrder !== undefined)
            Config.settingsTabOrder = normalizeSettingsTabOrder(o.settingsTabOrder)
        if (o.settingsTabLabels !== undefined)
            Config.settingsTabLabels = normalizeSettingsTabLabels(o.settingsTabLabels, Config.settingsTabLabels)
        if (o.ledFont !== undefined) Config.ledFont = String(o.ledFont)
        if (o.playerFont !== undefined) Config.playerFont = String(o.playerFont)
        if (o.playerMetaFont !== undefined) Config.playerMetaFont = String(o.playerMetaFont)
        if (o.playerSilenceText !== undefined) Config.playerSilenceText = String(o.playerSilenceText)
        if (o.playerTextOutlineEnabled !== undefined) Config.playerTextOutlineEnabled = !!o.playerTextOutlineEnabled
        if (o.playerTextOutlineColor !== undefined) Config.playerTextOutlineColor = String(o.playerTextOutlineColor)
        if (o.playerPlayingIcon !== undefined) Config.playerPlayingIcon = String(o.playerPlayingIcon)
        if (o.playerPausedIcon !== undefined) Config.playerPausedIcon = String(o.playerPausedIcon)
        if (o.playerNextIcon !== undefined) Config.playerNextIcon = String(o.playerNextIcon)

        // Timer icon order. Older settings had no order field and used timer-left.
        // Migrate those settings once to alarm-left by swapping the saved X positions.
        var legacyTimerIconOrder = o.timerIconOrder === undefined
        if (o.timerIconOrder !== undefined) {
            var timerIconOrderValue = String(o.timerIconOrder)
            Config.timerIconOrder = timerIconOrderValue === "timer-left" ? "timer-left" : "alarm-left"
        } else {
            Config.timerIconOrder = "alarm-left"
        }
        if (o.timerIcon !== undefined) Config.timerIcon = String(o.timerIcon)
        if (o.timerAlarmIcon !== undefined) Config.timerAlarmIcon = String(o.timerAlarmIcon)
        if (o.timerFinishedImageEnabled !== undefined) Config.timerFinishedImageEnabled = !!o.timerFinishedImageEnabled
        if (o.timerFinishedImagePath !== undefined) Config.timerFinishedImagePath = String(o.timerFinishedImagePath)
        if (o.timerFinishedBorderUsesTimerColor !== undefined) Config.timerFinishedBorderUsesTimerColor = !!o.timerFinishedBorderUsesTimerColor
        if (o.timerFinishedBackgroundUsesTimerColor !== undefined) Config.timerFinishedBackgroundUsesTimerColor = !!o.timerFinishedBackgroundUsesTimerColor
        if (o.timerFinishedBackgroundColor !== undefined) Config.timerFinishedBackgroundColor = Schema.normalizeSavedColor(o.timerFinishedBackgroundColor, "#4d000000")
        if (o.timerFinishedImageWidth !== undefined) { var tiw = Number(o.timerFinishedImageWidth); if (isFinite(tiw)) Config.timerFinishedImageWidth = Math.max(50, Math.min(1200, Math.round(tiw))) }
        if (o.timerFinishedImageMargin !== undefined) { var tim = Number(o.timerFinishedImageMargin); if (isFinite(tim)) { tim = Math.max(0, Math.min(100, Math.round(tim))); Config.timerFinishedImageMargin = tim } }
        else {
            var legacyTim = o.timerFinishedImageTopMargin !== undefined ? Number(o.timerFinishedImageTopMargin) : (o.timerFinishedImageBottomMargin !== undefined ? Number(o.timerFinishedImageBottomMargin) : NaN)
            if (isFinite(legacyTim)) { legacyTim = Math.max(0, Math.min(100, Math.round(legacyTim))); Config.timerFinishedImageMargin = legacyTim }
        }
        if (o.timerFinishedTitleUsesTimerColor !== undefined) Config.timerFinishedTitleUsesTimerColor = !!o.timerFinishedTitleUsesTimerColor
        if (o.timerFinishedTitleColor !== undefined) Config.timerFinishedTitleColor = Schema.normalizeSavedColor(o.timerFinishedTitleColor, "#ffffff")
        if (o.timerFinishedTitleFontSize !== undefined) { var ttfs = Number(o.timerFinishedTitleFontSize); if (isFinite(ttfs)) Config.timerFinishedTitleFontSize = Math.max(8, Math.min(72, Math.round(ttfs))) }
        if (o.timerFinishedTitleFont !== undefined) Config.timerFinishedTitleFont = String(o.timerFinishedTitleFont)
        if (o.timerFinishedTitleAlignment !== undefined) { var tta = Number(o.timerFinishedTitleAlignment); if (isFinite(tta)) Config.timerFinishedTitleAlignment = Math.max(0, Math.min(2, Math.round(tta))) }
        if (o.playerPlayingIconY !== undefined) Config.playerPlayingIconY = Number(o.playerPlayingIconY)
        if (o.playerPausedIconY !== undefined) Config.playerPausedIconY = Number(o.playerPausedIconY)
        if (o.playerNextIconY !== undefined) Config.playerNextIconY = Number(o.playerNextIconY)


        return legacyTimerIconOrder
}
