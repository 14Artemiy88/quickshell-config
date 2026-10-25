var STORAGE_FORMAT = "profile-overrides-v1"
var PROFILE_STORAGE_FORMAT = "sparse-v1"

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
    var name = String(owner.activeProfile || "")
    if (!name || !owner.profiles || !Object.prototype.hasOwnProperty.call(owner.profiles, name))
        return base
    if (typeof owner.expandedProfileData === "function") {
        var expanded = owner.expandedProfileData(name)
        if (expanded && typeof expanded === "object") {
            delete expanded.weatherToken
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
            font: config.font, fontSize: config.fontSize,
            settingsFont: config.settingsFont, settingsFontSize: config.settingsFontSize,
            settingsPadding: config.settingsPadding, settingsSpacing: config.settingsSpacing,
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
            launcherCrossSearchProjects: config.launcherCrossSearchProjects,
            launcherCrossSearchRunHistory: config.launcherCrossSearchRunHistory,
            launcherTabOrder: JSON.parse(JSON.stringify(config.launcherTabOrder || [0, 1, 2, 3, 4, 5, 6, 7, 8])),
            launcherTabVisible: JSON.parse(JSON.stringify(config.launcherTabVisible || [true, true, true, true, true, true, true, true, true])),
            launcherTabLabels: JSON.parse(JSON.stringify(config.launcherTabLabels || ["Apps", "Run", "Windows", "Clipboard", "Power", "Network", "Packages", "Pass", "Projects"])),
            launcherTabIcons: JSON.parse(JSON.stringify(config.launcherTabIcons || ["󰀻", "", "󰖯", "󰅇", "", "󰖩", "󱄅", "󰌋", ""])),
            launcherProjects: JSON.parse(JSON.stringify(config.launcherProjects || [])),
            ledFont: config.ledFont,
            playerFont: config.playerFont, playerMetaFont: config.playerMetaFont, playerSilenceText: config.playerSilenceText,
            animationCalendarVisibilityStyle: config.animationCalendarVisibilityStyle,
            animationMopidyVisibilityStyle: config.animationMopidyVisibilityStyle,
            animationTimerVisibilityStyle: config.animationTimerVisibilityStyle,
            animationSettingsVisibilityStyle: config.animationSettingsVisibilityStyle,
            animationTimerOptionsDuration: config.animationTimerOptionsDuration, animationCalendarSlideDuration: config.animationCalendarSlideDuration, animationCalendarFadeDuration: config.animationCalendarFadeDuration,
            systemMonitorInterval: config.systemMonitorInterval, cpuUpdateInterval: config.cpuUpdateInterval, playerUpdateInterval: config.playerUpdateInterval,
            weatherNowIntervalMinutes: config.weatherNowIntervalMinutes, weatherHourlyIntervalMinutes: config.weatherHourlyIntervalMinutes, weatherDailyIntervalMinutes: config.weatherDailyIntervalMinutes, weatherRetryDelayMinutes: config.weatherRetryDelayMinutes, weatherManualRefreshCooldownSeconds: config.weatherManualRefreshCooldownSeconds,
            timerMinHeight: config.timerMinHeight, volumeMinHeight: config.volumeMinHeight, volumeMaxHeight: config.volumeMaxHeight,
            timerWheelStep: config.timerWheelStep, timerCommentWidth: config.timerCommentWidth, timerCommentMaxLength: config.timerCommentMaxLength, timerCommentGap: config.timerCommentGap, timerCommentAlignFurthest: config.timerCommentAlignFurthest,
            timerRowSpacing: config.timerRowSpacing,
            timerRowTopMargin: config.timerRowTopMargin, timerRowRightMargin: config.timerRowRightMargin,
            timerButtonFadeDuration: config.timerButtonFadeDuration, timerButtonSlideDuration: config.timerButtonSlideDuration, timerButtonIconFadeDuration: config.timerButtonIconFadeDuration,
            timerIcon: config.timerIcon, timerIconOrder: config.timerIconOrder, timerIconSize: config.timerIconSize, timerIconX: config.timerIconX, timerIconY: config.timerIconY,
            timerAlarmIcon: config.timerAlarmIcon, timerAlarmIconSize: config.timerAlarmIconSize, timerAlarmIconX: config.timerAlarmIconX, timerAlarmIconY: config.timerAlarmIconY,
            timerFinishedImageEnabled: config.timerFinishedImageEnabled, timerFinishedImagePath: config.timerFinishedImagePath,
            timerFinishedBorderUsesTimerColor: config.timerFinishedBorderUsesTimerColor, timerFinishedBackgroundUsesTimerColor: config.timerFinishedBackgroundUsesTimerColor, timerFinishedBackgroundColor: String(config.timerFinishedBackgroundColor),
            timerFinishedImageWidth: config.timerFinishedImageWidth, timerFinishedImageMargin: config.timerFinishedImageMargin,
            timerFinishedTitleUsesTimerColor: config.timerFinishedTitleUsesTimerColor, timerFinishedTitleColor: String(config.timerFinishedTitleColor), timerFinishedTitleFontSize: config.timerFinishedTitleFontSize, timerFinishedTitleFont: config.timerFinishedTitleFont, timerFinishedTitleAlignment: config.timerFinishedTitleAlignment,
            playerSilenceFontSize: config.playerSilenceFontSize, playerSilenceLongFontSize: config.playerSilenceLongFontSize, playerMetaFontSize: config.playerMetaFontSize,
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
            mopidyShowTrackNumbers: config.mopidyShowTrackNumbers, mopidyTopIconOrder: config.mopidyTopIconOrder, mopidyMoveUpIcon: config.mopidyMoveUpIcon, mopidyMoveUpIconSize: config.mopidyMoveUpIconSize, mopidyMoveUpIconX: config.mopidyMoveUpIconX, mopidyMoveUpIconY: config.mopidyMoveUpIconY, mopidyShowMoveUpIcon: config.mopidyShowMoveUpIcon, mopidyMoveDownIcon: config.mopidyMoveDownIcon, mopidyMoveDownIconSize: config.mopidyMoveDownIconSize, mopidyMoveDownIconX: config.mopidyMoveDownIconX, mopidyMoveDownIconY: config.mopidyMoveDownIconY, mopidyShowMoveDownIcon: config.mopidyShowMoveDownIcon, mopidyGroupAlbums: config.mopidyGroupAlbums,
            mopidyAlbumFont: config.mopidyAlbumFont, mopidyAlbumFontSize: config.mopidyAlbumFontSize, mopidyAlbumBold: config.mopidyAlbumBold, mopidyTrackFont: config.mopidyTrackFont, mopidyTrackFontSize: config.mopidyTrackFontSize, mopidyTrackRowHeight: config.mopidyTrackRowHeight, mopidyArtistFont: config.mopidyArtistFont, mopidyArtistFontSize: config.mopidyArtistFontSize, mopidyArtistBold: config.mopidyArtistBold, mopidyArtistItalic: config.mopidyArtistItalic, mopidyTrackArtistDisplayMode: config.mopidyTrackArtistDisplayMode, mopidyTrackArtistSeparator: config.mopidyTrackArtistSeparator, mopidyDurationFont: config.mopidyDurationFont, mopidyDurationFontSize: config.mopidyDurationFontSize, mopidyAlbumSeparator: config.mopidyAlbumSeparator,
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
            calendarNoteMarkerStyle: config.calendarNoteMarkerStyle,
            calendarNoteMarkerPosition: config.calendarNoteMarkerPosition, calendarNoteFrameColor: config.calendarNoteFrameColor,
            weatherIconSize: config.weatherIconSize, weatherArrowSize: config.weatherArrowSize, weatherArrowYOffset: config.weatherArrowYOffset, weatherWindArrowGap: config.weatherWindArrowGap,
            weatherHourlyCount: config.weatherHourlyCount, weatherDailyCount: config.weatherDailyCount,
            weatherIconX: config.weatherIconX, weatherIconY: config.weatherIconY, weatherWindColumnX: config.weatherWindColumnX, weatherWindSpeedFontSize: config.weatherWindSpeedFontSize, weatherWindUnitFontSize: config.weatherWindUnitFontSize,
            weatherPressureY: config.weatherPressureY, weatherDescriptionY: config.weatherDescriptionY, weatherDescriptionFontSize: config.weatherDescriptionFontSize, weatherTempFontSize: config.weatherTempFontSize, weatherComfortFontSize: config.weatherComfortFontSize, weatherComfortOutlineColor: String(config.weatherComfortOutlineColor), weatherComfortOutlineWidth: config.weatherComfortOutlineWidth, weatherShowComfort: config.weatherShowComfort,
            weatherTempColumnWidth: config.weatherTempColumnWidth, weatherTempX: config.weatherTempX, weatherTempWidth: config.weatherTempWidth, weatherTempOffsetX: config.weatherTempOffsetX, weatherTempOffsetY: config.weatherTempOffsetY, weatherComfortY: config.weatherComfortY, weatherComfortOffsetX: config.weatherComfortOffsetX, weatherComfortOffsetY: config.weatherComfortOffsetY, weatherComfortHeight: config.weatherComfortHeight,
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
            cpuBarThickness: config.cpuBarThickness, cpuBarWidth: config.cpuBarWidth, cpuRowHeight: config.cpuRowHeight, cpuRowSpacing: config.cpuRowSpacing, cpuLabelLeftPadding: config.cpuLabelLeftPadding, cpuBarLeftOffset: config.cpuBarLeftOffset, cpuBarRadius: config.cpuBarRadius, cpuBarDirection: config.cpuBarDirection, cpuGraphSegmentSlotWidth: config.cpuGraphSegmentSlotWidth, cpuGraphBarWidth: config.cpuGraphBarWidth, cpuGraphMode: config.cpuGraphMode, cpuShowRam: config.cpuShowRam, topAppsShowHeaders: config.topAppsShowHeaders, topAppsCpuHeaderTitle: config.topAppsCpuHeaderTitle, topAppsCpuHeaderSubtitle: config.topAppsCpuHeaderSubtitle, topAppsRamHeaderTitle: config.topAppsRamHeaderTitle, topAppsRamHeaderSubtitle: config.topAppsRamHeaderSubtitle, topAppsHeaderTitleFontSize: config.topAppsHeaderTitleFontSize, topAppsHeaderSubtitleFontSize: config.topAppsHeaderSubtitleFontSize, topAppsShowBars: config.topAppsShowBars, topAppsBarX: config.topAppsBarX, topAppsBarY: config.topAppsBarY, topAppsBarHeight: config.topAppsBarHeight, topAppsBarWidth: config.topAppsBarWidth, topAppsShowSystemRemainder: config.topAppsShowSystemRemainder, topAppsSystemRemainderLabel: config.topAppsSystemRemainderLabel, topAppsFont: config.topAppsFont, topAppsFontSize: config.topAppsFontSize, topAppsRowSpacing: config.topAppsRowSpacing, topAppsTopOffset: config.topAppsTopOffset,
            networkShowUpload: config.networkShowUpload, networkShowDownload: config.networkShowDownload, networkRowHeight: config.networkRowHeight, networkRowSpacing: config.networkRowSpacing, networkIconSize: config.networkIconSize, networkValueFontSize: config.networkValueFontSize, networkRightPadding: config.networkRightPadding, networkHorizontalPadding: config.networkHorizontalPadding, networkIconLeftPadding: config.networkIconLeftPadding, networkIconColumnWidth: config.networkIconColumnWidth,
            volumeUpdateInterval: config.volumeUpdateInterval, volumeIcon: config.volumeIcon, volumeMutedIcon: config.volumeMutedIcon, volumeMainRowHeight: config.volumeMainRowHeight, volumeStreamRowHeight: config.volumeStreamRowHeight, volumeStreamSpacing: config.volumeStreamSpacing, volumeShowStreams: config.volumeShowStreams, volumeHorizontalPadding: config.volumeHorizontalPadding, volumeVerticalPadding: config.volumeVerticalPadding, volumeMainTrackWidth: config.volumeMainTrackWidth, volumeMainTrackHeight: config.volumeMainTrackHeight, volumeStreamTrackHeight: config.volumeStreamTrackHeight, volumeMainTrackOffsetY: config.volumeMainTrackOffsetY, volumeStreamTrackOffsetY: config.volumeStreamTrackOffsetY, volumeMainIconWidth: config.volumeMainIconWidth, volumeStreamLabelFontSize: config.volumeStreamLabelFontSize, volumeTrackRadius: config.volumeTrackRadius,
            timerPresetDefaults: owner.timerPresetDefaults, modules: modules, moduleFrames: owner.moduleFrames, moduleBackgrounds: owner.moduleBackgrounds, moduleBlurEnabled: owner.moduleBlurEnabled, moduleMonitors: owner.moduleMonitors, geometry: owner.geometry, settingsGeometry: owner.settingsGeometry, settingsMonitorName: owner.settingsMonitorName, colors: colors, activeTheme: owner.activeTheme
        }
    
}

function payloadObject(owner, config) {
    // Settings.qml exposes the canonical snapshot through owner.snapshotObject();
    // reuse it when available so profile capture and persistence compare the exact
    // same effective key set (also useful for isolated persistence tests).
    var full = typeof owner.snapshotObject === "function" ? owner.snapshotObject() : snapshotObject(owner, config)
    var state = cloneValue(full)
    delete state.weatherToken

    var base = activeProfileBase(owner)
    delete base.weatherToken
    var overrides = diffValue(base, state) || {}

    // The writer removes these legacy full-snapshot keys before merging this
    // compact payload. Include keys for known maps separately so unknown future
    // nested entries can survive without retaining duplicate current values.
    var managedKeys = Object.keys(full);
    ["playerControlIconSize", "timerFinishedImageTopMargin", "timerFinishedImageBottomMargin", "mopidyShowMoveButtons", "topApps", "timerPresets"].forEach(function(key) {
        if (managedKeys.indexOf(key) < 0) managedKeys.push(key)
    })
    var managedNestedKeys = {};
    ["modules", "moduleFrames", "moduleBackgrounds", "moduleBlurEnabled", "moduleMonitors", "geometry", "colors"].forEach(function(key) {
        var value = full[key]
        managedNestedKeys[key] = value && typeof value === "object" && !Array.isArray(value) ? Object.keys(value) : []
    })

    return {
        settingsPersistenceFormat: STORAGE_FORMAT,
        weatherToken: String(full.weatherToken || "").trim(),
        profiles: owner.profiles || {},
        profileStorageFormat: PROFILE_STORAGE_FORMAT,
        activeProfile: owner.activeProfile || "",
        customThemes: owner.customThemes || {},
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
    owner.writer.payload = JSON.stringify(payloadObject(owner, config))
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
    owner.writer.payload = JSON.stringify(payloadObject(owner, config))
    owner.writer.running = true
    return true
}
