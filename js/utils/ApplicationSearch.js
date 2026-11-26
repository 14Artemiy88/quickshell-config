.pragma library

.import "../launcher/LauncherKeyboardLayout.js" as KeyboardLayout

// Convert ordinary JavaScript arrays and QML/Qt list-like values into a
// stable array. DesktopEntries fields can cross the QML boundary as list-like
// objects rather than native JavaScript arrays.
function valuesOf(value) {
    if (Array.isArray(value)) return value
    if (value === undefined || value === null) return []
    if (typeof value === "string") return value.length > 0 ? [value] : []

    var length = Number(value.length)
    if (!isFinite(length) || length < 0) return []
    length = Math.floor(length)

    var result = []
    for (var i = 0; i < length; ++i) result.push(value[i])
    return result
}

function searchValue(value) {
    if (value === undefined || value === null) return ""
    if (typeof value === "string") return value
    if (typeof value.length === "number" && isFinite(value.length)) {
        var parts = []
        for (var i = 0; i < value.length; ++i) {
            var part = value[i]
            if (part !== undefined && part !== null) parts.push(String(part))
        }
        return parts.join(" ")
    }
    return String(value)
}

// Exact/prefix/substring and subsequence scoring shared by Launcher app
// search. Keyboard-layout fallback is applied by fuzzyScore below.
function fuzzyScoreCore(text, query, fuzzyEnabled) {
    text = String(text === undefined || text === null ? "" : text).toLowerCase().trim()
    query = String(query === undefined || query === null ? "" : query).toLowerCase().trim()

    if (query === "") return 0
    if (text === query) return 10000
    if (text.startsWith(query)) return 9000 - text.length
    if (text.includes(query)) return 8000 - text.indexOf(query)
    if (fuzzyEnabled === false) return -1

    var score = 0
    var position = 0
    var firstMatch = -1
    var previousMatch = -1
    for (var i = 0; i < query.length; ++i) {
        var character = query[i]
        var found = text.indexOf(character, position)
        if (found === -1) return -1
        if (firstMatch === -1) firstMatch = found
        if (previousMatch >= 0) {
            var gap = found - previousMatch - 1
            if (gap === 0) score += 500
            else score += Math.max(0, 200 - gap * 30)
        }
        if (found === 0 || text[found - 1] === " " || text[found - 1] === "-"
                || text[found - 1] === "_" || text[found - 1] === ".") score += 300
        score += Math.max(0, 200 - found * 10)
        previousMatch = found
        position = found + 1
    }
    score += Math.max(0, 100 - text.length)
    return score
}

function fuzzyScoreNative(text, query, fuzzyEnabled) {
    return fuzzyScoreCore(text, query, fuzzyEnabled)
}

function fuzzyScore(text, query, fuzzyEnabled) {
    return KeyboardLayout.scoreWithLayout(
        text, query,
        function(searchText, searchQuery) {
            return fuzzyScoreNative(searchText, searchQuery, fuzzyEnabled)
        }
    )
}
