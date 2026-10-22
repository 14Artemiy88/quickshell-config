import QtQuick
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 11
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
        { id: 8, label: "Projects", icon: "" }
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

    readonly property var orderedTabRows: {
        var order = root.normalizedTabOrder()
        var visibility = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible : []
        var result = []
        for (var i = 0; i < order.length; ++i) {
            var id = order[i]
            var definition = root.tabDefinitions[id]
            result.push({ id: id, label: definition.label, icon: definition.icon, visible: visibility[id] === undefined ? true : !!visibility[id] })
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
        var next = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible.slice(0) : [true, true, true, true, true, true, true, true, true]
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

    SettingsGroup {
        visible: root.host && root.host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 7

        Text {
            text: "Поведение при открытии"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

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
                model: ["Apps — Приложения", "Run — Команды", "Windows — Окна", "Clipboard — Буфер обмена", "Power — Питание", "Network — Сети", "Packages — Nix", "Pass — Пароли", "Projects — Проекты"]
                currentIndex: Math.max(0, Math.min(8, Number(Config.launcherDefaultMode) || 0))
                onItemChosen: index => {
                    Config.launcherDefaultMode = Math.max(0, Math.min(8, index))
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onLauncherDefaultModeChanged() {
                        launcherDefaultModeCombo.currentIndex = Math.max(0, Math.min(8, Number(Config.launcherDefaultMode) || 0))
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
        visible: root.host && root.host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            text: "Окно лаунчера"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

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
        visible: root.host && root.host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 7

        Text {
            text: "Элемент списка"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

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
        visible: root.host && root.host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            text: "Заголовок лаунчера"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

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
            SettingsTextField {
                id: launcherTitleFontField
                width: Math.min(260, parent.width - 198)
                height: 30
                text: Config.launcherTitleFont
                placeholderText: "По умолчанию"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                onEditingFinished: { Config.launcherTitleFont = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 128); text = Config.launcherTitleFont; root.settings.save() }
                Connections { target: Config; function onLauncherTitleFontChanged() { launcherTitleFontField.text = Config.launcherTitleFont } }
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
        visible: root.host && root.host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            text: "Строка поиска"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

        Row {
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 190; height: 30; text: "Шрифт поиска"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsTextField {
                id: launcherSearchFontField
                width: Math.min(260, parent.width - 198)
                height: 30
                text: Config.launcherSearchFont.trim() === "" ? "JetBrainsMono Nerd Font" : Config.launcherSearchFont
                placeholderText: "По умолчанию"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                onEditingFinished: { Config.launcherSearchFont = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 128); text = Config.launcherSearchFont; root.settings.save() }
                Connections { target: Config; function onLauncherSearchFontChanged() { launcherSearchFontField.text = Config.launcherSearchFont.trim() === "" ? "JetBrainsMono Nerd Font" : Config.launcherSearchFont } }
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
        visible: root.host && root.host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            text: "Сквозной поиск"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

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
    }

    SettingsGroup {
        visible: root.host && root.host.currentOtherSubTab === 1
        width: parent.width
        showFrame: true
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
                width: 28
                text: "Иконка"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: 150
                text: "Вкладка"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
            }
            Item { width: Math.max(0, parent.width - 40 - 28 - 150 - 72 - 24); height: 1 }
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
                    enabled: launcherTabRow.modelData.visible || root.visibleTabCount() > 1
                    checked: launcherTabRow.modelData.visible
                    onToggled: root.setTabVisible(launcherTabRow.modelData.id, checked)
                }

                Text {
                    width: 28
                    height: 30
                    text: launcherTabRow.modelData.icon
                    color: Config.text
                    font.family: "Symbols Nerd Font Mono"
                    font.pixelSize: Config.settingsUiSize(15)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: 150
                    height: 30
                    text: launcherTabRow.modelData.label
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                }

                Item { width: Math.max(0, launcherTabRow.width - 40 - 28 - 150 - 44 - 5 * launcherTabRow.spacing); height: 1 }

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
        visible: root.host && root.host.currentOtherSubTab === 2
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            text: "Проекты"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

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
}
