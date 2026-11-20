.pragma library

// Stable IDs for commands exposed only through the Launcher's `>` palette.
// Disabling an entry hides its command shortcut; it never disables the tab or
// the feature itself.
var tabActions = [
    { id: "tab.apps", label: "Apps — Приложения" },
    { id: "tab.run", label: "Run — Команды" },
    { id: "tab.windows", label: "Windows — Окна" },
    { id: "tab.clipboard", label: "Clipboard — Буфер обмена" },
    { id: "tab.power", label: "Power — Питание" },
    { id: "tab.network", label: "Network — Сети" },
    { id: "tab.packages", label: "Packages — Пакеты Nix" },
    { id: "tab.pass", label: "Pass — Пароли" },
    { id: "tab.projects", label: "Projects — Проекты" },
    { id: "tab.calculator", label: "Calculator — Калькулятор" }
]

var toolActions = [
    { id: "tool.colorSchemes", label: "Color schemes — Цветовые темы" },
    { id: "tool.schemeVariants", label: "Scheme variants — Варианты Material You" },
    { id: "tool.wallpapers", label: "Wallpaper picker — Обои и случайный выбор" },
    { id: "tool.emoji", label: "Emoji picker — Эмодзи" },
    { id: "tool.wallpaperDynamic", label: "Wallpaper Dynamic — Динамическая тема" }
]

function knownIds() {
    var result = []
    var sources = [tabActions, toolActions]
    for (var s = 0; s < sources.length; ++s) {
        for (var i = 0; i < sources[s].length; ++i)
            result.push(sources[s][i].id)
    }
    return result
}

function normalizeDisabledIds(value) {
    var source = Array.isArray(value) ? value : []
    var known = knownIds()
    var result = []
    for (var i = 0; i < source.length; ++i) {
        var id = String(source[i] === undefined || source[i] === null ? "" : source[i]).trim()
        if (known.indexOf(id) >= 0 && result.indexOf(id) < 0)
            result.push(id)
    }
    return result
}

function isEnabled(disabledIds, actionId) {
    return normalizeDisabledIds(disabledIds).indexOf(String(actionId || "")) < 0
}

function setEnabled(disabledIds, actionId, enabled) {
    var id = String(actionId || "")
    var result = normalizeDisabledIds(disabledIds)
    if (knownIds().indexOf(id) < 0)
        return result
    var index = result.indexOf(id)
    if (enabled && index >= 0)
        result.splice(index, 1)
    else if (!enabled && index < 0)
        result.push(id)
    return result
}
