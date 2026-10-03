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
    if (owner.activeProfile && owner.profiles && owner.profiles[owner.activeProfile])
        return owner.profiles[owner.activeProfile]
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
    applyConfigKeysFromProfile(owner, config, profile, ["settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing"])
    owner.save()
}

function resetModule(owner, config, moduleName) {
    if (!moduleName) return

    var profile = activeProfileData(owner)
    if (!profile) return

    var modules = profile.modules || {}
    var frames = profile.moduleFrames || {}
    var backgrounds = profile.moduleBackgrounds || {}
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

    if (moduleName === "calendar") {
        applyConfigKeysFromProfile(owner, config, profile, ["animationCalendarSlideDuration", "animationCalendarFadeDuration"])
    } else if (moduleName === "cpu") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing",
            "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuGraphSegmentSlotWidth",
            "cpuGraphBarWidth", "cpuShowRam"
        ])
    } else if (moduleName === "cpuGraph") {
        applyConfigKeysFromProfile(owner, config, profile, ["cpuGraphSegmentSlotWidth", "cpuGraphBarWidth"])
    } else if (moduleName === "networkStat" || moduleName === "networks") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "systemMonitorInterval", "networkShowUpload", "networkShowDownload", "networkRowHeight",
            "networkRowSpacing", "networkIconSize", "networkValueFontSize", "networkRightPadding",
            "networkHorizontalPadding", "networkIconLeftPadding", "networkIconColumnWidth"
        ])
    } else if (moduleName === "weatherNow" || moduleName === "weatherHourly" || moduleName === "weatherDaily") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes",
            "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds", "weatherIconSize",
            "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap", "weatherHourlyCount",
            "weatherDailyCount", "weatherIconY", "weatherWindColumnX", "weatherWindSpeedFontSize",
            "weatherWindUnitFontSize", "weatherPressureY", "weatherDescriptionY", "weatherDescriptionFontSize",
            "weatherTempFontSize", "weatherComfortFontSize", "weatherTempColumnWidth", "weatherTempX",
            "weatherTempWidth", "weatherTempOffsetX", "weatherTempOffsetY", "weatherComfortY", "weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortHeight", "weatherWindColumnWidth",
            "weatherWindArrowWidth", "weatherWindIcon", "weatherWindArrowHeight", "weatherWindSpeedX",
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
            "timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap", "timerRowSpacing",
            "timerIcon", "timerIconOrder", "timerIconSize", "timerIconX", "timerIconY", "timerAlarmIcon", "timerAlarmIconSize", "timerAlarmIconX", "timerAlarmIconY",
            "timerFinishedImageEnabled", "timerFinishedImagePath", "timerFinishedBorderUsesTimerColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBackgroundColor", "timerFinishedImageWidth", "timerFinishedImageMargin", "timerFinishedImageTopMargin", "timerFinishedImageBottomMargin", "timerFinishedTitleUsesTimerColor", "timerFinishedTitleColor", "timerFinishedTitleFontSize", "timerFinishedTitleFont", "timerFinishedTitleAlignment",
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
            "playerMetaLineSpacing", "playerBoldArtist", "playerShowProgress", "playerControlIconSize",
            "playerPlayingIconSize", "playerPausedIconSize", "playerNextIconSize",
            "playerPlayingIconY", "playerPausedIconY", "playerNextIconY",
            "playerPlayingIcon", "playerPausedIcon", "playerNextIcon", "playerBlurEnabled", "playerBlurRadius",
            "playerMetadataXPadding", "playerMetadataY", "playerProgressY",
            "playerProgressTrackHeight", "playerControlTopMargin", "playerControlGap", "playerTimeFontSize",
            "playerTimeRightPadding", "playerCoverOpacity", "playerSilenceWidth", "playerProgressTrackOffsetY",
            "playerUpdateInterval"
        ])
    } else if (moduleName === "cava") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "cavaBars", "cavaFramerate", "cavaRowSpacing", "cavaBarWidthRatio"
        ])
    }

    owner.save()
}

function resetModules(owner) {
    var profile = activeProfileData(owner)
    if (!profile) return
    var modules = profile.modules || {}
    for (var i = 0; i < owner.moduleNames.length; ++i) {
        var name = owner.moduleNames[i]
        if (modules[name] !== undefined) owner[name] = !!modules[name]
    }
    owner.moduleFrames = Object.assign({}, profile.moduleFrames || owner.moduleFrames)
    owner.moduleBackgrounds = Object.assign({}, profile.moduleBackgrounds || owner.moduleBackgrounds)
    if (profile.geometry) owner.geometry = JSON.parse(JSON.stringify(profile.geometry))
    owner.save()
}

function resetColors(owner, config, names, themes, colorNames) {
    resetColorsFromProfile(owner, config, names, themes, colorNames)
}

function resetCpuSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing", "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuShowRam"]); owner.save()
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
    applyConfigKeysFromProfile(owner, config, profile, ["timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap", "timerRowSpacing", "timerIcon", "timerIconOrder", "timerIconSize", "timerIconX", "timerIconY", "timerAlarmIcon", "timerAlarmIconSize", "timerAlarmIconX", "timerAlarmIconY", "timerFinishedImageEnabled", "timerFinishedImagePath", "timerFinishedBorderUsesTimerColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBackgroundColor", "timerFinishedImageWidth", "timerFinishedImageMargin", "timerFinishedImageTopMargin", "timerFinishedImageBottomMargin", "timerFinishedTitleUsesTimerColor", "timerFinishedTitleColor", "timerFinishedTitleFontSize", "timerFinishedTitleFont", "timerFinishedTitleAlignment", "timerRowTopMargin", "timerRowRightMargin", "timerButtonFadeDuration", "timerButtonSlideDuration", "timerButtonIconFadeDuration", "timerMinHeight"])
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
    applyConfigKeysFromProfile(owner, config, profile, ["playerSilenceText", "playerFont", "playerMetaFont", "playerSilenceFontSize", "playerTextOutlineEnabled", "playerTextOutlineColor", "playerSilenceLongFontSize", "playerMetaFontSize", "playerMetaSecondaryFontSize", "playerMetaLineSpacing", "playerBoldArtist", "playerShowProgress", "playerControlIconSize", "playerPlayingIconSize", "playerPausedIconSize", "playerNextIconSize", "playerPlayingIconY", "playerPausedIconY", "playerNextIconY", "playerPlayingIcon", "playerPausedIcon", "playerNextIcon", "playerBlurEnabled", "playerBlurRadius", "playerMetadataXPadding", "playerMetadataY", "playerProgressY", "playerProgressTrackHeight", "playerControlTopMargin", "playerControlGap", "playerTimeFontSize", "playerTimeFont", "playerTimeRightPadding", "playerCoverOpacity", "playerSilenceWidth", "playerProgressTrackOffsetY", "playerUpdateInterval"]); owner.save()
}

function resetWeatherSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes", "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds", "weatherIconSize", "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap", "weatherHourlyCount", "weatherDailyCount", "weatherIconY", "weatherWindColumnX", "weatherWindSpeedFontSize", "weatherWindUnitFontSize", "weatherPressureY", "weatherDescriptionY", "weatherDescriptionFontSize", "weatherTempFontSize", "weatherComfortFontSize", "weatherTempColumnWidth", "weatherTempX", "weatherTempWidth", "weatherTempOffsetX", "weatherTempOffsetY", "weatherComfortY", "weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortHeight", "weatherWindColumnWidth", "weatherWindArrowWidth", "weatherWindIcon", "weatherWindArrowHeight", "weatherWindSpeedX", "weatherWindSpeedY", "weatherWindSpeedWidth", "weatherWindUnitX", "weatherWindUnitY", "weatherWindUnitWidth", "weatherPressureValueWidth", "weatherPressureFontSize", "weatherPressureUnitX", "weatherPressureUnitY", "weatherPressureUnitFontSize", "weatherDescriptionHeight", "weatherHourlyTopPadding", "weatherHourlyDayY", "weatherHourlyDayFontSize", "weatherHourlyIconWidth", "weatherHourlyIconY", "weatherHourlyTempY", "weatherHourlyTempHeight", "weatherHourlyTempFontSize", "weatherDailyTopPadding", "weatherDailyDayY", "weatherDailyDayFontSize", "weatherDailyIconWidth", "weatherDailyIconY", "weatherDailyHighTempX", "weatherDailyHighTempY", "weatherDailyHighTempFontSize", "weatherDailyLowTempX", "weatherDailyLowTempY", "weatherDailyLowTempFontSize"]);
    if (profile.weatherToken !== undefined) owner.weatherToken = String(profile.weatherToken)
    owner.save()
}

function resetCalendarSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["calendarPreviousIcon", "calendarNextIcon", "calendarPreviousSize", "calendarNextSize", "calendarArrowY", "calendarPreviousX", "calendarNextX", "calendarTitleFontSize", "calendarTitleY", "calendarTitleFont", "calendarWeekdayFontSize", "calendarWeekdayY", "calendarWeekdayFont", "calendarDayFontSize", "calendarDayY", "calendarDayFont"]); owner.save()
}

function resetCavaSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["cavaBars", "cavaFramerate", "cavaRowSpacing", "cavaBarWidthRatio"]); owner.save()
}

function resetGeneralSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["font", "fontSize", "ledFont", "frameBorderWidth", "frameRadius"]); owner.save()
}

function resetAnimationSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["animationsEnabled", "animationSpeed", "animationEasing", "animationAppearanceEnabled", "animationMovementEnabled", "animationSizeEnabled", "animationExpansionEnabled", "animationTimerOptionsDuration", "animationCalendarSlideDuration", "animationCalendarFadeDuration"]); owner.save()
}

function resetSettingsWindow(owner, config) {
    resetSettingsWindowFromProfile(owner, config)
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
