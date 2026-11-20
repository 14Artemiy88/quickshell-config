import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: settingsWindowColumn

    function syncProfileComboToActiveProfile() {
        var idx = host && host.profileController
            ? host.profileController.indexOfProfile(String(settings.activeProfile || "")) : -1
        profileCombo.currentIndex = idx >= 0 ? idx : -1
    }

    Connections {
        target: settings
        function onProfilesRevisionChanged() { Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile) }
        function onActiveProfileChanged() { Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile) }
    }

    Component.onCompleted: Qt.callLater(settingsWindowColumn.syncProfileComboToActiveProfile)
    property var host
    property var settings: Settings

    width: parent ? parent.width : 0
    spacing: 10
    SettingsGroup {
                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing"] })
        padding: 8
        contentSpacing: 6

        Text {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 0
                                text: "Интерфейс настроек"
                                color: Config.textMuted
                                font.family: Config.settingsFont
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
                                label: "Размер шрифта настроек"
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
                                        font.family: Config.settingsFont
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

                            Text {
                                visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
                                text: "Изменения применяются и сохраняются сразу. Для X/Y/Width/Height можно использовать колесо мыши с шагом 1."
                                color: Config.textMuted
                                font.family: Config.settingsFont
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

                                Text {
                                    width: parent.width - 280
                                    height: 46
                                    text: "Скрывает окно настроек и позволяет перемещать его мышью.\nEsc — завершить перемещение и вернуться сюда."
                                    color: Config.textMuted
                                    font.family: Config.settingsFont
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
                visible: host && host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Вкладки панели настроек"
        changeKeys: ({ keys: ["settingsTabOrder", "settingsTabLabels"] })
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Изменяйте названия страниц и их порядок внутри групп. Сами группы имеют фиксированный порядок. Изменения сохраняются автоматически."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width
            spacing: 5

            Repeater {
                model: host ? host.settingsNavigationItems : []

                delegate: Row {
                    width: parent.width
                    height: 30
                    spacing: 5

                    Text {
                        width: 19
                        height: 30
                        text: String(index + 1)
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    SettingsTextField {
                        width: Math.max(80, parent.width - 19 - 28 - 28 - 15)
                        height: 30
                        text: modelData.label
                        maximumLength: 32
                        selectByMouse: true
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        placeholderText: host.defaultSettingsTabLabel(modelData.id)
                        onEditingFinished: {
                            if (host) host.setSettingsTabLabel(modelData.id, text)
                        }
                    }

                    Item {
                        width: 28
                        height: 30
                        SettingsButton {
                            anchors.fill: parent
                            visible: host && host.settingsTabCanMove(modelData.id, -1)
                            enabled: visible
                            iconText: "↑"
                            fontSize: 10
                            tooltip: "Переместить выше"
                            onClicked: if (host) host.moveSettingsTab(modelData.id, -1)
                        }
                    }

                    Item {
                        width: 28
                        height: 30
                        SettingsButton {
                            anchors.fill: parent
                            visible: host && host.settingsTabCanMove(modelData.id, 1)
                            enabled: visible
                            iconText: "↓"
                            fontSize: 10
                            tooltip: "Переместить ниже"
                            onClicked: if (host) host.moveSettingsTab(modelData.id, 1)
                        }
                    }
                }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "general" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1
                                text: settings.activeProfile ? "Активный профиль: " + settings.activeProfile : "Активный профиль: по умолчанию"
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Row {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1
                                width: parent.width
                                height: 30
                                spacing: 8

                                Text {
                                    width: 120
                                    height: 30
                                    text: "Имя профиля"
                                    color: Config.text
                                    font.family: Config.settingsFont
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
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(11)
                                    activeFocusOnTab: true
                                    background: Rectangle {
                                        color: Config.settingsBackground
                                        border.color: profileNameSavedFeedback.running || profileNameSavedFeedback.paused
                                            ? Config.accent
                                            : ((profileNameField.activeFocus || profileNameField.pointerHovered) ? Config.accent : Config.baseColor)
                                        border.width: 1
                                        radius: 4
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
                                        if (host.profileController.saveProfile(text))
                                            profileNameSavedFeedback.restart()
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
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(9)
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }

                            Row {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1
                                width: parent.width
                                height: 30
                                spacing: 8

                                Text {
                                    width: 120
                                    height: 30
                                    text: "Активный профиль"
                                    color: Config.text
                                    font.family: Config.settingsFont
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
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(11)
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 10
                                        elide: Text.ElideRight
                                    }
                                    background: Rectangle {
                                        color: Config.settingsBackground
                                        border.color: (profileCombo.activeFocus || profileCombo.pointerHovered) ? Config.accent : Config.baseColor
                                        border.width: 1
                                        radius: Config.frameRadius
                                    }
                                    currentIndex: -1
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(11)
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
                                        if (host.profileController.deleteProfile(profileCombo.currentText))
                                            profileActionFeedback.showMessage("✓ профиль удалён")
                                    }
                                }
                            }

                            Item {
                                id: profileActionFeedback
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1
                                width: parent.width
                                height: 22

                                property string message: ""

                                function showMessage(value) {
                                    message = value
                                    feedbackAnimation.restart()
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.message
                                    color: Config.accent
                                    opacity: parent.message.length > 0 ? 1 : 0
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(9)
                                }

                                SequentialAnimation {
                                    id: feedbackAnimation
                                    PauseAnimation { duration: 900 }
                                    PropertyAction { target: profileActionFeedback; property: "message"; value: "" }
                                }
                            }


                            Row {
                                visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1 && host.profileController.canResetScope("all")
                                width: parent.width
                                height: 30
                                spacing: 8
                                Text {
                                    width: parent.width - 38
                                    text: "Сбросить все настройки"
                                    color: Config.textMuted
                                    font.family: Config.settingsFont
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
        changeKeys: ({ keys: ["animationSettingsVisibilityStyle"] })
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1
            text: "Анимация"
            color: Config.accent
            font.family: Config.settingsFont
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
                background: Rectangle { color: Config.settingsBackground; border.color: (settingsWindowAnimationVisibilityBox.activeFocus || settingsWindowAnimationVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                contentItem: Text { text: settingsWindowAnimationVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
            }
        }
    }

}
