.pragma library

// Normalize untrusted JSON samples before they reach SegmentBarGraph. The
// daemon contract is a fixed history length of integer percentages; a malformed
// whole sample is rejected, while bad individual values become safe zeroes.
function normalizeHistory(values, expectedCount) {
    if (!Array.isArray(values) || !Number.isInteger(expectedCount) || expectedCount < 1)
        return null
    if (values.length !== expectedCount)
        return null

    var normalized = []
    for (var i = 0; i < values.length; i++) {
        var value = values[i]
        if (typeof value !== "number" || !isFinite(value))
            value = 0
        normalized.push(Math.max(0, Math.min(100, value)))
    }
    return normalized
}
