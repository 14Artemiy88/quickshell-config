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

    function moveCardToIndex(id, destination) {
        var nextOrder = DashboardCards.normalizeOrder(Config.dashboardCardOrder)
        var index = nextOrder.indexOf(String(id))
        var target = Number(destination)
        if (index < 0 || !isFinite(target) || Math.floor(target) !== target
                || target < 0 || target >= nextOrder.length || target === index)
            return
        var item = nextOrder.splice(index, 1)[0]
        nextOrder.splice(target, 0, item)
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
        id: dashboardAnimationSettingsGroup
        width: parent.width
        showFrame: true
        settings: root.settings
        heading: "Появление Dashboard"
        changeKeys: ({ keys: ["animationDashboardVisibilityStyle", "animationDashboardVisibilityProfile", "animationDashboardVisibilityDuration"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Направление"
            labelWidth: 190

            SettingsComboBox {
                id: dashboardAnimationStyleCombo
                width: 190
                height: 30
                property var values: ["auto", "none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Автоматически от края", "Без анимации", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationDashboardVisibilityStyle))
                settingsSearchable: true
                settingsSearchId: "dashboard-visibility-animation-direction"
                settingsSearchLabel: "Направление появления и исчезновения Dashboard"
                settingsSearchKeywords: "анимация появления закрытия выезд выезжать сторона слева справа сверху снизу автоматически ближайший край dashboard animation direction slide fade none"
                onItemChosen: function(index) {
                    if (index < 0 || index >= values.length) return
                    Config.animationDashboardVisibilityStyle = values[index]
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onAnimationDashboardVisibilityStyleChanged() {
                        dashboardAnimationStyleCombo.currentIndex = Math.max(0, dashboardAnimationStyleCombo.values.indexOf(Config.animationDashboardVisibilityStyle))
                    }
                }
            }
        }

        SettingsDescription {
            width: parent.width
            wrapMode: Text.WordWrap
            text: Config.animationDashboardVisibilityStyle === "auto"
                ? "Автоматический режим выбирает ближайший горизонтальный край монитора: Dashboard справа появляется справа, а Dashboard слева — слева. При закрытии он уходит в ту же сторону."
                : "Выбранное направление используется и при появлении, и при исчезновении Dashboard."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
        }

        SettingsAnimationCurveControl {
            profile: Config.animationDashboardVisibilityProfile
            searchId: "dashboard-visibility-animation-curve"
            searchLabel: "CSS-кривая появления Dashboard"
            searchKeywords: "dashboard панель drawer появление закрытие пружина bezier"
            onProfileEdited: function(value) {
                Config.animationDashboardVisibilityProfile = value
                root.settings.save()
            }
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Длительность (мс)"
            labelWidth: 190

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.animationDashboardVisibilityDuration
                minimum: 0
                maximum: 5000
                step: 50
                wheelStep: 50
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "animationDashboardVisibilityDuration"
                settingsObject: root.settings
                saveOnEdit: true
                settingsSearchable: true
                settingsSearchId: "dashboard-visibility-animation-duration"
                settingsSearchLabel: "Длительность анимации Dashboard"
                settingsSearchKeywords: "время скорость продолжительность миллисекунды ms duration animation dashboard"
            }
        }
    }

    SettingsGroup {
        id: dashboardCardsSettingsGroup
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

        SettingsDescription {
            width: parent.width
            text: "Выбирай карточки независимо от включения соответствующих модулей. Настрой количество колонок, порядок и размер каждой карточки отдельно. Расширенный размер показывает дополнительные данные модуля, а компактный сохраняет короткую сводку. В двухколоночном режиме карточки размещаются в независимых вертикальных колонках, сбалансированных по общей высоте: расширенная карточка не оставляет пустую полосу под соседней. В режиме «Автоматически» две колонки включаются при ширине области карточек от 500 px. Режим «2 колонки» допускает ширину от 470 px (не менее 230 px на карточку с учётом промежутка); ниже этого порога используется одна колонка, чтобы содержимое не сжималось."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Repeater {
            id: dashboardSettingsCardsRepeater
            model: DashboardCards.orderedVisible(Config.dashboardCardOrder, null)

            delegate: Column {
                id: cardSettings
                Behavior on y { NumberAnimation { duration: Config.animationDuration(190, "appearance"); easing.type: Easing.OutCubic } }
                property Item reorderTargetItem: cardSettings
                required property var modelData
                required property int index
                property string cardId: modelData.id
                width: parent.width
                height: implicitHeight
                spacing: 2

                Row {
                    id: cardRow
                    width: parent.width
                    height: 30
                    spacing: 4

                    SettingsCheckBox {
                        width: Math.max(80, parent.width - 30)
                        height: 30
                        text: cardSettings.modelData.settingsLabel
                        checked: root.cardEnabled(cardSettings.cardId)
                        settingsSearchable: true
                        settingsSearchId: "dashboard-card-" + cardSettings.cardId
                        settingsSearchLabel: "Карточка " + cardSettings.modelData.settingsLabel
                        settingsSearchKeywords: cardSettings.modelData.keywords
                        onToggled: root.setCardEnabled(cardSettings.cardId, checked)
                    }

                    DragReorderHandle {
                        width: 26
                        height: 26
                        listRepeater: dashboardSettingsCardsRepeater
                        dropIndicatorHost: dashboardCardsSettingsGroup
                        itemIndex: cardSettings.index
                        accessibleLabel: cardSettings.modelData.settingsLabel
                        onReorderRequested: function(fromIndex, toIndex) {
                            root.moveCardToIndex(cardSettings.cardId, toIndex)
                        }
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
