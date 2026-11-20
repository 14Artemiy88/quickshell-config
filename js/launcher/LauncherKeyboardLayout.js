.pragma library

// Physical key positions for the standard US QWERTY and Russian ЙЦУКЕН
// layouts. Search correction never changes the active system keyboard layout.
var LATIN_KEYS = "`qwertyuiop[]asdfghjkl;'zxcvbnm,./"
var CYRILLIC_KEYS = "ёйцукенгшщзхъфывапролджэячсмитьбю."
var ALTERNATE_LAYOUT_SCORE_PENALTY = 1200
var cachedLayoutQuery = null
var cachedLayoutAlternative = ""

function normalizeQuery(value) {
    return String(value === undefined || value === null ? "" : value)
        .toLowerCase()
        .trim()
}

function alternateLayoutQuery(value) {
    var query = normalizeQuery(value)
    if (query === "")
        return ""
    if (query === cachedLayoutQuery)
        return cachedLayoutAlternative

    var latinLetters = 0
    var cyrillicLetters = 0
    for (var i = 0; i < query.length; ++i) {
        var character = query[i]
        if (character >= "a" && character <= "z")
            latinLetters += 1
        else if ((character >= "а" && character <= "я") || character === "ё")
            cyrillicLetters += 1
    }

    var alternative = ""
    // Avoid interpreting mixed-language queries, short abbreviations, or
    // numeric-only input as a keyboard-layout mistake.
    if (latinLetters >= 3 && cyrillicLetters === 0) {
        for (var latinIndex = 0; latinIndex < query.length; ++latinIndex) {
            var latinCharacter = query[latinIndex]
            var latinKeyIndex = LATIN_KEYS.indexOf(latinCharacter)
            alternative += latinKeyIndex >= 0
                ? CYRILLIC_KEYS[latinKeyIndex]
                : latinCharacter
        }
    } else if (cyrillicLetters >= 3 && latinLetters === 0) {
        for (var cyrillicIndex = 0; cyrillicIndex < query.length; ++cyrillicIndex) {
            var cyrillicCharacter = query[cyrillicIndex]
            var cyrillicKeyIndex = CYRILLIC_KEYS.indexOf(cyrillicCharacter)
            alternative += cyrillicKeyIndex >= 0
                ? LATIN_KEYS[cyrillicKeyIndex]
                : cyrillicCharacter
        }
    }

    cachedLayoutQuery = query
    cachedLayoutAlternative = alternative !== query ? alternative : ""
    return cachedLayoutAlternative
}

function scoreWithLayout(text, query, scorer, penalty) {
    if (typeof scorer !== "function")
        return -1

    var normalizedQuery = normalizeQuery(query)
    var directScore = scorer(text, normalizedQuery)
    var alternateQuery = alternateLayoutQuery(normalizedQuery)
    if (alternateQuery === "")
        return directScore

    var alternateScore = scorer(text, alternateQuery)
    if (alternateScore < 0)
        return directScore

    var appliedPenalty = Number.isFinite(Number(penalty))
        ? Math.max(0, Number(penalty))
        : ALTERNATE_LAYOUT_SCORE_PENALTY
    return Math.max(directScore, Math.max(0, alternateScore - appliedPenalty))
}

function bestMatchingQuery(text, query, scorer, penalty) {
    if (typeof scorer !== "function")
        return normalizeQuery(query)

    var normalizedQuery = normalizeQuery(query)
    var alternateQuery = alternateLayoutQuery(normalizedQuery)
    if (alternateQuery === "")
        return normalizedQuery

    var directScore = scorer(text, normalizedQuery)
    var alternateScore = scorer(text, alternateQuery)
    var appliedPenalty = Number.isFinite(Number(penalty))
        ? Math.max(0, Number(penalty))
        : ALTERNATE_LAYOUT_SCORE_PENALTY

    return alternateScore >= 0 && Math.max(0, alternateScore - appliedPenalty) > directScore
        ? alternateQuery
        : normalizedQuery
}
