.pragma library

.import "../utils/ApplicationSearch.js" as ApplicationSearch

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
    return ApplicationSearch.searchValue(value)
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

// The canonical application scorer used by Launcher AppModel. Keep matching
// semantics here so every app picker (including DND rules) ranks and filters
// applications exactly like the Launcher Apps tab.
function scoreApplication(entry, queryValue, fuzzyEnabled) {
    if (!entry)
        return -1

    var specialQuery = parseSpecialQuery(queryValue)
    if (specialQuery) {
        if (!specialQuery.query)
            return -1
        return scoreEntry(entry, specialQuery, function(searchText, searchQuery) {
            return fuzzyScore(searchText, searchQuery, fuzzyEnabled)
        })
    }

    var query = String(queryValue === undefined || queryValue === null ? "" : queryValue)
        .toLowerCase().trim()
    if (query === "")
        return 0

    var score = -1

    // Name is the primary search field. These offsets intentionally mirror
    // the original AppModel.qml implementation.
    score = Math.max(score, fuzzyScore(entry.name, query, fuzzyEnabled))
    score = Math.max(score, fuzzyScore(entry.genericName, query, fuzzyEnabled) - 100)
    score = Math.max(score, fuzzyScore(entry.comment, query, fuzzyEnabled) - 200)

    var keywords = valuesOf(entry.keywords)
    for (var i = 0; i < keywords.length; ++i)
        score = Math.max(score, fuzzyScore(keywords[i], query, fuzzyEnabled) - 150)

    return score
}

// Canonical Launcher application-list builder. AppModel and secondary app
// pickers call this complete pipeline rather than reimplementing filtering,
// metadata matching, favorites, recency and result ordering independently.
// hiddenIds can be [] for management pickers that must also expose Launcher-hidden apps.
function buildApplicationResults(entries, queryValue, fuzzyEnabled, favoriteIds,
        hiddenIds, usageCounts, recentApplications, emptyQueryLimit) {
    var source = valuesOf(entries)
    var favorites = valuesOf(favoriteIds).map(function(id) {
        return String(id === undefined || id === null ? "" : id).trim()
    })
    var hidden = valuesOf(hiddenIds).map(function(id) {
        return String(id === undefined || id === null ? "" : id).trim()
    })
    var counts = usageCounts && typeof usageCounts === "object" ? usageCounts : {}
    var recent = valuesOf(recentApplications)
    var rawQuery = String(queryValue === undefined || queryValue === null ? "" : queryValue)
    var special = parseSpecialQuery(rawQuery)
    var query = (special ? special.query : rawQuery).toLowerCase().trim()

    // Launcher handles a bare @c as a category browser outside this list.
    // Other bare selectors intentionally produce no app results either.
    if (special && query === "")
        return []

    var ranked = []
    var hasNameMatch = false
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!entry)
            continue

        var id = String(entry.id || "").trim()
        if (id && hidden.indexOf(id) >= 0)
            continue

        var favoriteIndex = id ? favorites.indexOf(id) : -1
        if (query === "") {
            var usage = Number(counts[entry.name] || 0)
            var recentIndex = recent.indexOf(entry.name)
            var recency = recentIndex >= 0 ? Math.max(0, 1000 - recentIndex) : 0
            ranked.push({
                entry: entry,
                favoriteIndex: favoriteIndex,
                usage: usage,
                recency: recency,
                rank: usage * 1000 + recency
            })
            continue
        }

        var score = scoreApplication(entry, rawQuery, fuzzyEnabled)
        if (score >= 0) {
            // The visible Launcher behavior prioritizes application-name hits.
            // Without this second pass, a short query such as "fire" can also
            // match scattered letters in long descriptions (e.g. "files over").
            // Keep metadata search as a fallback when no app name matches.
            var nameScore = special ? -1 : fuzzyScore(entry.name, query, fuzzyEnabled)
            if (nameScore >= 0)
                hasNameMatch = true
            ranked.push({
                entry: entry,
                favoriteIndex: favoriteIndex,
                score: score,
                nameScore: nameScore
            })
        }
    }

    if (query === "") {
        ranked.sort(function(a, b) {
            var aFavorite = a.favoriteIndex >= 0
            var bFavorite = b.favoriteIndex >= 0
            if (aFavorite && bFavorite && a.favoriteIndex !== b.favoriteIndex)
                return a.favoriteIndex - b.favoriteIndex
            if (aFavorite !== bFavorite)
                return aFavorite ? -1 : 1
            if (b.rank !== a.rank)
                return b.rank - a.rank
            if (b.usage !== a.usage)
                return b.usage - a.usage
            return String(a.entry.name).localeCompare(String(b.entry.name))
        })

        var favoriteCount = 0
        for (var j = 0; j < ranked.length; ++j) {
            if (ranked[j].favoriteIndex >= 0)
                favoriteCount += 1
        }
        var emptyLimit = Math.max(Number(emptyQueryLimit) || 0, favoriteCount)
        return ranked.slice(0, emptyLimit)
    }

    if (hasNameMatch && !special) {
        ranked = ranked.filter(function(item) { return item.nameScore >= 0 })
    }

    ranked.sort(function(a, b) {
        var aFavorite = a.favoriteIndex >= 0
        var bFavorite = b.favoriteIndex >= 0
        if (aFavorite !== bFavorite)
            return aFavorite ? -1 : 1
        if (aFavorite && bFavorite && a.favoriteIndex !== b.favoriteIndex)
            return a.favoriteIndex - b.favoriteIndex
        if (b.score !== a.score)
            return b.score - a.score
        return String(a.entry.name).localeCompare(String(b.entry.name))
    })

    return ranked
}

function buildApplicationEntries(entries, queryValue, fuzzyEnabled, favoriteIds,
        hiddenIds, usageCounts, recentApplications, emptyQueryLimit) {
    return buildApplicationResults(
        entries, queryValue, fuzzyEnabled, favoriteIds, hiddenIds,
        usageCounts, recentApplications, emptyQueryLimit
    ).map(function(item) { return item.entry })
}

// App search primitives are shared with settings and other application lists.
function fuzzyScoreCore(text, query, fuzzyEnabled) {
    return ApplicationSearch.fuzzyScoreCore(text, query, fuzzyEnabled)
}

function valuesOf(value) {
    return ApplicationSearch.valuesOf(value)
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


function fuzzyScoreNative(text, query, fuzzyEnabled) {
    return ApplicationSearch.fuzzyScoreNative(text, query, fuzzyEnabled)
}

function fuzzyScore(text, query, fuzzyEnabled) {
    return ApplicationSearch.fuzzyScore(text, query, fuzzyEnabled)
}
