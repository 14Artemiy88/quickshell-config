.pragma library

.import "SettingsSchema.js" as Schema

var SETTINGS_TAB_IDS = ["modules", "themes", "general", "timers", "player", "mopidy", "weather", "cava", "cpuRam", "network", "volume", "calendar", "launcher", "notifications", "settingsWindow"]
var DEFAULT_SETTINGS_TAB_LABELS = ({modules:"Модули", themes:"Темы", general:"Общие", timers:"Таймеры", player:"Плеер", mopidy:"Mopidy", weather:"Погода", cava:"CAVA", cpuRam:"CPU/RAM", network:"Сеть", volume:"Громкость", calendar:"Календарь", launcher:"Лаунчер", notifications:"Уведомления", settingsWindow:"Окно настроек"})

function normalizeSettingsTabOrder(source) {
    var result = []
    var seen = ({})
    if (source instanceof Array) {
        for (var i = 0; i < source.length; ++i) {
            // Accept only canonical string IDs. Avoid coercing malformed JSON
            // objects into strings while settings are being loaded.
            if (typeof source[i] !== "string") continue
            var id = source[i]
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

function normalizeSettingsTabLabel(value, fallback) {
    // Labels must remain simple strings. Ignore malformed objects/arrays instead
    // of turning them into UI text such as "[object Object]".
    if (typeof value !== "string") return fallback
    var label = value.trim().slice(0, 32)
    return label || fallback
}

function normalizeSettingsTabLabels(source, current) {
    // Rebuild the map from the supported IDs only. This drops stale/unknown
    // keys from edited files and prevents bad values from leaking across
    // profile switches while still allowing partial updates to preserve labels.
    var result = ({})
    var currentIsObject = current && typeof current === "object" && !(current instanceof Array)
    var sourceIsObject = source && typeof source === "object" && !(source instanceof Array)
    for (var i = 0; i < SETTINGS_TAB_IDS.length; ++i) {
        var id = SETTINGS_TAB_IDS[i]
        var fallback = DEFAULT_SETTINGS_TAB_LABELS[id]
        var currentLabel = currentIsObject && Object.prototype.hasOwnProperty.call(current, id)
            ? normalizeSettingsTabLabel(current[id], fallback) : fallback
        result[id] = sourceIsObject && Object.prototype.hasOwnProperty.call(source, id)
            ? normalizeSettingsTabLabel(source[id], fallback) : currentLabel
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
        if (o.notificationsDefaultTimeout !== undefined) {
            var notificationTimeout = Number(o.notificationsDefaultTimeout)
            if (isFinite(notificationTimeout)) Config.notificationsDefaultTimeout = Math.max(0, Math.min(120000, Math.round(notificationTimeout)))
        }
        if (o.notificationsCriticalTimeout !== undefined) {
            var criticalNotificationTimeout = Number(o.notificationsCriticalTimeout)
            if (isFinite(criticalNotificationTimeout)) Config.notificationsCriticalTimeout = Math.max(0, Math.min(120000, Math.round(criticalNotificationTimeout)))
        }
        // One-time compatibility inputs for older corner/offset placement.
        // Notifications.qml converts them to absolute module geometry once a target screen is known.
        if (o.notificationsPosition !== undefined) {
            var legacyPosition = String(o.notificationsPosition)
            Config.notificationsLegacyPosition = ["top-right", "top-left", "bottom-right", "bottom-left"].indexOf(legacyPosition) >= 0
                ? legacyPosition : "top-right"
            if (o.notificationsVerticalAnchor === undefined)
                Config.notificationsVerticalAnchor = legacyPosition.indexOf("bottom-") === 0 ? "bottom" : "top"
        }
        if (o.notificationsVerticalAnchor !== undefined) {
            var verticalAnchor = String(o.notificationsVerticalAnchor).toLowerCase()
            Config.notificationsVerticalAnchor = verticalAnchor === "bottom" ? "bottom" : "top"
        }
        var legacyNotificationMargin = o.notificationsMargin !== undefined ? Number(o.notificationsMargin) : NaN
        if (o.notificationsPosition === undefined
                && (o.notificationsOffsetX !== undefined || o.notificationsOffsetY !== undefined || isFinite(legacyNotificationMargin)))
            Config.notificationsLegacyPosition = "top-right"
        if (o.notificationsOffsetX !== undefined) {
            var legacyOffsetX = Number(o.notificationsOffsetX)
            if (isFinite(legacyOffsetX)) Config.notificationsLegacyOffsetX = Math.max(0, Math.min(500, Math.round(legacyOffsetX)))
        } else if (isFinite(legacyNotificationMargin)) {
            Config.notificationsLegacyOffsetX = Math.max(0, Math.min(500, Math.round(legacyNotificationMargin)))
        }
        if (o.notificationsOffsetY !== undefined) {
            var legacyOffsetY = Number(o.notificationsOffsetY)
            if (isFinite(legacyOffsetY)) Config.notificationsLegacyOffsetY = Math.max(0, Math.min(500, Math.round(legacyOffsetY)))
        } else if (isFinite(legacyNotificationMargin)) {
            Config.notificationsLegacyOffsetY = Math.max(0, Math.min(500, Math.round(legacyNotificationMargin)))
        }
        if (o.notificationsCardWidth !== undefined) { var notificationWidth = Number(o.notificationsCardWidth); if (isFinite(notificationWidth)) Config.notificationsCardWidth = Math.max(280, Math.min(600, Math.round(notificationWidth))) }
        if (o.notificationsCardSpacing !== undefined) { var notificationSpacing = Number(o.notificationsCardSpacing); if (isFinite(notificationSpacing)) Config.notificationsCardSpacing = Math.max(0, Math.min(32, Math.round(notificationSpacing))) }
        if (o.notificationsImageHeight !== undefined) { var notificationImageHeight = Number(o.notificationsImageHeight); if (isFinite(notificationImageHeight)) Config.notificationsImageHeight = Math.max(0, Math.min(320, Math.round(notificationImageHeight))) }
        if (o.notificationsShowAppIcon !== undefined) Config.notificationsShowAppIcon = !!o.notificationsShowAppIcon
        if (o.notificationsShowBodyImages !== undefined) Config.notificationsShowBodyImages = !!o.notificationsShowBodyImages
        if (o.notificationsShowProgress !== undefined) Config.notificationsShowProgress = !!o.notificationsShowProgress
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
        if (o.timerIconEnabled !== undefined) Config.timerIconEnabled = !!o.timerIconEnabled
        if (o.timerAlarmIcon !== undefined) Config.timerAlarmIcon = String(o.timerAlarmIcon)
        if (o.timerAlarmIconEnabled !== undefined) Config.timerAlarmIconEnabled = !!o.timerAlarmIconEnabled

        var timerOptionsActionIds = ["comment", "duration", "refresh", "toggle_pause", "color"]
        if (o.timerOptionsCommentIcon !== undefined) Config.timerOptionsCommentIcon = String(o.timerOptionsCommentIcon)
        if (o.timerOptionsCommentIconEnabled !== undefined) Config.timerOptionsCommentIconEnabled = !!o.timerOptionsCommentIconEnabled
        if (o.timerOptionsCommentIconSize !== undefined) { var tcis = Number(o.timerOptionsCommentIconSize); if (isFinite(tcis)) Config.timerOptionsCommentIconSize = Math.max(8, Math.min(40, Math.round(tcis))) }
        if (o.timerOptionsDurationIcon !== undefined) Config.timerOptionsDurationIcon = String(o.timerOptionsDurationIcon)
        if (o.timerOptionsDurationIconEnabled !== undefined) Config.timerOptionsDurationIconEnabled = !!o.timerOptionsDurationIconEnabled
        if (o.timerOptionsDurationIconSize !== undefined) { var tdis = Number(o.timerOptionsDurationIconSize); if (isFinite(tdis)) Config.timerOptionsDurationIconSize = Math.max(8, Math.min(40, Math.round(tdis))) }
        if (o.timerOptionsRefreshIcon !== undefined) Config.timerOptionsRefreshIcon = String(o.timerOptionsRefreshIcon)
        if (o.timerOptionsRefreshIconEnabled !== undefined) Config.timerOptionsRefreshIconEnabled = !!o.timerOptionsRefreshIconEnabled
        if (o.timerOptionsRefreshIconSize !== undefined) { var tris = Number(o.timerOptionsRefreshIconSize); if (isFinite(tris)) Config.timerOptionsRefreshIconSize = Math.max(8, Math.min(40, Math.round(tris))) }
        if (o.timerOptionsPauseIcon !== undefined) Config.timerOptionsPauseIcon = String(o.timerOptionsPauseIcon)
        if (o.timerOptionsPauseIconEnabled !== undefined) Config.timerOptionsPauseIconEnabled = !!o.timerOptionsPauseIconEnabled
        if (o.timerOptionsPauseIconSize !== undefined) { var tpis = Number(o.timerOptionsPauseIconSize); if (isFinite(tpis)) Config.timerOptionsPauseIconSize = Math.max(8, Math.min(40, Math.round(tpis))) }
        if (o.timerOptionsColorIcon !== undefined) Config.timerOptionsColorIcon = String(o.timerOptionsColorIcon)
        if (o.timerOptionsColorIconEnabled !== undefined) Config.timerOptionsColorIconEnabled = !!o.timerOptionsColorIconEnabled
        if (o.timerOptionsColorIconSize !== undefined) { var tcis2 = Number(o.timerOptionsColorIconSize); if (isFinite(tcis2)) Config.timerOptionsColorIconSize = Math.max(8, Math.min(40, Math.round(tcis2))) }
        if (o.timerRandomColorMode !== undefined) {
            var timerColorMode = String(o.timerRandomColorMode)
            Config.timerRandomColorMode = ["full", "light", "dark", "custom"].indexOf(timerColorMode) >= 0 ? timerColorMode : "full"
        }
        if (o.timerRandomColorMin !== undefined) Config.timerRandomColorMin = Schema.normalizeSavedColor(o.timerRandomColorMin, "#000000")
        if (o.timerRandomColorMax !== undefined) Config.timerRandomColorMax = Schema.normalizeSavedColor(o.timerRandomColorMax, "#ffffff")
        if (o.timerOptionsActionIconOrder instanceof Array) {
            var timerOptionsOrder = []
            for (var to = 0; to < o.timerOptionsActionIconOrder.length; ++to) {
                var timerOptionsId = String(o.timerOptionsActionIconOrder[to] || "")
                if (timerOptionsActionIds.indexOf(timerOptionsId) >= 0 && timerOptionsOrder.indexOf(timerOptionsId) < 0)
                    timerOptionsOrder.push(timerOptionsId)
            }
            for (var tf = 0; tf < timerOptionsActionIds.length; ++tf) {
                if (timerOptionsOrder.indexOf(timerOptionsActionIds[tf]) < 0)
                    timerOptionsOrder.push(timerOptionsActionIds[tf])
            }
            Config.timerOptionsActionIconOrder = timerOptionsOrder
        }

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
