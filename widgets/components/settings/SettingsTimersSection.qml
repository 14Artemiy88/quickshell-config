import QtQuick
import QtQuick.Controls
import "../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    Text {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 0
        text: "Таймеры"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    Text {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 0
        text: "Дефолтные значения кнопок таймера, в минутах"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }

    Column {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 0
        width: parent.width
        spacing: 5

        Repeater {
            model: (root.settings.timerPresetDefaults || []).length
            delegate: Row {
                id: timerPresetRow
                width: parent.width
                height: 30
                spacing: 6

                Text {
                    width: 75
                    height: 28
                    text: "Кнопка " + (index + 1)
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                }

                SettingsTextField {
                    id: timerPresetField
                    width: 100
                    height: 30
                    property int presetIndex: index
                    text: String(Settings.timerPresetDefaults[presetIndex] === undefined ? 5 : Settings.timerPresetDefaults[presetIndex])
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    horizontalAlignment: Text.AlignHCenter
                    activeFocusOnTab: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    placeholderText: "мин"
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (timerPresetField.activeFocus || timerPresetField.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }

                    function applyValue() {
                        var n = Number(text)
                        var values = Settings.timerPresetDefaults || []
                        if (!isFinite(n) || presetIndex < 0 || presetIndex >= values.length) {
                            text = String(values[presetIndex] === undefined ? 5 : values[presetIndex])
                            return
                        }
                        n = Math.max(0, Math.round(n))
                        Settings.setTimerPresetDefault(presetIndex, n)
                        text = String(n)
                    }

                    onEditingFinished: applyValue()

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                                onWheel: function(wheel) {
                            Settings.adjustTimerPresetDefault(timerPresetField.presetIndex, (wheel.angleDelta.y > 0 ? 1 : -1) * ((wheel.modifiers & Qt.ShiftModifier) ? 10 : 1))
                            timerPresetField.text = String(Settings.timerPresetDefaults[timerPresetField.presetIndex])
                            wheel.accepted = true
                        }
                    }

                    Connections {
                        target: Settings
                        function onTimerPresetsChanged() {
                            if (timerPresetField.presetIndex < (Settings.timerPresetDefaults || []).length)
                                timerPresetField.text = String(Settings.timerPresetDefaults[timerPresetField.presetIndex])
                        }
                    }
                }

                Rectangle {
                    width: 70
                    height: 28
                    radius: 4
                    color: removeArea.containsMouse ? Config.baseColor : Config.settingsBackground
                    border.color: removeArea.containsMouse ? Config.accent : Config.baseColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Удалить"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                    }

                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Settings.removeTimerPreset(index)
                    }
                }
            }
        }

        Rectangle {
            width: 151
            height: 30
            radius: 4
            color: addArea.containsMouse ? Config.accent : Config.settingsBackground
            border.color: Config.accent
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "+ Добавить кнопку"
                color: addArea.containsMouse ? Config.black : Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                font.bold: addArea.containsMouse
            }

            MouseArea {
                id: addArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.settings.addTimerPreset(5)
            }
        }
    }


    Text {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        text: "Таймеры: оформление и поведение"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }

    Text {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        text: "Окно окончания таймера"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        width: parent.width
        height: 30
        spacing: 8
        SettingsCheckBox {
            width: 210
            height: 30
            text: "Показывать изображение"
            checked: Config.timerFinishedImageEnabled
            onToggled: { Config.timerFinishedImageEnabled = checked; root.settings.save() }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Путь к изображению"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField {
            id: timerFinishedImagePathField
            width: 250
            height: 30
            enabled: Config.timerFinishedImageEnabled
            opacity: enabled ? 1 : 0.55
            text: Config.timerFinishedImagePath
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedImagePathField.activeFocus || timerFinishedImagePathField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.timerFinishedImagePath = text.trim(); root.settings.save() }
            Connections { target: Config; function onTimerFinishedImagePathChanged() { timerFinishedImagePathField.text = Config.timerFinishedImagePath } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Ширина изображения"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: timerFinishedImageWidthField
            width: 100
            height: 30
            text: String(Config.timerFinishedImageWidth)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedImageWidthField.activeFocus || timerFinishedImageWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerFinishedImageWidth; n=Math.max(50,Math.min(1200,Math.round(n))); Config.timerFinishedImageWidth=n; text=String(n); root.settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerFinishedImageWidthField.applyValue(Config.timerFinishedImageWidth + root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onTimerFinishedImageWidthChanged() { timerFinishedImageWidthField.text=String(Config.timerFinishedImageWidth) } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Отступ изображения"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField {
            id: timerFinishedImageMarginField
            width: 100
            height: 30
            text: String(Config.timerFinishedImageMargin)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedImageMarginField.activeFocus || timerFinishedImageMarginField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerFinishedImageMargin; n=Math.max(0,Math.min(100,Math.round(n))); Config.timerFinishedImageMargin=n; Config.timerFinishedImageTopMargin=n; Config.timerFinishedImageBottomMargin=n; text=String(n); root.settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerFinishedImageMarginField.applyValue(Config.timerFinishedImageMargin + root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onTimerFinishedImageMarginChanged() { timerFinishedImageMarginField.text=String(Config.timerFinishedImageMargin) } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Цвет заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: timerFinishedTitleColorModeBox
            width: 250; height: 30
            model: ["Цвет таймера", "Свой цвет"]
            currentIndex: Config.timerFinishedTitleUsesTimerColor ? 0 : 1
            contentItem: Text { text: parent.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
            onItemChosen: function(index) { Config.timerFinishedTitleUsesTimerColor = index === 0; root.settings.save() }
            Connections { target: Config; function onTimerFinishedTitleUsesTimerColorChanged() { timerFinishedTitleColorModeBox.currentIndex = Config.timerFinishedTitleUsesTimerColor ? 0 : 1 } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled && !Config.timerFinishedTitleUsesTimerColor
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Свой цвет заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: timerFinishedTitleColorField
            width: 140; height: 30
            text: Config.timerFinishedTitleColor
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedTitleColorField.activeFocus || timerFinishedTitleColorField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { var v=text.trim(); if (/^#[0-9a-fA-F]{6,8}$/.test(v) || v === "transparent") { Config.timerFinishedTitleColor=v; text=v; root.settings.save() } else text=Config.timerFinishedTitleColor }
            Connections { target: Config; function onTimerFinishedTitleColorChanged() { timerFinishedTitleColorField.text=Config.timerFinishedTitleColor } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Размер заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: timerFinishedTitleFontSizeField
            width: 100; height: 30
            text: String(Config.timerFinishedTitleFontSize)
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedTitleFontSizeField.activeFocus || timerFinishedTitleFontSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerFinishedTitleFontSize; n=Math.max(8,Math.min(72,Math.round(n))); Config.timerFinishedTitleFontSize=n; text=String(n); root.settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerFinishedTitleFontSizeField.applyValue(Config.timerFinishedTitleFontSize+root.host.wheelDelta(wheel,1)); wheel.accepted=true } }
            Connections { target: Config; function onTimerFinishedTitleFontSizeChanged(){ timerFinishedTitleFontSizeField.text=String(Config.timerFinishedTitleFontSize) } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Шрифт заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: timerFinishedTitleFontField
            width: 250; height: 30
            text: Config.timerFinishedTitleFont
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedTitleFontField.activeFocus || timerFinishedTitleFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.timerFinishedTitleFont=text.trim() || Config.timerFinishedTitleFont; text=Config.timerFinishedTitleFont; root.settings.save() }
            Connections { target: Config; function onTimerFinishedTitleFontChanged(){ timerFinishedTitleFontField.text=Config.timerFinishedTitleFont } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Расположение заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsComboBox {
            id: timerFinishedTitleAlignmentBox
            width: 250; height: 30
            model: ["Слева", "По центру", "Справа"]
            currentIndex: Config.timerFinishedTitleAlignment
            contentItem: Text { text: parent.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
            onItemChosen: function(index) { Config.timerFinishedTitleAlignment = index; root.settings.save() }
            Connections { target: Config; function onTimerFinishedTitleAlignmentChanged() { timerFinishedTitleAlignmentBox.currentIndex = Config.timerFinishedTitleAlignment } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Цвет рамки окна"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: timerFinishedBorderColorBox
            width: 250
            height: 30
            model: ["Цвет таймера", "Общие рамки"]
            currentIndex: Config.timerFinishedBorderUsesTimerColor ? 0 : 1
            contentItem: Text { text: parent.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
            onItemChosen: function(index) { Config.timerFinishedBorderUsesTimerColor = index === 0; root.settings.save() }
            Connections { target: Config; function onTimerFinishedBorderUsesTimerColorChanged() { timerFinishedBorderColorBox.currentIndex = Config.timerFinishedBorderUsesTimerColor ? 0 : 1 } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Фон окна"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: timerFinishedBackgroundModeBox
            width: 250
            height: 30
            model: ["Свой цвет", "Цвет таймера"]
            currentIndex: Config.timerFinishedBackgroundUsesTimerColor ? 1 : 0
            contentItem: Text { text: parent.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
            onItemChosen: function(index) { Config.timerFinishedBackgroundUsesTimerColor = index === 1; root.settings.save() }
            Connections { target: Config; function onTimerFinishedBackgroundUsesTimerColorChanged() { timerFinishedBackgroundModeBox.currentIndex = Config.timerFinishedBackgroundUsesTimerColor ? 1 : 0 } }
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && !Config.timerFinishedBackgroundUsesTimerColor
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Свой цвет фона"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: timerFinishedBackgroundColorField
            width: 140
            height: 30
            text: Config.timerFinishedBackgroundColor
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (timerFinishedBackgroundColorField.activeFocus || timerFinishedBackgroundColorField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: {
                var v = text.trim()
                if (/^#[0-9a-fA-F]{6,8}$/.test(v) || v === "transparent") { Config.timerFinishedBackgroundColor = v; text = v; root.settings.save() }
                else text = Config.timerFinishedBackgroundColor
            }
            Connections { target: Config; function onTimerFinishedBackgroundColorChanged() { timerFinishedBackgroundColorField.text = Config.timerFinishedBackgroundColor } }
        }
    }

    Text {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 2
        text: "Иконки таймера"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Column {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 2
        width: parent.width
        spacing: 4
        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text { width: 210; text: "Порядок иконок"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
            SettingsComboBox {
                id: timerIconOrderCombo
                width: 140
                height: 30
                model: ["Будильник слева", "Таймер слева"]
                currentIndex: Config.timerIconOrder === "timer-left" ? 1 : 0
                contentItem: Text { text: timerIconOrderCombo.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 10; elide: Text.ElideRight }
                background: Rectangle { color: Config.settingsBackground; border.color: (timerIconOrderCombo.activeFocus || timerIconOrderCombo.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: Config.frameRadius }
                onActivated: {
                    var next = currentIndex === 1 ? "timer-left" : "alarm-left"
                    if (next === Config.timerIconOrder) return
                    var oldTimerX = Config.timerIconX
                    Config.timerIconX = Config.timerAlarmIconX
                    Config.timerAlarmIconX = oldTimerX
                    Config.timerIconOrder = next
                    root.settings.save()
                }
                Connections { target: Config; function onTimerIconOrderChanged() { timerIconOrderCombo.currentIndex = Config.timerIconOrder === "timer-left" ? 1 : 0 } }
            }
        }
        Row {
            width: parent.width
            height: 18
            spacing: 8
            Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField { id: timerIconField; width: 58; height: 30; text: Config.timerIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (timerIconField.activeFocus || timerIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.timerIcon=text; root.settings.save() } Connections { target: Config; function onTimerIconChanged(){ timerIconField.text=Config.timerIcon } } }
            SettingsTextField { id: timerIconSizeField; width: 58; height: 30; text: String(Config.timerIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (timerIconSizeField.activeFocus || timerIconSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.timerIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.timerIconSize=n; text=String(n); root.settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerIconSizeField.applyValue(Config.timerIconSize+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onTimerIconSizeChanged(){ timerIconSizeField.text=String(Config.timerIconSize) } } }
            SettingsTextField { id: timerIconXField; width: 58; height: 30; text: String(Config.timerIconX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (timerIconXField.activeFocus || timerIconXField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.timerIconX; n=Math.max(-100,Math.min(100,Math.round(n))); Config.timerIconX=n; text=String(n); root.settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerIconXField.applyValue(Config.timerIconX+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onTimerIconXChanged(){ timerIconXField.text=String(Config.timerIconX) } } }
            SettingsTextField { id: timerIconYField; width: 58; height: 30; text: String(Config.timerIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (timerIconYField.activeFocus || timerIconYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.timerIconY; n=Math.max(-100,Math.min(100,Math.round(n))); Config.timerIconY=n; text=String(n); root.settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerIconYField.applyValue(Config.timerIconY+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onTimerIconYChanged(){ timerIconYField.text=String(Config.timerIconY) } } }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField { id: timerAlarmIconField; width: 58; height: 30; text: Config.timerAlarmIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (timerAlarmIconField.activeFocus || timerAlarmIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.timerAlarmIcon=text; root.settings.save() } Connections { target: Config; function onTimerAlarmIconChanged(){ timerAlarmIconField.text=Config.timerAlarmIcon } } }
            SettingsTextField { id: timerAlarmIconSizeField; width: 58; height: 30; text: String(Config.timerAlarmIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (timerAlarmIconSizeField.activeFocus || timerAlarmIconSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.timerAlarmIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.timerAlarmIconSize=n; text=String(n); root.settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerAlarmIconSizeField.applyValue(Config.timerAlarmIconSize+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onTimerAlarmIconSizeChanged(){ timerAlarmIconSizeField.text=String(Config.timerAlarmIconSize) } } }
            SettingsTextField { id: timerAlarmIconXField; width: 58; height: 30; text: String(Config.timerAlarmIconX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (timerAlarmIconXField.activeFocus || timerAlarmIconXField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.timerAlarmIconX; n=Math.max(-100,Math.min(100,Math.round(n))); Config.timerAlarmIconX=n; text=String(n); root.settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerAlarmIconXField.applyValue(Config.timerAlarmIconX+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onTimerAlarmIconXChanged(){ timerAlarmIconXField.text=String(Config.timerAlarmIconX) } } }
            SettingsTextField { id: timerAlarmIconYField; width: 58; height: 30; text: String(Config.timerAlarmIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (timerAlarmIconYField.activeFocus || timerAlarmIconYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.timerAlarmIconY; n=Math.max(-100,Math.min(100,Math.round(n))); Config.timerAlarmIconY=n; text=String(n); root.settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerAlarmIconYField.applyValue(Config.timerAlarmIconY+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onTimerAlarmIconYChanged(){ timerAlarmIconYField.text=String(Config.timerAlarmIconY) } } }
        }
    }

    Row { width: parent.width; height: 30; spacing: 8
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        Text { width: 210; text: "Минимальная высота блока таймеров"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField { id: timerMinHeightField; width: 100; height: 30; text: String(Config.timerMinHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerMinHeight; n=Math.max(30,Math.min(1000,Math.round(n / 1) * 1)); Config.timerMinHeight=n; text=String(n); root.settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerMinHeightField.applyValue(Config.timerMinHeight+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        Text { width: 210; text: "Шаг колеса таймера"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField { id: timerWheelStepField; width: 100; height: 30; text: String(Config.timerWheelStep); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerWheelStep; n=Math.max(1,Math.min(60,Math.round(n / 1) * 1)); Config.timerWheelStep=n; text=String(n); root.settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerWheelStepField.applyValue(Config.timerWheelStep+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Комментарий"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField { id: timerCommentWidthField; width: 58; height: 30; text: String(Config.timerCommentWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                                color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentWidth; n=Math.max(40,Math.min(300,Math.round(n / 1) * 1)); Config.timerCommentWidth=n; text=String(n); root.settings.save() }
                                onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerCommentWidthField.applyValue(Config.timerCommentWidth+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
                            }
        SettingsTextField { id: timerCommentMaxLengthField; width: 58; height: 30; text: String(Config.timerCommentMaxLength); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                                color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentMaxLength; n=Math.max(1,Math.min(30,Math.round(n / 1) * 1)); Config.timerCommentMaxLength=n; text=String(n); root.settings.save() }
                                onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerCommentMaxLengthField.applyValue(Config.timerCommentMaxLength+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
                            }
        SettingsTextField { id: timerCommentGapField; width: 58; height: 30; text: String(Config.timerCommentGap); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                                color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentGap; n=Math.max(0,Math.min(40,Math.round(n / 1) * 1)); Config.timerCommentGap=n; text=String(n); root.settings.save() }
                                onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: function(wheel) { timerCommentGapField.applyValue(Config.timerCommentGap+root.host.wheelDelta(wheel, 1)); wheel.accepted=true } }
                            }
    }
    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        width: parent.width
        height: 24
        spacing: 8
        Item { width: 210; height: 24 }
        Text { width: 58; text: "Между"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Text { width: 58; text: "Сверху"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Text { width: 58; text: "Справа"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
}
