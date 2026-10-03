import QtQuick
import QtQuick.Controls
import "../.."

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
    SettingsTextField {
        id: generalFontSizeField
        width: 100; height: 30
        text: String(Config.fontSize)
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
        horizontalAlignment: Text.AlignHCenter
        activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle { color: Config.settingsBackground; border.color: (generalFontSizeField.activeFocus || generalFontSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) {
            var n = Number(v)
            if (!isFinite(n)) n = Config.fontSize
            n = Math.max(6, Math.min(32, Math.round(n)))
            Config.fontSize = n
            text = String(n)
            settings.save()
        }
        onEditingFinished: applyValue(text)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { generalFontSizeField.applyValue(Config.fontSize + host.wheelDelta(wheel, 1)); wheel.accepted = true } }
        Connections { target: Config; function onFontSizeChanged() { generalFontSizeField.text = String(Config.fontSize) } }
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
        contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width + 5; verticalAlignment: Text.AlignVCenter }
    }
    Text { text: Config.animationsEnabled ? "включены" : "выключены"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter }
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Скорость анимаций (×)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField {
        id: animationSpeedField
        width: 100; height: 30
        text: Number(Config.animationSpeed).toFixed(2)
        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
        background: Rectangle { color: Config.settingsBackground; border.color: (animationSpeedField.activeFocus || animationSpeedField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n = Number(v); if (!isFinite(n)) n = Config.animationSpeed; n = Math.max(0.25, Math.min(4, Math.round(n * 4) / 4)); Config.animationSpeed = n; text = Number(n).toFixed(2); settings.save() }
        onEditingFinished: applyValue(text)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { animationSpeedField.applyValue(Number(Config.animationSpeed) + host.wheelDelta(wheel, 0.25)); wheel.accepted = true } }
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
                text: "Появление"
                checked: Config.animationAppearanceEnabled
                onToggled: {
                    Config.animationAppearanceEnabled = checked
                    settings.save()
                }
                contentItem: Text {
                    text: parent.text
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    leftPadding: parent.indicator.width + 4
                    verticalAlignment: Text.AlignVCenter
                }
            }
            SettingsCheckBox {
                id: animationMovementBox
                text: "Движение"
                checked: Config.animationMovementEnabled
                onToggled: {
                    Config.animationMovementEnabled = checked
                    settings.save()
                }
                contentItem: Text {
                    text: parent.text
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    leftPadding: parent.indicator.width + 4
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        Row {
            spacing: 12
            SettingsCheckBox {
                id: animationSizeBox
                text: "Размер"
                checked: Config.animationSizeEnabled
                onToggled: {
                    Config.animationSizeEnabled = checked
                    settings.save()
                }
                contentItem: Text {
                    text: parent.text
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    leftPadding: parent.indicator.width + 4
                    verticalAlignment: Text.AlignVCenter
                }
            }
            SettingsCheckBox {
                id: animationExpansionBox
                text: "Раскрытие"
                checked: Config.animationExpansionEnabled
                onToggled: {
                    Config.animationExpansionEnabled = checked
                    settings.save()
                }
                contentItem: Text {
                    text: parent.text
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    leftPadding: parent.indicator.width + 4
                    verticalAlignment: Text.AlignVCenter
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
    SettingsTextField {
        id: animationCalendarSlideField
        width: 100; height: 30
        text: String(Config.animationCalendarSlideDuration)
        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle { color: Config.settingsBackground; border.color: (animationCalendarSlideField.activeFocus || animationCalendarSlideField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.animationCalendarSlideDuration; n=Math.max(0,Math.min(5000,Math.round(n))); Config.animationCalendarSlideDuration=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ animationCalendarSlideField.applyValue(Config.animationCalendarSlideDuration+host.wheelDelta(wheel, 50)); wheel.accepted=true } }
        Connections { target: Config; function onAnimationCalendarSlideDurationChanged() { animationCalendarSlideField.text=String(Config.animationCalendarSlideDuration) } }
    }
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Календарь: исчезновение (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField {
        id: animationCalendarFadeField
        width: 100; height: 30
        text: String(Config.animationCalendarFadeDuration)
        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle { color: Config.settingsBackground; border.color: (animationCalendarFadeField.activeFocus || animationCalendarFadeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.animationCalendarFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n))); Config.animationCalendarFadeDuration=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ animationCalendarFadeField.applyValue(Config.animationCalendarFadeDuration+host.wheelDelta(wheel, 50)); wheel.accepted=true } }
        Connections { target: Config; function onAnimationCalendarFadeDurationChanged() { animationCalendarFadeField.text=String(Config.animationCalendarFadeDuration) } }
    }
}

Row {
    visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 3
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Настройки таймера (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField {
        id: animationTimerOptionsField
        width: 100; height: 30
        text: String(Config.animationTimerOptionsDuration)
        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle { color: Config.settingsBackground; border.color: (animationTimerOptionsField.activeFocus || animationTimerOptionsField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.animationTimerOptionsDuration; n=Math.max(0,Math.min(5000,Math.round(n))); Config.animationTimerOptionsDuration=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ animationTimerOptionsField.applyValue(Config.animationTimerOptionsDuration+host.wheelDelta(wheel, 50)); wheel.accepted=true } }
        Connections { target: Config; function onAnimationTimerOptionsDurationChanged() { animationTimerOptionsField.text=String(Config.animationTimerOptionsDuration) } }
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

    SettingsTextField {
        id: frameBorderWidthField
        width: 100
        height: 30
        text: String(Config.frameBorderWidth)
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        horizontalAlignment: Text.AlignHCenter
        activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle {
            color: Config.settingsBackground
            border.color: (frameBorderWidthField.activeFocus || frameBorderWidthField.pointerHovered) ? Config.accent : Config.baseColor
            border.width: 1
            radius: 4
        }
        function applyValue() {
            var n = Number(text)
            if (!isFinite(n)) { text = String(Config.frameBorderWidth); return }
            n = Math.max(0, Math.min(20, Math.round(n)))
            Config.frameBorderWidth = n
            text = String(n)
            settings.save()
        }
        onEditingFinished: applyValue()
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                var n = Math.max(0, Math.min(20, Number(Config.frameBorderWidth) + host.wheelDelta(wheel, 1)))
                Config.frameBorderWidth = n
                frameBorderWidthField.text = String(n)
                settings.save()
                wheel.accepted = true
            }
        }
        Connections {
            target: Config
            function onFrameBorderWidthChanged() { frameBorderWidthField.text = String(Config.frameBorderWidth) }
        }
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

    SettingsTextField {
        id: frameRadiusField
        width: 100
        height: 30
        text: String(Config.frameRadius)
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        horizontalAlignment: Text.AlignHCenter
        activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle {
            color: Config.settingsBackground
            border.color: (frameRadiusField.activeFocus || frameRadiusField.pointerHovered) ? Config.accent : Config.baseColor
            border.width: 1
            radius: 4
        }
        function applyValue() {
            var n = Number(text)
            if (!isFinite(n)) { text = String(Config.frameRadius); return }
            n = Math.max(0, Math.min(50, Math.round(n)))
            Config.frameRadius = n
            text = String(n)
            settings.save()
        }
        onEditingFinished: applyValue()
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                var n = Math.max(0, Math.min(50, Number(Config.frameRadius) + host.wheelDelta(wheel, 1)))
                Config.frameRadius = n
                frameRadiusField.text = String(n)
                settings.save()
                wheel.accepted = true
            }
        }
        Connections {
            target: Config
            function onFrameRadiusChanged() { frameRadiusField.text = String(Config.frameRadius) }
        }
    }
}


}
