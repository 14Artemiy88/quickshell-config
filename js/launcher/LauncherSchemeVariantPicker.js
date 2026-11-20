.pragma library

var DEFAULT_VARIANT = "scheme-tonal-spot"
var variants = [
    { id: "scheme-tonal-spot", name: "Tonal Spot", description: "Сбалансированная палитра с умеренным акцентом", aliases: ["tonal", "tonal spot", "default", "сбалансированная", "тональная"] },
    { id: "scheme-content", name: "Content", description: "Палитра, сохраняющая характер цветов изображения", aliases: ["content", "содержание", "по содержимому"] },
    { id: "scheme-expressive", name: "Expressive", description: "Более выразительная и разнообразная палитра", aliases: ["expressive", "выразительная", "экспрессивная"] },
    { id: "scheme-fidelity", name: "Fidelity", description: "Палитра, ориентированная на исходный цвет", aliases: ["fidelity", "точность", "верная"] },
    { id: "scheme-fruit-salad", name: "Fruit Salad", description: "Палитра с дополнительным контрастом оттенков", aliases: ["fruit", "fruit salad", "фруктовая", "контрастная"] },
    { id: "scheme-monochrome", name: "Monochrome", description: "Монохромная палитра без цветового акцента", aliases: ["mono", "monochrome", "монохром", "чёрно-белая"] },
    { id: "scheme-neutral", name: "Neutral", description: "Сдержанная нейтральная палитра", aliases: ["neutral", "нейтральная", "спокойная"] },
    { id: "scheme-rainbow", name: "Rainbow", description: "Разноцветная палитра с широким спектром оттенков", aliases: ["rainbow", "радуга", "разноцветная"] }
]

function normalizeVariant(value) {
    var candidate = String(value === undefined || value === null ? "" : value).trim().toLowerCase()
    if (!candidate) return DEFAULT_VARIANT
    for (var i = 0; i < variants.length; ++i) {
        var item = variants[i]
        if (candidate === item.id || candidate === item.name.toLowerCase()) return item.id
        for (var a = 0; a < item.aliases.length; ++a) {
            if (candidate === String(item.aliases[a]).toLowerCase()) return item.id
        }
    }
    return ""
}

function parseQuery(value) {
    var query = String(value === undefined || value === null ? "" : value).trim()

    // Canonical command: >scheme variants. Keep the previous >variant form
    // as an alias so existing habits and saved snippets continue to work.
    var schemeCommand = /^(?:scheme|schemes|theme|themes|color-scheme|colour-scheme|палитра|тема|темы)(?:\s+|$)/i.exec(query)
    if (schemeCommand) {
        var remainder = query.slice(schemeCommand[0].length).trim()
        var variantCommand = /^(?:variant|variants|scheme-variant|scheme-variants|style|styles|вариант|варианты|стиль|стили)(?:\s+|$)/i.exec(remainder)
        if (!variantCommand) return { active: false, query: "" }
        return { active: true, query: remainder.slice(variantCommand[0].length).trim() }
    }

    var legacyCommand = /^(?:variant|variants|scheme-variant|scheme-variants|style|styles|вариант|варианты|стиль|стили)(?:\s+|$)/i.exec(query)
    if (!legacyCommand) return { active: false, query: "" }
    return { active: true, query: query.slice(legacyCommand[0].length).trim() }
}

function buildResults(query, activeVariant, scoreFunction, maxResults) {
    var needle = String(query || "").trim()
    var active = normalizeVariant(activeVariant)
    var results = []
    for (var i = 0; i < variants.length; ++i) {
        var item = variants[i]
        var text = [item.name, item.id.replace(/^scheme-/, "").replace(/-/g, " "), item.description]
            .concat(item.aliases).join(" ")
        var score = needle === "" ? 0 : (typeof scoreFunction === "function"
            ? Number(scoreFunction(text, needle)) : (text.toLowerCase().indexOf(needle.toLowerCase()) >= 0 ? 1 : -1))
        if (needle !== "" && (!isFinite(score) || score < 0)) continue
        results.push({
            kind: "schemeVariant",
            name: item.name,
            description: item.description,
            variant: item.id,
            isActive: item.id === active,
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

function isVariant(value) {
    return normalizeVariant(value) !== ""
}
