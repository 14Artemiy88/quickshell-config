.pragma library

.import "SettingsProfiles.js" as Profiles

function palette(owner, themes, name) {
    return themes.palette(name, owner.customThemes)
}

function currentThemeColors(owner, colorNames, Config) {
    var result = {}
    for (var i = 0; i < colorNames.length; ++i) {
        var key = colorNames[i]
        result[key] = String(Config[key])
    }
    return result
}

function isCurrentThemeModified(owner, themes, colorNames, Config) {
    var palette = themes.palette(owner.activeTheme, owner.customThemes)
    for (var i = 0; i < colorNames.length; ++i) {
        var key = colorNames[i]
        if (String(Config[key]) !== String(palette[key] !== undefined ? palette[key] : Config[key]))
            return true
    }
    return false
}

function saveCurrentTheme(owner, colorNames, Config, name) {
    var n = String(name || "").trim().slice(0, 32)
    if (!n) return false
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
    for (var key in p) Config[key] = p[key]
    // Custom themes saved before Top Apps bar colors existed inherit their
    // CPU/RAM colors from the corresponding palette entries when switched.
    if (p.topAppsCpuBarColor === undefined) Config.topAppsCpuBarColor = p.accent || Config.accent
    if (p.topAppsRamBarColor === undefined) Config.topAppsRamBarColor = p.ram || Config.ram
    if (p.topAppsCpuBarTrackColor === undefined) Config.topAppsCpuBarTrackColor = p.topAppsBarTrackColor || p.metricTrack || Config.metricTrack
    if (p.topAppsRamBarTrackColor === undefined) Config.topAppsRamBarTrackColor = p.topAppsBarTrackColor || p.metricTrack || Config.metricTrack
    owner.activeTheme = n
    owner.themeDraftSource = n
    owner.themeDraft = JSON.parse(JSON.stringify(p))
    owner.themeDraftRevision++
    owner.themeStateRevision++
    owner.save()
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
    if (!n || themes.builtinThemeNames.indexOf(n) >= 0 || !owner.themeDraft) return false
    var next = Object.assign({}, owner.customThemes || {})
    next[n] = JSON.parse(JSON.stringify(owner.themeDraft))
    owner.customThemes = next
    owner.activeTheme = n
    owner.themeDraftSource = n
    owner.themeDraft = JSON.parse(JSON.stringify(next[n]))
    owner.themeDraftRevision++
    for (var key in next[n]) Config[key] = next[n][key]
    owner.themeStateRevision++
    owner.save()
    return true
}

function renameCustomTheme(owner, themes, Config, oldName, newName) {
    var oldN = String(oldName || "").trim()
    var newN = String(newName || "").trim().slice(0, 32)
    if (!isCustomTheme(owner, oldN) || !newN || oldN === newN) return oldN === newN && isCustomTheme(owner, oldN)
    if (themes.builtinThemeNames.indexOf(newN) >= 0) return false
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
    var colorNames = owner.colorNames || []
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
