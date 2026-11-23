.pragma library

.import "SettingsProfiles.js" as Profiles

var GENERATED_WALLPAPER_THEME_NAME = "Wallpaper Dynamic"

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
        result[key] = String(Config[key])
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
    var n = String(name || "").trim().slice(0, 32)
    if (!n || (n === GENERATED_WALLPAPER_THEME_NAME && owner.activeTheme !== n)) return false
    var next = Object.assign({}, owner.customThemes || {})
    next[n] = currentThemeColors(owner, colorNames, Config)
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
    var n = String(name)
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
    owner.themeDraft = JSON.parse(JSON.stringify(p))
    owner.themeDraftRevision++
    owner.themeStateRevision++
    owner.save()
}

function applyGeneratedTheme(owner, themes, Config, colorNames, name, paletteValue) {
    var n = String(name || "").trim().slice(0, 32)
    if (n !== GENERATED_WALLPAPER_THEME_NAME || !paletteValue || typeof paletteValue !== "object")
        return false

    var generated = {}
    var names = managedColorNames(owner, colorNames)
    for (var i = 0; i < names.length; ++i) {
        var key = String(names[i])
        var value = paletteValue[key]
        if (typeof value !== "string") return false
        var normalized = value.trim().toLowerCase()
        if (!(/^#[0-9a-f]{6}([0-9a-f]{2})?$/.test(normalized) || normalized === "transparent"))
            return false
        generated[key] = normalized
    }
    if (!names.length) return false

    var next = Object.assign({}, owner.customThemes || {})
    next[n] = generated
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
    return !!(owner.customThemes && owner.customThemes[String(name)] !== undefined)
}

function beginThemeEdit(owner, themes, name) {
    var n = String(name)
    owner.themeDraft = JSON.parse(JSON.stringify(themes.palette(n, owner.customThemes)))
    owner.themeDraftSource = n
    owner.themeDraftRevision++
}

function themeDraftValue(owner, Config, name) {
    var n = String(name)
    return owner.themeDraft && owner.themeDraft[n] !== undefined ? String(owner.themeDraft[n]) : String(Config[n])
}

function setThemeDraftColor(owner, name, value) {
    var v = String(value || "").trim().toLowerCase()
    // Only accept valid six-digit RGB or eight-digit ARGB hex values. The old
    // {6,8} quantifier accidentally accepted invalid seven-digit colors.
    if (!(/^#(?:[0-9a-f]{6}|[0-9a-f]{8})$/.test(v) || v === "transparent")) return false
    var next = Object.assign({}, owner.themeDraft || {})
    next[String(name)] = v
    owner.themeDraft = next
    owner.themeDraftRevision++
    return true
}

function saveCustomTheme(owner, themes, Config, name) {
    var n = String(name || "").trim().slice(0, 32)
    if (!n || themes.builtinThemeNames.indexOf(n) >= 0 || !owner.themeDraft
            || (n === GENERATED_WALLPAPER_THEME_NAME && owner.themeDraftSource !== n)) return false
    var next = Object.assign({}, owner.customThemes || {})
    var savedPalette = JSON.parse(JSON.stringify(owner.themeDraft))
    var independent = independentColorNames(owner)
    for (var i = 0; i < independent.length; ++i) delete savedPalette[independent[i]]
    next[n] = savedPalette
    owner.customThemes = next
    owner.activeTheme = n
    owner.themeDraftSource = n
    owner.themeDraft = JSON.parse(JSON.stringify(next[n]))
    owner.themeDraftRevision++
    var managed = managedColorNames(owner, Object.keys(next[n]))
    for (var j = 0; j < managed.length; ++j) {
        var key = managed[j]
        if (next[n][key] !== undefined) Config[key] = next[n][key]
    }
    owner.themeStateRevision++
    owner.save()
    return true
}

function renameCustomTheme(owner, themes, Config, oldName, newName) {
    var oldN = String(oldName || "").trim()
    var newN = String(newName || "").trim().slice(0, 32)
    if (!isCustomTheme(owner, oldN) || !newN || oldN === newN) return oldN === newN && isCustomTheme(owner, oldN)
    if (themes.builtinThemeNames.indexOf(newN) >= 0 || newN === GENERATED_WALLPAPER_THEME_NAME) return false
    if (owner.customThemes && owner.customThemes[newN] !== undefined) return false

    var next = Object.assign({}, owner.customThemes || {})
    next[newN] = next[oldN]
    delete next[oldN]
    owner.customThemes = next
    // Profile snapshots keep color values even if the custom palette later
    // changes; update only the theme reference so rename does not orphan them.
    Profiles.rewriteThemeReferences(owner, themes, oldN, newN)
    owner.activeTheme = newN
    owner.themeDraftSource = newN
    owner.themeDraft = JSON.parse(JSON.stringify(next[newN]))
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
    var n = String(name || "")
    if (!isCustomTheme(owner, n)) return false
    var activeColors = owner.activeTheme === n
        ? currentThemeColors(owner, owner.colorNames || [], Config)
        : null
    var next = Object.assign({}, owner.customThemes || {})
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
        owner.themeDraft = JSON.parse(JSON.stringify(p))
        owner.themeDraftRevision++
    }
    owner.themeStateRevision++
    owner.save()
    return true
}
