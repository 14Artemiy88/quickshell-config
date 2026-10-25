// Settings reset logic extracted from Settings.qml.

function restoreProfileTheme(owner, profile, themes, colorNames) {
    var themeName = profile && profile.activeTheme !== undefined ? String(profile.activeTheme) : ""
    if (themeName && themes && themes.palette) {
        var knownNames = themes.builtinThemeNames || []
        var custom = owner.customThemes || {}
        if (knownNames.indexOf(themeName) >= 0 || custom[themeName] !== undefined) {
            owner.activeTheme = themeName
        } else {
            themeName = ""
        }
    }

    if (!themeName && themes && themes.builtinThemeNames && profile && profile.colors) {
        var candidates = themes.builtinThemeNames.slice()
        Object.keys(owner.customThemes || {}).sort().forEach(function(name) { candidates.push(name) })
        for (var i = 0; i < candidates.length; ++i) {
            var palette = themes.palette(candidates[i], owner.customThemes)
            var matches = true
            for (var j = 0; j < colorNames.length; ++j) {
                var key = colorNames[j]
                if (profile.colors[key] === undefined) continue
                if (String(profile.colors[key]) !== String(palette[key] !== undefined ? palette[key] : "")) {
                    matches = false
                    break
                }
            }
            if (matches) {
                owner.activeTheme = candidates[i]
                themeName = candidates[i]
                break
            }
        }
    }

    if (themeName && themes && themes.palette) {
        var p = themes.palette(themeName, owner.customThemes)
        owner.themeDraft = JSON.parse(JSON.stringify(p))
        owner.themeDraftSource = themeName
        owner.themeDraftRevision++
    }
    owner.themeStateRevision++
}

function resetConfigKeys(owner, config, names) {
    if (!(names instanceof Array)) return
    for (var i = 0; i < names.length; ++i) {
        var name = names[i]
        if (owner.defaultConfig[name] !== undefined) config[name] = owner.defaultConfig[name]
    }
}

function activeProfileData(owner) {
    if (owner.activeProfile && owner.profiles && owner.profiles[owner.activeProfile]) {
        if (owner.expandedProfileData)
            return owner.expandedProfileData(owner.activeProfile)
        return owner.profiles[owner.activeProfile]
    }
    owner.resetUnavailable("Сначала сохраните профиль")
    return null
}

function applyConfigKeysFromProfile(owner, config, profile, names) {
    if (!profile || !(names instanceof Array)) return
    for (var i = 0; i < names.length; ++i) {
        var name = names[i]
        if (profile[name] !== undefined) config[name] = profile[name]
    }
}

function resetColorsFromProfile(owner, config, names, themes, colorNames) {
    var profile = activeProfileData(owner)
    if (!profile) return
    var colors = profile.colors || {}
    if (!(names instanceof Array)) return
    for (var i = 0; i < names.length; ++i) {
        var name = names[i]
        if (colors[name] !== undefined) config[name] = colors[name]
    }
    // Keep the selected theme synchronized with the restored profile palette.
    restoreProfileTheme(owner, profile, themes, colorNames)
    owner.save()
}

function resetSettingsWindowFromProfile(owner, config) {
    var profile = activeProfileData(owner)
    if (!profile) return
    if (profile.settingsGeometry && profile.settingsGeometry.length === 4)
        owner.settingsGeometry = profile.settingsGeometry.slice()
    if (profile.settingsMonitorName !== undefined && String(profile.settingsMonitorName).trim() !== "")
        owner.settingsMonitorName = String(profile.settingsMonitorName)
    else
        owner.settingsMonitorName = config.monitorName
    applyConfigKeysFromProfile(owner, config, profile, ["animationSettingsVisibilityStyle", "settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing"])
    if (profile.colors && profile.colors.settingsBackground !== undefined)
        config.settingsBackground = profile.colors.settingsBackground
    if (profile.colors && profile.colors.settingsBorder !== undefined)
        config.settingsBorder = profile.colors.settingsBorder
    var blur = Object.assign({}, owner.moduleBlurEnabled || {})
    blur.settings = profile.moduleBlurEnabled && profile.moduleBlurEnabled.settings !== undefined
        ? !!profile.moduleBlurEnabled.settings : !!(owner.defaultModuleBlurEnabled || {}).settings
    owner.moduleBlurEnabled = blur
    owner.save()
}

function resetModule(owner, config, moduleName) {
    if (!moduleName) return

    var profile = activeProfileData(owner)
    if (!profile) return

    var modules = profile.modules || {}
    var frames = profile.moduleFrames || {}
    var backgrounds = profile.moduleBackgrounds || {}
    var blurEnabled = profile.moduleBlurEnabled || {}
    var profileMonitors = profile.moduleMonitors || {}
    var profileGeometry = profile.geometry || {}

    if (modules[moduleName] !== undefined)
        owner[moduleName] = !!modules[moduleName]

    var g = JSON.parse(JSON.stringify(owner.geometry || {}))
    if (profileGeometry[moduleName] !== undefined)
        g[moduleName] = (profileGeometry[moduleName] || []).slice()
    owner.geometry = g

    var f = Object.assign({}, owner.moduleFrames || {})
    if (frames[moduleName] !== undefined)
        f[moduleName] = !!frames[moduleName]
    owner.moduleFrames = f

    var b = Object.assign({}, owner.moduleBackgrounds || {})
    if (backgrounds[moduleName] !== undefined)
        b[moduleName] = !!backgrounds[moduleName]
    owner.moduleBackgrounds = b

    var blur = Object.assign({}, owner.moduleBlurEnabled || {})
    if (blurEnabled[moduleName] !== undefined) {
        blur[moduleName] = !!blurEnabled[moduleName]
    } else if (moduleName === "player" && profile.playerBlurEnabled !== undefined) {
        // Backward compatibility for profiles created before per-module blur.
        blur.player = !!profile.playerBlurEnabled
    } else if ((owner.defaultModuleBlurEnabled || {})[moduleName] !== undefined) {
        blur[moduleName] = !!owner.defaultModuleBlurEnabled[moduleName]
    }
    owner.moduleBlurEnabled = blur
    if (moduleName === "player") config.playerBlurEnabled = !!blur.player

    var m = Object.assign({}, owner.moduleMonitors || {})
    if (profileMonitors[moduleName] !== undefined && String(profileMonitors[moduleName]).trim() !== "")
        m[moduleName] = String(profileMonitors[moduleName])
    else
        delete m[moduleName]
    owner.moduleMonitors = m

    if (moduleName === "calendar") {
        applyConfigKeysFromProfile(owner, config, profile, ["animationCalendarVisibilityStyle", "animationCalendarSlideDuration", "animationCalendarFadeDuration", "calendarNoteMarkerStyle", "calendarNoteMarkerPosition", "calendarNoteFrameColor", "calendarAdjacentDaysColor", "calendarWeekendColor", "calendarPastDaysColorEnabled", "calendarPastDaysColor"])
    } else if (moduleName === "cpu") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing",
            "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarDirection", "cpuGraphSegmentSlotWidth",
            "cpuGraphBarWidth", "cpuShowRam"
        ])
    } else if (moduleName === "cpuGraph") {
        applyConfigKeysFromProfile(owner, config, profile, ["cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuGraphMode"])
    } else if (moduleName === "topAppsCpu" || moduleName === "topAppsRam") {
        applyConfigKeysFromProfile(owner, config, profile, ["topAppsShowHeaders", "topAppsCpuHeaderTitle", "topAppsCpuHeaderSubtitle", "topAppsRamHeaderTitle", "topAppsRamHeaderSubtitle", "topAppsHeaderTitleFontSize", "topAppsHeaderSubtitleFontSize", "topAppsShowBars", "topAppsBarX", "topAppsBarY", "topAppsBarHeight", "topAppsBarWidth", "topAppsShowSystemRemainder", "topAppsSystemRemainderLabel", "topAppsFont", "topAppsFontSize", "topAppsRowSpacing", "topAppsTopOffset"])
    } else if (moduleName === "networkStat" || moduleName === "networks") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "systemMonitorInterval", "networkShowUpload", "networkShowDownload", "networkRowHeight",
            "networkRowSpacing", "networkIconSize", "networkValueFontSize", "networkRightPadding",
            "networkHorizontalPadding", "networkIconLeftPadding", "networkIconColumnWidth"
        ])
    } else if (moduleName === "weatherNow" || moduleName === "weatherHourly" || moduleName === "weatherDaily") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes",
            "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds", "weatherIconSize", "weatherIconX",
            "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap", "weatherHourlyCount",
            "weatherDailyCount", "weatherIconY", "weatherWindColumnX", "weatherWindSpeedFontSize",
            "weatherWindUnitFontSize", "weatherPressureY", "weatherDescriptionY", "weatherDescriptionFontSize",
            "weatherTempFontSize", "weatherComfortFontSize", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherShowComfort", "weatherTempColumnWidth", "weatherTempX",
            "weatherTempWidth", "weatherTempOffsetX", "weatherTempOffsetY", "weatherComfortY", "weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortHeight", "weatherWindColumnWidth",
            "weatherWindArrowWidth", "weatherWindIcon", "weatherWindCalmIcon", "weatherWindCalmFont", "weatherWindNIcon", "weatherWindNFont", "weatherWindNEIcon", "weatherWindNEFont", "weatherWindEIcon", "weatherWindEFont", "weatherWindSEIcon", "weatherWindSEFont", "weatherWindSIcon", "weatherWindSFont", "weatherWindSWIcon", "weatherWindSWFont", "weatherWindWIcon", "weatherWindWFont", "weatherWindNWIcon", "weatherWindNWFont", "weatherWindArrowHeight", "weatherWindSpeedX",
            "weatherWindSpeedY", "weatherWindSpeedWidth", "weatherWindUnitX", "weatherWindUnitY",
            "weatherWindUnitWidth", "weatherPressureValueWidth", "weatherPressureFontSize",
            "weatherPressureUnitX", "weatherPressureUnitY", "weatherPressureUnitFontSize", "weatherDescriptionHeight",
            "weatherHourlyTopPadding", "weatherHourlyDayY", "weatherHourlyDayFontSize", "weatherHourlyIconWidth", "weatherHourlyIconY", "weatherHourlyTempY", "weatherHourlyTempHeight",
            "weatherHourlyTempFontSize", "weatherDailyTopPadding", "weatherDailyDayY", "weatherDailyDayFontSize",
            "weatherDailyIconWidth", "weatherDailyIconY", "weatherDailyHighTempX", "weatherDailyHighTempY", "weatherDailyHighTempFontSize", "weatherDailyLowTempX", "weatherDailyLowTempY", "weatherDailyLowTempFontSize"
        ])
        if (profile.weatherToken !== undefined)
            owner.weatherToken = String(profile.weatherToken)
    } else if (moduleName === "timer") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap", "timerCommentAlignFurthest", "timerRowSpacing",
            "timerIcon", "timerIconOrder", "timerIconSize", "timerIconX", "timerIconY", "timerAlarmIcon", "timerAlarmIconSize", "timerAlarmIconX", "timerAlarmIconY",
            "timerFinishedImageEnabled", "timerFinishedImagePath", "timerFinishedBorderUsesTimerColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBackgroundColor", "timerFinishedImageWidth", "timerFinishedImageMargin", "timerFinishedTitleUsesTimerColor", "timerFinishedTitleColor", "timerFinishedTitleFontSize", "timerFinishedTitleFont", "timerFinishedTitleAlignment",
            "timerRowTopMargin", "timerRowRightMargin", "timerButtonFadeDuration",
            "timerButtonSlideDuration", "timerButtonIconFadeDuration", "timerMinHeight"
        ])
        if (profile.timerPresetDefaults !== undefined) {
            owner.timerPresetDefaults = (profile.timerPresetDefaults || []).slice()
            owner.timerPresets = owner.timerPresetDefaults.slice()
        } else if (profile.timerPresets !== undefined) {
            owner.timerPresetDefaults = (profile.timerPresets || []).slice()
            owner.timerPresets = owner.timerPresetDefaults.slice()
        }
    } else if (moduleName === "volumes") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "volumeUpdateInterval", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing",
            "volumeShowStreams", "volumeHorizontalPadding", "volumeVerticalPadding", "volumeMainTrackWidth",
            "volumeMainTrackHeight", "volumeStreamTrackHeight", "volumeMainTrackOffsetY", "volumeStreamTrackOffsetY",
            "volumeMainIconWidth", "volumeIcon", "volumeMutedIcon", "volumeStreamLabelFontSize",
            "volumeTrackRadius", "volumeMinHeight", "volumeMaxHeight"
        ])
    } else if (moduleName === "player") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "playerSilenceText", "playerFont", "playerMetaFont", "playerSilenceFontSize", "playerTextOutlineEnabled",
            "playerTextOutlineColor", "playerSilenceLongFontSize", "playerMetaFontSize", "playerMetaSecondaryFontSize",
            "playerMetaLineSpacing", "playerBoldArtist", "playerShowProgress",
            "playerPlayingIconSize", "playerPausedIconSize", "playerNextIconSize",
            "playerPlayingIconY", "playerPausedIconY", "playerNextIconY",
            "playerPlayingIcon", "playerPausedIcon", "playerNextIcon",
            "playerMetadataXPadding", "playerMetadataY", "playerProgressY",
            "playerProgressTrackHeight", "playerControlTopMargin", "playerControlGap", "playerTimeFontSize",
            "playerTimeY", "playerTimeRightPadding", "playerCoverOpacity", "playerSilenceWidth", "playerProgressTrackOffsetY",
            "playerUpdateInterval"
        ])
    } else if (moduleName === "cava") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "cavaBars", "cavaFramerate", "cavaRowSpacing", "cavaBarWidthRatio", "cavaHideWhenSilent", "cavaHideZeroBars"
        ])
    }

    owner.save()
}

function resetModules(owner, config) {
    var profile = activeProfileData(owner)
    if (!profile) return
    var modules = profile.modules || {}
    for (var i = 0; i < owner.moduleNames.length; ++i) {
        var name = owner.moduleNames[i]
        if (modules[name] !== undefined) owner[name] = !!modules[name]
    }
    owner.moduleFrames = Object.assign({}, profile.moduleFrames || owner.moduleFrames)
    owner.moduleBackgrounds = Object.assign({}, profile.moduleBackgrounds || owner.moduleBackgrounds)
    var oldBlurValues = profile.moduleBlurEnabled || {}
    var blurValues = Object.assign({}, owner.defaultModuleBlurEnabled || {}, oldBlurValues)
    // Older profiles stored the Player flag directly; keep that choice when no new map exists.
    if (oldBlurValues.player === undefined && profile.playerBlurEnabled !== undefined)
        blurValues.player = !!profile.playerBlurEnabled
    // Window blur is edited/reset in the Settings Window tab, not in the module list.
    blurValues.settings = (owner.moduleBlurEnabled || {}).settings !== undefined
        ? !!owner.moduleBlurEnabled.settings : !!(owner.defaultModuleBlurEnabled || {}).settings
    owner.moduleBlurEnabled = blurValues
    if (config) config.playerBlurEnabled = !!blurValues.player
    owner.moduleMonitors = Object.assign({}, profile.moduleMonitors || {})
    if (profile.geometry) owner.geometry = JSON.parse(JSON.stringify(profile.geometry))
    owner.save()
}

function resetColors(owner, config, names, themes, colorNames) {
    resetColorsFromProfile(owner, config, names, themes, colorNames)
}

function resetCpuSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing", "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarDirection", "cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuGraphMode", "cpuShowRam", "topAppsShowHeaders", "topAppsCpuHeaderTitle", "topAppsCpuHeaderSubtitle", "topAppsRamHeaderTitle", "topAppsRamHeaderSubtitle", "topAppsHeaderTitleFontSize", "topAppsHeaderSubtitleFontSize", "topAppsShowBars", "topAppsBarX", "topAppsBarY", "topAppsBarHeight", "topAppsBarWidth", "topAppsShowSystemRemainder", "topAppsSystemRemainderLabel", "topAppsFont", "topAppsFontSize", "topAppsRowSpacing", "topAppsTopOffset"]); owner.save()
}

function resetNetworkSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["systemMonitorInterval", "networkShowUpload", "networkShowDownload", "networkRowHeight", "networkRowSpacing", "networkIconSize", "networkValueFontSize", "networkRightPadding", "networkHorizontalPadding", "networkIconLeftPadding", "networkIconColumnWidth"]); owner.save()
}

function resetVolumeSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["volumeUpdateInterval", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeShowStreams", "volumeHorizontalPadding", "volumeVerticalPadding", "volumeMainTrackWidth", "volumeMainTrackHeight", "volumeStreamTrackHeight", "volumeMainTrackOffsetY", "volumeStreamTrackOffsetY", "volumeMainIconWidth", "volumeIcon", "volumeMutedIcon", "volumeStreamLabelFontSize", "volumeTrackRadius", "volumeMinHeight", "volumeMaxHeight"]); owner.save()
}

function resetTimerSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["animationTimerVisibilityStyle", "animationTimerOptionsDuration", "timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap", "timerCommentAlignFurthest", "timerRowSpacing", "timerIcon", "timerIconOrder", "timerIconSize", "timerIconX", "timerIconY", "timerAlarmIcon", "timerAlarmIconSize", "timerAlarmIconX", "timerAlarmIconY", "timerFinishedImageEnabled", "timerFinishedImagePath", "timerFinishedBorderUsesTimerColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBackgroundColor", "timerFinishedImageWidth", "timerFinishedImageMargin", "timerFinishedTitleUsesTimerColor", "timerFinishedTitleColor", "timerFinishedTitleFontSize", "timerFinishedTitleFont", "timerFinishedTitleAlignment", "timerRowTopMargin", "timerRowRightMargin", "timerButtonFadeDuration", "timerButtonSlideDuration", "timerButtonIconFadeDuration", "timerMinHeight"])
    if (profile.timerIconOrder === undefined) {
        config.timerIconOrder = "alarm-left"
        var legacyTimerX = Number(profile.timerIconX)
        var legacyAlarmX = Number(profile.timerAlarmIconX)
        if (isFinite(legacyTimerX) && isFinite(legacyAlarmX)) {
            config.timerIconX = legacyAlarmX
            config.timerAlarmIconX = legacyTimerX
        }
    }
    if (profile.timerPresetDefaults !== undefined) owner.timerPresetDefaults = (profile.timerPresetDefaults || []).slice()
    else if (profile.timerPresets !== undefined) owner.timerPresetDefaults = (profile.timerPresets || []).slice()
    owner.timerPresets = owner.timerPresetDefaults.slice()
    owner.save()
}

function resetPlayerSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["playerSilenceText", "playerFont", "playerMetaFont", "playerSilenceFontSize", "playerTextOutlineEnabled", "playerTextOutlineColor", "playerSilenceLongFontSize", "playerMetaFontSize", "playerMetaSecondaryFontSize", "playerMetaLineSpacing", "playerBoldArtist", "playerShowProgress", "playerPlayingIconSize", "playerPausedIconSize", "playerNextIconSize", "playerPlayingIconY", "playerPausedIconY", "playerNextIconY", "playerPlayingIcon", "playerPausedIcon", "playerNextIcon", "playerMetadataXPadding", "playerMetadataY", "playerProgressY", "playerProgressTrackHeight", "playerControlTopMargin", "playerControlGap", "playerTimeFontSize", "playerTimeFont", "playerTimeY", "playerTimeRightPadding", "playerCoverOpacity", "playerSilenceWidth", "playerProgressTrackOffsetY", "playerPriority", "playerUpdateInterval"]); owner.save()
}

function resetMopidySettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["animationMopidyVisibilityStyle", "mopidyShowTrackNumbers", "mopidyTopIconOrder", "mopidyMoveUpIcon", "mopidyMoveUpIconSize", "mopidyMoveUpIconX", "mopidyMoveUpIconY", "mopidyShowMoveUpIcon", "mopidyMoveDownIcon", "mopidyMoveDownIconSize", "mopidyMoveDownIconX", "mopidyMoveDownIconY", "mopidyShowMoveDownIcon", "mopidyGroupAlbums", "mopidyAlbumFont", "mopidyAlbumFontSize", "mopidyAlbumBold", "mopidyTrackFont", "mopidyTrackFontSize", "mopidyTrackRowHeight", "mopidyArtistFont", "mopidyArtistFontSize", "mopidyArtistBold", "mopidyArtistItalic", "mopidyTrackArtistDisplayMode", "mopidyTrackArtistSeparator", "mopidyDurationFont", "mopidyDurationFontSize", "mopidyAlbumSeparator", "mopidyBackground", "mopidyToggleWithPlayerRightClick", "mopidyHideTopPanel", "mopidyTopPanelHoverHeight", "mopidyTopPanelOffsetY", "mopidyTopPanelBackground", "mopidyHoverMode", "mopidyHoverColor", "mopidyStopIcon", "mopidyStopIconSize", "mopidyStopIconX", "mopidyStopIconY", "mopidyRefreshIcon", "mopidyRefreshIconSize", "mopidyRefreshIconX", "mopidyRefreshIconY", "mopidyClearIcon", "mopidyClearIconSize", "mopidyClearIconX", "mopidyClearIconY", "mopidyControlIconColor", "mopidyShowStopIcon", "mopidyShowRefreshIcon", "mopidyShowClearIcon", "mopidyShowQueueTotalDuration", "mopidyQueueDurationMode", "mopidyQueueDurationFont", "mopidyQueueDurationFontSize", "mopidyQueueDurationColor", "mopidyQueueDurationX", "mopidyQueueDurationY", "mopidyQueueDurationAlignment", "mopidyShowAlbumRemaining", "mopidyShowTrackRemaining", "mopidyShuffleIcon", "mopidyShuffleIconSize", "mopidyShuffleIconX", "mopidyShuffleIconY", "mopidyShowShuffleIcon", "mopidyRepeatIcon", "mopidyRepeatIconSize", "mopidyRepeatIconX", "mopidyRepeatIconY", "mopidyShowRepeatIcon", "mopidyOpenAddIcon", "mopidyOpenAddIconSize", "mopidyOpenAddIconX", "mopidyOpenAddIconY", "mopidyShowOpenAddIcon", "mopidyAddIcon", "mopidyAddIconSize", "mopidyAddIconX", "mopidyAddIconY", "mopidyShowAddIcon", "mopidySwitchPlaylistIcon", "mopidySwitchPlaylistIconSize", "mopidySwitchPlaylistIconX", "mopidySwitchPlaylistIconY", "mopidyShowSwitchPlaylistIcon", "mopidyPlaylistDeleteIcon", "mopidyPlaylistDeleteIconSize", "mopidyPlaylistDeleteIconX", "mopidyPlaylistDeleteIconY", "mopidyShowPlaylistDeleteIcon", "mopidyVolumeIcon", "mopidyMutedIcon", "mopidyVolumeIconSize", "mopidyVolumeIconX", "mopidyVolumeIconY", "mopidyMutedIconSize", "mopidyMutedIconX", "mopidyMutedIconY", "mopidyShowVolumeIcon", "mopidyShowVolumePercent", "mopidyVolumeStep", "mopidyEmptyQueueText", "mopidyUnavailableText", "mopidyStatusFont", "mopidyStatusFontSize", "mopidyStatusLongFontSize", "mopidyStatusWidth"]); owner.save()
}

function resetWeatherSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes", "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds", "weatherIconSize", "weatherIconX", "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap", "weatherHourlyCount", "weatherDailyCount", "weatherIconY", "weatherWindColumnX", "weatherWindSpeedFontSize", "weatherWindUnitFontSize", "weatherPressureY", "weatherDescriptionY", "weatherDescriptionFontSize", "weatherTempFontSize", "weatherComfortFontSize", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherShowComfort", "weatherTempColumnWidth", "weatherTempX", "weatherTempWidth", "weatherTempOffsetX", "weatherTempOffsetY", "weatherComfortY", "weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortHeight", "weatherWindColumnWidth", "weatherWindArrowWidth", "weatherWindIcon", "weatherWindCalmIcon", "weatherWindCalmFont", "weatherWindNIcon", "weatherWindNFont", "weatherWindNEIcon", "weatherWindNEFont", "weatherWindEIcon", "weatherWindEFont", "weatherWindSEIcon", "weatherWindSEFont", "weatherWindSIcon", "weatherWindSFont", "weatherWindSWIcon", "weatherWindSWFont", "weatherWindWIcon", "weatherWindWFont", "weatherWindNWIcon", "weatherWindNWFont", "weatherWindArrowHeight", "weatherWindSpeedX", "weatherWindSpeedY", "weatherWindSpeedWidth", "weatherWindUnitX", "weatherWindUnitY", "weatherWindUnitWidth", "weatherPressureValueWidth", "weatherPressureFontSize", "weatherPressureUnitX", "weatherPressureUnitY", "weatherPressureUnitFontSize", "weatherDescriptionHeight", "weatherHourlyTopPadding", "weatherHourlyDayY", "weatherHourlyDayFontSize", "weatherHourlyIconWidth", "weatherHourlyIconY", "weatherHourlyTempY", "weatherHourlyTempHeight", "weatherHourlyTempFontSize", "weatherDailyTopPadding", "weatherDailyDayY", "weatherDailyDayFontSize", "weatherDailyIconWidth", "weatherDailyIconY", "weatherDailyHighTempX", "weatherDailyHighTempY", "weatherDailyHighTempFontSize", "weatherDailyLowTempX", "weatherDailyLowTempY", "weatherDailyLowTempFontSize"]);
    if (profile.weatherToken !== undefined) owner.weatherToken = String(profile.weatherToken)
    owner.save()
}

function resetCalendarSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["calendarPreviousIcon", "calendarNextIcon", "calendarPreviousSize", "calendarNextSize", "calendarArrowY", "calendarPreviousX", "calendarNextX", "calendarTitleFontSize", "calendarTitleY", "calendarTitleFont", "calendarWeekdayFontSize", "calendarWeekdayY", "calendarWeekdayFont", "calendarDayFontSize", "calendarDayY", "calendarDayFont", "calendarNoteMarkerStyle", "calendarNoteMarkerPosition", "calendarNoteFrameColor", "calendarAdjacentDaysColor", "calendarWeekendColor", "calendarPastDaysColorEnabled", "calendarPastDaysColor"]); owner.save()
}

function resetCavaSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["cavaBars", "cavaFramerate", "cavaRowSpacing", "cavaBarWidthRatio", "cavaMode", "cavaHideWhenSilent", "cavaHideZeroBars"]); owner.save()
}

function resetGeneralSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["font", "fontSize", "ledFont", "frameBorderWidth", "frameRadius", "backgroundBlurRadius"]); owner.save()
}

function resetSettingsWindow(owner, config) {
    resetSettingsWindowFromProfile(owner, config)
}

function resetLauncherSettings(owner, config) {
    var profile = activeProfileData(owner)
    if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["launcherEnabled", "launcherWidth", "launcherHeight", "launcherItemHeight", "launcherItemRadius", "launcherRadius", "launcherBackdropOpacity", "launcherBackground", "launcherTitleText", "launcherTitleFont", "launcherTitleFontSize", "launcherTitleY", "launcherTitleColor", "launcherTitleLetterSpacing", "launcherTitleBold", "launcherSearchFont", "launcherSearchFontSize", "launcherSearchHeight", "launcherSearchRadius", "launcherSearchBackground", "launcherSearchPlaceholder", "launcherDefaultMode", "launcherShowResultCount", "launcherCrossSearchProjects", "launcherCrossSearchRunHistory", "launcherTabOrder", "launcherTabVisible", "launcherTabLabels", "launcherTabIcons", "launcherProjects"])
    // Older profiles predate editable launcher tab labels and icons.
    if (profile.launcherTabLabels === undefined) config.launcherTabLabels = ["Apps", "Run", "Windows", "Clipboard", "Power", "Network", "Packages", "Pass", "Projects"]
    if (profile.launcherTabIcons === undefined) config.launcherTabIcons = ["󰀻", "", "󰖯", "󰅇", "", "󰖩", "󱄅", "󰌋", ""]
    // Older full-profile snapshots predate the launcher title position/color fields.
    if (profile.launcherTitleY === undefined) config.launcherTitleY = 0
    if (profile.launcherTitleColor === undefined) config.launcherTitleColor = "#ffffff"

    // Position and monitor are part of the launcher module configuration too.
    var geometry = Object.assign({}, owner.geometry || {})
    geometry.launcher = profile.geometry && profile.geometry.launcher
        ? profile.geometry.launcher.slice()
        : ((owner.defaultGeometry && owner.defaultGeometry.launcher) || [-999999, -999999, Number(config.launcherWidth) || 720, Number(config.launcherHeight) || 640]).slice()
    owner.geometry = geometry
    var monitors = Object.assign({}, owner.moduleMonitors || {})
    var profileMonitors = profile.moduleMonitors || {}
    if (profileMonitors.launcher !== undefined && String(profileMonitors.launcher).trim() !== "")
        monitors.launcher = String(profileMonitors.launcher)
    else
        delete monitors.launcher
    owner.moduleMonitors = monitors

    // Restore the launcher row's Frame and Background flags along with its detailed settings.
    var profileFrames = profile.moduleFrames || {}
    var frames = Object.assign({}, owner.moduleFrames || {})
    frames.launcher = profileFrames.launcher !== undefined ? !!profileFrames.launcher : true
    owner.moduleFrames = frames

    var profileBackgrounds = profile.moduleBackgrounds || {}
    var backgrounds = Object.assign({}, owner.moduleBackgrounds || {})
    backgrounds.launcher = profileBackgrounds.launcher !== undefined ? !!profileBackgrounds.launcher : true
    owner.moduleBackgrounds = backgrounds
    var profileBlurEnabled = profile.moduleBlurEnabled || {}
    var blurEnabled = Object.assign({}, owner.moduleBlurEnabled || {})
    blurEnabled.launcher = profileBlurEnabled.launcher !== undefined ? !!profileBlurEnabled.launcher : !!(owner.defaultModuleBlurEnabled || {}).launcher
    owner.moduleBlurEnabled = blurEnabled
    owner.save()
}

function resetAllSettings(owner, themes, colorNames) {
    var profile = activeProfileData(owner)
    if (!profile) return
    var currentProfile = owner.activeProfile
    owner.applyObject(JSON.parse(JSON.stringify(profile)))
    restoreProfileTheme(owner, profile, themes, colorNames)
    owner.activeProfile = currentProfile
    owner.save()
}
