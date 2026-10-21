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

function sparseProfile(owner, fullSnapshot) {
    var full = clone(fullSnapshot || {})
    delete full.weatherToken
    return diffValue(profileBase(owner), full) || {}
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
