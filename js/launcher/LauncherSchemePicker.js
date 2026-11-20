.pragma library

function parseQuery(value) {
    var query = String(value || "").trim()
    var match = /^(?:scheme|schemes|theme|themes|color-scheme|colour-scheme|палитра|тема|темы)(?:\s+|$)/i.exec(query)
    if (!match)
        return { active: false, query: "" }
    return { active: true, query: query.slice(match[0].length).trim() }
}

function buildResults(query, names, activeName, previewProvider, descriptionProvider, scoreFunction, maxResults) {
    var needle = String(query || "").trim()
    var source = Array.isArray(names) ? names : []
    var active = String(activeName || "")
    var seen = Object.create(null)
    var results = []

    for (var i = 0; i < source.length; ++i) {
        var name = String(source[i] || "").trim()
        if (!name || seen[name])
            continue
        seen[name] = true

        var description = typeof descriptionProvider === "function"
            ? String(descriptionProvider(name) || "") : ""
        var score = needle === "" ? 0 : (typeof scoreFunction === "function"
            ? Number(scoreFunction(name + " " + description, needle)) : -1)
        if (needle !== "" && (!isFinite(score) || score < 0))
            continue

        var colors = typeof previewProvider === "function" ? previewProvider(name) : []
        results.push({
            kind: "scheme",
            name: name,
            description: description,
            colors: Array.isArray(colors) ? colors.slice(0, 6) : [],
            isActive: name === active,
            score: needle === "" ? 0 : score,
            order: i
        })
    }

    results.sort(function(a, b) {
        if (b.score !== a.score) return b.score - a.score
        if (needle === "" && a.isActive !== b.isActive) return a.isActive ? -1 : 1
        return a.order - b.order
    })

    var limit = Math.max(1, Math.floor(Number(maxResults) || 100))
    return results.slice(0, limit)
}
