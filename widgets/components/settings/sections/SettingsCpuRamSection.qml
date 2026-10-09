import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 5
    width: parent ? parent.width : 0
    spacing: 10

    Text {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        text: "CPU и RAM"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    Text {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        text: "Настройки полос CPU и RAM"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Интервал обновления CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
            id: cpuSettingsIntervalField
            value: Config.cpuUpdateInterval
            minimum: 200
            maximum: 10000
            step: 100
            wheelStep: 100
            labelWidth: 0
            fieldWidth: 100
            compact: true
            targetObject: Config
            targetProperty: "cpuUpdateInterval"
            settingsObject: settings
            saveOnEdit: true
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Направление заполнения полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: cpuBarDirectionCombo
            width: 170
            height: 30
            model: ["Слева направо", "Справа налево", "Сверху вниз", "Снизу вверх"]
            currentIndex: ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"].indexOf(Config.cpuBarDirection) >= 0 ? ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"].indexOf(Config.cpuBarDirection) : 0
            onItemChosen: index => {
                Config.cpuBarDirection = ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"][index]
                settings.save()
            }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Толщина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuBarThicknessField
    width: 100
    height: 30
    value: Config.cpuBarThickness
    minimum: 1
    maximum: 30
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuBarThickness"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Ширина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuBarWidthField
    width: 100
    height: 30
    value: Config.cpuBarWidth
    minimum: 40
    maximum: 1000
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuBarWidth"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuRowHeightField
    width: 100
    height: 30
    value: Config.cpuRowHeight
    minimum: 10
    maximum: 60
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuRowHeight"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuRowSpacingField
    width: 100
    height: 30
    value: Config.cpuRowSpacing
    minimum: 0
    maximum: 30
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuRowSpacing"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Отступ подписи слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuLabelPaddingField
    width: 100
    height: 30
    value: Config.cpuLabelLeftPadding
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
    targetProperty: "cpuLabelLeftPadding"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Смещение полос слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuBarOffsetField
    width: 100
    height: 30
    value: Config.cpuBarLeftOffset
    minimum: 0
    maximum: 200
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuBarLeftOffset"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Радиус полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuBarRadiusField
    width: 100
    height: 30
    value: Config.cpuBarRadius
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
    targetProperty: "cpuBarRadius"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Text { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; text: "График CPU"; color: Config.accent; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12) }

    Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Режим графика CPU"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: cpuGraphModeCombo
            width: 130
            height: 30
            model: ["Обе половины", "Только верхние", "Только нижние"]
            currentIndex: ["both", "top", "bottom"].indexOf(Config.cpuGraphMode) >= 0 ? ["both", "top", "bottom"].indexOf(Config.cpuGraphMode) : 0
            onItemChosen: index => {
                Config.cpuGraphMode = ["both", "top", "bottom"][index]
                settings.save()
            }
        }
    }

    Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Ширина сегмента графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuGraphSlotField
    width: 100
    height: 30
    value: Config.cpuGraphSegmentSlotWidth
    minimum: 1
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuGraphSegmentSlotWidth"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Толщина полос графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: cpuGraphBarWidthField
    width: 100
    height: 30
    value: Config.cpuGraphBarWidth
    minimum: 1
    maximum: 10
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "cpuGraphBarWidth"
    settingsObject: root.settings
    saveOnEdit: true
}
    }



    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1
        width: parent.width; height: 30; spacing: 8
        SettingsCheckBox {
            width: 210; height: 30; text: "Показывать RAM"; checked: Config.cpuShowRam
            onToggled: { Config.cpuShowRam=checked; settings.save() }
           
        }
    }

}
