.pragma library

// Stable settings page identities live here rather than in the rendering
// component. Keep these IDs aligned with Config/settings persistence IDs.
var TAB_DEFINITIONS = [
    { id: "modules", defaultLabel: "Модули" },
    { id: "themes", defaultLabel: "Темы" },
    { id: "general", defaultLabel: "Общие" },
    { id: "timers", defaultLabel: "Таймеры" },
    { id: "player", defaultLabel: "Плеер" },
    { id: "mopidy", defaultLabel: "Mopidy" },
    { id: "weather", defaultLabel: "Погода" },
    { id: "cava", defaultLabel: "CAVA" },
    { id: "cpuRam", defaultLabel: "CPU/RAM" },
    { id: "network", defaultLabel: "Сеть" },
    { id: "volume", defaultLabel: "Громкость" },
    { id: "calendar", defaultLabel: "Календарь" },
    { id: "launcher", defaultLabel: "Лаунчер" },
    { id: "notifications", defaultLabel: "Уведомления" },
    { id: "settingsWindow", defaultLabel: "Окно настроек" }
]

// Page IDs are the canonical route identity. Array order is only presentation metadata.
var OTHER_PAGE_DEFINITIONS = [
    { id: "general", saveScope: "general", subTabs: ["Интерфейс", "Профили", "Хранилища"] },
    { id: "timers", saveScope: "timer", subTabs: ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации", "Опции таймера"] },
    { id: "player", saveScope: "player", subTabs: ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон"] },
    { id: "weather", saveScope: "weather", subTabs: ["Общие", "Сейчас", "По часам", "По дням"] },
    { id: "cava", saveScope: "cava", subTabs: ["Основные", "Полосы"] },
    { id: "cpuRam", saveScope: "cpu", subTabs: ["Общие", "График CPU", "Top Apps"] },
    { id: "network", saveScope: "network", subTabs: ["Обновления", "Сеть"] },
    { id: "volume", saveScope: "volume", subTabs: ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность", "Анимация"] },
    { id: "calendar", saveScope: "calendar", subTabs: ["Разметка", "Цвета", "Метки заметок", "Анимации"] },
    { id: "settingsWindow", saveScope: "settingsWindow", subTabs: ["Интерфейс", "Окно настроек", "Вкладки"] },
    { id: "mopidy", saveScope: "mopidy", subTabs: ["Общее", "Время", "Иконки", "Пусто и недоступен"] },
    { id: "launcher", saveScope: "launcher", subTabs: ["Общее", "Вкладки", "Проекты"] },
    { id: "notifications", saveScope: "notifications", subTabs: ["Поведение", "Внешний вид", "Размещение"] }
]

function tabDefinitions() {
    return TAB_DEFINITIONS.slice()
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
