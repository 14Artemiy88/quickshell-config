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
        var historyIgnored = root.normalizedDndRuleIds(Config.notificationsHistoryIgnoredApps)
        var nextAllowed = allowed.join(";")
        var nextBlocked = blocked.join(";")
        var nextHistoryIgnored = historyIgnored.join(";")
        var changed = false
        if (nextAllowed !== String(Config.notificationsDndAllowedApps || "")) {
            Config.notificationsDndAllowedApps = nextAllowed
            changed = true
        }
        if (nextBlocked !== String(Config.notificationsDndBlockedApps || "")) {
            Config.notificationsDndBlockedApps = nextBlocked
            changed = true
        }
        if (nextHistoryIgnored !== String(Config.notificationsHistoryIgnoredApps || "")) {
            Config.notificationsHistoryIgnoredApps = nextHistoryIgnored
            changed = true
        }
        if (changed) root.settings.save()
    }

    function setDndApplicationRule(kind, appIds, enabled, legacyAliases) {
        var identities = root.normalizedDndRuleIds(appIds)
        var aliases = root.normalizedDndRuleIds(legacyAliases)
        if (identities.length === 0) return

        // Each column owns an independent persisted list. Do not rewrite the
        // other property when one rule is toggled.
        if (kind === "allowed") {
            var allowed = root.normalizedDndRuleIds(Config.notificationsDndAllowedApps)
            for (var a = 0; a < aliases.length; ++a)
                allowed = LauncherAppPreferences.setId(allowed, aliases[a], false)
            for (var i = 0; i < identities.length; ++i)
                allowed = LauncherAppPreferences.setId(allowed, identities[i], enabled)
            var nextAllowed = allowed.join(";")
            if (nextAllowed === String(Config.notificationsDndAllowedApps || "")) return
            Config.notificationsDndAllowedApps = nextAllowed
        } else if (kind === "blocked") {
            var blocked = root.normalizedDndRuleIds(Config.notificationsDndBlockedApps)
            for (var b = 0; b < aliases.length; ++b)
                blocked = LauncherAppPreferences.setId(blocked, aliases[b], false)
            for (var j = 0; j < identities.length; ++j)
                blocked = LauncherAppPreferences.setId(blocked, identities[j], enabled)
            var nextBlocked = blocked.join(";")
            if (nextBlocked === String(Config.notificationsDndBlockedApps || "")) return
            Config.notificationsDndBlockedApps = nextBlocked
        } else if (kind === "history") {
            var historyIgnored = root.normalizedDndRuleIds(Config.notificationsHistoryIgnoredApps)
            for (var h = 0; h < aliases.length; ++h)
                historyIgnored = LauncherAppPreferences.setId(historyIgnored, aliases[h], false)
            for (var k = 0; k < identities.length; ++k)
                historyIgnored = LauncherAppPreferences.setId(historyIgnored, identities[k], enabled)
            var nextHistoryIgnored = historyIgnored.join(";")
            if (nextHistoryIgnored === String(Config.notificationsHistoryIgnoredApps || "")) return
            Config.notificationsHistoryIgnoredApps = nextHistoryIgnored
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
        var historyIgnored = root.normalizedDndRuleIds(Config.notificationsHistoryIgnoredApps)

        for (var i = 0; i < removableIds.length; ++i) {
            allowed = LauncherAppPreferences.setId(allowed, removableIds[i], false)
            blocked = LauncherAppPreferences.setId(blocked, removableIds[i], false)
            historyIgnored = LauncherAppPreferences.setId(historyIgnored, removableIds[i], false)
        }

        var nextAllowed = allowed.join(";")
        var nextBlocked = blocked.join(";")
        var nextHistoryIgnored = historyIgnored.join(";")
        var settingsChanged = nextAllowed !== String(Config.notificationsDndAllowedApps || "")
            || nextBlocked !== String(Config.notificationsDndBlockedApps || "")
            || nextHistoryIgnored !== String(Config.notificationsHistoryIgnoredApps || "")

        Config.notificationsSeenSenders = remainingSenders
        if (nextAllowed !== String(Config.notificationsDndAllowedApps || ""))
            Config.notificationsDndAllowedApps = nextAllowed
        if (nextBlocked !== String(Config.notificationsDndBlockedApps || ""))
            Config.notificationsDndBlockedApps = nextBlocked
        if (nextHistoryIgnored !== String(Config.notificationsHistoryIgnoredApps || ""))
            Config.notificationsHistoryIgnoredApps = nextHistoryIgnored
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
        root.dndShowAllApplications,
        root.normalizedDndRuleIds(Config.notificationsHistoryIgnoredApps))
    readonly property int dndApplicationRowCount: Array.isArray(root.dndApplicationRows)
        ? root.dndApplicationRows.length : 0
    // Catalog-wide counters do not depend on the current query, Show All state,
    // or the 40-row search cap, so the overview always describes the whole list.
    readonly property var dndCatalogSummary: NotificationAppCatalog.summarizeSenders(
        Config.notificationsSeenSenders || [],
        root.normalizedDndRuleIds(Config.notificationsDndAllowedApps),
        root.normalizedDndRuleIds(Config.notificationsDndBlockedApps),
        root.normalizedDndRuleIds(Config.notificationsHistoryIgnoredApps))

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
        changeKeys: ({ keys: ["notificationsDndAllowedApps", "notificationsDndBlockedApps", "notificationsHistoryIgnoredApps", "notificationsHistoryLimit", "notificationsHistoryRetentionDays"] })
        heading: root.dndSubTab === 0 ? "Правила приложений" : "История уведомлений"
        padding: 8
        contentSpacing: 6

        SettingsRow {
            visible: root.dndSubTab === 1
            settingsSearchSubTabIndex: 1
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
                settingsSearchId: "notifications-history-limit"
                settingsSearchLabel: "Размер истории уведомлений"
                settingsSearchKeywords: "история уведомлений память количество записей лимит очистка хранение"
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
        SettingsDescription {
            descriptionConditionVisible: root.dndSubTab === 1
            width: parent.width
            text: "Количество последних уведомлений, сохраняемых в оперативной памяти. Допустимо от 1 до 200; содержимое не записывается на диск."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
        SettingsRow {
            visible: root.dndSubTab === 1
            settingsSearchSubTabIndex: 1
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
                settingsSearchId: "notifications-history-retention"
                settingsSearchLabel: "Срок хранения истории уведомлений"
                settingsSearchKeywords: "история уведомлений срок возраст дней автоматическое удаление очистка памяти"
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
        SettingsDescription {
            descriptionConditionVisible: root.dndSubTab === 1
            width: parent.width
            text: "0 — без ограничения по возрасту. От 1 до 365 дней — автоматически удалять более старые записи. Лимит по количеству действует всегда."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        SettingsDescription {
            descriptionConditionVisible: root.dndSubTab === 0
            width: parent.width
            text: "В списке появляются приложения, от которых Quickshell уже получил уведомления. «Игнор DND» оставляет их уведомления видимыми при включённом режиме. «Отключить» подавляет их уведомления при выключенном режиме. Ранее настроенные правила остаются доступны после перезапуска; кнопка с корзиной удаляет запись и оба правила."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Text {
            visible: root.dndSubTab === 0
            width: parent.width
            text: {
                var stats = root.dndCatalogSummary || ({})
                var firstLine = "Отправителей: " + (stats.senderCount || 0)
                    + " · С правилами: " + (stats.senderWithRulesCount || 0)
                    + " · Без правил: " + (stats.senderWithoutRulesCount || 0)
                var secondLine = "Игнор DND: " + (stats.ignoreDndCount || 0)
                    + " · Отключить: " + (stats.disabledOutsideDndCount || 0)
                    + " · Игнор истории: " + (stats.historyIgnoredCount || 0)
                    + " · Ранее настроено: " + (stats.savedOnlyCount || 0)
                if ((stats.unresolvedCount || 0) > 0)
                    secondLine += " · Неоднозначные: " + stats.unresolvedCount
                return firstLine + "\n" + secondLine
            }
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(8)
            wrapMode: Text.WordWrap
        }

        Row {
            visible: root.dndSubTab === 0
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField {
                id: notificationsDndApplicationSearch
                width: Math.max(100, parent.width - 126)
                height: 30
                text: root.dndApplicationSearch
                placeholderText: "Найти отправителя уведомлений…"
                settingsSearchId: "notifications-dnd-sender-search"
                settingsSearchLabel: "Поиск отправителя для правил DND"
                settingsSearchKeywords: "не беспокоить исключения разрешить подавить приложение отправитель уведомлений поиск dnd"
                settingsSearchSubTabIndex: 0
                color: Config.text
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
                selectByMouse: true
                onTextEdited: root.dndApplicationSearch = text
            }
            SettingsCheckBox {
                id: notificationsDndShowAllCheck
                width: 118
                height: 30
                text: "Показать все"
                settingsSearchId: "notifications-dnd-show-all"
                settingsSearchLabel: "Показать все известные отправители уведомлений"
                settingsSearchKeywords: "не беспокоить список отправители полный каталог все приложения show all"
                settingsSearchSubTabIndex: 0
                labelFontSize: 9
                checked: root.dndShowAllApplications
                ToolTip.visible: pointerHovered
                ToolTip.text: "Показать всех отправителей, от которых Quickshell уже получал уведомления, а не только приложения с настроенными правилами."
                ToolTip.delay: 450
                onToggled: root.dndShowAllApplications = checked
            }
        }

        Row {
            visible: root.dndSubTab === 0
            width: parent.width
            height: 28
            spacing: 6
            Text {
                width: Math.max(70, parent.width - 294)
                text: "Приложение"
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(9)
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 82
                text: "Игнор DND"
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(8)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 82
                text: "Отключить"
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(8)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                width: 82
                text: "Игнор истории"
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(8)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            Item { width: 24; height: 1 }
        }

        Repeater {
            visible: root.dndSubTab === 0
            model: root.dndSubTab === 0 ? root.dndApplicationRows : []
            delegate: Item {
                required property var modelData
                width: parent.width
                height: 34
                Row {
                    anchors.fill: parent
                    spacing: 6
                    Column {
                        width: modelData.kind === "category"
                            ? parent.width : Math.max(70, parent.width - 294)
                        height: parent.height
                        spacing: 1
                        Text {
                            width: parent.width
                            height: 17
                            text: modelData.name
                            color: Config.text
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(10)
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            width: parent.width
                            height: 14
                            text: modelData.comment || modelData.id
                            color: Config.textMuted
                            font.family: Config.settingsFontFamily
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
                        settingsSearchSubTabIndex: 0
                        settingsSearchId: "notifications-dnd-ignore-" + String(modelData.id || modelData.name || "sender")
                        settingsSearchLabel: "Игнор DND — " + String(modelData.name || modelData.id || "приложение")
                        settingsSearchKeywords: String(modelData.comment || "") + " разрешить уведомления при включённом DND исключение"
                        checked: modelData.allowed
                        enabled: modelData.unusableRule !== true
                        ToolTip.visible: pointerHovered
                        ToolTip.text: modelData.unusableRule
                            ? "Нельзя однозначно определить отправителя: уведомление не содержит desktopEntry, а appName совпадает с другим приложением."
                            : (modelData.allowed
                                ? "Игнор DND включён: уведомления приложения показываются при активном DND."
                                : "Игнор DND выключен: при активном DND уведомления приложения подавляются.")
                        ToolTip.delay: 450
                        onToggled: root.setDndApplicationRule("allowed", modelData.ruleIds || [modelData.id], checked, modelData.legacyRuleIds || [])
                    }
                    SettingsCheckBox {
                        visible: modelData.kind !== "category"
                        width: 82
                        height: 30
                        indicatorOnly: true
                        settingsSearchSubTabIndex: 0
                        settingsSearchId: "notifications-dnd-disable-" + String(modelData.id || modelData.name || "sender")
                        settingsSearchLabel: "Отключить — " + String(modelData.name || modelData.id || "приложение")
                        settingsSearchKeywords: String(modelData.comment || "") + " подавлять уведомления при выключенном DND блокировка"
                        checked: modelData.blocked
                        enabled: modelData.unusableRule !== true
                        ToolTip.visible: pointerHovered
                        ToolTip.text: modelData.unusableRule
                            ? "Нельзя однозначно определить отправителя: уведомление не содержит desktopEntry, а appName совпадает с другим приложением."
                            : (modelData.blocked
                                ? "Отключено: всплывающие уведомления приложения подавляются при выключенном DND."
                                : "Включите, чтобы подавлять всплывающие уведомления приложения при выключенном DND.")
                        ToolTip.delay: 450
                        onToggled: root.setDndApplicationRule("blocked", modelData.ruleIds || [modelData.id], checked, modelData.legacyRuleIds || [])
                    }
                    SettingsCheckBox {
                        visible: modelData.kind !== "category"
                        width: 82
                        height: 30
                        indicatorOnly: true
                        settingsSearchSubTabIndex: 0
                        settingsSearchId: "notifications-dnd-history-ignore-" + String(modelData.id || modelData.name || "sender")
                        settingsSearchLabel: "Игнорировать в истории — " + String(modelData.name || modelData.id || "приложение")
                        settingsSearchKeywords: String(modelData.comment || "") + " история уведомлений не сохранять исключить из истории скрыть запись"
                        checked: modelData.historyIgnored === true
                        enabled: modelData.unusableRule !== true
                        ToolTip.visible: pointerHovered
                        ToolTip.text: modelData.unusableRule
                            ? "Нельзя однозначно определить отправителя: уведомление не содержит desktopEntry, а appName совпадает с другим приложением."
                            : (modelData.historyIgnored
                                ? "Игнорирование истории включено: новые уведомления приложения не добавляются в историю. Уже сохранённые записи остаются."
                                : "Игнорирование истории выключено: уведомления приложения добавляются в историю.")
                        ToolTip.delay: 450
                        onToggled: root.setDndApplicationRule("history", modelData.ruleIds || [modelData.id], checked, modelData.legacyRuleIds || [])
                    }
                    SettingsResetButton {
                        visible: modelData.kind !== "category"
                        width: 24
                        height: 26
                        label: ""
                        iconText: "\uf1f8"
                        fontSize: 9
                        tooltip: "Удалить приложение из списка и снять все его правила"
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

        SettingsDescription {
            descriptionConditionVisible: root.dndSubTab === 0 && root.dndApplicationRowCount === 0
            width: parent.width
            text: root.dndApplicationSearch.trim().startsWith("@")
                ? "@i ID\n@c category\n@d description\n@e command\n@w WM_CLASS\n@g generic name\n@k keywords\n@t apps inside terminal"
                : (root.dndApplicationSearch.trim().length > 0
                    ? "Ничего не найдено."
                    : (root.dndShowAllApplications
                        ? "Пока нет отправителей уведомлений. Приложения появятся здесь после того, как Quickshell получит от них первое уведомление."
                        : "Нет приложений с настроенными правилами. Включите «Показать все», чтобы увидеть остальных отправителей уведомлений."))
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
        SettingsDescription {
            descriptionConditionVisible: root.dndSubTab === 0 && root.dndApplicationSearch.trim().length > 0 && root.dndApplicationRowCount === 40
            width: parent.width
            text: "Показаны первые 40 совпадений. Уточните запрос, чтобы найти нужное приложение."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(8)
            wrapMode: Text.WordWrap
        }

    }


    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsDoNotDisturb"] })
        heading: "Режим Не беспокоить"
        settingsSearchSubTabIndex: 0
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            id: notificationsDoNotDisturbCheck
            width: parent.width
            height: 28
            text: "Не беспокоить"
            checked: Config.notificationsDoNotDisturb
            settingsSearchId: "notifications-do-not-disturb"
            settingsSearchLabel: "Не беспокоить: скрывать всплывающие уведомления"
            settingsSearchKeywords: "уведомления режим тишина dnd do not disturb подавлять скрывать без звука"
            settingsSearchSubTabIndex: 0
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
        SettingsDescription {
            width: parent.width
            text: "Входящие уведомления продолжают приниматься, но всплывающие карточки не показываются. Последние уведомления доступны в истории Dashboard; история ограничена 200 записями и хранится только в оперативной памяти, без записи содержимого на диск."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
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

        SettingsDescription {
            width: parent.width
            text: "Модуль управляет приёмом и показом карточек. В Quickshell 0.3.1 служба org.freedesktop.Notifications имеет процессный жизненный цикл: выключение модуля скрывает карточки и отклоняет новые уведомления, но не освобождает D-Bus-имя. Чтобы передать его другому серверу уведомлений, нужно завершить Quickshell."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        SettingsDescription {
            width: parent.width
            text: "Время указывается в секундах. Значение 0 отключает автоматическое закрытие. Явный тайм-аут, переданный приложением, имеет приоритет."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
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
                settingsSearchId: "notifications-default-timeout"
                settingsSearchLabel: "Время показа обычных уведомлений"
                settingsSearchKeywords: "уведомления автоматическое закрытие длительность секунды таймер timeout"
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
                settingsSearchId: "notifications-critical-timeout"
                settingsSearchLabel: "Время показа критических уведомлений"
                settingsSearchKeywords: "уведомления критические срочные автоматическое закрытие длительность секунды таймер timeout urgency"
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

        SettingsDescription {
            width: parent.width
            text: "По умолчанию критические уведомления не закрываются автоматически."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        SettingsCheckBox {
            id: notificationsShowTimeoutIndicatorCheck
            width: parent.width
            height: 28
            text: "Показывать время до закрытия"
            settingsSearchId: "notifications-timeout-indicator-visible"
            settingsSearchLabel: "Показывать индикатор оставшегося времени уведомления"
            settingsSearchKeywords: "уведомления таймер обратный отсчёт полоса рамка progress countdown"
            checked: Config.notificationsShowTimeoutIndicator
            onToggled: { Config.notificationsShowTimeoutIndicator = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowTimeoutIndicatorChanged() { notificationsShowTimeoutIndicatorCheck.checked = Config.notificationsShowTimeoutIndicator } }
        }
        SettingsDescription {
            width: parent.width
            text: "Индикатор показывает оставшееся время до автоматического закрытия. При наведении на карточку отсчёт приостанавливается."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
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
        SettingsDescription {
            width: parent.width
            text: "Пустое значение использует основной цвет темы. Цвет применяется и к полосе, и к рамке. Для рамки можно выбрать направление обхода."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
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
                settingsSearchId: "notifications-card-spacing"
                settingsSearchLabel: "Расстояние между карточками уведомлений"
                settingsSearchKeywords: "уведомления интервалы отступ промежуток расстояние карточки stack"
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
                settingsSearchId: "notifications-image-height"
                settingsSearchLabel: "Максимальная высота изображения в уведомлении"
                settingsSearchKeywords: "уведомления изображение картинка фото превью высота body image"
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
        changeKeys: ({ keys: ["notificationsShowAppIcon", "notificationsShowAppIconBackground", "notificationsShowBodyImages", "notificationsShowProgress"] })
        heading: "Элементы карточки"
        padding: 8
        contentSpacing: 4

        SettingsCheckBox {
            id: notificationsShowAppIconCheck
            width: parent.width
            height: 28
            text: "Показывать иконку приложения"
            settingsSearchId: "notifications-show-app-icon"
            settingsSearchLabel: "Показывать иконку приложения в уведомлении"
            settingsSearchKeywords: "уведомления иконка значок приложение app icon leading visual"
            checked: Config.notificationsShowAppIcon
            onToggled: { Config.notificationsShowAppIcon = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowAppIconChanged() { notificationsShowAppIconCheck.checked = Config.notificationsShowAppIcon } }
        }
        SettingsCheckBox {
            id: notificationsShowAppIconBackgroundCheck
            width: parent.width
            height: 28
            text: "Показывать фон под иконкой приложения"
            settingsSearchId: "notifications-show-app-icon-background"
            settingsSearchLabel: "Показывать фон под иконкой приложения в уведомлении"
            settingsSearchKeywords: "уведомления иконка значок фон подложка убрать отключить прозрачный прозрачность app icon background"
            checked: Config.notificationsShowAppIconBackground
            enabled: Config.notificationsShowAppIcon
            onToggled: { Config.notificationsShowAppIconBackground = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowAppIconBackgroundChanged() { notificationsShowAppIconBackgroundCheck.checked = Config.notificationsShowAppIconBackground } }
        }
        SettingsCheckBox {
            id: notificationsShowBodyImagesCheck
            width: parent.width
            height: 28
            text: "Показывать изображения в сообщениях"
            settingsSearchId: "notifications-show-body-images"
            settingsSearchLabel: "Показывать изображения в тексте уведомления"
            settingsSearchKeywords: "уведомления изображения фотографии картинки вложения body image preview"
            checked: Config.notificationsShowBodyImages
            onToggled: { Config.notificationsShowBodyImages = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowBodyImagesChanged() { notificationsShowBodyImagesCheck.checked = Config.notificationsShowBodyImages } }
        }
        SettingsCheckBox {
            id: notificationsShowProgressCheck
            width: parent.width
            height: 28
            text: "Показывать индикатор прогресса"
            settingsSearchId: "notifications-show-progress"
            settingsSearchLabel: "Показывать индикатор прогресса уведомления"
            settingsSearchKeywords: "уведомления progress bar прогресс загрузка процент progress hint"
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
        settingsSearchSubTabIndex: 1
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт заголовка"
            settingsSearchId: "notifications-summary-font"
            settingsSearchLabel: "Шрифт заголовка уведомления"
            settingsSearchKeywords: "уведомления заголовок summary title typography семейство гарнитура font"
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
                settingsSearchId: "notifications-summary-font-size"
                settingsSearchLabel: "Размер заголовка уведомления"
                settingsSearchKeywords: "уведомления заголовок summary title размер кегль px"
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
            settingsSearchId: "notifications-summary-color"
            settingsSearchLabel: "Цвет заголовка уведомления"
            settingsSearchKeywords: "уведомления заголовок summary title цвет текста typography"
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
                settingsSearchId: "notifications-leading-visual-size"
                settingsSearchLabel: "Размер иконки или аватара уведомления"
                settingsSearchKeywords: "уведомления иконка аватар изображение размер ведущий элемент leading visual"
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

        SettingsDescription {
            width: parent.width
            text: "Пустой шрифт использует системный. Размер иконки применяется одинаково к иконкам приложений, аватарам и ведущим изображениям."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
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
        settingsSearchSubTabIndex: 1
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт названия"
            settingsSearchId: "notifications-app-name-font"
            settingsSearchLabel: "Шрифт названия приложения в уведомлении"
            settingsSearchKeywords: "уведомления приложение имя app name source label font шрифт"
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
                settingsSearchId: "notifications-app-name-font-size"
                settingsSearchLabel: "Размер названия приложения в уведомлении"
                settingsSearchKeywords: "уведомления приложение имя app name source размер кегль"
                minimum: 8; maximum: 24; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsAppNameFontSize"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsColorField {
            width: parent.width
            label: "Цвет названия"
            settingsSearchId: "notifications-app-name-color"
            settingsSearchLabel: "Цвет названия приложения в уведомлении"
            settingsSearchKeywords: "уведомления приложение имя app name источник цвет текста"
            value: String(Config.notificationsAppNameColor || Config.text)
            targetObject: Config; targetProperty: "notificationsAppNameColor"
            settingsObject: root.settings; saveOnEdit: true
            allowAlpha: true; allowTransparent: false
            labelWidth: 220; fieldWidth: 120
        }
        SettingsCheckBox {
            width: parent.width; height: 28
            text: "Полужирное начертание"
            settingsSearchId: "notifications-app-name-bold"
            settingsSearchLabel: "Полужирное название приложения в уведомлении"
            settingsSearchKeywords: "уведомления приложение имя app name жирный bold начертание вес шрифта"
            checked: Config.notificationsAppNameBold
            onToggled: { Config.notificationsAppNameBold = checked; root.settings.save() }
        }
        SettingsDescription {
            width: parent.width
            text: "Пустой шрифт и цвет используют системное семейство и активный цвет текста."
            color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(9)
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
        settingsSearchSubTabIndex: 1
        padding: 8
        contentSpacing: 6
        SettingsRow {
            width: parent.width; height: 30
            label: "Радиус скругления"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsLeadingVisualRadius
                settingsSearchId: "notifications-leading-visual-radius"
                settingsSearchLabel: "Скругление углов иконки или аватара"
                settingsSearchKeywords: "уведомления иконка аватар радиус скругление corners border radius rounded"
                minimum: 0; maximum: 36; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsLeadingVisualRadius"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsDescription { width: parent.width; text: "0 — квадратные углы; максимальный радиус автоматически ограничивается половиной размера изображения."; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(9); wrapMode: Text.WordWrap }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsCardPadding"] })
        heading: "Внутренние отступы карточки"
        settingsSearchSubTabIndex: 1
        padding: 8
        contentSpacing: 6
        SettingsRow {
            width: parent.width; height: 30
            label: "Отступ от краёв"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsCardPadding
                settingsSearchId: "notifications-card-padding"
                settingsSearchLabel: "Внутренние отступы карточки уведомления"
                settingsSearchKeywords: "уведомления карточка padding внутренний отступ поля расстояние до краёв"
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
        settingsSearchSubTabIndex: 1
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
                settingsSearchId: "notifications-body-font-size"
                settingsSearchLabel: "Размер основного текста уведомления"
                settingsSearchKeywords: "уведомления текст сообщения body размер кегль шрифт"
                minimum: 8; maximum: 32; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsBodyFontSize"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsColorField {
            label: "Цвет текста"
            settingsSearchId: "notifications-body-color"
            settingsSearchLabel: "Цвет основного текста уведомления"
            settingsSearchKeywords: "уведомления текст сообщения body цвет шрифт typography"
            value: String(Config.notificationsBodyColor || Config.text)
            targetObject: Config; targetProperty: "notificationsBodyColor"
            settingsObject: root.settings; saveOnEdit: true
            allowAlpha: true; allowTransparent: false
            labelWidth: 220; fieldWidth: 120
        }
        SettingsDescription { width: parent.width; text: "Пустой цвет использует основной цвет активной темы."; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(9); wrapMode: Text.WordWrap }
    }

    SettingsGroup {
        visible: root.pageId === "notifications" && root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsBackgroundColor"] })
        heading: "Фон уведомлений"
        settingsSearchSubTabIndex: 1
        padding: 8
        contentSpacing: 6

        SettingsColorField {
            width: parent.width
            label: "Цвет и прозрачность"
            settingsSearchId: "notifications-background-color"
            settingsSearchLabel: "Цвет и прозрачность фона уведомлений"
            settingsSearchKeywords: "уведомления карточка фон background прозрачность alpha цвет заливка"
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

        SettingsDescription {
            width: parent.width
            text: "Уведомления можно привязать к верхнему или нижнему краю выбранного монитора. Горизонтальная координата X всегда отсчитывается слева."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
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
                settingsSearchId: "notifications-vertical-anchor"
                settingsSearchLabel: "Вертикальная привязка уведомлений к краю экрана"
                settingsSearchKeywords: "уведомления расположение экран монитор сверху снизу top bottom position anchor"
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
        settingsSearchSubTabIndex: 3
        profileSearchId: "notifications-animation-profile"
        profileSearchLabel: "Профиль анимации уведомлений"
        profileSearchKeywords: "анимация уведомления кривая плавность выразительность spatial effects expressive standard none"
        durationSearchId: "notifications-animation-duration"
        durationSearchLabel: "Длительность анимации уведомлений"
        durationSearchKeywords: "анимация уведомления переход миллисекунды скорость длительность duration motion"
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
            changeKeys: ({ keys: ["animationNotificationsVisibilityStyle", "animationNotificationsVisibilityProfile"] })
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
                    settingsSearchId: "notifications-animation-visibility-style"
                    settingsSearchLabel: "Направление и стиль появления уведомлений"
                    settingsSearchKeywords: "уведомления анимация появление исчезновение направление нет fade slide слева справа сверху снизу"
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
                        color: "transparent"
                        border.color: (notificationVisibilityStyleBox.activeFocus || notificationVisibilityStyleBox.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: (Config.inputBordersEnabled || notificationVisibilityStyleBox.activeFocus) ? 1 : 0
                        radius: Config.scaledCornerRadius(Config.settingsUiSize(4))
                    }
                    contentItem: Text {
                        text: notificationVisibilityStyleBox.currentText
                        color: Config.text
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                }
            }

            SettingsAnimationCurveControl {
                profile: Config.animationNotificationsVisibilityProfile
                searchId: "notifications-visibility-animation-curve"
                searchLabel: "CSS-кривая появления уведомлений"
                searchKeywords: "уведомления карточки появление исчезновение очередь bezier"
                onProfileEdited: function(value) {
                    Config.animationNotificationsVisibilityProfile = value
                    root.settings.save()
                }
            }

            SettingsDescription {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Кривая сглаживания управляет ускорением и замедлением появления и исчезновения карточек. Перемещение остальных карточек в очереди настраивается отдельно."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }

}
