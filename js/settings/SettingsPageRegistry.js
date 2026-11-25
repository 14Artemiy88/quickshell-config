.pragma library

// Stable settings page identities live here rather than in the rendering
// component. Keep these IDs aligned with Config/settings persistence IDs.
// Sidebar groups are presentation-only. Page IDs remain stable and keep their
// existing routes, profiles, reset scopes and user-customized labels.
var NAVIGATION_GROUPS = [
    { id: "appearance", label: "Внешний вид", symbol: "◈", description: "Темы, цвета и оформление окна настроек." },
    { id: "modules", label: "Модули", symbol: "▦", description: "Настройки и поведение встроенных модулей." },
    { id: "dashboard", label: "Dashboard", symbol: "▣", description: "Состав, порядок и размеры карточек панели." },
    { id: "launcher", label: "Лаунчер", symbol: "⌕", description: "Поиск, вкладки, действия и оформление лаунчера." },
    { id: "general", label: "Общие", symbol: "⚙", description: "Общие параметры, профили и хранение данных." }
]

var TAB_DEFINITIONS = [
    { id: "modules", defaultLabel: "Включение модулей", groupId: "modules", description: "Включение и отключение модулей оболочки.", keywords: ["включить модуль", "отключить модуль", "компоненты оболочки", "виджеты", "список модулей"] },
    { id: "dashboard", defaultLabel: "Dashboard", groupId: "dashboard", description: "Состав, порядок, видимость и размеры карточек Dashboard.", keywords: ["панель обзора", "главный экран", "карточки панели", "виджеты панели", "обзор системы"] },
    { id: "themes", defaultLabel: "Темы и цвета", groupId: "appearance", description: "Цветовые схемы, палитры, акцентные и пользовательские цвета.", keywords: ["палитра", "цветовая схема", "тема оформления", "акцентный цвет", "цвета интерфейса", "theme", "color scheme"] },
    { id: "general", defaultLabel: "Общие", groupId: "general", description: "Общие параметры интерфейса, профили и пути хранения данных.", keywords: ["общие параметры", "настройки оболочки", "профили", "пресеты", "хранилище", "пути файлов", "каталог данных"] },
    { id: "timers", defaultLabel: "Таймеры", groupId: "modules", description: "Поведение таймеров, оформление, кнопки, подписи и анимации.", keywords: ["обратный отсчет", "отсчет времени", "секундомер", "таймер обратного отсчета", "завершение таймера"] },
    { id: "player", defaultLabel: "Плеер", groupId: "modules", description: "Подключение плеера, метаданные, прогресс, обложка и анимации.", keywords: ["медиаплеер", "музыкальный плеер", "воспроизведение", "трек", "композиция", "музыка", "media player"] },
    { id: "mopidy", defaultLabel: "Mopidy", groupId: "modules", description: "Настройки Mopidy, отображение состояния, времени и иконок.", keywords: ["музыкальный сервер", "сервер музыки", "управление музыкой", "mopidy server"] },
    { id: "weather", defaultLabel: "Погода", groupId: "modules", description: "Источник погоды, текущие условия, прогноз и оформление.", keywords: ["прогноз погоды", "погодные условия", "метео", "температура воздуха", "forecast", "weather forecast"] },
    { id: "cava", defaultLabel: "CAVA", groupId: "modules", description: "Режим CAVA, количество полос, размеры и анимация.", keywords: ["визуализатор", "аудиовизуализатор", "спектр", "аудиоспектр", "эквалайзер", "музыкальные полосы"] },
    { id: "cpuRam", defaultLabel: "CPU/RAM", groupId: "modules", description: "Мониторинг процессора и памяти, график CPU и Top Apps.", keywords: ["процессор", "загрузка процессора", "оперативная память", "оперативка", "озу", "оперативное запоминающее устройство", "монитор ресурсов", "процессы", "top apps"] },
    { id: "network", defaultLabel: "Сеть", groupId: "modules", description: "Обновление сетевой статистики, подключения и оформление.", keywords: ["интернет", "wifi", "wi fi", "wi-fi", "ethernet", "подключение", "сетевой трафик", "скорость сети", "загрузка и отдача"] },
    { id: "volume", defaultLabel: "Громкость", groupId: "modules", description: "Громкость, потоки, индикаторы, иконки и адаптивность.", keywords: ["звук", "аудио", "микшер", "громкость динамиков", "выходное устройство", "аудиопотоки", "системная громкость"] },
    { id: "calendar", defaultLabel: "Календарь", groupId: "modules", description: "Разметка календаря, цвета, заметки и метки событий.", keywords: ["даты", "события", "календарные заметки", "расписание", "планировщик", "напоминания"] },
    { id: "launcher", defaultLabel: "Общее", groupId: "launcher", description: "Общее поведение лаунчера, навигация, оформление и поиск.", keywords: ["запуск приложений", "меню приложений", "панель запуска", "запускалка", "поиск приложений"] },
    { id: "launcherSearch", defaultLabel: "Поиск", groupId: "launcher", description: "Источники поиска лаунчера, приложения, действия и схемы.", keywords: ["поиск приложений", "поиск команд", "поиск файлов", "поиск в интернете", "калькулятор", "веб поиск", "nix search"] },
    { id: "launcherTabs", defaultLabel: "Вкладки", groupId: "launcher", description: "Состав, порядок и оформление вкладок лаунчера.", keywords: ["вкладки лаунчера", "разделы лаунчера", "категории лаунчера", "табы"] },
    { id: "launcherProjects", defaultLabel: "Проекты", groupId: "launcher", description: "Проекты и связанные с ними элементы лаунчера.", keywords: ["рабочие проекты", "проекты лаунчера", "наборы проектов"] },
    { id: "launcherActions", defaultLabel: "Действия", groupId: "launcher", description: "Переходы, инструменты и пользовательские действия.", keywords: ["команды", "быстрые действия", "пользовательские команды", "переходы", "запустить действие"] },
    { id: "launcherAnimation", defaultLabel: "Анимация", groupId: "launcher", description: "Профили и длительность анимаций лаунчера.", keywords: ["плавность", "скорость анимации", "анимация переходов", "эффекты движения"] },
    { id: "launcherApplications", defaultLabel: "Приложения", groupId: "launcher", description: "Список приложений и параметры их отображения.", keywords: ["список программ", "установленные программы", "программы в меню", "запуск программ"] },
    { id: "notifications", defaultLabel: "Уведомления", groupId: "modules", description: "Поведение, внешний вид, размещение и анимации уведомлений.", keywords: ["всплывающие сообщения", "попапы", "баннеры", "уведомления приложений", "notification", "popup"] },
    { id: "settingsWindow", defaultLabel: "Окно настроек", groupId: "appearance", description: "Размеры, поведение, навигация и внешний вид окна настроек.", keywords: ["окно конфигурации", "панель настроек", "размер окна", "боковая панель", "навигация настроек", "окно параметров"] }
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
    return pageMetadataCatalog()
}

// Build the concrete sidebar row model from the same canonical page metadata
// used by search. Keeping this loop in the pure registry avoids QML property
// bindings accidentally placing row creation outside the loop body.
function navigationItemsForOrder(order, labels) {
    var source = Array.isArray(order) ? order : []
    var labelMap = labels && typeof labels === "object" ? labels : {}
    var result = []
    for (var i = 0; i < source.length; ++i) {
        var pageId = String(source[i] === undefined || source[i] === null ? "" : source[i])
        var metadata = pageMetadataForId(pageId)
        if (!metadata)
            continue
        var configuredLabel = labelMap[pageId]
        var label = configuredLabel === undefined || configuredLabel === null
            ? "" : String(configuredLabel).trim()
        result.push({
            id: pageId,
            label: label || metadata.defaultLabel,
            groupId: metadata.groupId
        })
    }
    return result
}

function navigationGroupDefinitions() {
    return NAVIGATION_GROUPS.slice()
}

// Build sidebar groups in the user's configured frame order. Page membership
// remains fixed by canonical metadata; only the top-level presentation order
// is customizable here.
function navigationGroupsForOrder(source, labels) {
    var normalized = normalizeNavigationOrder(source)
    var items = navigationItemsForOrder(flattenNavigationOrder(normalized), labels)
    var result = []
    for (var orderIndex = 0; orderIndex < normalized.groupOrder.length; ++orderIndex) {
        var groupId = normalized.groupOrder[orderIndex]
        var definition = null
        for (var definitionIndex = 0; definitionIndex < NAVIGATION_GROUPS.length; ++definitionIndex) {
            if (NAVIGATION_GROUPS[definitionIndex].id === groupId) {
                definition = NAVIGATION_GROUPS[definitionIndex]
                break
            }
        }
        if (!definition) continue
        var groupItems = []
        for (var itemIndex = 0; itemIndex < items.length; ++itemIndex) {
            if (items[itemIndex].groupId === groupId)
                groupItems.push(items[itemIndex])
        }
        result.push({
            id: definition.id,
            label: definition.label,
            symbol: definition.symbol,
            description: definition.description,
            items: groupItems
        })
    }
    return result
}

// Hierarchical navigation order. Folder/frame order is independent from the
// page order inside each frame. Page membership remains canonical in
// TAB_DEFINITIONS; cross-frame page moves are intentionally not supported yet.
function defaultNavigationOrder() {
    var groupOrder = []
    var pagesByGroup = {}
    for (var groupIndex = 0; groupIndex < NAVIGATION_GROUPS.length; ++groupIndex) {
        var groupId = NAVIGATION_GROUPS[groupIndex].id
        groupOrder.push(groupId)
        pagesByGroup[groupId] = []
    }
    for (var pageIndex = 0; pageIndex < TAB_DEFINITIONS.length; ++pageIndex) {
        var page = TAB_DEFINITIONS[pageIndex]
        if (pagesByGroup[page.groupId])
            pagesByGroup[page.groupId].push(page.id)
    }
    return { groupOrder: groupOrder, pagesByGroup: pagesByGroup }
}

function normalizeNavigationOrder(source) {
    var defaults = defaultNavigationOrder()
    var input = source && typeof source === "object" && !Array.isArray(source) ? source : {}
    var result = { groupOrder: [], pagesByGroup: {} }
    var seenGroups = {}
    var savedGroupOrder = Array.isArray(input.groupOrder) ? input.groupOrder : []
    for (var groupIndex = 0; groupIndex < savedGroupOrder.length; ++groupIndex) {
        var groupId = savedGroupOrder[groupIndex]
        if (typeof groupId !== "string" || !Object.prototype.hasOwnProperty.call(defaults.pagesByGroup, groupId) || seenGroups[groupId])
            continue
        seenGroups[groupId] = true
        result.groupOrder.push(groupId)
    }
    for (var defaultGroupIndex = 0; defaultGroupIndex < defaults.groupOrder.length; ++defaultGroupIndex) {
        var fallbackGroupId = defaults.groupOrder[defaultGroupIndex]
        if (!seenGroups[fallbackGroupId]) result.groupOrder.push(fallbackGroupId)
    }

    var savedPages = input.pagesByGroup && typeof input.pagesByGroup === "object" && !Array.isArray(input.pagesByGroup)
        ? input.pagesByGroup : {}
    for (var pageGroupIndex = 0; pageGroupIndex < defaults.groupOrder.length; ++pageGroupIndex) {
        var pageGroupId = defaults.groupOrder[pageGroupIndex]
        var allowed = defaults.pagesByGroup[pageGroupId]
        var pages = []
        var seenPages = {}
        var candidatePages = Array.isArray(savedPages[pageGroupId]) ? savedPages[pageGroupId] : []
        for (var candidateIndex = 0; candidateIndex < candidatePages.length; ++candidateIndex) {
            var pageId = candidatePages[candidateIndex]
            if (typeof pageId !== "string" || allowed.indexOf(pageId) < 0 || seenPages[pageId])
                continue
            seenPages[pageId] = true
            pages.push(pageId)
        }
        for (var allowedIndex = 0; allowedIndex < allowed.length; ++allowedIndex) {
            var fallbackPageId = allowed[allowedIndex]
            if (!seenPages[fallbackPageId]) pages.push(fallbackPageId)
        }
        result.pagesByGroup[pageGroupId] = pages
    }
    return result
}

// Convert the former flat order into the new object. Legacy ordering only
// represented per-page order because frame order was fixed, so frame order
// starts with the historic default and page order is retained within groups.
function navigationOrderFromLegacyTabOrder(source) {
    var defaults = defaultNavigationOrder()
    var result = { groupOrder: defaults.groupOrder.slice(), pagesByGroup: {} }
    var seen = {}
    for (var groupIndex = 0; groupIndex < defaults.groupOrder.length; ++groupIndex)
        result.pagesByGroup[defaults.groupOrder[groupIndex]] = []

    var candidateIds = Array.isArray(source) ? source : []
    for (var candidateIndex = 0; candidateIndex < candidateIds.length; ++candidateIndex) {
        var pageId = candidateIds[candidateIndex]
        if (typeof pageId !== "string" || seen[pageId]) continue
        var groupId = navigationGroupIdForTabId(pageId)
        if (!result.pagesByGroup[groupId]) continue
        seen[pageId] = true
        result.pagesByGroup[groupId].push(pageId)
    }
    for (var fallbackGroupIndex = 0; fallbackGroupIndex < defaults.groupOrder.length; ++fallbackGroupIndex) {
        var fallbackGroupId = defaults.groupOrder[fallbackGroupIndex]
        var allowed = defaults.pagesByGroup[fallbackGroupId]
        for (var fallbackIndex = 0; fallbackIndex < allowed.length; ++fallbackIndex) {
            var fallbackPageId = allowed[fallbackIndex]
            if (!seen[fallbackPageId]) result.pagesByGroup[fallbackGroupId].push(fallbackPageId)
        }
    }
    return normalizeNavigationOrder(result)
}

function flattenNavigationOrder(source) {
    var normalized = normalizeNavigationOrder(source)
    var result = []
    for (var groupIndex = 0; groupIndex < normalized.groupOrder.length; ++groupIndex) {
        var groupId = normalized.groupOrder[groupIndex]
        var pages = normalized.pagesByGroup[groupId] || []
        for (var pageIndex = 0; pageIndex < pages.length; ++pageIndex)
            result.push(pages[pageIndex])
    }
    return result
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
    var group = navigationGroupForId(groupId)
    return group ? group.label : "Общие"
}

function navigationGroupForId(id) {
    var groupId = String(id === undefined || id === null ? "" : id)
    for (var i = 0; i < NAVIGATION_GROUPS.length; ++i) {
        if (NAVIGATION_GROUPS[i].id === groupId) {
            return {
                id: NAVIGATION_GROUPS[i].id,
                label: NAVIGATION_GROUPS[i].label,
                symbol: NAVIGATION_GROUPS[i].symbol,
                description: NAVIGATION_GROUPS[i].description || ""
            }
        }
    }
    return null
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

// Alternate user wording for each settings subsection. Arrays follow the
// canonical subtab order below; keep aliases narrow enough to avoid making
// unrelated controls match generic words such as "время" or "цвет".
var SUBTAB_KEYWORDS = {
    general: [
        ["интерфейс пользователя", "ui", "внешний вид окна"],
        ["наборы настроек", "предустановки", "переключить профиль", "presets"],
        ["файлы настроек", "каталог конфигурации", "пути хранения", "директории данных"]
    ],
    timers: [
        ["настройки таймера", "длительность отсчета", "запуск и пауза"],
        ["окно завершения", "таймер закончился", "сигнал завершения"],
        ["значки таймера", "символы таймера"],
        ["расположение элементов", "порядок элементов", "разметка таймера"],
        ["эффекты таймера", "движение элементов"],
        ["дополнительные режимы", "действия таймера", "опции обратного отсчета"]
    ],
    player: [
        ["музыкальный плеер", "воспроизведение трека", "медиаплеер"],
        ["пауза при тишине", "беззвучный режим", "тишина"],
        ["остаток трека", "время до конца", "сколько осталось играть"],
        ["название трека", "исполнитель", "альбом", "обложка метаданных"],
        ["значки плеера", "кнопки управления музыкой"],
        ["полоса воспроизведения", "позиция трека", "seek bar"],
        ["обложка альбома", "album art", "изображение трека"],
        ["эффекты плеера", "анимация воспроизведения"]
    ],
    weather: [
        ["источник прогноза", "местоположение погоды", "город погоды"],
        ["текущая температура", "сейчас на улице", "ощущается как", "ветер и давление"],
        ["почасовой прогноз", "погода по часам", "температура каждый час"],
        ["прогноз на несколько дней", "погода на неделю", "дневной прогноз"],
        ["погодные эффекты", "анимация погоды"]
    ],
    cava: [
        ["визуализатор звука", "аудиоспектр", "режим спектра"],
        ["число полос", "частотные полосы", "столбики эквалайзера"],
        ["анимация спектра", "плавность полос"]
    ],
    cpuRam: [
        ["процессор и оперативная память", "нагрузка системы", "монитор ресурсов"],
        ["график процессора", "история загрузки cpu", "линия нагрузки"],
        ["топ процессов", "самые прожорливые приложения", "нагрузка приложений", "список процессов"],
        ["эффекты графика cpu", "анимация процессора"]
    ],
    network: [
        ["частота обновления сети", "интервал опроса", "скорость обновления статистики"],
        ["интернет и подключения", "сетевые интерфейсы", "wifi и ethernet"],
        ["анимация сетевых индикаторов", "движение скорости сети"]
    ],
    volume: [
        ["значки звука", "иконки громкости"],
        ["общий уровень звука", "устройство вывода", "динамики и наушники"],
        ["индикаторы уровня", "полоса громкости", "звуковые полосы"],
        ["аудиопотоки", "приложения со звуком", "громкость отдельных программ"],
        ["адаптивный размер звука", "подстройка громкости"],
        ["анимация громкости", "эффекты аудио"]
    ],
    calendar: [
        ["расположение календаря", "сетка дат", "вид календаря"],
        ["цвета календаря", "выделение дат", "цвет событий"],
        ["метки заметок", "значки событий", "маркеры дат"],
        ["анимация календаря", "переходы между месяцами"]
    ],
    settingsWindow: [
        ["интерфейс окна", "внешний вид настроек", "размеры панели"],
        ["размер и поведение окна", "позиция окна", "геометрия настроек"],
        ["вкладки настроек", "группы навигации", "свернуть разделы"]
    ],
    mopidy: [
        ["подключение к mopidy", "музыкальный сервер", "адрес сервера"],
        ["время воспроизведения", "длительность трека"],
        ["иконки mopidy", "значки состояния"],
        ["пустой плеер", "сервер недоступен", "нет музыки"],
        ["анимация mopidy", "эффекты музыкального сервера"]
    ],
    launcher: [
        ["общие настройки лаунчера", "запускалка", "поведение меню"],
        ["навигация по лаунчеру", "переключение разделов", "клавиши перемещения"],
        ["оформление лаунчера", "внешний вид меню"],
        ["поиск в лаунчере", "поисковая строка меню"]
    ],
    launcherSearch: [
        ["поиск программ", "список приложений для поиска"],
        ["поиск команд", "действия в поиске"],
        ["внешний вид результатов", "схемы поиска"],
        ["поиск фоновых изображений", "обои в поиске"]
    ],
    launcherActions: [
        ["переходы лаунчера", "переключение страниц"],
        ["инструменты лаунчера", "калькулятор", "командные инструменты"],
        ["пользовательские команды", "свои действия", "кастомные действия"]
    ],
    notifications: [
        ["поведение всплывающих сообщений", "таймаут уведомлений", "очередь уведомлений"],
        ["внешний вид уведомлений", "карточки сообщений", "иконки и изображения уведомлений"],
        ["позиция уведомлений", "координаты уведомлений", "размер и отступы уведомлений"],
        ["анимация всплывающих окон", "появление уведомлений"]
    ]
}

// Subtab IDs mirror the existing stable page + local index route. They are
// metadata identifiers only: persistence and navigation still use page IDs
// plus the established subtab index, so no stored settings are migrated.
function subTabMetadataForPageId(id) {
    var page = pageForId(id)
    if (!page || !Array.isArray(page.subTabs))
        return []
    var result = []
    for (var i = 0; i < page.subTabs.length; ++i) {
        var label = String(page.subTabs[i])
        var slug = label.toLocaleLowerCase().replace(/ё/g, "е")
            .replace(/[^a-zа-я0-9]+/g, "-").replace(/^-+|-+$/g, "")
        var pageKeywords = SUBTAB_KEYWORDS[page.id]
        var aliases = pageKeywords && Array.isArray(pageKeywords[i]) ? pageKeywords[i].slice() : []
        result.push({
            id: page.id + "." + (slug || ("subtab-" + String(i))),
            index: i,
            label: label,
            keywords: aliases
        })
    }
    return result
}

function subtabsForPageId(id) {
    var metadata = subTabMetadataForPageId(id)
    var labels = []
    for (var i = 0; i < metadata.length; ++i)
        labels.push(metadata[i].label)
    return labels
}

function pageMetadataForId(id) {
    var pageId = String(id === undefined || id === null ? "" : id)
    var tab = null
    for (var i = 0; i < TAB_DEFINITIONS.length; ++i) {
        if (TAB_DEFINITIONS[i].id === pageId) {
            tab = TAB_DEFINITIONS[i]
            break
        }
    }
    if (!tab)
        return null

    var route = pageForId(pageId)
    var group = navigationGroupForId(tab.groupId)
    return {
        id: tab.id,
        defaultLabel: tab.defaultLabel,
        label: tab.defaultLabel,
        groupId: tab.groupId,
        navigationGroupLabel: group ? group.label : "Общие",
        navigationGroupDescription: group ? group.description : "",
        description: tab.description || "",
        keywords: Array.isArray(tab.keywords) ? tab.keywords.slice() : [],
        saveScope: route ? (route.saveScope || "") : "",
        subTabs: subTabMetadataForPageId(pageId),
        hasSharedPageRoute: route !== null
    }
}

function pageMetadataCatalog() {
    var result = []
    for (var i = 0; i < TAB_DEFINITIONS.length; ++i) {
        var metadata = pageMetadataForId(TAB_DEFINITIONS[i].id)
        if (metadata)
            result.push(metadata)
    }
    return result
}

function saveScopeForPageId(id, subIndex) {
    var metadata = pageMetadataForId(id)
    if (!metadata || !metadata.hasSharedPageRoute)
        return ""
    // General settings has shared UI/profile/storage subtabs. Only its
    // interface subtab has the scoped save/reset action.
    if (metadata.id === "general" && Number(subIndex) !== 0)
        return ""
    return metadata.saveScope || ""
}
