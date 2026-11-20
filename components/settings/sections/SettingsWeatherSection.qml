import "../../.."
import QtQuick
import "../primitives"
import "../../primitives"

Column {
    id: weatherSection

    property var host
    property var settings: Settings
    // Keep the detailed nine-direction glyph editor out of the way until needed.
    property bool windDirectionSettingsExpanded: false

    visible: host && host.currentPageId === "weather"
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        heading: "Токен Gismeteo"
        padding: 8
        contentSpacing: 6

                        SettingsTextField {
                            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
                            id: token
                            width: parent.width
                            height: 34
                            text: settings.weatherToken
                            color: Config.text
                            selectionColor: Config.accent
                            selectedTextColor: Config.black
                            placeholderText: "Введите токен Gismeteo"
                            placeholderTextColor: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(12)
                            activeFocusOnTab: true
                            background: Rectangle {
                                color: Config.settingsBackground
                                border.color: (token.activeFocus || token.pointerHovered) ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: Config.radius
                            }
                            onEditingFinished: {
                                settings.weatherToken = text
                                settings.save()
                            }
                        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        heading: "Время обновлений"
        changeKeys: ({ keys: ["weatherDailyIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherManualRefreshCooldownSeconds", "weatherNowIntervalMinutes", "weatherRetryDelayMinutes"] })
        padding: 8
        contentSpacing: 6

                        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
    width: parent.width
    height: 30
    spacing: 8
    label: "Погода сейчас (мин)"
    labelWidth: 210
                                SettingsNumberField { id: weatherNowIntervalField; width: 100; height: 30; value: Config.weatherNowIntervalMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherNowIntervalMinutes"; settingsObject: settings; saveOnEdit: true }
}
                        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
    width: parent.width
    height: 30
    spacing: 8
    label: "Погода по часам (мин)"
    labelWidth: 210
                                SettingsNumberField { id: weatherHourlyIntervalField; width: 100; height: 30; value: Config.weatherHourlyIntervalMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherHourlyIntervalMinutes"; settingsObject: settings; saveOnEdit: true }
}
                        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
    width: parent.width
    height: 30
    spacing: 8
    label: "Погода по дням (мин)"
    labelWidth: 210
                                SettingsNumberField { id: weatherDailyIntervalField; width: 100; height: 30; value: Config.weatherDailyIntervalMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherDailyIntervalMinutes"; settingsObject: settings; saveOnEdit: true }
}
                        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
    width: parent.width
    height: 30
    spacing: 8
    label: "Повтор после ошибки (мин)"
    labelWidth: 210
        labelElide: Text.ElideRight
                                SettingsNumberField { id: weatherRetryDelayField; width: 100; height: 30; value: Config.weatherRetryDelayMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherRetryDelayMinutes"; settingsObject: settings; saveOnEdit: true }
}
                        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 0
    width: parent.width
    height: 30
    spacing: 8
    label: "Пауза между ручными обновлениями (с)"
    labelWidth: 210
        labelElide: Text.ElideRight
                                SettingsNumberField { id: weatherManualCooldownField; width: 100; height: 30; value: Config.weatherManualRefreshCooldownSeconds; minimum: 5; maximum: 3600; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherManualRefreshCooldownSeconds"; settingsObject: settings; saveOnEdit: true }
}
    }
                // Keep the nine-direction glyph editor as the first visible control in this subtab.
    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["weatherWindCalmFont", "weatherWindCalmIcon", "weatherWindEFont", "weatherWindEIcon", "weatherWindNEFont", "weatherWindNEIcon", "weatherWindNFont", "weatherWindNIcon", "weatherWindNWFont", "weatherWindNWIcon", "weatherWindSEFont", "weatherWindSEIcon", "weatherWindSFont", "weatherWindSIcon", "weatherWindSWFont", "weatherWindSWIcon", "weatherWindWFont", "weatherWindWIcon"] })
        padding: 8
        contentSpacing: 6

                        Rectangle {
                            id: windDirectionSettingsHeader
                            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
                            width: parent.width
                            height: 34
                            radius: Config.radius
                            color: Config.settingsBackground
                            border.color: windDirectionSettingsMouse.containsMouse ? Config.accent : Config.baseColor
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    width: 24
                                    height: parent.height
                                    text: weatherSection.windDirectionSettingsExpanded ? "▾" : "▸"
                                    color: windDirectionSettingsMouse.containsMouse ? Config.accent : Config.text
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(17)
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(0, parent.width - 32)
                                    text: "Иконки направления ветра"
                                    color: Config.text
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(11)
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: windDirectionSettingsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: weatherSection.windDirectionSettingsExpanded = !weatherSection.windDirectionSettingsExpanded
                            }
                        }
                        MorphGeometry {
                            id: windDirectionRowsMorph
                            width: parent.width
                            clip: true
                            visible: weatherSection.windDirectionSettingsExpanded || normalizedProgress > 0.001
                            fromGeometry: Qt.rect(0, 0, parent.width, 0)
                            toGeometry: Qt.rect(0, 0, parent.width, windDirectionRowsContent.implicitHeight)
                            progress: weatherSection.windDirectionSettingsExpanded ? 1 : 0
                            animationDuration: Config.animationDuration(180, "appearance")
                            animationEasing: Config.animationEasingType("standard", weatherSection.windDirectionSettingsExpanded ? "enter" : "exit")

                            Column {
                                id: windDirectionRowsContent
                                width: parent.width
                                spacing: 5

                            Row {
                                width: parent.width
                                height: 22
                                spacing: 6
                                Text { width: 130; text: "Направление"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter }
                                Text { width: 55; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                Text { width: 150; text: "Шрифт"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Без направления (0)"
                                iconValue: Config.weatherWindCalmIcon
                                fontValue: Config.weatherWindCalmFont
                                onIconEdited: function(value) { Config.weatherWindCalmIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindCalmFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Север (1)"
                                iconValue: Config.weatherWindNIcon
                                fontValue: Config.weatherWindNFont
                                onIconEdited: function(value) { Config.weatherWindNIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindNFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Северо-восток (2)"
                                iconValue: Config.weatherWindNEIcon
                                fontValue: Config.weatherWindNEFont
                                onIconEdited: function(value) { Config.weatherWindNEIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindNEFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Восток (3)"
                                iconValue: Config.weatherWindEIcon
                                fontValue: Config.weatherWindEFont
                                onIconEdited: function(value) { Config.weatherWindEIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindEFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Юго-восток (4)"
                                iconValue: Config.weatherWindSEIcon
                                fontValue: Config.weatherWindSEFont
                                onIconEdited: function(value) { Config.weatherWindSEIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindSEFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Юг (5)"
                                iconValue: Config.weatherWindSIcon
                                fontValue: Config.weatherWindSFont
                                onIconEdited: function(value) { Config.weatherWindSIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindSFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Юго-запад (6)"
                                iconValue: Config.weatherWindSWIcon
                                fontValue: Config.weatherWindSWFont
                                onIconEdited: function(value) { Config.weatherWindSWIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindSWFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Запад (7)"
                                iconValue: Config.weatherWindWIcon
                                fontValue: Config.weatherWindWFont
                                onIconEdited: function(value) { Config.weatherWindWIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindWFont = value; settings.save() }
                            }
                            WeatherWindDirectionSettingsRow {
                                label: "Северо-запад (8)"
                                iconValue: Config.weatherWindNWIcon
                                fontValue: Config.weatherWindNWFont
                                onIconEdited: function(value) { Config.weatherWindNWIcon = value; settings.save() }
                                onFontEdited: function(value) { Config.weatherWindNWFont = value; settings.save() }
                            }
                            }
                        }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Ширина блоков"
        changeKeys: ({ keys: ["weatherTempColumnWidth", "weatherMiddleBlockWidth", "weatherWindColumnWidth"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
    width: parent.width
    height: 30
    spacing: 8
    label: "Левый · температура"
    labelWidth: 210
                SettingsNumberField { id: weatherLeftBlockWidthField; width: 100; height: 30; value: Config.weatherTempColumnWidth; minimum: 40; maximum: 200; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherTempColumnWidth"; settingsObject: settings; saveOnEdit: true }
}
        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
    width: parent.width
    height: 30
    spacing: 8
    label: "Средний · иконка"
    labelWidth: 210
                SettingsNumberField { id: weatherMiddleBlockWidthField; width: 100; height: 30; value: Config.weatherMiddleBlockWidth; minimum: 16; maximum: 180; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherMiddleBlockWidth"; settingsObject: settings; saveOnEdit: true }
}
        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
    width: parent.width
    height: 30
    spacing: 8
    label: "Правый · ветер"
    labelWidth: 210
                SettingsNumberField { id: weatherRightBlockWidthField; width: 100; height: 30; value: Config.weatherWindColumnWidth; minimum: 60; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindColumnWidth"; settingsObject: settings; saveOnEdit: true }
}
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Выравнивание блоков"
        changeKeys: ({ keys: ["weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
    width: parent.width
    height: 30
    spacing: 8
    label: "Левый · температура"
    labelWidth: 210
                SettingsComboBox {
                    id: weatherLeftAlignmentCombo; width: 150; height: 30
                    model: ["Слева", "По центру", "Справа"]
                    currentIndex: ["left", "center", "right"].indexOf(Config.weatherLeftBlockAlignment) >= 0 ? ["left", "center", "right"].indexOf(Config.weatherLeftBlockAlignment) : 1
                    onItemChosen: index => { Config.weatherLeftBlockAlignment = ["left", "center", "right"][index]; settings.save() }
                    Connections { target: Config; function onWeatherLeftBlockAlignmentChanged() { weatherLeftAlignmentCombo.currentIndex = ["left", "center", "right"].indexOf(Config.weatherLeftBlockAlignment) >= 0 ? ["left", "center", "right"].indexOf(Config.weatherLeftBlockAlignment) : 1 } }
                }
}
        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
    width: parent.width
    height: 30
    spacing: 8
    label: "Средний · иконка"
    labelWidth: 210
                SettingsComboBox {
                    id: weatherMiddleAlignmentCombo; width: 150; height: 30
                    model: ["Слева", "По центру", "Справа"]
                    currentIndex: ["left", "center", "right"].indexOf(Config.weatherMiddleBlockAlignment) >= 0 ? ["left", "center", "right"].indexOf(Config.weatherMiddleBlockAlignment) : 1
                    onItemChosen: index => { Config.weatherMiddleBlockAlignment = ["left", "center", "right"][index]; settings.save() }
                    Connections { target: Config; function onWeatherMiddleBlockAlignmentChanged() { weatherMiddleAlignmentCombo.currentIndex = ["left", "center", "right"].indexOf(Config.weatherMiddleBlockAlignment) >= 0 ? ["left", "center", "right"].indexOf(Config.weatherMiddleBlockAlignment) : 1 } }
                }
}
        SettingsRow {
    visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
    width: parent.width
    height: 30
    spacing: 8
    label: "Правый · ветер"
    labelWidth: 210
                SettingsComboBox {
                    id: weatherRightAlignmentCombo; width: 150; height: 30
                    model: ["Слева", "По центру", "Справа"]
                    currentIndex: ["left", "center", "right"].indexOf(Config.weatherRightBlockAlignment) >= 0 ? ["left", "center", "right"].indexOf(Config.weatherRightBlockAlignment) : 2
                    onItemChosen: index => { Config.weatherRightBlockAlignment = ["left", "center", "right"][index]; settings.save() }
                    Connections { target: Config; function onWeatherRightBlockAlignmentChanged() { weatherRightAlignmentCombo.currentIndex = ["left", "center", "right"].indexOf(Config.weatherRightBlockAlignment) >= 0 ? ["left", "center", "right"].indexOf(Config.weatherRightBlockAlignment) : 2 } }
                }
}
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Иконка текущей погоды"
        changeKeys: ({ keys: ["weatherIconSize", "weatherIconX", "weatherIconY", "weatherIconPlacement"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Расположение"
            labelWidth: 210
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsComboBox {
                id: weatherIconPlacementCombo; width: 150; height: 30
                model: ["Слева", "По центру", "Скрыть"]
                currentIndex: ["left", "center", "off"].indexOf(Config.weatherIconPlacement) >= 0 ? ["left", "center", "off"].indexOf(Config.weatherIconPlacement) : 1
                onItemChosen: index => { Config.weatherIconPlacement = ["left", "center", "off"][index]; settings.save() }
                Connections { target: Config; function onWeatherIconPlacementChanged() { weatherIconPlacementCombo.currentIndex = ["left", "center", "off"].indexOf(Config.weatherIconPlacement) >= 0 ? ["left", "center", "off"].indexOf(Config.weatherIconPlacement) : 1 } }
            }
        }
        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1; width: parent.width; height: 24; spacing: 8
            Item { width: 210; height: 24 }
            Text { width: 70; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 70; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 70; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        SettingsRow {
            label: "Иконка"
            labelWidth: 210
            controlSpacing: 8
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsNumberField { id: weatherIconXField; width: 70; height: 30; value: Config.weatherIconX; minimum: 0; maximum: 500; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherIconX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherIconYField; width: 70; height: 30; value: Config.weatherIconY; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherIconY"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherIconSizeField; width: 70; height: 30; value: Config.weatherIconSize; minimum: 16; maximum: 128; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherIconSize"; settingsObject: settings; saveOnEdit: true }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Описание погоды"
        changeKeys: ({ keys: ["weatherDescriptionX", "weatherDescriptionY", "weatherDescriptionWidth", "weatherDescriptionFontSize"] })
        padding: 8
        contentSpacing: 6

        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1; width: parent.width; height: 24; spacing: 8
            Item { width: 210; height: 24 }
            Text { width: 70; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 70; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        SettingsRow {
            label: "Описание"
            labelWidth: 210
            controlSpacing: 8
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsNumberField { id: weatherDescriptionXField; width: 70; height: 30; value: Config.weatherDescriptionX; minimum: -300; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherDescriptionX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherDescriptionYField; width: 70; height: 30; value: Config.weatherDescriptionY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDescriptionY"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Ширина / размер текста"
            labelWidth: 210
            labelElide: Text.ElideRight
            controlSpacing: 8
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsNumberField { id: weatherDescriptionWidthField; width: 70; height: 30; value: Config.weatherDescriptionWidth; minimum: 20; maximum: 400; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDescriptionWidth"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherDescSizeField; width: 70; height: 30; value: Config.weatherDescriptionFontSize; minimum: 6; maximum: 48; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDescriptionFontSize"; settingsObject: settings; saveOnEdit: true }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Стрелка ветра"
        changeKeys: ({ keys: ["weatherArrowSize", "weatherArrowYOffset", "weatherWindArrowGap"] })
        padding: 8
        contentSpacing: 6

        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1; width: parent.width; height: 24; spacing: 8
            Item { width: 210; height: 24 }
            Text { width: 70; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 70; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 70; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Row {            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8
            Item { width: 210; height: 30 }
            SettingsNumberField { id: weatherWindGapField; width: 70; height: 30; value: Config.weatherWindArrowGap; minimum: -20; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindArrowGap"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherArrowYField; width: 70; height: 30; value: Config.weatherArrowYOffset; minimum: -40; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherArrowYOffset"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherArrowSizeField; width: 70; height: 30; value: Config.weatherArrowSize; minimum: 8; maximum: 64; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherArrowSize"; settingsObject: settings; saveOnEdit: true }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Температура комфорта"
        changeKeys: ({ keys: ["weatherShowComfort", "weatherComfortFontSize", "weatherComfortHeight", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherComfortY", "weatherComfortOffsetY", "weatherComfortOffsetX"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Показывать"
            labelWidth: 210

            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsCheckBox {
                id: weatherShowComfortCheckBox
                width: 24; height: 30; indicatorOnly: true; checked: Config.weatherShowComfort
                onToggled: { Config.weatherShowComfort = checked; settings.save() }
                Connections { target: Config; function onWeatherShowComfortChanged() { weatherShowComfortCheckBox.checked = Config.weatherShowComfort } }
            }
        }
        MorphGeometry {
            id: weatherComfortOptionsMorph
            width: parent.width
            clip: true
            visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
                && (Config.weatherShowComfort || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, weatherComfortOptionsContent.implicitHeight)
            progress: Config.weatherShowComfort ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.weatherShowComfort ? "enter" : "exit")

            Column {
                id: weatherComfortOptionsContent
                width: parent.width
                spacing: 6

            SettingsColorField { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1; width: parent.width; label: "Цвет обводки"; value: String(Config.weatherComfortOutlineColor); targetObject: Config; targetProperty: "weatherComfortOutlineColor"; settingsObject: settings; saveOnEdit: true; allowAlpha: false; allowTransparent: false; labelWidth: 210; fieldWidth: 120 }
            SettingsRow {
            label: "Толщина обводки"
            labelWidth: 210
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

                SettingsNumberField { id: weatherComfortOutlineWidthField; width: 100; height: 30; value: Config.weatherComfortOutlineWidth; minimum: 0; maximum: 4; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherComfortOutlineWidth"; settingsObject: settings; saveOnEdit: true }
            }
            SettingsRow {
            label: "Положение Y"
            labelWidth: 210
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

                SettingsNumberField { id: weatherComfortYField; width: 100; height: 30; value: Config.weatherComfortY + Config.weatherComfortOffsetY; minimum: -120; maximum: 200; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; valueWriter: function(n) { var baseY = Math.max(-20, Math.min(100, n)); Config.weatherComfortY = baseY; Config.weatherComfortOffsetY = n - baseY }; settingsObject: settings; saveOnEdit: true }
            }
            SettingsRow {
            label: "Смещение X"
            labelWidth: 210
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

                SettingsNumberField { id: weatherComfortOffsetXField; width: 100; height: 30; value: Config.weatherComfortOffsetX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherComfortOffsetX"; settingsObject: settings; saveOnEdit: true }
            }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Положение элементов"
        changeKeys: ({ keys: ["weatherTempX", "weatherTempOffsetX", "weatherTempOffsetY", "weatherWindColumnX", "weatherWindColumnY", "weatherWindSpeedX", "weatherWindSpeedY", "weatherWindUnitX", "weatherWindUnitY", "weatherPressureX", "weatherPressureY", "weatherPressureUnitX", "weatherPressureUnitY"] })
        padding: 8
        contentSpacing: 6

        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1; width: parent.width; height: 24; spacing: 6
            Item { width: 210; height: 24 }
            Text { width: 62; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 62; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        SettingsRow {
            label: "Температура"
            labelWidth: 210
            controlSpacing: 6
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 6

            SettingsNumberField { id: weatherTempPositionXField; width: 62; height: 30; value: Config.weatherTempX + Config.weatherTempOffsetX; minimum: -100; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; valueWriter: function(n) { Config.weatherTempX = Math.max(0, Math.min(200, n)); Config.weatherTempOffsetX = n - Config.weatherTempX }; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherTempPositionYField; width: 62; height: 30; value: Config.weatherTempOffsetY; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherTempOffsetY"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Колонка ветра"
            labelWidth: 210
            controlSpacing: 6
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 6

            SettingsNumberField { id: weatherWindColumnXField; width: 62; height: 30; value: Config.weatherWindColumnX; minimum: 0; maximum: 500; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindColumnX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherWindColumnYField; width: 62; height: 30; value: Config.weatherWindColumnY; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindColumnY"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Скорость ветра"
            labelWidth: 210
            controlSpacing: 6
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 6

            SettingsNumberField { id: weatherWindSpeedXField; width: 62; height: 30; value: Config.weatherWindSpeedX; minimum: 0; maximum: 250; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindSpeedX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherWindSpeedYField; width: 62; height: 30; value: Config.weatherWindSpeedY; minimum: -20; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindSpeedY"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Единица ветра"
            labelWidth: 210
            controlSpacing: 6
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 6

            SettingsNumberField { id: weatherWindUnitXField; width: 62; height: 30; value: Config.weatherWindUnitX; minimum: 0; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindUnitX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherWindUnitYField; width: 62; height: 30; value: Config.weatherWindUnitY; minimum: -20; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindUnitY"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Давление"
            labelWidth: 210
            controlSpacing: 6
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 6

            SettingsNumberField { id: weatherPressureXField; width: 62; height: 30; value: Config.weatherPressureX; minimum: -100; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherPressureX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherPressureYField; width: 62; height: 30; value: Config.weatherPressureY; minimum: 0; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureY"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Единица давления"
            labelWidth: 210
            controlSpacing: 6
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 6

            SettingsNumberField { id: weatherPressureUnitXField; width: 62; height: 30; value: Config.weatherPressureUnitX; minimum: 0; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureUnitX"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherPressureUnitYField; width: 62; height: 30; value: Config.weatherPressureUnitY; minimum: -20; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherPressureUnitY"; settingsObject: settings; saveOnEdit: true }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Оформление давления"
        changeKeys: ({ keys: ["weatherPressureFontSize", "weatherPressureUnitFontSize", "weatherPressureValueWidth"] })
        padding: 8
        contentSpacing: 6

        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1; width: parent.width; height: 24; spacing: 8
            Item { width: 210; height: 24 }
            Text { width: 70; text: "Ширина"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            Text { width: 70; text: "Шрифт"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        SettingsRow {
            label: "Значение давления"
            labelWidth: 210
            controlSpacing: 8
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsNumberField { id: weatherPressureWidthExtraField; width: 70; height: 30; value: Config.weatherPressureValueWidth; minimum: 20; maximum: 180; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureValueWidth"; settingsObject: settings; saveOnEdit: true }
            SettingsNumberField { id: weatherPressureFontExtraField; width: 70; height: 30; value: Config.weatherPressureFontSize; minimum: 8; maximum: 48; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureFontSize"; settingsObject: settings; saveOnEdit: true }
        }
        SettingsRow {
            label: "Единица давления"
            labelWidth: 210
            visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            SettingsNumberField { id: weatherPressureUnitFontExtraField; width: 70; height: 30; value: Config.weatherPressureUnitFontSize; minimum: 6; maximum: 30; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureUnitFontSize"; settingsObject: settings; saveOnEdit: true }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Почасовой блок"
        changeKeys: ({ keys: ["weatherHourlyCount", "weatherHourlyDayFontSize", "weatherHourlyDayY", "weatherHourlyIconWidth", "weatherHourlyIconY", "weatherHourlyTempFontSize", "weatherHourlyTempY", "weatherHourlyTopPadding"] })
        padding: 8
        contentSpacing: 6

                        SettingsRow {
            label: "Количество часов"
            labelWidth: 210
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: whCount; width: 58; height: 30; value: Config.weatherHourlyCount; minimum: 1; maximum: 12; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyCount"; settingsObject: settings; saveOnEdit: true }
                        }
                        SettingsRow {
            label: "Верхний отступ"
            labelWidth: 210
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: whPad; width: 58; height: 30; value: Config.weatherHourlyTopPadding; minimum: 0; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyTopPadding"; settingsObject: settings; saveOnEdit: true }
                        }
                        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 2; width: parent.width; height: 24; spacing: 8
                            Item { width: 210; height: 24 }
                            Text { width: 58; y: 4; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            Text { width: 58; y: 4; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        SettingsRow {
            label: "Время"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: whDayYTable; width: 58; height: 30; value: Config.weatherHourlyDayY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyDayY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: whDaySizeTable; width: 58; height: 30; value: Config.weatherHourlyDayFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyDayFontSize"; settingsObject: settings; saveOnEdit: true }
                        }
                        SettingsRow {
            label: "Иконка"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: whIconYTable; width: 58; height: 30; value: Config.weatherHourlyIconY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyIconY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: whIconSizeTable; width: 58; height: 30; value: Config.weatherHourlyIconWidth; minimum: 16; maximum: 90; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyIconWidth"; settingsObject: settings; saveOnEdit: true }
                        }
                        SettingsRow {
            label: "Температура"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: whTempYTable; width: 58; height: 30; value: Config.weatherHourlyTempY; minimum: 0; maximum: 150; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyTempY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: whTempSizeTable; width: 58; height: 30; value: Config.weatherHourlyTempFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyTempFontSize"; settingsObject: settings; saveOnEdit: true }
                        }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 3
settingsSearchSubTabIndex: 3
        width: parent.width
        showFrame: true
        heading: "Дневной прогноз"
        changeKeys: ({ keys: ["weatherDailyCount", "weatherDailyDayFontSize", "weatherDailyDayY", "weatherDailyHighTempFontSize", "weatherDailyHighTempX", "weatherDailyHighTempY", "weatherDailyIconWidth", "weatherDailyIconY", "weatherDailyLowTempFontSize", "weatherDailyLowTempX", "weatherDailyLowTempY", "weatherDailyTopPadding"] })
        padding: 8
        contentSpacing: 6

                        SettingsRow {
            label: "Количество дней"
            labelWidth: 210
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: wdCount; width: 58; height: 30; value: Config.weatherDailyCount; minimum: 1; maximum: 4; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyCount"; settingsObject: settings; saveOnEdit: true }
                        }
                        SettingsRow {
            label: "Верхний отступ"
            labelWidth: 210
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: wdPad; width: 58; height: 30; value: Config.weatherDailyTopPadding; minimum: 0; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyTopPadding"; settingsObject: settings; saveOnEdit: true }
                        }
                        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 24; spacing: 8
                            Item { width: 210; height: 24 }
                            Text { width: 58; y: 4; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            Text { width: 58; y: 4; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        SettingsRow {
            label: "День"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: wdDayYTable; width: 58; height: 30; value: Config.weatherDailyDayY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyDayY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: wdDaySizeTable; width: 58; height: 30; value: Config.weatherDailyDayFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyDayFontSize"; settingsObject: settings; saveOnEdit: true }
                        }
                        SettingsRow {
            label: "Иконка"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: wdIconYTable; width: 58; height: 30; value: Config.weatherDailyIconY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyIconY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: wdIconSizeTable; width: 58; height: 30; value: Config.weatherDailyIconWidth; minimum: 16; maximum: 90; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyIconWidth"; settingsObject: settings; saveOnEdit: true }
                        }
                        Row { visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 24; spacing: 8
                            Item { width: 210; height: 24 }
                            Text { width: 58; y: 4; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            Text { width: 58; y: 4; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            Text { width: 58; y: 4; text: "Шрифт"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        SettingsRow {
            label: "Дневная температура"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: wdHX; width: 58; height: 30; value: Config.weatherDailyHighTempX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherDailyHighTempX"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: wdHY; width: 58; height: 30; value: Config.weatherDailyHighTempY; minimum: 0; maximum: 150; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyHighTempY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: wdHF; width: 58; height: 30; value: Config.weatherDailyHighTempFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyHighTempFontSize"; settingsObject: settings; saveOnEdit: true }
                        }
                        SettingsRow {
            label: "Ночная температура"
            labelWidth: 210
            controlSpacing: 8
 visible: host.currentPageId === "weather" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8

                            SettingsNumberField { id: wdLX; width: 58; height: 30; value: Config.weatherDailyLowTempX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherDailyLowTempX"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: wdLY; width: 58; height: 30; value: Config.weatherDailyLowTempY; minimum: 0; maximum: 180; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyLowTempY"; settingsObject: settings; saveOnEdit: true }
                            SettingsNumberField { id: wdLF; width: 58; height: 30; value: Config.weatherDailyLowTempFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyLowTempFontSize"; settingsObject: settings; saveOnEdit: true }
                        }
    }
}
