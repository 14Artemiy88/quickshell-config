var STORAGE_FORMAT = "profile-overrides-v1"
var PROFILE_STORAGE_FORMAT = "sparse-v1"
var SETTINGS_SCHEMA_VERSION = 1

function normalizeDashboardColumnsMode(value) {
    var mode = String(value === undefined || value === null ? "" : value)
    return mode === "auto" || mode === "one" || mode === "two" ? mode : "auto"
}

function normalizeDashboardCardOrder(values) {
    var validIds = ["today", "system", "network", "weather", "media"]
    if (!Array.isArray(values)) return validIds.slice()
    var result = []
    for (var i = 0; i < values.length; ++i) {
        var id = String(values[i] || "")
        if (validIds.indexOf(id) >= 0 && result.indexOf(id) < 0) result.push(id)
    }
    for (var j = 0; j < validIds.length; ++j)
        if (result.indexOf(validIds[j]) < 0) result.push(validIds[j])
    return result
}

function normalizeDashboardCards(values, orderValues) {
    var validIds = ["today", "system", "network", "weather", "media"]
    if (!Array.isArray(values)) return validIds.slice()

    // Migrate the exact previous default only when the stored order also
    // proves this is a pre-Today profile. A current profile can intentionally
    // disable Today while retaining all four module cards; in that case the
    // five-card order still contains "today" and must remain untouched.
    var legacyIds = ["system", "network", "weather", "media"]
    var hasLegacySelection = values.length === legacyIds.length
    if (hasLegacySelection) {
        for (var legacyIndex = 0; legacyIndex < legacyIds.length; ++legacyIndex) {
            var legacyId = String(values[legacyIndex] || "")
            if (legacyIds.indexOf(legacyId) < 0 || values.indexOf(legacyId) !== legacyIndex) {
                hasLegacySelection = false
                break
            }
        }
    }
    var orderContainsToday = Array.isArray(orderValues) && orderValues.indexOf("today") >= 0
    if (hasLegacySelection && !orderContainsToday) return validIds.slice()

    var result = []
    for (var i = 0; i < values.length; ++i) {
        var id = String(values[i] || "")
        if (validIds.indexOf(id) >= 0 && result.indexOf(id) < 0) result.push(id)
    }
    return result
}

function normalizeDashboardCardSizes(values) {
    var validIds = ["today", "system", "network", "weather", "media"]
    var source = values && typeof values === "object" && !Array.isArray(values) ? values : ({})
    var result = {}
    for (var i = 0; i < validIds.length; ++i) {
        var id = validIds[i]
        var mode = String(source[id] === undefined || source[id] === null ? "" : source[id])
        result[id] = mode === "compact" || mode === "expanded" ? mode : "compact"
    }
    return result
}

function cloneValue(value) {
    if (value === undefined) return undefined
    return JSON.parse(JSON.stringify(value))
}

function isPlainObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
}

function sameValue(a, b) {
    if (a === b) return true
    if (a === null || b === null || a === undefined || b === undefined) return a === b
    if (Array.isArray(a) || Array.isArray(b)) {
        if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false
        for (var i = 0; i < a.length; ++i) if (!sameValue(a[i], b[i])) return false
        return true
    }
    if (isPlainObject(a) && isPlainObject(b)) {
        var ak = Object.keys(a).sort()
        var bk = Object.keys(b).sort()
        if (ak.length !== bk.length) return false
        for (var j = 0; j < ak.length; ++j) {
            if (ak[j] !== bk[j] || !sameValue(a[ak[j]], b[bk[j]])) return false
        }
        return true
    }
    return false
}

function diffValue(base, current) {
    if (sameValue(base, current)) return undefined
    if (isPlainObject(base) && isPlainObject(current)) {
        var baseKeys = Object.keys(base)
        var currentKeys = Object.keys(current)
        for (var m = 0; m < baseKeys.length; ++m) {
            if (!Object.prototype.hasOwnProperty.call(current, baseKeys[m])) {
                var replacement = {}
                replacement.__profile_replace__ = cloneValue(current)
                return replacement
            }
        }
        var out = {}
        for (var i = 0; i < currentKeys.length; ++i) {
            var key = currentKeys[i]
            var delta = diffValue(base[key], current[key])
            if (delta !== undefined) out[key] = delta
        }
        return out
    }
    return cloneValue(current)
}

function activeProfileBase(owner) {
    var base = cloneValue(owner.profileDefaults || {}) || {}
    delete base.weatherToken
    delete base.settingsLastActivePageId
    var name = String(owner.activeProfile || "")
    if (!name || !owner.profiles || !Object.prototype.hasOwnProperty.call(owner.profiles, name))
        return base
    if (typeof owner.expandedProfileData === "function") {
        var expanded = owner.expandedProfileData(name)
        if (expanded && typeof expanded === "object") {
            delete expanded.weatherToken
            delete expanded.settingsLastActivePageId
            return cloneValue(expanded)
        }
    }
    var profile = owner.profiles[name]
    if (String(owner.profileStorageFormat || "") === PROFILE_STORAGE_FORMAT && isPlainObject(profile)) {
        // Profiles.js uses this same recursive delta format. Arrays and scalar
        // values replace their base; nested objects merge recursively.
        return mergeProfileDelta(base, profile)
    }
    return cloneValue(profile || base)
}

function mergeProfileDelta(base, delta) {
    if (isPlainObject(delta) && Object.keys(delta).length === 1 && Object.prototype.hasOwnProperty.call(delta, "__profile_replace__"))
        return cloneValue(delta.__profile_replace__)
    if (isPlainObject(base) && isPlainObject(delta)) {
        var merged = cloneValue(base)
        for (var key in delta) {
            if (!Object.prototype.hasOwnProperty.call(delta, key)) continue
            merged[key] = mergeProfileDelta(base[key], delta[key])
        }
        return merged
    }
    return cloneValue(delta)
}

function snapshotObject(owner, config) {

        var modules = {}
        for (var i=0; i<owner.moduleNames.length; ++i) modules[owner.moduleNames[i]] = owner[owner.moduleNames[i]]
        var colors = {}
        for (var j=0; j<owner.colorNames.length; ++j) colors[owner.colorNames[j]] = String(config[owner.colorNames[j]])
        return {
            weatherToken: String(owner.weatherToken || "").trim(),
            font: config.font, fontSize: config.fontSize, fontScale: config.fontScale, uiScale: config.uiScale,
            settingsFont: config.settingsFont, settingsFontSize: config.settingsFontSize,
            settingsFontScale: config.settingsFontScale, settingsUiScale: config.settingsUiScale,
            settingsShowDescriptions: config.settingsShowDescriptions !== false,
            settingsPadding: config.settingsPadding, settingsSpacing: config.settingsSpacing,
            settingsSearchHighlightColor: String(config.settingsSearchHighlightColor),
            settingsSearchHighlightBorderWidth: config.settingsSearchHighlightBorderWidth,
            settingsSearchMatchCountFontSize: config.settingsSearchMatchCountFontSize,
            settingsSearchVisible: config.settingsSearchVisible,
            settingsNavigationOrder: cloneValue(owner && typeof owner.normalizeSettingsNavigationOrder === "function"
                ? owner.normalizeSettingsNavigationOrder(config.settingsNavigationOrder)
                : (config.settingsNavigationOrder || {})),
            settingsTabLabels: cloneValue(config.settingsTabLabels || {}),
            dashboardVisibleCards: normalizeDashboardCards(config.dashboardVisibleCards, config.dashboardCardOrder),
            dashboardCardOrder: normalizeDashboardCardOrder(config.dashboardCardOrder),
            dashboardColumnsMode: normalizeDashboardColumnsMode(config.dashboardColumnsMode),
            dashboardCardSizes: normalizeDashboardCardSizes(config.dashboardCardSizes),
            notificationsDefaultTimeout: config.notificationsDefaultTimeout,
            notificationsDoNotDisturb: config.notificationsDoNotDisturb,
            notificationsDndOsdEnabled: config.notificationsDndOsdEnabled,
            osdIntegrateWithNotifications: config.osdIntegrateWithNotifications === true,
            notificationsDndOsdHideDelay: config.notificationsDndOsdHideDelay,
            notificationsDndOsdAnimationDuration: config.notificationsDndOsdAnimationDuration,
            animationNotificationsDndOsdMorphProfile: config.animationNotificationsDndOsdMorphProfile,
            notificationsDndAllowedApps: String(config.notificationsDndAllowedApps || ""),
            notificationsDndBlockedApps: String(config.notificationsDndBlockedApps || ""),
            notificationsHistoryIgnoredApps: String(config.notificationsHistoryIgnoredApps || ""),
            notificationsHistoryLimit: config.notificationsHistoryLimit,
            notificationsHistoryRetentionDays: config.notificationsHistoryRetentionDays,
            notificationsCriticalTimeout: config.notificationsCriticalTimeout,
            notificationsShowTimeoutIndicator: config.notificationsShowTimeoutIndicator,
            notificationsTimeoutIndicatorColor: config.notificationsTimeoutIndicatorColor,
            notificationsTimeoutIndicatorStyle: config.notificationsTimeoutIndicatorStyle,
            notificationsTimeoutIndicatorDirection: config.notificationsTimeoutIndicatorDirection,
            notificationsVerticalAnchor: config.notificationsVerticalAnchor,
            notificationsCardWidth: config.notificationsCardWidth,
            notificationsCardSpacing: config.notificationsCardSpacing,
            notificationsImageHeight: config.notificationsImageHeight,
            notificationsBackgroundColor: String(config.notificationsBackgroundColor),
            notificationsSummaryFont: config.notificationsSummaryFont,
            notificationsSummaryFontSize: config.notificationsSummaryFontSize,
            notificationsSummaryColor: String(config.notificationsSummaryColor),
            notificationsAppNameFont: config.notificationsAppNameFont,
            notificationsAppNameFontSize: config.notificationsAppNameFontSize,
            notificationsAppNameColor: String(config.notificationsAppNameColor),
            notificationsAppNameBold: config.notificationsAppNameBold,
            notificationsLeadingVisualSize: config.notificationsLeadingVisualSize,
            notificationsLeadingVisualRadius: config.notificationsLeadingVisualRadius,
            notificationsCardPadding: config.notificationsCardPadding,
            notificationsBodyFont: config.notificationsBodyFont,
            notificationsBodyFontSize: config.notificationsBodyFontSize,
            notificationsBodyColor: String(config.notificationsBodyColor),
            notificationsShowAppIcon: config.notificationsShowAppIcon,
            notificationsShowAppIconBackground: config.notificationsShowAppIconBackground,
            notificationsShowBodyImages: config.notificationsShowBodyImages,
            notificationsShowProgress: config.notificationsShowProgress,
            animationNotificationsMorphDuration: config.animationNotificationsMorphDuration,
            animationNotificationsMorphProfile: config.animationNotificationsMorphProfile,
            animationNotificationsVisibilityStyle: config.animationNotificationsVisibilityStyle,
            animationNotificationsVisibilityProfile: config.animationNotificationsVisibilityProfile,
            launcherEnabled: config.launcherEnabled,
            launcherWidth: config.launcherWidth, launcherHeight: config.launcherHeight,
            launcherItemHeight: config.launcherItemHeight, launcherItemRadius: config.launcherItemRadius, launcherRadius: config.launcherRadius,
            launcherBackdropOpacity: config.launcherBackdropOpacity,
            launcherBackground: String(config.launcherBackground),
            launcherTitleText: config.launcherTitleText,
            launcherTitleFont: config.launcherTitleFont,
            launcherTitleFontSize: config.launcherTitleFontSize,
            launcherTitleY: config.launcherTitleY,
            launcherTitleColor: String(config.launcherTitleColor),
            launcherTitleLetterSpacing: config.launcherTitleLetterSpacing,
            launcherTitleBold: config.launcherTitleBold,
            launcherSearchFont: config.launcherSearchFont,
            launcherSearchPlaceholder: config.launcherSearchPlaceholder,
            launcherSearchFontSize: config.launcherSearchFontSize,
            launcherSearchHeight: config.launcherSearchHeight,
            launcherSearchRadius: config.launcherSearchRadius,
            launcherSearchBackground: String(config.launcherSearchBackground),
            launcherDefaultMode: config.launcherDefaultMode,
            launcherShowResultCount: config.launcherShowResultCount,
            launcherVimKeybinds: config.launcherVimKeybinds,
            launcherShowNavigationHints: config.launcherShowNavigationHints,
            launcherNavigationHintsHeight: config.launcherNavigationHintsHeight,
            launcherNavigationHintsFontSize: config.launcherNavigationHintsFontSize,
            launcherNavigationHintsTextY: config.launcherNavigationHintsTextY,
            launcherFuzzySearchApps: config.launcherFuzzySearchApps,
            launcherFuzzySearchActions: config.launcherFuzzySearchActions,
            launcherFuzzySearchSchemes: config.launcherFuzzySearchSchemes,
            launcherFuzzySearchWallpapers: config.launcherFuzzySearchWallpapers,
            launcherDynamicSchemeVariant: String(config.launcherDynamicSchemeVariant || "scheme-tonal-spot"),
            launcherWallpaperDirectory: String(config.launcherWallpaperDirectory || ""),
            launcherCrossSearchProjects: config.launcherCrossSearchProjects,
            launcherCrossSearchRunHistory: config.launcherCrossSearchRunHistory,
            launcherCrossSearchCalculator: config.launcherCrossSearchCalculator,
            launcherTabOrder: JSON.parse(JSON.stringify(config.launcherTabOrder || [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])),
            launcherTabVisible: JSON.parse(JSON.stringify(config.launcherTabVisible || [true, true, true, true, true, true, true, true, true, true])),
            launcherTabLabels: JSON.parse(JSON.stringify(config.launcherTabLabels || ["Apps", "Run", "Windows", "Clipboard", "Power", "Network", "Packages", "Pass", "Projects", "Calculator"])),
            launcherTabIcons: JSON.parse(JSON.stringify(config.launcherTabIcons || ["󰀻", "", "󰖯", "󰅇", "", "󰖩", "󱄅", "󰌋", "", "󰃬"])),
            launcherDisabledBuiltinActions: JSON.parse(JSON.stringify(config.launcherDisabledBuiltinActions || [])),
            launcherProjects: JSON.parse(JSON.stringify(config.launcherProjects || [])),
            launcherCustomActions: JSON.parse(JSON.stringify(config.launcherCustomActions || [])),
            launcherFavoriteApps: JSON.parse(JSON.stringify(config.launcherFavoriteApps || [])),
            launcherHiddenApps: JSON.parse(JSON.stringify(config.launcherHiddenApps || [])),
            ledFont: config.ledFont,
            clockFont: config.clockFont, clockDateFont: config.clockDateFont, clockFontSize: config.clockFontSize,
            clockDateFontSize: config.clockDateFontSize, clockWeekdayFont: config.clockWeekdayFont,
            clockWeekdayFontSize: config.clockWeekdayFontSize,
            clockTimeColor: config.clockTimeColor, clockDateColor: config.clockDateColor,
            clockWeekdayColor: config.clockWeekdayColor, clockPaddingX: config.clockPaddingX,
            clockPaddingY: config.clockPaddingY, clockColumnSpacing: config.clockColumnSpacing,
            clockDetailsRightPadding: config.clockDetailsRightPadding,
            playerFont: config.playerFont, playerMetaFont: config.playerMetaFont, playerSilenceText: config.playerSilenceText,
            playerOsdEnabled: config.playerOsdEnabled, playerOsdHideDelay: config.playerOsdHideDelay, playerOsdAnimationDuration: config.playerOsdAnimationDuration,
            animationDashboardVisibilityStyle: config.animationDashboardVisibilityStyle,
            animationDashboardVisibilityProfile: config.animationDashboardVisibilityProfile,
            animationDashboardVisibilityDuration: config.animationDashboardVisibilityDuration,
            animationCalendarVisibilityStyle: config.animationCalendarVisibilityStyle,
            animationCalendarVisibilityProfile: config.animationCalendarVisibilityProfile,
            animationMopidyVisibilityStyle: config.animationMopidyVisibilityStyle,
            animationMopidyVisibilityProfile: config.animationMopidyVisibilityProfile,
            animationMopidyMorphDuration: config.animationMopidyMorphDuration,
            animationMopidyMorphProfile: config.animationMopidyMorphProfile,
            animationPlayerMorphDuration: config.animationPlayerMorphDuration,
            animationPlayerMorphProfile: config.animationPlayerMorphProfile,
            animationPlayerOsdMorphProfile: config.animationPlayerOsdMorphProfile,
            animationWeatherMorphDuration: config.animationWeatherMorphDuration,
            animationWeatherHourlyDuration: config.animationWeatherHourlyDuration,
            animationWeatherMorphProfile: config.animationWeatherMorphProfile,
            animationTimerMorphDuration: config.animationTimerMorphDuration,
            animationTimerMorphProfile: config.animationTimerMorphProfile,
            animationNetworkVisibilityStyle: config.animationNetworkVisibilityStyle,
            animationNetworkVisibilityProfile: config.animationNetworkVisibilityProfile,
            animationNetworkVisibilityDuration: config.animationNetworkVisibilityDuration,
            animationNetworkMorphDuration: config.animationNetworkMorphDuration,
            animationNetworkMorphProfile: config.animationNetworkMorphProfile,
            animationCavaMorphDuration: config.animationCavaMorphDuration,
            animationCavaMorphProfile: config.animationCavaMorphProfile,
            animationCalendarMorphDuration: config.animationCalendarMorphDuration,
            animationCalendarMorphProfile: config.animationCalendarMorphProfile,
            animationCpuMorphDuration: config.animationCpuMorphDuration,
            animationCpuMorphProfile: config.animationCpuMorphProfile,
            animationLauncherMorphDuration: config.animationLauncherMorphDuration,
            animationLauncherMorphProfile: config.animationLauncherMorphProfile,
            animationTimerVisibilityStyle: config.animationTimerVisibilityStyle,
            animationTimerVisibilityProfile: config.animationTimerVisibilityProfile,
            animationTimerOptionsVisibilityStyle: config.animationTimerOptionsVisibilityStyle,
            animationTimerOptionsVisibilityProfile: config.animationTimerOptionsVisibilityProfile,
            animationSettingsVisibilityStyle: config.animationSettingsVisibilityStyle,
            animationSettingsVisibilityProfile: config.animationSettingsVisibilityProfile,
            animationVolumeStreamsVisibilityStyle: config.animationVolumeStreamsVisibilityStyle,
            animationVolumeStreamsVisibilityProfile: config.animationVolumeStreamsVisibilityProfile,
            animationVolumeMorphProfile: config.animationVolumeMorphProfile,
            animationVolumeOsdMorphProfile: config.animationVolumeOsdMorphProfile,
            animationTimerOptionsDuration: config.animationTimerOptionsDuration, animationCalendarSlideDuration: config.animationCalendarSlideDuration, animationCalendarFadeDuration: config.animationCalendarFadeDuration,
            volumeStreamsAnimationDuration: config.volumeStreamsAnimationDuration,
            systemMonitorInterval: config.systemMonitorInterval, cpuUpdateInterval: config.cpuUpdateInterval, playerUpdateInterval: config.playerUpdateInterval,
            volumeOsdHideDelay: config.volumeOsdHideDelay, volumeOsdAnimationDuration: config.volumeOsdAnimationDuration,
            weatherNowIntervalMinutes: config.weatherNowIntervalMinutes, weatherHourlyIntervalMinutes: config.weatherHourlyIntervalMinutes, weatherDailyIntervalMinutes: config.weatherDailyIntervalMinutes, weatherRetryDelayMinutes: config.weatherRetryDelayMinutes, weatherManualRefreshCooldownSeconds: config.weatherManualRefreshCooldownSeconds,
            timerMinHeight: config.timerMinHeight, volumeMinHeight: config.volumeMinHeight, volumeMaxHeight: config.volumeMaxHeight, volumeOsdEnabled: config.volumeOsdEnabled,
            timerElapsedFont: config.timerElapsedFont, timerElapsedFontSize: config.timerElapsedFontSize,
            timerWheelStep: config.timerWheelStep, timerCommentWidth: config.timerCommentWidth, timerCommentMaxLength: config.timerCommentMaxLength, timerCommentGap: config.timerCommentGap, timerCommentAlignFurthest: config.timerCommentAlignFurthest,
            timerRowSpacing: config.timerRowSpacing,
            timerRowTopMargin: config.timerRowTopMargin, timerRowRightMargin: config.timerRowRightMargin,
            timerButtonFadeDuration: config.timerButtonFadeDuration, timerButtonSlideDuration: config.timerButtonSlideDuration, timerButtonIconFadeDuration: config.timerButtonIconFadeDuration,
            timerIcon: config.timerIcon, timerIconEnabled: config.timerIconEnabled, timerIconOrder: config.timerIconOrder, timerIconSize: config.timerIconSize, timerIconX: config.timerIconX, timerIconY: config.timerIconY,
            timerAlarmIcon: config.timerAlarmIcon, timerAlarmIconEnabled: config.timerAlarmIconEnabled, timerAlarmIconSize: config.timerAlarmIconSize, timerAlarmIconX: config.timerAlarmIconX, timerAlarmIconY: config.timerAlarmIconY,
            timerOptionsCommentIcon: config.timerOptionsCommentIcon, timerOptionsCommentIconEnabled: config.timerOptionsCommentIconEnabled, timerOptionsCommentIconSize: config.timerOptionsCommentIconSize,
            timerOptionsDurationIcon: config.timerOptionsDurationIcon, timerOptionsDurationIconEnabled: config.timerOptionsDurationIconEnabled, timerOptionsDurationIconSize: config.timerOptionsDurationIconSize,
            timerOptionsRefreshIcon: config.timerOptionsRefreshIcon, timerOptionsRefreshIconEnabled: config.timerOptionsRefreshIconEnabled, timerOptionsRefreshIconSize: config.timerOptionsRefreshIconSize,
            timerOptionsPauseIcon: config.timerOptionsPauseIcon, timerOptionsPauseIconEnabled: config.timerOptionsPauseIconEnabled, timerOptionsPauseIconSize: config.timerOptionsPauseIconSize,
            timerOptionsColorIcon: config.timerOptionsColorIcon, timerOptionsColorIconEnabled: config.timerOptionsColorIconEnabled, timerOptionsColorIconSize: config.timerOptionsColorIconSize,
            timerOptionsActionIconOrder: JSON.parse(JSON.stringify(config.timerOptionsActionIconOrder || ["comment", "duration", "refresh", "toggle_pause", "color"])),
            timerRandomColorMode: config.timerRandomColorMode, timerRandomColorMin: String(config.timerRandomColorMin), timerRandomColorMax: String(config.timerRandomColorMax),
            timerFinishedImageEnabled: config.timerFinishedImageEnabled, timerFinishedImagePath: config.timerFinishedImagePath,
            timerFinishedBorderUsesTimerColor: config.timerFinishedBorderUsesTimerColor, timerFinishedBackgroundUsesTimerColor: config.timerFinishedBackgroundUsesTimerColor, timerFinishedBackgroundColor: String(config.timerFinishedBackgroundColor),
            timerFinishedImageWidth: config.timerFinishedImageWidth, timerFinishedImageMargin: config.timerFinishedImageMargin,
            timerFinishedTitleUsesTimerColor: config.timerFinishedTitleUsesTimerColor, timerFinishedTitleColor: String(config.timerFinishedTitleColor), timerFinishedTitleFontSize: config.timerFinishedTitleFontSize, timerFinishedTitleFont: config.timerFinishedTitleFont, timerFinishedTitleAlignment: config.timerFinishedTitleAlignment,
            playerSilenceFontSize: config.playerSilenceFontSize, playerSilenceLongFontSize: config.playerSilenceLongFontSize,
            playerSilenceOutlineColor: String(config.playerSilenceOutlineColor), playerSilenceOutlineWidth: config.playerSilenceOutlineWidth,
            playerMetaFontSize: config.playerMetaFontSize,
            playerTextOutlineEnabled: config.playerTextOutlineEnabled, playerTextOutlineColor: config.playerTextOutlineColor,
            playerMetaSecondaryFontSize: config.playerMetaSecondaryFontSize, playerMetaLineSpacing: config.playerMetaLineSpacing, playerBoldArtist: config.playerBoldArtist,
            playerShowProgress: config.playerShowProgress, playerPlayingIconSize: config.playerPlayingIconSize, playerPausedIconSize: config.playerPausedIconSize, playerNextIconSize: config.playerNextIconSize, playerPlayingIconY: config.playerPlayingIconY, playerPausedIconY: config.playerPausedIconY, playerNextIconY: config.playerNextIconY, playerPlayingIcon: config.playerPlayingIcon, playerPausedIcon: config.playerPausedIcon, playerNextIcon: config.playerNextIcon,
            backgroundBlurRadius: config.backgroundBlurRadius,
            playerMetadataXPadding: config.playerMetadataXPadding,
            playerMetadataY: config.playerMetadataY, playerProgressY: config.playerProgressY,
            playerProgressTrackHeight: config.playerProgressTrackHeight,
            playerControlTopMargin: config.playerControlTopMargin, playerControlGap: config.playerControlGap,
            playerTimeFontSize: config.playerTimeFontSize, playerTimeFont: config.playerTimeFont, playerTimeY: config.playerTimeY, playerTimeRightPadding: config.playerTimeRightPadding, playerCoverOpacity: config.playerCoverOpacity,
            playerSilenceWidth: config.playerSilenceWidth, playerProgressTrackOffsetY: config.playerProgressTrackOffsetY, playerPriority: JSON.parse(JSON.stringify(config.playerPriority || [])),
            mopidyShowTrackNumbers: config.mopidyShowTrackNumbers, mopidyTopIconOrder: config.mopidyTopIconOrder, mopidyMoveUpIcon: config.mopidyMoveUpIcon, mopidyMoveUpIconSize: config.mopidyMoveUpIconSize, mopidyMoveUpIconX: config.mopidyMoveUpIconX, mopidyMoveUpIconY: config.mopidyMoveUpIconY, mopidyShowMoveUpIcon: config.mopidyShowMoveUpIcon, mopidyMoveDownIcon: config.mopidyMoveDownIcon, mopidyMoveDownIconSize: config.mopidyMoveDownIconSize, mopidyMoveDownIconX: config.mopidyMoveDownIconX, mopidyMoveDownIconY: config.mopidyMoveDownIconY, mopidyShowMoveDownIcon: config.mopidyShowMoveDownIcon, mopidyGroupAlbums: config.mopidyGroupAlbums, mopidyBrowseCoverMode: config.mopidyBrowseCoverMode, mopidyBrowseCoverKeepSelectedVisible: config.mopidyBrowseCoverKeepSelectedVisible,
            mopidyAlbumFont: config.mopidyAlbumFont, mopidyAlbumFontSize: config.mopidyAlbumFontSize, mopidyAlbumBold: config.mopidyAlbumBold, mopidyTrackFont: config.mopidyTrackFont, mopidyTrackFontSize: config.mopidyTrackFontSize, mopidyTrackRowHeight: config.mopidyTrackRowHeight, mopidyArtistFont: config.mopidyArtistFont, mopidyArtistFontSize: config.mopidyArtistFontSize, mopidyArtistBold: config.mopidyArtistBold, mopidyArtistItalic: config.mopidyArtistItalic, mopidyTrackArtistDisplayMode: config.mopidyTrackArtistDisplayMode, mopidyTrackArtistGap: config.mopidyTrackArtistGap, mopidyTrackArtistSeparator: config.mopidyTrackArtistSeparator, mopidyDurationFont: config.mopidyDurationFont, mopidyDurationFontSize: config.mopidyDurationFontSize, mopidyAlbumSeparator: config.mopidyAlbumSeparator,
            mopidyBackground: String(config.mopidyBackground), mopidyToggleWithPlayerRightClick: config.mopidyToggleWithPlayerRightClick, mopidyHideTopPanel: config.mopidyHideTopPanel, mopidyTopPanelHoverHeight: config.mopidyTopPanelHoverHeight, mopidyTopPanelOffsetY: config.mopidyTopPanelOffsetY, mopidyTopPanelBackground: config.mopidyTopPanelBackground, mopidyHoverMode: config.mopidyHoverMode, mopidyHoverColor: config.mopidyHoverColor,
            mopidyStopIcon: config.mopidyStopIcon, mopidyStopIconSize: config.mopidyStopIconSize, mopidyStopIconX: config.mopidyStopIconX, mopidyStopIconY: config.mopidyStopIconY,
            mopidyRefreshIcon: config.mopidyRefreshIcon, mopidyRefreshIconSize: config.mopidyRefreshIconSize, mopidyRefreshIconX: config.mopidyRefreshIconX, mopidyRefreshIconY: config.mopidyRefreshIconY,
            mopidyClearIcon: config.mopidyClearIcon, mopidyClearIconSize: config.mopidyClearIconSize, mopidyClearIconX: config.mopidyClearIconX, mopidyClearIconY: config.mopidyClearIconY, mopidyControlIconColor: config.mopidyControlIconColor, mopidyShowStopIcon: config.mopidyShowStopIcon, mopidyShowRefreshIcon: config.mopidyShowRefreshIcon, mopidyShowClearIcon: config.mopidyShowClearIcon, mopidyShowQueueTotalDuration: config.mopidyShowQueueTotalDuration, mopidyQueueDurationMode: config.mopidyQueueDurationMode, mopidyQueueDurationFont: config.mopidyQueueDurationFont, mopidyQueueDurationFontSize: config.mopidyQueueDurationFontSize, mopidyQueueDurationColor: config.mopidyQueueDurationColor, mopidyQueueDurationX: config.mopidyQueueDurationX, mopidyQueueDurationY: config.mopidyQueueDurationY, mopidyQueueDurationAlignment: config.mopidyQueueDurationAlignment, mopidyShowAlbumRemaining: config.mopidyShowAlbumRemaining, mopidyShowTrackRemaining: config.mopidyShowTrackRemaining, mopidyShuffleIcon: config.mopidyShuffleIcon, mopidyShuffleIconSize: config.mopidyShuffleIconSize, mopidyShuffleIconX: config.mopidyShuffleIconX, mopidyShuffleIconY: config.mopidyShuffleIconY, mopidyShowShuffleIcon: config.mopidyShowShuffleIcon, mopidyRepeatIcon: config.mopidyRepeatIcon, mopidyRepeatIconSize: config.mopidyRepeatIconSize, mopidyRepeatIconX: config.mopidyRepeatIconX, mopidyRepeatIconY: config.mopidyRepeatIconY, mopidyShowRepeatIcon: config.mopidyShowRepeatIcon, mopidyOpenAddIcon: config.mopidyOpenAddIcon, mopidyOpenAddIconSize: config.mopidyOpenAddIconSize, mopidyOpenAddIconX: config.mopidyOpenAddIconX, mopidyOpenAddIconY: config.mopidyOpenAddIconY, mopidyShowOpenAddIcon: config.mopidyShowOpenAddIcon, mopidyAddIcon: config.mopidyAddIcon, mopidyAddIconSize: config.mopidyAddIconSize, mopidyAddIconX: config.mopidyAddIconX, mopidyAddIconY: config.mopidyAddIconY, mopidyShowAddIcon: config.mopidyShowAddIcon, mopidySwitchPlaylistIcon: config.mopidySwitchPlaylistIcon, mopidySwitchPlaylistIconSize: config.mopidySwitchPlaylistIconSize, mopidySwitchPlaylistIconX: config.mopidySwitchPlaylistIconX, mopidySwitchPlaylistIconY: config.mopidySwitchPlaylistIconY, mopidyShowSwitchPlaylistIcon: config.mopidyShowSwitchPlaylistIcon, mopidyPlaylistDeleteIcon: config.mopidyPlaylistDeleteIcon, mopidyPlaylistDeleteIconSize: config.mopidyPlaylistDeleteIconSize, mopidyPlaylistDeleteIconX: config.mopidyPlaylistDeleteIconX, mopidyPlaylistDeleteIconY: config.mopidyPlaylistDeleteIconY, mopidyShowPlaylistDeleteIcon: config.mopidyShowPlaylistDeleteIcon,
            mopidyEmptyQueueText: config.mopidyEmptyQueueText, mopidyUnavailableText: config.mopidyUnavailableText, mopidyStatusFont: config.mopidyStatusFont, mopidyStatusFontSize: config.mopidyStatusFontSize, mopidyStatusLongFontSize: config.mopidyStatusLongFontSize, mopidyStatusWidth: config.mopidyStatusWidth,
            mopidyVolumeIcon: config.mopidyVolumeIcon, mopidyMutedIcon: config.mopidyMutedIcon,
            mopidyVolumeIconSize: config.mopidyVolumeIconSize, mopidyVolumeIconX: config.mopidyVolumeIconX, mopidyVolumeIconY: config.mopidyVolumeIconY,
            mopidyMutedIconSize: config.mopidyMutedIconSize, mopidyMutedIconX: config.mopidyMutedIconX, mopidyMutedIconY: config.mopidyMutedIconY,
            mopidyShowVolumeIcon: config.mopidyShowVolumeIcon, mopidyShowVolumePercent: config.mopidyShowVolumePercent, mopidyVolumeStep: config.mopidyVolumeStep,
            calendarPreviousIcon: config.calendarPreviousIcon, calendarNextIcon: config.calendarNextIcon,
            calendarPreviousSize: config.calendarPreviousSize, calendarNextSize: config.calendarNextSize, calendarArrowY: config.calendarArrowY,
            calendarPreviousX: config.calendarPreviousX, calendarNextX: config.calendarNextX,
            calendarTitleFontSize: config.calendarTitleFontSize, calendarTitleY: config.calendarTitleY, calendarTitleFont: config.calendarTitleFont,
            calendarWeekdayFontSize: config.calendarWeekdayFontSize, calendarWeekdayY: config.calendarWeekdayY, calendarWeekdayFont: config.calendarWeekdayFont,
            calendarDayFontSize: config.calendarDayFontSize, calendarDayY: config.calendarDayY, calendarDayFont: config.calendarDayFont,
            calendarAdjacentDaysColor: config.calendarAdjacentDaysColor,
            calendarWeekendColor: config.calendarWeekendColor,
            calendarPastDaysColorEnabled: config.calendarPastDaysColorEnabled, calendarPastDaysColor: config.calendarPastDaysColor,
            calendarAlwaysVisible: config.calendarAlwaysVisible,
            calendarNoteMarkerStyle: config.calendarNoteMarkerStyle,
            calendarNoteMarkerPosition: config.calendarNoteMarkerPosition, calendarNoteFrameColor: config.calendarNoteFrameColor,
            weatherFont: config.weatherFont, weatherIconSize: config.weatherIconSize, weatherArrowSize: config.weatherArrowSize, weatherArrowYOffset: config.weatherArrowYOffset, weatherWindArrowGap: config.weatherWindArrowGap,
            weatherHourlyCount: config.weatherHourlyCount, weatherDailyCount: config.weatherDailyCount,
            weatherIconX: config.weatherIconX, weatherIconY: config.weatherIconY, weatherWindColumnX: config.weatherWindColumnX, weatherWindColumnY: config.weatherWindColumnY, weatherWindSpeedFontSize: config.weatherWindSpeedFontSize, weatherWindUnitFontSize: config.weatherWindUnitFontSize,
            weatherPressureX: config.weatherPressureX, weatherPressureY: config.weatherPressureY, weatherDescriptionX: config.weatherDescriptionX, weatherDescriptionY: config.weatherDescriptionY, weatherDescriptionWidth: config.weatherDescriptionWidth, weatherDescriptionFontSize: config.weatherDescriptionFontSize, weatherTempFontSize: config.weatherTempFontSize, weatherComfortFontSize: config.weatherComfortFontSize, weatherComfortOutlineColor: String(config.weatherComfortOutlineColor), weatherComfortOutlineWidth: config.weatherComfortOutlineWidth, weatherShowComfort: config.weatherShowComfort,
            weatherTempColumnWidth: config.weatherTempColumnWidth, weatherMiddleBlockWidth: config.weatherMiddleBlockWidth, weatherLeftBlockAlignment: config.weatherLeftBlockAlignment, weatherMiddleBlockAlignment: config.weatherMiddleBlockAlignment, weatherRightBlockAlignment: config.weatherRightBlockAlignment, weatherIconPlacement: config.weatherIconPlacement, weatherTempX: config.weatherTempX, weatherTempWidth: config.weatherTempWidth, weatherTempOffsetX: config.weatherTempOffsetX, weatherTempOffsetY: config.weatherTempOffsetY, weatherComfortY: config.weatherComfortY, weatherComfortOffsetX: config.weatherComfortOffsetX, weatherComfortOffsetY: config.weatherComfortOffsetY, weatherComfortHeight: config.weatherComfortHeight,
            weatherWindColumnWidth: config.weatherWindColumnWidth, weatherWindArrowWidth: config.weatherWindArrowWidth, weatherWindIcon: config.weatherWindIcon, weatherWindArrowHeight: config.weatherWindArrowHeight, weatherWindCalmIcon: config.weatherWindCalmIcon, weatherWindCalmFont: config.weatherWindCalmFont, weatherWindNIcon: config.weatherWindNIcon, weatherWindNFont: config.weatherWindNFont, weatherWindNEIcon: config.weatherWindNEIcon, weatherWindNEFont: config.weatherWindNEFont, weatherWindEIcon: config.weatherWindEIcon, weatherWindEFont: config.weatherWindEFont, weatherWindSEIcon: config.weatherWindSEIcon, weatherWindSEFont: config.weatherWindSEFont, weatherWindSIcon: config.weatherWindSIcon, weatherWindSFont: config.weatherWindSFont, weatherWindSWIcon: config.weatherWindSWIcon, weatherWindSWFont: config.weatherWindSWFont, weatherWindWIcon: config.weatherWindWIcon, weatherWindWFont: config.weatherWindWFont, weatherWindNWIcon: config.weatherWindNWIcon, weatherWindNWFont: config.weatherWindNWFont, weatherWindSpeedX: config.weatherWindSpeedX, weatherWindSpeedY: config.weatherWindSpeedY, weatherWindSpeedWidth: config.weatherWindSpeedWidth,
            weatherWindUnitX: config.weatherWindUnitX, weatherWindUnitY: config.weatherWindUnitY, weatherWindUnitWidth: config.weatherWindUnitWidth, weatherPressureValueWidth: config.weatherPressureValueWidth, weatherPressureFontSize: config.weatherPressureFontSize,
            weatherPressureUnitX: config.weatherPressureUnitX, weatherPressureUnitY: config.weatherPressureUnitY, weatherPressureUnitFontSize: config.weatherPressureUnitFontSize, weatherDescriptionHeight: config.weatherDescriptionHeight,
            weatherHourlyTopPadding: config.weatherHourlyTopPadding, weatherHourlyDayY: config.weatherHourlyDayY, weatherHourlyDayFontSize: config.weatherHourlyDayFontSize,
            weatherHourlyIconWidth: config.weatherHourlyIconWidth, weatherHourlyIconY: config.weatherHourlyIconY,
            weatherHourlyTempY: config.weatherHourlyTempY, weatherHourlyTempHeight: config.weatherHourlyTempHeight, weatherHourlyTempFontSize: config.weatherHourlyTempFontSize,
            weatherDailyTopPadding: config.weatherDailyTopPadding, weatherDailyDayY: config.weatherDailyDayY, weatherDailyDayFontSize: config.weatherDailyDayFontSize,
            weatherDailyIconWidth: config.weatherDailyIconWidth, weatherDailyIconY: config.weatherDailyIconY,
            weatherDailyHighTempX: config.weatherDailyHighTempX, weatherDailyHighTempY: config.weatherDailyHighTempY, weatherDailyHighTempFontSize: config.weatherDailyHighTempFontSize,
            weatherDailyLowTempX: config.weatherDailyLowTempX, weatherDailyLowTempY: config.weatherDailyLowTempY, weatherDailyLowTempFontSize: config.weatherDailyLowTempFontSize,
            cavaBars: config.cavaBars, cavaFramerate: config.cavaFramerate, cavaRowSpacing: config.cavaRowSpacing, cavaBarWidthRatio: config.cavaBarWidthRatio, cavaMode: config.cavaMode, cavaHideWhenSilent: config.cavaHideWhenSilent, cavaHideZeroBars: config.cavaHideZeroBars, frameBorderWidth: config.frameBorderWidth, frameRadius: config.frameRadius,
            cornerRadiusScale: config.cornerRadiusScale, buttonBordersEnabled: config.buttonBordersEnabled !== false,
            inputBordersEnabled: config.inputBordersEnabled !== false, popupBordersEnabled: config.popupBordersEnabled !== false,
            cardBordersEnabled: config.cardBordersEnabled !== false,
            cpuBarThickness: config.cpuBarThickness, cpuBarWidth: config.cpuBarWidth, cpuRowHeight: config.cpuRowHeight, cpuRowSpacing: config.cpuRowSpacing, cpuLabelLeftPadding: config.cpuLabelLeftPadding, cpuBarLeftOffset: config.cpuBarLeftOffset, cpuBarRadius: config.cpuBarRadius, cpuBarDirection: config.cpuBarDirection, animationCpuMorphDuration: config.animationCpuMorphDuration, animationCpuMorphProfile: config.animationCpuMorphProfile, cpuGraphSegmentSlotWidth: config.cpuGraphSegmentSlotWidth, cpuGraphBarWidth: config.cpuGraphBarWidth, cpuGraphMode: config.cpuGraphMode, cpuShowRam: config.cpuShowRam, topAppsShowHeaders: config.topAppsShowHeaders, topAppsCpuHeaderTitle: config.topAppsCpuHeaderTitle, topAppsCpuHeaderSubtitle: config.topAppsCpuHeaderSubtitle, topAppsRamHeaderTitle: config.topAppsRamHeaderTitle, topAppsRamHeaderSubtitle: config.topAppsRamHeaderSubtitle, topAppsHeaderTitleFontSize: config.topAppsHeaderTitleFontSize, topAppsHeaderSubtitleFontSize: config.topAppsHeaderSubtitleFontSize, topAppsShowBars: config.topAppsShowBars, topAppsBarX: config.topAppsBarX, topAppsBarY: config.topAppsBarY, topAppsBarHeight: config.topAppsBarHeight, topAppsBarWidth: config.topAppsBarWidth, topAppsShowSystemRemainder: config.topAppsShowSystemRemainder, topAppsSystemRemainderLabel: config.topAppsSystemRemainderLabel, topAppsFont: config.topAppsFont, topAppsFontSize: config.topAppsFontSize, topAppsRowSpacing: config.topAppsRowSpacing, topAppsTopOffset: config.topAppsTopOffset,
            networkShowUpload: config.networkShowUpload, networkShowDownload: config.networkShowDownload, networksAlwaysVisible: config.networksAlwaysVisible, networkSpacing: config.networkSpacing, networkTopPadding: config.networkTopPadding, networkIconSize: config.networkIconSize, networkValueFontSize: config.networkValueFontSize, networkRightPadding: config.networkRightPadding, networkIconLeftPadding: config.networkIconLeftPadding, networkFont: config.networkFont,
            volumeUpdateInterval: config.volumeUpdateInterval, volumeIcon: config.volumeIcon, volumeMutedIcon: config.volumeMutedIcon, volumeMainRowHeight: config.volumeMainRowHeight, volumeStreamRowHeight: config.volumeStreamRowHeight, volumeStreamSpacing: config.volumeStreamSpacing, volumeShowStreams: config.volumeShowStreams, volumeHorizontalPadding: config.volumeHorizontalPadding, volumeVerticalPadding: config.volumeVerticalPadding, volumeMainTrackWidth: config.volumeMainTrackWidth, volumeMainTrackHeight: config.volumeMainTrackHeight, volumeStreamTrackHeight: config.volumeStreamTrackHeight, volumeMainTrackOffsetY: config.volumeMainTrackOffsetY, volumeStreamTrackOffsetY: config.volumeStreamTrackOffsetY, volumeMainIconWidth: config.volumeMainIconWidth, volumeStreamLabelFont: config.volumeStreamLabelFont, volumeStreamLabelFontSize: config.volumeStreamLabelFontSize, volumeTrackRadius: config.volumeTrackRadius,
            timerPresetDefaults: owner.timerPresetDefaults, modules: modules, moduleFrames: owner.moduleFrames, moduleBackgrounds: owner.moduleBackgrounds, moduleBlurEnabled: owner.moduleBlurEnabled, moduleMonitors: owner.moduleMonitors, geometry: owner.geometry, settingsGeometry: owner.settingsGeometry, settingsMonitorName: owner.settingsMonitorName, colors: colors, activeTheme: owner.activeTheme
        }
    
}

function updateResetOverridesCache(owner, overrides) {
    if (!owner) return
    var next = isPlainObject(overrides) ? overrides : {}
    var current = isPlainObject(owner.resetOverrides) ? owner.resetOverrides : {}
    // Keep the cache stable if a save leaves the sparse override set unchanged.
    if (!sameValue(current, next))
        owner.resetOverrides = cloneValue(next)
}

function payloadObject(owner, config) {
    // Settings.qml exposes the canonical snapshot through owner.snapshotObject();
    // reuse it when available so profile capture and persistence compare the exact
    // same effective key set (also useful for isolated persistence tests).
    var full = typeof owner.snapshotObject === "function" ? owner.snapshotObject() : snapshotObject(owner, config)
    var state = cloneValue(full)
    delete state.weatherToken
    // Navigation expansion and last selection are UI preferences, not named-profile data.
    // Keep them at the settings.json root so navigation never creates sparse overrides
    // or exposes unrelated Save/Reset actions.
    delete state.settingsNavigationCollapsedGroups
    // The selected page is global navigation UI state, never a profile override.
    delete state.settingsLastActivePageId

    var base = activeProfileBase(owner)
    delete base.weatherToken
    delete base.settingsLastActivePageId
    var overrides = diffValue(base, state) || {}

    // Without an active profile, colors are installation-level preferences.
    // Persist the complete map even when a value equals today's defaults, so a
    // future release changing its palette cannot silently replace the user's
    // saved color. With an active profile, the profile owns its full palette
    // and only deliberate differences remain in profileOverrides.
    var activeProfileName = String(owner.activeProfile || "")
    var hasActiveProfile = activeProfileName !== "" && owner.profiles
        && Object.prototype.hasOwnProperty.call(owner.profiles, activeProfileName)
    if (!hasActiveProfile && isPlainObject(state.colors))
        overrides.colors = cloneValue(state.colors)

    // The writer removes these legacy full-snapshot keys before merging this
    // compact payload. Include keys for known maps separately so unknown future
    // nested entries can survive without retaining duplicate current values.
    var managedKeys = Object.keys(full);
    if (managedKeys.indexOf("settingsNavigationCollapsedGroups") < 0)
        managedKeys.push("settingsNavigationCollapsedGroups");
    if (managedKeys.indexOf("settingsLastActivePageId") < 0)
        managedKeys.push("settingsLastActivePageId");
    if (managedKeys.indexOf("settingsNavigationOrder") < 0)
        managedKeys.push("settingsNavigationOrder");
    // Remove the obsolete flat field from persisted roots after migration.
    if (managedKeys.indexOf("settingsTabOrder") < 0)
        managedKeys.push("settingsTabOrder");
    ["playerControlIconSize", "timerFinishedImageTopMargin", "timerFinishedImageBottomMargin", "mopidyShowMoveButtons", "topApps", "timerPresets", "notificationsMargin", "notificationsPosition", "notificationsOffsetX", "notificationsOffsetY", "animationMopidyMorphEnabled", "animationPlayerMorphEnabled", "animationWeatherMorphEnabled", "animationTimerMorphEnabled"].forEach(function(key) {
        if (managedKeys.indexOf(key) < 0) managedKeys.push(key)
    })
    var managedNestedKeys = {};
    ["modules", "moduleFrames", "moduleBackgrounds", "moduleBlurEnabled", "moduleMonitors", "geometry", "colors"].forEach(function(key) {
        var value = full[key]
        managedNestedKeys[key] = value && typeof value === "object" && !Array.isArray(value) ? Object.keys(value) : []
    })

    return {
        settingsPersistenceFormat: STORAGE_FORMAT,
        settingsSchemaVersion: SETTINGS_SCHEMA_VERSION,
        weatherToken: String(full.weatherToken || "").trim(),
        profiles: owner.profiles || {},
        profileStorageFormat: PROFILE_STORAGE_FORMAT,
        activeProfile: owner.activeProfile || "",
        customThemes: owner.customThemes || {},
        settingsNavigationCollapsedGroups: cloneValue(config.settingsNavigationCollapsedGroups || { appearance: false, modules: false, launcher: false, notifications: false }),
        settingsLastActivePageId: String(config.settingsLastActivePageId || "interface"),
        profileOverrides: overrides,
        managedKeys: managedKeys,
        managedNestedKeys: managedNestedKeys
    }
}

// Qt Quick Process.running may become false before StdioCollector emits
// onStreamFinished (or vice versa). Keep the writer reserved until both
// completion signals have been observed and finalizeWriteIfReady has reset
// their flags; otherwise a second save can reuse the Process and erase the
// first write's result/exit state.
function writerBusy(writer) {
    if (!writer)
        return false
    return !!writer.running || !!writer.processExited || !!writer.tokenOutputFinished
}

function save(owner, config) {
    // The initial disk snapshot must be applied before any UI-triggered save.
    // Otherwise a quick interaction during startup could overwrite existing
    // settings with the QML defaults before the loader finishes.
    if (!owner.loaded) {
        owner.pendingWriteRequested = true
        owner.saved()
        return
    }

    if (!owner.writer)
        owner.writer = owner.writerComponent.createObject(owner)

    if (writerBusy(owner.writer)) {
        // Defer one fresh snapshot until both the process exit and stdout
        // completion callbacks have been observed and finalized.
        owner.pendingWriteRequested = true
        owner.saved()
        return
    }

    // This current snapshot includes every request queued before the write
    // started, so no extra stale pending write is needed.
    owner.pendingWriteRequested = false
    owner.profileStorageFormat = "sparse-v1"
    owner.writer.tokenBaseline = String(owner.persistedWeatherToken || "").trim()
    owner.writer.tokenRequested = String(owner.weatherToken || "").trim()
    owner.writer.tokenResult = ""
    owner.writer.tokenOutputFinished = false
    owner.writer.processExited = false
    owner.writer.writerExitCode = -1
    owner.writer.commandMode = "set-json-ui"
    var payload = payloadObject(owner, config)
    updateResetOverridesCache(owner, payload.profileOverrides)
    owner.writer.payload = JSON.stringify(payload)
    owner.writer.running = true
    owner.saved()
}

function flushPendingWrite(owner, config) {
    if (!owner.loaded || !owner.pendingWriteRequested || writerBusy(owner.writer))
        return false

    owner.pendingWriteRequested = false
    owner.profileStorageFormat = "sparse-v1"
    owner.writer.tokenBaseline = String(owner.persistedWeatherToken || "").trim()
    owner.writer.tokenRequested = String(owner.weatherToken || "").trim()
    owner.writer.tokenResult = ""
    owner.writer.tokenOutputFinished = false
    owner.writer.processExited = false
    owner.writer.writerExitCode = -1
    owner.writer.commandMode = "set-json-ui"
    var payload = payloadObject(owner, config)
    updateResetOverridesCache(owner, payload.profileOverrides)
    owner.writer.payload = JSON.stringify(payload)
    owner.writer.running = true
    return true
}
