import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 4
    width: parent ? parent.width : 0
    spacing: 10

Text {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    text: "CAVA"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}

Row {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Режим CAVA"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

        SettingsComboBox {
        id: cavaModeCombo
        width: 100
        height: 30
        model: ["Обе половины", "Только верхние", "Только нижние"]
        currentIndex: ["both", "top", "bottom"].indexOf(Config.cavaMode) >= 0 ? ["both", "top", "bottom"].indexOf(Config.cavaMode) : 0
        onItemChosen: index => {
            Config.cavaMode = ["both", "top", "bottom"][index]
            settings.save()
        }
    }

}

Row {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Количество полос CAVA"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

    SettingsNumberField {
    id: cavaBarsField
    width: 100
    height: 30
    value: Config.cavaBars
    minimum: 8
    maximum: 120
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cavaBars"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Row {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Частота обновления CAVA (FPS)"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

    SettingsNumberField {
    id: cavaFramerateField
    width: 100
    height: 30
    value: Config.cavaFramerate
    minimum: 1
    maximum: 120
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cavaFramerate"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Row { visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Зазор между слотами CAVA"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: cavaRowSpacingField
    width: 100
    height: 30
    value: Config.cavaRowSpacing
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
    targetProperty: "cavaRowSpacing"
    settingsObject: root.settings
    saveOnEdit: true
}
}
Row { visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Ширина полоски (% слота)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: cavaBarWidthRatioField
    width: 100
    height: 30
    value: Config.cavaBarWidthRatio
    minimum: 0.05
    maximum: 1
    step: 0.05
    wheelStep: 0.05
    decimals: 2
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "cavaBarWidthRatio"
    settingsObject: root.settings
    saveOnEdit: true
}
}
}
