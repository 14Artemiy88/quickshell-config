.pragma library

.import "LauncherWallpaperPicker.js" as WallpaperPicker

var GENERATED_THEME_NAME = "Wallpaper Dynamic"

function parseQuery(value) {
    var query = String(value === undefined || value === null ? "" : value).trim()
    var command = /^(?:scheme|schemes|theme|themes|color-scheme|colour-scheme|палитра|тема|темы)(?:\s+|$)/i.exec(query)
    if (!command)
        return { active: false, query: "" }

    var remainder = query.slice(command[0].length).trim()
    var dynamic = /^(?:dynamic|wallpaper|обои|динамика|динамическая)(?:\s+|$)/i.exec(remainder)
    if (!dynamic)
        return { active: false, query: "" }

    return { active: true, query: remainder.slice(dynamic[0].length).trim() }
}

function latestWallpaperForScreen(data, screenName) {
    var recent = WallpaperPicker.recentUsageForScreen(data, screenName)
    if (!recent.length)
        return null
    var item = recent[0]
    if (!WallpaperPicker.isValidLocalImagePath(item.path))
        return null
    return {
        path: item.path,
        screenName: String(item.screenName || screenName || ""),
        count: Math.max(1, Math.floor(Number(item.count) || 1)),
        lastUsed: Math.max(0, Number(item.lastUsed) || 0)
    }
}

function buildResults(data, screenName, busy, error, query, scoreFunction) {
    var source = latestWallpaperForScreen(data, screenName)
    var screen = String(screenName || "этот монитор")
    var needle = String(query || "").trim().toLowerCase()

    // Processing is reported through the shared Notifications module, not as
    // a transient row in the Launcher action palette.
    if (busy)
        return []

    if (error) {
        return [{
            kind: "dynamicSchemeError",
            name: "Не удалось создать динамическую тему",
            description: String(error)
        }, {
            kind: "dynamicSchemeWallpaperAction",
            name: "Открыть выбор обоев",
            description: "Выберите изображение в Wallpaper Picker и установите его для нужного монитора"
        }]
    }

    if (!source) {
        return [{
            kind: "dynamicSchemeUnavailable",
            name: "Нет сохранённых обоев для " + screen,
            description: "Сначала установите изображение через >wallpaper на этом мониторе"
        }, {
            kind: "dynamicSchemeWallpaperAction",
            name: "Открыть выбор обоев",
            description: "Выберите изображение и установите его для нужного монитора"
        }]
    }

    var fileName = source.path.slice(source.path.lastIndexOf("/") + 1)
    var matchScore = needle && typeof scoreFunction === "function"
        ? Number(scoreFunction(fileName, needle)) : (needle ? (fileName.toLowerCase().indexOf(needle) >= 0 ? 1 : -1) : 0)
    if (needle && (!isFinite(matchScore) || matchScore < 0)) {
        return [{
            kind: "dynamicSchemeUnavailable",
            name: "Последние обои не совпадают с запросом",
            description: fileName + " · монитор " + source.screenName
        }, {
            kind: "dynamicSchemeWallpaperAction",
            name: "Открыть выбор обоев",
            description: "Установите нужное изображение и повторите >scheme dynamic"
        }]
    }

    return [{
        kind: "dynamicSchemeGenerate",
        name: "Создать тему из " + fileName,
        description: "Источник: " + source.screenName + " · Matugen · только меняет цвета оболочки",
        path: source.path,
        screenName: source.screenName,
        usageCount: source.count,
        score: Number.isFinite(matchScore) ? matchScore : 0
    }]
}

function matugenHex(value) {
    if (typeof value === "string")
        return value
    if (value && typeof value === "object" && typeof value.color === "string")
        return value.color
    return ""
}

function isHexColor(value) {
    return /^#[0-9a-f]{6}$/i.test(matugenHex(value))
}

function alphaColor(color, alpha) {
    var value = String(color || "")
    if (!isHexColor(value))
        return ""
    return "#" + String(alpha).toLowerCase() + value.slice(1).toLowerCase()
}

function copyObject(source) {
    var result = {}
    if (!source || typeof source !== "object")
        return result
    for (var key in source) {
        if (Object.prototype.hasOwnProperty.call(source, key))
            result[key] = source[key]
    }
    return result
}

function extractJson(output) {
    var text = String(output === undefined || output === null ? "" : output).trim()
    var first = text.indexOf("{")
    var last = text.lastIndexOf("}")
    if (first < 0 || last <= first)
        return null
    try {
        return JSON.parse(text.slice(first, last + 1))
    } catch (error) {
        return null
    }
}

function buildPaletteFromMatugen(output, basePalette, colorNames) {
    var parsed = extractJson(output)
    if (!parsed || !parsed.colors || typeof parsed.colors !== "object")
        return { ok: false, error: "Matugen вернул некорректный JSON палитры." }

    // Matugen <= 3 emits mode-first JSON: colors.dark.primary.
    // Matugen 4+ emits token-first JSON: colors.primary.dark.color.
    // Normalize both formats before mapping Material roles into our palette.
    var tokens = parsed.colors.dark || parsed.colors.amoled
    if (!tokens || typeof tokens !== "object") {
        var modernTokens = {}
        for (var colorName in parsed.colors) {
            if (!Object.prototype.hasOwnProperty.call(parsed.colors, colorName))
                continue
            var colorEntry = parsed.colors[colorName]
            if (!colorEntry || typeof colorEntry !== "object")
                continue
            var darkEntry = colorEntry.dark !== undefined ? colorEntry.dark : colorEntry.amoled
            if (darkEntry !== undefined)
                modernTokens[colorName] = darkEntry
        }
        if (Object.keys(modernTokens).length > 0)
            tokens = modernTokens
    }
    if (!tokens || typeof tokens !== "object")
        return { ok: false, error: "В ответе Matugen отсутствует тёмная цветовая схема. Получен неизвестный формат JSON." }

    var result = copyObject(basePalette)
    var requiredTokens = ["primary", "secondary", "tertiary", "error", "background", "surface", "on_background", "on_surface", "on_surface_variant", "outline", "outline_variant"]
    for (var i = 0; i < requiredTokens.length; ++i) {
        if (!isHexColor(tokens[requiredTokens[i]]))
            return { ok: false, error: "В палитре Matugen отсутствует цвет: " + requiredTokens[i] }
    }

    function token(name, fallback) {
        var value = matugenHex(tokens[name])
        return isHexColor(value) ? String(value).toLowerCase() : fallback
    }
    function alpha(name, prefix, fallback) {
        return alphaColor(token(name, fallback), prefix) || fallback
    }

    var primary = token("primary", result.accent)
    var secondary = token("secondary", primary)
    var tertiary = token("tertiary", secondary)
    var errorColor = token("error", tertiary)
    var background = token("background", result.black)
    var surface = token("surface", background)
    var surfaceVariant = token("surface_variant", token("outline_variant", surface))
    var onBackground = token("on_background", result.text)
    var onSurfaceVariant = token("on_surface_variant", result.textMuted)
    var outline = token("outline", result.textDisabled)
    var outlineVariant = token("outline_variant", result.textDim)

    result.baseColor = token("secondary_container", surfaceVariant)
    result.accent = primary
    result.currentWeather = tertiary
    result.background = alphaColor(background, "4d")
    result.text = onBackground
    result.textMuted = onSurfaceVariant
    result.textDim = outlineVariant
    result.textDisabled = outline
    result.black = background
    result.calendarBackground = alphaColor(background, "cc")
    // Settings background, player tracks/fill and top-app bars are independent
    // user-tuned colors; SettingsThemeManager preserves their current values.
    result.settingsBorder = primary
    result.settingsSubheading = onSurfaceVariant
    result.playerOverlay = alphaColor(surface, "26")
    result.activeNetworkBackground = alpha("secondary_container", "1a", surfaceVariant)
    result.volumeTrack = alphaColor(surfaceVariant, "99")
    result.volumeFill = primary

    var cpuColors = [
        errorColor,
        token("tertiary_container", tertiary),
        secondary,
        primary,
        token("inverse_primary", primary),
        token("secondary_container", secondary),
        token("primary_container", primary),
        token("tertiary", tertiary)
    ]
    for (var c = 0; c < 8; ++c) {
        result["cpu" + (c + 1)] = cpuColors[c]
        result["cpu" + (c + 1) + "Track"] = alphaColor(surfaceVariant, "4d")
    }
    result.ram = secondary
    result.ramTrack = alphaColor(secondary, "4d")
    result.metricTrack = alphaColor(surfaceVariant, "4d")
    result.networkUpload = secondary
    result.networkDownload = errorColor
    result.tempHot = errorColor
    result.tempWarm = token("error_container", tertiary)
    result.tempMild = secondary
    result.tempCool = tertiary
    result.tempZero = onBackground
    result.tempCold = primary
    result.tempVeryCold = token("tertiary_container", tertiary)
    result.tempFreezing = token("primary_container", primary)
    var names = Array.isArray(colorNames) ? colorNames : []
    for (var j = 0; j < names.length; ++j) {
        var name = String(names[j])
        if (result[name] === undefined || result[name] === null || String(result[name]).trim() === "")
            return { ok: false, error: "Не удалось сформировать цвет темы: " + name }
    }

    return { ok: true, palette: result, sourceColor: token("source_color", primary) }
}
