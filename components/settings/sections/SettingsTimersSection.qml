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

    function timerOptionsActionIconOrderNormalized() {
        var allowed = ["comment", "duration", "refresh", "toggle_pause", "color"]
        var source = Config.timerOptionsActionIconOrder
        var result = []
        if (source instanceof Array) {
            for (var i = 0; i < source.length; ++i) {
                var id = String(source[i] || "")
                if (allowed.indexOf(id) >= 0 && result.indexOf(id) < 0)
                    result.push(id)
            }
        }
        for (var j = 0; j < allowed.length; ++j)
            if (result.indexOf(allowed[j]) < 0) result.push(allowed[j])
        return result
    }

    function timerOptionsActionIconPrefix(iconId) {
        switch (String(iconId)) {
        case "comment": return "timerOptionsComment"
        case "duration": return "timerOptionsDuration"
        case "refresh": return "timerOptionsRefresh"
        case "toggle_pause": return "timerOptionsPause"
        case "color": return "timerOptionsColor"
        default: return "timerOptionsComment"
        }
    }

    function timerOptionsActionIconLabel(iconId) {
        switch (String(iconId)) {
        case "comment": return "Комментарий"
        case "duration": return "Длительность"
        case "refresh": return "Перезапуск"
        case "toggle_pause": return "Пауза"
        case "color": return "Цвет"
        default: return String(iconId)
        }
    }

    function moveTimerOptionsActionIconOrder(iconId, delta) {
        var order = root.timerOptionsActionIconOrderNormalized()
        var index = order.indexOf(String(iconId))
        var target = index + Number(delta)
        if (index < 0 || target < 0 || target >= order.length) return
        var item = order[index]
        order.splice(index, 1)
        order.splice(target, 0, item)
        Config.timerOptionsActionIconOrder = order
        root.settings.save()
    }
    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["timerPresetDefaults"] })
        padding: 8
        contentSpacing: 6

        Text {
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 0
                text: "Минуты кнопок таймера"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }

            Column {
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 0
                width: parent.width
                spacing: 5

                Repeater {
                    model: (root.settings.timerPresetDefaults || []).length
                    delegate: SettingsRow {
                        id: timerPresetRow
                        width: parent.width
                        height: 30
                        spacing: 6
                        controlSpacing: 6
                        label: "Кнопка " + (index + 1)
                        labelWidth: 75
                        labelFontSize: 11
                        labelColor: Config.textMuted

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
                            fillOnHover: false
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
                    fillOnHover: false
                    borderOnHover: true
                    backgroundColor: Config.settingsBackground
                    textColor: Config.text
                    onClicked: root.settings.addTimerPreset(5)
                }
            }
    }


    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        settings: root.settings
        heading: "Случайные цвета таймеров"
        changeKeys: ({ keys: ["timerRandomColorMode", "timerRandomColorMin", "timerRandomColorMax"] })
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Правый клик по таймеру меняет его цвет. Этот же диапазон используется для новых таймеров."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        SettingsRow {
            label: "Диапазон"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8
            SettingsComboBox {
                id: timerRandomColorModeBox
                width: 180
                height: 30
                model: ["Полный · чёрный–белый", "Только светлые", "Только тёмные", "Пользовательский"]
                currentIndex: ["full", "light", "dark", "custom"].indexOf(Config.timerRandomColorMode)
                onItemChosen: function(index) {
                    Config.timerRandomColorMode = ["full", "light", "dark", "custom"][index]
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onTimerRandomColorModeChanged() {
                        timerRandomColorModeBox.currentIndex = ["full", "light", "dark", "custom"].indexOf(Config.timerRandomColorMode)
                    }
                }
            }
        }

        MorphGeometry {
            id: timerRandomCustomColorsMorph
            width: parent.width
            enabled: Config.timerRandomColorMode === "custom"
            clip: true
            visible: root.host && root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 0
                && (Config.timerRandomColorMode === "custom" || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, timerRandomCustomColorsContent.implicitHeight)
            progress: Config.timerRandomColorMode === "custom" ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.timerRandomColorMode === "custom" ? "enter" : "exit")

            Column {
                id: timerRandomCustomColorsContent
                width: parent.width
                spacing: 6

                SettingsRow {
                    label: "От"
                    labelWidth: 210
                    width: parent.width
                    height: 30
                    SettingsColorField {
                        value: String(Config.timerRandomColorMin)
                        targetObject: Config
                        targetProperty: "timerRandomColorMin"
                        settingsObject: root.settings
                        saveOnEdit: true
                        allowAlpha: false
                        allowTransparent: false
                        compact: true
                        swatchSize: 24
                        fieldWidth: 120
                    }
                }

                SettingsRow {
                    label: "До"
                    labelWidth: 210
                    width: parent.width
                    height: 30
                    SettingsColorField {
                        value: String(Config.timerRandomColorMax)
                        targetObject: Config
                        targetProperty: "timerRandomColorMax"
                        settingsObject: root.settings
                        saveOnEdit: true
                        allowAlpha: false
                        allowTransparent: false
                        compact: true
                        swatchSize: 24
                        fieldWidth: 120
                    }
                }
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["timerFinishedBackgroundColor", "timerFinishedBackgroundUsesTimerColor", "timerFinishedBorderUsesTimerColor", "timerFinishedImageEnabled", "timerFinishedImageMargin", "timerFinishedImagePath", "timerFinishedImageWidth", "timerFinishedTitleAlignment", "timerFinishedTitleColor", "timerFinishedTitleFont", "timerFinishedTitleFontSize", "timerFinishedTitleUsesTimerColor"] })
        padding: 8
        contentSpacing: 6

            Text {
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 1
                text: "Оформление и показ"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }


            Row {
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 1
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

            SettingsRow {
                label: "Путь к изображению"
                labelWidth: 210
                labelElide: Text.ElideRight

                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 1
                width: parent.width
                height: 30
                spacing: 8
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

        MorphGeometry {
            id: timerFinishedImageOptionsMorph
            width: parent.width
            enabled: Config.timerFinishedImageEnabled
            clip: true
            visible: Config.timerFinishedImageEnabled || normalizedProgress > 0.001
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, timerFinishedImageOptionsContent.implicitHeight)
            progress: Config.timerFinishedImageEnabled ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.timerFinishedImageEnabled ? "enter" : "exit")

            Column {
                id: timerFinishedImageOptionsContent
                width: parent.width
                spacing: 6

            SettingsRow {
                label: "Ширина изображения"
                labelWidth: 210

                width: parent.width
                height: 30
                spacing: 8
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

            SettingsRow {
                label: "Отступ изображения"
                labelWidth: 210
                labelElide: Text.ElideRight

                width: parent.width
                height: 30
                spacing: 8
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

            SettingsRow {
                label: "Цвет заголовка"
                labelWidth: 210

                width: parent.width; height: 30; spacing: 8
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

            MorphGeometry {
                id: timerFinishedTitleColorMorph
                width: parent.width
                enabled: !Config.timerFinishedTitleUsesTimerColor
                clip: true
                visible: !Config.timerFinishedTitleUsesTimerColor || normalizedProgress > 0.001
                fromGeometry: Qt.rect(0, 0, parent.width, 0)
                toGeometry: Qt.rect(0, 0, parent.width, 30)
                progress: !Config.timerFinishedTitleUsesTimerColor ? 1 : 0
                animationDuration: Config.animationDuration(180, "appearance")
                animationEasing: Config.animationEasingType("standard", !Config.timerFinishedTitleUsesTimerColor ? "enter" : "exit")

                SettingsRow {
                label: "Свой цвет заголовка"
                labelWidth: 210

                    width: parent.width; height: 30; spacing: 8
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
            }

            SettingsRow {
                label: "Размер заголовка"
                labelWidth: 210

                width: parent.width; height: 30; spacing: 8
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

            SettingsRow {
                label: "Шрифт заголовка"
                labelWidth: 210

                width: parent.width; height: 30; spacing: 8
                SettingsFontField {
                    width: 288
                    height: 30
                    compact: true
                    fieldWidth: 250
                    fieldFontSize: 11
                    value: Config.timerFinishedTitleFont
                    targetObject: Config
                    targetProperty: "timerFinishedTitleFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
            }

            SettingsRow {
                label: "Расположение заголовка"
                labelWidth: 210
                labelElide: Text.ElideRight

                width: parent.width; height: 30; spacing: 8
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

            }
        }

            SettingsRow {
                label: "Цвет рамки окна"
                labelWidth: 210

                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 1
                width: parent.width
                height: 30
                spacing: 8
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

            SettingsRow {
                label: "Фон окна"
                labelWidth: 210

                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 1
                width: parent.width
                height: 30
                spacing: 8
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

            MorphGeometry {
                id: timerFinishedBackgroundColorMorph
                width: parent.width
                enabled: !Config.timerFinishedBackgroundUsesTimerColor
                clip: true
                visible: !Config.timerFinishedBackgroundUsesTimerColor || normalizedProgress > 0.001
                fromGeometry: Qt.rect(0, 0, parent.width, 0)
                toGeometry: Qt.rect(0, 0, parent.width, 30)
                progress: !Config.timerFinishedBackgroundUsesTimerColor ? 1 : 0
                animationDuration: Config.animationDuration(180, "appearance")
                animationEasing: Config.animationEasingType("standard", !Config.timerFinishedBackgroundUsesTimerColor ? "enter" : "exit")

                SettingsRow {
                label: "Свой цвет фона"
                labelWidth: 210

                    width: parent.width
                    height: 30
                    spacing: 8
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
            }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Иконки таймера и будильника"
        changeKeys: ({ keys: ["timerAlarmIcon", "timerAlarmIconEnabled", "timerIcon", "timerIconEnabled"] })
        padding: 8
        contentSpacing: 6

            Column {
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 2
                width: parent.width
                spacing: 4

                Row {
                    width: parent.width
                    height: 18
                    spacing: 6
                    Item { width: 110; height: 18 }
                    Text { width: 30; text: "Вкл."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
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

                        SettingsCheckBox {
                            width: 30
                            height: 30
                            indicatorOnly: true
                            checked: modelData === "timer" ? Config.timerIconEnabled : Config.timerAlarmIconEnabled
                            onToggled: {
                                if (modelData === "timer") Config.timerIconEnabled = checked
                                else Config.timerAlarmIconEnabled = checked
                                root.settings.save()
                            }
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
                            hoverMode: "frame"
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
                            hoverMode: "frame"
                            hoverColor: Config.accent
                            interactionEnabled: index < 1
                            toolTipText: "Опустить ниже"
                            onClicked: root.moveTimerIconOrder(modelData, 1)
                        }
                    }
                }
            }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 3
settingsSearchSubTabIndex: 3
        width: parent.width
        showFrame: true
        heading: "Отображение времени"
        changeKeys: ({ keys: ["timerElapsedFont", "timerElapsedFontSize"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Шрифт времени таймера"
            labelWidth: 210
            width: parent.width
            height: 30
            SettingsFontField {
                compact: true
                fieldWidth: 180
                value: Config.timerElapsedFont
                targetObject: Config
                targetProperty: "timerElapsedFont"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            label: "Размер времени таймера"
            labelWidth: 210
            width: parent.width
            height: 30
            SettingsNumberField {
                compact: true
                fieldWidth: 100
                value: Config.timerElapsedFontSize
                minimum: 8
                maximum: 60
                step: 1
                targetObject: Config
                targetProperty: "timerElapsedFontSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 3
settingsSearchSubTabIndex: 3
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["timerCommentAlignFurthest", "timerCommentGap", "timerCommentMaxLength", "timerCommentWidth", "timerMinHeight", "timerRowRightMargin", "timerRowSpacing", "timerRowTopMargin", "timerWheelStep"] })
        padding: 8
        contentSpacing: 6

            SettingsRow {
                label: "Минимальная высота блока таймеров"
                labelWidth: 210
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3
                width: parent.width
                height: 30
                SettingsNumberField {
                    compact: true
                    fieldWidth: 100
                    value: Config.timerMinHeight
                    minimum: 30
                    maximum: 1000
                    step: 1
                    onValueEdited: function(value) {
                        Config.timerMinHeight = value
                        root.settings.save()
                    }
                }
            }
            SettingsRow {
                label: "Шаг колеса таймера"
                labelWidth: 210
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3
                width: parent.width
                height: 30
                SettingsNumberField {
                    compact: true
                    fieldWidth: 100
                    value: Config.timerWheelStep
                    minimum: 1
                    maximum: 60
                    step: 1
                    onValueEdited: function(value) {
                        Config.timerWheelStep = value
                        root.settings.save()
                    }
                }
            }
            SettingsRow {
            label: "Комментарий"
            labelWidth: 210
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3
                width: parent.width
                height: 30
                spacing: 8
            controlSpacing: 8
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
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3
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
                visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3
                width: parent.width
                height: 24
                spacing: 8
                Item { width: 210; height: 24 }
                Text { width: 58; text: "Между"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                Text { width: 58; text: "Сверху"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                Text { width: 58; text: "Справа"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
                    SettingsRow {
            label: "Таймеры"
            labelWidth: 210
                        visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3
                        width: parent.width
                        height: 30
                        spacing: 8
            controlSpacing: 8
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
    }
    SettingsAnimationGroup {
        visible: root.host && root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 4
        settings: root.settings
        heading: "Внутренние переходы таймера"
        changeKeys: ({ keys: ["animationTimerMorphDuration", "animationTimerMorphProfile"] })
        duration: Config.animationTimerMorphDuration
        durationLabel: "Добавление/удаление строк (мс)"
        profile: Config.animationTimerMorphProfile

        onDurationEdited: function(value) {
            Config.animationTimerMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            // Legacy compatibility flag is no longer exposed in the UI.
            // Keep it enabled so the selected profile is the sole control.
            Config.animationTimerMorphEnabled = true
            Config.animationTimerMorphProfile = value
            root.settings.save()
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Профиль управляет появлением и удалением строк, морфингом иконок таймера/будильника и показом кнопок пресетов. Длительность выше относится к строкам; интервалы и стиль кнопок настраиваются ниже. Окно опций имеет отдельные параметры."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 4
settingsSearchSubTabIndex: 4
        width: parent.width
        showFrame: true
        heading: "Анимация кнопок таймера"
        changeKeys: ({ keys: ["animationTimerVisibilityStyle", "timerButtonFadeDuration", "timerButtonIconFadeDuration", "timerButtonSlideDuration"] })
        padding: 8
        contentSpacing: 6


        SettingsRow {
            label: "Стиль появления кнопок"
            labelWidth: 210
            visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 4
            width: parent.width
            height: 30
            spacing: 8
                        SettingsComboBox {
                id: timerWidgetVisibilityBox
                width: 180
                height: 30
                property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationTimerVisibilityStyle))
                onItemChosen: function(index) { Config.animationTimerVisibilityStyle = values[index]; root.settings.save() }
                Connections {
                    target: Config
                    function onAnimationTimerVisibilityStyleChanged() { timerWidgetVisibilityBox.currentIndex = Math.max(0, timerWidgetVisibilityBox.values.indexOf(Config.animationTimerVisibilityStyle)) }
                }
                background: Rectangle { color: Config.settingsBackground; border.color: (timerWidgetVisibilityBox.activeFocus || timerWidgetVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                contentItem: Text { text: timerWidgetVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
            }
        }

                    SettingsRow {
            label: "Затухание кнопок (мс)"
            labelWidth: 210
            width: parent.width
            height: visible ? 30 : 0
            spacing: 8
                        visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 4
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
                    SettingsRow {
            label: "Сдвиг кнопок (мс)"
            labelWidth: 210
            width: parent.width
            height: visible ? 30 : 0
            spacing: 8
                        visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 4
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
                    SettingsRow {
            label: "Появление/исчезновение иконок (мс)"
            labelWidth: 210
            labelElide: Text.ElideRight
            width: parent.width
            height: visible ? 30 : 0
            spacing: 8
                        visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 4
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
    }

    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 5
settingsSearchSubTabIndex: 5
        width: parent.width
        showFrame: true
        heading: "Анимация окна опций"
        changeKeys: ({ keys: ["animationTimerOptionsDuration", "animationTimerOptionsVisibilityStyle"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Стиль"
            labelWidth: 210
            visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 5
            width: parent.width
            height: 30
            spacing: 8
                        SettingsComboBox {
                id: animationTimerVisibilityBox
                width: 180
                height: 30
                property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationTimerOptionsVisibilityStyle))
                onItemChosen: function(index) { Config.animationTimerOptionsVisibilityStyle = values[index]; settings.save() }
                Connections {
                    target: Config
                    function onAnimationTimerOptionsVisibilityStyleChanged() { animationTimerVisibilityBox.currentIndex = Math.max(0, animationTimerVisibilityBox.values.indexOf(Config.animationTimerOptionsVisibilityStyle)) }
                }
                background: Rectangle { color: Config.settingsBackground; border.color: (animationTimerVisibilityBox.activeFocus || animationTimerVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                contentItem: Text { text: animationTimerVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
            }
        }

        SettingsRow {
            label: "Анимация окна опций (мс)"
            labelWidth: 210
            visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 5
            width: parent.width
            height: 30
            spacing: 8
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



    SettingsGroup {
                visible: host && host.currentPageId === "timers" && host.currentPageSubTabIndex === 5
settingsSearchSubTabIndex: 5
        width: parent.width
        showFrame: true
        heading: "Иконки окна опций"
        changeKeys: ({ prefixes: ["timerOptionsCommentIcon", "timerOptionsDurationIcon", "timerOptionsRefreshIcon", "timerOptionsPauseIcon", "timerOptionsColorIcon"], keys: ["timerOptionsActionIconOrder"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 5
            width: parent.width
            height: 18
            spacing: 6
            Item { width: 110; height: 18 }
            Text { width: 30; text: "Вкл."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Item { width: 44; height: 18 }
        }

        Repeater {
            model: root.timerOptionsActionIconOrderNormalized()
            delegate: Row {
                id: timerOptionsActionIconRow
                width: parent.width
                height: 30
                spacing: 6
                property string keyPrefix: root.timerOptionsActionIconPrefix(modelData)

                Text {
                    width: 110
                    height: 30
                    text: root.timerOptionsActionIconLabel(modelData)
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                SettingsCheckBox {
                    width: 30
                    height: 30
                    indicatorOnly: true
                    checked: Config[timerOptionsActionIconRow.keyPrefix + "IconEnabled"]
                    onToggled: {
                        Config[timerOptionsActionIconRow.keyPrefix + "IconEnabled"] = checked
                        root.settings.save()
                    }
                }

                SettingsTextField {
                    id: timerOptionsActionIconField
                    width: 58
                    height: 30
                    text: Config[timerOptionsActionIconRow.keyPrefix + "Icon"]
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(12)
                    horizontalAlignment: Text.AlignHCenter
                    activeFocusOnTab: true
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (timerOptionsActionIconField.activeFocus || timerOptionsActionIconField.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }
                    onEditingFinished: {
                        Config[timerOptionsActionIconRow.keyPrefix + "Icon"] = text
                        root.settings.save()
                    }
                    Connections {
                        target: Config
                        function onTimerOptionsCommentIconChanged() { if (modelData === "comment") timerOptionsActionIconField.text = Config.timerOptionsCommentIcon }
                        function onTimerOptionsDurationIconChanged() { if (modelData === "duration") timerOptionsActionIconField.text = Config.timerOptionsDurationIcon }
                        function onTimerOptionsRefreshIconChanged() { if (modelData === "refresh") timerOptionsActionIconField.text = Config.timerOptionsRefreshIcon }
                        function onTimerOptionsPauseIconChanged() { if (modelData === "toggle_pause") timerOptionsActionIconField.text = Config.timerOptionsPauseIcon }
                        function onTimerOptionsColorIconChanged() { if (modelData === "color") timerOptionsActionIconField.text = Config.timerOptionsColorIcon }
                    }
                }

                SettingsNumberField {
                    width: 58
                    height: 30
                    value: Config[timerOptionsActionIconRow.keyPrefix + "IconSize"]
                    minimum: 8
                    maximum: 40
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 58
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    targetObject: Config
                    targetProperty: timerOptionsActionIconRow.keyPrefix + "IconSize"
                    settingsObject: root.settings
                    saveOnEdit: true
                }

                MoveArrowButton {
                    width: 22
                    height: 22
                    iconText: "↑"
                    iconSize: Config.settingsUiSize(12)
                    baseColor: Config.text
                    hoverMode: "frame"
                    hoverColor: Config.accent
                    interactionEnabled: index > 0
                    toolTipText: "Поднять выше"
                    onClicked: root.moveTimerOptionsActionIconOrder(modelData, -1)
                }

                MoveArrowButton {
                    width: 22
                    height: 22
                    iconText: "↓"
                    iconSize: Config.settingsUiSize(12)
                    baseColor: Config.text
                    hoverMode: "frame"
                    hoverColor: Config.accent
                    interactionEnabled: index < root.timerOptionsActionIconOrderNormalized().length - 1
                    toolTipText: "Опустить ниже"
                    onClicked: root.moveTimerOptionsActionIconOrder(modelData, 1)
                }
            }
        }
    }

}
