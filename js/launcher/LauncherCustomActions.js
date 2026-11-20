.pragma library

function normalizeText(value) {
    return String(value === undefined || value === null ? "" : value)
        .toLowerCase()
        .trim()
}

function buildResults(source, query, scoreFunction, orderOffset, includeEmptyQuery) {
    var normalizedQuery = normalizeText(query)
    if (!normalizedQuery && includeEmptyQuery !== true)
        return []
    if (typeof scoreFunction !== "function")
        return []

    var actions = Array.isArray(source) ? source : []
    var results = []
    var offset = Number(orderOffset) || 0

    for (var i = 0; i < actions.length; ++i) {
        var action = actions[i]
        if (!action || typeof action !== "object" || action.enabled === false)
            continue

        var name = String(action.name || "").trim()
        var command = String(action.command || "").trim()
        if (!name || !command)
            continue

        var description = String(action.description || "").trim()
        var terms = [name, description, command]
        var score = normalizedQuery ? -1 : 0
        for (var j = 0; j < terms.length; ++j) {
            if (!terms[j]) continue
            if (normalizedQuery)
                score = Math.max(score, Number(scoreFunction(terms[j], normalizedQuery)))
        }
        if (score < 0)
            continue

        results.push({
            kind: "customAction",
            actionId: String(action.id || "custom-" + String(i + 1)),
            name: name,
            icon: String(action.icon || "󰌌"),
            description: description || "Пользовательское действие",
            command: command,
            score: score,
            order: offset + i
        })
    }

    return results
}
