import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../../js/launcher/LauncherAppPreferences.js" as LauncherAppPreferences
import "../../../js/notifications/NotificationAppSearch.js" as NotificationAppSearch
import "../../../js/notifications/NotificationAppCatalog.js" as NotificationAppCatalog

Column {
    id: root

    property var host
    property var settings: Settings
    property string pageId: "notifications"
    property string dndApplicationSearch: ""
    property bool dndShowAllApplications: false

    function normalizedDndRuleIds(value) {
        return NotificationAppCatalog.normalizeDndRuleIds(value)
    }

    function migrateLegacyDndCharacterRules() {
        var allowed = root.normalizedDndRuleIds(Config.notificationsDndAllowedApps)
        var blocked = root.normalizedDndRuleIds(Config.notificationsDndBlockedApps)
        var nextAllowed = allowed.join(";")
        var nextBlocked = blocked.join(";")
        var changed = false
        if (nextAllowed !== String(Config.notificationsDndAllowedApps || "")) {
            Config.notificationsDndAllowedApps = nextAllowed
            changed = true
        }
        if (nextBlocked !== String(Config.notificationsDndBlockedApps || "")) {
            Config.notificationsDndBlockedApps = nextBlocked
            changed = true
        }
        if (changed) root.settings.save()
    }

    function setDndApplicationRule(kind, appIds, enabled) {
        var identities = root.normalizedDndRuleIds(appIds)
        if (identities.length === 0) return

        // Each column owns an independent persisted list. Do not rewrite the
        // other property when one rule is toggled.
        if (kind === "allowed") {
            var allowed = root.normalizedDndRuleIds(Config.notificationsDndAllowedApps)
            for (var i = 0; i < identities.length; ++i)
                allowed = LauncherAppPreferences.setId(allowed, identities[i], enabled)
            var nextAllowed = allowed.join(";")
            if (nextAllowed === String(Config.notificationsDndAllowedApps || "")) return
            Config.notificationsDndAllowedApps = nextAllowed
        } else if (kind === "blocked") {
            var blocked = root.normalizedDndRuleIds(Config.notificationsDndBlockedApps)
            for (var j = 0; j < identities.length; ++j)
                blocked = LauncherAppPreferences.setId(blocked, identities[j], enabled)
            var nextBlocked = blocked.join(";")
            if (nextBlocked === String(Config.notificationsDndBlockedApps || "")) return
            Config.notificationsDndBlockedApps = nextBlocked
        } else {
            return
        }
        root.settings.save()
    }

    function removeDndApplication(entry) {
        if (!entry || entry.kind === "category") return

        var senders = NotificationAppCatalog.valuesOf(Config.notificationsSeenSenders)
        var remainingSenders = NotificationAppCatalog.removeSenderById(senders, entry.id)
        var removableIds = NotificationAppCatalog.removableRuleIds(entry, remainingSenders)
        var allowed = root.normalizedDndRuleIds(Config.notificationsDndAllowedApps)
        var blocked = root.normalizedDndRuleIds(Config.notificationsDndBlockedApps)

        for (var i = 0; i < removableIds.length; ++i) {
            allowed = LauncherAppPreferences.setId(allowed, removableIds[i], false)
            blocked = LauncherAppPreferences.setId(blocked, removableIds[i], false)
        }

        var nextAllowed = allowed.join(";")
        var nextBlocked = blocked.join(";")
        var settingsChanged = nextAllowed !== String(Config.notificationsDndAllowedApps || "")
            || nextBlocked !== String(Config.notificationsDndBlockedApps || "")

        Config.notificationsSeenSenders = remainingSenders
        if (nextAllowed !== String(Config.notificationsDndAllowedApps || ""))
            Config.notificationsDndAllowedApps = nextAllowed
        if (nextBlocked !== String(Config.notificationsDndBlockedApps || ""))
            Config.notificationsDndBlockedApps = nextBlocked
        if (settingsChanged) root.settings.save()
    }

    // DND's catalog is learned from actual notification senders, not every
    // installed desktop entry. Previously configured rules are merged by the
    // search helper so they remain removable after a restart.
    readonly property var dndApplicationRows: NotificationAppSearch.buildRows(
        Config.notificationsSeenSenders || [],
        root.normalizedDndRuleIds(Config.notificationsDndAllowedApps),
        root.normalizedDndRuleIds(Config.notificationsDndBlockedApps),
        root.dndApplicationSearch, 40,
        Config.launcherFuzzySearchApps !== false,
        LauncherAppPreferences.normalizeIds(Config.launcherFavoriteApps || []),
        root.dndShowAllApplications)
    readonly property int dndApplicationRowCount: Array.isArray(root.dndApplicationRows)
        ? root.dndApplicationRows.length : 0

    readonly property bool dndPage: root.pageId === "notificationsDnd" && host && host.currentPageId === root.pageId
    readonly property int dndSubTab: host ? host.currentPageSubTabIndex : 0

    Component.onCompleted: Qt.callLater(root.migrateLegacyDndCharacterRules)

    visible: host && host.currentPageId === root.pageId
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
        visible: root.dndPage
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsDoNotDisturb", "notificationsDndAllowedApps", "notificationsDndBlockedApps", "notificationsHistoryLimit", "notificationsHistoryRetentionDays"] })
        heading: root.dndSubTab === 0 ? "Режим Не беспокоить" : (root.dndSubTab === 1 ? "Правила приложений" : "История уведомлений")
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            id: notificationsDoNotDisturbCheck
            visible: root.dndSubTab === 0
            width: parent.width
            height: 28
            text: "Не беспокоить"
            checked: Config.notificationsDoNotDisturb
            settingsSearchId: "notifications-do-not-disturb"
            settingsSearchLabel: "Не беспокоить: скрывать всплывающие уведомления"
            settingsSearchKeywords: "уведомления режим тишина dnd do not disturb подавлять скрывать без звука"
            onToggled: {
                Config.notificationsDoNotDisturb = checked
                root.settings.save()
            }
            Connections {
                target: Config
                function onNotificationsDoNotDisturbChanged() {
                    notificationsDoNotDisturbCheck.checked = Config.notificationsDoNotDisturb
                }
            }
        }
        Text {
            visible: root.dndSubTab === 0
            width: parent.width
            text: "Входящие уведомления продолжают приниматься, но всплывающие карточки не показываются. Последние уведомления доступны в истории Dashboard; история ограничена 200 записями и хранится только в оперативной памяти, без записи содержимого на диск."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        SettingsRow {
            visible: root.dndSubTab === 2
            width: parent.width
            height: 30
            spacing: 8
            label: "Размер истории"
            labelWidth: 120
            labelElide: Text.ElideRight
            SettingsNumberField {
                id: notificationsHistoryLimitField
                width: 100
                height: 30
                value: Config.notificationsHistoryLimit
                minimum: 1
                maximum: 200
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                onValueEdited: value => {
                    Config.notificationsHistoryLimit = Math.max(1, Math.min(200, Math.round(value)))
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onNotificationsHistoryLimitChanged() {
                        notificationsHistoryLimitField.value = Config.notificationsHistoryLimit
                    }
                }
            }
        }
        Text {
            visible: root.dndSubTab === 2
            width: parent.width
            text: "Количество последних уведомлений, сохраняемых в оперативной памяти. Допустимо от 1 до 200; содержимое не записывается на диск."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
        SettingsRow {
            visible: root.dndSubTab === 2
            width: parent.width
            height: 30
            spacing: 8
            label: "Срок хранения, дни"
            labelWidth: 120
            labelElide: Text.ElideRight
            SettingsNumberField {
                id: notificationsHistoryRetentionField
                width: 100
                height: 30
                value: Config.notificationsHistoryRetentionDays
                minimum: 0
                maximum: 365
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                onValueEdited: value => {
                    Config.notificationsHistoryRetentionDays = Math.max(0, Math.min(365, Math.round(value)))
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onNotificationsHistoryRetentionDaysChanged() {
                        notificationsHistoryRetentionField.value = Config.notificationsHistoryRetentionDays
                    }
                }
            }
        }
        Text {
            visible: root.dndSubTab === 2
            width: parent.width
            text: "0 — без ограничения по возрасту. От 1 до 365 дней — автоматически удалять более старые записи. Лимит по количеству действует всегда."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Text {
            visible: root.dndSubTab === 1
            width: parent.width
            text: "В списке появляются приложения, от которых Quickshell уже получил уведомления. «Игнор DND» оставляет их уведомления видимыми при включённом режиме. «Отключить» подавляет их уведомления при выключенном режиме. Ранее настроенные правила остаются доступны после перезапуска; кнопка с корзиной удаляет запись и оба правила."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Row {
            visible: root.dndSubTab === 1
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField {
                id: notificationsDndApplicationSearch
                width: Math.max(100, parent.width - 126)
                height: 30
                text: root.dndApplicationSearch
                placeholderText: "Найти отправителя уведомлений…"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                selectByMouse: true
                onTextEdited: root.dndApplicationSearch = text
            }
            SettingsCheckBox {
                id: notificationsDndShowAllCheck
                width: 118
                height: 30
                text: "Показать все"
                labelFontSize: 9
                checked: root.dndShowAllApplications
                ToolTip.visible: pointerHovered
                ToolTip.text: "Показать всех отправителей, от которых Quickshell уже получал уведомления, а не только приложения с настроенными правилами."
                ToolTip.delay: 450
                onToggled: root.dndShowAllApplications = checked
            }
        }

        Row {
            visible: root.dndSubTab === 1
            width: parent.width
            height: 28
            spacing: 6
            Text {
                width: Math.max(70, parent.width - 200)
                text: "Приложение"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 82
                text: "Игнор DND"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(8)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 82
                text: "Отключить"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(8)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Item { width: 24; height: 1 }
        }

        Repeater {
            visible: root.dndSubTab === 1
            model: root.dndSubTab === 1 ? root.dndApplicationRows : []
            delegate: Item {
                required property var modelData
                width: parent.width
                height: 34
                Row {
                    anchors.fill: parent
                    spacing: 6
                    Column {
                        width: modelData.kind === "category"
                            ? parent.width : Math.max(70, parent.width - 206)
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
                        visible: modelData.kind !== "category"
                        width: 82
                        height: 30
                        indicatorOnly: true
                        checked: modelData.allowed
                        ToolTip.visible: pointerHovered
                        ToolTip.text: "Игнорировать общий режим DND для этого приложения: показывать его уведомления, даже когда DND включён."
                        ToolTip.delay: 450
                        onToggled: root.setDndApplicationRule("allowed", modelData.ruleIds || [modelData.id], checked)
                    }
                    SettingsCheckBox {
                        visible: modelData.kind !== "category"
                        width: 82
                        height: 30
                        indicatorOnly: true
                        checked: modelData.blocked
                        ToolTip.visible: pointerHovered
                        ToolTip.text: "Отключить всплывающие уведомления этого приложения, когда общий режим DND выключен."
                        ToolTip.delay: 450
                        onToggled: root.setDndApplicationRule("blocked", modelData.ruleIds || [modelData.id], checked)
                    }
                    SettingsResetButton {
                        visible: modelData.kind !== "category"
                        width: 24
                        height: 26
                        label: ""
                        iconText: "\uf1f8"
                        fontSize: 9
                        tooltip: "Удалить приложение из списка и снять оба его правила DND"
                        emphasized: true
                        emphasizedHoverOnly: true
                        emphasizedColor: "#663333"
                        emphasizedHoverColor: "#aa3333"
                        onClicked: root.removeDndApplication(modelData)
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    z: 2
                    enabled: modelData.kind === "category"
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        root.dndApplicationSearch = "@c " + modelData.category
                        notificationsDndApplicationSearch.forceActiveFocus()
                        notificationsDndApplicationSearch.cursorPosition = root.dndApplicationSearch.length
                    }
                }
            }
        }

        Text {
            visible: root.dndSubTab === 1 && root.dndApplicationRowCount === 0
            width: parent.width
            text: root.dndApplicationSearch.trim().startsWith("@")
                ? "@i ID\n@c category\n@d description\n@e command\n@w WM_CLASS\n@g generic name\n@k keywords\n@t apps inside terminal"
                : (root.dndApplicationSearch.trim().length > 0
                    ? "Ничего не найдено."
                    : (root.dndShowAllApplications
                        ? "Пока нет отправителей уведомлений. Приложения появятся здесь после того, как Quickshell получит от них первое уведомление."
                        : "Нет приложений с настроенными правилами. Включите «Показать все», чтобы увидеть остальных отправителей уведомлений."))
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
        Text {
            visible: root.dndSubTab === 1 && root.dndApplicationSearch.trim().length > 0 && root.dndApplicationRowCount === 40
            width: parent.width
            text: "Показаны первые 40 совпадений. Уточните запрос, чтобы найти нужное приложение."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(8)
            wrapMode: Text.WordWrap
        }

    }

    SettingsGroup {
                visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsDefaultTimeout", "notificationsCriticalTimeout", "notificationsShowTimeoutIndicator", "notificationsTimeoutIndicatorColor", "notificationsTimeoutIndicatorStyle", "notificationsTimeoutIndicatorDirection"] })
        heading: "Тайм-ауты"
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Сервер уведомлений работает, пока модуль включён в разделе «Модули». Здесь настраиваются тайм-ауты и содержимое карточек."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: "Время указывается в секундах. Значение 0 отключает автоматическое закрытие. Явный тайм-аут, переданный приложением, имеет приоритет."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Обычные уведомления (с)"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                width: 100
                height: 30
                value: Math.round(Config.notificationsDefaultTimeout / 1000)
                minimum: 0
                maximum: 120
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                onValueEdited: value => {
                    Config.notificationsDefaultTimeout = Math.round(value * 1000)
                    root.settings.save()
                }
            }
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Критические уведомления (с)"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                width: 100
                height: 30
                value: Math.round(Config.notificationsCriticalTimeout / 1000)
                minimum: 0
                maximum: 120
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                onValueEdited: value => {
                    Config.notificationsCriticalTimeout = Math.round(value * 1000)
                    root.settings.save()
                }
            }
        }

        Text {
            width: parent.width
            text: "По умолчанию критические уведомления не закрываются автоматически."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        SettingsCheckBox {
            id: notificationsShowTimeoutIndicatorCheck
            width: parent.width
            height: 28
            text: "Показывать время до закрытия"
            checked: Config.notificationsShowTimeoutIndicator
            onToggled: { Config.notificationsShowTimeoutIndicator = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowTimeoutIndicatorChanged() { notificationsShowTimeoutIndicatorCheck.checked = Config.notificationsShowTimeoutIndicator } }
        }
        Text {
            width: parent.width
            text: "Индикатор показывает оставшееся время до автоматического закрытия. При наведении на карточку отсчёт приостанавливается."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Вид индикатора"
            labelWidth: 220
            labelElide: Text.ElideRight
            SettingsComboBox {
                id: notificationsTimeoutIndicatorStyleCombo
                width: 140
                height: 30
                model: ["Полоса", "Рамка"]
                currentIndex: Config.notificationsTimeoutIndicatorStyle === "border" ? 1 : 0
                settingsSearchId: "notifications-timeout-indicator-style"
                settingsSearchLabel: "Вид индикатора оставшегося времени"
                settingsSearchKeywords: "уведомления таймер обратный отсчёт полоса рамка периметр border outline style"
                onItemChosen: index => {
                    Config.notificationsTimeoutIndicatorStyle = index === 1 ? "border" : "bar"
                    root.settings.save()
                }
            }
        }
        Connections {
            target: Config
            function onNotificationsTimeoutIndicatorStyleChanged() {
                notificationsTimeoutIndicatorStyleCombo.currentIndex = Config.notificationsTimeoutIndicatorStyle === "border" ? 1 : 0
            }
        }
        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            visible: Config.notificationsTimeoutIndicatorStyle === "border"
            label: "Направление рамки"
            labelWidth: 220
            labelElide: Text.ElideRight
            SettingsComboBox {
                id: notificationsTimeoutIndicatorDirectionCombo
                width: 180
                height: 30
                model: ["По часовой стрелке", "Против часовой стрелки"]
                currentIndex: Config.notificationsTimeoutIndicatorDirection === "counterclockwise" ? 1 : 0
                settingsSearchId: "notifications-timeout-indicator-direction"
                settingsSearchLabel: "Направление исчезновения рамки уведомления"
                settingsSearchKeywords: "уведомления таймер рамка направление по часовой против часовой clockwise counterclockwise reverse обратное периметр"
                onItemChosen: index => {
                    Config.notificationsTimeoutIndicatorDirection = index === 1 ? "counterclockwise" : "clockwise"
                    root.settings.save()
                }
            }
        }
        Connections {
            target: Config
            function onNotificationsTimeoutIndicatorDirectionChanged() {
                notificationsTimeoutIndicatorDirectionCombo.currentIndex = Config.notificationsTimeoutIndicatorDirection === "counterclockwise" ? 1 : 0
            }
        }
        SettingsColorField {
            width: parent.width
            label: "Цвет индикатора"
            value: String(Config.notificationsTimeoutIndicatorColor || Config.accent)
            targetObject: Config
            targetProperty: "notificationsTimeoutIndicatorColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: false
            allowTransparent: false
            labelWidth: 220
            fieldWidth: 120
            settingsSearchId: "notifications-timeout-indicator-color"
            settingsSearchLabel: "Цвет полосы или рамки оставшегося времени уведомления"
            settingsSearchKeywords: "уведомления countdown таймер цвет полоска рамка progress accent"
        }
        Text {
            width: parent.width
            text: "Пустое значение использует основной цвет темы. Цвет применяется и к полосе, и к рамке. Для рамки можно выбрать направление обхода."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
                visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] })
        heading: "Интервалы и изображения"
        padding: 8
        contentSpacing: 6

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Расстояние между карточками"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                value: Config.notificationsCardSpacing
                minimum: 0
                maximum: 32
                step: 1
                wheelStep: 1
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                targetObject: Config
                targetProperty: "notificationsCardSpacing"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Максимальная высота превью"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                value: Config.notificationsImageHeight
                minimum: 0
                maximum: 320
                step: 8
                wheelStep: 8
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                targetObject: Config
                targetProperty: "notificationsImageHeight"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
                visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] })
        heading: "Элементы карточки"
        padding: 8
        contentSpacing: 4

        SettingsCheckBox {
            id: notificationsShowAppIconCheck
            width: parent.width
            height: 28
            text: "Показывать иконку приложения"
            checked: Config.notificationsShowAppIcon
            onToggled: { Config.notificationsShowAppIcon = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowAppIconChanged() { notificationsShowAppIconCheck.checked = Config.notificationsShowAppIcon } }
        }
        SettingsCheckBox {
            id: notificationsShowBodyImagesCheck
            width: parent.width
            height: 28
            text: "Показывать изображения в сообщениях"
            checked: Config.notificationsShowBodyImages
            onToggled: { Config.notificationsShowBodyImages = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowBodyImagesChanged() { notificationsShowBodyImagesCheck.checked = Config.notificationsShowBodyImages } }
        }
        SettingsCheckBox {
            id: notificationsShowProgressCheck
            width: parent.width
            height: 28
            text: "Показывать индикатор прогресса"
            checked: Config.notificationsShowProgress
            onToggled: { Config.notificationsShowProgress = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowProgressChanged() { notificationsShowProgressCheck.checked = Config.notificationsShowProgress } }
        }
    }
    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsLeadingVisualSize"] })
        heading: "Заголовок и иконка"
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт заголовка"
            value: Config.notificationsSummaryFont
            targetObject: Config
            targetProperty: "notificationsSummaryFont"
            settingsObject: root.settings
            saveOnEdit: true
            labelWidth: 220
            fieldWidth: 150
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Размер заголовка"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.notificationsSummaryFontSize
                minimum: 8
                maximum: 32
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "notificationsSummaryFontSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsColorField {
            width: parent.width
            label: "Цвет заголовка"
            value: String(Config.notificationsSummaryColor || Config.text)
            targetObject: Config
            targetProperty: "notificationsSummaryColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: false
            labelWidth: 220
            fieldWidth: 120
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Размер иконки / аватара"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.notificationsLeadingVisualSize
                minimum: 24
                maximum: 72
                step: 2
                wheelStep: 2
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "notificationsLeadingVisualSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Text {
            width: parent.width
            text: "Пустой шрифт использует системный. Размер иконки применяется одинаково к иконкам приложений, аватарам и ведущим изображениям."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold"] })
        heading: "Название приложения"
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт названия"
            value: Config.notificationsAppNameFont
            targetObject: Config
            targetProperty: "notificationsAppNameFont"
            settingsObject: root.settings
            saveOnEdit: true
            labelWidth: 220
            fieldWidth: 150
        }
        SettingsRow {
            width: parent.width
            height: 30
            label: "Размер названия"
            labelWidth: 220
            labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsAppNameFontSize
                minimum: 8; maximum: 24; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsAppNameFontSize"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsColorField {
            width: parent.width
            label: "Цвет названия"
            value: String(Config.notificationsAppNameColor || Config.text)
            targetObject: Config; targetProperty: "notificationsAppNameColor"
            settingsObject: root.settings; saveOnEdit: true
            allowAlpha: true; allowTransparent: false
            labelWidth: 220; fieldWidth: 120
        }
        SettingsCheckBox {
            width: parent.width; height: 28
            text: "Полужирное начертание"
            checked: Config.notificationsAppNameBold
            onToggled: { Config.notificationsAppNameBold = checked; root.settings.save() }
        }
        Text {
            width: parent.width
            text: "Пустой шрифт и цвет используют системное семейство и активный цвет текста."
            color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsLeadingVisualRadius"] })
        heading: "Скругление иконки / аватара"
        padding: 8
        contentSpacing: 6
        SettingsRow {
            width: parent.width; height: 30
            label: "Радиус скругления"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsLeadingVisualRadius
                minimum: 0; maximum: 36; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsLeadingVisualRadius"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        Text { width: parent.width; text: "0 — квадратные углы; максимальный радиус автоматически ограничивается половиной размера изображения."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); wrapMode: Text.WordWrap }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsCardPadding"] })
        heading: "Внутренние отступы карточки"
        padding: 8
        contentSpacing: 6
        SettingsRow {
            width: parent.width; height: 30
            label: "Отступ от краёв"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsCardPadding
                minimum: 0; maximum: 32; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsCardPadding"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor"] })
        heading: "Основной текст уведомления"
        padding: 8
        contentSpacing: 6
        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт основного текста"
            value: Config.notificationsBodyFont
            targetObject: Config
            targetProperty: "notificationsBodyFont"
            settingsObject: root.settings
            saveOnEdit: true
            labelWidth: 220
            fieldWidth: 150
            placeholderText: "Системный шрифт"
            settingsSearchId: "notifications-body-font"
            settingsSearchLabel: "Шрифт основного текста уведомления"
            settingsSearchKeywords: "основной текст тело сообщения уведомления шрифт family body font"
        }
        SettingsRow {
            width: parent.width; height: 30
            label: "Размер текста"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsBodyFontSize
                minimum: 8; maximum: 32; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsBodyFontSize"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsColorField {
            width: parent.width; label: "Цвет текста"
            value: String(Config.notificationsBodyColor || Config.text)
            targetObject: Config; targetProperty: "notificationsBodyColor"
            settingsObject: root.settings; saveOnEdit: true
            allowAlpha: true; allowTransparent: false
            labelWidth: 220; fieldWidth: 120
        }
        Text { width: parent.width; text: "Пустой цвет использует основной цвет активной темы."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); wrapMode: Text.WordWrap }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsBackgroundColor"] })
        heading: "Фон уведомлений"
        padding: 8
        contentSpacing: 6

        SettingsColorField {
            width: parent.width
            label: "Цвет и прозрачность"
            value: String(Config.notificationsBackgroundColor)
            targetObject: Config
            targetProperty: "notificationsBackgroundColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            labelWidth: 220
            fieldWidth: 120
        }
    }

    SettingsGroup {
                visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsVerticalAnchor"] })
        heading: "Расположение"
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Уведомления можно привязать к верхнему или нижнему краю выбранного монитора. Горизонтальная координата X всегда отсчитывается слева."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Вертикальная привязка"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsComboBox {
                id: notificationsVerticalAnchorCombo
                width: 140
                height: 30
                model: ["Сверху", "Снизу"]
                currentIndex: Config.notificationsVerticalAnchor === "bottom" ? 1 : 0
                onItemChosen: index => root.settings.setNotificationsVerticalAnchor(index === 1 ? "bottom" : "top")
            }
        }
    }

    SettingsAnimationGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 3
        width: parent.width
        settings: root.settings
        heading: "Переходы карточек уведомлений"
        detailsHeading: "Параметры переходов"
        changeKeys: ({ keys: ["animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle"] })
        duration: Config.animationNotificationsMorphDuration
        durationLabel: "Длительность (мс)"
        minimumDuration: 0
        maximumDuration: 2000
        durationStep: 10
        profile: Config.animationNotificationsMorphProfile
        onDurationEdited: value => {
            Config.animationNotificationsMorphDuration = Math.max(0, Math.min(2000, Math.round(Number(value) || 0)))
            root.settings.save()
        }
        onProfileEdited: value => {
            Config.animationNotificationsMorphProfile = value
            root.settings.save()
        }

        SettingsGroup {
            width: parent.width
            showFrame: true
            heading: "Вид появления и исчезновения"
            changeKeys: ({ keys: ["animationNotificationsVisibilityStyle"] })
            padding: 8
            contentSpacing: 6

            SettingsRow {
                label: "Направление движения"
                labelWidth: 210
                labelElide: Text.ElideRight
                width: parent.width
                height: 30
                spacing: 8

                

                SettingsComboBox {
                    id: notificationVisibilityStyleBox
                    width: 180
                    height: 30
                    property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                    model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                    currentIndex: Math.max(0, values.indexOf(Config.animationNotificationsVisibilityStyle))
                    onItemChosen: function(index) {
                        if (index >= 0 && index < values.length) {
                            Config.animationNotificationsVisibilityStyle = values[index]
                            root.settings.save()
                        }
                    }
                    Connections {
                        target: Config
                        function onAnimationNotificationsVisibilityStyleChanged() {
                            notificationVisibilityStyleBox.currentIndex = Math.max(0, notificationVisibilityStyleBox.values.indexOf(Config.animationNotificationsVisibilityStyle))
                        }
                    }
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (notificationVisibilityStyleBox.activeFocus || notificationVisibilityStyleBox.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: notificationVisibilityStyleBox.currentText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Стиль применяется к появлению и исчезновению новых карточек. Профиль кривой и длительность задают характер движения; перемещение остальных карточек в очереди настраивается отдельно."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }

}
