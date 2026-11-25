.pragma library

.import "SettingsProfiles.js" as Profiles

var GENERATED_WALLPAPER_THEME_NAME = "Wallpaper Dynamic"
var MAX_CUSTOM_THEME_NAME_LENGTH = 32
var RESERVED_THEME_KEYS = ["__proto__", "prototype", "constructor", "toString", "toLocaleString", "valueOf", "hasOwnProperty", "isPrototypeOf", "propertyIsEnumerable"]

function hasOwn(object, key) {
    return !!object && Object.prototype.hasOwnProperty.call(object, String(key))
}

function setOwn(object, key, value) {
    Object.defineProperty(object, String(key), {
        value: value, enumerable: true, configurable: true, writable: true
    })
}

function copyThemeMap(source) {
    var result = {}
    if (!source || typeof source !== "object" || Array.isArray(source)) return result
    var names = Object.keys(source)
    for (var i = 0; i < names.length; ++i)
        setOwn(result, names[i], JSON.parse(JSON.stringify(source[names[i]])))
    return result
}

function normalizeThemeName(value) {
    return String(value === undefined || value === null ? "" : value).trim()
}

function validNewThemeName(value) {
    var name = normalizeThemeName(value)
    return name.length > 0 && name.length <= MAX_CUSTOM_THEME_NAME_LENGTH
        && !/[\u0000-\u001f\u007f]/.test(name)
        && RESERVED_THEME_KEYS.indexOf(name) < 0
}

function isThemeAvailable(themes, owner, name) {
    if (themes && Array.isArray(themes.builtinThemeNames))
        return themes.builtinThemeNames.indexOf(String(name)) >= 0 || hasOwn(owner && owner.customThemes, name)
    // Small test adapters and older integrations may expose only palette().
    return !!(themes && typeof themes.palette === "function")
}

function validColorValue(value) {
    if (typeof value !== "string") return false
    var normalized = value.trim().toLowerCase()
    return /^#[0-9a-f]{6}([0-9a-f]{2})?$/.test(normalized) || normalized === "transparent"
}

function copyPaletteForDraft(owner, sourcePalette, Config) {
    var draft = JSON.parse(JSON.stringify(sourcePalette || {}))
    var managed = managedColorNames(owner, owner && owner.colorNames ? owner.colorNames : Object.keys(draft))
    for (var i = 0; i < managed.length; ++i) {
        var key = String(managed[i])
        if (!hasOwn(draft, key) && Config && Config[key] !== undefined)
            setOwn(draft, key, String(Config[key]))
    }
    return draft
}

function managedColorNames(owner, fallback) {
    if (owner && Array.isArray(owner.themeManagedColorNames))
        return owner.themeManagedColorNames
    var independent = ["settingsBackground", "playerProgressTrack", "playerProgressFill",
        "topAppsCpuBarColor", "topAppsRamBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarTrackColor"]
    return (Array.isArray(fallback) ? fallback : []).filter(function(name) {
        return independent.indexOf(name) < 0
    })
}

function independentColorNames(owner) {
    if (owner && Array.isArray(owner.independentThemeColorNames))
        return owner.independentThemeColorNames
    return ["settingsBackground", "playerProgressTrack", "playerProgressFill",
        "topAppsCpuBarColor", "topAppsRamBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarTrackColor"]
}

function palette(owner, themes, name) {
    return themes.palette(name, owner.customThemes)
}

function currentThemeColors(owner, colorNames, Config) {
    var result = {}
    var managed = managedColorNames(owner, colorNames)
    for (var i = 0; i < managed.length; ++i) {
        var key = managed[i]
        setOwn(result, key, String(Config[key]))
    }
    return result
}

function isCurrentThemeModified(owner, themes, colorNames, Config) {
    var palette = themes.palette(owner.activeTheme, owner.customThemes)
    var managed = managedColorNames(owner, colorNames)
    for (var i = 0; i < managed.length; ++i) {
        var key = managed[i]
        if (String(Config[key]) !== String(palette[key] !== undefined ? palette[key] : Config[key]))
            return true
    }
    return false
}

function saveCurrentTheme(owner, colorNames, Config, name) {
    var n = normalizeThemeName(name)
    var updatingActiveCustomTheme = owner.activeTheme === n && hasOwn(owner.customThemes, n)
    if ((!validNewThemeName(n) && !updatingActiveCustomTheme)
            || (owner.builtinThemeNames && owner.builtinThemeNames.indexOf(n) >= 0)
            || (n === GENERATED_WALLPAPER_THEME_NAME && owner.activeTheme !== n)) return false
    if (owner.customThemes && hasOwn(owner.customThemes, n) && owner.activeTheme !== n) return false
    if (owner.activeTheme === n && !hasOwn(owner.customThemes, n)) return false
    var next = copyThemeMap(owner.customThemes)
    setOwn(next, n, currentThemeColors(owner, colorNames, Config))
    owner.customThemes = next
    owner.activeTheme = n
    owner.themeDraftSource = n
    owner.themeDraft = JSON.parse(JSON.stringify(next[n]))
    owner.themeDraftRevision++
    owner.themeStateRevision++
    owner.save()
    return true
}

function applyTheme(owner, themes, Config, name) {
    var n = normalizeThemeName(name)
    if (!n || !isThemeAvailable(themes, owner, n)) return false
    var p = themes.palette(n, owner.customThemes)
    // These are user-tuned component/window colors, not part of the global
    // theme. Keep their current values when switching built-in or custom themes.
    var independentColors = independentColorNames(owner)
    var preserved = {}
    for (var i = 0; i < independentColors.length; ++i) {
        var independentKey = independentColors[i]
        preserved[independentKey] = Config[independentKey]
    }
    for (var key in p) Config[key] = p[key]
    for (var j = 0; j < independentColors.length; ++j) {
        var restoreKey = independentColors[j]
        if (preserved[restoreKey] !== undefined) Config[restoreKey] = preserved[restoreKey]
    }
    owner.activeTheme = n
    owner.themeDraftSource = n
    owner.themeDraft = copyPaletteForDraft(owner, p, Config)
    owner.themeDraftRevision++
    owner.themeStateRevision++
    owner.save()
    return true
}

function applyGeneratedTheme(owner, themes, Config, colorNames, name, paletteValue) {
    var n = normalizeThemeName(name)
    if (n !== GENERATED_WALLPAPER_THEME_NAME || !paletteValue || typeof paletteValue !== "object")
        return false

    var generated = {}
    var names = managedColorNames(owner, colorNames)
    for (var i = 0; i < names.length; ++i) {
        var key = String(names[i])
        var value = paletteValue[key]
        if (typeof value !== "string") return false
        var normalized = value.trim().toLowerCase()
        if (!validColorValue(value)) return false
        setOwn(generated, key, normalized)
    }
    if (!names.length) return false

    var next = copyThemeMap(owner.customThemes)
    setOwn(next, n, generated)
    owner.customThemes = next
    applyTheme(owner, themes, Config, n)
    return true
}

function preview(owner, themes, name) {
    return themes.preview(name, owner.customThemes)
}

function description(themes, name) {
    return themes.description(name)
}

function isCustomTheme(owner, name) {
    return hasOwn(owner && owner.customThemes, name)
}

function beginThemeEdit(owner, themes, name, Config) {
    var n = normalizeThemeName(name)
    if (!isThemeAvailable(themes, owner, n)) return false
    var sourcePalette = themes.palette(n, owner.customThemes)
    if (!sourcePalette || typeof sourcePalette !== "object") return false
    owner.themeDraft = copyPaletteForDraft(owner, sourcePalette, Config)
    owner.themeDraftSource = n
    owner.themeDraftRevision++
    return true
}

function themeDraftValue(owner, Config, name) {
    var n = String(name)
    return hasOwn(owner && owner.themeDraft, n) ? String(owner.themeDraft[n]) : String(Config[n])
}

function setThemeDraftColor(owner, name, value) {
    var key = String(name)
    var v = String(value === undefined || value === null ? "" : value).trim().toLowerCase()
    var allowed = managedColorNames(owner, owner && owner.colorNames ? owner.colorNames : Object.keys(owner && owner.themeDraft || {}))
    if (allowed.indexOf(key) < 0 || !hasOwn(owner && owner.themeDraft, key) || !validColorValue(v)) return false
    var next = copyThemeMap(owner.themeDraft)
    setOwn(next, key, v)
    owner.themeDraft = next
    owner.themeDraftRevision++
    return true
}

function saveCustomTheme(owner, themes, Config, name) {
    var n = normalizeThemeName(name)
    var updatingDraftSource = owner.themeDraftSource === n && hasOwn(owner.customThemes, n)
    if ((!validNewThemeName(n) && !updatingDraftSource) || themes.builtinThemeNames.indexOf(n) >= 0 || !owner.themeDraft
            || (n === GENERATED_WALLPAPER_THEME_NAME && owner.themeDraftSource !== n)) return false
    if (hasOwn(owner.customThemes, n) && owner.themeDraftSource !== n) return false
    var next = copyThemeMap(owner.customThemes)
    var savedPalette = {}
    var managed = managedColorNames(owner, Object.keys(owner.themeDraft))
    for (var m = 0; m < managed.length; ++m) {
        var managedKey = String(managed[m])
        // Some compatibility colors (for example settingsSubheading) are
        // intentionally absent from built-in palettes and remain user-tuned.
        if (!hasOwn(owner.themeDraft, managedKey)) continue
        if (!validColorValue(owner.themeDraft[managedKey])) return false
        setOwn(savedPalette, managedKey, String(owner.themeDraft[managedKey]).trim().toLowerCase())
    }
    if (Object.keys(savedPalette).length === 0) return false
    setOwn(next, n, savedPalette)
    owner.customThemes = next
    owner.activeTheme = n
    owner.themeDraftSource = n
    owner.themeDraft = JSON.parse(JSON.stringify(next[n]))
    owner.themeDraftRevision++
    var applyNames = managedColorNames(owner, Object.keys(next[n]))
    for (var j = 0; j < applyNames.length; ++j) {
        var key = applyNames[j]
        if (next[n][key] !== undefined) Config[key] = next[n][key]
    }
    owner.themeStateRevision++
    owner.save()
    return true
}

function renameCustomTheme(owner, themes, Config, oldName, newName) {
    var oldN = normalizeThemeName(oldName)
    var newN = normalizeThemeName(newName)
    if (!isCustomTheme(owner, oldN)) return false
    if (oldN === newN) return true
    if (!validNewThemeName(newN) || themes.builtinThemeNames.indexOf(newN) >= 0
            || newN === GENERATED_WALLPAPER_THEME_NAME || hasOwn(owner.customThemes, newN)) return false

    var next = copyThemeMap(owner.customThemes)
    setOwn(next, newN, next[oldN])
    delete next[oldN]
    owner.customThemes = next
    // Profile snapshots keep color values even if the custom palette later
    // changes; update only the theme reference so rename does not orphan them.
    Profiles.rewriteThemeReferences(owner, themes, oldN, newN)
    owner.activeTheme = newN
    owner.themeDraftSource = newN
    owner.themeDraft = copyPaletteForDraft(owner, next[newN], Config)
    owner.themeDraftRevision++
    owner.themeStateRevision++
    owner.save()
    return true
}

function findExactThemeForColors(owner, themes, colors) {
    var names = (themes && themes.builtinThemeNames) ? themes.builtinThemeNames.slice() : []
    Object.keys(owner.customThemes || {}).sort(function(a, b) { return a.localeCompare(b) }).forEach(function(name) {
        if (names.indexOf(name) < 0) names.push(name)
    })
    var colorNames = managedColorNames(owner, owner.colorNames || [])
    if (!colorNames.length) return ""

    for (var i = 0; i < names.length; ++i) {
        var candidateName = names[i]
        var candidate = themes.palette(candidateName, owner.customThemes)
        var matches = true
        for (var j = 0; j < colorNames.length; ++j) {
            var key = colorNames[j]
            if (colors[key] === undefined || candidate[key] === undefined
                    || String(colors[key]).trim().toLowerCase() !== String(candidate[key]).trim().toLowerCase()) {
                matches = false
                break
            }
        }
        if (matches) return candidateName
    }
    return ""
}

function deleteCustomTheme(owner, themes, Config, name) {
    var n = normalizeThemeName(name)
    if (!isCustomTheme(owner, n)) return false
    var activeColors = owner.activeTheme === n
        ? currentThemeColors(owner, owner.colorNames || [], Config)
        : null
    var next = copyThemeMap(owner.customThemes)
    delete next[n]
    owner.customThemes = next
    // The theme is global, but saved profiles also retain their palette colors.
    // Retarget dangling references to an exact matching remaining theme when
    // possible; otherwise use the default name and keep the profile colors.
    Profiles.rewriteThemeReferences(owner, themes, n, "")
    if (owner.activeTheme === n) {
        var matchingName = findExactThemeForColors(owner, themes, activeColors)
        owner.activeTheme = matchingName || (themes.builtinThemeNames.indexOf("14 Theme") >= 0
            ? "14 Theme" : (themes.builtinThemeNames[0] || "14 Theme"))
        // Do not replace the currently displayed colors with the fallback
        // palette. If no remaining theme matches exactly, the color values are
        // a valid user palette and should remain visible as (Changed), just as
        // saved profiles preserve them when their custom theme is deleted.
        var p = themes.palette(owner.activeTheme, owner.customThemes)
        owner.themeDraftSource = owner.activeTheme
        owner.themeDraft = copyPaletteForDraft(owner, p, Config)
        owner.themeDraftRevision++
    }
    owner.themeStateRevision++
    owner.save()
    return true
}
