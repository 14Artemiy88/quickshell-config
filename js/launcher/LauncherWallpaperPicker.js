.pragma library

var MAX_WALLPAPERS = 300
var MAX_WALLPAPER_USAGE = 100
var MAX_RECENT_WALLPAPERS = 12
var IMAGE_EXTENSION_PATTERN = /\.(?:jpe?g|png|webp|avif|bmp|gif)$/i

function isValidLocalImagePath(value) {
    var path = String(value === undefined || value === null ? "" : value).trim()
    if (!path || path === "/" || path.charAt(0) !== "/" || path.charAt(path.length - 1) === "/")
        return false
    var fileName = path.slice(path.lastIndexOf("/") + 1)
    if (!fileName || fileName === "." || fileName === "..")
        return false
    return IMAGE_EXTENSION_PATTERN.test(fileName)
}

function localFileUrl(value) {
    var path = String(value === undefined || value === null ? "" : value).trim()
    if (!isValidLocalImagePath(path))
        return ""
    var parts = path.split("/")
    for (var i = 0; i < parts.length; ++i)
        parts[i] = encodeURIComponent(parts[i])
    return "file://" + parts.join("/")
}

function normalize(value) {
    return String(value === undefined || value === null ? "" : value)
        .toLowerCase()
        .trim()
}

function parseQuery(value) {
    var query = String(value === undefined || value === null ? "" : value).trim()
    var match = /^(?:wallpaper|wallpapers|обои)(?:\s+|$)/i.exec(query)
    if (!match)
        return { active: false, query: "", scope: "all" }

    var remainder = query.slice(match[0].length).trim()
    var firstSpace = remainder.search(/\s/)
    var firstToken = firstSpace < 0 ? remainder : remainder.slice(0, firstSpace)
    var token = normalize(firstToken)
    var scope = "all"
    var scopedAliases = {
        favorites: "favorites", favorite: "favorites", fav: "favorites", starred: "favorites",
        "избранное": "favorites", "избранные": "favorites",
        recent: "recent", recents: "recent", recently: "recent", history: "recent", used: "recent",
        "недавние": "recent", "последние": "recent", "история": "recent"
    }
    if (scopedAliases[token]) {
        scope = scopedAliases[token]
        remainder = firstSpace < 0 ? "" : remainder.slice(firstSpace).trim()
    }
    return { active: true, query: remainder, scope: scope }
}

function displayName(value) {
    var name = String(value === undefined || value === null ? "" : value)
    return name.replace(/\.(?:jpe?g|png|webp|avif|bmp|gif)$/i, "")
}

function normalizeEntries(value) {
    var source = Array.isArray(value) ? value : []
    var result = []
    var seen = Object.create(null)
    for (var i = 0; i < source.length && result.length < MAX_WALLPAPERS; ++i) {
        var item = source[i]
        if (!item || typeof item !== "object")
            continue
        var path = String(item.path === undefined || item.path === null ? "" : item.path).trim()
        // Catalog entries must be absolute image files, never the selected
        // directory itself (which QQuickImage would try to load as file:///).
        if (!isValidLocalImagePath(path) || seen["$" + path])
            continue
        var name = String(item.name === undefined || item.name === null ? "" : item.name).trim()
        if (!name)
            name = path.slice(path.lastIndexOf("/") + 1)
        seen["$" + path] = true
        result.push({ path: path, name: name, displayName: displayName(name) })
    }
    result.sort(function(a, b) {
        var order = a.displayName.localeCompare(b.displayName)
        return order !== 0 ? order : a.path.localeCompare(b.path)
    })
    return result
}

function emptyData() {
    return { version: 1, favorites: [], usage: [] }
}

function normalizeData(value) {
    var source = value && typeof value === "object" ? value : {}
    var favorites = []
    var favoriteSeen = Object.create(null)
    var rawFavorites = Array.isArray(source.favorites) ? source.favorites : []
    for (var i = 0; i < rawFavorites.length && favorites.length < MAX_WALLPAPERS; ++i) {
        var path = String(rawFavorites[i] === undefined || rawFavorites[i] === null ? "" : rawFavorites[i]).trim()
        if (!isValidLocalImagePath(path) || favoriteSeen["$" + path])
            continue
        favoriteSeen["$" + path] = true
        favorites.push(path)
    }

    var usage = []
    var usageByKey = Object.create(null)
    var rawUsage = Array.isArray(source.usage) ? source.usage : []
    for (var j = 0; j < rawUsage.length; ++j) {
        var entry = rawUsage[j]
        if (!entry || typeof entry !== "object")
            continue
        var usagePath = String(entry.path === undefined || entry.path === null ? "" : entry.path).trim()
        var screen = String(entry.screenName === undefined || entry.screenName === null ? "" : entry.screenName).trim()
        var count = Math.max(0, Math.floor(Number(entry.count) || 0))
        var lastUsed = Math.max(0, Number(entry.lastUsed) || 0)
        if (!isValidLocalImagePath(usagePath) || !screen || count < 1 || lastUsed <= 0)
            continue
        var key = usagePath + "\n" + screen.toLowerCase()
        var normalized = { path: usagePath, screenName: screen, count: count, lastUsed: lastUsed }
        var old = usageByKey["$" + key]
        if (!old || normalized.lastUsed > old.lastUsed || (normalized.lastUsed === old.lastUsed && normalized.count > old.count))
            usageByKey["$" + key] = normalized
    }
    Object.keys(usageByKey).forEach(function(key) { usage.push(usageByKey[key]) })
    usage.sort(function(a, b) { return b.lastUsed - a.lastUsed })
    if (usage.length > MAX_WALLPAPER_USAGE)
        usage = usage.slice(0, MAX_WALLPAPER_USAGE)

    return { version: 1, favorites: favorites, usage: usage }
}

function parseData(contents) {
    try {
        return normalizeData(JSON.parse(String(contents === undefined || contents === null ? "" : contents)))
    } catch (error) {
        return emptyData()
    }
}

function serializeData(value) {
    var normalized = normalizeData(value)
    return JSON.stringify(normalized)
}

function toggleFavorite(value, path) {
    var data = normalizeData(value)
    var wanted = String(path === undefined || path === null ? "" : path).trim()
    if (!isValidLocalImagePath(wanted))
        return data
    var result = []
    var found = false
    for (var i = 0; i < data.favorites.length; ++i) {
        if (data.favorites[i] === wanted) {
            found = true
            continue
        }
        result.push(data.favorites[i])
    }
    if (!found)
        result.unshift(wanted)
    return normalizeData({ version: 1, favorites: result, usage: data.usage })
}

function recordUsage(value, path, screenNameValue, timestamp) {
    var data = normalizeData(value)
    var wanted = String(path === undefined || path === null ? "" : path).trim()
    var screen = String(screenNameValue === undefined || screenNameValue === null ? "" : screenNameValue).trim()
    var time = Math.max(0, Number(timestamp) || 0)
    if (!isValidLocalImagePath(wanted) || !screen || time <= 0)
        return data
    var key = wanted + "\n" + screen.toLowerCase()
    var nextUsage = []
    var nextCount = 1
    for (var i = 0; i < data.usage.length; ++i) {
        var item = data.usage[i]
        if ((item.path + "\n" + item.screenName.toLowerCase()) === key) {
            nextCount = item.count + 1
            continue
        }
        nextUsage.push(item)
    }
    nextUsage.unshift({ path: wanted, screenName: screen, count: nextCount, lastUsed: time })
    return normalizeData({ version: 1, favorites: data.favorites, usage: nextUsage })
}

function applyMutations(value, mutations) {
    var data = normalizeData(value)
    var changes = Array.isArray(mutations) ? mutations : []
    for (var i = 0; i < changes.length; ++i) {
        var mutation = changes[i] || {}
        var type = String(mutation.type || "")
        if (type === "toggleFavorite")
            data = toggleFavorite(data, mutation.path)
        else if (type === "recordUsage")
            data = recordUsage(data, mutation.path, mutation.screenName, mutation.timestamp)
    }
    return data
}

function isFavorite(value, path) {
    var data = normalizeData(value)
    var wanted = String(path === undefined || path === null ? "" : path)
    return data.favorites.indexOf(wanted) !== -1
}

function recentUsageForScreen(value, screenNameValue) {
    var data = normalizeData(value)
    var wanted = String(screenNameValue === undefined || screenNameValue === null ? "" : screenNameValue).trim().toLowerCase()
    if (!wanted)
        return []
    return data.usage.filter(function(item) {
        return item.screenName.toLowerCase() === wanted
    }).sort(function(a, b) { return b.lastUsed - a.lastUsed }).slice(0, MAX_RECENT_WALLPAPERS)
}

function buildResults(query, entries, scoreFunction, maxResults, storedData, scopeValue, screenNameValue) {
    var normalizedQuery = normalize(query)
    var catalog = normalizeEntries(entries)
    var data = normalizeData(storedData)
    var scope = String(scopeValue || "all")
    if (scope !== "favorites" && scope !== "recent") scope = "all"
    var favoriteIndexes = Object.create(null)
    for (var fi = 0; fi < data.favorites.length; ++fi)
        favoriteIndexes["$" + data.favorites[fi]] = fi
    var recentEntries = recentUsageForScreen(data, screenNameValue)
    var recentByPath = Object.create(null)
    for (var ri = 0; ri < recentEntries.length; ++ri)
        recentByPath["$" + recentEntries[ri].path] = recentEntries[ri]

    var recentSet = Object.create(null)
    if (scope === "recent") {
        for (var rj = 0; rj < recentEntries.length; ++rj)
            recentSet["$" + recentEntries[rj].path] = true
    }

    var matches = []
    var limit = Math.max(1, Math.min(MAX_WALLPAPERS, Math.floor(Number(maxResults) || MAX_WALLPAPERS)))
    for (var i = 0; i < catalog.length; ++i) {
        var item = catalog[i]
        var favoriteIndex = Object.prototype.hasOwnProperty.call(favoriteIndexes, "$" + item.path)
            ? favoriteIndexes["$" + item.path] : -1
        var usage = recentByPath["$" + item.path] || null
        if (scope === "favorites" && favoriteIndex < 0)
            continue
        if (scope === "recent" && !recentSet["$" + item.path])
            continue

        var score = 0
        if (normalizedQuery !== "") {
            if (typeof scoreFunction !== "function")
                continue
            var displayScore = Number(scoreFunction(item.displayName, normalizedQuery))
            var fileScore = Number(scoreFunction(item.name, normalizedQuery))
            if (!isFinite(displayScore)) displayScore = -1
            if (!isFinite(fileScore)) fileScore = -1
            score = Math.max(displayScore, fileScore)
            if (score < 0)
                continue
        }
        matches.push({
            kind: "wallpaper",
            path: item.path,
            fileName: item.name,
            name: item.displayName,
            score: score,
            order: i,
            isFavorite: favoriteIndex >= 0,
            favoriteOrder: favoriteIndex,
            usageCount: usage ? usage.count : 0,
            lastUsed: usage ? usage.lastUsed : 0,
            recentOnSelectedScreen: !!usage
        })
    }

    matches.sort(function(a, b) {
        if (normalizedQuery !== "" && b.score !== a.score)
            return b.score - a.score
        if (scope === "favorites" && a.favoriteOrder !== b.favoriteOrder)
            return a.favoriteOrder - b.favoriteOrder
        if (scope === "recent" && b.lastUsed !== a.lastUsed)
            return b.lastUsed - a.lastUsed
        if (scope === "all") {
            if (a.isFavorite !== b.isFavorite) return a.isFavorite ? -1 : 1
            if (a.isFavorite && b.isFavorite && a.favoriteOrder !== b.favoriteOrder)
                return a.favoriteOrder - b.favoriteOrder
            if ((a.lastUsed > 0) !== (b.lastUsed > 0)) return a.lastUsed > 0 ? -1 : 1
            if (a.lastUsed > 0 && b.lastUsed > 0 && a.lastUsed !== b.lastUsed)
                return b.lastUsed - a.lastUsed
        }
        return a.order - b.order
    })
    return matches.slice(0, limit)
}


function screenName(screen, index) {
    if (!screen || typeof screen !== "object")
        return "Screen " + (Number(index) + 1)
    var name = String(screen.name === undefined || screen.name === null ? "" : screen.name).trim()
    if (name) return name
    var model = String(screen.model === undefined || screen.model === null ? "" : screen.model).trim()
    return model || ("Screen " + (Number(index) + 1))
}

function screenIndex(screens, selectedName) {
    var wanted = String(selectedName === undefined || selectedName === null ? "" : selectedName).trim().toLowerCase()
    if (!screens || !wanted) return -1
    for (var i = 0; i < screens.length; ++i) {
        var screen = screens[i]
        if (screenName(screen, i).toLowerCase() === wanted)
            return i
    }
    return -1
}

function moveGridIndex(currentIndex, direction, columns, count) {
    var total = Math.max(0, Math.floor(Number(count) || 0))
    var cols = Math.max(1, Math.floor(Number(columns) || 1))
    var current = Math.floor(Number(currentIndex))
    if (!total || !isFinite(current) || current < 0 || current >= total)
        return -1

    var row = Math.floor(current / cols)
    var column = current % cols
    var targetRow = row
    var targetColumn = column
    switch (String(direction || "").toLowerCase()) {
    case "left": targetColumn -= 1; break
    case "right": targetColumn += 1; break
    case "up": targetRow -= 1; break
    case "down": targetRow += 1; break
    default: return current
    }

    var rowCount = Math.ceil(total / cols)
    if (targetRow < 0 || targetRow >= rowCount)
        return current
    var itemsInTargetRow = Math.min(cols, total - targetRow * cols)
    if (targetColumn < 0 || targetColumn >= cols)
        return current
    // When moving vertically into a shorter final row, select its last tile.
    if (targetColumn >= itemsInTargetRow)
        targetColumn = itemsInTargetRow - 1
    var target = targetRow * cols + targetColumn
    return target >= 0 && target < total ? target : current
}

function emptyStateMessage(loading, error, directory, hasEntries, query, scopeValue, screenNameValue) {
    var scope = String(scopeValue || "all")
    if (loading)
        return "Загружаем обои…"
    if (String(error || "") === "directory-not-found")
        return "Папка с обоями не найдена: " + String(directory || "") + "\nУкажите существующую папку в настройках Launcher."
    if (String(error || "") !== "")
        return "Не удалось прочитать каталог обоев. Проверьте права доступа к папке."
    if (scope === "favorites")
        return normalize(query) !== ""
            ? "Среди избранных обоев нет совпадений."
            : "Избранных обоев в этой папке пока нет. Нажмите ☆ на плитке, чтобы добавить изображение."
    if (scope === "recent")
        return normalize(query) !== ""
            ? "Среди недавно установленных обоев нет совпадений для этого экрана."
            : "На экране " + String(screenNameValue || "") + " пока нет недавно установленных обоев."
    if (Number(hasEntries) > 0 && normalize(query) !== "")
        return "По этому запросу обои не найдены. Попробуйте другое название."
    return "В выбранной папке пока нет изображений. Поддерживаются JPG, PNG, WebP, AVIF, BMP и GIF."
}

