import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: settingsWindowColumn

    property string pendingDeleteProfileName: ""

    function syncProfileComboToActiveProfile() {
        var idx = host && host.profileController
            ? host.profileController.indexOfProfile(String(settings.activeProfile || "")) : -1
        profileCombo.currentIndex = idx >= 0 ? idx : -1
    }

    Connections {
        target: settings
        function onProfilesRevisionChanged() {
            Qt.callLater(function() {
                settingsWindowColumn.syncProfileComboToActiveProfile()
                if (settingsWindowColumn.pendingDeleteProfileName.length > 0
                        && host && host.profileController
                        && host.profileController.indexOfProfile(settingsWindowColumn.pendingDeleteProfileName) < 0)
                    settingsWindowColumn.pendingDeleteProfileName = ""
            })
        }
        function onActiveProfileChanged() { Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile) }
    }

    Connections {
        target: settingsWindowColumn.host
        function onCurrentPageIdChanged() { settingsWindowColumn.pendingDeleteProfileName = "" }
        function onCurrentPageSubTabIndexChanged() { settingsWindowColumn.pendingDeleteProfileName = "" }
    }

    Component.onCompleted: Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile)
    property var host
    property var settings: Settings
    property string pageGroupDropTargetId: ""
    property int pageGroupDropTargetIndex: -1

    function clearPageGroupDropTarget() {
        pageGroupDropTargetId = ""
        pageGroupDropTargetIndex = -1
    }

    function updatePageGroupDropTarget(pageId, sourceGroupId, sceneX, sceneY) {
        var groups = settingsNavigationPageGroupsRepeater
        if (!groups) {
            clearPageGroupDropTarget()
            return false
        }
        for (var i = 0; i < groups.count; ++i) {
            var groupItem = groups.itemAt(i)
            if (!groupItem || !groupItem.groupData || groupItem.groupData.id === sourceGroupId)
                continue
            var point = groupItem.mapFromItem(null, sceneX, sceneY)
            if (point.x < 0 || point.y < 0 || point.x > groupItem.width || point.y > groupItem.height)
                continue

            var pages = groupItem.pageOrderRepeater
            var destination = pages ? pages.count : 0
            if (pages) {
                for (var rowIndex = 0; rowIndex < pages.count; ++rowIndex) {
                    var row = pages.itemAt(rowIndex)
                    if (!row) continue
                    var rowPoint = row.mapFromItem(null, sceneX, sceneY)
                    if (rowPoint.y < row.height / 2) {
                        destination = rowIndex
                        break
                    }
                    if (rowPoint.y <= row.height) {
                        destination = rowIndex + 1
                        break
                    }
                }
            }
            pageGroupDropTargetId = String(groupItem.groupData.id)
            pageGroupDropTargetIndex = destination
            return true
        }
        clearPageGroupDropTarget()
        return false
    }

    function finishPageGroupDrag(pageId, sourceGroupId) {
        var targetGroupId = pageGroupDropTargetId
        var targetIndex = pageGroupDropTargetIndex
        clearPageGroupDropTarget()
        if (!targetGroupId || targetGroupId === sourceGroupId || !host)
            return false
        return host.moveSettingsTabToGroup(pageId, targetGroupId, targetIndex)
    }

    width: parent ? parent.width : 0
    spacing: 10
    SettingsGroup {
                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["settingsFont", "settingsFontSize", "settingsFontScale", "settingsUiScale", "settingsShowDescriptions", "settingsPadding", "settingsSpacing"] })
        padding: 8
        contentSpacing: 6

        Text {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                text: "Интерфейс настроек"
                                color: Config.textMuted
                                font.family: Config.settingsFontFamily
                                font.pixelSize: Config.settingsUiSize(10)
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Шрифт настроек"
                                spacing: 8
                                
                                SettingsFontField {
                                    width: parent.width
                                    height: 30
                                    compact: true
                                    fieldWidth: 160
                                    fieldFontSize: 11
                                    value: Config.settingsFont
                                    targetObject: Config
                                    targetProperty: "settingsFont"
                                    settingsObject: settings
                                    saveOnEdit: true
                                }
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Базовый размер шрифта настроек"
                                spacing: 8
                                
                                SettingsNumberField {
            id: settingsFontSizeField
            width: 100
            height: 30
            value: Config.settingsFontSize
            minimum: 6
            maximum: 32
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "settingsFontSize"
            settingsObject: settingsWindowColumn.settings
            saveOnEdit: true
        }
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Масштаб окна настроек (%)"
                                spacing: 8
                                SettingsNumberField {
                                    width: 100; height: 30
                                    value: Config.settingsUiScale
                                    minimum: 75; maximum: 150; step: 5; wheelStep: 5; decimals: 0
                                    compact: true; fieldWidth: 100; fieldFontSize: 11
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    targetObject: Config; targetProperty: "settingsUiScale"
                                    settingsObject: settingsWindowColumn.settings; saveOnEdit: true
                                }
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Масштаб шрифтов настроек (%)"
                                spacing: 8
                                SettingsNumberField {
                                    width: 100; height: 30
                                    value: Config.settingsFontScale
                                    minimum: 75; maximum: 150; step: 5; wheelStep: 5; decimals: 0
                                    compact: true; fieldWidth: 100; fieldFontSize: 11
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    targetObject: Config; targetProperty: "settingsFontScale"
                                    settingsObject: settingsWindowColumn.settings; saveOnEdit: true
                                }
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Пояснения к настройкам"
                                spacing: 8

                                SettingsCheckBox {
                                    width: parent.width
                                    height: 30
                                    text: "Показывать поясняющие описания"
                                    checked: Config.settingsShowDescriptions
                                    onToggled: {
                                        Config.settingsShowDescriptions = checked
                                        settingsWindowColumn.settings.save()
                                    }
                                    settingsSearchLabel: "Показывать пояснения к настройкам"
                                    settingsSearchKeywords: "описания пояснения помощь подсказки дополнительные тексты справка скрыть показать интерфейс настроек"
                                }
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Внутренний отступ"
                                spacing: 8
                                
                                SettingsNumberField {
            id: settingsPaddingField
            width: 100
            height: 30
            value: Config.settingsPadding
            minimum: 0
            maximum: 40
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "settingsPadding"
            settingsObject: settingsWindowColumn.settings
            saveOnEdit: true
        }
                            }

                            SettingsRow {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 34
                                labelWidth: 210
                                labelFontSize: 11
                                label: "Расстояние между элементами"
                                spacing: 8
                                
                                SettingsNumberField {
            id: settingsSpacingField
            width: 100
            height: 30
            value: Config.settingsSpacing
            minimum: 0
            maximum: 40
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "settingsSpacing"
            settingsObject: settingsWindowColumn.settings
            saveOnEdit: true
        }
                            }

    }
    SettingsGroup {
        visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
        settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        heading: "Поиск"
        changeKeys: ({ keys: ["settingsSearchVisible", "settingsSearchHighlightColor", "settingsSearchHighlightBorderWidth", "settingsSearchMatchCountFontSize"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
            width: parent.width
            height: 34
            spacing: 8
            SettingsCheckBox {
                width: parent.width
                height: 30
                text: "Показывать поиск в боковой панели"
                checked: Config.settingsSearchVisible
                onToggled: {
                    Config.settingsSearchVisible = checked
                    if (!checked && host && host.clearSettingsSearchQuery)
                        host.clearSettingsSearchQuery()
                    settings.save()
                }
                settingsSearchLabel: "Показывать строку поиска настроек"
                settingsSearchKeywords: "поиск строка поле навигация боковая панель показать скрыть отображение"
            }
        }

        Column {
            id: searchAppearanceOptions
            width: parent.width
            height: Config.settingsSearchVisible ? implicitHeight : 0
            spacing: 6
            clip: true
            opacity: Config.settingsSearchVisible ? 1 : 0
            enabled: Config.settingsSearchVisible

            Behavior on height {
                NumberAnimation {
                    duration: Config.animationDuration(180, "size")
                    easing.type: Config.easingType()
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animationDuration(140, "appearance")
                    easing.type: Config.easingType()
                }
            }

            SettingsRow {
                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                width: parent.width
                height: 34
                labelWidth: 210
                labelFontSize: 11
                label: "Цвет рамки совпадений поиска"
                spacing: 8
                
                SettingsColorField {
                    width: parent.width
                    height: 30
                    compact: true
                    fieldWidth: 120
                    fieldFontSize: 11
                    value: String(Config.settingsSearchHighlightColor)
                    targetObject: Config
                    targetProperty: "settingsSearchHighlightColor"
                    settingsObject: settingsWindowColumn.settings
                    saveOnEdit: true
                    settingsSearchLabel: "Цвет рамки совпадений поиска"
                    settingsSearchKeywords: "поиск подсветка совпадения контур рамка найденные результаты"
                }
            }

            SettingsRow {
                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                width: parent.width
                height: 34
                labelWidth: 210
                labelFontSize: 11
                label: "Толщина рамки совпадений"
                spacing: 8
                
                SettingsNumberField {
                    width: 100
                    height: 30
                    value: Config.settingsSearchHighlightBorderWidth
                    minimum: 1
                    maximum: 5
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 100
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    targetObject: Config
                    targetProperty: "settingsSearchHighlightBorderWidth"
                    settingsObject: settingsWindowColumn.settings
                    saveOnEdit: true
                    settingsSearchLabel: "Толщина рамки совпадений поиска"
                    settingsSearchKeywords: "поиск подсветка рамка контур толщина обводка ширина"
                }
            }
            SettingsRow {
                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                width: parent.width
                height: 34
                labelWidth: 210
                labelFontSize: 11
                label: "Размер шрифта счётчиков"
                spacing: 8
                
                SettingsNumberField {
                    width: 100
                    height: 30
                    value: Config.settingsSearchMatchCountFontSize
                    minimum: 6
                    maximum: 12
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 100
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    targetObject: Config
                    targetProperty: "settingsSearchMatchCountFontSize"
                    settingsObject: settingsWindowColumn.settings
                    saveOnEdit: true
                    settingsSearchLabel: "Размер шрифта счётчиков поиска"
                    settingsSearchKeywords: "поиск счетчик счётчик совпадения размер шрифт число количество навигация"
                }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Положение и размер окна"
        changeKeys: ({ keys: ["settingsGeometry", "settingsMonitorName"] })
        padding: 8
        contentSpacing: 6

                            Row {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
                                width: parent.width
                                height: 18
                                spacing: 6

                                Item { width: 0; height: 18 }

                                Repeater {
                                    model: ["X", "Y", "Width", "Height"]
                                    delegate: Text {
                                        width: 76
                                        height: 18
                                        text: modelData
                                        color: Config.textMuted
                                        font.family: Config.settingsFontFamily
                                        font.pixelSize: Config.settingsUiSize(10)
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Row {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
                                width: parent.width
                                height: 30
                                spacing: 6

                                Repeater {
                                    model: [0, 1, 2, 3]
                                    delegate: SettingsNumberField {
                                        id: settingsGeometryField
                                        width: 76
                                        height: 30
                                        property int fieldIndex: modelData
                                        value: Number(settings.settingsGeometry[fieldIndex])
                                        minimum: fieldIndex === 2 ? 320 : fieldIndex === 3 ? 240 : -Infinity
                                        maximum: Infinity
                                        step: 1
                                        wheelStep: 1
                                        compact: true
                                        fieldWidth: 76
                                        fieldFontSize: 10
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        valueWriter: function(n) {
                                            var a = (settings.settingsGeometry || [640, 40, 560, 850]).slice()
                                            a[fieldIndex] = Math.round(n)
                                            settings.settingsGeometry = a
                                            settings.save()
                                        }
                                        ToolTip.visible: settingsGeometryField.pointerHovered
                                        ToolTip.text: ["X", "Y", "Width", "Height"][fieldIndex]
                                        ToolTip.delay: 500
                                    }
                                }
                            }

                            SettingsDescription {
                                descriptionConditionVisible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
                                text: "Изменения применяются и сохраняются сразу. Для X/Y/Width/Height можно использовать колесо мыши с шагом 1."
                                color: Config.textMuted
                                font.family: Config.settingsFontFamily
                                font.pixelSize: Config.settingsUiSize(9)
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Row {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
                                width: parent.width
                                height: 46
                                spacing: 10

                                SettingsButton {
                                    width: 270
                                    height: 46
                                    text: "УМНОЕ ПЕРЕМЕЩЕНИЕ"
                                    fontSize: 11
                                    fontBold: true
                                    fillOnHover: false
                                    borderOnHover: true
                                    accentColor: Config.accent
                                    backgroundColor: "transparent"
                                    textColor: Config.accent
                                    onClicked: host.settingsMoveRequested()
                                }

                                SettingsDescription {
                                    width: parent.width - 280
                                    height: 46
                                    text: "Скрывает окно настроек и позволяет перемещать его мышью.\nEsc — завершить перемещение и вернуться сюда."
                                    color: Config.textMuted
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(10)
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Фон и рамка окна настроек"
        changeKeys: ({ keys: ["settingsBackground", "settingsBorder"], nested: { colors: ["settingsBackground", "settingsBorder"], moduleBlurEnabled: ["settings"] } })
        padding: 8
        contentSpacing: 6

        SettingsColorField {
            width: parent.width
            label: "Фон окна настроек"
            value: String(Config.settingsBackground)
            targetObject: Config
            targetProperty: "settingsBackground"
            settingsObject: settingsWindowColumn.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            labelWidth: 210
            fieldWidth: 120
        }

        SettingsColorField {
            width: parent.width
            label: "Цвет рамки окна настроек"
            value: String(Config.settingsBorder)
            targetObject: Config
            targetProperty: "settingsBorder"
            settingsObject: settingsWindowColumn.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: false
            labelWidth: 210
            fieldWidth: 120
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsCheckBox {
                width: parent.width
                height: 30
                text: "Блюр окна настроек"
                checked: settings.moduleBlurEnabled.settings === true
                onToggled: settings.setModuleBlurEnabled("settings", checked)
            }
        }
    }
    SettingsGroup {
        id: settingsNavigationGroupOrderFrame
        visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 2
        settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Порядок рамок"
        padding: 8
        contentSpacing: 6

        SettingsDescription {
            width: parent.width
            text: "Перетаскивайте целые разделы панели настроек за маркер ⠿. Dashboard и Общие тоже можно переставлять. Порядок страниц внутри разделов не меняется. С клавиатуры: Alt + ↑/↓."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Column {
            id: settingsNavigationGroupsOrderColumn
            width: parent.width
            spacing: 5

            Repeater {
                id: settingsNavigationGroupsOrderRepeater
                model: host ? host.settingsNavigationGroups : []

                delegate: Row {
                    id: settingsGroupOrderRow
                    required property var modelData
                    required property int index
                    property Item reorderTargetItem: settingsGroupOrderRow
                    Behavior on y {
                        NumberAnimation {
                            duration: Config.animationDuration(160, "appearance")
                            easing.type: Easing.OutCubic
                        }
                    }
                    width: parent.width
                    height: 30
                    readonly property int orderSpacing: 5
                    readonly property int indexWidth: width < 220 ? 14 : 19
                    readonly property int handleWidth: width < 220 ? 24 : 26
                    spacing: orderSpacing

                    Text {
                        width: settingsGroupOrderRow.indexWidth
                        height: 30
                        text: String(settingsGroupOrderRow.index + 1)
                        color: Config.textMuted
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.settingsUiSize(10)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: Math.max(42, parent.width - settingsGroupOrderRow.indexWidth
                            - settingsGroupOrderRow.handleWidth - settingsGroupOrderRow.spacing * 2)
                        height: 30
                        text: settingsGroupOrderRow.modelData.items.length === 1
                            ? settingsGroupOrderRow.modelData.items[0].label : settingsGroupOrderRow.modelData.label
                        color: Config.text
                        font.family: Config.settingsFontFamily
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        HoverHandler { id: settingsGroupOrderLabelHover }
                        ToolTip.visible: settingsGroupOrderLabelHover.hovered && implicitWidth > width + 1
                        ToolTip.text: settingsGroupOrderRow.modelData.items.length === 1
                            ? settingsGroupOrderRow.modelData.items[0].label : settingsGroupOrderRow.modelData.label
                    }

                    DragReorderHandle {
                        width: settingsGroupOrderRow.handleWidth
                        height: 26
                        listRepeater: settingsNavigationGroupsOrderRepeater
                        dropIndicatorHost: settingsNavigationGroupOrderFrame
                        itemIndex: settingsGroupOrderRow.index
                        accessibleLabel: settingsGroupOrderRow.modelData.items.length === 1
                            ? settingsGroupOrderRow.modelData.items[0].label : settingsGroupOrderRow.modelData.label
                        onReorderRequested: function(fromIndex, toIndex) {
                            if (settingsWindowColumn.host)
                                settingsWindowColumn.host.moveSettingsNavigationGroupTo(
                                    settingsGroupOrderRow.modelData.id, toIndex)
                        }
                    }
                }
            }
        }
    }

    Row {
        visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 2
        width: parent.width
        height: 18
        spacing: 6

        Text {
            width: parent.width - 14
            height: parent.height
            text: "Вкладки панели настроек"
            color: Config.settingsSubheading
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            width: 6
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            visible: settingsWindowColumn.settings.hasResetChanges("keys", ({ keys: ["settingsNavigationOrder", "settingsTabLabels"] }))
            color: Config.accent
            border.width: 0
        }
    }

    SettingsDescription {
        descriptionConditionVisible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 2
        width: parent.width
        text: "Переименовывайте страницы и перетаскивайте их за маркер ⠿. Внутри рамки меняется порядок, а перенос на другую рамку перемещает страницу между папками. Перетаскивание на заголовок или пустое место добавляет страницу в конец папки. Порядок самих рамок настраивается отдельно выше. Внутри папки также доступны Alt + ↑/↓."
        color: Config.textMuted
        font.family: Config.settingsFontFamily
        font.pixelSize: Config.settingsUiSize(10)
        wrapMode: Text.WordWrap
    }

    Column {
        visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 2
        width: parent.width
        spacing: 8

        Repeater {
            id: settingsNavigationPageGroupsRepeater
            model: host ? host.settingsNavigationGroups : []

            delegate: SettingsGroup {
                id: settingsNavigationPageGroup
                required property var modelData
                property var groupData: modelData
                property var pageOrderRepeater: settingsNavigationPagesOrderRepeater

                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 2
                width: parent.width
                showFrame: true
                forceFrameBorder: settingsWindowColumn.pageGroupDropTargetId === groupData.id
                borderColor: forceFrameBorder ? Config.accent : Config.baseColor
                borderWidth: forceFrameBorder ? 2 : 1
                heading: groupData.label
                settingsSearchSubTabIndex: 2
                padding: 8
                contentSpacing: 5

                Repeater {
                    id: settingsNavigationPagesOrderRepeater
                    model: settingsNavigationPageGroup.groupData.items

                    delegate: Row {
                        id: settingsNavigationPageOrderRow
                        required property var modelData
                        required property int index
                        property Item reorderTargetItem: settingsNavigationPageOrderRow
                        Behavior on y {
                            NumberAnimation {
                                duration: Config.animationDuration(160, "appearance")
                                easing.type: Easing.OutCubic
                            }
                        }
                        width: parent.width
                        height: 30
                        readonly property int orderSpacing: width < 220 ? 3 : 5
                        readonly property int indexWidth: width < 220 ? 14 : 19
                        readonly property int handleWidth: width < 220 ? 24 : 26
                        spacing: orderSpacing

                        Text {
                            width: settingsNavigationPageOrderRow.indexWidth
                            height: 30
                            text: String(index + 1)
                            color: Config.textMuted
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        SettingsTextField {
                            width: Math.max(42, parent.width - settingsNavigationPageOrderRow.indexWidth
                                - settingsNavigationPageOrderRow.handleWidth - settingsNavigationPageOrderRow.spacing * 2)
                            height: 30
                            text: modelData.label
                            maximumLength: 32
                            selectByMouse: true
                            color: Config.text
                            selectionColor: Config.accent
                            selectedTextColor: Config.black
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(10)
                            placeholderText: host.defaultSettingsTabLabel(modelData.id)
                            Accessible.name: "Название вкладки «" + host.defaultSettingsTabLabel(modelData.id) + "»"
                            Accessible.description: "Изменяет подпись страницы в рамке «" + settingsNavigationPageGroup.groupData.label + "»."
                            onEditingFinished: {
                                if (host) host.setSettingsTabLabel(modelData.id, text)
                            }
                        }

                        DragReorderHandle {
                            width: settingsNavigationPageOrderRow.handleWidth
                            height: 26
                            listRepeater: settingsNavigationPagesOrderRepeater
                            dropIndicatorHost: settingsNavigationPageGroup
                            itemIndex: settingsNavigationPageOrderRow.index
                            allowSingleItemDrag: true
                            accessibleLabel: settingsNavigationPageOrderRow.modelData.label
                            onDragPositionChanged: function(sceneX, sceneY) {
                                settingsWindowColumn.updatePageGroupDropTarget(
                                    settingsNavigationPageOrderRow.modelData.id,
                                    settingsNavigationPageGroup.groupData.id,
                                    sceneX, sceneY)
                            }
                            onReorderRequested: function(fromIndex, toIndex) {
                                if (settingsWindowColumn.host
                                        && !settingsWindowColumn.pageGroupDropTargetId)
                                    settingsWindowColumn.host.moveSettingsTabWithinGroupTo(
                                        settingsNavigationPageGroup.groupData.id,
                                        settingsNavigationPageOrderRow.modelData.id, toIndex)
                            }
                            onDragSessionFinished: function(fromIndex, toIndex) {
                                settingsWindowColumn.finishPageGroupDrag(
                                    settingsNavigationPageOrderRow.modelData.id,
                                    settingsNavigationPageGroup.groupData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "general" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0
                                text: settings.activeProfile ? "Активный профиль: " + settings.activeProfile : "Активный профиль: по умолчанию"
                                color: Config.textMuted
                                font.family: Config.settingsFontFamily
                                font.pixelSize: Config.settingsUiSize(10)
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Row {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 30
                                spacing: 8

                                Text {
                                    width: 120
                                    height: 30
                                    text: "Имя профиля"
                                    color: Config.text
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(11)
                                    verticalAlignment: Text.AlignVCenter
                                }

                                SettingsTextField {
                                    id: profileNameField
                                    width: 180
                                    height: 30
                                    placeholderText: "Имя профиля"
                                    text: settings.activeProfile
                                    color: Config.text
                                    selectionColor: Config.accent
                                    selectedTextColor: Config.black
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(11)
                                    activeFocusOnTab: true
                                    background: Rectangle {
                                        color: "transparent"
                                        border.color: profileNameSavedFeedback.running || profileNameSavedFeedback.paused
                                            ? Config.accent
                                            : ((profileNameField.activeFocus || profileNameField.pointerHovered) ? Config.accent : Config.baseColor)
                                        border.width: (Config.inputBordersEnabled || profileNameField.activeFocus) ? 1 : 0
                                        radius: Config.scaledCornerRadius(Config.settingsUiSize(4))
                                    }

                                    SequentialAnimation {
                                        id: profileNameSavedFeedback
                                        PropertyAnimation {
                                            target: profileSavedMark
                                            property: "opacity"
                                            to: 1
                                            duration: Config.animationDuration(90, "appearance")
                                            easing.type: Config.easingType()
                                        }
                                        PauseAnimation { duration: Config.animationDuration(550, "appearance") }
                                        PropertyAnimation {
                                            target: profileSavedMark
                                            property: "opacity"
                                            to: 0
                                            duration: Config.animationDuration(260, "appearance")
                                            easing.type: Config.easingType()
                                        }
                                    }

                                    onAccepted: {
                                        if (host.profileController.saveProfile(text)) {
                                            profileNameField.text = settings.activeProfile
                                            profileNameSavedFeedback.restart()
                                        } else {
                                            var validationError = host.profileController.profileNameError(text)
                                            profileActionFeedback.showMessage(validationError.length > 0
                                                ? validationError : "Не удалось сохранить профиль", true)
                                        }
                                        host.clearSettingsFocus()
                                    }
                                }

                                Text {
                                    id: profileSavedMark
                                    width: 75
                                    height: 28
                                    text: "✓ сохранено"
                                    color: Config.accent
                                    opacity: 0
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(9)
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }

                            Row {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 30
                                spacing: 8

                                Text {
                                    width: 120
                                    height: 30
                                    text: "Активный профиль"
                                    color: Config.text
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(11)
                                    verticalAlignment: Text.AlignVCenter
                                }

                                SettingsComboBox {
                                    id: profileCombo
                                    width: 150
                                    height: 30
                                    model: host && host.profileController ? host.profileController.profileModel : []
                                    textRole: "name"
                                    valueRole: "name"
                                    displayText: currentIndex >= 0 ? currentText : "Профили не созданы"
                                    contentItem: Text {
                                        text: profileCombo.displayText
                                        color: Config.text
                                        font.family: Config.settingsFontFamily
                                        font.pixelSize: Config.settingsUiSize(11)
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 10
                                        elide: Text.ElideRight
                                    }
                                    background: Rectangle {
                                        color: "transparent"
                                        border.color: (profileCombo.activeFocus || profileCombo.pointerHovered) ? Config.accent : Config.baseColor
                                        border.width: (Config.inputBordersEnabled || profileCombo.activeFocus) ? 1 : 0
                                        radius: Config.frameRadius
                                    }
                                    currentIndex: -1
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(11)
                                    onItemChosen: settingsWindowColumn.pendingDeleteProfileName = ""
                                    onActivated: settingsWindowColumn.pendingDeleteProfileName = ""
                                }

                                SettingsButton {
                                    width: 30
                                    height: 30
                                    text: ""
                                    iconText: "\uf019"
                                    fontSize: 11
                                    enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                                    onClicked: {
                                        if (host.profileController.loadProfile(profileCombo.currentText))
                                            profileActionFeedback.showMessage("✓ профиль загружен")
                                    }
                                }

                                SettingsResetButton {
                                    width: 30
                                    height: 30
                                    label: ""
                                    iconText: "\uf1f8"
                                    tooltip: "Удалить выбранный профиль"
                                    emphasized: true
                                    emphasizedHoverOnly: true
                                    emphasizedColor: "#660000"
                                    emphasizedHoverColor: "#aa0000"
                                    enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                                    onClicked: {
                                        settingsWindowColumn.pendingDeleteProfileName = profileCombo.currentText
                                    }
                                }
                            }

                            Column {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0
                                    && settingsWindowColumn.pendingDeleteProfileName.length > 0
                                width: parent.width
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: "Удалить профиль «" + settingsWindowColumn.pendingDeleteProfileName + "»?"
                                    color: Config.textMuted
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(10)
                                    wrapMode: Text.WordWrap
                                }

                                Row {
                                    width: parent.width
                                    height: 28
                                    spacing: 8

                                    SettingsButton {
                                        width: 70
                                        height: 28
                                        text: "Удалить"
                                        fontSize: 10
                                        emphasized: true
                                        accentColor: "#aa0000"
                                        outlineColor: "#aa0000"
                                        textColor: "#ff9999"
                                        fillOnHover: true
                                        hoverBackgroundColor: "#aa0000"
                                        hoverTextColor: Config.black
                                        tooltip: "Подтвердить удаление профиля"
                                        onClicked: {
                                            var deletingName = settingsWindowColumn.pendingDeleteProfileName
                                            settingsWindowColumn.pendingDeleteProfileName = ""
                                            if (host.profileController.deleteProfile(deletingName))
                                                profileActionFeedback.showMessage("✓ профиль удалён")
                                            else
                                                profileActionFeedback.showMessage("Профиль уже недоступен", true)
                                        }
                                    }

                                    SettingsButton {
                                        width: 64
                                        height: 28
                                        text: "Отмена"
                                        fontSize: 10
                                        tooltip: "Отменить удаление профиля"
                                        onClicked: settingsWindowColumn.pendingDeleteProfileName = ""
                                    }
                                }
                            }

                            Item {
                                id: profileActionFeedback
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0
                                width: parent.width
                                height: 22

                                property string message: ""
                                property bool isError: false

                                function showMessage(value, error) {
                                    message = value
                                    isError = !!error
                                    feedbackAnimation.restart()
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.message
                                    color: parent.isError ? "#ff9999" : Config.accent
                                    opacity: parent.message.length > 0 ? 1 : 0
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(9)
                                }

                                SequentialAnimation {
                                    id: feedbackAnimation
                                    PauseAnimation { duration: 900 }
                                    PropertyAction { target: profileActionFeedback; property: "message"; value: "" }
                                }
                            }


                            Row {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0 && host.profileController.canResetScope("all")
                                width: parent.width
                                height: 30
                                spacing: 8
                                Text {
                                    width: parent.width - 38
                                    text: "Сбросить все настройки"
                                    color: Config.textMuted
                                    font.family: Config.settingsFontFamily
                                    font.pixelSize: Config.settingsUiSize(10)
                                    verticalAlignment: Text.AlignVCenter
                                }
                                SettingsResetButton {
                                    enabled: host.profileController.hasActiveProfile
                                    actionAvailable: host.profileController.canResetScope("all")
                                    tooltip: "Сбросить все параметры"
                                    onClicked: settings.resetAllSettings()
                                }
                            }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["animationSettingsVisibilityStyle", "animationSettingsVisibilityProfile"] })
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
            text: "Анимация"
            color: Config.accent
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(13)
        }

        SettingsRow {
            visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            labelWidth: 210
            labelFontSize: 11
            label: "Стиль"
            spacing: 8
            
            SettingsComboBox {
                id: settingsWindowAnimationVisibilityBox
                width: 180; height: 30
                property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationSettingsVisibilityStyle))
                onItemChosen: function(index) { Config.animationSettingsVisibilityStyle = values[index]; settings.save() }
                Connections { target: Config; function onAnimationSettingsVisibilityStyleChanged() { settingsWindowAnimationVisibilityBox.currentIndex = Math.max(0, settingsWindowAnimationVisibilityBox.values.indexOf(Config.animationSettingsVisibilityStyle)) } }
                background: Rectangle { color: "transparent"; border.color: (settingsWindowAnimationVisibilityBox.activeFocus || settingsWindowAnimationVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || settingsWindowAnimationVisibilityBox.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
                contentItem: Text { text: settingsWindowAnimationVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
            }
        }

        SettingsAnimationCurveControl {
            profile: Config.animationSettingsVisibilityProfile
            searchId: "settings-window-visibility-animation-curve"
            searchLabel: "CSS-кривая появления окна настроек"
            searchKeywords: "окно настроек settings появление закрытие bezier"
            onProfileEdited: function(value) {
                Config.animationSettingsVisibilityProfile = value
                settings.save()
            }
        }
    }

}
