import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."
import "../primitives"
import "../../primitives"
import "../../../js/settings/SettingsLauncherActions.js" as LauncherActions
import "../../../js/launcher/LauncherAppPreferences.js" as LauncherAppPreferences

Column {
    id: root

    property var host
    property var settings: Settings
    property string applicationPreferenceSearch: ""

    visible: host && host.currentPageId === "launcher"
    width: parent ? parent.width : 0
    spacing: 10

    readonly property var tabDefinitions: [
        { id: 0, label: "Apps", icon: "󰀻" },
        { id: 1, label: "Run", icon: "" },
        { id: 2, label: "Windows", icon: "󰖯" },
        { id: 3, label: "Clipboard", icon: "󰅇" },
        { id: 4, label: "Power", icon: "" },
        { id: 5, label: "Network", icon: "󰖩" },
        { id: 6, label: "Packages", icon: "󱄅" },
        { id: 7, label: "Pass", icon: "󰌋" },
        { id: 8, label: "Projects", icon: "" },
        { id: 9, label: "Calculator", icon: "󰃬" }
    ]

    function normalizedTabOrder() {
        var result = []
        var saved = Config.launcherTabOrder
        if (saved instanceof Array) {
            for (var i = 0; i < saved.length; ++i) {
                var id = Number(saved[i])
                if (isFinite(id) && Math.floor(id) === id && id >= 0 && id < root.tabDefinitions.length && result.indexOf(id) < 0)
                    result.push(id)
            }
        }
        for (var j = 0; j < root.tabDefinitions.length; ++j) {
            if (result.indexOf(j) < 0) result.push(j)
        }
        return result
    }

    function tabLabel(tabId) {
        var definition = root.tabDefinitions[tabId]
        if (!definition) return ""
        var saved = Config.launcherTabLabels
        if (saved instanceof Array && tabId >= 0 && tabId < saved.length) {
            var value = String(saved[tabId] === undefined ? "" : saved[tabId]).replace(/[\r\n\t]/g, " ").trim().slice(0, 32)
            return value || definition.label
        }
        return definition.label
    }

    function tabIcon(tabId) {
        var definition = root.tabDefinitions[tabId]
        if (!definition) return ""
        var saved = Config.launcherTabIcons
        if (saved instanceof Array && tabId >= 0 && tabId < saved.length)
            return String(saved[tabId] === undefined ? "" : saved[tabId]).replace(/[\r\n\t]/g, " ").slice(0, 16)
        return definition.icon
    }

    function setTabLabel(tabId, value) {
        if (tabId < 0 || tabId >= root.tabDefinitions.length) return
        var next = Config.launcherTabLabels instanceof Array ? Config.launcherTabLabels.slice(0) : []
        while (next.length < root.tabDefinitions.length) next.push(root.tabDefinitions[next.length].label)
        var clean = String(value === undefined ? "" : value).replace(/[\r\n\t]/g, " ").trim().slice(0, 32)
        next[tabId] = clean || root.tabDefinitions[tabId].label
        Config.launcherTabLabels = next
        root.settings.save()
    }

    function setTabIcon(tabId, value) {
        if (tabId < 0 || tabId >= root.tabDefinitions.length) return
        var next = Config.launcherTabIcons instanceof Array ? Config.launcherTabIcons.slice(0) : []
        while (next.length < root.tabDefinitions.length) next.push(root.tabDefinitions[next.length].icon)
        next[tabId] = String(value === undefined ? "" : value).replace(/[\r\n\t]/g, " ").slice(0, 16)
        Config.launcherTabIcons = next
        root.settings.save()
    }

    readonly property var orderedTabRows: {
        var order = root.normalizedTabOrder()
        var visibility = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible : []
        var labels = Config.launcherTabLabels instanceof Array ? Config.launcherTabLabels : []
        var icons = Config.launcherTabIcons instanceof Array ? Config.launcherTabIcons : []
        var result = []
        for (var i = 0; i < order.length; ++i) {
            var id = order[i]
            var definition = root.tabDefinitions[id]
            var label = labels[id] === undefined ? definition.label : String(labels[id]).replace(/[\r\n\t]/g, " ").trim().slice(0, 32)
            var icon = icons[id] === undefined ? definition.icon : String(icons[id]).replace(/[\r\n\t]/g, " ").slice(0, 16)
            result.push({ id: id, label: label || definition.label, icon: icon, visible: visibility[id] === undefined ? true : !!visibility[id] })
        }
        return result
    }

    function visibleTabCount() {
        var visibility = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible : []
        var count = 0
        for (var i = 0; i < root.tabDefinitions.length; ++i) {
            if (visibility[i] !== false) count++
        }
        return count
    }

    function setTabVisible(tabId, value) {
        var next = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible.slice(0) : [true, true, true, true, true, true, true, true, true, true]
        while (next.length < root.tabDefinitions.length) next.push(true)
        if (!value && next[tabId] !== false && root.visibleTabCount() <= 1) {
            // Keep at least one visible entry so the tab selector cannot become unusable.
            Config.launcherTabVisible = next
            return
        }
        next[tabId] = !!value
        Config.launcherTabVisible = next
        root.settings.save()
    }

    function moveTab(tabId, delta) {
        var order = root.normalizedTabOrder()
        var index = order.indexOf(tabId)
        var destination = index + delta
        if (index < 0 || destination < 0 || destination >= order.length) return
        order.splice(index, 1)
        order.splice(destination, 0, tabId)
        Config.launcherTabOrder = order
        root.settings.save()
    }

    function projectValue(index, field) {
        var list = Config.launcherProjects instanceof Array ? Config.launcherProjects : []
        if (index < 0 || index >= list.length || !list[index]) return ""
        return String(list[index][field] === undefined ? "" : list[index][field])
    }

    function updateProject(index, field, value) {
        root.settings.updateLauncherProject(index, field, value)
    }

    function customActionValue(index, field) {
        var list = Array.isArray(Config.launcherCustomActions) ? Config.launcherCustomActions : []
        if (index < 0 || index >= list.length || !list[index]) return ""
        return field === "enabled" ? !!list[index][field] : String(list[index][field] === undefined ? "" : list[index][field])
    }

    function setLauncherAppPreference(kind, appId, enabled) {
        var favorites = LauncherAppPreferences.normalizeIds(Config.launcherFavoriteApps)
        var hidden = LauncherAppPreferences.normalizeIds(Config.launcherHiddenApps)
        if (kind === "favorite") {
            favorites = LauncherAppPreferences.setId(favorites, appId, enabled)
            if (enabled) hidden = LauncherAppPreferences.setId(hidden, appId, false)
        } else if (kind === "hidden") {
            hidden = LauncherAppPreferences.setId(hidden, appId, enabled)
            if (enabled) favorites = LauncherAppPreferences.setId(favorites, appId, false)
        } else {
            return
        }
        Config.launcherFavoriteApps = favorites
        Config.launcherHiddenApps = hidden
        root.settings.save()
    }

    readonly property var applicationPreferenceRows: {
        var entries = DesktopEntries.applications.values || []
        var favorites = LauncherAppPreferences.normalizeIds(Config.launcherFavoriteApps)
        var hidden = LauncherAppPreferences.normalizeIds(Config.launcherHiddenApps)
        var needle = String(root.applicationPreferenceSearch || "").trim().toLowerCase()
        var rows = []
        for (var i = 0; i < entries.length; ++i) {
            var entry = entries[i]
            if (!entry || !entry.id) continue
            var id = String(entry.id).trim()
            var isFavorite = favorites.indexOf(id) >= 0
            var isHidden = hidden.indexOf(id) >= 0
            if (!needle && !isFavorite && !isHidden) continue
            if (needle) {
                var haystack = [entry.name, entry.genericName, entry.comment, id]
                if (entry.keywords && typeof entry.keywords.length === "number") {
                    for (var k = 0; k < entry.keywords.length; ++k) haystack.push(entry.keywords[k])
                }
                if (haystack.join(" ").toLowerCase().indexOf(needle) < 0) continue
            }
            rows.push({
                id: id,
                name: String(entry.name || id),
                comment: String(entry.comment || entry.genericName || ""),
                favorite: isFavorite,
                hidden: isHidden
            })
        }
        rows.sort(function(a, b) {
            return a.name.localeCompare(b.name, undefined, { sensitivity: "base" })
        })
        if (needle && rows.length > 40) rows = rows.slice(0, 40)
        return rows
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherDefaultMode", "launcherShowResultCount"] })
        heading: "Поведение при открытии"
        padding: 8
        contentSpacing: 7

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Вкладка по умолчанию"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsComboBox {
                id: launcherDefaultModeCombo
                width: 235
                height: 30
                model: ["Apps — Приложения", "Run — Команды", "Windows — Окна", "Clipboard — Буфер обмена", "Power — Питание", "Network — Сети", "Packages — Nix", "Pass — Пароли", "Projects — Проекты", "Calculator — Калькулятор"]
                currentIndex: Math.max(0, Math.min(9, Number(Config.launcherDefaultMode) || 0))
                onItemChosen: index => {
                    Config.launcherDefaultMode = Math.max(0, Math.min(9, index))
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherDefaultModeChanged() {
                        launcherDefaultModeCombo.currentIndex = Math.max(0, Math.min(9, Number(Config.launcherDefaultMode) || 0))
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Показывать счётчик RESULTS"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsCheckBox {
                id: launcherResultCountCheckBox
                width: 58
                height: 30
                indicatorOnly: true
                checked: Config.launcherShowResultCount
                onToggled: {
                    Config.launcherShowResultCount = checked
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherShowResultCountChanged() {
                        launcherResultCountCheckBox.checked = Config.launcherShowResultCount
                    }
                }
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherFuzzySearchApps"] })
        heading: "Поиск приложений"
        padding: 8
        contentSpacing: 5

        Row {
            width: parent.width
            height: 32
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Нечёткий поиск"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsCheckBox {
                id: launcherFuzzySearchAppsCheckBox
                width: 58
                height: 30
                indicatorOnly: true
                checked: Config.launcherFuzzySearchApps
                onToggled: {
                    Config.launcherFuzzySearchApps = checked
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherFuzzySearchAppsChanged() {
                        launcherFuzzySearchAppsCheckBox.checked = Config.launcherFuzzySearchApps
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Включено: ищет также по непоследовательным буквам (например, ff → Firefox). Выключено: только точное, начальное или непрерывное совпадение. Работает и для фильтров @."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherFuzzySearchActions"] })
        heading: "Поиск действий"
        padding: 8
        contentSpacing: 5

        Row {
            width: parent.width
            height: 32
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Нечёткий поиск действий"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsCheckBox {
                id: launcherFuzzySearchActionsCheckBox
                width: 58
                height: 30
                indicatorOnly: true
                checked: Config.launcherFuzzySearchActions
                onToggled: {
                    Config.launcherFuzzySearchActions = checked
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherFuzzySearchActionsChanged() {
                        launcherFuzzySearchActionsCheckBox.checked = Config.launcherFuzzySearchActions
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Включено: пользовательские действия ищутся по непоследовательным буквам в названии, описании и команде. Выключено: остаются точные, начальные и непрерывные совпадения. Работает в Apps и палитре >."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }


    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherFuzzySearchSchemes"] })
        heading: "Поиск цветовых схем"
        padding: 8
        contentSpacing: 5

        Row {
            width: parent.width
            height: 32
            spacing: 8
            Text {
                width: 190
                height: 30
                text: "Нечёткий поиск тем"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsCheckBox {
                id: launcherFuzzySearchSchemesCheckBox
                width: 58
                height: 30
                indicatorOnly: true
                checked: Config.launcherFuzzySearchSchemes
                onToggled: {
                    Config.launcherFuzzySearchSchemes = checked
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherFuzzySearchSchemesChanged() {
                        launcherFuzzySearchSchemesCheckBox.checked = Config.launcherFuzzySearchSchemes
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Включено: ищет темы по непоследовательным буквам в названии и описании. Выключено: остаются точные, начальные и непрерывные совпадения. Работает также для >scheme dynamic."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherFuzzySearchWallpapers"] })
        heading: "Поиск обоев"
        padding: 8
        contentSpacing: 5

        Row {
            width: parent.width
            height: 32
            spacing: 8
            Text {
                width: 190
                height: 30
                text: "Нечёткий поиск обоев"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsCheckBox {
                id: launcherFuzzySearchWallpapersCheckBox
                width: 58
                height: 30
                indicatorOnly: true
                checked: Config.launcherFuzzySearchWallpapers
                onToggled: {
                    Config.launcherFuzzySearchWallpapers = checked
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherFuzzySearchWallpapersChanged() {
                        launcherFuzzySearchWallpapersCheckBox.checked = Config.launcherFuzzySearchWallpapers
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Включено: ищет файлы обоев по непоследовательным буквам в имени. Выключено: остаются точные, начальные и непрерывные совпадения. Работает в режимах Все, Избранное и Недавние."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherWallpaperDirectory"] })
        heading: "Обои рабочего стола"
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Папка с изображениями"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsTextField {
                id: launcherWallpaperDirectoryField
                width: Math.max(120, parent.width - 198)
                height: 30
                text: Config.launcherWallpaperDirectory
                placeholderText: "~/Pictures/Wallpapers"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                onEditingFinished: {
                    Config.launcherWallpaperDirectory = text.replace(/[\r\n\t]/g, " ").trim()
                    text = Config.launcherWallpaperDirectory
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherWallpaperDirectoryChanged() {
                        launcherWallpaperDirectoryField.text = Config.launcherWallpaperDirectory
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Пустое значение использует ~/Pictures/Wallpapers. В Launcher откройте >wallpaper; установка поддерживает plasma-apply-wallpaperimage (KDE) и swww (Wayland)."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherBackdropOpacity", "launcherBackground", "launcherRadius"] })
        heading: "Окно лаунчера"
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Скругление окна"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                compact: true
                fieldWidth: 100
                value: Config.launcherRadius
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                targetObject: Config
                targetProperty: "launcherRadius"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Затемнение фона"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                compact: true
                fieldWidth: 100
                value: Config.launcherBackdropOpacity
                minimum: 0
                maximum: 0.95
                step: 0.05
                wheelStep: 0.05
                decimals: 2
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                targetObject: Config
                targetProperty: "launcherBackdropOpacity"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsColorField {
            width: parent.width
            label: "Фон окна лаунчера"
            value: String(Config.launcherBackground)
            targetObject: Config
            targetProperty: "launcherBackground"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            labelWidth: 190
            fieldWidth: 120
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherItemHeight", "launcherItemRadius"] })
        heading: "Элемент списка"
        padding: 8
        contentSpacing: 7

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Высота элемента списка"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                compact: true
                fieldWidth: 100
                value: Config.launcherItemHeight
                minimum: 36
                maximum: 110
                step: 2
                wheelStep: 2
                targetObject: Config
                targetProperty: "launcherItemHeight"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8

            Text {
                width: 190
                height: 30
                text: "Скругление элементов"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                compact: true
                fieldWidth: 100
                value: Config.launcherItemRadius
                minimum: 0
                maximum: 30
                step: 1
                wheelStep: 1
                targetObject: Config
                targetProperty: "launcherItemRadius"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherTitleBold", "launcherTitleColor", "launcherTitleFont", "launcherTitleFontSize", "launcherTitleLetterSpacing", "launcherTitleText", "launcherTitleY"] })
        heading: "Заголовок лаунчера"
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Текст заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsTextField {
                id: launcherTitleTextField
                width: Math.min(260, parent.width - 198)
                height: 30
                text: Config.launcherTitleText
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                onEditingFinished: {
                    Config.launcherTitleText = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 64) || "LAUNCHER"
                    text = Config.launcherTitleText
                    root.settings.save()
                }
                Connections { target: Config; function onLauncherTitleTextChanged() { launcherTitleTextField.text = Config.launcherTitleText } }
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Шрифт заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsFontField {
                width: parent.width - 198
                height: 30
                compact: true
                fieldWidth: Math.max(80, Math.min(222, parent.width - 236))
                fieldFontSize: 11
                value: Config.launcherTitleFont
                targetObject: Config
                targetProperty: "launcherTitleFont"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Размер шрифта заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField { width: 100; compact: true; fieldWidth: 100; value: Config.launcherTitleFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; targetObject: Config; targetProperty: "launcherTitleFontSize"; settingsObject: root.settings; saveOnEdit: true }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Положение Y заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField { width: 100; compact: true; fieldWidth: 100; value: Config.launcherTitleY; minimum: -40; maximum: 40; step: 1; wheelStep: 1; targetObject: Config; targetProperty: "launcherTitleY"; settingsObject: root.settings; saveOnEdit: true }
        }

        SettingsColorField {
            width: parent.width
            label: "Цвет заголовка"
            value: String(Config.launcherTitleColor)
            targetObject: Config
            targetProperty: "launcherTitleColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: false
            labelWidth: 190
            fieldWidth: 120
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Межбуквенный интервал"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField { width: 100; compact: true; fieldWidth: 100; value: Config.launcherTitleLetterSpacing; minimum: 0; maximum: 12; step: 1; wheelStep: 1; targetObject: Config; targetProperty: "launcherTitleLetterSpacing"; settingsObject: root.settings; saveOnEdit: true }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Жирный заголовок"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsCheckBox {
                id: launcherTitleBoldCheckBox
                width: 58; height: 30; indicatorOnly: true
                checked: Config.launcherTitleBold
                onToggled: { Config.launcherTitleBold = checked; root.settings.save() }
                Connections { target: Config; function onLauncherTitleBoldChanged() { launcherTitleBoldCheckBox.checked = Config.launcherTitleBold } }
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherSearchBackground", "launcherSearchFont", "launcherSearchFontSize", "launcherSearchHeight", "launcherSearchPlaceholder", "launcherSearchRadius"] })
        heading: "Строка поиска"
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Шрифт поиска"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsFontField {
                width: parent.width - 198
                height: 30
                compact: true
                fieldWidth: Math.max(80, Math.min(222, parent.width - 236))
                fieldFontSize: 11
                value: Config.launcherSearchFont
                targetObject: Config
                targetProperty: "launcherSearchFont"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Плейсхолдер поиска"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsTextField {
                id: launcherSearchPlaceholderField
                width: Math.min(260, parent.width - 198)
                height: 30
                text: Config.launcherSearchPlaceholder
                placeholderText: "Текст-подсказка"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                onEditingFinished: { Config.launcherSearchPlaceholder = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 128); text = Config.launcherSearchPlaceholder; root.settings.save() }
                Connections { target: Config; function onLauncherSearchPlaceholderChanged() { launcherSearchPlaceholderField.text = Config.launcherSearchPlaceholder } }
            }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Размер шрифта поиска"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField { width: 100; compact: true; fieldWidth: 100; value: Config.launcherSearchFontSize; minimum: 8; maximum: 40; step: 1; wheelStep: 1; targetObject: Config; targetProperty: "launcherSearchFontSize"; settingsObject: root.settings; saveOnEdit: true }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField { width: 100; compact: true; fieldWidth: 100; value: Config.launcherSearchHeight; minimum: 36; maximum: 100; step: 2; wheelStep: 2; targetObject: Config; targetProperty: "launcherSearchHeight"; settingsObject: root.settings; saveOnEdit: true }
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Скругление строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField { width: 100; compact: true; fieldWidth: 100; value: Config.launcherSearchRadius; minimum: 0; maximum: 36; step: 1; wheelStep: 1; targetObject: Config; targetProperty: "launcherSearchRadius"; settingsObject: root.settings; saveOnEdit: true }
        }

        SettingsColorField {
            width: parent.width
            label: "Фон строки поиска"
            value: String(Config.launcherSearchBackground)
            targetObject: Config
            targetProperty: "launcherSearchBackground"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            labelWidth: 190
            fieldWidth: 120
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherCrossSearchCalculator", "launcherCrossSearchProjects", "launcherCrossSearchRunHistory"] })
        heading: "Сквозной поиск"
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            text: "Искать проекты из Apps"
            checked: Config.launcherCrossSearchProjects
            onToggled: {
                Config.launcherCrossSearchProjects = checked
                root.settings.save()
            }
        }

        SettingsCheckBox {
            text: "Искать сохранённые команды из Apps"
            checked: Config.launcherCrossSearchRunHistory
            onToggled: {
                Config.launcherCrossSearchRunHistory = checked
                root.settings.save()
            }
        }

        SettingsCheckBox {
            text: "Искать вычисления из Apps"
            checked: Config.launcherCrossSearchCalculator
            onToggled: {
                Config.launcherCrossSearchCalculator = checked
                root.settings.save()
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 2
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherTabOrder", "launcherTabVisible", "launcherTabLabels", "launcherTabIcons"] })
        heading: "Настройка вкладок"
        padding: 8
        contentSpacing: 5

        Row {
            width: parent.width
            height: 28
            spacing: 6

            Text {
                width: 40
                text: "Вкл."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: 78
                text: "Иконка"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: 165
                text: "Название вкладки"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
            }
            Item { width: Math.max(0, parent.width - 40 - 78 - 165 - 72 - 4 * parent.spacing); height: 1 }
            Text {
                width: 72
                text: "Порядок"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            model: root.orderedTabRows

            delegate: Row {
                id: launcherTabRow
                required property var modelData
                required property int index
                width: parent.width
                height: 32
                spacing: 6

                SettingsCheckBox {
                    width: 40
                    height: 30
                    indicatorOnly: true
                    // Keep every checkbox interactive so a hidden final tab can
                    // always be restored. setTabVisible() still prevents hiding
                    // the last remaining visible tab.
                    checked: launcherTabRow.modelData.visible
                    onToggled: root.setTabVisible(launcherTabRow.modelData.id, checked)
                }

                SettingsTextField {
                    id: launcherTabIconField
                    width: 78
                    height: 28
                    text: launcherTabRow.modelData.icon
                    placeholderText: "Иконка"
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    font.family: "Symbols Nerd Font Mono"
                    font.pixelSize: Config.settingsUiSize(13)
                    horizontalAlignment: TextInput.AlignHCenter
                    activeFocusOnTab: true
                    onEditingFinished: {
                        root.setTabIcon(launcherTabRow.modelData.id, text)
                        text = root.tabIcon(launcherTabRow.modelData.id)
                    }
                }

                SettingsTextField {
                    id: launcherTabLabelField
                    width: 165
                    height: 28
                    text: launcherTabRow.modelData.label
                    placeholderText: "Название"
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    activeFocusOnTab: true
                    onEditingFinished: {
                        root.setTabLabel(launcherTabRow.modelData.id, text)
                        text = root.tabLabel(launcherTabRow.modelData.id)
                    }
                }

                Item { width: Math.max(0, launcherTabRow.width - 40 - 78 - 165 - 44 - 5 * launcherTabRow.spacing); height: 1 }

                Item {
                    width: 22
                    height: 22
                    MoveArrowButton {
                        anchors.fill: parent
                        iconText: "↑"
                        iconSize: Config.settingsUiSize(12)
                        baseColor: Config.text
                        hoverMode: "frame"
                        hoverColor: Config.accent
                        interactionEnabled: launcherTabRow.index > 0
                        toolTipText: "Поднять выше"
                        onClicked: root.moveTab(launcherTabRow.modelData.id, -1)
                    }
                }

                Item {
                    width: 22
                    height: 22
                    MoveArrowButton {
                        anchors.fill: parent
                        iconText: "↓"
                        iconSize: Config.settingsUiSize(12)
                        baseColor: Config.text
                        hoverMode: "frame"
                        hoverColor: Config.accent
                        interactionEnabled: launcherTabRow.index < root.orderedTabRows.length - 1
                        toolTipText: "Опустить ниже"
                        onClicked: root.moveTab(launcherTabRow.modelData.id, 1)
                    }
                }
            }
        }
    }


    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 3
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherProjects"] })
        heading: "Проекты"
        padding: 8
        contentSpacing: 6

        Repeater {
            model: Config.launcherProjects instanceof Array ? Config.launcherProjects.length : 0

            delegate: SettingsGroup {
                id: projectSettingsCard
                required property int index
                width: projectSettingsCard.parent ? projectSettingsCard.parent.width : root.width
                showFrame: true
                padding: 6
                contentSpacing: 4

                Row {
                    width: parent.width
                    height: 29
                    spacing: 5

                    SettingsTextField {
                        id: projectIconField
                        width: 48
                        height: 28
                        text: root.projectValue(projectSettingsCard.index, "icon")
                        placeholderText: "Иконка"
                        color: Config.text
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: Config.settingsUiSize(13)
                        horizontalAlignment: TextInput.AlignHCenter
                        onEditingFinished: root.updateProject(projectSettingsCard.index, "icon", text)
                    }

                    SettingsTextField {
                        id: projectNameField
                        width: Math.max(100, parent.width - 48 - 22 - 22 - 50 - 4 * parent.spacing)
                        height: 28
                        text: root.projectValue(projectSettingsCard.index, "name")
                        placeholderText: "Название"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        onEditingFinished: root.updateProject(projectSettingsCard.index, "name", text)
                    }

                    Item {
                        width: 22
                        height: 28
                        MoveArrowButton {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            iconText: "↑"
                            iconSize: Config.settingsUiSize(12)
                            baseColor: Config.text
                            hoverMode: "frame"
                            hoverColor: Config.accent
                            interactionEnabled: projectSettingsCard.index > 0
                            toolTipText: "Поднять выше"
                            onClicked: root.settings.moveLauncherProject(projectSettingsCard.index, -1)
                        }
                    }

                    Item {
                        width: 22
                        height: 28
                        MoveArrowButton {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            iconText: "↓"
                            iconSize: Config.settingsUiSize(12)
                            baseColor: Config.text
                            hoverMode: "frame"
                            hoverColor: Config.accent
                            interactionEnabled: projectSettingsCard.index < Config.launcherProjects.length - 1
                            toolTipText: "Опустить ниже"
                            onClicked: root.settings.moveLauncherProject(projectSettingsCard.index, 1)
                        }
                    }

                    SettingsButton {
                        width: 50
                        height: 28
                        text: "Удалить"
                        fontSize: 9
                        radius: 4
                        fillOnHover: false
                        borderOnHover: true
                        backgroundColor: Config.settingsBackground
                        textColor: Config.text
                        onClicked: root.settings.removeLauncherProject(projectSettingsCard.index)
                    }
                }

                SettingsTextField {
                    width: parent.width
                    height: 28
                    text: root.projectValue(projectSettingsCard.index, "path")
                    placeholderText: "Путь к проекту (например ~/WORK/project)"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    onEditingFinished: root.updateProject(projectSettingsCard.index, "path", text)
                }

                SettingsTextField {
                    width: parent.width
                    height: 28
                    text: root.projectValue(projectSettingsCard.index, "ide")
                    placeholderText: "IDE: полный путь к исполняемому файлу или команда"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    onEditingFinished: root.updateProject(projectSettingsCard.index, "ide", text)
                }
            }
        }

        SettingsButton {
            width: 165
            height: 30
            text: "+ Добавить проект"
            fontSize: 10
            radius: 4
            fillOnHover: false
            borderOnHover: true
            backgroundColor: Config.settingsBackground
            textColor: Config.text
            onClicked: root.settings.addLauncherProject()
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 4
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherCustomActions"] })
        heading: "Пользовательские действия"
        padding: 8
        contentSpacing: 7

        Text {
            width: parent.width
            text: "Действия доступны в обычном поиске Apps и через префикс > с любой вкладки Launcher. Для включённого действия обязательны название и команда; краткое описание можно оставить пустым. Новая запись создаётся с пустыми полями: подсказки внутри полей показывают, что нужно ввести. При сохранении любого поля проверяются название и команда. Незаполненное обязательное поле подсвечивается мягкой красной рамкой, а сохранение блокируется до исправления. Команда запускается через Zsh от имени текущего пользователя. Добавляйте только команды, которым доверяете."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: Array.isArray(Config.launcherCustomActions) ? Config.launcherCustomActions : []

            delegate: SettingsGroup {
                id: customActionCard
                required property var modelData
                required property int index
                property bool validationAttempted: false
                property bool validationTargetEnabled: modelData.enabled !== false
                property var pendingEnabledOverride: null
                width: customActionCard.parent ? customActionCard.parent.width : root.width
                showFrame: true

                function saveAction(enabledOverride) {
                    var nextEnabled = enabledOverride === undefined
                        ? (pendingEnabledOverride === null ? modelData.enabled !== false : !!pendingEnabledOverride)
                        : !!enabledOverride
                    var actionName = String(customActionNameField.text || "").trim()
                    var actionCommand = String(customActionCommandField.text || "").trim()
                    var validation = LauncherActions.validateRequiredFields({
                        enabled: nextEnabled,
                        name: actionName,
                        command: actionCommand
                    })
                    validationAttempted = true
                    validationTargetEnabled = nextEnabled
                    if (!validation.valid) {
                        pendingEnabledOverride = nextEnabled
                        if (validation.missingName) customActionNameField.forceActiveFocus()
                        else if (validation.missingCommand) customActionCommandField.forceActiveFocus()
                        return false
                    }
                    root.settings.updateLauncherCustomActionFields(customActionCard.index, {
                        enabled: nextEnabled,
                        icon: customActionIconField.text,
                        name: actionName,
                        description: customActionDescriptionField.text,
                        command: actionCommand
                    })
                    validationAttempted = false
                    pendingEnabledOverride = null
                    return true
                }
                changeKeys: ({ keys: ["launcherCustomActions"] })
                padding: 6
                contentSpacing: 5

                Row {
                    width: parent.width
                    height: 30
                    spacing: 5

                    SettingsCheckBox {
                        width: 34
                        height: 28
                        indicatorOnly: true
                        checked: customActionCard.modelData.enabled !== false
                        onToggled: customActionCard.saveAction(checked)
                    }

                    SettingsTextField {
                        id: customActionIconField
                        width: 48
                        height: 28
                        text: String(customActionCard.modelData.icon || "󰌌")
                        placeholderText: "Иконка"
                        color: Config.text
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: Config.settingsUiSize(13)
                        horizontalAlignment: TextInput.AlignHCenter
                        onEditingFinished: customActionCard.saveAction()
                    }

                    SettingsTextField {
                        id: customActionNameField
                        width: Math.max(90, parent.width - 34 - 48 - 22 - 22 - 54 - 5 * parent.spacing)
                        height: 28
                        validationFailed: customActionCard.validationAttempted
                            && customActionCard.validationTargetEnabled && text.trim().length === 0
                        text: String(customActionCard.modelData.name || "")
                        placeholderText: "Название действия (обязательно)"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        onEditingFinished: customActionCard.saveAction()
                    }

                    Item {
                        width: 22
                        height: 28
                        MoveArrowButton {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            iconText: "↑"
                            iconSize: Config.settingsUiSize(12)
                            baseColor: Config.text
                            hoverMode: "frame"
                            hoverColor: Config.accent
                            interactionEnabled: customActionCard.index > 0
                            toolTipText: "Поднять выше"
                            onClicked: root.settings.moveLauncherCustomAction(customActionCard.index, -1)
                        }
                    }

                    Item {
                        width: 22
                        height: 28
                        MoveArrowButton {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            iconText: "↓"
                            iconSize: Config.settingsUiSize(12)
                            baseColor: Config.text
                            hoverMode: "frame"
                            hoverColor: Config.accent
                            interactionEnabled: customActionCard.index < Config.launcherCustomActions.length - 1
                            toolTipText: "Опустить ниже"
                            onClicked: root.settings.moveLauncherCustomAction(customActionCard.index, 1)
                        }
                    }

                    SettingsButton {
                        width: 54
                        height: 28
                        text: "Удалить"
                        fontSize: 9
                        radius: 4
                        fillOnHover: false
                        borderOnHover: true
                        backgroundColor: Config.settingsBackground
                        textColor: Config.text
                        onClicked: root.settings.removeLauncherCustomAction(customActionCard.index)
                    }
                }

                SettingsTextField {
                    id: customActionDescriptionField
                    width: parent.width
                    height: 28
                    text: String(customActionCard.modelData.description || "")
                    placeholderText: "Краткое описание действия (необязательно)"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    onEditingFinished: customActionCard.saveAction()
                }

                Row {
                    width: parent.width
                    height: 28
                    spacing: 6

                    SettingsTextField {
                        id: customActionCommandField
                        width: Math.max(100, parent.width - 130)
                        height: 28
                        validationFailed: customActionCard.validationAttempted
                            && customActionCard.validationTargetEnabled && text.trim().length === 0
                        text: String(customActionCard.modelData.command || "")
                        placeholderText: "Команда для запуска (обязательно), например: foot -- nvim ~/WORK"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        // Every commit path validates and saves the whole action, including when this
                        // field was never visited and a different field is edited or submitted.
                        onAccepted: customActionCard.saveAction()
                        onEditingFinished: customActionCard.saveAction()
                    }

                    SettingsButton {
                        width: 124
                        height: 28
                        text: "Сохранить действие"
                        fontSize: 8
                        radius: 4
                        fillOnHover: false
                        borderOnHover: true
                        backgroundColor: Config.settingsBackground
                        textColor: Config.text
                        tooltip: "Проверить обязательные поля и сохранить действие"
                        onClicked: customActionCard.saveAction()
                    }
                }
            }
        }

        SettingsButton {
            width: 175
            height: 30
            enabled: !(Array.isArray(Config.launcherCustomActions)) || Config.launcherCustomActions.length < 100
            text: "+ Добавить действие"
            fontSize: 10
            radius: 4
            fillOnHover: false
            borderOnHover: true
            backgroundColor: Config.settingsBackground
            textColor: Config.text
            onClicked: root.settings.addLauncherCustomAction()
        }
    }

    SettingsAnimationGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 5
        width: parent.width
        settings: root.settings
        heading: "Внутренние переходы лаунчера"
        detailsHeading: "Параметры анимации"
        profile: Config.animationLauncherMorphProfile
        duration: Config.animationLauncherMorphDuration
        changeKeys: ({ keys: ["animationLauncherMorphDuration", "animationLauncherMorphProfile"] })
        onDurationEdited: function(value) {
            Config.animationLauncherMorphDuration = Math.max(0, Math.min(5000, Math.round(Number(value) || 0)))
            root.settings.save()
        }
        onProfileEdited: function(value) {
            Config.animationLauncherMorphProfile = value
            root.settings.save()
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageSubTabIndex === 6
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["launcherFavoriteApps", "launcherHiddenApps"] })
        heading: "Избранные и скрытые приложения"
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Избранные приложения поднимаются в начало списка Apps. Скрытые приложения не показываются в поиске, включая фильтры @. Один и тот же пункт нельзя одновременно добавить в избранное и скрыть."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        SettingsInputField {
            id: launcherApplicationPreferenceSearch
            width: parent.width
            height: 30
            placeholderText: "Найти установленное приложение…"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            onTextChanged: root.applicationPreferenceSearch = text
        }

        Row {
            width: parent.width
            height: 22
            spacing: 6
            Text {
                width: Math.max(80, parent.width - 150)
                text: "Приложение"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 66
                text: "Избр."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 66
                text: "Скрыть"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Repeater {
            model: root.applicationPreferenceRows
            delegate: Row {
                required property var modelData
                width: parent.width
                height: 34
                spacing: 6

                Column {
                    width: Math.max(80, parent.width - 150)
                    height: parent.height
                    spacing: 1
                    Text {
                        width: parent.width
                        height: 17
                        text: modelData.name
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        width: parent.width
                        height: 14
                        text: modelData.comment || modelData.id
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(8)
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                SettingsCheckBox {
                    width: 66
                    height: 30
                    indicatorOnly: true
                    checked: modelData.favorite
                    ToolTip.visible: pointerHovered
                    ToolTip.text: modelData.favorite ? "Убрать из избранного" : "Добавить в избранное"
                    ToolTip.delay: 450
                    onToggled: root.setLauncherAppPreference("favorite", modelData.id, checked)
                }

                SettingsCheckBox {
                    width: 66
                    height: 30
                    indicatorOnly: true
                    checked: modelData.hidden
                    ToolTip.visible: pointerHovered
                    ToolTip.text: modelData.hidden ? "Показать в Launcher Apps" : "Скрыть из Launcher Apps"
                    ToolTip.delay: 450
                    onToggled: root.setLauncherAppPreference("hidden", modelData.id, checked)
                }
            }
        }

        Text {
            visible: root.applicationPreferenceRows.length === 0
            width: parent.width
            text: root.applicationPreferenceSearch.trim().length > 0
                ? "Ничего не найдено."
                : "Пока нет выбранных приложений. Введите часть названия, чтобы найти приложение и добавить его в избранное или скрыть."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Text {
            visible: root.applicationPreferenceSearch.trim().length > 0 && root.applicationPreferenceRows.length === 40
            width: parent.width
            text: "Выдача ограничена 40 совпадениями. Уточните запрос, чтобы найти нужное приложение."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(8)
            wrapMode: Text.WordWrap
        }
    }

}
