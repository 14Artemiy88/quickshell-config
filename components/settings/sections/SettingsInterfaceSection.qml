import QtQuick
import "../../.."
import "../primitives"

// General module appearance and typography controls, now routed as a page in
// the Appearance navigation folder. Existing profile keys and reset scope
// remain unchanged.
Column {
    id: root
    property var host: null
    property var settings: Settings

    visible: host && host.currentPageId === "interface"
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
        visible: host && host.currentPageId === "interface"
        settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["font", "fontSize", "ledFont"] })
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentPageId === "interface"
            text: "Шрифты интерфейса"
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 34
            spacing: 8
            labelWidth: 210
            label: "Основной шрифт интерфейса"
            SettingsFontField {
                width: parent.width
                height: 30
                compact: true
                fieldWidth: 160
                fieldFontSize: 11
                value: Config.font
                targetObject: Config
                targetProperty: "font"
                settingsObject: settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 34
            spacing: 8
            labelWidth: 210
            label: "Базовый размер шрифта"
            SettingsNumberField {
                id: generalFontSizeField
                width: 100
                height: 30
                value: Config.fontSize
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
                targetProperty: "fontSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 34
            spacing: 8
            labelWidth: 210
            label: "LED-шрифт"
            SettingsFontField {
                width: parent.width
                height: 30
                compact: true
                fieldWidth: 160
                fieldFontSize: 11
                value: Config.ledFont
                targetObject: Config
                targetProperty: "ledFont"
                settingsObject: settings
                saveOnEdit: true
            }
        }
    }
    SettingsGroup {
        visible: host && host.currentPageId === "interface"
        settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        heading: "Масштаб интерфейса модулей"
        changeKeys: ({ keys: ["uiScale", "fontScale"] })
        padding: 8
        contentSpacing: 6

        SettingsDescription {
            width: parent.width
            text: "Меняет размеры окон модулей и текст, не изменяя сохранённые координаты и индивидуальные размеры шрифтов."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 34
            spacing: 8
            labelWidth: 210
            label: "Масштаб модулей (%)"
            SettingsNumberField {
                width: 100; height: 30
                value: Config.uiScale
                minimum: 75; maximum: 150; step: 5; wheelStep: 5; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "uiScale"
                settingsObject: root.settings; saveOnEdit: true
            }
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 34
            spacing: 8
            labelWidth: 210
            label: "Масштаб шрифтов модулей (%)"
            SettingsNumberField {
                width: 100; height: 30
                value: Config.fontScale
                minimum: 75; maximum: 150; step: 5; wheelStep: 5; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "fontScale"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: host && host.currentPageId === "interface"
        settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["backgroundBlurRadius"] })
        heading: "Размытие фона"
        padding: 8
        contentSpacing: 6

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 30
            spacing: 8
            labelWidth: 210
            label: "Радиус области блюра (0–40)"
            SettingsNumberField {
                id: backgroundBlurRadiusField
                width: 72
                height: 30
                value: Config.backgroundBlurRadius
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 72
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "backgroundBlurRadius"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
        SettingsDescription {
            descriptionConditionVisible: host.currentPageId === "interface"
            width: parent.width
            text: "Для работы блюра требуется поддержка композитора."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: host && host.currentPageId === "interface"
        settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["frameBorderWidth", "frameRadius", "cornerRadiusScale", "buttonBordersEnabled", "inputBordersEnabled", "popupBordersEnabled", "cardBordersEnabled"] })
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentPageId === "interface"
            text: "Общие рамки и скругления"
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 30
            spacing: 8
            labelWidth: 210
            label: "Толщина рамки карточек (0 = выкл.)"
            SettingsNumberField {
                id: frameBorderWidthField
                width: 100
                height: 30
                value: Config.frameBorderWidth
                minimum: 0
                maximum: 20
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "frameBorderWidth"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 30
            spacing: 8
            labelWidth: 210
            label: "Радиус внешних рамок"
            SettingsNumberField {
                id: frameRadiusField
                width: 100
                height: 30
                value: Config.frameRadius
                minimum: 0
                maximum: 50
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "frameRadius"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 30
            spacing: 8
            labelWidth: 210
            label: "Масштаб скруглений (%)"
            SettingsNumberField {
                id: cornerRadiusScaleField
                width: 100
                height: 30
                value: Config.cornerRadiusScale
                minimum: 50
                maximum: 150
                step: 5
                wheelStep: 5
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "cornerRadiusScale"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsDescription {
            width: parent.width
            text: "100% сохраняет текущие пропорции скруглений. Изменение масштаба применяется к существующим радиусам, не выравнивая мелкие элементы и внешние рамки в один размер."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }

        Row {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 30
            spacing: 12
            SettingsCheckBox {
                width: (parent.width - parent.spacing) / 2
                height: 30
                text: "Рамки кнопок"
                checked: Config.buttonBordersEnabled
                settingsSearchId: "general.button-borders"
                settingsSearchLabel: "Рамки кнопок"
                settingsSearchKeywords: "оформление границы border buttons"
                onToggled: { Config.buttonBordersEnabled = checked; root.settings.save() }
            }
            SettingsCheckBox {
                width: (parent.width - parent.spacing) / 2
                height: 30
                text: "Рамки полей ввода"
                checked: Config.inputBordersEnabled
                settingsSearchId: "general.input-borders"
                settingsSearchLabel: "Рамки полей ввода"
                settingsSearchKeywords: "оформление границы input fields checkbox combobox"
                onToggled: { Config.inputBordersEnabled = checked; root.settings.save() }
            }
        }

        Row {
            visible: host.currentPageId === "interface"
            width: parent.width
            height: 30
            spacing: 12
            SettingsCheckBox {
                width: (parent.width - parent.spacing) / 2
                height: 30
                text: "Рамки всплывающих окон"
                checked: Config.popupBordersEnabled
                settingsSearchId: "general.popup-borders"
                settingsSearchLabel: "Рамки всплывающих окон"
                settingsSearchKeywords: "оформление границы popup dropdown menu"
                onToggled: { Config.popupBordersEnabled = checked; root.settings.save() }
            }
            SettingsCheckBox {
                width: (parent.width - parent.spacing) / 2
                height: 30
                text: "Рамки карточек"
                checked: Config.cardBordersEnabled
                settingsSearchId: "general.card-borders"
                settingsSearchLabel: "Рамки карточек"
                settingsSearchKeywords: "оформление границы cards widgets surfaces"
                onToggled: { Config.cardBordersEnabled = checked; root.settings.save() }
            }
        }
    }

}
