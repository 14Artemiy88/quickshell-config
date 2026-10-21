import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    function setTimerIconOrder(nextOrder) {
        if (nextOrder !== "timer-left" && nextOrder !== "alarm-left")
            return
        if (nextOrder === Config.timerIconOrder)
            return

        var oldTimerX = Number(Config.timerIconX)
        var oldAlarmX = Number(Config.timerAlarmIconX)
        if (!isFinite(oldTimerX) || !isFinite(oldAlarmX))
            return

        Config.timerIconX = Math.round(oldAlarmX)
        Config.timerAlarmIconX = Math.round(oldTimerX)
        Config.timerIconOrder = nextOrder
        root.settings.save()
    }

    function moveTimerIconOrder(iconId, delta) {
        var order = Config.timerIconOrder === "timer-left"
            ? ["timer", "alarm"]
            : ["alarm", "timer"]
        var index = order.indexOf(String(iconId))
        var target = index + Number(delta)
        if (index < 0 || target < 0 || target >= order.length)
            return
        var item = order[index]
        order.splice(index, 1)
        order.splice(target, 0, item)
        root.setTimerIconOrder(order[0] === "timer" ? "timer-left" : "alarm-left")
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
                    height: 30
                    text: "Кнопка " + (index + 1)
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                }

                SettingsNumberField {
                    id: timerPresetField
                    width: 100
                    height: 30
                    property int presetIndex: index
                    value: Number(Settings.timerPresetDefaults[presetIndex] === undefined ? 5 : Settings.timerPresetDefaults[presetIndex])
                    minimum: 0
                    maximum: Infinity
                    step: 1
                    wheelStep: 1
                    compact: true
                    fieldWidth: 100
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    valueWriter: function(n) { Settings.setTimerPresetDefault(presetIndex, n) }
                    ToolTip.visible: timerPresetField.pointerHovered
                    ToolTip.text: "Минуты"
                    ToolTip.delay: 500
                }

                SettingsButton {
                    width: 70
                    height: 28
                    text: "Удалить"
                    fontSize: 10
                    radius: 4
                    fillOnHover: true
                    borderOnHover: true
                    backgroundColor: Config.settingsBackground
                    hoverBackgroundColor: Config.baseColor
                    textColor: Config.text
                    hoverTextColor: Config.text
                    onClicked: Settings.removeTimerPreset(index)
                }
            }
        }

        SettingsButton {
            width: 151
            height: 30
            text: "+ Добавить кнопку"
            fontSize: 10
            radius: 4
            fillOnHover: true
            borderOnHover: true
            backgroundColor: Config.settingsBackground
            textColor: Config.text
            onClicked: root.settings.addTimerPreset(5)
        }
    }


    Text {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1
        text: "Таймеры: оформление и поведение"
        color: Config.textMuted
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
        Text { width: 210; height: 30; text: "Путь к изображению"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
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
        Text { width: 210; height: 30; text: "Ширина изображения"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: timerFinishedImageWidthField
    width: 100
    height: 30
    value: Config.timerFinishedImageWidth
    minimum: 50
    maximum: 1200
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerFinishedImageWidth"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; height: 30; text: "Отступ изображения"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsNumberField {
            id: timerFinishedImageMarginField
            width: 100
            height: 30
            value: Config.timerFinishedImageMargin
            minimum: 0
            maximum: 100
            step: 1
            wheelStep: 1
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            valueWriter: function(n) {
                Config.timerFinishedImageMargin = n
            }
            settingsObject: root.settings
            saveOnEdit: true
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; height: 30; text: "Цвет заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
        Text { width: 210; height: 30; text: "Свой цвет заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsColorField {
            id: timerFinishedTitleColorField
            width: 140
            height: 30
            value: Config.timerFinishedTitleColor
            targetObject: Config
            targetProperty: "timerFinishedTitleColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            compact: true
            fieldWidth: 108
            swatchSize: 24
        }
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; height: 30; text: "Размер заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: timerFinishedTitleFontSizeField
    width: 100
    height: 30
    value: Config.timerFinishedTitleFontSize
    minimum: 8
    maximum: 72
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerFinishedTitleFontSize"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 1 && Config.timerFinishedImageEnabled
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; height: 30; text: "Шрифт заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
        Text { width: 210; height: 30; text: "Расположение заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
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
        Text { width: 210; height: 30; text: "Цвет рамки окна"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
        Text { width: 210; height: 30; text: "Фон окна"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
        Text { width: 210; height: 30; text: "Свой цвет фона"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsColorField {
            id: timerFinishedBackgroundColorField
            width: 140
            height: 30
            value: Config.timerFinishedBackgroundColor
            targetObject: Config
            targetProperty: "timerFinishedBackgroundColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            compact: true
            fieldWidth: 108
            swatchSize: 24
        }
    }

    Column {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 2
        width: parent.width
        spacing: 4

        Text {
            width: parent.width
            text: "Иконки таймера и будильника"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Row {
            width: parent.width
            height: 18
            spacing: 6
            Item { width: 110; height: 18 }
            Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        }

        Repeater {
            model: Config.timerIconOrder === "timer-left" ? ["timer", "alarm"] : ["alarm", "timer"]
            delegate: Row {
                width: parent.width
                height: 30
                spacing: 6

                Text {
                    width: 110
                    height: 30
                    text: modelData === "alarm" ? "Будильник" : "Таймер"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                SettingsTextField {
                    id: timerIconValueField
                    width: 58
                    height: 30
                    text: modelData === "timer" ? Config.timerIcon : Config.timerAlarmIcon
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(12)
                    horizontalAlignment: Text.AlignHCenter
                    activeFocusOnTab: true
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (timerIconValueField.activeFocus || timerIconValueField.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }
                    onEditingFinished: {
                        if (modelData === "timer") Config.timerIcon = text
                        else Config.timerAlarmIcon = text
                        root.settings.save()
                    }
                    Connections {
                        target: Config
                        function onTimerIconChanged() {
                            if (modelData === "timer") timerIconValueField.text = Config.timerIcon
                        }
                        function onTimerAlarmIconChanged() {
                            if (modelData === "alarm") timerIconValueField.text = Config.timerAlarmIcon
                        }
                    }
                }

                SettingsNumberField {
                    width: 58
                    height: 30
                    value: modelData === "timer" ? Config.timerIconSize : Config.timerAlarmIconSize
                    minimum: 8
                    maximum: 64
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 58
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    targetObject: Config
                    targetProperty: modelData === "timer" ? "timerIconSize" : "timerAlarmIconSize"
                    settingsObject: root.settings
                    saveOnEdit: true
                }

                SettingsNumberField {
                    width: 58
                    height: 30
                    value: modelData === "timer" ? Config.timerIconX : Config.timerAlarmIconX
                    minimum: -100
                    maximum: 100
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 58
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    targetObject: Config
                    targetProperty: modelData === "timer" ? "timerIconX" : "timerAlarmIconX"
                    settingsObject: root.settings
                    saveOnEdit: true
                }

                SettingsNumberField {
                    width: 58
                    height: 30
                    value: modelData === "timer" ? Config.timerIconY : Config.timerAlarmIconY
                    minimum: -100
                    maximum: 100
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 58
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    targetObject: Config
                    targetProperty: modelData === "timer" ? "timerIconY" : "timerAlarmIconY"
                    settingsObject: root.settings
                    saveOnEdit: true
                }

                MoveArrowButton {
                    width: 22
                    height: 22
                    iconText: "↑"
                    iconSize: Config.settingsUiSize(12)
                    baseColor: Config.text
                    hoverMode: "background"
                    hoverColor: Config.accent
                    interactionEnabled: index > 0
                    toolTipText: "Поднять выше"
                    onClicked: root.moveTimerIconOrder(modelData, -1)
                }

                MoveArrowButton {
                    width: 22
                    height: 22
                    iconText: "↓"
                    iconSize: Config.settingsUiSize(12)
                    baseColor: Config.text
                    hoverMode: "background"
                    hoverColor: Config.accent
                    interactionEnabled: index < 1
                    toolTipText: "Опустить ниже"
                    onClicked: root.moveTimerIconOrder(modelData, 1)
                }
            }
        }
    }

    SettingsNumberField {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        label: "Минимальная высота блока таймеров"
        value: Config.timerMinHeight
        minimum: 30
        maximum: 1000
        step: 1
        fieldWidth: 100
        onValueEdited: function(value) {
            Config.timerMinHeight = value
            root.settings.save()
        }
    }
    SettingsNumberField {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        label: "Шаг колеса таймера"
        value: Config.timerWheelStep
        minimum: 1
        maximum: 60
        step: 1
        fieldWidth: 100
        onValueEdited: function(value) {
            Config.timerWheelStep = value
            root.settings.save()
        }
    }
    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; height: 30; text: "Комментарий"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsNumberField {
    id: timerCommentWidthField
    width: 58
    height: 30
    value: Config.timerCommentWidth
    minimum: 40
    maximum: 300
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerCommentWidth"
    settingsObject: root.settings
    saveOnEdit: true
}
        SettingsNumberField {
    id: timerCommentMaxLengthField
    width: 58
    height: 30
    value: Config.timerCommentMaxLength
    minimum: 1
    maximum: 30
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerCommentMaxLength"
    settingsObject: root.settings
    saveOnEdit: true
}
        SettingsNumberField {
    id: timerCommentGapField
    width: 58
    height: 30
    value: Config.timerCommentGap
    minimum: 0
    maximum: 40
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerCommentGap"
    settingsObject: root.settings
    saveOnEdit: true
}
    }
    Row {
        visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
        width: parent.width
        height: 30
        SettingsCheckBox {
            width: parent.width
            height: 30
            text: "Выравнивать комментарии по самому длинному таймеру"
            checked: Config.timerCommentAlignFurthest
            onToggled: { Config.timerCommentAlignFurthest = checked; root.settings.save() }
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
            Row {
                visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3
                width: parent.width
                height: 30
                spacing: 8
                Text { width: 210; height: 30; text: "Таймеры"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                SettingsNumberField {
    id: timerRowSpacingField
    width: 58
    height: 30
    value: Config.timerRowSpacing
    minimum: 0
    maximum: 50
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerRowSpacing"
    settingsObject: root.settings
    saveOnEdit: true
}
                SettingsNumberField {
    id: timerRowTopField
    width: 58
    height: 30
    value: Config.timerRowTopMargin
    minimum: 0
    maximum: 50
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerRowTopMargin"
    settingsObject: root.settings
    saveOnEdit: true
}
                SettingsNumberField {
    id: timerRowRightField
    width: 58
    height: 30
    value: Config.timerRowRightMargin
    minimum: 0
    maximum: 50
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerRowRightMargin"
    settingsObject: root.settings
    saveOnEdit: true
}
            }
            Row { width: parent.width; height: 30; spacing: 8
                visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4
                Text { width: 210; height: 30; text: "Анимация появления кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                SettingsNumberField {
    id: timerFadeField
    width: 100
    height: 30
    value: Config.timerButtonFadeDuration
    minimum: 0
    maximum: 5000
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerButtonFadeDuration"
    settingsObject: root.settings
    saveOnEdit: true
}
            }
            Row { width: parent.width; height: 30; spacing: 8
                visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4
                Text { width: 210; height: 30; text: "Сдвиг кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                SettingsNumberField {
    id: timerSlideField
    width: 100
    height: 30
    value: Config.timerButtonSlideDuration
    minimum: 0
    maximum: 5000
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerButtonSlideDuration"
    settingsObject: root.settings
    saveOnEdit: true
}
            }
            Row { width: parent.width; height: 30; spacing: 8
                visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4
                Text { width: 210; height: 30; text: "Исчезновение иконки (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                SettingsNumberField {
    id: timerIconFadeField
    width: 100
    height: 30
    value: Config.timerButtonIconFadeDuration
    minimum: 0
    maximum: 5000
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "timerButtonIconFadeDuration"
    settingsObject: root.settings
    saveOnEdit: true
}
            }

Text {
    visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4
    text: "Анимация появления/исчезновения"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(13)
}

Row {
    visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; height: 30; text: "Стиль"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsComboBox {
        id: animationTimerVisibilityBox
        width: 180
        height: 30
        property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
        currentIndex: Math.max(0, values.indexOf(Config.animationTimerVisibilityStyle))
        onItemChosen: function(index) { Config.animationTimerVisibilityStyle = values[index]; settings.save() }
        Connections {
            target: Config
            function onAnimationTimerVisibilityStyleChanged() { animationTimerVisibilityBox.currentIndex = Math.max(0, animationTimerVisibilityBox.values.indexOf(Config.animationTimerVisibilityStyle)) }
        }
        background: Rectangle { color: Config.settingsBackground; border.color: (animationTimerVisibilityBox.activeFocus || animationTimerVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        contentItem: Text { text: animationTimerVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
    }
}

Row {
    visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; height: 30; text: "Анимация окна опций (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: timerAnimationOptionsDurationField
        width: 100; height: 30
        value: Config.animationTimerOptionsDuration
        minimum: 0; maximum: 5000; step: 50; wheelStep: 50; decimals: 0; compact: true
        fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
        targetObject: Config; targetProperty: "animationTimerOptionsDuration"; settingsObject: root.settings; saveOnEdit: true
    }
}

}
