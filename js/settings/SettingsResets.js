// Settings reset logic extracted from Settings.qml.



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

function normalizeLauncherDynamicSchemeVariant(value) {
    var candidate = String(value === undefined || value === null ? "" : value).trim()
    var supported = ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot"]
    return supported.indexOf(candidate) >= 0 ? candidate : "scheme-tonal-spot"
}


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
            var comparableColors = owner && Array.isArray(owner.themeManagedColorNames)
                ? owner.themeManagedColorNames
                : (colorNames || []).filter(function(key) {
                    return ["settingsBackground", "playerProgressTrack", "playerProgressFill",
                        "topAppsCpuBarColor", "topAppsRamBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarTrackColor"].indexOf(key) < 0
                })
            for (var j = 0; j < comparableColors.length; ++j) {
                var key = comparableColors[j]
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
    if (owner.activeProfile && owner.profiles
            && Object.prototype.hasOwnProperty.call(owner.profiles, owner.activeProfile)
            && owner.profiles[owner.activeProfile]) {
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

    // Older profiles stored an independent master checkbox. Translate a
    // disabled legacy value into the new explicit "none" profile on reset.
    var legacyAnimationPairs = [
        ["animationMopidyMorphEnabled", "animationMopidyMorphProfile"],
        ["animationPlayerMorphEnabled", "animationPlayerMorphProfile"],
        ["animationWeatherMorphEnabled", "animationWeatherMorphProfile"],
        ["animationTimerMorphEnabled", "animationTimerMorphProfile"]
    ]
    for (var a = 0; a < legacyAnimationPairs.length; ++a) {
        var enabledKey = legacyAnimationPairs[a][0]
        var profileKey = legacyAnimationPairs[a][1]
        if (names.indexOf(enabledKey) < 0) continue
        config[enabledKey] = true
        if (profile[enabledKey] === false)
            config[profileKey] = "none"
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
    applyConfigKeysFromProfile(owner, config, profile, ["animationSettingsVisibilityStyle", "settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing", "settingsSearchHighlightColor", "settingsSearchHighlightBorderWidth", "settingsSearchMatchCountFontSize", "settingsSearchVisible", "settingsNavigationOrder", "settingsTabLabels"])
    if (profile.settingsNavigationOrder !== undefined)
        config.settingsNavigationOrder = owner && typeof owner.normalizeSettingsNavigationOrder === "function"
            ? owner.normalizeSettingsNavigationOrder(profile.settingsNavigationOrder) : profile.settingsNavigationOrder
    else if (profile.settingsTabOrder !== undefined)
        config.settingsNavigationOrder = owner && typeof owner.settingsNavigationOrderFromLegacyTabOrder === "function"
            ? owner.settingsNavigationOrderFromLegacyTabOrder(profile.settingsTabOrder) : config.settingsNavigationOrder
    if (profile.settingsSearchHighlightColor === undefined)
        config.settingsSearchHighlightColor = owner.defaultConfig.settingsSearchHighlightColor
    if (profile.settingsSearchHighlightBorderWidth === undefined)
        config.settingsSearchHighlightBorderWidth = owner.defaultConfig.settingsSearchHighlightBorderWidth
    if (profile.settingsSearchMatchCountFontSize === undefined)
        config.settingsSearchMatchCountFontSize = owner.defaultConfig.settingsSearchMatchCountFontSize
    if (profile.settingsSearchVisible === undefined)
        config.settingsSearchVisible = owner.defaultConfig.settingsSearchVisible
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
    else if (owner.defaultGeometry && owner.defaultGeometry[moduleName])
        g[moduleName] = owner.defaultGeometry[moduleName].slice()
    owner.geometry = g

    var f = Object.assign({}, owner.moduleFrames || {})
    if (frames[moduleName] !== undefined) {
        f[moduleName] = !!frames[moduleName]
    } else if ((owner.defaultModuleFrames || {})[moduleName] !== undefined) {
        // Older profiles may predate a module's appearance toggles. Fall back
        // to the current built-in module defaults instead of preserving edits.
        f[moduleName] = !!owner.defaultModuleFrames[moduleName]
    }
    owner.moduleFrames = f

    var b = Object.assign({}, owner.moduleBackgrounds || {})
    if (backgrounds[moduleName] !== undefined) {
        b[moduleName] = !!backgrounds[moduleName]
    } else if ((owner.defaultModuleBackgrounds || {})[moduleName] !== undefined) {
        b[moduleName] = !!owner.defaultModuleBackgrounds[moduleName]
    }
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

    if (moduleName === "time") {
        applyConfigKeysFromProfile(owner, config, profile, ["clockFont", "clockFontSize", "clockDateFontSize", "clockWeekdayFont", "clockWeekdayFontSize"])
    } else if (moduleName === "calendar") {
        applyConfigKeysFromProfile(owner, config, profile, ["animationCalendarVisibilityStyle", "animationCalendarSlideDuration", "animationCalendarFadeDuration", "animationCalendarMorphDuration", "animationCalendarMorphProfile", "calendarNoteMarkerStyle", "calendarNoteMarkerPosition", "calendarNoteFrameColor", "calendarAdjacentDaysColor", "calendarWeekendColor", "calendarPastDaysColorEnabled", "calendarPastDaysColor"])
    } else if (moduleName === "cpu") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing",
            "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarDirection", "cpuGraphSegmentSlotWidth",
            "cpuGraphBarWidth", "cpuShowRam", "animationCpuMorphDuration", "animationCpuMorphProfile"
        ])
    } else if (moduleName === "cpuGraph") {
        applyConfigKeysFromProfile(owner, config, profile, ["cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuGraphMode"])
    } else if (moduleName === "topAppsCpu" || moduleName === "topAppsRam") {
        applyConfigKeysFromProfile(owner, config, profile, ["topAppsShowHeaders", "topAppsCpuHeaderTitle", "topAppsCpuHeaderSubtitle", "topAppsRamHeaderTitle", "topAppsRamHeaderSubtitle", "topAppsHeaderTitleFontSize", "topAppsHeaderSubtitleFontSize", "topAppsShowBars", "topAppsBarX", "topAppsBarY", "topAppsBarHeight", "topAppsBarWidth", "topAppsShowSystemRemainder", "topAppsSystemRemainderLabel", "topAppsFont", "topAppsFontSize", "topAppsRowSpacing", "topAppsTopOffset"])
    } else if (moduleName === "networkStat" || moduleName === "networks") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "systemMonitorInterval", "networkShowUpload", "networkShowDownload", "networksAlwaysVisible", "networkSpacing", "networkTopPadding",
            "networkIconSize", "networkValueFontSize", "networkRightPadding",
            "networkIconLeftPadding", "networkFont"
        ])
        if (moduleName === "networks")
            applyConfigKeysFromProfile(owner, config, profile, ["animationNetworkVisibilityStyle", "animationNetworkVisibilityDuration", "animationNetworkMorphDuration", "animationNetworkMorphProfile"])
    } else if (moduleName === "weatherNow" || moduleName === "weatherHourly" || moduleName === "weatherDaily") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "animationWeatherMorphEnabled", "animationWeatherMorphDuration", "animationWeatherHourlyDuration", "animationWeatherMorphProfile",
            "weatherFont", "weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes",
            "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds", "weatherIconSize", "weatherIconX",
            "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap", "weatherHourlyCount",
            "weatherDailyCount", "weatherIconY", "weatherWindColumnX", "weatherWindColumnY", "weatherPressureX", "weatherDescriptionX", "weatherDescriptionWidth", "weatherMiddleBlockWidth", "weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment", "weatherIconPlacement", "weatherWindSpeedFontSize",
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
            "timerElapsedFont", "timerElapsedFontSize", "timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap", "timerCommentAlignFurthest", "timerRowSpacing",
            "timerIcon", "timerIconEnabled", "timerIconOrder", "timerIconSize", "timerIconX", "timerIconY", "timerAlarmIcon", "timerAlarmIconEnabled", "timerAlarmIconSize", "timerAlarmIconX", "timerAlarmIconY",
            "timerOptionsCommentIcon", "timerOptionsCommentIconEnabled", "timerOptionsCommentIconSize", "timerOptionsDurationIcon", "timerOptionsDurationIconEnabled", "timerOptionsDurationIconSize",
            "timerOptionsRefreshIcon", "timerOptionsRefreshIconEnabled", "timerOptionsRefreshIconSize", "timerOptionsPauseIcon", "timerOptionsPauseIconEnabled", "timerOptionsPauseIconSize", "timerOptionsColorIcon", "timerOptionsColorIconEnabled", "timerOptionsColorIconSize", "timerOptionsActionIconOrder", "timerRandomColorMode", "timerRandomColorMin", "timerRandomColorMax",
            "timerFinishedImageEnabled", "timerFinishedImagePath", "timerFinishedBorderUsesTimerColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBackgroundColor", "timerFinishedImageWidth", "timerFinishedImageMargin", "timerFinishedTitleUsesTimerColor", "timerFinishedTitleColor", "timerFinishedTitleFontSize", "timerFinishedTitleFont", "timerFinishedTitleAlignment",
            "timerRowTopMargin", "timerRowRightMargin", "timerButtonFadeDuration",
            "timerButtonSlideDuration", "timerButtonIconFadeDuration", "timerMinHeight"
        ])
        if (profile.timerOptionsActionIconOrder === undefined)
            config.timerOptionsActionIconOrder = ["comment", "duration", "refresh", "toggle_pause", "color"]
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
            "volumeMainIconWidth", "volumeIcon", "volumeMutedIcon", "volumeStreamLabelFont", "volumeStreamLabelFontSize",
            "volumeTrackRadius", "volumeMinHeight", "volumeMaxHeight",
            "animationVolumeStreamsVisibilityStyle", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"
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
            "cavaBars", "cavaFramerate", "cavaRowSpacing", "cavaBarWidthRatio", "cavaHideWhenSilent", "cavaHideZeroBars",
            "animationCavaMorphDuration", "animationCavaMorphProfile"
        ])
    } else if (moduleName === "notifications") {
        applyConfigKeysFromProfile(owner, config, profile, [
            "notificationsDefaultTimeout", "notificationsCriticalTimeout", "notificationsShowTimeoutIndicator", "notificationsTimeoutIndicatorColor", "notificationsTimeoutIndicatorStyle", "notificationsTimeoutIndicatorDirection", "notificationsVerticalAnchor", "notificationsCardWidth", "notificationsCardSpacing",
            "notificationsImageHeight", "notificationsBackgroundColor", "notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold", "notificationsLeadingVisualSize", "notificationsLeadingVisualRadius", "notificationsCardPadding", "notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress",
            "animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle"
        ])
        resetNotificationTimeoutIndicatorDefaults(owner, config, profile)
        // Geometry is authoritative for module placement. Keep its width and the
        // legacy scalar aligned when resetting profiles created before this move.
        var notificationGeometry = Object.assign({}, owner.geometry || {})
        var notificationValues = (notificationGeometry.notifications || [-999999, 16, 380, 0]).slice()
        if (profile.notificationsCardWidth === undefined) {
            // Older profiles may not have the notification geometry entry at all.
            // In that case owner.geometry already contains the built-in fallback
            // restored above; use it to reset the legacy scalar width as well.
            var resetNotificationGeometry = profileGeometry.notifications
                || (owner.geometry || {}).notifications
                || (owner.defaultGeometry || {}).notifications
            if (resetNotificationGeometry && resetNotificationGeometry.length > 2) {
                config.notificationsCardWidth = Math.max(280, Math.min(600,
                    Number(resetNotificationGeometry[2]) || Number(notificationValues[2]) || 380))
            }
        }
        notificationValues[2] = Math.max(280, Math.min(600,
            Number(config.notificationsCardWidth) || Number(notificationValues[2]) || 380))
        config.notificationsCardWidth = notificationValues[2]
        notificationGeometry.notifications = notificationValues
        owner.geometry = notificationGeometry
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
    // Keep the moved module width synchronized with the legacy profile key.
    if (config) {
        var notificationGeometry = Object.assign({}, owner.geometry || {})
        var notificationValues = (notificationGeometry.notifications || [-999999, 16, 380, 0]).slice()
        var savedNotificationWidth = profile.notificationsCardWidth !== undefined
            ? Number(profile.notificationsCardWidth) : Number(notificationValues[2])
        notificationValues[2] = Math.max(280, Math.min(600,
            savedNotificationWidth || Number(notificationValues[2]) || Number(config.notificationsCardWidth) || 380))
        config.notificationsCardWidth = notificationValues[2]
        notificationGeometry.notifications = notificationValues
        owner.geometry = notificationGeometry
    }
    owner.save()
}

function resetColors(owner, config, names, themes, colorNames) {
    resetColorsFromProfile(owner, config, names, themes, colorNames)
}

function resetCpuSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["cpuUpdateInterval", "cpuBarThickness", "cpuBarWidth", "cpuRowHeight", "cpuRowSpacing", "cpuLabelLeftPadding", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarDirection", "cpuGraphSegmentSlotWidth", "cpuGraphBarWidth", "cpuGraphMode", "cpuShowRam", "animationCpuMorphDuration", "animationCpuMorphProfile", "topAppsShowHeaders", "topAppsCpuHeaderTitle", "topAppsCpuHeaderSubtitle", "topAppsRamHeaderTitle", "topAppsRamHeaderSubtitle", "topAppsHeaderTitleFontSize", "topAppsHeaderSubtitleFontSize", "topAppsShowBars", "topAppsBarX", "topAppsBarY", "topAppsBarHeight", "topAppsBarWidth", "topAppsShowSystemRemainder", "topAppsSystemRemainderLabel", "topAppsFont", "topAppsFontSize", "topAppsRowSpacing", "topAppsTopOffset"])
    // The four Top Apps bar colors live inside profile.colors. Restore only
    // those fields here so the CPU/RAM page-level Reset action also clears
    // their sparse overrides without disturbing unrelated palette edits.
    var profileColors = profile.colors || {}
    var topAppsColorNames = ["topAppsCpuBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarColor", "topAppsRamBarTrackColor"]
    for (var i = 0; i < topAppsColorNames.length; ++i) {
        var colorName = topAppsColorNames[i]
        if (profileColors[colorName] !== undefined)
            config[colorName] = profileColors[colorName]
    }
    owner.save()
}

function resetNetworkSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["systemMonitorInterval", "networkShowUpload", "networkShowDownload", "networksAlwaysVisible", "networkSpacing", "networkTopPadding", "networkIconSize", "networkValueFontSize", "networkRightPadding", "networkIconLeftPadding", "networkFont", "animationNetworkVisibilityStyle", "animationNetworkVisibilityDuration", "animationNetworkMorphDuration", "animationNetworkMorphProfile"]); owner.save()
}

function resetVolumeSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["volumeUpdateInterval", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeShowStreams", "volumeHorizontalPadding", "volumeVerticalPadding", "volumeMainTrackWidth", "volumeMainTrackHeight", "volumeStreamTrackHeight", "volumeMainTrackOffsetY", "volumeStreamTrackOffsetY", "volumeMainIconWidth", "volumeIcon", "volumeMutedIcon", "volumeStreamLabelFont", "volumeStreamLabelFontSize", "volumeTrackRadius", "volumeMinHeight", "volumeMaxHeight", "animationVolumeStreamsVisibilityStyle", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"]); owner.save()
}

function resetTimerSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["animationTimerMorphEnabled", "animationTimerMorphDuration", "animationTimerMorphProfile", "animationTimerVisibilityStyle", "animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration", "timerElapsedFont", "timerElapsedFontSize", "timerWheelStep", "timerCommentWidth", "timerCommentMaxLength", "timerCommentGap", "timerCommentAlignFurthest", "timerRowSpacing", "timerIcon", "timerIconEnabled", "timerIconOrder", "timerIconSize", "timerIconX", "timerIconY", "timerAlarmIcon", "timerAlarmIconEnabled", "timerAlarmIconSize", "timerAlarmIconX", "timerAlarmIconY", "timerOptionsCommentIcon", "timerOptionsCommentIconEnabled", "timerOptionsCommentIconSize", "timerOptionsDurationIcon", "timerOptionsDurationIconEnabled", "timerOptionsDurationIconSize", "timerOptionsRefreshIcon", "timerOptionsRefreshIconEnabled", "timerOptionsRefreshIconSize", "timerOptionsPauseIcon", "timerOptionsPauseIconEnabled", "timerOptionsPauseIconSize", "timerOptionsColorIcon", "timerOptionsColorIconEnabled", "timerOptionsColorIconSize", "timerOptionsActionIconOrder", "timerRandomColorMode", "timerRandomColorMin", "timerRandomColorMax", "timerFinishedImageEnabled", "timerFinishedImagePath", "timerFinishedBorderUsesTimerColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBackgroundColor", "timerFinishedImageWidth", "timerFinishedImageMargin", "timerFinishedTitleUsesTimerColor", "timerFinishedTitleColor", "timerFinishedTitleFontSize", "timerFinishedTitleFont", "timerFinishedTitleAlignment", "timerRowTopMargin", "timerRowRightMargin", "timerButtonFadeDuration", "timerButtonSlideDuration", "timerButtonIconFadeDuration", "timerMinHeight"])
    if (profile.timerOptionsActionIconOrder === undefined)
        config.timerOptionsActionIconOrder = ["comment", "duration", "refresh", "toggle_pause", "color"]
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
    applyConfigKeysFromProfile(owner, config, profile, ["playerSilenceText", "playerFont", "playerMetaFont", "playerSilenceFontSize", "playerTextOutlineEnabled", "playerTextOutlineColor", "playerSilenceLongFontSize", "playerMetaFontSize", "playerMetaSecondaryFontSize", "playerMetaLineSpacing", "playerBoldArtist", "playerShowProgress", "playerPlayingIconSize", "playerPausedIconSize", "playerNextIconSize", "playerPlayingIconY", "playerPausedIconY", "playerNextIconY", "playerPlayingIcon", "playerPausedIcon", "playerNextIcon", "playerMetadataXPadding", "playerMetadataY", "playerProgressY", "playerProgressTrackHeight", "playerControlTopMargin", "playerControlGap", "playerTimeFontSize", "playerTimeFont", "playerTimeY", "playerTimeRightPadding", "playerCoverOpacity", "playerSilenceWidth", "playerProgressTrackOffsetY", "playerPriority", "playerUpdateInterval", "animationPlayerMorphEnabled", "animationPlayerMorphDuration", "animationPlayerMorphProfile"]); owner.save()
}

function resetMopidySettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["animationMopidyVisibilityStyle", "animationMopidyMorphEnabled", "animationMopidyMorphDuration", "animationMopidyMorphProfile", "mopidyShowTrackNumbers", "mopidyTopIconOrder", "mopidyMoveUpIcon", "mopidyMoveUpIconSize", "mopidyMoveUpIconX", "mopidyMoveUpIconY", "mopidyShowMoveUpIcon", "mopidyMoveDownIcon", "mopidyMoveDownIconSize", "mopidyMoveDownIconX", "mopidyMoveDownIconY", "mopidyShowMoveDownIcon", "mopidyGroupAlbums", "mopidyBrowseCoverMode", "mopidyBrowseCoverKeepSelectedVisible", "mopidyAlbumFont", "mopidyAlbumFontSize", "mopidyAlbumBold", "mopidyTrackFont", "mopidyTrackFontSize", "mopidyTrackRowHeight", "mopidyArtistFont", "mopidyArtistFontSize", "mopidyArtistBold", "mopidyArtistItalic", "mopidyTrackArtistDisplayMode", "mopidyTrackArtistGap", "mopidyTrackArtistSeparator", "mopidyDurationFont", "mopidyDurationFontSize", "mopidyAlbumSeparator", "mopidyBackground", "mopidyToggleWithPlayerRightClick", "mopidyHideTopPanel", "mopidyTopPanelHoverHeight", "mopidyTopPanelOffsetY", "mopidyTopPanelBackground", "mopidyHoverMode", "mopidyHoverColor", "mopidyStopIcon", "mopidyStopIconSize", "mopidyStopIconX", "mopidyStopIconY", "mopidyRefreshIcon", "mopidyRefreshIconSize", "mopidyRefreshIconX", "mopidyRefreshIconY", "mopidyClearIcon", "mopidyClearIconSize", "mopidyClearIconX", "mopidyClearIconY", "mopidyControlIconColor", "mopidyShowStopIcon", "mopidyShowRefreshIcon", "mopidyShowClearIcon", "mopidyShowQueueTotalDuration", "mopidyQueueDurationMode", "mopidyQueueDurationFont", "mopidyQueueDurationFontSize", "mopidyQueueDurationColor", "mopidyQueueDurationX", "mopidyQueueDurationY", "mopidyQueueDurationAlignment", "mopidyShowAlbumRemaining", "mopidyShowTrackRemaining", "mopidyShuffleIcon", "mopidyShuffleIconSize", "mopidyShuffleIconX", "mopidyShuffleIconY", "mopidyShowShuffleIcon", "mopidyRepeatIcon", "mopidyRepeatIconSize", "mopidyRepeatIconX", "mopidyRepeatIconY", "mopidyShowRepeatIcon", "mopidyOpenAddIcon", "mopidyOpenAddIconSize", "mopidyOpenAddIconX", "mopidyOpenAddIconY", "mopidyShowOpenAddIcon", "mopidyAddIcon", "mopidyAddIconSize", "mopidyAddIconX", "mopidyAddIconY", "mopidyShowAddIcon", "mopidySwitchPlaylistIcon", "mopidySwitchPlaylistIconSize", "mopidySwitchPlaylistIconX", "mopidySwitchPlaylistIconY", "mopidyShowSwitchPlaylistIcon", "mopidyPlaylistDeleteIcon", "mopidyPlaylistDeleteIconSize", "mopidyPlaylistDeleteIconX", "mopidyPlaylistDeleteIconY", "mopidyShowPlaylistDeleteIcon", "mopidyVolumeIcon", "mopidyMutedIcon", "mopidyVolumeIconSize", "mopidyVolumeIconX", "mopidyVolumeIconY", "mopidyMutedIconSize", "mopidyMutedIconX", "mopidyMutedIconY", "mopidyShowVolumeIcon", "mopidyShowVolumePercent", "mopidyVolumeStep", "mopidyEmptyQueueText", "mopidyUnavailableText", "mopidyStatusFont", "mopidyStatusFontSize", "mopidyStatusLongFontSize", "mopidyStatusWidth"]); owner.save()
}

function resetWeatherSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["animationWeatherMorphEnabled", "animationWeatherMorphDuration", "animationWeatherHourlyDuration", "animationWeatherMorphProfile", "weatherFont", "weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes", "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds", "weatherIconSize", "weatherIconX", "weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap", "weatherHourlyCount", "weatherDailyCount", "weatherIconY", "weatherWindColumnX", "weatherWindColumnY", "weatherPressureX", "weatherDescriptionX", "weatherDescriptionWidth", "weatherMiddleBlockWidth", "weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment", "weatherIconPlacement", "weatherWindSpeedFontSize", "weatherWindUnitFontSize", "weatherPressureY", "weatherDescriptionY", "weatherDescriptionFontSize", "weatherTempFontSize", "weatherComfortFontSize", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherShowComfort", "weatherTempColumnWidth", "weatherTempX", "weatherTempWidth", "weatherTempOffsetX", "weatherTempOffsetY", "weatherComfortY", "weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortHeight", "weatherWindColumnWidth", "weatherWindArrowWidth", "weatherWindIcon", "weatherWindCalmIcon", "weatherWindCalmFont", "weatherWindNIcon", "weatherWindNFont", "weatherWindNEIcon", "weatherWindNEFont", "weatherWindEIcon", "weatherWindEFont", "weatherWindSEIcon", "weatherWindSEFont", "weatherWindSIcon", "weatherWindSFont", "weatherWindSWIcon", "weatherWindSWFont", "weatherWindWIcon", "weatherWindWFont", "weatherWindNWIcon", "weatherWindNWFont", "weatherWindArrowHeight", "weatherWindSpeedX", "weatherWindSpeedY", "weatherWindSpeedWidth", "weatherWindUnitX", "weatherWindUnitY", "weatherWindUnitWidth", "weatherPressureValueWidth", "weatherPressureFontSize", "weatherPressureUnitX", "weatherPressureUnitY", "weatherPressureUnitFontSize", "weatherDescriptionHeight", "weatherHourlyTopPadding", "weatherHourlyDayY", "weatherHourlyDayFontSize", "weatherHourlyIconWidth", "weatherHourlyIconY", "weatherHourlyTempY", "weatherHourlyTempHeight", "weatherHourlyTempFontSize", "weatherDailyTopPadding", "weatherDailyDayY", "weatherDailyDayFontSize", "weatherDailyIconWidth", "weatherDailyIconY", "weatherDailyHighTempX", "weatherDailyHighTempY", "weatherDailyHighTempFontSize", "weatherDailyLowTempX", "weatherDailyLowTempY", "weatherDailyLowTempFontSize"]);
    if (profile.weatherToken !== undefined) owner.weatherToken = String(profile.weatherToken)
    owner.save()
}

function resetCalendarSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["calendarPreviousIcon", "calendarNextIcon", "calendarPreviousSize", "calendarNextSize", "calendarArrowY", "calendarPreviousX", "calendarNextX", "calendarTitleFontSize", "calendarTitleY", "calendarTitleFont", "calendarWeekdayFontSize", "calendarWeekdayY", "calendarWeekdayFont", "calendarDayFontSize", "calendarDayY", "calendarDayFont", "calendarNoteMarkerStyle", "calendarNoteMarkerPosition", "calendarNoteFrameColor", "calendarAdjacentDaysColor", "calendarWeekendColor", "calendarPastDaysColorEnabled", "calendarPastDaysColor", "animationCalendarVisibilityStyle", "animationCalendarSlideDuration", "animationCalendarFadeDuration", "animationCalendarMorphDuration", "animationCalendarMorphProfile"]); owner.save()
}

function resetCavaSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["cavaBars", "cavaFramerate", "cavaRowSpacing", "cavaBarWidthRatio", "cavaMode", "cavaHideWhenSilent", "cavaHideZeroBars", "animationCavaMorphDuration", "animationCavaMorphProfile"]); owner.save()
}

function resetClockSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["clockFont", "clockFontSize", "clockDateFontSize", "clockWeekdayFont", "clockWeekdayFontSize"])
    owner.save()
}

function resetGeneralSettings(owner, config) {
    var profile = activeProfileData(owner); if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["font", "fontSize", "ledFont", "frameBorderWidth", "frameRadius", "backgroundBlurRadius"]); owner.save()
}

function resetSettingsWindow(owner, config) {
    resetSettingsWindowFromProfile(owner, config)
}

function resetNotificationTimeoutIndicatorDefaults(owner, config, profile) {
    var defaults = owner && owner.defaultConfig ? owner.defaultConfig : ({})
    if (!profile || profile.notificationsTimeoutIndicatorColor === undefined)
        config.notificationsTimeoutIndicatorColor = defaults.notificationsTimeoutIndicatorColor !== undefined
            ? defaults.notificationsTimeoutIndicatorColor : ""
    if (!profile || profile.notificationsTimeoutIndicatorStyle === undefined)
        config.notificationsTimeoutIndicatorStyle = defaults.notificationsTimeoutIndicatorStyle !== undefined
            ? defaults.notificationsTimeoutIndicatorStyle : "bar"
    if (!profile || profile.notificationsTimeoutIndicatorDirection === undefined)
        config.notificationsTimeoutIndicatorDirection = defaults.notificationsTimeoutIndicatorDirection !== undefined
            ? defaults.notificationsTimeoutIndicatorDirection : "clockwise"
}

function resetNotificationsSettings(owner, config) {
    var profile = activeProfileData(owner)
    if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, [
        "notificationsDefaultTimeout", "notificationsCriticalTimeout", "notificationsShowTimeoutIndicator", "notificationsTimeoutIndicatorColor", "notificationsTimeoutIndicatorStyle", "notificationsTimeoutIndicatorDirection", "notificationsVerticalAnchor", "notificationsCardSpacing",
        "notificationsImageHeight", "notificationsBackgroundColor", "notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold", "notificationsLeadingVisualSize", "notificationsLeadingVisualRadius", "notificationsCardPadding", "notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor", "notificationsShowAppIcon", "notificationsShowBodyImages",
        "notificationsShowProgress", "animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle"
    ])
    resetNotificationTimeoutIndicatorDefaults(owner, config, profile)
    owner.save()
}

function resetDashboardModule(owner, config) {
    // Restore the common module placement/surface controls and the Dashboard-
    // specific card composition from the same active profile.
    resetModule(owner, config, "dashboard")
    resetDashboardSettings(owner, config, true)
}

function resetDashboardSettings(owner, config, includeModule) {
    var profile = activeProfileData(owner)
    if (!profile) return
    // Keep the raw profile order for legacy detection: an absent order means
    // the profile predates Today, even though the normalized reset value will
    // use the current five-card default below.
    if (includeModule) {
        var profileModules = profile.modules || {}
        owner.dashboard = profileModules.dashboard !== undefined
            ? !!profileModules.dashboard : !!(owner.defaultModules || {}).dashboard
    }
    var profileCardOrder = profile.dashboardCardOrder
    config.dashboardVisibleCards = normalizeDashboardCards(
        profile.dashboardVisibleCards === undefined ? owner.defaultConfig.dashboardVisibleCards : profile.dashboardVisibleCards,
        profileCardOrder
    )
    config.dashboardCardOrder = normalizeDashboardCardOrder(
        profile.dashboardCardOrder === undefined ? owner.defaultConfig.dashboardCardOrder : profile.dashboardCardOrder
    )
    config.dashboardColumnsMode = normalizeDashboardColumnsMode(
        profile.dashboardColumnsMode === undefined ? owner.defaultConfig.dashboardColumnsMode : profile.dashboardColumnsMode
    )
    config.dashboardCardSizes = normalizeDashboardCardSizes(
        profile.dashboardCardSizes === undefined ? owner.defaultConfig.dashboardCardSizes : profile.dashboardCardSizes
    )
    applyConfigKeysFromProfile(owner, config, profile, ["animationDashboardVisibilityStyle", "animationDashboardVisibilityDuration"])
    if (profile.animationDashboardVisibilityStyle === undefined)
        config.animationDashboardVisibilityStyle = owner.defaultConfig.animationDashboardVisibilityStyle !== undefined
            ? owner.defaultConfig.animationDashboardVisibilityStyle : "auto"
    if (profile.animationDashboardVisibilityDuration === undefined)
        config.animationDashboardVisibilityDuration = owner.defaultConfig.animationDashboardVisibilityDuration !== undefined
            ? Number(owner.defaultConfig.animationDashboardVisibilityDuration) : 300
    owner.save()
}

function resetLauncherSettings(owner, config) {
    var profile = activeProfileData(owner)
    if (!profile) return
    applyConfigKeysFromProfile(owner, config, profile, ["launcherEnabled", "launcherWidth", "launcherHeight", "launcherItemHeight", "launcherItemRadius", "launcherRadius", "launcherBackdropOpacity", "launcherBackground", "launcherTitleText", "launcherTitleFont", "launcherTitleFontSize", "launcherTitleY", "launcherTitleColor", "launcherTitleLetterSpacing", "launcherTitleBold", "launcherSearchFont", "launcherSearchFontSize", "launcherSearchHeight", "launcherSearchRadius", "launcherSearchBackground", "launcherSearchPlaceholder", "launcherDefaultMode", "launcherShowResultCount", "launcherVimKeybinds", "launcherShowNavigationHints", "launcherNavigationHintsHeight", "launcherNavigationHintsFontSize", "launcherNavigationHintsTextY", "launcherFuzzySearchApps", "launcherFuzzySearchActions", "launcherFuzzySearchSchemes", "launcherFuzzySearchWallpapers", "launcherDynamicSchemeVariant", "launcherWallpaperDirectory", "launcherCrossSearchProjects", "launcherCrossSearchRunHistory", "launcherCrossSearchCalculator", "launcherTabOrder", "launcherTabVisible", "launcherTabLabels", "launcherTabIcons", "launcherDisabledBuiltinActions", "launcherProjects", "launcherCustomActions", "launcherFavoriteApps", "launcherHiddenApps", "animationLauncherMorphDuration", "animationLauncherMorphProfile"])
    // Older profiles predate calculator cross-search and editable launcher tabs.
    if (profile.launcherCrossSearchCalculator === undefined) config.launcherCrossSearchCalculator = true
    if (profile.launcherVimKeybinds === undefined) config.launcherVimKeybinds = false
    if (profile.launcherShowNavigationHints === undefined) config.launcherShowNavigationHints = true
    var hintHeight = profile.launcherNavigationHintsHeight === undefined
        ? 24 : Number(config.launcherNavigationHintsHeight)
    config.launcherNavigationHintsHeight = isFinite(hintHeight) ? Math.max(0, Math.min(48, Math.round(hintHeight))) : 24
    var hintFontSize = profile.launcherNavigationHintsFontSize === undefined
        ? 11 : Number(config.launcherNavigationHintsFontSize)
    config.launcherNavigationHintsFontSize = isFinite(hintFontSize) ? Math.max(8, Math.min(18, Math.round(hintFontSize))) : 11
    var hintTextY = profile.launcherNavigationHintsTextY === undefined
        ? 0 : Number(config.launcherNavigationHintsTextY)
    config.launcherNavigationHintsTextY = isFinite(hintTextY) ? Math.max(-48, Math.min(48, Math.round(hintTextY))) : 0
    if (profile.launcherFuzzySearchApps === undefined) config.launcherFuzzySearchApps = true
    if (profile.launcherFuzzySearchActions === undefined) config.launcherFuzzySearchActions = true
    if (profile.launcherFuzzySearchSchemes === undefined) config.launcherFuzzySearchSchemes = true
    if (profile.launcherFuzzySearchWallpapers === undefined) config.launcherFuzzySearchWallpapers = true
    if (profile.launcherDynamicSchemeVariant === undefined) config.launcherDynamicSchemeVariant = "scheme-tonal-spot"
    else config.launcherDynamicSchemeVariant = normalizeLauncherDynamicSchemeVariant(profile.launcherDynamicSchemeVariant)
    if (profile.launcherWallpaperDirectory === undefined) config.launcherWallpaperDirectory = ""
    if (profile.launcherTabLabels === undefined) config.launcherTabLabels = ["Apps", "Run", "Windows", "Clipboard", "Power", "Network", "Packages", "Pass", "Projects", "Calculator"]
    if (profile.launcherTabIcons === undefined) config.launcherTabIcons = ["󰀻", "", "󰖯", "󰅇", "", "󰖩", "󱄅", "󰌋", "", "󰃬"]
    config.launcherDisabledBuiltinActions = Array.isArray(profile.launcherDisabledBuiltinActions)
        ? profile.launcherDisabledBuiltinActions.slice() : []
    if (profile.launcherCustomActions === undefined) config.launcherCustomActions = []
    if (profile.launcherFavoriteApps === undefined) config.launcherFavoriteApps = []
    if (profile.launcherHiddenApps === undefined) config.launcherHiddenApps = []
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
