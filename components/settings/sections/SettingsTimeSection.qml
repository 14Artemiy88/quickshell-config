import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Item {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "time"
    width: parent ? parent.width : 0
    height: visible ? clockColumn.implicitHeight : 0
    implicitHeight: clockColumn.implicitHeight

    Column {
        id: clockColumn
        width: parent.width
        spacing: 10

        SettingsGroup {
            visible: host && host.currentPageId === "time"
            width: parent.width
            showFrame: true
            heading: "Время и дата"
            changeKeys: ({ keys: ["clockFont", "clockDateFont", "clockFontSize", "clockDateFontSize"] })
            padding: 8
            contentSpacing: 6

            SettingsDescription {
                width: parent.width
                text: "Пустое поле шрифта использует общий LED-шрифт из раздела «Общие». Время и дата используют общий шрифт, но имеют независимые размеры."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
                wrapMode: Text.WordWrap
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Шрифт времени и даты"
                SettingsFontField {
                    width: parent.width
                    height: 30
                    compact: true
                    fieldWidth: 160
                    fieldFontSize: 11
                    value: Config.clockFont
                    placeholderText: "Общий LED-шрифт"
                    resetTooltip: "Использовать общий LED-шрифт"
                    targetObject: Config
                    targetProperty: "clockFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-font"
                    settingsSearchLabel: "Шрифт времени и даты"
                    settingsSearchKeywords: "часы дата led типографика font clock date"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Шрифт даты"
                SettingsFontField {
                    width: parent.width
                    height: 30
                    compact: true
                    fieldWidth: 160
                    fieldFontSize: 11
                    value: Config.clockDateFont
                    placeholderText: "Как у времени"
                    resetTooltip: "Использовать шрифт времени"
                    targetObject: Config
                    targetProperty: "clockDateFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-date-font"
                    settingsSearchLabel: "Шрифт даты"
                    settingsSearchKeywords: "часы отдельный шрифт даты дата clock date font"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Размер времени"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockFontSize
                    minimum: 24
                    maximum: 72
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockFontSize"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-time-size"
                    settingsSearchLabel: "Размер времени"
                    settingsSearchKeywords: "часы размер цифры time clock font size"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Размер даты"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockDateFontSize
                    minimum: 12
                    maximum: 36
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockDateFontSize"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-date-size"
                    settingsSearchLabel: "Размер даты"
                    settingsSearchKeywords: "дата размер число date font size"
                }
            }
        }

        SettingsGroup {
            visible: host && host.currentPageId === "time"
            width: parent.width
            showFrame: true
            heading: "День недели"
            changeKeys: ({ keys: ["clockWeekdayFont", "clockWeekdayFontSize"] })
            padding: 8
            contentSpacing: 6

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Шрифт дня недели"
                SettingsFontField {
                    width: parent.width
                    height: 30
                    compact: true
                    fieldWidth: 160
                    fieldFontSize: 11
                    value: Config.clockWeekdayFont
                    placeholderText: "Ubuntu"
                    targetObject: Config
                    targetProperty: "clockWeekdayFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-weekday-font"
                    settingsSearchLabel: "Шрифт дня недели"
                    settingsSearchKeywords: "день недели weekday font типографика"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Размер дня недели"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockWeekdayFontSize
                    minimum: 8
                    maximum: 24
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockWeekdayFontSize"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-weekday-size"
                    settingsSearchLabel: "Размер дня недели"
                    settingsSearchKeywords: "день недели размер weekday font size"
                }
            }
        }

        SettingsGroup {
            visible: host && host.currentPageId === "time"
            width: parent.width
            showFrame: true
            heading: "Цвета текста"
            changeKeys: ({ keys: ["clockTimeColor", "clockDateColor", "clockWeekdayColor"] })
            padding: 8
            contentSpacing: 6

            SettingsDescription {
                width: parent.width
                text: "Если цвет не переопределён, используется основной цвет текста активной темы."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
                wrapMode: Text.WordWrap
            }

            SettingsColorField {
                width: parent.width
                label: "Цвет времени"
                value: String(Config.clockTimeColor || Config.text)
                targetObject: Config
                targetProperty: "clockTimeColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: false
                allowTransparent: false
                labelWidth: 210
                fieldWidth: 120
                settingsSearchId: "clock-time-color"
                settingsSearchLabel: "Цвет времени"
                settingsSearchKeywords: "часы цифры основной цвет текста clock time color"
            }

            SettingsColorField {
                width: parent.width
                label: "Цвет даты"
                value: String(Config.clockDateColor || Config.text)
                targetObject: Config
                targetProperty: "clockDateColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: false
                allowTransparent: false
                labelWidth: 210
                fieldWidth: 120
                settingsSearchId: "clock-date-color"
                settingsSearchLabel: "Цвет даты"
                settingsSearchKeywords: "дата цвет date color"
            }

            SettingsColorField {
                width: parent.width
                label: "Цвет дня недели"
                value: String(Config.clockWeekdayColor || Config.text)
                targetObject: Config
                targetProperty: "clockWeekdayColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: false
                allowTransparent: false
                labelWidth: 210
                fieldWidth: 120
                settingsSearchId: "clock-weekday-color"
                settingsSearchLabel: "Цвет дня недели"
                settingsSearchKeywords: "день недели цвет weekday color"
            }
        }

        SettingsGroup {
            visible: host && host.currentPageId === "time"
            width: parent.width
            showFrame: true
            heading: "Отступы и интервалы"
            changeKeys: ({ keys: ["clockPaddingX", "clockPaddingY", "clockColumnSpacing", "clockDetailsRightPadding"] })
            padding: 8
            contentSpacing: 6

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Горизонтальный отступ"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockPaddingX
                    minimum: 0
                    maximum: 24
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockPaddingX"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-padding-x"
                    settingsSearchLabel: "Горизонтальный отступ часов"
                    settingsSearchKeywords: "часы отступ слева справа горизонтальный padding x"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Вертикальный отступ"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockPaddingY
                    minimum: 0
                    maximum: 18
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockPaddingY"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-padding-y"
                    settingsSearchLabel: "Вертикальный отступ часов"
                    settingsSearchKeywords: "часы отступ сверху снизу вертикальный padding y"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Расстояние между блоками"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockColumnSpacing
                    minimum: 0
                    maximum: 24
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockColumnSpacing"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-column-spacing"
                    settingsSearchLabel: "Расстояние между временем и датой"
                    settingsSearchKeywords: "часы расстояние между колонками блоками gap spacing"
                }
            }

            SettingsRow {
                width: parent.width
                height: 34
                spacing: 8
                labelWidth: 210
                label: "Отступ даты справа"
                SettingsNumberField {
                    width: 90
                    height: 30
                    value: Config.clockDetailsRightPadding
                    minimum: 0
                    maximum: 24
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 90
                    fieldFontSize: 11
                    targetObject: Config
                    targetProperty: "clockDetailsRightPadding"
                    settingsObject: root.settings
                    saveOnEdit: true
                    settingsSearchId: "clock-details-right-padding"
                    settingsSearchLabel: "Отступ даты справа"
                    settingsSearchKeywords: "часы дата справа отступ right padding"
                }
            }
        }
    }
}
