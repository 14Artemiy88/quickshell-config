.pragma library

function normalize(value) {
    return String(value === undefined || value === null ? "" : value)
        .replace(/([a-zа-я0-9])([A-ZА-Я])/g, "$1 $2")
        .toLocaleLowerCase()
        .replace(/ё/g, "е")
        .replace(/[^a-zа-я0-9]+/g, " ")
        .replace(/\s+/g, " ")
        .trim()
}

function words(value) {
    var normalized = normalize(value)
    return normalized.length > 0 ? normalized.split(" ") : []
}

function humanizeKey(key) {
    var text = String(key || "")
        .replace(/([a-zа-я0-9])([A-ZА-Я])/g, "$1 $2")
        .replace(/[._-]+/g, " ")
        .replace(/\s+/g, " ")
        .trim()
    if (text.length === 0)
        return ""
    return text.charAt(0).toLocaleUpperCase() + text.slice(1)
}

function keyTerms(key) {
    var text = String(key || "").replace(/([a-zа-я0-9])([A-ZА-Я])/g, "$1 $2")
    var normalized = normalize(text)
    var aliases = []
    var rules = [
        { pattern: /blur|размыт/, terms: "блюр размытие прозрачность" },
        { pattern: /background|фон/, terms: "фон задний фон подложка background" },
        { pattern: /font|шрифт/, terms: "шрифт гарнитура типографика текст" },
        { pattern: /color|цвет/, terms: "цвет окраска палитра" },
        { pattern: /animat|анимац/, terms: "анимация движение появление исчезновение" },
        { pattern: /duration|длитель/, terms: "длительность время скорость" },
        { pattern: /spacing|padding|margin|отступ|интервал/, terms: "отступ интервал расстояние промежуток" },
        { pattern: /width|ширин/, terms: "ширина размер горизонтальный" },
        { pattern: /height|высот/, terms: "высота размер вертикальный" },
        { pattern: /position|geometry|coordinate|координат|положен|размещ/, terms: "положение размещение координаты позиция экран" },
        { pattern: /network|сеть/, terms: "сеть интернет wi fi wifi подключение" },
        { pattern: /weather|погод/, terms: "погода температура прогноз ветер" },
        { pattern: /volume|громк/, terms: "громкость звук аудио поток" },
        { pattern: /calendar|календар/, terms: "календарь дата событие заметка" },
        { pattern: /timer|таймер/, terms: "таймер время обратный отсчет" },
        { pattern: /icon|икон/, terms: "иконка значок символ glyph" },
        { pattern: /opacity|прозрач/, terms: "прозрачность непрозрачность альфа" }
    ]
    for (var i = 0; i < rules.length; ++i) {
        if (rules[i].pattern.test(normalized))
            aliases.push(rules[i].terms)
    }
    return [normalized].concat(aliases).join(" ")
}

function search(entries, query, limit) {
    var queryText = normalize(query)
    var queryWords = words(queryText)
    if (queryWords.length === 0)
        return []

    var matches = []
    var cap = Number(limit)
    if (!isFinite(cap) || cap < 1)
        cap = 8

    for (var i = 0; i < entries.length; ++i) {
        var entry = entries[i]
        var fullText = normalize(entry.searchText || "")
        var label = normalize(entry.label || "")
        var key = normalize(entry.keyTerms || "")
        var valid = true
        var score = 0

        if (label === queryText)
            score += 120
        else if (label.indexOf(queryText) === 0)
            score += 80
        else if (label.indexOf(queryText) >= 0)
            score += 55

        for (var w = 0; w < queryWords.length; ++w) {
            var token = queryWords[w]
            if (fullText.indexOf(token) < 0) {
                valid = false
                break
            }
            if (label.indexOf(token) >= 0)
                score += 12
            else if (key.indexOf(token) >= 0)
                score += 5
            else
                score += 2
        }

        if (!valid)
            continue

        matches.push({ entry: entry, score: score, order: i })
    }

    matches.sort(function(a, b) {
        if (a.score !== b.score)
            return b.score - a.score
        return a.order - b.order
    })

    var result = []
    for (var j = 0; j < matches.length && j < cap; ++j)
        result.push(matches[j].entry)
    return result
}
