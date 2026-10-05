function snapshotObject(owner, config) {

        var modules = {}
        for (var i=0; i<owner.moduleNames.length; ++i) modules[owner.moduleNames[i]] = owner[owner.moduleNames[i]]
        var colors = {}
        for (var j=0; j<owner.colorNames.length; ++j) colors[owner.colorNames[j]] = config[owner.colorNames[j]]
        return {
            weatherToken: owner.weatherToken,
            font: config.font, fontSize: config.fontSize,
            settingsFont: config.settingsFont, settingsFontSize: config.settingsFontSize,
            settingsPadding: config.settingsPadding, settingsSpacing: config.settingsSpacing,
            ledFont: config.ledFont,
            playerFont: config.playerFont, playerMetaFont: config.playerMetaFont, playerSilenceText: config.playerSilenceText,
            animationsEnabled: config.animationsEnabled, animationSpeed: config.animationSpeed,
            animationEasing: config.animationEasing,
            animationAppearanceEnabled: config.animationAppearanceEnabled,
            animationMovementEnabled: config.animationMovementEnabled,
            animationSizeEnabled: config.animationSizeEnabled,
            animationExpansionEnabled: config.animationExpansionEnabled,
            animationTimerOptionsDuration: config.animationTimerOptionsDuration, animationCalendarSlideDuration: config.animationCalendarSlideDuration, animationCalendarFadeDuration: config.animationCalendarFadeDuration,
            systemMonitorInterval: config.systemMonitorInterval, cpuUpdateInterval: config.cpuUpdateInterval, playerUpdateInterval: config.playerUpdateInterval,
            weatherNowIntervalMinutes: config.weatherNowIntervalMinutes, weatherHourlyIntervalMinutes: config.weatherHourlyIntervalMinutes, weatherDailyIntervalMinutes: config.weatherDailyIntervalMinutes, weatherRetryDelayMinutes: config.weatherRetryDelayMinutes, weatherManualRefreshCooldownSeconds: config.weatherManualRefreshCooldownSeconds,
            timerMinHeight: config.timerMinHeight, volumeMinHeight: config.volumeMinHeight, volumeMaxHeight: config.volumeMaxHeight,
            timerWheelStep: config.timerWheelStep, timerCommentWidth: config.timerCommentWidth, timerCommentMaxLength: config.timerCommentMaxLength, timerCommentGap: config.timerCommentGap,
            timerRowSpacing: config.timerRowSpacing,
            timerRowTopMargin: config.timerRowTopMargin, timerRowRightMargin: config.timerRowRightMargin,
            timerButtonFadeDuration: config.timerButtonFadeDuration, timerButtonSlideDuration: config.timerButtonSlideDuration, timerButtonIconFadeDuration: config.timerButtonIconFadeDuration,
            timerIcon: config.timerIcon, timerIconOrder: config.timerIconOrder, timerIconSize: config.timerIconSize, timerIconX: config.timerIconX, timerIconY: config.timerIconY,
            timerAlarmIcon: config.timerAlarmIcon, timerAlarmIconSize: config.timerAlarmIconSize, timerAlarmIconX: config.timerAlarmIconX, timerAlarmIconY: config.timerAlarmIconY,
            timerFinishedImageEnabled: config.timerFinishedImageEnabled, timerFinishedImagePath: config.timerFinishedImagePath,
            timerFinishedBorderUsesTimerColor: config.timerFinishedBorderUsesTimerColor, timerFinishedBackgroundUsesTimerColor: config.timerFinishedBackgroundUsesTimerColor, timerFinishedBackgroundColor: config.timerFinishedBackgroundColor,
            timerFinishedImageWidth: config.timerFinishedImageWidth, timerFinishedImageMargin: config.timerFinishedImageMargin, timerFinishedImageTopMargin: config.timerFinishedImageMargin, timerFinishedImageBottomMargin: config.timerFinishedImageMargin,
            timerFinishedTitleUsesTimerColor: config.timerFinishedTitleUsesTimerColor, timerFinishedTitleColor: config.timerFinishedTitleColor, timerFinishedTitleFontSize: config.timerFinishedTitleFontSize, timerFinishedTitleFont: config.timerFinishedTitleFont, timerFinishedTitleAlignment: config.timerFinishedTitleAlignment,
            playerSilenceFontSize: config.playerSilenceFontSize, playerSilenceLongFontSize: config.playerSilenceLongFontSize, playerMetaFontSize: config.playerMetaFontSize,
            playerTextOutlineEnabled: config.playerTextOutlineEnabled, playerTextOutlineColor: config.playerTextOutlineColor,
            playerMetaSecondaryFontSize: config.playerMetaSecondaryFontSize, playerMetaLineSpacing: config.playerMetaLineSpacing, playerBoldArtist: config.playerBoldArtist,
            playerShowProgress: config.playerShowProgress, playerControlIconSize: config.playerControlIconSize, playerPlayingIconSize: config.playerPlayingIconSize, playerPausedIconSize: config.playerPausedIconSize, playerNextIconSize: config.playerNextIconSize, playerPlayingIconY: config.playerPlayingIconY, playerPausedIconY: config.playerPausedIconY, playerNextIconY: config.playerNextIconY, playerPlayingIcon: config.playerPlayingIcon, playerPausedIcon: config.playerPausedIcon, playerNextIcon: config.playerNextIcon,
            playerBlurEnabled: config.playerBlurEnabled, playerBlurRadius: config.playerBlurRadius,
            playerMetadataXPadding: config.playerMetadataXPadding,
            playerMetadataY: config.playerMetadataY, playerProgressY: config.playerProgressY,
            playerProgressTrackHeight: config.playerProgressTrackHeight,
            playerControlTopMargin: config.playerControlTopMargin, playerControlGap: config.playerControlGap,
            playerTimeFontSize: config.playerTimeFontSize, playerTimeFont: config.playerTimeFont, playerTimeRightPadding: config.playerTimeRightPadding, playerCoverOpacity: config.playerCoverOpacity,
            playerSilenceWidth: config.playerSilenceWidth, playerProgressTrackOffsetY: config.playerProgressTrackOffsetY,
            calendarPreviousIcon: config.calendarPreviousIcon, calendarNextIcon: config.calendarNextIcon,
            calendarPreviousSize: config.calendarPreviousSize, calendarNextSize: config.calendarNextSize, calendarArrowY: config.calendarArrowY,
            calendarPreviousX: config.calendarPreviousX, calendarNextX: config.calendarNextX,
            calendarTitleFontSize: config.calendarTitleFontSize, calendarTitleY: config.calendarTitleY, calendarTitleFont: config.calendarTitleFont,
            calendarWeekdayFontSize: config.calendarWeekdayFontSize, calendarWeekdayY: config.calendarWeekdayY, calendarWeekdayFont: config.calendarWeekdayFont,
            calendarDayFontSize: config.calendarDayFontSize, calendarDayY: config.calendarDayY, calendarDayFont: config.calendarDayFont,
            weatherIconSize: config.weatherIconSize, weatherArrowSize: config.weatherArrowSize, weatherArrowYOffset: config.weatherArrowYOffset, weatherWindArrowGap: config.weatherWindArrowGap,
            weatherHourlyCount: config.weatherHourlyCount, weatherDailyCount: config.weatherDailyCount,
            weatherIconY: config.weatherIconY, weatherWindColumnX: config.weatherWindColumnX, weatherWindSpeedFontSize: config.weatherWindSpeedFontSize, weatherWindUnitFontSize: config.weatherWindUnitFontSize,
            weatherPressureY: config.weatherPressureY, weatherDescriptionY: config.weatherDescriptionY, weatherDescriptionFontSize: config.weatherDescriptionFontSize, weatherTempFontSize: config.weatherTempFontSize, weatherComfortFontSize: config.weatherComfortFontSize,
            weatherTempColumnWidth: config.weatherTempColumnWidth, weatherTempX: config.weatherTempX, weatherTempWidth: config.weatherTempWidth, weatherTempOffsetX: config.weatherTempOffsetX, weatherTempOffsetY: config.weatherTempOffsetY, weatherComfortY: config.weatherComfortY, weatherComfortOffsetX: config.weatherComfortOffsetX, weatherComfortOffsetY: config.weatherComfortOffsetY, weatherComfortHeight: config.weatherComfortHeight,
            weatherWindColumnWidth: config.weatherWindColumnWidth, weatherWindArrowWidth: config.weatherWindArrowWidth, weatherWindIcon: config.weatherWindIcon, weatherWindArrowHeight: config.weatherWindArrowHeight, weatherWindSpeedX: config.weatherWindSpeedX, weatherWindSpeedY: config.weatherWindSpeedY, weatherWindSpeedWidth: config.weatherWindSpeedWidth,
            weatherWindUnitX: config.weatherWindUnitX, weatherWindUnitY: config.weatherWindUnitY, weatherWindUnitWidth: config.weatherWindUnitWidth, weatherPressureValueWidth: config.weatherPressureValueWidth, weatherPressureFontSize: config.weatherPressureFontSize,
            weatherPressureUnitX: config.weatherPressureUnitX, weatherPressureUnitY: config.weatherPressureUnitY, weatherPressureUnitFontSize: config.weatherPressureUnitFontSize, weatherDescriptionHeight: config.weatherDescriptionHeight,
            weatherHourlyTopPadding: config.weatherHourlyTopPadding, weatherHourlyDayY: config.weatherHourlyDayY, weatherHourlyDayFontSize: config.weatherHourlyDayFontSize,
            weatherHourlyIconWidth: config.weatherHourlyIconWidth, weatherHourlyIconY: config.weatherHourlyIconY,
            weatherHourlyTempY: config.weatherHourlyTempY, weatherHourlyTempHeight: config.weatherHourlyTempHeight, weatherHourlyTempFontSize: config.weatherHourlyTempFontSize,
            weatherDailyTopPadding: config.weatherDailyTopPadding, weatherDailyDayY: config.weatherDailyDayY, weatherDailyDayFontSize: config.weatherDailyDayFontSize,
            weatherDailyIconWidth: config.weatherDailyIconWidth, weatherDailyIconY: config.weatherDailyIconY,
            weatherDailyHighTempX: config.weatherDailyHighTempX, weatherDailyHighTempY: config.weatherDailyHighTempY, weatherDailyHighTempFontSize: config.weatherDailyHighTempFontSize,
            weatherDailyLowTempX: config.weatherDailyLowTempX, weatherDailyLowTempY: config.weatherDailyLowTempY, weatherDailyLowTempFontSize: config.weatherDailyLowTempFontSize,
            cavaBars: config.cavaBars, cavaFramerate: config.cavaFramerate, cavaRowSpacing: config.cavaRowSpacing, cavaBarWidthRatio: config.cavaBarWidthRatio, frameBorderWidth: config.frameBorderWidth, frameRadius: config.frameRadius,
            cpuBarThickness: config.cpuBarThickness, cpuBarWidth: config.cpuBarWidth, cpuRowHeight: config.cpuRowHeight, cpuRowSpacing: config.cpuRowSpacing, cpuLabelLeftPadding: config.cpuLabelLeftPadding, cpuBarLeftOffset: config.cpuBarLeftOffset, cpuBarRadius: config.cpuBarRadius, cpuGraphSegmentSlotWidth: config.cpuGraphSegmentSlotWidth, cpuGraphBarWidth: config.cpuGraphBarWidth, cpuShowRam: config.cpuShowRam,
            networkShowUpload: config.networkShowUpload, networkShowDownload: config.networkShowDownload, networkRowHeight: config.networkRowHeight, networkRowSpacing: config.networkRowSpacing, networkIconSize: config.networkIconSize, networkValueFontSize: config.networkValueFontSize, networkRightPadding: config.networkRightPadding, networkHorizontalPadding: config.networkHorizontalPadding, networkIconLeftPadding: config.networkIconLeftPadding, networkIconColumnWidth: config.networkIconColumnWidth,
            volumeUpdateInterval: config.volumeUpdateInterval, volumeIcon: config.volumeIcon, volumeMutedIcon: config.volumeMutedIcon, volumeMainRowHeight: config.volumeMainRowHeight, volumeStreamRowHeight: config.volumeStreamRowHeight, volumeStreamSpacing: config.volumeStreamSpacing, volumeShowStreams: config.volumeShowStreams, volumeHorizontalPadding: config.volumeHorizontalPadding, volumeVerticalPadding: config.volumeVerticalPadding, volumeMainTrackWidth: config.volumeMainTrackWidth, volumeMainTrackHeight: config.volumeMainTrackHeight, volumeStreamTrackHeight: config.volumeStreamTrackHeight, volumeMainTrackOffsetY: config.volumeMainTrackOffsetY, volumeStreamTrackOffsetY: config.volumeStreamTrackOffsetY, volumeMainIconWidth: config.volumeMainIconWidth, volumeStreamLabelFontSize: config.volumeStreamLabelFontSize, volumeTrackRadius: config.volumeTrackRadius,
            timerPresets: owner.timerPresetDefaults, timerPresetDefaults: owner.timerPresetDefaults, modules: modules, moduleFrames: owner.moduleFrames, moduleBackgrounds: owner.moduleBackgrounds, moduleMonitors: owner.moduleMonitors, geometry: owner.geometry, settingsGeometry: owner.settingsGeometry, settingsMonitorName: owner.settingsMonitorName, colors: colors, activeTheme: owner.activeTheme
        }
    
}

function save(owner, config) {

        if (!owner.writer)
            owner.writer = owner.writerComponent.createObject(owner)

        if (owner.writer.running) {
            // The current writer already has a snapshot in flight.
            // Only remember that another snapshot is required after it finishes;
            // build the expensive JSON payload once, at that point.
            owner.pendingWriteRequested = true
            owner.saved()
            return
        }

        var payloadObject = snapshotObject(owner, config)
        payloadObject.profiles = owner.profiles
        payloadObject.activeProfile = owner.activeProfile
        payloadObject.customThemes = owner.customThemes
        payloadObject.activeTheme = owner.activeTheme

        owner.writer.payload = JSON.stringify(payloadObject)
        owner.writer.running = true
        owner.saved()
    
}
