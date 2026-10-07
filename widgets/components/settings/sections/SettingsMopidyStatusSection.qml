import QtQuick
import QtQuick.Controls
import "../primitives"
import "../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    visible: host && host.currentOtherTab === 10 && host.currentOtherSubTab === 3

    Text {
        text: "Пустая очередь / недоступен"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
    }

    Row {
        width: parent.width
        height: 34
        spacing: 8
        Text { width: 180; text: "Текст «Очередь пуста»"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: mopidyEmptyQueueTextField
            width: 180; height: 30; text: Config.mopidyEmptyQueueText; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (mopidyEmptyQueueTextField.activeFocus || mopidyEmptyQueueTextField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyEmptyQueueText = text; settings.save() }
            Connections { target: Config; function onMopidyEmptyQueueTextChanged() { mopidyEmptyQueueTextField.text = Config.mopidyEmptyQueueText } }
        }
    }

    Row {
        width: parent.width
        height: 34
        spacing: 8
        Text { width: 180; text: "Текст «Недоступен»"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: mopidyUnavailableTextField
            width: 180; height: 30; text: Config.mopidyUnavailableText; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (mopidyUnavailableTextField.activeFocus || mopidyUnavailableTextField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyUnavailableText = text; settings.save() }
            Connections { target: Config; function onMopidyUnavailableTextChanged() { mopidyUnavailableTextField.text = Config.mopidyUnavailableText } }
        }
    }

    Row { width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Шрифт текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: mopidyStatusFontField
            width: 180; height: 30; text: Config.mopidyStatusFont; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (mopidyStatusFontField.activeFocus || mopidyStatusFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { var v = text.trim(); if (v.length > 0) Config.mopidyStatusFont = v; text = Config.mopidyStatusFont; settings.save() }
            Connections { target: Config; function onMopidyStatusFontChanged() { mopidyStatusFontField.text = Config.mopidyStatusFont } }
        }
    }

    Row { width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Размер текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyStatusFontSize; minimum: 8; maximum: 100; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStatusFontSize"; settingsObject: root.settings; saveOnEdit: true }
    }

    Row { width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Размер длинного текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyStatusLongFontSize; minimum: 6; maximum: 100; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStatusLongFontSize"; settingsObject: root.settings; saveOnEdit: true }
    }

    Row { width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Ширина текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyStatusWidth; minimum: 80; maximum: 600; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStatusWidth"; settingsObject: root.settings; saveOnEdit: true }
    }
}
