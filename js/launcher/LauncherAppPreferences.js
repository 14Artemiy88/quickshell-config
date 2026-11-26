.pragma library

function valuesOf(value) {
    if (Array.isArray(value)) return value
    if (!value || typeof value.length !== "number" || !isFinite(value.length)) return []
    var result = []
    for (var i = 0; i < value.length; ++i) result.push(value[i])
    return result
}

function normalizeIds(value) {
    // Persisted notification rules are delimiter-separated strings, while
    // Launcher favorites/hidden apps are arrays or Qt list-like values.
    // Treat strings as ID lists instead of iterating their characters.
    var source = typeof value === "string"
        ? value.split(/[;,\n]+/)
        : valuesOf(value)
    var result = []
    for (var i = 0; i < source.length; ++i) {
        if (source[i] === undefined || source[i] === null) continue
        var id = String(source[i]).replace(/[\r\n\t]/g, " ").trim().slice(0, 512)
        if (!id || result.indexOf(id) >= 0) continue
        result.push(id)
    }
    return result
}

function containsId(value, id) {
    var wanted = String(id === undefined || id === null ? "" : id).trim()
    if (!wanted) return false
    return normalizeIds(value).indexOf(wanted) >= 0
}

function setId(value, id, enabled) {
    var wanted = String(id === undefined || id === null ? "" : id).trim().slice(0, 512)
    var result = normalizeIds(value)
    if (!wanted) return result
    var index = result.indexOf(wanted)
    if (enabled && index < 0) result.push(wanted)
    else if (!enabled && index >= 0) result.splice(index, 1)
    return result
}

function indexOfId(value, id) {
    var wanted = String(id === undefined || id === null ? "" : id).trim()
    return wanted ? normalizeIds(value).indexOf(wanted) : -1
}
