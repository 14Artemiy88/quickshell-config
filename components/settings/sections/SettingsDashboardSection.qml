import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"
import "../../../js/dashboard/DashboardCards.js" as DashboardCards

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "dashboard"
    width: parent ? parent.width : 0
    spacing: 10

    function cardEnabled(id) {
        return DashboardCards.contains(Config.dashboardVisibleCards, id)
    }

    function cardOrderIndex(id) {
        return DashboardCards.indexOf(Config.dashboardCardOrder, id)
    }

    function setCardEnabled(id, enabled) {
        Config.dashboardVisibleCards = DashboardCards.setEnabled(Config.dashboardVisibleCards, id, enabled)
        root.settings.save()
    }

    function setColumnsMode(mode) {
        var normalized = DashboardCards.normalizeColumnsMode(mode)
        if (Config.dashboardColumnsMode === normalized) return
        Config.dashboardColumnsMode = normalized
        root.settings.save()
    }

    function moveCard(id, direction) {
        var nextOrder = DashboardCards.move(Config.dashboardCardOrder, id, direction)
        var currentOrder = DashboardCards.normalizeOrder(Config.dashboardCardOrder)
        if (JSON.stringify(nextOrder) === JSON.stringify(currentOrder)) return
        Config.dashboardCardOrder = nextOrder
        root.settings.save()
    }

    function setCardSize(id, mode) {
        var nextSizes = DashboardCards.setCardSize(Config.dashboardCardSizes, id, mode)
        if (JSON.stringify(nextSizes) === JSON.stringify(DashboardCards.normalizeCardSizes(Config.dashboardCardSizes))) return
        Config.dashboardCardSizes = nextSizes
        root.settings.save()
    }

    SettingsGroup {
        width: parent.width
        showFrame: true
        heading: "Карточки Dashboard"
        changeKeys: ({ keys: ["dashboardVisibleCards", "dashboardCardOrder", "dashboardColumnsMode", "dashboardCardSizes"] })
        padding: 8
        contentSpacing: 7

        SettingsRow {
            width: parent.width
            height: 32
            spacing: 8
            label: "Количество колонок"
            labelWidth: 190

            SettingsComboBox {
                id: dashboardColumnsModeCombo
                width: 170
                height: 30
                model: ["Автоматически", "1 колонка", "2 колонки"]
                currentIndex: DashboardCards.COLUMN_MODES.indexOf(DashboardCards.normalizeColumnsMode(Config.dashboardColumnsMode))
                settingsSearchable: true
                settingsSearchId: "dashboard-columns-mode"
                settingsSearchLabel: "Количество колонок Dashboard"
                settingsSearchKeywords: "расположение карточек сетка одна две автоматически layout columns grid one two auto"
                onItemChosen: index => root.setColumnsMode(DashboardCards.COLUMN_MODES[index])

                Connections {
                    target: Config
                    function onDashboardColumnsModeChanged() {
                        dashboardColumnsModeCombo.currentIndex = DashboardCards.COLUMN_MODES.indexOf(DashboardCards.normalizeColumnsMode(Config.dashboardColumnsMode))
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Выбирай карточки независимо от включения соответствующих модулей. Настрой количество колонок, порядок и размер каждой карточки отдельно. Расширенный размер показывает дополнительные данные модуля, а компактный сохраняет короткую сводку. В двухколоночном режиме карточки размещаются в независимых вертикальных колонках, сбалансированных по общей высоте: расширенная карточка не оставляет пустую полосу под соседней. В режиме «Автоматически» две колонки включаются при ширине области карточек от 500 px. Режим «2 колонки» допускает ширину от 470 px (не менее 230 px на карточку с учётом промежутка); ниже этого порога используется одна колонка, чтобы содержимое не сжималось."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: DashboardCards.orderedVisible(Config.dashboardCardOrder, null)

            delegate: Column {
                id: cardSettings
                required property var modelData
                property string cardId: modelData.id
                width: parent.width
                spacing: 2

                Row {
                    id: cardRow
                    width: parent.width
                    height: 30
                    spacing: 4

                    SettingsCheckBox {
                        width: Math.max(80, parent.width - 52)
                        height: 30
                        text: cardSettings.modelData.settingsLabel
                        checked: root.cardEnabled(cardSettings.cardId)
                        settingsSearchable: true
                        settingsSearchId: "dashboard-card-" + cardSettings.cardId
                        settingsSearchLabel: "Карточка " + cardSettings.modelData.settingsLabel
                        settingsSearchKeywords: cardSettings.modelData.keywords
                        onToggled: root.setCardEnabled(cardSettings.cardId, checked)
                    }

                    MoveArrowButton {
                        width: 22
                        height: 22
                        iconText: "↑"
                        iconSize: Config.settingsUiSize(12)
                        baseColor: Config.text
                        hoverMode: "frame"
                        hoverColor: Config.accent
                        interactionEnabled: root.cardOrderIndex(cardSettings.cardId) > 0
                        toolTipText: "Поднять карточку выше"
                        onClicked: root.moveCard(cardSettings.cardId, -1)
                    }

                    MoveArrowButton {
                        width: 22
                        height: 22
                        iconText: "↓"
                        iconSize: Config.settingsUiSize(12)
                        baseColor: Config.text
                        hoverMode: "frame"
                        hoverColor: Config.accent
                        interactionEnabled: root.cardOrderIndex(cardSettings.cardId) < DashboardCards.DEFAULT_IDS.length - 1
                        toolTipText: "Опустить карточку ниже"
                        onClicked: root.moveCard(cardSettings.cardId, 1)
                    }
                }

                SettingsRow {
                    width: parent.width
                    height: 28
                    spacing: 8
                    label: "Размер карточки · " + cardSettings.modelData.label
                    labelWidth: 190

                    SettingsComboBox {
                        id: cardSizeCombo
                        width: 142
                        height: 28
                        model: ["Компактный", "Расширенный"]
                        currentIndex: DashboardCards.cardSizeModeIndex(Config.dashboardCardSizes, cardSettings.cardId)
                        settingsSearchable: true
                        settingsSearchId: "dashboard-card-size-" + cardSettings.cardId
                        settingsSearchLabel: "Размер карточки " + cardSettings.modelData.settingsLabel
                        settingsSearchKeywords: "размер карточки compact expanded compactный расширенный height tall small large " + cardSettings.modelData.keywords
                        onItemChosen: index => root.setCardSize(cardSettings.cardId, DashboardCards.CARD_SIZE_MODES[index])

                        Connections {
                            target: Config
                            function onDashboardCardSizesChanged() {
                                cardSizeCombo.currentIndex = DashboardCards.cardSizeModeIndex(Config.dashboardCardSizes, cardSettings.cardId)
                            }
                        }
                    }
                }
            }
        }
    }
}
