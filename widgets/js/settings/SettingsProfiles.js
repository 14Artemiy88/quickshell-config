.pragma library

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

function saveProfile(owner, name) {
    var n = String(name || "").trim()
    if (!n) return false
    n = n.slice(0, 32)
    var next = Object.assign({}, owner.profiles || {})
    next[n] = JSON.parse(JSON.stringify(owner.snapshotObject()))
    owner.profiles = next
    owner.activeProfile = n
    rebuildProfileList(owner)
    owner.save()
    return true
}

function loadProfile(owner, name) {
    var n = String(name || "")
    var profile = owner.profiles ? owner.profiles[n] : null
    if (!profile) return false
    owner.applyObject(JSON.parse(JSON.stringify(profile)))
    owner.activeProfile = n
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
