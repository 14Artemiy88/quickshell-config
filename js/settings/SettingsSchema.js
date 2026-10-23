.pragma library

// Keep old settings readable while new snapshots contain only canonical fields.
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
                if (fallbackKey === "topAppsCpuBarColor" && savedPalette.accent !== undefined)
                    fallbackColor = normalizeSavedColor(savedPalette.accent, fallbackColor)
                else if (fallbackKey === "topAppsRamBarColor" && savedPalette.ram !== undefined)
                    fallbackColor = normalizeSavedColor(savedPalette.ram, fallbackColor)
                else if ((fallbackKey === "topAppsCpuBarTrackColor" || fallbackKey === "topAppsRamBarTrackColor")
                        && (savedPalette.topAppsBarTrackColor !== undefined || savedPalette.metricTrack !== undefined))
                    fallbackColor = normalizeSavedColor(savedPalette.topAppsBarTrackColor !== undefined ? savedPalette.topAppsBarTrackColor : savedPalette.metricTrack, fallbackColor)
            }
            normalized[fallbackKey] = normalizeSavedColor(savedPalette[fallbackKey], fallbackColor)
        }
        for (var savedKey in savedPalette) {
            if (!Object.prototype.hasOwnProperty.call(savedPalette, savedKey) || normalized[savedKey] !== undefined) continue
            var extraColor = normalizeSavedColor(savedPalette[savedKey], null)
            if (extraColor !== null) normalized[savedKey] = extraColor
        }
        result[String(themeName)] = normalized
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

function normalizeProfile(profile, isSparse) {
    if (!profile || typeof profile !== "object") return null
    var p = JSON.parse(JSON.stringify(profile))

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

    if (!isSparse && p.mopidyAlbumBold === undefined) p.mopidyAlbumBold = true
    if (p.weatherToken !== undefined) p.weatherToken = String(p.weatherToken).trim()
    if (isSparse) delete p.weatherToken
    if (p.timerFinishedBackgroundColor !== undefined)
        p.timerFinishedBackgroundColor = normalizeSavedColor(p.timerFinishedBackgroundColor, "#4d000000")
    if (p.timerFinishedTitleColor !== undefined)
        p.timerFinishedTitleColor = normalizeSavedColor(p.timerFinishedTitleColor, "#ffffff")

    // QColor values in old JSON files are objects. Convert valid entries to
    // canonical ARGB strings; omit invalid entries so the captured defaults
    // are inherited when the profile is expanded.
    if (p.colors && typeof p.colors === "object") {
        var normalizedColors = {}
        for (var colorName in p.colors) {
            if (!Object.prototype.hasOwnProperty.call(p.colors, colorName)) continue
            var normalizedColor = normalizeSavedColor(p.colors[colorName], null)
            if (normalizedColor !== null) normalizedColors[colorName] = normalizedColor
        }
        p.colors = normalizedColors
    }
    return p
}

function normalizeProfiles(profiles, isSparse) {
    var clean = {}
    if (!profiles || typeof profiles !== "object") return clean
    for (var name in profiles) {
        if (!Object.prototype.hasOwnProperty.call(profiles, name)) continue
        var p = normalizeProfile(profiles[name], !!isSparse)
        if (p) clean[name] = p
    }
    return clean
}
