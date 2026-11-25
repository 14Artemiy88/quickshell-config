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
            changeKeys: ({ keys: ["clockFont", "clockFontSize", "clockDateFontSize"] })
            padding: 8
            contentSpacing: 6

            Text {
                width: parent.width
                text: "Пустое поле шрифта использует общий LED-шрифт из раздела «Общие». Размеры времени и даты регулируются отдельно."
                color: Config.textMuted
                font.family: Config.settingsFont
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
    }
}
