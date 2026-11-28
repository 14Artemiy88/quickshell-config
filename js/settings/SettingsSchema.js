.pragma library

// Keep old settings readable while new snapshots contain only canonical fields.

// Persisted catalogs are keyed by user-controlled names. Define dynamic keys as
// data properties so legacy names such as "__proto__" never mutate prototypes
// or disappear during startup normalization.
function setOwn(object, key, value) {
    Object.defineProperty(object, String(key), {
        value: value, enumerable: true, configurable: true, writable: true
    })
}


function normalizeAnimationProfileValue(value) {
    var name = String(value === undefined || value === null ? "" : value).trim().toLowerCase()
    var legacy = {
        standard: "ease-out", spatial: "ease-out", effects: "ease-in",
        expressive: "ease-in-out", expressivespatial: "ease-out", expressiveeffects: "ease-in"
    }
    if (name === "none" || name === "linear" || name === "ease" || name === "ease-in"
            || name === "ease-out" || name === "ease-in-out")
        return name
    if (Object.prototype.hasOwnProperty.call(legacy, name)) return legacy[name]
    var match = name.match(/^cubic-bezier\(\s*([^)]*)\s*\)$/i)
    if (!match) return ""
    var parts = match[1].split(",")
    if (parts.length !== 4) return ""
    var values = []
    for (var i = 0; i < 4; ++i) {
        var number = Number(String(parts[i]).trim())
        if (!isFinite(number)) return ""
        values.push(number)
    }
    if (values[0] < 0 || values[0] > 1 || values[2] < 0 || values[2] > 1) return ""
    var formatted = []
    for (var j = 0; j < 4; ++j) formatted.push(String(Math.round(values[j] * 1000) / 1000))
    return "cubic-bezier(" + formatted.join(", ") + ")"
}

function normalizeSavedColor(value, fallback) {
    if (typeof value === "string") {
        var text = value.trim()
        // Canonicalize persisted colors so semantically identical hex values
        // do not spuriously mark a theme as Changed or prevent palette matching.
        if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(text))
            return text.toLowerCase()
        if (text.toLowerCase() === "transparent")
            return "transparent"
        return fallback
    }
    if (value && typeof value === "object" && value.valid === true) {
        var channels = [value.a, value.r, value.g, value.b]
        for (var i = 0; i < channels.length; ++i) {
            if (typeof channels[i] !== "number" || !isFinite(channels[i])) return fallback
        }
        function hexByte(component) {
            var n = Math.max(0, Math.min(255, Math.round(component * 255)))
            return (n < 16 ? "0" : "") + n.toString(16)
        }
        return "#" + hexByte(value.a) + hexByte(value.r) + hexByte(value.g) + hexByte(value.b)
    }
    return fallback
}

// Normalize persisted custom theme palettes. Older JSON snapshots may contain
// QColor objects, and palettes created before newer color controls existed may
// omit keys that current widgets consume. Convert known colors to canonical
// ARGB/RGB strings, fill newly introduced keys from the current default theme,
// and retain any extra valid color keys for forward compatibility.
function normalizeCustomThemes(customThemes, fallbackPalette) {
    var result = {}
    if (!customThemes || typeof customThemes !== "object" || Array.isArray(customThemes))
        return result

    var fallback = fallbackPalette && typeof fallbackPalette === "object" ? fallbackPalette : {}
    for (var themeName in customThemes) {
        if (!Object.prototype.hasOwnProperty.call(customThemes, themeName)) continue
        var savedPalette = customThemes[themeName]
        if (!savedPalette || typeof savedPalette !== "object" || Array.isArray(savedPalette)) continue

        var normalized = {}
        for (var fallbackKey in fallback) {
            if (!Object.prototype.hasOwnProperty.call(fallback, fallbackKey)) continue
            var fallbackColor = normalizeSavedColor(fallback[fallbackKey], "#ffffff")
            // Older custom palettes predate the individual Top Apps bar colors.
            // Preserve their original accent/RAM identity instead of injecting
            // the built-in theme's colors into an otherwise custom palette.
            if (savedPalette[fallbackKey] === undefined) {
                if (/^cpu[1-8]Track$/.test(fallbackKey) && savedPalette.metricTrack !== undefined)
                    fallbackColor = normalizeSavedColor(savedPalette.metricTrack, fallbackColor)
                else if (fallbackKey === "topAppsCpuBarColor" && savedPalette.accent !== undefined)
                    fallbackColor = normalizeSavedColor(savedPalette.accent, fallbackColor)
                else if (fallbackKey === "topAppsRamBarColor" && savedPalette.ram !== undefined)
                    fallbackColor = normalizeSavedColor(savedPalette.ram, fallbackColor)
                else if ((fallbackKey === "topAppsCpuBarTrackColor" || fallbackKey === "topAppsRamBarTrackColor")
                        && (savedPalette.topAppsBarTrackColor !== undefined || savedPalette.metricTrack !== undefined))
                    fallbackColor = normalizeSavedColor(savedPalette.topAppsBarTrackColor !== undefined ? savedPalette.topAppsBarTrackColor : savedPalette.metricTrack, fallbackColor)
            }
            setOwn(normalized, fallbackKey, normalizeSavedColor(savedPalette[fallbackKey], fallbackColor))
        }
        for (var savedKey in savedPalette) {
            if (!Object.prototype.hasOwnProperty.call(savedPalette, savedKey) || normalized[savedKey] !== undefined) continue
            var extraColor = normalizeSavedColor(savedPalette[savedKey], null)
            if (extraColor !== null) setOwn(normalized, savedKey, extraColor)
        }
        setOwn(result, String(themeName), normalized)
    }
    return result
}

function migrateLegacyTopAppsMap(source) {
    if (!source || typeof source !== "object") return source
    var result = source
    if (result.topApps !== undefined) {
        if (result.topAppsCpu === undefined) result.topAppsCpu = result.topApps
        if (result.topAppsRam === undefined) result.topAppsRam = result.topApps
        delete result.topApps
    }
    return result
}

function splitLegacyTopAppsGeometry(geometry) {
    var x = Number(geometry[0]) || 0
    var y = Number(geometry[1]) || 0
    var width = Math.max(1, Number(geometry[2]) || 315)
    var totalHeight = Math.max(7, Number(geometry[3]) || 198)
    var gap = 5
    var sectionHeight = Math.max(1, Math.floor((totalHeight - gap) / 2))
    return [[x, y, width, sectionHeight], [x, y + sectionHeight + gap, width, sectionHeight]]
}

function normalizeProfileScale(p, key, isSparse) {
    if (p[key] === undefined || p[key] === null || !isFinite(Number(p[key]))) {
        if (isSparse) delete p[key]
        else p[key] = 100
        return
    }
    p[key] = Math.max(75, Math.min(150, Math.round(Number(p[key]))))
}

function normalizeProfileCornerScale(p, isSparse) {
    if (p.cornerRadiusScale === undefined || p.cornerRadiusScale === null || !isFinite(Number(p.cornerRadiusScale))) {
        if (isSparse) delete p.cornerRadiusScale
        else p.cornerRadiusScale = 100
        return
    }
    p.cornerRadiusScale = Math.max(50, Math.min(150, Math.round(Number(p.cornerRadiusScale))))
}

function normalizeProfileBorderToggle(p, key, isSparse) {
    if (p[key] === undefined || p[key] === null) {
        if (isSparse) delete p[key]
        else p[key] = true
        return
    }
    p[key] = p[key] !== false
}

function normalizeProfile(profile, isSparse) {
    if (!profile || typeof profile !== "object" || Array.isArray(profile)) return null
    var p = JSON.parse(JSON.stringify(profile))

    // New global scales must not leak from the previously active profile when
    // loading an older full snapshot. Sparse profiles omit absent keys and
    // inherit the active profile baseline instead.
    normalizeProfileScale(p, "uiScale", !!isSparse)
    normalizeProfileScale(p, "fontScale", !!isSparse)
    normalizeProfileScale(p, "settingsUiScale", !!isSparse)
    normalizeProfileScale(p, "settingsFontScale", !!isSparse)
    normalizeProfileCornerScale(p, !!isSparse)
    normalizeProfileBorderToggle(p, "buttonBordersEnabled", !!isSparse)
    normalizeProfileBorderToggle(p, "inputBordersEnabled", !!isSparse)
    normalizeProfileBorderToggle(p, "popupBordersEnabled", !!isSparse)
    normalizeProfileBorderToggle(p, "cardBordersEnabled", !!isSparse)

    p.modules = migrateLegacyTopAppsMap(p.modules)
    p.moduleFrames = migrateLegacyTopAppsMap(p.moduleFrames)
    p.moduleBackgrounds = migrateLegacyTopAppsMap(p.moduleBackgrounds)
    p.moduleMonitors = migrateLegacyTopAppsMap(p.moduleMonitors)
    if (p.geometry && p.geometry.topApps && p.geometry.topApps.length === 4) {
        var splitTopApps = splitLegacyTopAppsGeometry(p.geometry.topApps)
        if (!p.geometry.topAppsCpu) p.geometry.topAppsCpu = splitTopApps[0]
        if (!p.geometry.topAppsRam) p.geometry.topAppsRam = splitTopApps[1]
        delete p.geometry.topApps
    }

    // Timer preset arrays were previously saved as `timerPresets`. Convert
    // the profile field before completing legacy snapshots with new defaults,
    // otherwise the newly added `timerPresetDefaults` array masks user values.
    var presetSource = Array.isArray(p.timerPresetDefaults) ? p.timerPresetDefaults : p.timerPresets
    if (Array.isArray(presetSource)) {
        var normalizedPresets = []
        for (var presetIndex = 0; presetIndex < presetSource.length; ++presetIndex) {
            var presetValue = Number(presetSource[presetIndex])
            if (isFinite(presetValue)) normalizedPresets.push(Math.max(0, Math.round(presetValue)))
        }
        p.timerPresetDefaults = normalizedPresets
    }
    delete p.timerPresets

    // Older full profiles had timer-left positions and no explicit icon-order
    // field. Match the root-settings migration before default completion adds
    // the modern `alarm-left` value and suppresses the legacy position swap.
    if (!isSparse && p.timerIconOrder === undefined) {
        var legacyTimerX = Number(p.timerIconX)
        var legacyAlarmX = Number(p.timerAlarmIconX)
        if (p.timerIconX !== undefined && p.timerAlarmIconX !== undefined
                && isFinite(legacyTimerX) && isFinite(legacyAlarmX)) {
            p.timerIconX = legacyAlarmX
            p.timerAlarmIconX = legacyTimerX
        }
        p.timerIconOrder = "alarm-left"
    }

    // v408 moved the untouched default Mopidy surface downward to prevent
    // overlap with Networks. Legacy full profiles need the same one-time
    // migration as the root geometry; sparse profiles may contain intentional
    // user-selected coordinates and therefore remain unchanged.
    if (!isSparse && p.geometry && p.geometry.mopidy && p.geometry.mopidy.length === 4
            && Number(p.geometry.mopidy[0]) === 330
            && Number(p.geometry.mopidy[1]) === 730
            && Number(p.geometry.mopidy[2]) === 300
            && Number(p.geometry.mopidy[3]) === 150) {
        p.geometry.mopidy = [330, 865, 300, 150]
    }

    // Migrate old separate finished-image margins to the current shared field.
    if (p.timerFinishedImageMargin === undefined) {
        var oldMargin = p.timerFinishedImageTopMargin !== undefined
            ? Number(p.timerFinishedImageTopMargin)
            : (p.timerFinishedImageBottomMargin !== undefined ? Number(p.timerFinishedImageBottomMargin) : NaN)
        if (isFinite(oldMargin)) p.timerFinishedImageMargin = Math.max(0, Math.min(100, Math.round(oldMargin)))
    }
    delete p.timerFinishedImageTopMargin
    delete p.timerFinishedImageBottomMargin

    // Migrate the old one-size-fits-all Player icon size only by dropping it;
    // current Player controls have independent size settings.
    delete p.playerControlIconSize

    // Migrate the former shared Mopidy move-button switch when split values are absent.
    if (p.mopidyShowMoveUpIcon === undefined && p.mopidyShowMoveDownIcon === undefined && p.mopidyShowMoveButtons !== undefined) {
        p.mopidyShowMoveUpIcon = !!p.mopidyShowMoveButtons
        p.mopidyShowMoveDownIcon = !!p.mopidyShowMoveButtons
    }
    delete p.mopidyShowMoveButtons

    // Volume's previous "none" style becomes the shared "none" animation profile.
    // Keep the visual direction as fade so the style selector only represents fade/slide.
    var legacyVolumeAnimationStyle = p.animationVolumeStreamsVisibilityStyle !== undefined
        ? String(p.animationVolumeStreamsVisibilityStyle) : ""
    if (p.animationVolumeMorphProfile === undefined && legacyVolumeAnimationStyle === "none")
        p.animationVolumeMorphProfile = "none"
    if (legacyVolumeAnimationStyle === "none")
        p.animationVolumeStreamsVisibilityStyle = "fade"

    if (p.notificationsDoNotDisturb !== undefined) {
        if (typeof p.notificationsDoNotDisturb === "boolean") p.notificationsDoNotDisturb = p.notificationsDoNotDisturb
        else if (isSparse) delete p.notificationsDoNotDisturb
        else p.notificationsDoNotDisturb = false
    } else if (!isSparse) {
        p.notificationsDoNotDisturb = false
    }

    if (p.osdIntegrateWithNotifications !== undefined) {
        if (typeof p.osdIntegrateWithNotifications === "boolean") p.osdIntegrateWithNotifications = p.osdIntegrateWithNotifications
        else if (isSparse) delete p.osdIntegrateWithNotifications
        else p.osdIntegrateWithNotifications = false
    } else if (!isSparse) {
        p.osdIntegrateWithNotifications = false
    }

    if (p.notificationsDndOsdEnabled !== undefined) {
        if (typeof p.notificationsDndOsdEnabled === "boolean") p.notificationsDndOsdEnabled = p.notificationsDndOsdEnabled
        else if (isSparse) delete p.notificationsDndOsdEnabled
        else p.notificationsDndOsdEnabled = true
    } else if (!isSparse) {
        p.notificationsDndOsdEnabled = true
    }

    if (p.notificationsDndOsdHideDelay !== undefined) {
        var notificationsDndOsdHideDelay = Number(p.notificationsDndOsdHideDelay)
        if (isFinite(notificationsDndOsdHideDelay)) p.notificationsDndOsdHideDelay = Math.max(500, Math.min(10000, Math.round(notificationsDndOsdHideDelay)))
        else if (isSparse) delete p.notificationsDndOsdHideDelay
        else p.notificationsDndOsdHideDelay = 1800
    } else if (!isSparse) {
        p.notificationsDndOsdHideDelay = 1800
    }

    if (p.notificationsDndOsdAnimationDuration !== undefined) {
        var notificationsDndOsdAnimationDuration = Number(p.notificationsDndOsdAnimationDuration)
        if (isFinite(notificationsDndOsdAnimationDuration)) p.notificationsDndOsdAnimationDuration = Math.max(0, Math.min(1500, Math.round(notificationsDndOsdAnimationDuration)))
        else if (isSparse) delete p.notificationsDndOsdAnimationDuration
        else p.notificationsDndOsdAnimationDuration = 180
    } else if (!isSparse) {
        p.notificationsDndOsdAnimationDuration = 180
    }

    if (p.animationNotificationsDndOsdMorphProfile === undefined && !isSparse)
        p.animationNotificationsDndOsdMorphProfile = "ease-in-out"

    // Module entrance curves are independent of each module's internal morph
    // curve. Older full profiles did not store these fields, so give them the
    // current default instead of leaking the previous profile's active value.
    // Sparse profiles deliberately omit absent keys and inherit their baseline.
    var visibilityAnimationProfileKeys = [
        "animationDashboardVisibilityProfile", "animationCalendarVisibilityProfile",
        "animationMopidyVisibilityProfile", "animationNetworkVisibilityProfile",
        "animationTimerVisibilityProfile", "animationTimerOptionsVisibilityProfile",
        "animationSettingsVisibilityProfile", "animationVolumeStreamsVisibilityProfile",
        "animationNotificationsVisibilityProfile"
    ]
    for (var visibilityIndex = 0; visibilityIndex < visibilityAnimationProfileKeys.length; ++visibilityIndex) {
        var visibilityKey = visibilityAnimationProfileKeys[visibilityIndex]
        if (p[visibilityKey] === undefined || p[visibilityKey] === null) {
            if (isSparse) delete p[visibilityKey]
            else p[visibilityKey] = "ease-out"
        } else {
            var normalizedVisibility = normalizeAnimationProfileValue(p[visibilityKey])
            if (normalizedVisibility !== "") p[visibilityKey] = normalizedVisibility
            else if (isSparse) delete p[visibilityKey]
            else p[visibilityKey] = "ease-out"
        }
    }

    // Normalize all saved easing fields before the profile is restored.
    var animationProfileKeys = [
        "animationNotificationsDndOsdMorphProfile", "animationNotificationsMorphProfile",
        "animationMopidyMorphProfile", "animationPlayerMorphProfile",
        "animationWeatherMorphProfile", "animationTimerMorphProfile",
        "animationNetworkMorphProfile", "animationCavaMorphProfile",
        "animationCalendarMorphProfile", "animationCpuMorphProfile",
        "animationLauncherMorphProfile", "animationVolumeMorphProfile",
        "animationVolumeOsdMorphProfile", "animationPlayerOsdMorphProfile",
        "animationDashboardVisibilityProfile", "animationCalendarVisibilityProfile",
        "animationMopidyVisibilityProfile", "animationNetworkVisibilityProfile",
        "animationTimerVisibilityProfile", "animationTimerOptionsVisibilityProfile",
        "animationSettingsVisibilityProfile", "animationVolumeStreamsVisibilityProfile",
        "animationNotificationsVisibilityProfile"
    ]
    for (var animationIndex = 0; animationIndex < animationProfileKeys.length; ++animationIndex) {
        var animationKey = animationProfileKeys[animationIndex]
        if (p[animationKey] === undefined) continue
        var normalizedAnimation = normalizeAnimationProfileValue(p[animationKey])
        if (normalizedAnimation !== "") p[animationKey] = normalizedAnimation
        else if (isSparse) delete p[animationKey]
        else p[animationKey] = "ease-in-out"
    }

    if (p.notificationsDndAllowedApps !== undefined) {
        if (typeof p.notificationsDndAllowedApps === "string") p.notificationsDndAllowedApps = p.notificationsDndAllowedApps.slice(0, 4096)
        else if (isSparse) delete p.notificationsDndAllowedApps
        else p.notificationsDndAllowedApps = ""
    } else if (!isSparse) {
        p.notificationsDndAllowedApps = ""
    }

    if (p.notificationsDndBlockedApps !== undefined) {
        if (typeof p.notificationsDndBlockedApps === "string") p.notificationsDndBlockedApps = p.notificationsDndBlockedApps.slice(0, 4096)
        else if (isSparse) delete p.notificationsDndBlockedApps
        else p.notificationsDndBlockedApps = ""
    } else if (!isSparse) {
        p.notificationsDndBlockedApps = ""
    }

    if (p.notificationsHistoryIgnoredApps !== undefined) {
        if (typeof p.notificationsHistoryIgnoredApps === "string") p.notificationsHistoryIgnoredApps = p.notificationsHistoryIgnoredApps.slice(0, 4096)
        else if (isSparse) delete p.notificationsHistoryIgnoredApps
        else p.notificationsHistoryIgnoredApps = ""
    } else if (!isSparse) {
        p.notificationsHistoryIgnoredApps = ""
    }

    if (p.notificationsHistoryLimit !== undefined) {
        var notificationHistoryLimit = Number(p.notificationsHistoryLimit)
        if (isFinite(notificationHistoryLimit)) p.notificationsHistoryLimit = Math.max(1, Math.min(200, Math.round(notificationHistoryLimit)))
        else if (isSparse) delete p.notificationsHistoryLimit
        else p.notificationsHistoryLimit = 30
    } else if (!isSparse) {
        p.notificationsHistoryLimit = 30
    }

    if (p.notificationsHistoryRetentionDays !== undefined) {
        var notificationHistoryRetentionDays = Number(p.notificationsHistoryRetentionDays)
        if (isFinite(notificationHistoryRetentionDays)) p.notificationsHistoryRetentionDays = Math.max(0, Math.min(365, Math.round(notificationHistoryRetentionDays)))
        else if (isSparse) delete p.notificationsHistoryRetentionDays
        else p.notificationsHistoryRetentionDays = 0
    } else if (!isSparse) {
        p.notificationsHistoryRetentionDays = 0
    }

    if (p.notificationsTimeoutIndicatorDirection !== undefined) {
        var timeoutIndicatorDirection = String(p.notificationsTimeoutIndicatorDirection)
        if (timeoutIndicatorDirection === "clockwise" || timeoutIndicatorDirection === "counterclockwise")
            p.notificationsTimeoutIndicatorDirection = timeoutIndicatorDirection
        else if (isSparse)
            delete p.notificationsTimeoutIndicatorDirection
        else
            p.notificationsTimeoutIndicatorDirection = "clockwise"
    } else if (!isSparse) {
        // Legacy profiles predate the direction control; preserve the original clockwise path.
        p.notificationsTimeoutIndicatorDirection = "clockwise"
    }

    if (p.notificationsBackgroundColor !== undefined)
        p.notificationsBackgroundColor = normalizeSavedColor(p.notificationsBackgroundColor, "#4d000000")
    else if (!isSparse)
        p.notificationsBackgroundColor = "#4d000000"

    if (p.notificationsSummaryFont !== undefined) {
        if (typeof p.notificationsSummaryFont === "string")
            p.notificationsSummaryFont = p.notificationsSummaryFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128)
        else if (isSparse)
            delete p.notificationsSummaryFont
        else
            p.notificationsSummaryFont = ""
    } else if (!isSparse) {
        p.notificationsSummaryFont = ""
    }
    if (p.notificationsSummaryFontSize !== undefined) {
        var summaryFontSize = Number(p.notificationsSummaryFontSize)
        if (isFinite(summaryFontSize)) p.notificationsSummaryFontSize = Math.max(8, Math.min(32, Math.round(summaryFontSize)))
        else delete p.notificationsSummaryFontSize
    } else if (!isSparse) {
        p.notificationsSummaryFontSize = 14
    }
    if (p.notificationsSummaryColor !== undefined) {
        var rawSummaryColor = typeof p.notificationsSummaryColor === "string" ? p.notificationsSummaryColor.trim() : null
        if (rawSummaryColor === "") p.notificationsSummaryColor = ""
        else {
            var summaryColor = normalizeSavedColor(rawSummaryColor, isSparse ? null : "")
            if (summaryColor === null) delete p.notificationsSummaryColor
            else p.notificationsSummaryColor = summaryColor
        }
    } else if (!isSparse) {
        p.notificationsSummaryColor = ""
    }
    if (p.notificationsAppNameFont !== undefined) {
        if (typeof p.notificationsAppNameFont === "string")
            p.notificationsAppNameFont = p.notificationsAppNameFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128)
        else if (isSparse) delete p.notificationsAppNameFont
        else p.notificationsAppNameFont = ""
    } else if (!isSparse) p.notificationsAppNameFont = ""

    if (p.notificationsAppNameFontSize !== undefined) {
        var appNameFontSize = Number(p.notificationsAppNameFontSize)
        if (isFinite(appNameFontSize)) p.notificationsAppNameFontSize = Math.max(8, Math.min(24, Math.round(appNameFontSize)))
        else delete p.notificationsAppNameFontSize
    } else if (!isSparse) p.notificationsAppNameFontSize = 11

    if (p.notificationsAppNameColor !== undefined) {
        var rawAppNameColor = typeof p.notificationsAppNameColor === "string" ? p.notificationsAppNameColor.trim() : null
        if (rawAppNameColor === "") p.notificationsAppNameColor = ""
        else {
            var appNameColor = normalizeSavedColor(rawAppNameColor, isSparse ? null : "")
            if (appNameColor === null) delete p.notificationsAppNameColor
            else p.notificationsAppNameColor = appNameColor
        }
    } else if (!isSparse) p.notificationsAppNameColor = ""

    if (p.notificationsAppNameBold !== undefined) p.notificationsAppNameBold = !!p.notificationsAppNameBold
    else if (!isSparse) p.notificationsAppNameBold = false

    if (p.notificationsShowAppIconBackground !== undefined) {
        if (typeof p.notificationsShowAppIconBackground !== "boolean") {
            if (isSparse) delete p.notificationsShowAppIconBackground
            else p.notificationsShowAppIconBackground = true
        }
    } else if (!isSparse) p.notificationsShowAppIconBackground = true

    if (p.notificationsLeadingVisualSize !== undefined) {
        var leadingVisualSize = Number(p.notificationsLeadingVisualSize)
        if (isFinite(leadingVisualSize)) p.notificationsLeadingVisualSize = Math.max(24, Math.min(72, Math.round(leadingVisualSize)))
        else delete p.notificationsLeadingVisualSize
    } else if (!isSparse) {
        p.notificationsLeadingVisualSize = 48
    }
    if (p.notificationsLeadingVisualRadius !== undefined) {
        var leadingVisualRadius = Number(p.notificationsLeadingVisualRadius)
        if (isFinite(leadingVisualRadius)) p.notificationsLeadingVisualRadius = Math.max(0, Math.min(36, Math.round(leadingVisualRadius)))
        else delete p.notificationsLeadingVisualRadius
    } else if (!isSparse) p.notificationsLeadingVisualRadius = 10

    if (p.notificationsCardPadding !== undefined) {
        var notificationCardPadding = Number(p.notificationsCardPadding)
        if (isFinite(notificationCardPadding)) p.notificationsCardPadding = Math.max(0, Math.min(32, Math.round(notificationCardPadding)))
        else delete p.notificationsCardPadding
    } else if (!isSparse) p.notificationsCardPadding = 12

    if (p.notificationsBodyFont !== undefined) {
        if (typeof p.notificationsBodyFont === "string")
            p.notificationsBodyFont = p.notificationsBodyFont.replace(/[\r\n\t]/g, " ").trim().slice(0, 128)
        else if (isSparse) delete p.notificationsBodyFont
        else p.notificationsBodyFont = ""
    } else if (!isSparse) p.notificationsBodyFont = ""

    if (p.notificationsBodyFontSize !== undefined) {
        var notificationBodyFontSize = Number(p.notificationsBodyFontSize)
        if (isFinite(notificationBodyFontSize)) p.notificationsBodyFontSize = Math.max(8, Math.min(32, Math.round(notificationBodyFontSize)))
        else delete p.notificationsBodyFontSize
    } else if (!isSparse) p.notificationsBodyFontSize = 12

    if (p.notificationsBodyColor !== undefined) {
        var rawBodyColor = typeof p.notificationsBodyColor === "string" ? p.notificationsBodyColor.trim() : null
        if (rawBodyColor === "") p.notificationsBodyColor = ""
        else {
            var bodyColor = normalizeSavedColor(rawBodyColor, isSparse ? null : "")
            if (bodyColor === null) delete p.notificationsBodyColor
            else p.notificationsBodyColor = bodyColor
        }
    } else if (!isSparse) p.notificationsBodyColor = ""

    // Notification placement is now stored in geometry.notifications as absolute X/Y.
    // Old corner/offset values are obsolete and intentionally do not survive profile normalization.
    delete p.notificationsPosition
    delete p.notificationsOffsetX
    delete p.notificationsOffsetY
    delete p.notificationsMargin

    if (p.mopidyBrowseCoverKeepSelectedVisible !== undefined) {
        if (typeof p.mopidyBrowseCoverKeepSelectedVisible !== "boolean") {
            if (isSparse) delete p.mopidyBrowseCoverKeepSelectedVisible
            else p.mopidyBrowseCoverKeepSelectedVisible = false
        }
    } else if (!isSparse) p.mopidyBrowseCoverKeepSelectedVisible = false

    if (p.mopidyTrackArtistGap !== undefined) {
        var mopidyTrackArtistGap = Number(p.mopidyTrackArtistGap)
        if (isFinite(mopidyTrackArtistGap)) p.mopidyTrackArtistGap = Math.max(0, Math.min(8, Math.round(mopidyTrackArtistGap)))
        else if (isSparse) delete p.mopidyTrackArtistGap
        else p.mopidyTrackArtistGap = 0
    } else if (!isSparse) p.mopidyTrackArtistGap = 0

    if (!isSparse && p.mopidyAlbumBold === undefined) p.mopidyAlbumBold = true
    if (p.weatherToken !== undefined) p.weatherToken = String(p.weatherToken).trim()
    if (isSparse) delete p.weatherToken
    if (p.timerFinishedBackgroundColor !== undefined)
        p.timerFinishedBackgroundColor = normalizeSavedColor(p.timerFinishedBackgroundColor, "#4d000000")
    if (p.timerFinishedTitleColor !== undefined)
        p.timerFinishedTitleColor = normalizeSavedColor(p.timerFinishedTitleColor, "#ffffff")
    if (p.timerRandomColorMin !== undefined)
        p.timerRandomColorMin = normalizeSavedColor(p.timerRandomColorMin, "#000000")
    if (p.timerRandomColorMax !== undefined)
        p.timerRandomColorMax = normalizeSavedColor(p.timerRandomColorMax, "#ffffff")
    if (p.timerRandomColorMode !== undefined && ["full", "light", "dark", "custom"].indexOf(String(p.timerRandomColorMode)) < 0)
        p.timerRandomColorMode = "full"

    // QColor values in old JSON files are objects. Convert valid entries to
    // canonical ARGB strings; omit invalid entries so the captured defaults
    // are inherited when the profile is expanded.
    if (p.colors && typeof p.colors === "object") {
        var normalizedColors = {}
        for (var colorName in p.colors) {
            if (!Object.prototype.hasOwnProperty.call(p.colors, colorName)) continue
            var normalizedColor = normalizeSavedColor(p.colors[colorName], null)
            if (normalizedColor !== null) setOwn(normalizedColors, colorName, normalizedColor)
        }
        p.colors = normalizedColors
    }
    return p
}

function normalizeProfiles(profiles, isSparse) {
    var clean = {}
    if (!profiles || typeof profiles !== "object" || Array.isArray(profiles)) return clean
    for (var name in profiles) {
        if (!Object.prototype.hasOwnProperty.call(profiles, name)) continue
        var p = normalizeProfile(profiles[name], !!isSparse)
        if (p) setOwn(clean, name, p)
    }
    return clean
}

// Keep only the collapsible settings sidebar groups. Missing values preserve
// the current UI preference, while malformed values fall back to expanded.
function normalizeSettingsNavigationCollapsedGroups(source, current) {
    var ids = ["appearance", "modules", "launcher", "notifications"]
    var result = ({})
    var sourceIsObject = source && typeof source === "object" && !Array.isArray(source)
    var currentIsObject = current && typeof current === "object" && !Array.isArray(current)
    for (var i = 0; i < ids.length; ++i) {
        var id = ids[i]
        var fallback = currentIsObject && typeof current[id] === "boolean" ? current[id] : false
        result[id] = sourceIsObject && typeof source[id] === "boolean" ? source[id] : fallback
    }
    return result
}

