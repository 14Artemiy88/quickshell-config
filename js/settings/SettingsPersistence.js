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
            launcherWidth: config.launcherWidth, launcherHeight: config.launcherHeight,
            launcherItemHeight: config.launcherItemHeight, launcherRadius: config.launcherRadius,
            launcherBackdropOpacity: config.launcherBackdropOpacity,
            launcherDefaultMode: config.launcherDefaultMode,
            launcherShowResultCount: config.launcherShowResultCount,
            launcherTabOrder: JSON.parse(JSON.stringify(config.launcherTabOrder || [0, 1, 2, 3, 4, 5, 6, 7, 8])),
            launcherTabVisible: JSON.parse(JSON.stringify(config.launcherTabVisible || [true, true, true, true, true, true, true, true, true])),
            launcherProjects: JSON.parse(JSON.stringify(config.launcherProjects || [])),
            ledFont: config.ledFont,
            playerFont: config.playerFont, playerMetaFont: config.playerMetaFont, playerSilenceText: config.playerSilenceText,
            animationsEnabled: config.animationsEnabled, animationSpeed: config.animationSpeed,
            animationEasing: config.animationEasing,
            animationCalendarVisibilityStyle: config.animationCalendarVisibilityStyle,
            animationMopidyVisibilityStyle: config.animationMopidyVisibilityStyle,
            animationTimerVisibilityStyle: config.animationTimerVisibilityStyle,
            animationSettingsVisibilityStyle: config.animationSettingsVisibilityStyle,
            animationAppearanceEnabled: config.animationAppearanceEnabled,
            animationMovementEnabled: config.animationMovementEnabled,
            animationSizeEnabled: config.animationSizeEnabled,
            animationExpansionEnabled: config.animationExpansionEnabled,
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
            playerBlurEnabled: config.playerBlurEnabled, playerBlurRadius: config.playerBlurRadius,
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
            weatherPressureY: config.weatherPressureY, weatherDescriptionY: config.weatherDescriptionY, weatherDescriptionFontSize: config.weatherDescriptionFontSize, weatherTempFontSize: config.weatherTempFontSize, weatherComfortFontSize: config.weatherComfortFontSize, weatherShowComfort: config.weatherShowComfort,
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
            timerPresetDefaults: owner.timerPresetDefaults, modules: modules, moduleFrames: owner.moduleFrames, moduleBackgrounds: owner.moduleBackgrounds, moduleMonitors: owner.moduleMonitors, geometry: owner.geometry, settingsGeometry: owner.settingsGeometry, settingsMonitorName: owner.settingsMonitorName, colors: colors, activeTheme: owner.activeTheme
        }
    
}

function payloadObject(owner, config) {
    var payload = snapshotObject(owner, config)
    payload.profiles = owner.profiles || {}
    payload.profileStorageFormat = "sparse-v1"
    payload.activeProfile = owner.activeProfile
    payload.customThemes = owner.customThemes || {}
    payload.activeTheme = owner.activeTheme
    return payload
}

function save(owner, config) {
    if (!owner.writer)
        owner.writer = owner.writerComponent.createObject(owner)

    if (owner.writer.running) {
        // Defer one fresh snapshot until the in-flight write has completed.
        owner.pendingWriteRequested = true
        owner.saved()
        return
    }

    owner.profileStorageFormat = "sparse-v1"
    owner.writer.payload = JSON.stringify(payloadObject(owner, config))
    owner.writer.running = true
    owner.saved()
}
