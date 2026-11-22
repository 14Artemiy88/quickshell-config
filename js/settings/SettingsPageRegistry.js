.pragma library

// Stable settings page identities live here rather than in the rendering
// component. Keep these IDs aligned with Config/settings persistence IDs.
// Sidebar groups are presentation-only. Page IDs remain stable and keep their
// existing routes, profiles, reset scopes and user-customized labels.
var NAVIGATION_GROUPS = [
    { id: "appearance", label: "Внешний вид", symbol: "◈" },
    { id: "modules", label: "Модули", symbol: "▦" },
    { id: "dashboard", label: "Dashboard", symbol: "▣" },
    { id: "launcher", label: "Лаунчер", symbol: "⌕" },
    { id: "general", label: "Общие", symbol: "⚙" }
]

var TAB_DEFINITIONS = [
    { id: "modules", defaultLabel: "Включение модулей", groupId: "modules" },
    { id: "dashboard", defaultLabel: "Dashboard", groupId: "dashboard" },
    { id: "themes", defaultLabel: "Темы и цвета", groupId: "appearance" },
    { id: "general", defaultLabel: "Общие", groupId: "general" },
    { id: "timers", defaultLabel: "Таймеры", groupId: "modules" },
    { id: "player", defaultLabel: "Плеер", groupId: "modules" },
    { id: "mopidy", defaultLabel: "Mopidy", groupId: "modules" },
    { id: "weather", defaultLabel: "Погода", groupId: "modules" },
    { id: "cava", defaultLabel: "CAVA", groupId: "modules" },
    { id: "cpuRam", defaultLabel: "CPU/RAM", groupId: "modules" },
    { id: "network", defaultLabel: "Сеть", groupId: "modules" },
    { id: "volume", defaultLabel: "Громкость", groupId: "modules" },
    { id: "calendar", defaultLabel: "Календарь", groupId: "modules" },
    { id: "launcher", defaultLabel: "Общее", groupId: "launcher" },
    { id: "launcherSearch", defaultLabel: "Поиск", groupId: "launcher" },
    { id: "launcherTabs", defaultLabel: "Вкладки", groupId: "launcher" },
    { id: "launcherProjects", defaultLabel: "Проекты", groupId: "launcher" },
    { id: "launcherActions", defaultLabel: "Действия", groupId: "launcher" },
    { id: "launcherAnimation", defaultLabel: "Анимация", groupId: "launcher" },
    { id: "launcherApplications", defaultLabel: "Приложения", groupId: "launcher" },
    { id: "notifications", defaultLabel: "Уведомления", groupId: "modules" },
    { id: "settingsWindow", defaultLabel: "Окно настроек", groupId: "appearance" }
]

// Page IDs are the canonical route identity. Array order is only presentation metadata.
var OTHER_PAGE_DEFINITIONS = [
    { id: "dashboard", saveScope: "dashboard", subTabs: [] },
    { id: "general", saveScope: "general", subTabs: ["Интерфейс", "Профили", "Хранилища"] },
    { id: "timers", saveScope: "timer", subTabs: ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации", "Опции таймера"] },
    { id: "player", saveScope: "player", subTabs: ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон", "Анимация"] },
    { id: "weather", saveScope: "weather", subTabs: ["Общие", "Сейчас", "По часам", "По дням", "Анимация"] },
    { id: "cava", saveScope: "cava", subTabs: ["Основные", "Полосы", "Анимация"] },
    { id: "cpuRam", saveScope: "cpu", subTabs: ["Общие", "График CPU", "Top Apps", "Анимация CPU"] },
    { id: "network", saveScope: "network", subTabs: ["Обновления", "Сеть", "Анимация"] },
    { id: "volume", saveScope: "volume", subTabs: ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность", "Анимация"] },
    { id: "calendar", saveScope: "calendar", subTabs: ["Разметка", "Цвета", "Метки заметок", "Анимации"] },
    { id: "settingsWindow", saveScope: "settingsWindow", subTabs: ["Интерфейс", "Окно настроек", "Вкладки"] },
    { id: "mopidy", saveScope: "mopidy", subTabs: ["Общее", "Время", "Иконки", "Пусто и недоступен", "Анимация"] },
    { id: "launcher", saveScope: "launcher", subTabs: ["Общее", "Навигация", "Оформление", "Поиск"] },
    { id: "launcherSearch", saveScope: "launcher", subTabs: ["Приложения", "Действия", "Схемы", "Обои"] },
    { id: "launcherTabs", saveScope: "launcher", subTabs: [] },
    { id: "launcherProjects", saveScope: "launcher", subTabs: [] },
    { id: "launcherActions", saveScope: "launcher", subTabs: ["Переходы", "Инструменты", "Пользовательские"] },
    { id: "launcherAnimation", saveScope: "launcher", subTabs: [] },
    { id: "launcherApplications", saveScope: "launcher", subTabs: [] },
    { id: "notifications", saveScope: "notifications", subTabs: ["Поведение", "Внешний вид", "Размещение", "Анимация"] }
]

function tabDefinitions() {
    return TAB_DEFINITIONS.slice()
}

function navigationGroupDefinitions() {
    return NAVIGATION_GROUPS.slice()
}

function navigationGroupIdForTabId(id) {
    var pageId = String(id === undefined || id === null ? "" : id)
    for (var i = 0; i < TAB_DEFINITIONS.length; ++i) {
        if (TAB_DEFINITIONS[i].id === pageId)
            return TAB_DEFINITIONS[i].groupId
    }
    return "general"
}

function navigationGroupLabelForTabId(id) {
    var groupId = navigationGroupIdForTabId(id)
    for (var i = 0; i < NAVIGATION_GROUPS.length; ++i) {
        if (NAVIGATION_GROUPS[i].id === groupId)
            return NAVIGATION_GROUPS[i].label
    }
    return "Общие"
}

function groupedTabOrder(order) {
    var source = Array.isArray(order) ? order : []
    var result = []
    for (var groupIndex = 0; groupIndex < NAVIGATION_GROUPS.length; ++groupIndex) {
        var groupId = NAVIGATION_GROUPS[groupIndex].id
        for (var itemIndex = 0; itemIndex < source.length; ++itemIndex) {
            var pageId = String(source[itemIndex])
            if (navigationGroupIdForTabId(pageId) === groupId)
                result.push(pageId)
        }
    }
    return result
}

function otherPageDefinitions() {
    return OTHER_PAGE_DEFINITIONS.slice()
}

function pageForId(id) {
    var pageId = String(id === undefined || id === null ? "" : id)
    for (var i = 0; i < OTHER_PAGE_DEFINITIONS.length; ++i) {
        if (OTHER_PAGE_DEFINITIONS[i].id === pageId)
            return OTHER_PAGE_DEFINITIONS[i]
    }
    return null
}

function hasOtherPageId(id) {
    return pageForId(id) !== null
}

function subtabsForPageId(id) {
    var page = pageForId(id)
    return page ? page.subTabs.slice() : []
}


function saveScopeForPageId(id, subIndex) {
    var page = pageForId(id)
    if (!page)
        return ""
    // General settings has shared UI/profile/storage subtabs. Only its
    // interface subtab has the scoped save/reset action.
    if (page.id === "general" && Number(subIndex) !== 0)
        return ""
    return page.saveScope || ""
}
