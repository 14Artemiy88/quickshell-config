.pragma library

.import "SettingsSchema.js" as Schema
var SETTINGS_TAB_IDS = ["modules", "time", "dashboard", "themes", "interface", "general", "timers", "player", "mopidy", "weather", "cava", "cpuRam", "network", "volume", "osd", "calendar", "launcher", "launcherSearch", "launcherTabs", "launcherProjects", "launcherActions", "launcherAnimation", "launcherApplications", "notifications", "notificationsDnd", "settingsWindow"]
var DEFAULT_SETTINGS_TAB_LABELS = ({modules:"Модули", time:"Часы", dashboard:"Dashboard", themes:"Темы", interface:"Интерфейс", general:"Общие", timers:"Таймеры", player:"Плеер", mopidy:"Mopidy", weather:"Погода", cava:"CAVA", cpuRam:"CPU/RAM", network:"Сеть", volume:"Громкость", osd:"OSD", calendar:"Календарь", launcher:"Общее", launcherSearch:"Поиск", launcherTabs:"Вкладки", launcherProjects:"Проекты", launcherActions:"Действия", launcherAnimation:"Анимация", launcherApplications:"Приложения", notifications:"Уведомления", notificationsDnd:"Не беспокоить", settingsWindow:"Окно настроек"})

function normalizeSettingsLastActivePageId(value) {
    var pageId = typeof value === "string" ? value.trim() : ""
    return SETTINGS_TAB_IDS.indexOf(pageId) >= 0 ? pageId : "interface"
}

function fallbackNavigationOrder(source) {
    var groupOrder = ["appearance", "modules", "dashboard", "launcher", "notifications", "general"]
    var defaults = {
        appearance: ["themes", "interface", "settingsWindow"],
        modules: ["modules", "time", "timers", "player", "mopidy", "weather", "cava", "cpuRam", "network", "volume", "osd", "calendar"],
        dashboard: ["dashboard"],
        launcher: ["launcher", "launcherSearch", "launcherTabs", "launcherProjects", "launcherActions", "launcherAnimation", "launcherApplications"],
        notifications: ["notifications", "notificationsDnd"],
        general: ["general"]
    }
    var input = source && typeof source === "object" && !Array.isArray(source) ? source : {}
    var result = { groupOrder: [], pagesByGroup: {} }
    var seenGroups = {}
    var savedGroups = Array.isArray(input.groupOrder) ? input.groupOrder : []
    for (var g = 0; g < savedGroups.length; ++g) {
        var groupId = savedGroups[g]
        if (typeof groupId === "string" && defaults[groupId] && !seenGroups[groupId]) {
            seenGroups[groupId] = true
            result.groupOrder.push(groupId)
        }
    }
    for (var dg = 0; dg < groupOrder.length; ++dg)
        if (!seenGroups[groupOrder[dg]]) result.groupOrder.push(groupOrder[dg])
    var savedPages = input.pagesByGroup && typeof input.pagesByGroup === "object" && !Array.isArray(input.pagesByGroup) ? input.pagesByGroup : {}
    for (var p = 0; p < groupOrder.length; ++p) {
        var id = groupOrder[p]
        var pages = []
        var seen = {}
        var candidates = Array.isArray(savedPages[id]) ? savedPages[id] : []
        for (var c = 0; c < candidates.length; ++c) {
            var pageId = candidates[c]
            if (typeof pageId === "string" && defaults[id].indexOf(pageId) >= 0 && !seen[pageId]) {
                seen[pageId] = true
                pages.push(pageId)
            }
        }
        for (var d = 0; d < defaults[id].length; ++d)
            if (!seen[defaults[id][d]]) pages.push(defaults[id][d])
        result.pagesByGroup[id] = pages
    }
    return result
}

function fallbackNavigationOrderFromLegacy(source) {
    var order = fallbackNavigationOrder(null)
    var pagesByGroup = {}
    for (var i = 0; i < order.groupOrder.length; ++i) pagesByGroup[order.groupOrder[i]] = []
    var seen = {}
    var saved = Array.isArray(source) ? source : []
    for (var j = 0; j < saved.length; ++j) {
        var pageId = saved[j]
        if (typeof pageId !== "string" || seen[pageId]) continue
        var groupId = "general"
        for (var k = 0; k < order.groupOrder.length; ++k) {
            var candidateGroup = order.groupOrder[k]
            if (order.pagesByGroup[candidateGroup].indexOf(pageId) >= 0) { groupId = candidateGroup; break }
        }
        if (!pagesByGroup[groupId]) continue
        seen[pageId] = true
        pagesByGroup[groupId].push(pageId)
    }
    return fallbackNavigationOrder({ groupOrder: order.groupOrder, pagesByGroup: pagesByGroup })
}

function normalizeNavigationOrderForOwner(owner, source) {
    return owner && typeof owner.normalizeSettingsNavigationOrder === "function"
        ? owner.normalizeSettingsNavigationOrder(source) : fallbackNavigationOrder(source)
}

function legacyNavigationOrderForOwner(owner, source) {
    return owner && typeof owner.settingsNavigationOrderFromLegacyTabOrder === "function"
        ? owner.settingsNavigationOrderFromLegacyTabOrder(source) : fallbackNavigationOrderFromLegacy(source)
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
        if (o.settingsShowDescriptions !== undefined) Config.settingsShowDescriptions = o.settingsShowDescriptions !== false
        if (o.settingsFontSize !== undefined) {
            var sfs = Number(o.settingsFontSize)
            if (isFinite(sfs)) Config.settingsFontSize = Math.max(6, Math.min(32, Math.round(sfs)))
        }
        // Global UI/font scales are percentage multipliers. Clamp persisted or
        // hand-edited profile values so malformed data cannot collapse a surface.
        if (o.uiScale !== undefined) {
            var moduleUiScale = Number(o.uiScale)
            if (isFinite(moduleUiScale)) Config.uiScale = Math.max(75, Math.min(150, Math.round(moduleUiScale)))
        }
        if (o.fontScale !== undefined) {
            var moduleFontScale = Number(o.fontScale)
            if (isFinite(moduleFontScale)) Config.fontScale = Math.max(75, Math.min(150, Math.round(moduleFontScale)))
        }
        if (o.settingsUiScale !== undefined) {
            var settingsUiScale = Number(o.settingsUiScale)
            if (isFinite(settingsUiScale)) Config.settingsUiScale = Math.max(75, Math.min(150, Math.round(settingsUiScale)))
        }
        if (o.settingsFontScale !== undefined) {
            var settingsFontScale = Number(o.settingsFontScale)
            if (isFinite(settingsFontScale)) Config.settingsFontScale = Math.max(75, Math.min(150, Math.round(settingsFontScale)))
        }
        if (o.cornerRadiusScale !== undefined) {
            var cornerRadiusScale = Number(o.cornerRadiusScale)
            if (isFinite(cornerRadiusScale)) Config.cornerRadiusScale = Math.max(50, Math.min(150, Math.round(cornerRadiusScale)))
        }
        if (o.buttonBordersEnabled !== undefined) Config.buttonBordersEnabled = o.buttonBordersEnabled !== false
        if (o.inputBordersEnabled !== undefined) Config.inputBordersEnabled = o.inputBordersEnabled !== false
        if (o.popupBordersEnabled !== undefined) Config.popupBordersEnabled = o.popupBordersEnabled !== false
        if (o.cardBordersEnabled !== undefined) Config.cardBordersEnabled = o.cardBordersEnabled !== false
        if (o.settingsPadding !== undefined) {
            var sp = Number(o.settingsPadding)
            if (isFinite(sp)) Config.settingsPadding = Math.max(0, Math.min(40, Math.round(sp)))
        }
        if (o.settingsSpacing !== undefined) {
            var ss = Number(o.settingsSpacing)
            if (isFinite(ss)) Config.settingsSpacing = Math.max(0, Math.min(40, Math.round(ss)))
        }
        if (o.settingsSearchHighlightColor !== undefined)
            Config.settingsSearchHighlightColor = Schema.normalizeSavedColor(o.settingsSearchHighlightColor, String(Config.settingsSearchHighlightColor))
        if (o.settingsSearchHighlightBorderWidth !== undefined) {
            var searchBorderWidth = Number(o.settingsSearchHighlightBorderWidth)
            if (isFinite(searchBorderWidth))
                Config.settingsSearchHighlightBorderWidth = Math.max(1, Math.min(5, Math.round(searchBorderWidth)))
        }
        if (o.settingsSearchMatchCountFontSize !== undefined) {
            var searchCountFontSize = Number(o.settingsSearchMatchCountFontSize)
            if (isFinite(searchCountFontSize))
                Config.settingsSearchMatchCountFontSize = Math.max(6, Math.min(12, Math.round(searchCountFontSize)))
        }
        if (o.settingsSearchVisible !== undefined)
            Config.settingsSearchVisible = o.settingsSearchVisible === true
        if (o.settingsLastActivePageId !== undefined)
            Config.settingsLastActivePageId = normalizeSettingsLastActivePageId(o.settingsLastActivePageId)
        if (o.settingsNavigationOrder !== undefined) {
            Config.settingsNavigationOrder = normalizeNavigationOrderForOwner(owner, o.settingsNavigationOrder)
        } else if (o.settingsTabOrder !== undefined) {
            // One-time migration from the old flat list. The former group order
            // was fixed, so only per-group page order can be recovered.
            Config.settingsNavigationOrder = legacyNavigationOrderForOwner(owner, o.settingsTabOrder)
        }
        if (o.settingsTabLabels !== undefined) {
            var normalizedSettingsLabels = normalizeSettingsTabLabels(o.settingsTabLabels, Config.settingsTabLabels)
            // The old single Launcher page is now the first child of its sidebar folder.
            if (normalizedSettingsLabels.launcher === "Лаунчер") normalizedSettingsLabels.launcher = "Общее"
            Config.settingsTabLabels = normalizedSettingsLabels
        }
        if (o.settingsNavigationCollapsedGroups !== undefined)
            Config.settingsNavigationCollapsedGroups = Schema.normalizeSettingsNavigationCollapsedGroups(
                o.settingsNavigationCollapsedGroups, Config.settingsNavigationCollapsedGroups)
        if (o.notificationsDoNotDisturb !== undefined) Config.notificationsDoNotDisturb = o.notificationsDoNotDisturb === true
        if (o.notificationsDndAllowedApps !== undefined) Config.notificationsDndAllowedApps = String(o.notificationsDndAllowedApps || "").slice(0, 4096)
        if (o.notificationsDndBlockedApps !== undefined) Config.notificationsDndBlockedApps = String(o.notificationsDndBlockedApps || "").slice(0, 4096)
        if (o.notificationsHistoryIgnoredApps !== undefined) Config.notificationsHistoryIgnoredApps = String(o.notificationsHistoryIgnoredApps || "").slice(0, 4096)
        if (o.notificationsHistoryLimit !== undefined) {
            var notificationHistoryLimit = Number(o.notificationsHistoryLimit)
            if (isFinite(notificationHistoryLimit)) Config.notificationsHistoryLimit = Math.max(1, Math.min(200, Math.round(notificationHistoryLimit)))
        }
        if (o.notificationsHistoryRetentionDays !== undefined) {
            var notificationHistoryRetentionDays = Number(o.notificationsHistoryRetentionDays)
            if (isFinite(notificationHistoryRetentionDays)) Config.notificationsHistoryRetentionDays = Math.max(0, Math.min(365, Math.round(notificationHistoryRetentionDays)))
        }
        if (o.notificationsDefaultTimeout !== undefined) {
            var notificationTimeout = Number(o.notificationsDefaultTimeout)
            if (isFinite(notificationTimeout)) Config.notificationsDefaultTimeout = Math.max(0, Math.min(120000, Math.round(notificationTimeout)))
        }
        if (o.notificationsCriticalTimeout !== undefined) {
            var criticalNotificationTimeout = Number(o.notificationsCriticalTimeout)
            if (isFinite(criticalNotificationTimeout)) Config.notificationsCriticalTimeout = Math.max(0, Math.min(120000, Math.round(criticalNotificationTimeout)))
        }
        if (o.notificationsShowTimeoutIndicator !== undefined) Config.notificationsShowTimeoutIndicator = !!o.notificationsShowTimeoutIndicator
        if (o.notificationsTimeoutIndicatorColor !== undefined) {
            var timeoutIndicatorColor = typeof o.notificationsTimeoutIndicatorColor === "string"
                ? o.notificationsTimeoutIndicatorColor.trim() : ""
            Config.notificationsTimeoutIndicatorColor = timeoutIndicatorColor === ""
                ? "" : Schema.normalizeSavedColor(timeoutIndicatorColor, "")
        }
        if (o.notificationsTimeoutIndicatorStyle !== undefined) {
            Config.notificationsTimeoutIndicatorStyle = String(o.notificationsTimeoutIndicatorStyle) === "border" ? "border" : "bar"
        }
        if (o.notificationsTimeoutIndicatorDirection !== undefined) {
            Config.notificationsTimeoutIndicatorDirection = String(o.notificationsTimeoutIndicatorDirection) === "counterclockwise"
                ? "counterclockwise" : "clockwise"
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
        if (o.notificationsBackgroundColor !== undefined) Config.notificationsBackgroundColor = Schema.normalizeSavedColor(o.notificationsBackgroundColor, "#4d000000")
        if (o.notificationsSummaryFont !== undefined) {
            Config.notificationsSummaryFont = typeof o.notificationsSummaryFont === "string"
                ? o.notificationsSummaryFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128) : ""
        }
        if (o.notificationsSummaryFontSize !== undefined) {
            var summaryFontSize = Number(o.notificationsSummaryFontSize)
            if (isFinite(summaryFontSize)) Config.notificationsSummaryFontSize = Math.max(8, Math.min(32, Math.round(summaryFontSize)))
        }
        if (o.notificationsSummaryColor !== undefined) {
            var summaryColor = typeof o.notificationsSummaryColor === "string" ? o.notificationsSummaryColor.trim() : ""
            Config.notificationsSummaryColor = summaryColor === "" ? "" : Schema.normalizeSavedColor(summaryColor, "")
        }
        if (o.notificationsAppNameFont !== undefined) {
            Config.notificationsAppNameFont = typeof o.notificationsAppNameFont === "string"
                ? o.notificationsAppNameFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128) : ""
        }
        if (o.notificationsAppNameFontSize !== undefined) {
            var appNameFontSize = Number(o.notificationsAppNameFontSize)
            if (isFinite(appNameFontSize)) Config.notificationsAppNameFontSize = Math.max(8, Math.min(24, Math.round(appNameFontSize)))
        }
        if (o.notificationsAppNameColor !== undefined) {
            var appNameColor = typeof o.notificationsAppNameColor === "string" ? o.notificationsAppNameColor.trim() : ""
            Config.notificationsAppNameColor = appNameColor === "" ? "" : Schema.normalizeSavedColor(appNameColor, "")
        }
        if (o.notificationsAppNameBold !== undefined) Config.notificationsAppNameBold = !!o.notificationsAppNameBold
        if (o.notificationsLeadingVisualSize !== undefined) {
            var leadingVisualSize = Number(o.notificationsLeadingVisualSize)
            if (isFinite(leadingVisualSize)) Config.notificationsLeadingVisualSize = Math.max(24, Math.min(72, Math.round(leadingVisualSize)))
        }
        if (o.notificationsLeadingVisualRadius !== undefined) {
            var leadingVisualRadius = Number(o.notificationsLeadingVisualRadius)
            if (isFinite(leadingVisualRadius)) Config.notificationsLeadingVisualRadius = Math.max(0, Math.min(36, Math.round(leadingVisualRadius)))
        }
        if (o.notificationsCardPadding !== undefined) {
            var notificationCardPadding = Number(o.notificationsCardPadding)
            if (isFinite(notificationCardPadding)) Config.notificationsCardPadding = Math.max(0, Math.min(32, Math.round(notificationCardPadding)))
        }
        if (o.notificationsBodyFont !== undefined) {
            Config.notificationsBodyFont = typeof o.notificationsBodyFont === "string"
                ? o.notificationsBodyFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128) : ""
        }
        if (o.notificationsBodyFontSize !== undefined) {
            var notificationBodyFontSize = Number(o.notificationsBodyFontSize)
            if (isFinite(notificationBodyFontSize)) Config.notificationsBodyFontSize = Math.max(8, Math.min(32, Math.round(notificationBodyFontSize)))
        }
        if (o.notificationsBodyColor !== undefined) {
            var bodyColor = typeof o.notificationsBodyColor === "string" ? o.notificationsBodyColor.trim() : ""
            Config.notificationsBodyColor = bodyColor === "" ? "" : Schema.normalizeSavedColor(bodyColor, "")
        }
        if (o.notificationsShowAppIcon !== undefined) Config.notificationsShowAppIcon = !!o.notificationsShowAppIcon
        if (o.notificationsShowAppIconBackground !== undefined) Config.notificationsShowAppIconBackground = !!o.notificationsShowAppIconBackground
        if (o.notificationsShowBodyImages !== undefined) Config.notificationsShowBodyImages = !!o.notificationsShowBodyImages
        if (o.notificationsShowProgress !== undefined) Config.notificationsShowProgress = !!o.notificationsShowProgress
        if (o.ledFont !== undefined) Config.ledFont = String(o.ledFont)
        if (o.clockFont !== undefined) {
            Config.clockFont = typeof o.clockFont === "string"
                ? o.clockFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128) : ""
        }
        if (o.clockFontSize !== undefined) { var clockFontSize = Number(o.clockFontSize); if (isFinite(clockFontSize)) Config.clockFontSize = Math.max(24, Math.min(72, Math.round(clockFontSize))) }
        if (o.clockDateFontSize !== undefined) { var clockDateFontSize = Number(o.clockDateFontSize); if (isFinite(clockDateFontSize)) Config.clockDateFontSize = Math.max(12, Math.min(36, Math.round(clockDateFontSize))) }
        if (o.clockWeekdayFont !== undefined) {
            Config.clockWeekdayFont = typeof o.clockWeekdayFont === "string"
                ? o.clockWeekdayFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128) : "Ubuntu"
        }
        if (o.clockWeekdayFontSize !== undefined) { var clockWeekdayFontSize = Number(o.clockWeekdayFontSize); if (isFinite(clockWeekdayFontSize)) Config.clockWeekdayFontSize = Math.max(8, Math.min(24, Math.round(clockWeekdayFontSize))) }
        if (o.playerFont !== undefined) Config.playerFont = String(o.playerFont)
        if (o.playerMetaFont !== undefined) Config.playerMetaFont = String(o.playerMetaFont)
        if (o.playerSilenceText !== undefined) Config.playerSilenceText = String(o.playerSilenceText)
        if (o.playerSilenceOutlineColor !== undefined) Config.playerSilenceOutlineColor = String(o.playerSilenceOutlineColor)
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
