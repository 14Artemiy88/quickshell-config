import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Item {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "calendar"
    width: parent ? parent.width : 0
    height: visible ? calendarColumn.implicitHeight : 0
    implicitHeight: calendarColumn.implicitHeight

    Column {
        id: calendarColumn
        width: parent.width
        spacing: 10

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        heading: "Показ"
        changeKeys: ({ keys: ["calendarAlwaysVisible"] })
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            id: calendarAlwaysVisibleCheck
            width: parent.width
            height: 30
            text: "Показывать календарь всегда"
            checked: Config.calendarAlwaysVisible
            onToggled: {
                Config.calendarAlwaysVisible = checked
                settings.save()
            }
            Connections {
                target: Config
                function onCalendarAlwaysVisibleChanged() { calendarAlwaysVisibleCheck.checked = Config.calendarAlwaysVisible }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        heading: "Стрелки навигации"
        changeKeys: ({ keys: ["calendarArrowY", "calendarNextIcon", "calendarNextSize", "calendarNextX", "calendarPreviousIcon", "calendarPreviousSize", "calendarPreviousX"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width
            height: 24
            spacing: 8
            Item { width: 210; height: parent.height }
            Text { width: 80; height: parent.height; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; height: parent.height; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; height: parent.height; text: "X"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; height: parent.height; text: "Y"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
        }

        SettingsRow {

            label: "Предыдущий месяц"
            labelWidth: 210
            labelElide: Text.ElideRight
            controlSpacing: 8
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width; height: 30; spacing: 8
            
            SettingsTextField { id: calendarPrevIconField; width: 80; height: 30; text: Config.calendarPreviousIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarPreviousIcon = text; settings.save() } }
            SettingsNumberField {
            id: calendarArrowSizeField
            width: 58
            height: 30
            value: Config.calendarPreviousSize
            minimum: 8
            maximum: 64
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "calendarPreviousSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsNumberField {
            id: calendarPrevXField
            width: 58
            height: 30
            value: Config.calendarPreviousX
            minimum: -20
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "calendarPreviousX"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsNumberField {
            id: calendarArrowYField
            width: 58
            height: 30
            value: Config.calendarArrowY
            minimum: -20
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "calendarArrowY"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }

        SettingsRow {

            label: "Следующий месяц"
            labelWidth: 210
            labelElide: Text.ElideRight
            controlSpacing: 8
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width; height: 30; spacing: 8
            
            SettingsTextField { id: calendarNextIconField; width: 80; height: 30; text: Config.calendarNextIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarNextIcon = text; settings.save() } }
            SettingsNumberField {
            id: calendarNextSizeField
            width: 58
            height: 30
            value: Config.calendarNextSize
            minimum: 8
            maximum: 64
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "calendarNextSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsNumberField {
            id: calendarNextXField
            width: 58
            height: 30
            value: Config.calendarNextX
            minimum: -20
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "calendarNextX"
            settingsObject: root.settings
            saveOnEdit: true
        }
            Text { width: 58; height: 30; text: ""; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        }

    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["calendarDayFont", "calendarDayFontSize", "calendarDayY", "calendarTitleFont", "calendarTitleFontSize", "calendarTitleY", "calendarWeekdayFont", "calendarWeekdayFontSize", "calendarWeekdayY"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width; height: 24; spacing: 8
            Item { width: 210; height: parent.height }
            Text { width: 58; height: parent.height; text: "Y"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; height: parent.height; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
            Text { width: 130; height: parent.height; text: "Шрифт"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
        }
        SettingsRow {

            label: "Месяц"
            labelWidth: 210
            controlSpacing: 8
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
            id: calendarTitleY2Field
            width: 58
            height: 30
            value: Config.calendarTitleY
            minimum: -20
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "calendarTitleY"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsNumberField {
            id: calendarTitleSizeField2
            width: 58
            height: 30
            value: Config.calendarTitleFontSize
            minimum: 8
            maximum: 48
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "calendarTitleFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsFontField {
                width: 130
                height: 30
                compact: true
                fieldWidth: 92
                fieldFontSize: 10
                value: Config.calendarTitleFont
                targetObject: Config
                targetProperty: "calendarTitleFont"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {

            label: "Дни недели"
            labelWidth: 210
            controlSpacing: 8
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
            id: calendarWeekdayYField
            width: 58
            height: 30
            value: Config.calendarWeekdayY
            minimum: -20
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "calendarWeekdayY"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsNumberField {
            id: calendarWeekdaySizeField
            width: 58
            height: 30
            value: Config.calendarWeekdayFontSize
            minimum: 8
            maximum: 32
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "calendarWeekdayFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsFontField {
                width: 130
                height: 30
                compact: true
                fieldWidth: 92
                fieldFontSize: 10
                value: Config.calendarWeekdayFont
                targetObject: Config
                targetProperty: "calendarWeekdayFont"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {

            label: "Дни"
            labelWidth: 210
            controlSpacing: 8
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0
            width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
            id: calendarDayYField
            width: 58
            height: 30
            value: Config.calendarDayY
            minimum: -20
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "calendarDayY"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsNumberField {
            id: calendarDaySizeField
            width: 58
            height: 30
            value: Config.calendarDayFontSize
            minimum: 8
            maximum: 32
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "calendarDayFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            SettingsFontField {
                width: 130
                height: 30
                compact: true
                fieldWidth: 92
                fieldFontSize: 10
                value: Config.calendarDayFont
                targetObject: Config
                targetProperty: "calendarDayFont"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["calendarAdjacentDaysColor"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8
            SettingsColorField {
                width: parent.width
                label: "Цвет дней соседних месяцев"
                value: String(Config.calendarAdjacentDaysColor)
                targetObject: Config
                targetProperty: "calendarAdjacentDaysColor"
                settingsObject: settings
                saveOnEdit: true
                allowAlpha: false
                allowTransparent: false
                fieldWidth: 120
                compact: false
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Выходные и отмеченные дни"
        changeKeys: ({ keys: ["calendarWeekendColor"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8
            SettingsColorField {
                width: parent.width
                label: "Цвет выходных и отмеченных дней"
                value: String(Config.calendarWeekendColor)
                targetObject: Config
                targetProperty: "calendarWeekendColor"
                settingsObject: settings
                saveOnEdit: true
                allowAlpha: false
                allowTransparent: false
                fieldWidth: 120
                compact: false
            }
        }

        SettingsDescription {
            descriptionConditionVisible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
            text: "Щёлкни правой кнопкой по дате и выбери «Отметить день», чтобы выделить отпуск или событие этим же цветом."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Прошедшие дни"
        changeKeys: ({ keys: ["calendarPastDaysColor", "calendarPastDaysColorEnabled"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8
            SettingsCheckBox {
                id: pastDaysColorCheck
                width: parent.width
                height: 30
                text: "Выделять прошедшие дни и их заметки другим цветом"
                checked: Config.calendarPastDaysColorEnabled
                onToggled: {
                    Config.calendarPastDaysColorEnabled = checked
                    settings.save()
                }
                Connections {
                    target: Config
                    function onCalendarPastDaysColorEnabledChanged() {
                        pastDaysColorCheck.checked = Config.calendarPastDaysColorEnabled
                    }
                }
            }
        }

        MorphGeometry {
            id: calendarPastDaysColorMorph
            width: parent.width
            enabled: Config.calendarPastDaysColorEnabled
            clip: true
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1
                && (Config.calendarPastDaysColorEnabled || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, calendarPastDaysColorContent.implicitHeight)
            progress: Config.calendarPastDaysColorEnabled ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("ease-out", Config.calendarPastDaysColorEnabled ? "enter" : "exit")

            Column {
                id: calendarPastDaysColorContent
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    height: 30
                    spacing: 8
                    SettingsColorField {
                        width: parent.width
                        label: "Цвет прошедших дней и меток заметок"
                        value: String(Config.calendarPastDaysColor)
                        targetObject: Config
                        targetProperty: "calendarPastDaysColor"
                        settingsObject: settings
                        saveOnEdit: true
                        allowAlpha: false
                        allowTransparent: false
                        fieldWidth: 120
                        compact: false
                    }
                }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["calendarNoteFrameColor", "calendarNoteMarkerPosition", "calendarNoteMarkerStyle"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {

            label: "Вид метки"
            labelWidth: 210
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 2
            width: parent.width
            height: 30
            spacing: 8
            
            SettingsComboBox {
                id: calendarNoteMarkerStyleBox
                width: 180
                height: 30
                property var values: ["dot", "line", "ring", "note", "frame"]
                model: ["Точка", "Полоска", "Кольцо", "Значок заметки", "Рамка"]
                currentIndex: Math.max(0, values.indexOf(Config.calendarNoteMarkerStyle))
                onItemChosen: function(index) {
                    Config.calendarNoteMarkerStyle = values[index]
                    settings.save()
                }
                Connections {
                    target: Config
                    function onCalendarNoteMarkerStyleChanged() {
                        calendarNoteMarkerStyleBox.currentIndex = Math.max(0, calendarNoteMarkerStyleBox.values.indexOf(Config.calendarNoteMarkerStyle))
                    }
                }
                background: Rectangle { color: "transparent"; border.color: (calendarNoteMarkerStyleBox.activeFocus || calendarNoteMarkerStyleBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || calendarNoteMarkerStyleBox.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
                contentItem: Text { text: calendarNoteMarkerStyleBox.currentText; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
            }
        }

        SettingsRow {

            label: "Положение метки"
            labelWidth: 210
            width: parent.width
            height: Config.calendarNoteMarkerStyle === "frame" ? 0 : 30
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 2 && Config.calendarNoteMarkerStyle !== "frame"
            spacing: 8
            
            SettingsComboBox {
                id: calendarNoteMarkerPositionBox
                width: 180
                height: 30
                property var values: Config.calendarNoteMarkerStyle === "line"
                                     ? ["leftCenter", "rightCenter", "topCenter", "bottomCenter"]
                                     : ["topLeft", "topCenter", "topRight", "leftCenter", "rightCenter", "bottomLeft", "bottomCenter", "bottomRight"]
                model: Config.calendarNoteMarkerStyle === "line"
                       ? ["Слева", "Справа", "Сверху", "Снизу"]
                       : ["Сверху слева", "Сверху", "Сверху справа", "Слева", "Справа", "Снизу слева", "Снизу", "Снизу справа"]
                currentIndex: Math.max(0, values.indexOf(Config.calendarNoteMarkerPosition))
                onItemChosen: function(index) {
                    Config.calendarNoteMarkerPosition = values[index]
                    settings.save()
                }
                Connections {
                    target: Config
                    function onCalendarNoteMarkerStyleChanged() {
                        // A stripe only supports its four edges. Preserve the nearest
                        // edge when switching from a corner marker to the stripe style.
                        if (Config.calendarNoteMarkerStyle === "line" &&
                            calendarNoteMarkerPositionBox.values.indexOf(Config.calendarNoteMarkerPosition) < 0) {
                            var pos = String(Config.calendarNoteMarkerPosition || "bottomCenter")
                            if (pos.indexOf("top") === 0)
                                Config.calendarNoteMarkerPosition = "topCenter"
                            else if (pos.indexOf("bottom") === 0)
                                Config.calendarNoteMarkerPosition = "bottomCenter"
                            else if (pos.indexOf("left") === 0)
                                Config.calendarNoteMarkerPosition = "leftCenter"
                            else if (pos.indexOf("right") === 0)
                                Config.calendarNoteMarkerPosition = "rightCenter"
                            else
                                Config.calendarNoteMarkerPosition = "bottomCenter"
                            settings.save()
                        }
                        calendarNoteMarkerPositionBox.currentIndex = Math.max(0, calendarNoteMarkerPositionBox.values.indexOf(Config.calendarNoteMarkerPosition))
                    }
                    function onCalendarNoteMarkerPositionChanged() {
                        calendarNoteMarkerPositionBox.currentIndex = Math.max(0, calendarNoteMarkerPositionBox.values.indexOf(Config.calendarNoteMarkerPosition))
                    }
                }
                background: Rectangle { color: "transparent"; border.color: (calendarNoteMarkerPositionBox.activeFocus || calendarNoteMarkerPositionBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || calendarNoteMarkerPositionBox.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
                contentItem: Text { text: calendarNoteMarkerPositionBox.currentText; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
            }
        }

        Row {
            width: parent.width
            height: Config.calendarNoteMarkerStyle === "frame" ? 30 : 0
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 2 && Config.calendarNoteMarkerStyle === "frame"
            spacing: 8
            SettingsColorField {
                width: parent.width
                label: "Цвет рамки"
                value: String(Config.calendarNoteFrameColor)
                targetObject: Config
                targetProperty: "calendarNoteFrameColor"
                settingsObject: settings
                saveOnEdit: true
                allowAlpha: true
                allowTransparent: false
                fieldWidth: 120
                compact: false
            }
        }
        Row {
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 2
            width: parent.width
            height: 30
            spacing: 8
            Text { width: 210; height: 30; text: "Цвет обводки активной даты с событием"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            Text { height: 30; text: "Цвет событий"; color: Config.calendarWeekendColor; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 3
settingsSearchSubTabIndex: 3
        width: parent.width
        showFrame: true
        heading: "Появление модуля"
        changeKeys: ({ keys: ["animationCalendarFadeDuration", "animationCalendarSlideDuration", "animationCalendarVisibilityStyle", "animationCalendarVisibilityProfile"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {

            label: "Стиль"
            labelWidth: 210
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 3
            width: parent.width
            height: 30
            spacing: 8
            
            SettingsComboBox {
                id: animationCalendarVisibilityBox
                width: 180
                height: 30
                property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationCalendarVisibilityStyle))
                onItemChosen: function(index) { Config.animationCalendarVisibilityStyle = values[index]; settings.save() }
                Connections {
                    target: Config
                    function onAnimationCalendarVisibilityStyleChanged() { animationCalendarVisibilityBox.currentIndex = Math.max(0, animationCalendarVisibilityBox.values.indexOf(Config.animationCalendarVisibilityStyle)) }
                }
                background: Rectangle { color: "transparent"; border.color: (animationCalendarVisibilityBox.activeFocus || animationCalendarVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || animationCalendarVisibilityBox.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
                contentItem: Text { text: animationCalendarVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
            }
        }

        SettingsAnimationCurveControl {
            profile: Config.animationCalendarVisibilityProfile
            searchId: "calendar-visibility-animation-curve"
            searchLabel: "CSS-кривая появления календаря"
            searchKeywords: "календарь модуль появление закрытие spring пружина bezier"
            onProfileEdited: function(value) {
                Config.animationCalendarVisibilityProfile = value
                root.settings.save()
            }
        }

        SettingsRow {

            label: "Раскрытие (мс)"
            labelWidth: 210
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 3
            width: parent.width
            height: 30
            spacing: 8
            
            SettingsNumberField {
                id: calendarAnimationSlideField
                width: 100; height: 30
                value: Config.animationCalendarSlideDuration
                minimum: 0; maximum: 5000; step: 50; wheelStep: 50; decimals: 0; compact: true
                fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "animationCalendarSlideDuration"; settingsObject: root.settings; saveOnEdit: true
            }
        }

        SettingsRow {

            label: "Исчезновение (мс)"
            labelWidth: 210
            visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 3
            width: parent.width
            height: 30
            spacing: 8
            
            SettingsNumberField {
                id: calendarAnimationFadeField
                width: 100; height: 30
                value: Config.animationCalendarFadeDuration
                minimum: 0; maximum: 5000; step: 50; wheelStep: 50; decimals: 0; compact: true
                fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "animationCalendarFadeDuration"; settingsObject: root.settings; saveOnEdit: true
            }
        }
    }

    SettingsAnimationGroup {
        visible: host && host.currentPageId === "calendar" && host.currentPageSubTabIndex === 3
        width: root.width
        settings: root.settings
        heading: "Внутренние переходы календаря"
        changeKeys: ({ keys: ["animationCalendarMorphDuration", "animationCalendarMorphProfile"] })
        duration: Config.animationCalendarMorphDuration
        profile: Config.animationCalendarMorphProfile

        onDurationEdited: function(value) {
            Config.animationCalendarMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            Config.animationCalendarMorphProfile = value
            root.settings.save()
        }

        SettingsGroup {
            visible: Config.settingsShowDescriptions
            width: parent.width
            showFrame: true
            heading: "Что управляется"
            padding: 8
            contentSpacing: 4
            SettingsDescription {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Профиль и длительность управляют открытием и закрытием встроенного просмотра и редактора заметки. Они не меняют перелистывание месяцев и анимацию появления самого календаря."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }

    }
}
