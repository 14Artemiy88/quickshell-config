import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 0
    width: parent ? parent.width : 0
    spacing: 10

Text {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
    text: "Общие"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}

Text {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
    text: "Основной шрифт интерфейса, LED-шрифт и общие параметры"
    color: Config.textMuted
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(10)
    wrapMode: Text.WordWrap
    width: parent.width
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
    width: parent.width
    height: 34
    spacing: 8
    Text { width: 210; text: "Основной шрифт интерфейса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField {
        id: generalFontField
        width: 160; height: 30
        text: Config.font
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
        activeFocusOnTab: true
        background: Rectangle { color: Config.settingsBackground; border.color: (generalFontField.activeFocus || generalFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        onEditingFinished: { Config.font = text.trim() || Config.font; text = Config.font; settings.save() }
        Connections { target: Config; function onFontChanged() { generalFontField.text = Config.font } }
    }
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
    width: parent.width
    height: 34
    spacing: 8
    Text { width: 210; text: "Размер шрифта интерфейса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
    width: parent.width
    height: 34
    spacing: 8
    Text { width: 210; text: "LED-шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField {
        id: ledFontField
        width: 160; height: 30
        text: Config.ledFont
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
        activeFocusOnTab: true
        background: Rectangle { color: Config.settingsBackground; border.color: (ledFontField.activeFocus || ledFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        onEditingFinished: { Config.ledFont = text.trim() || Config.ledFont; text = Config.ledFont; settings.save() }
        Connections { target: Config; function onLedFontChanged() { ledFontField.text = Config.ledFont } }
    }
}

Text {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    text: "Анимации"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    SettingsCheckBox {
        id: animationsEnabledBox
        width: 210; height: 30
        text: "Анимации"
        checked: Config.animationsEnabled
        onToggled: { Config.animationsEnabled = checked; settings.save() }
       
    }
    Text { text: Config.animationsEnabled ? "включены" : "выключены"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter }
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Скорость анимаций (×)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: animationSpeedField
    width: 100
    height: 30
    value: Config.animationSpeed
    minimum: 0.25
    maximum: 4
    step: 0.25
    wheelStep: 0.25
    decimals: 2
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "animationSpeed"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Сглаживание"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsComboBox {
        id: animationEasingBox
        width: 180; height: 30
        model: ["Linear", "InOutQuad", "OutQuad", "InOutCubic", "InCubic", "OutCubic", "OutBack", "InOutBack"]
        currentIndex: Math.max(0, model.indexOf(Config.animationEasing))
        onActivated: { Config.animationEasing = currentText; settings.save() }
        background: Rectangle { color: Config.settingsBackground; border.color: (animationEasingBox.activeFocus || animationEasingBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        contentItem: Text { text: animationEasingBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
    }
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 60
    spacing: 8
    Column {
        width: 210; spacing: 3
        Text { text: "Типы анимаций"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11) }
        Text { text: "Можно отключить отдельные категории"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9) }
    }
    Column {
        spacing: 2
        Row {
            spacing: 12
            SettingsCheckBox {
                id: animationAppearanceBox
                labelFontSize: 10
                labelLeftPadding: 4
                text: "Появление"
                checked: Config.animationAppearanceEnabled
                onToggled: {
                    Config.animationAppearanceEnabled = checked
                    settings.save()
                }
            }
            SettingsCheckBox {
                id: animationMovementBox
                labelFontSize: 10
                labelLeftPadding: 4
                text: "Движение"
                checked: Config.animationMovementEnabled
                onToggled: {
                    Config.animationMovementEnabled = checked
                    settings.save()
                }
            }
        }
        Row {
            spacing: 12
            SettingsCheckBox {
                id: animationSizeBox
                labelFontSize: 10
                labelLeftPadding: 4
                text: "Размер"
                checked: Config.animationSizeEnabled
                onToggled: {
                    Config.animationSizeEnabled = checked
                    settings.save()
                }
            }
            SettingsCheckBox {
                id: animationExpansionBox
                labelFontSize: 10
                labelLeftPadding: 4
                text: "Раскрытие"
                checked: Config.animationExpansionEnabled
                onToggled: {
                    Config.animationExpansionEnabled = checked
                    settings.save()
                }
            }
        }
    }
}

Text {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    text: "Единая скорость и длительности встроенных анимаций. 0 мс отключает конкретную анимацию."
    color: Config.textMuted
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(10)
    wrapMode: Text.WordWrap
    width: parent.width
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Календарь: раскрытие (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: animationCalendarSlideField
    width: 100
    height: 30
    value: Config.animationCalendarSlideDuration
    minimum: 0
    maximum: 5000
    step: 50
    wheelStep: 50
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "animationCalendarSlideDuration"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Календарь: исчезновение (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: animationCalendarFadeField
    width: 100
    height: 30
    value: Config.animationCalendarFadeDuration
    minimum: 0
    maximum: 5000
    step: 50
    wheelStep: 50
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "animationCalendarFadeDuration"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Настройки таймера (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: animationTimerOptionsField
    width: 100
    height: 30
    value: Config.animationTimerOptionsDuration
    minimum: 0
    maximum: 5000
    step: 50
    wheelStep: 50
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "animationTimerOptionsDuration"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Text {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1
    text: "Рамки"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}

Text {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1
    text: "Общие рамки виджетов. Толщина 0 полностью отключает рамку."
    color: Config.textMuted
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(10)
    wrapMode: Text.WordWrap
    width: parent.width
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Толщина рамки (0 = выкл.)"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

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

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Радиус скругления рамки"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

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


}
