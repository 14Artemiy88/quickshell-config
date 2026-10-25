.pragma library

var SPARSE_FORMAT = "sparse-v1"
var REPLACE_MARKER = "__profile_replace__"

function clone(value) {
    if (value === undefined) return undefined
    return JSON.parse(JSON.stringify(value))
}

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
}

function sameValue(a, b) {
    if (a === b) return true
    if (a === null || b === null || a === undefined || b === undefined) return a === b
    if (Array.isArray(a) || Array.isArray(b)) {
        if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false
        for (var i = 0; i < a.length; ++i) if (!sameValue(a[i], b[i])) return false
        return true
    }
    if (isObject(a) && isObject(b)) {
        var ak = Object.keys(a).sort()
        var bk = Object.keys(b).sort()
        if (ak.length !== bk.length) return false
        for (var j = 0; j < ak.length; ++j) {
            if (ak[j] !== bk[j] || !sameValue(a[ak[j]], b[bk[j]])) return false
        }
        return true
    }
    return false
}

// Return only values that differ from the captured application defaults.
// Arrays are atomic values; objects are diffed recursively to keep nested
// structures such as colors, module toggles and geometry compact too.
function diffValue(base, current) {
    if (sameValue(base, current)) return undefined

    if (isObject(base) && isObject(current)) {
        var baseKeys = Object.keys(base)
        var currentKeys = Object.keys(current)
        for (var m = 0; m < baseKeys.length; ++m) {
            if (!Object.prototype.hasOwnProperty.call(current, baseKeys[m])) {
                var replacement = {}
                replacement[REPLACE_MARKER] = clone(current)
                return replacement
            }
        }
        var out = {}
        for (var i = 0; i < currentKeys.length; ++i) {
            var key = currentKeys[i]
            var delta = diffValue(base[key], current[key])
            if (delta !== undefined) out[key] = delta
        }
        return out
    }

    return clone(current)
}

function mergeValue(base, delta) {
    if (isObject(delta) && Object.keys(delta).length === 1 && Object.prototype.hasOwnProperty.call(delta, REPLACE_MARKER))
        return clone(delta[REPLACE_MARKER])

    if (isObject(base) && isObject(delta)) {
        var merged = clone(base)
        for (var key in delta) {
            if (!Object.prototype.hasOwnProperty.call(delta, key)) continue
            merged[key] = mergeValue(base[key], delta[key])
        }
        return merged
    }
    return clone(delta)
}

function profileBase(owner) {
    var base = clone(owner.profileDefaults || {})
    // Weather credentials belong to the installation, not to a visual profile.
    delete base.weatherToken
    return base
}


var STORAGE_FORMAT = "profile-overrides-v1"

// Expand the compact settings file back into the effective flat snapshot used
// by the existing QML settings adapters. The active profile is the base;
// profileOverrides contains only deliberate differences from that profile.
function expandStoredSettings(owner, stored) {
    if (!stored || typeof stored !== "object" || stored.settingsPersistenceFormat !== STORAGE_FORMAT)
        return clone(stored)

    var defaults = profileBase(owner)
    var profiles = clone(stored.profiles || {})
    var sparse = String(stored.profileStorageFormat || "") === SPARSE_FORMAT

    // New-format files are written with sparse profiles. If a hand-edited or
    // interrupted migration leaves a legacy profile representation under the
    // new marker, normalize it to sparse deltas before choosing the base.
    if (!sparse) {
        var migrated = {}
        for (var legacyName in profiles) {
            if (!Object.prototype.hasOwnProperty.call(profiles, legacyName)) continue
            var completed = completeLegacySnapshot(defaults, profiles[legacyName])
            migrated[legacyName] = sparseProfile(owner, completed)
        }
        profiles = migrated
    }

    var requested = String(stored.activeProfile || "").trim()
    var active = requested && Object.prototype.hasOwnProperty.call(profiles, requested) ? requested : ""
    var base = clone(defaults)
    if (active)
        base = mergeValue(base, profiles[active])

    var overrides = isObject(stored.profileOverrides) ? clone(stored.profileOverrides) : {}
    var reserved = [
        "settingsPersistenceFormat", "profileOverrides", "managedKeys", "managedNestedKeys",
        "weatherToken", "profiles", "profileStorageFormat", "activeProfile", "customThemes"
    ]
    // Preserve unrecognized top-level fields from newer app versions. They
    // are passthrough extensions, not part of this version's active schema.
    var extras = {}
    for (var key in stored) {
        if (!Object.prototype.hasOwnProperty.call(stored, key) || reserved.indexOf(key) >= 0) continue
        extras[key] = clone(stored[key])
    }

    var effective = mergeValue(base, overrides)
    effective = mergeValue(effective, extras)
    effective.weatherToken = String(stored.weatherToken || "").trim()
    effective.profiles = profiles
    effective.profileStorageFormat = SPARSE_FORMAT
    effective.activeProfile = active
    effective.customThemes = clone(stored.customThemes || {})
    return effective
}

function captureDefaults(owner) {
    var base = clone(owner.snapshotObject())
    delete base.weatherToken
    return base
}

function rebuildProfileList(owner) {
    var names = Object.keys(owner.profiles || {}).sort(function(a, b) {
        return a.localeCompare(b)
    })
    owner.profileList = names
    owner.profilesRevision++
}

function profileNames(owner) {
    return owner.profileList
}

// Complete a legacy full snapshot with defaults that did not exist when the
// profile was created. This is intentionally a recursive merge for plain
// objects (module flags, geometry, colors); arrays and scalar values stored by
// the legacy profile remain authoritative and replace the defaults atomically.
function completeLegacySnapshot(defaults, profile) {
    if (!isObject(defaults) || !isObject(profile)) return clone(profile)

    var result = clone(defaults)
    for (var key in profile) {
        if (!Object.prototype.hasOwnProperty.call(profile, key)) continue
        if (isObject(defaults[key]) && isObject(profile[key]))
            result[key] = completeLegacySnapshot(defaults[key], profile[key])
        else
            result[key] = clone(profile[key])
    }
    return result
}

function sparseProfile(owner, fullSnapshot) {
    var full = clone(fullSnapshot || {})
    delete full.weatherToken
    var sparse = diffValue(profileBase(owner), full) || {}

    // Colors are user-facing visual preferences. Keep a complete color map in
    // each saved profile instead of inheriting colors that happen to equal the
    // current release defaults. Otherwise a later release changing a default
    // can silently change an existing profile on its next load.
    if (isObject(full.colors)) {
        sparse.colors = clone(full.colors)
        var colorNames = owner && Array.isArray(owner.colorNames) ? owner.colorNames : []
        for (var i = 0; i < colorNames.length; ++i) {
            var colorName = colorNames[i]
            if (full.colors[colorName] !== undefined)
                sparse.colors[colorName] = String(full.colors[colorName])
        }
    }
    return sparse
}

function sparsifyProfiles(owner, fullProfiles) {
    var result = {}
    for (var name in (fullProfiles || {})) {
        if (!Object.prototype.hasOwnProperty.call(fullProfiles, name)) continue
        result[name] = sparseProfile(owner, fullProfiles[name])
    }
    return result
}

function expandProfile(owner, profile) {
    if (!profile || typeof profile !== "object") return null
    if (owner.profileStorageFormat === SPARSE_FORMAT)
        return mergeValue(profileBase(owner), profile)
    var full = clone(profile)
    delete full.weatherToken
    return full
}

function expandedProfileByName(owner, name) {
    var key = String(name || owner.activeProfile || "")
    var profile = owner.profiles ? owner.profiles[key] : null
    return profile ? expandProfile(owner, profile) : null
}

function saveProfile(owner, name) {
    var n = String(name || "").trim()
    if (!n) return false
    n = n.slice(0, 32)
    var next = Object.assign({}, owner.profiles || {})
    next[n] = sparseProfile(owner, owner.snapshotObject())
    owner.profiles = next
    owner.profileStorageFormat = SPARSE_FORMAT
    owner.activeProfile = n
    rebuildProfileList(owner)
    owner.save()
    return true
}

function loadProfile(owner, name) {
    var n = String(name || "")
    var profile = owner.profiles ? owner.profiles[n] : null
    if (!profile) return false
    var expanded = expandProfile(owner, profile)
    if (!expanded) return false
    owner.applyObject(clone(expanded))
    owner.activeProfile = n
    owner.profileStorageFormat = SPARSE_FORMAT
    rebuildProfileList(owner)
    owner.save()
    return true
}

function deleteProfile(owner, name) {
    var n = String(name || "")
    if (!owner.profiles || owner.profiles[n] === undefined) return false
    var next = Object.assign({}, owner.profiles)
    delete next[n]
    owner.profiles = next
    if (owner.activeProfile === n) owner.activeProfile = ""
    rebuildProfileList(owner)
    owner.save()
    return true
}


// Keep profiles valid when a referenced custom theme is renamed or deleted.
// Saved color values remain profile-scoped, while the custom theme catalog is
// global; a deleted theme therefore falls back to an exact matching palette
// when possible, or the default theme while retaining the saved colors.
function rewriteThemeReferences(owner, themes, oldName, newName) {
    var current = owner.profiles || {}
    var next = Object.assign({}, current)
    var changed = false
    var candidateNames = (themes && themes.builtinThemeNames ? themes.builtinThemeNames.slice() : [])
    Object.keys(owner.customThemes || {}).sort(function(a, b) { return a.localeCompare(b) }).forEach(function(name) {
        if (candidateNames.indexOf(name) < 0) candidateNames.push(name)
    })
    var colorNames = owner.colorNames || []

    function matchingTheme(profile) {
        var colors = profile && profile.colors ? profile.colors : {}
        for (var i = 0; i < candidateNames.length; ++i) {
            var candidate = candidateNames[i]
            var palette = themes.palette(candidate, owner.customThemes)
            var matches = true
            for (var j = 0; j < colorNames.length; ++j) {
                var key = colorNames[j]
                if (colors[key] === undefined) continue
                if (String(colors[key]) !== String(palette[key] !== undefined ? palette[key] : "")) {
                    matches = false
                    break
                }
            }
            if (matches) return candidate
        }
        return candidateNames.indexOf("14 Theme") >= 0 ? "14 Theme" : (candidateNames[0] || "14 Theme")
    }

    Object.keys(current).forEach(function(name) {
        var full = expandProfile(owner, current[name])
        if (!full || String(full.activeTheme || "") !== String(oldName)) return
        full.activeTheme = newName ? String(newName) : matchingTheme(full)
        next[name] = owner.profileStorageFormat === SPARSE_FORMAT ? sparseProfile(owner, full) : full
        changed = true
    })

    if (changed) owner.profiles = next
    return changed
}
