.pragma library

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
    var v = String(value)
    if (!(/^#[0-9a-fA-F]{6,8}$/.test(v) || v === "transparent")) return false
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
    owner.activeTheme = newN
    owner.themeDraftSource = newN
    owner.themeDraft = JSON.parse(JSON.stringify(next[newN]))
    owner.themeDraftRevision++
    owner.themeStateRevision++
    owner.save()
    return true
}

function deleteCustomTheme(owner, themes, Config, name) {
    var n = String(name || "")
    if (!isCustomTheme(owner, n)) return false
    var next = Object.assign({}, owner.customThemes || {})
    delete next[n]
    owner.customThemes = next
    if (owner.activeTheme === n) {
        owner.activeTheme = "14 Theme"
        var p = themes.palette(owner.activeTheme, owner.customThemes)
        for (var key in p) Config[key] = p[key]
        owner.themeDraftSource = owner.activeTheme
        owner.themeDraft = JSON.parse(JSON.stringify(p))
        owner.themeDraftRevision++
    }
    owner.themeStateRevision++
    owner.save()
    return true
}
