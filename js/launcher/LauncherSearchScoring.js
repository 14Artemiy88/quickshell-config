.pragma library

function normalizeText(value) {
    return String(value === undefined || value === null ? "" : value)
        .toLowerCase()
        .trim()
}

// Shared with Launcher Run search. The default path preserves its current
// scoring exactly; strict mode exits after exact/prefix/substring matches.
function fuzzyScore(text, query, fuzzyEnabled) {
    text = normalizeText(text)
    query = normalizeText(query)

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

    var score = 0
    var position = 0
    var previousMatch = -1

    for (var i = 0; i < query.length; ++i) {
        var found = text.indexOf(query[i], position)
        if (found === -1)
            return -1

        if (previousMatch >= 0) {
            var gap = found - previousMatch - 1
            score += gap === 0
                ? 500
                : Math.max(0, 200 - gap * 30)
        }

        if (
            found === 0 ||
            text[found - 1] === " " ||
            text[found - 1] === "/" ||
            text[found - 1] === "-" ||
            text[found - 1] === "_" ||
            text[found - 1] === "."
        ) {
            score += 300
        }

        score += Math.max(0, 200 - found * 10)
        previousMatch = found
        position = found + 1
    }

    return score
}

