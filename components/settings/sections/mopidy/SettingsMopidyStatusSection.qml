import QtQuick
import QtQuick.Controls
import "../../primitives"
import "../../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    visible: host && host.currentPageId === "mopidy" && host.currentPageSubTabIndex === 3

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyEmptyQueueText", "mopidyStatusFont", "mopidyStatusFontSize", "mopidyStatusLongFontSize", "mopidyStatusWidth", "mopidyUnavailableText"] })
        padding: 8
        contentSpacing: 6

            Text {
                text: "Пустая очередь / недоступен"
                color: Config.settingsSubheading
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(11)
            }

            SettingsRow {
                label: "Текст «Очередь пуста»"
                controlSpacing: 8
                width: parent.width
                height: 34
                spacing: 8

                SettingsTextField {
                    id: mopidyEmptyQueueTextField
                    width: 180; height: 30; text: Config.mopidyEmptyQueueText; color: Config.text; activeFocusOnTab: true
                    font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11)
                    background: Rectangle { color: "transparent"; border.color: (mopidyEmptyQueueTextField.activeFocus || mopidyEmptyQueueTextField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || mopidyEmptyQueueTextField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
                    onEditingFinished: { Config.mopidyEmptyQueueText = text; settings.save() }
                    Connections { target: Config; function onMopidyEmptyQueueTextChanged() { mopidyEmptyQueueTextField.text = Config.mopidyEmptyQueueText } }
                }
            }

            SettingsRow {
                label: "Текст «Недоступен»"
                controlSpacing: 8
                width: parent.width
                height: 34
                spacing: 8

                SettingsTextField {
                    id: mopidyUnavailableTextField
                    width: 180; height: 30; text: Config.mopidyUnavailableText; color: Config.text; activeFocusOnTab: true
                    font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11)
                    background: Rectangle { color: "transparent"; border.color: (mopidyUnavailableTextField.activeFocus || mopidyUnavailableTextField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || mopidyUnavailableTextField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
                    onEditingFinished: { Config.mopidyUnavailableText = text; settings.save() }
                    Connections { target: Config; function onMopidyUnavailableTextChanged() { mopidyUnavailableTextField.text = Config.mopidyUnavailableText } }
                }
            }

            SettingsRow {

                label: "Шрифт текста"
                controlSpacing: 8
                width: parent.width; height: 30; spacing: 8

                SettingsFontField {
                    width: 218
                    height: 30
                    compact: true
                    fieldWidth: 180
                    fieldFontSize: 11
                    value: Config.mopidyStatusFont
                    targetObject: Config
                    targetProperty: "mopidyStatusFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
            }

            SettingsRow {

                label: "Размер текста"
                controlSpacing: 8
                width: parent.width; height: 30; spacing: 8

                SettingsNumberField { width: 72; height: 30; value: Config.mopidyStatusFontSize; minimum: 8; maximum: 100; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStatusFontSize"; settingsObject: root.settings; saveOnEdit: true }
            }

            SettingsRow {

                label: "Размер длинного текста"
                controlSpacing: 8
                width: parent.width; height: 30; spacing: 8

                SettingsNumberField { width: 72; height: 30; value: Config.mopidyStatusLongFontSize; minimum: 6; maximum: 100; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStatusLongFontSize"; settingsObject: root.settings; saveOnEdit: true }
            }

            SettingsRow {

                label: "Ширина текста"
                controlSpacing: 8
                width: parent.width; height: 30; spacing: 8

                SettingsNumberField { width: 72; height: 30; value: Config.mopidyStatusWidth; minimum: 80; maximum: 600; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStatusWidth"; settingsObject: root.settings; saveOnEdit: true }
            }
    }
}
