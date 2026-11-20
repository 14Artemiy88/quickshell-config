.pragma library

var MAX_ENTRIES = 50

function normalizeEntry(entry) {
    if (!entry || typeof entry !== "object")
        return null

    var expression = String(entry.expression === undefined || entry.expression === null ? "" : entry.expression).trim()
    var result = String(entry.result === undefined || entry.result === null ? "" : entry.result).trim()
    if (expression === "" || result === "" || expression.length > 128 || result.length > 128)
        return null

    return { expression: expression, result: result }
}

function sameEntry(left, right) {
    return left && right
        && String(left.expression) === String(right.expression)
        && String(left.result) === String(right.result)
}

function parseHistory(contents) {
    var parsed = null
    try {
        parsed = JSON.parse(String(contents === undefined || contents === null ? "" : contents))
    } catch (error) {
        return []
    }
    if (!Array.isArray(parsed))
        return []

    var entries = []
    for (var i = 0; i < parsed.length && entries.length < MAX_ENTRIES; ++i) {
        var entry = normalizeEntry(parsed[i])
        if (!entry)
            continue
        var duplicate = false
        for (var j = 0; j < entries.length; ++j) {
            if (sameEntry(entries[j], entry)) {
                duplicate = true
                break
            }
        }
        if (!duplicate)
            entries.push(entry)
    }
    return entries
}

function remember(entries, entry) {
    var normalized = normalizeEntry(entry)
    if (!normalized)
        return Array.isArray(entries) ? entries.slice(0, MAX_ENTRIES) : []

    var result = [normalized]
    var source = Array.isArray(entries) ? entries : []
    for (var i = 0; i < source.length && result.length < MAX_ENTRIES; ++i) {
        var oldEntry = normalizeEntry(source[i])
        if (!oldEntry || sameEntry(oldEntry, normalized))
            continue
        result.push(oldEntry)
    }
    return result
}

function applyMutations(entries, mutations) {
    var result = Array.isArray(entries) ? parseHistory(JSON.stringify(entries)) : []
    var changes = Array.isArray(mutations) ? mutations : []

    for (var i = 0; i < changes.length; ++i) {
        var mutation = changes[i] || {}
        var type = String(mutation.type || "")
        if (type === "clear") {
            result = []
        } else if (type === "remember") {
            result = remember(result, mutation.entry)
        }
    }
    return result
}

function serialize(entries) {
    return JSON.stringify(parseHistory(JSON.stringify(Array.isArray(entries) ? entries : [])))
}
