.pragma library

// Caelestia-inspired special application-search prefixes. These selectors
// only change which DesktopEntry metadata is searched; they never alter how
// an application is launched.
var SPECIAL_SEARCH_FIELDS = {
    i: { property: "id" },
    c: { property: "categories" },
    d: { property: "comment" },
    e: { property: "execString" },
    w: { property: "startupClass" },
    g: { property: "genericName" },
    k: { property: "keywords" },
    t: { property: "name", terminalOnly: true }
}

function parseSpecialQuery(value) {
    var query = String(value === undefined || value === null ? "" : value).trim()
    if (query.charAt(0) !== "@")
        return null

    var code = query.charAt(1).toLowerCase()
    var field = SPECIAL_SEARCH_FIELDS[code]
    if (!field)
        return null

    var remainder = query.slice(2)
    // Require a separator between the selector and its search text. Bare
    // selectors are recognized but intentionally return no app results yet.
    if (remainder.length > 0 && !/^\s/.test(remainder))
        return null

    return {
        code: code,
        property: field.property,
        terminalOnly: field.terminalOnly === true,
        query: remainder.trim()
    }
}

function searchValue(value) {
    if (value === undefined || value === null)
        return ""
    if (typeof value === "string")
        return value

    // Qt list properties may cross the QML/JS boundary as list-like values
    // rather than native arrays. Read them by length instead of relying on
    // Array.isArray or an Array prototype from a particular JS realm.
    if (typeof value.length === "number" && isFinite(value.length)) {
        var parts = []
        for (var i = 0; i < value.length; ++i) {
            var part = value[i]
            if (part !== undefined && part !== null)
                parts.push(String(part))
        }
        return parts.join(" ")
    }

    return String(value)
}

function scoreEntry(entry, specialQuery, fuzzyScore) {
    if (!entry || !specialQuery || !specialQuery.query || typeof fuzzyScore !== "function")
        return -1
    if (specialQuery.terminalOnly && entry.runInTerminal !== true)
        return -1

    var haystack = searchValue(entry[specialQuery.property])
    var fieldScore = fuzzyScore(haystack, specialQuery.query)
    if (fieldScore < 0)
        return -1

    // Match Caelestia's emphasis: selected metadata is primary (90%), while
    // the app name provides a smaller ranking boost (10%). The selected field
    // must match, so @c stays a category filter rather than ordinary search.
    var nameScore = specialQuery.property === "name"
        ? fieldScore
        : fuzzyScore(entry.name, specialQuery.query)
    return fieldScore * 0.9 + (nameScore >= 0 ? nameScore * 0.1 : 0)
}

// Shared App search scorer. Disabling fuzzy mode still allows exact, prefix,
// and contiguous substring matches; only subsequence/gapped matching is removed.
function fuzzyScore(text, query, fuzzyEnabled) {
    text = String(text === undefined || text === null ? "" : text).toLowerCase().trim()
    query = String(query === undefined || query === null ? "" : query).toLowerCase().trim()

    if (query === "")
        return 0
    if (text === query)
        return 10000
    if (text.startsWith(query))
        return 9000 - text.length
    if (text.includes(query))
        return 8000 - text.indexOf(query)

    if (fuzzyEnabled === false)
        return -1

    let score = 0
    let position = 0
    let firstMatch = -1
    let previousMatch = -1

    for (let i = 0; i < query.length; ++i) {
        const character = query[i]
        const found = text.indexOf(character, position)
        if (found === -1)
            return -1
        if (firstMatch === -1)
            firstMatch = found
        if (previousMatch >= 0) {
            const gap = found - previousMatch - 1
            if (gap === 0)
                score += 500
            else
                score += Math.max(0, 200 - gap * 30)
        }
        if (found === 0 || text[found - 1] === " " || text[found - 1] === "-" || text[found - 1] === "_" || text[found - 1] === ".")
            score += 300
        score += Math.max(0, 200 - found * 10)
        previousMatch = found
        position = found + 1
    }

    score += Math.max(0, 100 - text.length)
    return score
}

function valuesOf(value) {
    if (Array.isArray(value))
        return value
    if (typeof value === "string")
        return value.trim() ? [value] : []
    if (!value || typeof value.length !== "number" || !isFinite(value.length))
        return []
    var result = []
    for (var i = 0; i < value.length; ++i)
        result.push(value[i])
    return result
}

function displayCategoryName(value) {
    return String(value === undefined || value === null ? "" : value)
        .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
        .replace(/[-_]+/g, " ")
        .replace(/\s+/g, " ")
        .trim()
}

// Build a discoverable category list for the bare `@c` selector. Counts are
// based on visible applications, so hidden apps do not leak into the browser.
function collectCategories(entries, hiddenIds) {
    var apps = valuesOf(entries)
    var hidden = valuesOf(hiddenIds).map(function(id) { return String(id || "").trim() })
    var categories = []

    for (var i = 0; i < apps.length; ++i) {
        var entry = apps[i]
        if (!entry)
            continue

        var appId = String(entry.id || "").trim()
        if (appId && hidden.indexOf(appId) >= 0)
            continue

        var values = valuesOf(entry.categories)
        var seenForApp = []
        for (var j = 0; j < values.length; ++j) {
            var raw = String(values[j] === undefined || values[j] === null ? "" : values[j]).trim()
            if (!raw)
                continue

            var key = raw.toLowerCase()
            if (seenForApp.indexOf(key) >= 0)
                continue
            seenForApp.push(key)

            var categoryIndex = -1
            for (var k = 0; k < categories.length; ++k) {
                if (categories[k].key === key) {
                    categoryIndex = k
                    break
                }
            }
            if (categoryIndex < 0) {
                categories.push({
                    key: key,
                    name: raw,
                    label: displayCategoryName(raw),
                    count: 1
                })
            } else {
                categories[categoryIndex].count += 1
            }
        }
    }

    categories.sort(function(a, b) {
        var byLabel = a.label.localeCompare(b.label)
        return byLabel !== 0 ? byLabel : a.name.localeCompare(b.name)
    })
    return categories.map(function(item) {
        return { name: item.name, label: item.label, count: item.count }
    })
}
