import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root

    function wheelDelta(wheel, step) {
        var direction = wheel.angleDelta.y > 0 ? 1 : -1
        var multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
        return direction * step * multiplier
    }
    property var settings: Settings
    property int currentTab: 0
    property int currentOtherTab: 0
    signal layoutEditRequested()
    clip: true

    ListModel {
        id: profileModel
    }

    function refreshProfileModel() {
        profileModel.clear()
        var names = settings.profileNames()
        for (var i = 0; i < names.length; ++i)
            profileModel.append({ name: String(names[i]) })
    }

    Connections {
        target: settings
        function onProfilesRevisionChanged() { root.refreshProfileModel() }
    }

    Component.onCompleted: root.refreshProfileModel()

    Rectangle {
        anchors.fill: parent
        color: Config.settingsBackground
        border.color: Config.settingsBorder
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius
        antialiasing: true
    }

    Column {
        anchors.fill: parent
        anchors.margins: Config.settingsPadding
        spacing: Config.settingsSpacing

        Row {
            width: parent.width
            height: 28
            Text {
                width: parent.width - 120
                text: "НАСТРОЙКИ"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(20)
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: saveIndicator
                width: 120
                text: "✓ сохранено"
                color: Config.accent
                opacity: 0
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
        SequentialAnimation {
            id: savePulse
            PropertyAnimation { target: saveIndicator; property: "opacity"; to: 0.9; duration: 100 }
            PauseAnimation { duration: 500 }
            PropertyAnimation { target: saveIndicator; property: "opacity"; to: 0; duration: 350 }
        }
        Connections { target: settings; function onSaved() { savePulse.restart() } }

        Row {
            id: tabs
            width: parent.width
            height: 34
            spacing: 6

            Repeater {
                model: ["Модули", "Цвета", "Прочие настройки"]

                delegate: Rectangle {
                    width: (tabs.width - 12) / 3
                    height: tabs.height
                    radius: Config.radius
                    color: root.currentTab === index ? Config.accent : Config.background
                    border.color: Config.baseColor
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        text: modelData
                        color: root.currentTab === index ? Config.black : Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        font.bold: root.currentTab === index
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.currentTab = index
                    }
                }
            }
        }

        Item {
            id: otherSettingsArea
            visible: root.currentTab === 2
            width: parent.width
            height: parent.height - y

            Row {
                anchors.fill: parent
                spacing: 8

                Column {
                    id: otherTabs
                    width: 128
                    height: parent.height
                    spacing: 5

                    Repeater {
                        model: ["Общие", "Таймеры", "Плеер", "Погода", "CAVA", "CPU/RAM", "Сеть", "Громкость", "Настройки", "Анимации"]

                        delegate: Rectangle {
                            width: otherTabs.width
                            height: 34
                            radius: 4
                            color: root.currentOtherTab === index ? Config.accent : Config.background
                            border.color: Config.baseColor
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                text: modelData
                                color: root.currentOtherTab === index ? Config.black : Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                font.bold: root.currentOtherTab === index
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.currentOtherTab = index
                            }
                        }
                    }
                }

                Flickable {
            id: otherFlick
            width: parent.width - otherTabs.width - 8
            height: parent.height
            contentWidth: width
            contentHeight: otherColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: otherColumn
                width: otherFlick.width - 12
                spacing: 10

                Row {
                    width: parent.width
                    height: 30
                    Text {
                        width: parent.width - 38
                        text: "ПРОЧИЕ НАСТРОЙКИ"
                        color: Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(15)
                        verticalAlignment: Text.AlignVCenter
                    }
                    SettingsResetButton {
                        tooltip: "Сбросить текущую вкладку"
                        onClicked: {
                            if (root.currentOtherTab === 0) settings.resetGeneralSettings()
                            else if (root.currentOtherTab === 1) settings.resetTimerSettings()
                            else if (root.currentOtherTab === 2) settings.resetPlayerSettings()
                            else if (root.currentOtherTab === 3) settings.resetWeatherSettings()
                            else if (root.currentOtherTab === 4) settings.resetCavaSettings()
                            else if (root.currentOtherTab === 5) settings.resetCpuSettings()
                            else if (root.currentOtherTab === 6) settings.resetNetworkSettings()
                            else if (root.currentOtherTab === 7) settings.resetVolumeSettings()
                            else if (root.currentOtherTab === 8) settings.resetSettingsWindow()
                            else if (root.currentOtherTab === 9) settings.resetAnimationSettings()
                        }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 3
                    text: "Токен Gismeteo"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(13)
                }

                TextField {
                    visible: root.currentOtherTab === 3
                    id: token
                    width: parent.width
                    height: 34
                    text: settings.weatherToken
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    placeholderText: "Введите токен Gismeteo"
                    placeholderTextColor: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(12)
                    activeFocusOnTab: true
                    background: Rectangle {
                        color: Config.background
                        border.color: token.activeFocus ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: Config.radius
                    }
                    onEditingFinished: {
                        settings.weatherToken = text
                        settings.save()
                    }
                }


                Text {
                    visible: root.currentOtherTab === 0
                    text: "Общие"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 0
                    text: "Основной шрифт интерфейса, LED-шрифт и общие параметры"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 0
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "Основной шрифт интерфейса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: generalFontField
                        width: 160; height: 30
                        text: Config.font
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle { color: Config.background; border.color: generalFontField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        onEditingFinished: { Config.font = text.trim() || Config.font; text = Config.font; settings.save() }
                        Connections { target: Config; function onFontChanged() { generalFontField.text = Config.font } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 0
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "Размер шрифта интерфейса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
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
                        background: Rectangle { color: Config.background; border.color: generalFontSizeField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) {
                            var n = Number(v)
                            if (!isFinite(n)) n = Config.fontSize
                            n = Math.max(6, Math.min(32, Math.round(n)))
                            Config.fontSize = n
                            text = String(n)
                            settings.save()
                        }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { generalFontSizeField.applyValue(Config.fontSize + root.wheelDelta(wheel, 1)); wheel.accepted = true } }
                        Connections { target: Config; function onFontSizeChanged() { generalFontSizeField.text = String(Config.fontSize) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 0
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "LED-шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: ledFontField
                        width: 160; height: 30
                        text: Config.ledFont
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle { color: Config.background; border.color: ledFontField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        onEditingFinished: { Config.ledFont = text.trim() || Config.ledFont; text = Config.ledFont; settings.save() }
                        Connections { target: Config; function onLedFontChanged() { ledFontField.text = Config.ledFont } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 9
                    text: "Анимации"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Row {
                    visible: root.currentOtherTab === 9
                    width: parent.width
                    height: 30
                    spacing: 8
                    CheckBox {
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
                    visible: root.currentOtherTab === 9
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text { width: 210; text: "Скорость анимаций (×)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: animationSpeedField
                        width: 100; height: 28
                        text: Number(Config.animationSpeed).toFixed(2)
                        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                        background: Rectangle { color: Config.background; border.color: animationSpeedField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n = Number(v); if (!isFinite(n)) n = Config.animationSpeed; n = Math.max(0.25, Math.min(4, Math.round(n * 4) / 4)); Config.animationSpeed = n; text = Number(n).toFixed(2); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { animationSpeedField.applyValue(Number(Config.animationSpeed) + root.wheelDelta(wheel, 0.25)); wheel.accepted = true } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 9
                    text: "Единая скорость и длительности встроенных анимаций. 0 мс отключает конкретную анимацию."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 9
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text { width: 210; text: "Календарь: раскрытие (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: animationCalendarSlideField
                        width: 100; height: 28
                        text: String(Config.animationCalendarSlideDuration)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: animationCalendarSlideField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.animationCalendarSlideDuration; n=Math.max(0,Math.min(5000,Math.round(n))); Config.animationCalendarSlideDuration=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ animationCalendarSlideField.applyValue(Config.animationCalendarSlideDuration+root.wheelDelta(wheel, 50)); wheel.accepted=true } }
                        Connections { target: Config; function onAnimationCalendarSlideDurationChanged() { animationCalendarSlideField.text=String(Config.animationCalendarSlideDuration) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 9
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text { width: 210; text: "Календарь: исчезновение (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: animationCalendarFadeField
                        width: 100; height: 28
                        text: String(Config.animationCalendarFadeDuration)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: animationCalendarFadeField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.animationCalendarFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n))); Config.animationCalendarFadeDuration=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ animationCalendarFadeField.applyValue(Config.animationCalendarFadeDuration+root.wheelDelta(wheel, 50)); wheel.accepted=true } }
                        Connections { target: Config; function onAnimationCalendarFadeDurationChanged() { animationCalendarFadeField.text=String(Config.animationCalendarFadeDuration) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 9
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text { width: 210; text: "Настройки таймера (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: animationTimerOptionsField
                        width: 100; height: 28
                        text: String(Config.animationTimerOptionsDuration)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: animationTimerOptionsField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.animationTimerOptionsDuration; n=Math.max(0,Math.min(5000,Math.round(n))); Config.animationTimerOptionsDuration=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ animationTimerOptionsField.applyValue(Config.animationTimerOptionsDuration+root.wheelDelta(wheel, 50)); wheel.accepted=true } }
                        Connections { target: Config; function onAnimationTimerOptionsDurationChanged() { animationTimerOptionsField.text=String(Config.animationTimerOptionsDuration) } }
                    }
                }

                Text { visible: root.currentOtherTab === 6; text: "Обновление общих данных"; color: Config.accent; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12) }

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 6
                    Text { width: 210; text: "System Monitor (мс) — общие данные"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: systemIntervalField; width: 100; height: 28; text: String(Config.systemMonitorInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n = Number(text); if (!isFinite(n)) n = Config.systemMonitorInterval; n = Math.max(200, Math.min(10000, Math.round(n))); Config.systemMonitorInterval = n; text = String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { var n = Math.max(200, Math.min(10000, Config.systemMonitorInterval + root.wheelDelta(wheel, 100))); Config.systemMonitorInterval=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 5
                    Text { width: 210; text: "CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuIntervalField; width: 100; height: 28; text: String(Config.cpuUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.cpuUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.cpuUpdateInterval=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(200,Math.min(10000,Config.cpuUpdateInterval+root.wheelDelta(wheel, 100))); Config.cpuUpdateInterval=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Плеер (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerIntervalField; width: 100; height: 28; text: String(Config.playerUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.playerUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.playerUpdateInterval=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(200,Math.min(10000,Config.playerUpdateInterval+root.wheelDelta(wheel, 100))); Config.playerUpdateInterval=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Погода сейчас (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherNowIntervalField; width: 100; height: 28; text: String(Config.weatherNowIntervalMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherNowIntervalMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherNowIntervalMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherNowIntervalMinutes+root.wheelDelta(wheel, 1))); Config.weatherNowIntervalMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Погода по часам (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherHourlyIntervalField; width: 100; height: 28; text: String(Config.weatherHourlyIntervalMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherHourlyIntervalMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherHourlyIntervalMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherHourlyIntervalMinutes+root.wheelDelta(wheel, 1))); Config.weatherHourlyIntervalMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Погода по дням (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherDailyIntervalField; width: 100; height: 28; text: String(Config.weatherDailyIntervalMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherDailyIntervalMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherDailyIntervalMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherDailyIntervalMinutes+root.wheelDelta(wheel, 1))); Config.weatherDailyIntervalMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Повтор после ошибки (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherRetryDelayField; width: 100; height: 28; text: String(Config.weatherRetryDelayMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherRetryDelayMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherRetryDelayMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherRetryDelayMinutes+root.wheelDelta(wheel, 1))); Config.weatherRetryDelayMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Пауза между ручными обновлениями (с)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherManualCooldownField; width: 100; height: 28; text: String(Config.weatherManualRefreshCooldownSeconds); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherManualRefreshCooldownSeconds; n=Math.max(5,Math.min(3600,Math.round(n))); Config.weatherManualRefreshCooldownSeconds=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(5,Math.min(3600,Config.weatherManualRefreshCooldownSeconds+root.wheelDelta(wheel, 1))); Config.weatherManualRefreshCooldownSeconds=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 0
                    text: "Рамки"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 0
                    text: "Общие рамки виджетов. Толщина 0 полностью отключает рамку."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 0
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

                    TextField {
                        id: frameBorderWidthField
                        width: 100
                        height: 28
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
                            color: Config.background
                            border.color: frameBorderWidthField.activeFocus ? Config.accent : Config.baseColor
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
                            hoverEnabled: true
                            onWheel: wheel => {
                                var n = Math.max(0, Math.min(20, Number(Config.frameBorderWidth) + root.wheelDelta(wheel, 1)))
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
                    visible: root.currentOtherTab === 0
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

                    TextField {
                        id: frameRadiusField
                        width: 100
                        height: 28
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
                            color: Config.background
                            border.color: frameRadiusField.activeFocus ? Config.accent : Config.baseColor
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
                            hoverEnabled: true
                            onWheel: wheel => {
                                var n = Math.max(0, Math.min(50, Number(Config.frameRadius) + root.wheelDelta(wheel, 1)))
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


                Text {
                    visible: root.currentOtherTab === 0
                    text: "Адаптивные блоки"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(12)
                }
                Text {
                    visible: root.currentOtherTab === 0
                    text: "Высота блока автоматически растёт по содержимому в пределах этих ограничений."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(9)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 0
                    Text { width: 210; text: "Минимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMinHeightField; width: 100; height: 28; text: String(Config.volumeMinHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMinHeight; n=Math.max(30,Math.min(1000,Math.round(n))); Config.volumeMinHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMinHeightField.applyValue(Config.volumeMinHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 0
                    Text { width: 210; text: "Максимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMaxHeightField; width: 100; height: 28; text: String(Config.volumeMaxHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMaxHeight; n=Math.max(100,Math.min(2000,Math.round(n))); Config.volumeMaxHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMaxHeightField.applyValue(Config.volumeMaxHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 2
                    text: "Плеер"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 2
                    text: "Тексты и шрифты плеера"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row {
                    visible: root.currentOtherTab === 2
                    width: parent.width
                    height: 34
                    spacing: 8

                    Text {
                        width: 210
                        text: "Текст при отсутствии воспроизведения"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    TextField {
                        id: playerSilenceField
                        width: 160
                        height: 30
                        text: Config.playerSilenceText
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle {
                            color: Config.background
                            border.color: playerSilenceField.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: 4
                        }
                        onEditingFinished: {
                            Config.playerSilenceText = text
                            settings.save()
                        }
                        Connections {
                            target: Config
                            function onPlayerSilenceTextChanged() {
                                playerSilenceField.text = Config.playerSilenceText
                            }
                        }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 2
                    width: parent.width
                    height: 34
                    spacing: 8

                    Text {
                        width: 210
                        text: "Основной шрифт плеера"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                    }

                    TextField {
                        id: playerFontField
                        width: 160
                        height: 30
                        text: Config.playerFont
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle {
                            color: Config.background
                            border.color: playerFontField.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: 4
                        }
                        onEditingFinished: {
                            Config.playerFont = text
                            settings.save()
                        }
                        Connections {
                            target: Config
                            function onPlayerFontChanged() {
                                playerFontField.text = Config.playerFont
                            }
                        }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 2
                    width: parent.width
                    height: 34
                    spacing: 8

                    Text {
                        width: 210
                        text: "Шрифт метаданных плеера"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                    }

                    TextField {
                        id: playerMetaFontField
                        width: 160
                        height: 30
                        text: Config.playerMetaFont
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle {
                            color: Config.background
                            border.color: playerMetaFontField.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: 4
                        }
                        onEditingFinished: {
                            Config.playerMetaFont = text
                            settings.save()
                        }
                        Connections {
                            target: Config
                            function onPlayerMetaFontChanged() {
                                playerMetaFontField.text = Config.playerMetaFont
                            }
                        }
                    }
                }


                Text {
                    visible: root.currentOtherTab === 2
                    text: "Размеры и поведение плеера"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер текста Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: silenceSizeField; width: 100; height: 28; text: String(Config.playerSilenceFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceFontSize; n=Math.max(8,Math.min(100,Math.round(n))); Config.playerSilenceFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ silenceSizeField.applyValue(Config.playerSilenceFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер длинного Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: silenceLongSizeField; width: 100; height: 28; text: String(Config.playerSilenceLongFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceLongFontSize; n=Math.max(8,Math.min(100,Math.round(n))); Config.playerSilenceLongFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ silenceLongSizeField.applyValue(Config.playerSilenceLongFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер основной строки метаданных"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: metaSizeField; width: 100; height: 28; text: String(Config.playerMetaFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerMetaFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSizeField.applyValue(Config.playerMetaFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер остальных строк"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: metaSecondarySizeField; width: 100; height: 28; text: String(Config.playerMetaSecondaryFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaSecondaryFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerMetaSecondaryFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSecondarySizeField.applyValue(Config.playerMetaSecondaryFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: metaSpacingField; width: 100; height: 28; text: String(Config.playerMetaLineSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaLineSpacing; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerMetaLineSpacing=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSpacingField.applyValue(Config.playerMetaLineSpacing+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    CheckBox { id: boldArtistBox; width: 210; height: 30; text: "Жирный исполнитель"; checked: Config.playerBoldArtist; onToggled: { Config.playerBoldArtist=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    CheckBox { id: showProgressBox; width: 210; height: 30; text: "Показывать прогресс"; checked: Config.playerShowProgress; onToggled: { Config.playerShowProgress=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер иконок управления"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: controlIconSizeField; width: 100; height: 28; text: String(Config.playerControlIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerControlIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.playerControlIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ controlIconSizeField.applyValue(Config.playerControlIconSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 2
                    text: "Геометрия и отображение"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ метаданных по X"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerMetaXPadField; width: 100; height: 28; text: String(Config.playerMetadataXPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: playerMetaXPadField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerMetadataXPadding; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerMetadataXPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerMetaXPadField.applyValue(Config.playerMetadataXPadding+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerMetadataXPaddingChanged(){playerMetaXPadField.text=String(Config.playerMetadataXPadding)}}
                    }
                }
                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Положение метаданных по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerMetaYField; width: 100; height: 28; text: String(Config.playerMetadataY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: playerMetaYField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerMetadataY; n=Math.max(0,Math.min(1000,Math.round(n))); Config.playerMetadataY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerMetaYField.applyValue(Config.playerMetadataY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerMetadataYChanged(){playerMetaYField.text=String(Config.playerMetadataY)}}
                    }
                }
                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Положение прогресса по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerProgressYField; width: 100; height: 28; text: String(Config.playerProgressY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: playerProgressYField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerProgressY; n=Math.max(0,Math.min(1000,Math.round(n))); Config.playerProgressY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerProgressYField.applyValue(Config.playerProgressY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerProgressYChanged(){playerProgressYField.text=String(Config.playerProgressY)}}
                    }
                }
                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота полосы прогресса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerProgressHeightField; width: 100; height: 28; text: String(Config.playerProgressHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: playerProgressHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerProgressHeight; n=Math.max(1,Math.min(30,Math.round(n))); Config.playerProgressHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerProgressHeightField.applyValue(Config.playerProgressHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerProgressHeightChanged(){playerProgressHeightField.text=String(Config.playerProgressHeight)}}
                    }
                }
                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Прозрачность обложки (0–1)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerCoverOpacityField; width: 100; height: 28; text: Number(Config.playerCoverOpacity).toFixed(2); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: playerCoverOpacityField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerCoverOpacity; n=Math.max(0,Math.min(1,Math.round(n*20)/20)); Config.playerCoverOpacity=n; text=Number(n).toFixed(2); settings.save() } onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerCoverOpacityField.applyValue(Config.playerCoverOpacity+root.wheelDelta(wheel, 0.05));wheel.accepted=true}} Connections{target:Config;function onPlayerCoverOpacityChanged(){playerCoverOpacityField.text=Number(Config.playerCoverOpacity).toFixed(2)}}
                    }
                }

                Text {
                    visible: root.currentOtherTab === 2
                    text: "Размытие фона плеера"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row {
                    visible: root.currentOtherTab === 2
                    width: parent.width
                    height: 30
                    spacing: 8
                    CheckBox {
                        id: playerBlurEnabledBox
                        width: 210
                        height: 30
                        text: "Блюр фона плеера"
                        checked: Config.playerBlurEnabled
                        onToggled: { Config.playerBlurEnabled = checked; settings.save() }
                        contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width + 5; verticalAlignment: Text.AlignVCenter }
                    }
                    Text { text: Config.playerBlurEnabled ? "включён" : "выключен"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter }
                }

                Text {
                    visible: root.currentOtherTab === 2
                    text: "Размывается содержимое позади плеера; сила блюра задаётся композитором Niri."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(9)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 2
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text { width: 210; text: "Радиус области блюра (0–40)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: playerBlurRadiusField
                        width: 100
                        height: 28
                        text: String(Config.playerBlurRadius)
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        horizontalAlignment: Text.AlignHCenter
                        activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: playerBlurRadiusField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerBlurRadius; n=Math.max(0,Math.min(40,Math.round(n))); Config.playerBlurRadius=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { playerBlurRadiusField.applyValue(Config.playerBlurRadius + root.wheelDelta(wheel, 1)); wheel.accepted = true } }
                        Connections { target: Config; function onPlayerBlurRadiusChanged() { playerBlurRadiusField.text = String(Config.playerBlurRadius) } }
                    }
                }

                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина области Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerSilenceWidthField; width: 100; height: 28; text: String(Config.playerSilenceWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: playerSilenceWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceWidth; n=Math.max(100,Math.min(600,Math.round(n))); Config.playerSilenceWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerSilenceWidthField.applyValue(Config.playerSilenceWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerSilenceWidthChanged(){ playerSilenceWidthField.text=String(Config.playerSilenceWidth) } }
                    }
                }
                Row { visible: root.currentOtherTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Смещение дорожки прогресса по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerProgressTrackOffsetYField; width: 100; height: 28; text: String(Config.playerProgressTrackOffsetY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: playerProgressTrackOffsetYField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerProgressTrackOffsetY; n=Math.max(-10,Math.min(20,Math.round(n))); Config.playerProgressTrackOffsetY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerProgressTrackOffsetYField.applyValue(Config.playerProgressTrackOffsetY+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerProgressTrackOffsetYChanged(){ playerProgressTrackOffsetYField.text=String(Config.playerProgressTrackOffsetY) } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 4
                    text: "CAVA"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Row {
                    visible: root.currentOtherTab === 4
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

                    TextField {
                        id: cavaBarsField
                        width: 100
                        height: 28
                        text: String(Config.cavaBars)
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        horizontalAlignment: Text.AlignHCenter
                        activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle {
                            color: Config.background
                            border.color: cavaBarsField.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: 4
                        }
                        function applyValue() {
                            var n = Number(text)
                            if (!isFinite(n)) {
                                text = String(Config.cavaBars)
                                return
                            }
                            n = Math.max(8, Math.min(120, Math.round(n)))
                            Config.cavaBars = n
                            text = String(n)
                            settings.save()
                        }
                        onEditingFinished: applyValue()

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            hoverEnabled: true
                            onWheel: wheel => {
                                var n = Math.max(8, Math.min(120, Number(Config.cavaBars) + root.wheelDelta(wheel, 1)))
                                Config.cavaBars = n
                                cavaBarsField.text = String(n)
                                settings.save()
                                wheel.accepted = true
                            }
                        }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 4
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

                    TextField {
                        id: cavaFramerateField
                        width: 100
                        height: 28
                        text: String(Config.cavaFramerate)
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        horizontalAlignment: Text.AlignHCenter
                        activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle {
                            color: Config.background
                            border.color: cavaFramerateField.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: 4
                        }
                        function applyValue() {
                            var n = Number(text)
                            if (!isFinite(n)) { text = String(Config.cavaFramerate); return }
                            n = Math.max(1, Math.min(120, Math.round(n)))
                            Config.cavaFramerate = n
                            text = String(n)
                            settings.save()
                        }
                        onEditingFinished: applyValue()
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            hoverEnabled: true
                            onWheel: wheel => {
                                var n = Math.max(1, Math.min(120, Number(Config.cavaFramerate) + root.wheelDelta(wheel, 1)))
                                Config.cavaFramerate = n
                                cavaFramerateField.text = String(n)
                                settings.save()
                                wheel.accepted = true
                            }
                        }
                        Connections {
                            target: Config
                            function onCavaFramerateChanged() { cavaFramerateField.text = String(Config.cavaFramerate) }
                        }
                    }
                }

                Row { visible: root.currentOtherTab === 4; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота ряда CAVA"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cavaRowHeightField; width: 100; height: 28; text: String(Config.cavaRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cavaRowHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.cavaRowHeight;n=Math.max(10,Math.min(200,Math.round(n)));Config.cavaRowHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{cavaRowHeightField.applyValue(Config.cavaRowHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onCavaRowHeightChanged(){cavaRowHeightField.text=String(Config.cavaRowHeight)}}
                    }
                }
                Row { visible: root.currentOtherTab === 4; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Зазор между слотами CAVA"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cavaRowSpacingField; width: 100; height: 28; text: String(Config.cavaRowSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cavaRowSpacingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.cavaRowSpacing;n=Math.max(0,Math.min(20,Math.round(n)));Config.cavaRowSpacing=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{cavaRowSpacingField.applyValue(Config.cavaRowSpacing+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onCavaRowSpacingChanged(){cavaRowSpacingField.text=String(Config.cavaRowSpacing)}}
                    }
                }
                Row { visible: root.currentOtherTab === 4; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина полоски (% слота)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cavaBarWidthRatioField; width: 100; height: 28; text: Number(Config.cavaBarWidthRatio).toFixed(2); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: cavaBarWidthRatioField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.cavaBarWidthRatio;n=Math.max(0.05,Math.min(1,n));Config.cavaBarWidthRatio=n;text=Number(n).toFixed(2);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{cavaBarWidthRatioField.applyValue(Config.cavaBarWidthRatio+root.wheelDelta(wheel, 0.05));wheel.accepted=true}} Connections{target:Config;function onCavaBarWidthRatioChanged(){cavaBarWidthRatioField.text=Number(Config.cavaBarWidthRatio).toFixed(2)}}
                    }
                }
                Row { visible: root.currentOtherTab === 4; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Масштаб высоты полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cavaBarHeightScaleField; width: 100; height: 28; text: Number(Config.cavaBarHeightScale).toFixed(2); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: cavaBarHeightScaleField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.cavaBarHeightScale;n=Math.max(0.01,Math.min(2,n));Config.cavaBarHeightScale=n;text=Number(n).toFixed(2);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{cavaBarHeightScaleField.applyValue(Config.cavaBarHeightScale+root.wheelDelta(wheel, 0.05));wheel.accepted=true}} Connections{target:Config;function onCavaBarHeightScaleChanged(){cavaBarHeightScaleField.text=Number(Config.cavaBarHeightScale).toFixed(2)}}
                    }
                }

                // -------------------- CPU / RAM --------------------
                Text {
                    visible: root.currentOtherTab === 5
                    text: "CPU и RAM"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 5
                    text: "Настройки полос CPU и RAM"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Интервал обновления CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: cpuSettingsIntervalField
                        width: 100; height: 28
                        text: String(Config.cpuUpdateInterval)
                        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: cpuSettingsIntervalField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.cpuUpdateInterval=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuSettingsIntervalField.applyValue(Config.cpuUpdateInterval+root.wheelDelta(wheel, 100)); wheel.accepted=true } }
                        Connections { target: Config; function onCpuUpdateIntervalChanged() { cpuSettingsIntervalField.text = String(Config.cpuUpdateInterval) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Толщина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: cpuBarThicknessField
                        width: 100; height: 28; text: String(Config.cpuBarThickness)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: cpuBarThicknessField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarThickness; n=Math.max(1,Math.min(30,Math.round(n))); Config.cpuBarThickness=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarThicknessField.applyValue(Config.cpuBarThickness+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onCpuBarThicknessChanged() { cpuBarThicknessField.text=String(Config.cpuBarThickness) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: cpuBarWidthField
                        width: 100; height: 28; text: String(Config.cpuBarWidth)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: cpuBarWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarWidth; n=Math.max(40,Math.min(1000,Math.round(n))); Config.cpuBarWidth=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarWidthField.applyValue(Config.cpuBarWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onCpuBarWidthChanged() { cpuBarWidthField.text=String(Config.cpuBarWidth) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: cpuRowHeightField
                        width: 100; height: 28; text: String(Config.cpuRowHeight)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: cpuRowHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuRowHeight; n=Math.max(10,Math.min(60,Math.round(n))); Config.cpuRowHeight=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuRowHeightField.applyValue(Config.cpuRowHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onCpuRowHeightChanged() { cpuRowHeightField.text=String(Config.cpuRowHeight) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: cpuRowSpacingField
                        width: 100; height: 28; text: String(Config.cpuRowSpacing)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: cpuRowSpacingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuRowSpacing; n=Math.max(0,Math.min(30,Math.round(n))); Config.cpuRowSpacing=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuRowSpacingField.applyValue(Config.cpuRowSpacing+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onCpuRowSpacingChanged() { cpuRowSpacingField.text=String(Config.cpuRowSpacing) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ подписи слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuLabelPaddingField; width: 100; height: 28; text: String(Config.cpuLabelLeftPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cpuLabelPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuLabelLeftPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.cpuLabelLeftPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuLabelPaddingField.applyValue(Config.cpuLabelLeftPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuLabelLeftPaddingChanged(){ cpuLabelPaddingField.text=String(Config.cpuLabelLeftPadding) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Смещение полос слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuBarOffsetField; width: 100; height: 28; text: String(Config.cpuBarLeftOffset); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cpuBarOffsetField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarLeftOffset; n=Math.max(0,Math.min(200,Math.round(n))); Config.cpuBarLeftOffset=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarOffsetField.applyValue(Config.cpuBarLeftOffset+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuBarLeftOffsetChanged(){ cpuBarOffsetField.text=String(Config.cpuBarLeftOffset) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Радиус полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuBarRadiusField; width: 100; height: 28; text: String(Config.cpuBarRadius); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cpuBarRadiusField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarRadius; n=Math.max(0,Math.min(40,Math.round(n))); Config.cpuBarRadius=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarRadiusField.applyValue(Config.cpuBarRadius+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuBarRadiusChanged(){ cpuBarRadiusField.text=String(Config.cpuBarRadius) } }
                    }
                }

                Text { visible: root.currentOtherTab === 5; text: "График CPU"; color: Config.accent; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12) }

                Row { visible: root.currentOtherTab === 5; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина сегмента графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuGraphSlotField; width: 100; height: 28; text: String(Config.cpuGraphSegmentSlotWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cpuGraphSlotField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuGraphSegmentSlotWidth; n=Math.max(1,Math.min(20,Math.round(n))); Config.cpuGraphSegmentSlotWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuGraphSlotField.applyValue(Config.cpuGraphSegmentSlotWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuGraphSegmentSlotWidthChanged(){ cpuGraphSlotField.text=String(Config.cpuGraphSegmentSlotWidth) } }
                    }
                }

                Row { visible: root.currentOtherTab === 5; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Толщина полос графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuGraphBarWidthField; width: 100; height: 28; text: String(Config.cpuGraphBarWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: cpuGraphBarWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuGraphBarWidth; n=Math.max(1,Math.min(10,Math.round(n))); Config.cpuGraphBarWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuGraphBarWidthField.applyValue(Config.cpuGraphBarWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuGraphBarWidthChanged(){ cpuGraphBarWidthField.text=String(Config.cpuGraphBarWidth) } }
                    }
                }

                Row { visible: root.currentOtherTab === 5; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Масштаб высоты графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuGraphScaleField; width: 100; height: 28; text: Number(Config.cpuGraphScale).toFixed(2); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: cpuGraphScaleField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuGraphScale; n=Math.max(0.05,Math.min(2.0,n)); Config.cpuGraphScale=n; text=Number(n).toFixed(2); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuGraphScaleField.applyValue(Number(Config.cpuGraphScale)+root.wheelDelta(wheel, 0.05)); wheel.accepted=true } } Connections { target: Config; function onCpuGraphScaleChanged(){ cpuGraphScaleField.text=Number(Config.cpuGraphScale).toFixed(2) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
                    width: parent.width; height: 30; spacing: 8
                    CheckBox {
                        width: 210; height: 30; text: "Показывать RAM"; checked: Config.cpuShowRam
                        onToggled: { Config.cpuShowRam=checked; settings.save() }
                        contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter }
                    }
                }

                // -------------------- Network --------------------
                Text {
                    visible: root.currentOtherTab === 6
                    text: "Сеть"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 6
                    text: "Отображение сетевого трафика и общий интервал system monitor"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 6
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Интервал обновления данных (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: networkIntervalField
                        width: 100; height: 28; text: String(Config.systemMonitorInterval)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: networkIntervalField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.systemMonitorInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.systemMonitorInterval=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIntervalField.applyValue(Config.systemMonitorInterval+root.wheelDelta(wheel, 100)); wheel.accepted=true } }
                        Connections { target: Config; function onSystemMonitorIntervalChanged() { networkIntervalField.text=String(Config.systemMonitorInterval) } }
                    }
                }

                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ блока слева/справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkPaddingField; width: 100; height: 28; text: String(Config.networkHorizontalPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkHorizontalPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.networkHorizontalPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkPaddingField.applyValue(Config.networkHorizontalPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkHorizontalPaddingChanged(){ networkPaddingField.text=String(Config.networkHorizontalPadding) } }
                    }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ иконки слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkIconPaddingField; width: 100; height: 28; text: String(Config.networkIconLeftPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkIconPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkIconLeftPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.networkIconLeftPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIconPaddingField.applyValue(Config.networkIconLeftPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkIconLeftPaddingChanged(){ networkIconPaddingField.text=String(Config.networkIconLeftPadding) } }
                    }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина колонки иконки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkIconColumnWidthField; width: 100; height: 28; text: String(Config.networkIconColumnWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkIconColumnWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkIconColumnWidth; n=Math.max(16,Math.min(80,Math.round(n))); Config.networkIconColumnWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIconColumnWidthField.applyValue(Config.networkIconColumnWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkIconColumnWidthChanged(){ networkIconColumnWidthField.text=String(Config.networkIconColumnWidth) } }
                    }
                }

                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    CheckBox { width: 210; height: 30; text: "Показывать Upload"; checked: Config.networkShowUpload; onToggled: { Config.networkShowUpload=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    CheckBox { width: 210; height: 30; text: "Показывать Download"; checked: Config.networkShowDownload; onToggled: { Config.networkShowDownload=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }

                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkRowHeightField; width: 100; height: 28; text: String(Config.networkRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkRowHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkRowHeight; n=Math.max(12,Math.min(60,Math.round(n))); Config.networkRowHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkRowHeightField.applyValue(Config.networkRowHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkRowHeightChanged(){ networkRowHeightField.text=String(Config.networkRowHeight) } }
                    }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkRowSpacingField; width: 100; height: 28; text: String(Config.networkRowSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkRowSpacingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkRowSpacing; n=Math.max(0,Math.min(30,Math.round(n))); Config.networkRowSpacing=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkRowSpacingField.applyValue(Config.networkRowSpacing+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkRowSpacingChanged(){ networkRowSpacingField.text=String(Config.networkRowSpacing) } }
                    }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер иконки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkIconSizeField; width: 100; height: 28; text: String(Config.networkIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkIconSizeField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkIconSize; n=Math.max(8,Math.min(40,Math.round(n))); Config.networkIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIconSizeField.applyValue(Config.networkIconSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkIconSizeChanged(){ networkIconSizeField.text=String(Config.networkIconSize) } }
                    }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkFontSizeField; width: 100; height: 28; text: String(Config.networkValueFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkFontSizeField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkValueFontSize; n=Math.max(8,Math.min(32,Math.round(n))); Config.networkValueFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkFontSizeField.applyValue(Config.networkValueFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkValueFontSizeChanged(){ networkFontSizeField.text=String(Config.networkValueFontSize) } }
                    }
                }
                Row { visible: root.currentOtherTab === 6; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ значений справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: networkRightPaddingField; width: 100; height: 28; text: String(Config.networkRightPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: networkRightPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkRightPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.networkRightPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkRightPaddingField.applyValue(Config.networkRightPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkRightPaddingChanged(){ networkRightPaddingField.text=String(Config.networkRightPadding) } }
                    }
                }

                // -------------------- Volume --------------------
                Text {
                    visible: root.currentOtherTab === 7
                    text: "Громкость"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }
                Text {
                    visible: root.currentOtherTab === 7
                    text: "Основная полоса и дополнительные аудиопотоки"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Интервал опроса громкости (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeUpdateField; width: 100; height: 28; text: String(Config.volumeUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeUpdateField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeUpdateInterval; n=Math.max(50,Math.min(5000,Math.round(n))); Config.volumeUpdateInterval=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeUpdateField.applyValue(Config.volumeUpdateInterval+root.wheelDelta(wheel, 10)); wheel.accepted=true } } Connections { target: Config; function onVolumeUpdateIntervalChanged(){ volumeUpdateField.text=String(Config.volumeUpdateInterval) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота основной строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMainRowHeightField; width: 100; height: 28; text: String(Config.volumeMainRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeMainRowHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainRowHeight; n=Math.max(20,Math.min(80,Math.round(n))); Config.volumeMainRowHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainRowHeightField.applyValue(Config.volumeMainRowHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainRowHeightChanged(){ volumeMainRowHeightField.text=String(Config.volumeMainRowHeight) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота строк потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeStreamRowHeightField; width: 100; height: 28; text: String(Config.volumeStreamRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeStreamRowHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamRowHeight; n=Math.max(12,Math.min(60,Math.round(n))); Config.volumeStreamRowHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamRowHeightField.applyValue(Config.volumeStreamRowHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamRowHeightChanged(){ volumeStreamRowHeightField.text=String(Config.volumeStreamRowHeight) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Расстояние между потоками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeStreamSpacingField; width: 100; height: 28; text: String(Config.volumeStreamSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeStreamSpacingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamSpacing; n=Math.max(0,Math.min(20,Math.round(n))); Config.volumeStreamSpacing=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamSpacingField.applyValue(Config.volumeStreamSpacing+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamSpacingChanged(){ volumeStreamSpacingField.text=String(Config.volumeStreamSpacing) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ блока слева/справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeHorizontalPaddingField; width: 100; height: 28; text: String(Config.volumeHorizontalPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeHorizontalPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeHorizontalPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.volumeHorizontalPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeHorizontalPaddingField.applyValue(Config.volumeHorizontalPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeHorizontalPaddingChanged(){ volumeHorizontalPaddingField.text=String(Config.volumeHorizontalPadding) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ блока сверху/снизу"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeVerticalPaddingField; width: 100; height: 28; text: String(Config.volumeVerticalPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeVerticalPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeVerticalPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.volumeVerticalPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeVerticalPaddingField.applyValue(Config.volumeVerticalPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeVerticalPaddingChanged(){ volumeVerticalPaddingField.text=String(Config.volumeVerticalPadding) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина основной полосы"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMainTrackWidthField; width: 100; height: 28; text: String(Config.volumeMainTrackWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeMainTrackWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainTrackWidth; n=Math.max(40,Math.min(1000,Math.round(n))); Config.volumeMainTrackWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainTrackWidthField.applyValue(Config.volumeMainTrackWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainTrackWidthChanged(){ volumeMainTrackWidthField.text=String(Config.volumeMainTrackWidth) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота полосы громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMainTrackHeightField; width: 100; height: 28; text: String(Config.volumeMainTrackHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeMainTrackHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainTrackHeight; n=Math.max(1,Math.min(30,Math.round(n))); Config.volumeMainTrackHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainTrackHeightField.applyValue(Config.volumeMainTrackHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainTrackHeightChanged(){ volumeMainTrackHeightField.text=String(Config.volumeMainTrackHeight) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота полос потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeStreamTrackHeightField; width: 100; height: 28; text: String(Config.volumeStreamTrackHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeStreamTrackHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamTrackHeight; n=Math.max(1,Math.min(20,Math.round(n))); Config.volumeStreamTrackHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamTrackHeightField.applyValue(Config.volumeStreamTrackHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamTrackHeightChanged(){ volumeStreamTrackHeightField.text=String(Config.volumeStreamTrackHeight) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Смещение основной полосы Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMainTrackOffsetField; width: 100; height: 28; text: String(Config.volumeMainTrackOffsetY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: volumeMainTrackOffsetField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainTrackOffsetY; n=Math.max(-30,Math.min(30,Math.round(n))); Config.volumeMainTrackOffsetY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainTrackOffsetField.applyValue(Config.volumeMainTrackOffsetY+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainTrackOffsetYChanged(){ volumeMainTrackOffsetField.text=String(Config.volumeMainTrackOffsetY) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Смещение полос потоков Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeStreamTrackOffsetField; width: 100; height: 28; text: String(Config.volumeStreamTrackOffsetY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: volumeStreamTrackOffsetField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamTrackOffsetY; n=Math.max(-20,Math.min(20,Math.round(n))); Config.volumeStreamTrackOffsetY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamTrackOffsetField.applyValue(Config.volumeStreamTrackOffsetY+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamTrackOffsetYChanged(){ volumeStreamTrackOffsetField.text=String(Config.volumeStreamTrackOffsetY) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина иконки громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMainIconWidthField; width: 100; height: 28; text: String(Config.volumeMainIconWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeMainIconWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainIconWidth; n=Math.max(16,Math.min(80,Math.round(n))); Config.volumeMainIconWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainIconWidthField.applyValue(Config.volumeMainIconWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainIconWidthChanged(){ volumeMainIconWidthField.text=String(Config.volumeMainIconWidth) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер текста потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeStreamLabelFontField; width: 100; height: 28; text: String(Config.volumeStreamLabelFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeStreamLabelFontField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamLabelFontSize; n=Math.max(8,Math.min(32,Math.round(n))); Config.volumeStreamLabelFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamLabelFontField.applyValue(Config.volumeStreamLabelFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamLabelFontSizeChanged(){ volumeStreamLabelFontField.text=String(Config.volumeStreamLabelFontSize) } }
                    }
                }
                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Радиус полос громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeTrackRadiusField; width: 100; height: 28; text: String(Config.volumeTrackRadius); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: volumeTrackRadiusField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeTrackRadius; n=Math.max(0,Math.min(20,Math.round(n))); Config.volumeTrackRadius=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeTrackRadiusField.applyValue(Config.volumeTrackRadius+root.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeTrackRadiusChanged(){ volumeTrackRadiusField.text=String(Config.volumeTrackRadius) } }
                    }
                }

                Row { visible: root.currentOtherTab === 7; width: parent.width; height: 30; spacing: 8
                    CheckBox { width: 210; height: 30; text: "Показывать дополнительные потоки"; checked: Config.volumeShowStreams; onToggled: { Config.volumeShowStreams=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }

                Text {
                    visible: root.currentOtherTab === 1
                    text: "Таймеры"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 1
                    text: "Дефолтные значения кнопок таймера, в минутах"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Column {
                    visible: root.currentOtherTab === 1
                    width: parent.width
                    spacing: 5

                    Repeater {
                        model: settings.timerPresetDefaults
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

                            TextField {
                                id: timerPresetField
                                width: 100
                                height: 28
                                property int presetIndex: index
                                text: String(settings.timerPresetDefaults[presetIndex] === undefined ? 5 : settings.timerPresetDefaults[presetIndex])
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
                                    color: Config.background
                                    border.color: timerPresetField.activeFocus ? Config.accent : Config.baseColor
                                    border.width: 1
                                    radius: 4
                                }

                                function applyValue() {
                                    var n = Number(text)
                                    var values = settings.timerPresetDefaults || []
                                    if (!isFinite(n) || presetIndex < 0 || presetIndex >= values.length) {
                                        text = String(values[presetIndex] === undefined ? 5 : values[presetIndex])
                                        return
                                    }
                                    n = Math.max(0, Math.round(n))
                                    settings.setTimerPresetDefault(presetIndex, n)
                                    text = String(n)
                                }

                                onEditingFinished: applyValue()

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    hoverEnabled: true
                                    onWheel: wheel => {
                                        settings.adjustTimerPresetDefault(timerPresetField.presetIndex, root.wheelDelta(wheel, 1))
                                        timerPresetField.text = String(settings.timerPresetDefaults[timerPresetField.presetIndex])
                                        wheel.accepted = true
                                    }
                                }

                                Connections {
                                    target: settings
                                    function onTimerPresetsChanged() {
                                        if (timerPresetField.presetIndex < (settings.timerPresetDefaults || []).length)
                                            timerPresetField.text = String(settings.timerPresetDefaults[timerPresetField.presetIndex])
                                    }
                                }
                            }

                            Rectangle {
                                width: 70
                                height: 28
                                radius: 4
                                color: removeArea.containsMouse ? Config.baseColor : Config.background
                                border.color: Config.baseColor
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
                                    onClicked: settings.removeTimerPreset(index)
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 151
                        height: 30
                        radius: 4
                        color: addArea.containsMouse ? Config.accent : Config.background
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
                            onClicked: settings.addTimerPreset(5)
                        }
                    }
                }


                Text {
                    visible: root.currentOtherTab === 1
                    text: "Таймеры: оформление и поведение"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Минимальная высота блока таймеров"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerMinHeightField; width: 100; height: 28; text: String(Config.timerMinHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerMinHeight; n=Math.max(30,Math.min(1000,Math.round(n / 1) * 1)); Config.timerMinHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerMinHeightField.applyValue(Config.timerMinHeight+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Шаг колеса таймера"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerWheelStepField; width: 100; height: 28; text: String(Config.timerWheelStep); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerWheelStep; n=Math.max(1,Math.min(60,Math.round(n / 1) * 1)); Config.timerWheelStep=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerWheelStepField.applyValue(Config.timerWheelStep+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Ширина комментария"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerCommentWidthField; width: 100; height: 28; text: String(Config.timerCommentWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentWidth; n=Math.max(40,Math.min(300,Math.round(n / 1) * 1)); Config.timerCommentWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerCommentWidthField.applyValue(Config.timerCommentWidth+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Максимальная длина комментария"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerCommentMaxLengthField; width: 100; height: 28; text: String(Config.timerCommentMaxLength); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentMaxLength; n=Math.max(1,Math.min(30,Math.round(n / 1) * 1)); Config.timerCommentMaxLength=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerCommentMaxLengthField.applyValue(Config.timerCommentMaxLength+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Отступ комментария до отсчёта"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerCommentGapField; width: 100; height: 28; text: String(Config.timerCommentGap); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentGap; n=Math.max(0,Math.min(40,Math.round(n / 1) * 1)); Config.timerCommentGap=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerCommentGapField.applyValue(Config.timerCommentGap+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Верхний отступ таймеров"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerRowTopField; width: 100; height: 28; text: String(Config.timerRowTopMargin); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowTopMargin; n=Math.max(0,Math.min(50,Math.round(n / 1) * 1)); Config.timerRowTopMargin=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowTopField.applyValue(Config.timerRowTopMargin+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Правый отступ таймеров"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerRowRightField; width: 100; height: 28; text: String(Config.timerRowRightMargin); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowRightMargin; n=Math.max(0,Math.min(50,Math.round(n / 1) * 1)); Config.timerRowRightMargin=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowRightField.applyValue(Config.timerRowRightMargin+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Анимация появления кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerFadeField; width: 100; height: 28; text: String(Config.timerButtonFadeDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonFadeDuration=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerFadeField.applyValue(Config.timerButtonFadeDuration+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Сдвиг кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerSlideField; width: 100; height: 28; text: String(Config.timerButtonSlideDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonSlideDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonSlideDuration=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerSlideField.applyValue(Config.timerButtonSlideDuration+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Исчезновение иконки (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerIconFadeField; width: 100; height: 28; text: String(Config.timerButtonIconFadeDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonIconFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonIconFadeDuration=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerIconFadeField.applyValue(Config.timerButtonIconFadeDuration+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 3
                    text: "Погода"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 3
                    text: "Количество элементов, размеры и положение элементов погодных блоков. При ошибке API используется заданная пауза перед новым запросом."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Размер иконки текущей погоды"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherIconSizeField; width: 100; height: 28; text: String(Config.weatherIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherIconSize; n=Math.max(16,Math.min(128,Math.round(n / 1) * 1)); Config.weatherIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherIconSizeField.applyValue(Config.weatherIconSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Размер стрелки ветра"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherArrowSizeField; width: 100; height: 28; text: String(Config.weatherArrowSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherArrowSize; n=Math.max(8,Math.min(64,Math.round(n / 1) * 1)); Config.weatherArrowSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherArrowSizeField.applyValue(Config.weatherArrowSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Смещение стрелки ветра по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherArrowYField; width: 100; height: 28; text: String(Config.weatherArrowYOffset); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherArrowYOffset; n=Math.max(-40,Math.min(40,Math.round(n / 1) * 1)); Config.weatherArrowYOffset=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherArrowYField.applyValue(Config.weatherArrowYOffset+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Зазор стрелки до скорости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherWindGapField; width: 100; height: 28; text: String(Config.weatherWindArrowGap); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherWindArrowGap; n=Math.max(-20,Math.min(40,Math.round(n / 1) * 1)); Config.weatherWindArrowGap=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherWindGapField.applyValue(Config.weatherWindArrowGap+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Количество часов"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherHourlyCountField; width: 100; height: 28; text: String(Config.weatherHourlyCount); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherHourlyCount; n=Math.max(1,Math.min(12,Math.round(n / 1) * 1)); Config.weatherHourlyCount=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherHourlyCountField.applyValue(Config.weatherHourlyCount+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Количество дней"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherDailyCountField; width: 100; height: 28; text: String(Config.weatherDailyCount); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherDailyCount; n=Math.max(1,Math.min(10,Math.round(n / 1) * 1)); Config.weatherDailyCount=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherDailyCountField.applyValue(Config.weatherDailyCount+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Верхний отступ погодных списков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherPaddingField; width: 100; height: 28; text: String(Config.weatherListTopPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherListTopPadding; n=Math.max(0,Math.min(40,Math.round(n / 1) * 1)); Config.weatherListTopPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherPaddingField.applyValue(Config.weatherListTopPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Text {
                    visible: root.currentOtherTab === 3
                    text: "Дополнительная геометрия текущей погоды"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Y картинки текущей погоды"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherIconYField; width: 100; height: 28; text: String(Config.weatherIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: weatherIconYField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherIconY;n=Math.max(-100,Math.min(100,Math.round(n)));Config.weatherIconY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherIconYField.applyValue(Config.weatherIconY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherIconYChanged(){weatherIconYField.text=String(Config.weatherIconY)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "X колонки ветра"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherWindXField; width: 100; height: 28; text: String(Config.weatherWindColumnX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindXField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindColumnX;n=Math.max(0,Math.min(500,Math.round(n)));Config.weatherWindColumnX=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindXField.applyValue(Config.weatherWindColumnX+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindColumnXChanged(){weatherWindXField.text=String(Config.weatherWindColumnX)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер текста описания"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherDescSizeField; width: 100; height: 28; text: String(Config.weatherDescriptionFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherDescSizeField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherDescriptionFontSize;n=Math.max(6,Math.min(48,Math.round(n)));Config.weatherDescriptionFontSize=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherDescSizeField.applyValue(Config.weatherDescriptionFontSize+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherDescriptionFontSizeChanged(){weatherDescSizeField.text=String(Config.weatherDescriptionFontSize)}}
                    }
                }

                Text { visible: root.currentOtherTab === 3; text: "Дополнительная геометрия и типографика"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура: ширина колонки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherTempColumnWidthField; width: 100; height: 28; text: String(Config.weatherTempColumnWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherTempColumnWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherTempColumnWidth;n=Math.max(40,Math.min(200,Math.round(n)));Config.weatherTempColumnWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherTempColumnWidthField.applyValue(Config.weatherTempColumnWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherTempColumnWidthChanged(){weatherTempColumnWidthField.text=String(Config.weatherTempColumnWidth)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура: X / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherTempXField; width: 70; height: 28; text: String(Config.weatherTempX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherTempXField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherTempX;n=Math.max(0,Math.min(200,Math.round(n)));Config.weatherTempX=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherTempXField.applyValue(Config.weatherTempX+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherTempXChanged(){weatherTempXField.text=String(Config.weatherTempX)}}
                    }
                    TextField { id: weatherTempWidthField; width: 70; height: 28; text: String(Config.weatherTempWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherTempWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherTempWidth;n=Math.max(20,Math.min(200,Math.round(n)));Config.weatherTempWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherTempWidthField.applyValue(Config.weatherTempWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherTempWidthChanged(){weatherTempWidthField.text=String(Config.weatherTempWidth)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Комфорт: Y / высота"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherComfortYField; width: 70; height: 28; text: String(Config.weatherComfortY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: weatherComfortYField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherComfortY;n=Math.max(-20,Math.min(100,Math.round(n)));Config.weatherComfortY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherComfortYField.applyValue(Config.weatherComfortY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherComfortYChanged(){weatherComfortYField.text=String(Config.weatherComfortY)}}
                    }
                    TextField { id: weatherComfortHeightField; width: 70; height: 28; text: String(Config.weatherComfortHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherComfortHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherComfortHeight;n=Math.max(10,Math.min(100,Math.round(n)));Config.weatherComfortHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherComfortHeightField.applyValue(Config.weatherComfortHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherComfortHeightChanged(){weatherComfortHeightField.text=String(Config.weatherComfortHeight)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ветер: X / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherWindColumnXExtraField; width: 70; height: 28; text: String(Config.weatherWindColumnX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindColumnXExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindColumnX;n=Math.max(0,Math.min(500,Math.round(n)));Config.weatherWindColumnX=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindColumnXExtraField.applyValue(Config.weatherWindColumnX+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindColumnXChanged(){weatherWindColumnXExtraField.text=String(Config.weatherWindColumnX)}}
                    }
                    TextField { id: weatherWindColumnWidthExtraField; width: 70; height: 28; text: String(Config.weatherWindColumnWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindColumnWidthExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindColumnWidth;n=Math.max(60,Math.min(300,Math.round(n)));Config.weatherWindColumnWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindColumnWidthExtraField.applyValue(Config.weatherWindColumnWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindColumnWidthChanged(){weatherWindColumnWidthExtraField.text=String(Config.weatherWindColumnWidth)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Стрелка: ширина / высота"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherWindArrowWidthField; width: 70; height: 28; text: String(Config.weatherWindArrowWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindArrowWidthField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindArrowWidth;n=Math.max(8,Math.min(50,Math.round(n)));Config.weatherWindArrowWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindArrowWidthField.applyValue(Config.weatherWindArrowWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindArrowWidthChanged(){weatherWindArrowWidthField.text=String(Config.weatherWindArrowWidth)}}
                    }
                    TextField { id: weatherWindArrowHeightField; width: 70; height: 28; text: String(Config.weatherWindArrowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindArrowHeightField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindArrowHeight;n=Math.max(15,Math.min(80,Math.round(n)));Config.weatherWindArrowHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindArrowHeightField.applyValue(Config.weatherWindArrowHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindArrowHeightChanged(){weatherWindArrowHeightField.text=String(Config.weatherWindArrowHeight)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Скорость ветра: X / Y / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherWindSpeedXExtraField; width: 62; height: 28; text: String(Config.weatherWindSpeedX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindSpeedXExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindSpeedX;n=Math.max(0,Math.min(250,Math.round(n)));Config.weatherWindSpeedX=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindSpeedXExtraField.applyValue(Config.weatherWindSpeedX+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindSpeedXChanged(){weatherWindSpeedXExtraField.text=String(Config.weatherWindSpeedX)}}
                    }
                    TextField { id: weatherWindSpeedYExtraField; width: 62; height: 28; text: String(Config.weatherWindSpeedY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: weatherWindSpeedYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindSpeedY;n=Math.max(-20,Math.min(80,Math.round(n)));Config.weatherWindSpeedY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindSpeedYExtraField.applyValue(Config.weatherWindSpeedY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindSpeedYChanged(){weatherWindSpeedYExtraField.text=String(Config.weatherWindSpeedY)}}
                    }
                    TextField { id: weatherWindSpeedWidthExtraField; width: 62; height: 28; text: String(Config.weatherWindSpeedWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindSpeedWidthExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindSpeedWidth;n=Math.max(20,Math.min(150,Math.round(n)));Config.weatherWindSpeedWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindSpeedWidthExtraField.applyValue(Config.weatherWindSpeedWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindSpeedWidthChanged(){weatherWindSpeedWidthExtraField.text=String(Config.weatherWindSpeedWidth)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ед. ветра: X / Y / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherWindUnitXExtraField; width: 62; height: 28; text: String(Config.weatherWindUnitX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindUnitXExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindUnitX;n=Math.max(0,Math.min(300,Math.round(n)));Config.weatherWindUnitX=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindUnitXExtraField.applyValue(Config.weatherWindUnitX+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindUnitXChanged(){weatherWindUnitXExtraField.text=String(Config.weatherWindUnitX)}}
                    }
                    TextField { id: weatherWindUnitYExtraField; width: 62; height: 28; text: String(Config.weatherWindUnitY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: weatherWindUnitYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindUnitY;n=Math.max(-20,Math.min(80,Math.round(n)));Config.weatherWindUnitY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindUnitYExtraField.applyValue(Config.weatherWindUnitY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindUnitYChanged(){weatherWindUnitYExtraField.text=String(Config.weatherWindUnitY)}}
                    }
                    TextField { id: weatherWindUnitWidthExtraField; width: 62; height: 28; text: String(Config.weatherWindUnitWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherWindUnitWidthExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherWindUnitWidth;n=Math.max(10,Math.min(120,Math.round(n)));Config.weatherWindUnitWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherWindUnitWidthExtraField.applyValue(Config.weatherWindUnitWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherWindUnitWidthChanged(){weatherWindUnitWidthExtraField.text=String(Config.weatherWindUnitWidth)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Давление: ширина / шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherPressureWidthExtraField; width: 70; height: 28; text: String(Config.weatherPressureValueWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherPressureWidthExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherPressureValueWidth;n=Math.max(20,Math.min(180,Math.round(n)));Config.weatherPressureValueWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherPressureWidthExtraField.applyValue(Config.weatherPressureValueWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherPressureValueWidthChanged(){weatherPressureWidthExtraField.text=String(Config.weatherPressureValueWidth)}}
                    }
                    TextField { id: weatherPressureFontExtraField; width: 70; height: 28; text: String(Config.weatherPressureFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherPressureFontExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherPressureFontSize;n=Math.max(8,Math.min(48,Math.round(n)));Config.weatherPressureFontSize=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherPressureFontExtraField.applyValue(Config.weatherPressureFontSize+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherPressureFontSizeChanged(){weatherPressureFontExtraField.text=String(Config.weatherPressureFontSize)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ед. давления: X / Y / шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherPressureUnitXExtraField; width: 60; height: 28; text: String(Config.weatherPressureUnitX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherPressureUnitXExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherPressureUnitX;n=Math.max(0,Math.min(300,Math.round(n)));Config.weatherPressureUnitX=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherPressureUnitXExtraField.applyValue(Config.weatherPressureUnitX+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherPressureUnitXChanged(){weatherPressureUnitXExtraField.text=String(Config.weatherPressureUnitX)}}
                    }
                    TextField { id: weatherPressureUnitYExtraField; width: 60; height: 28; text: String(Config.weatherPressureUnitY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: weatherPressureUnitYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherPressureUnitY;n=Math.max(-20,Math.min(80,Math.round(n)));Config.weatherPressureUnitY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherPressureUnitYExtraField.applyValue(Config.weatherPressureUnitY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherPressureUnitYChanged(){weatherPressureUnitYExtraField.text=String(Config.weatherPressureUnitY)}}
                    }
                    TextField { id: weatherPressureUnitFontExtraField; width: 60; height: 28; text: String(Config.weatherPressureUnitFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherPressureUnitFontExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherPressureUnitFontSize;n=Math.max(6,Math.min(30,Math.round(n)));Config.weatherPressureUnitFontSize=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherPressureUnitFontExtraField.applyValue(Config.weatherPressureUnitFontSize+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherPressureUnitFontSizeChanged(){weatherPressureUnitFontExtraField.text=String(Config.weatherPressureUnitFontSize)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Описание: высота"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherDescriptionHeightExtraField; width: 100; height: 28; text: String(Config.weatherDescriptionHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherDescriptionHeightExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherDescriptionHeight;n=Math.max(8,Math.min(40,Math.round(n)));Config.weatherDescriptionHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherDescriptionHeightExtraField.applyValue(Config.weatherDescriptionHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherDescriptionHeightChanged(){weatherDescriptionHeightExtraField.text=String(Config.weatherDescriptionHeight)}}
                    }
                }
                Text { visible: root.currentOtherTab === 3; text: "Почасовая / дневная типографика"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "День: высота / шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherDayHeightExtraField; width: 70; height: 28; text: String(Config.weatherListDayHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherDayHeightExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListDayHeight;n=Math.max(10,Math.min(40,Math.round(n)));Config.weatherListDayHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherDayHeightExtraField.applyValue(Config.weatherListDayHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListDayHeightChanged(){weatherDayHeightExtraField.text=String(Config.weatherListDayHeight)}}
                    }
                    TextField { id: weatherDayFontExtraField; width: 70; height: 28; text: String(Config.weatherListDayFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherDayFontExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListDayFontSize;n=Math.max(6,Math.min(32,Math.round(n)));Config.weatherListDayFontSize=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherDayFontExtraField.applyValue(Config.weatherListDayFontSize+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListDayFontSizeChanged(){weatherDayFontExtraField.text=String(Config.weatherListDayFontSize)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Иконка списка: ширина / высота / Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherListIconWidthExtraField; width: 58; height: 28; text: String(Config.weatherListIconWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListIconWidthExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListIconWidth;n=Math.max(16,Math.min(90,Math.round(n)));Config.weatherListIconWidth=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListIconWidthExtraField.applyValue(Config.weatherListIconWidth+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListIconWidthChanged(){weatherListIconWidthExtraField.text=String(Config.weatherListIconWidth)}}
                    }
                    TextField { id: weatherListIconHeightExtraField; width: 58; height: 28; text: String(Config.weatherListIconHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListIconHeightExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListIconHeight;n=Math.max(16,Math.min(100,Math.round(n)));Config.weatherListIconHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListIconHeightExtraField.applyValue(Config.weatherListIconHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListIconHeightChanged(){weatherListIconHeightExtraField.text=String(Config.weatherListIconHeight)}}
                    }
                    TextField { id: weatherListIconYExtraField; width: 58; height: 28; text: String(Config.weatherListIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.background; border.color: weatherListIconYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListIconY;n=Math.max(0,Math.min(120,Math.round(n)));Config.weatherListIconY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListIconYExtraField.applyValue(Config.weatherListIconY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListIconYChanged(){weatherListIconYExtraField.text=String(Config.weatherListIconY)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура списка: Y час / Y день / высота"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherListHourlyYExtraField; width: 58; height: 28; text: String(Config.weatherListHourlyTempY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListHourlyYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListHourlyTempY;n=Math.max(0,Math.min(150,Math.round(n)));Config.weatherListHourlyTempY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListHourlyYExtraField.applyValue(Config.weatherListHourlyTempY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListHourlyTempYChanged(){weatherListHourlyYExtraField.text=String(Config.weatherListHourlyTempY)}}
                    }
                    TextField { id: weatherListDailyYExtraField; width: 58; height: 28; text: String(Config.weatherListDailyTempY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListDailyYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListDailyTempY;n=Math.max(0,Math.min(150,Math.round(n)));Config.weatherListDailyTempY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListDailyYExtraField.applyValue(Config.weatherListDailyTempY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListDailyTempYChanged(){weatherListDailyYExtraField.text=String(Config.weatherListDailyTempY)}}
                    }
                    TextField { id: weatherListTempHeight2Field; width: 58; height: 28; text: String(Config.weatherListTempHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListTempHeight2Field.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListTempHeight;n=Math.max(10,Math.min(50,Math.round(n)));Config.weatherListTempHeight=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListTempHeight2Field.applyValue(Config.weatherListTempHeight+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListTempHeightChanged(){weatherListTempHeight2Field.text=String(Config.weatherListTempHeight)}}
                    }
                }
                Row { visible: root.currentOtherTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Нижняя температура: Y / шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherListLowYExtraField; width: 70; height: 28; text: String(Config.weatherListLowTempY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListLowYExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListLowTempY;n=Math.max(0,Math.min(180,Math.round(n)));Config.weatherListLowTempY=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListLowYExtraField.applyValue(Config.weatherListLowTempY+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListLowTempYChanged(){weatherListLowYExtraField.text=String(Config.weatherListLowTempY)}}
                    }
                    TextField { id: weatherListLowFontExtraField; width: 70; height: 28; text: String(Config.weatherListLowTempFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.background; border.color: weatherListLowFontExtraField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.weatherListLowTempFontSize;n=Math.max(6,Math.min(32,Math.round(n)));Config.weatherListLowTempFontSize=n;text=String(n);settings.save()} onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{weatherListLowFontExtraField.applyValue(Config.weatherListLowTempFontSize+root.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onWeatherListLowTempFontSizeChanged(){weatherListLowFontExtraField.text=String(Config.weatherListLowTempFontSize)}}
                    }
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Настройки интерфейса настроек"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Отдельный шрифт, размер текста и внутренние отступы самого окна настроек."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "Шрифт настроек"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: settingsFontField
                        width: 160; height: 30
                        text: Config.settingsFont
                        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle { color: Config.background; border.color: settingsFontField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        onEditingFinished: { Config.settingsFont = text.trim() || Config.settingsFont; text = Config.settingsFont; settings.save() }
                        Connections { target: Config; function onSettingsFontChanged() { settingsFontField.text = Config.settingsFont } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "Размер шрифта настроек"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: settingsFontSizeField
                        width: 100; height: 30
                        text: String(Config.settingsFontSize)
                        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                        horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: settingsFontSizeField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.settingsFontSize; n=Math.max(6,Math.min(32,Math.round(n))); Config.settingsFontSize=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsFontSizeField.applyValue(Config.settingsFontSize+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onSettingsFontSizeChanged() { settingsFontSizeField.text = String(Config.settingsFontSize) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "Внутренний отступ"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: settingsPaddingField
                        width: 100; height: 30
                        text: String(Config.settingsPadding)
                        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                        horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: settingsPaddingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.settingsPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.settingsPadding=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsPaddingField.applyValue(Config.settingsPadding+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onSettingsPaddingChanged() { settingsPaddingField.text = String(Config.settingsPadding) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 34
                    spacing: 8
                    Text { width: 210; text: "Расстояние между элементами"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField {
                        id: settingsSpacingField
                        width: 100; height: 30
                        text: String(Config.settingsSpacing)
                        color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                        font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                        horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.background; border.color: settingsSpacingField.activeFocus ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.settingsSpacing; n=Math.max(0,Math.min(40,Math.round(n))); Config.settingsSpacing=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsSpacingField.applyValue(Config.settingsSpacing+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                        Connections { target: Config; function onSettingsSpacingChanged() { settingsSpacingField.text = String(Config.settingsSpacing) } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Окно настроек"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Координаты и размеры окна настроек"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 18
                    spacing: 6

                    Item { width: 0; height: 18 }

                    Repeater {
                        model: ["X", "Y", "Width", "Height"]
                        delegate: Text {
                            width: 76
                            height: 18
                            text: modelData
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 30
                    spacing: 6

                    Repeater {
                        model: [0, 1, 2, 3]
                        delegate: TextField {
                            id: settingsGeometryField
                            width: 76
                            height: 28
                            property int fieldIndex: modelData
                            text: String(settings.settingsGeometry[fieldIndex])
                            color: Config.text
                            selectionColor: Config.accent
                            selectedTextColor: Config.black
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            activeFocusOnTab: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            background: Rectangle {
                                color: Config.background
                                border.color: settingsGeometryField.activeFocus ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: 4
                            }
                            onEditingFinished: {
                                var a = (settings.settingsGeometry || [640, 40, 560, 850]).slice()
                                var n = Number(text)
                                if (!isNaN(n)) {
                                    if (fieldIndex === 2) n = Math.max(320, Math.round(n))
                                    if (fieldIndex === 3) n = Math.max(240, Math.round(n))
                                    a[fieldIndex] = Math.round(n)
                                    settings.settingsGeometry = a
                                    settings.save()
                                    text = String(a[fieldIndex])
                                } else {
                                    text = String(settings.settingsGeometry[fieldIndex])
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                onWheel: wheel => {
                                    settings.adjustSettingsGeometry(settingsGeometryField.fieldIndex, root.wheelDelta(wheel, 1))
                                    settingsGeometryField.text = String(settings.settingsGeometry[settingsGeometryField.fieldIndex])
                                    wheel.accepted = true
                                }
                            }
                            Connections {
                                target: settings
                                function onSettingsGeometryChanged() {
                                    settingsGeometryField.text = String(settings.settingsGeometry[settingsGeometryField.fieldIndex])
                                }
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: ["X", "Y", "Width", "Height"][fieldIndex]
                            ToolTip.delay: 500
                        }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Изменения применяются и сохраняются сразу. Для X/Y/Width/Height можно использовать колесо мыши с шагом 1."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(9)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Профили"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 8
                    text: "Сохраняй несколько вариантов всей конфигурации и переключайся между ними без ручной перенастройки."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 30
                    spacing: 8

                    TextField {
                        id: profileNameField
                        width: 180
                        height: 28
                        placeholderText: "Имя профиля"
                        text: settings.activeProfile
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle {
                            color: Config.background
                            border.color: profileNameField.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: 4
                        }
                                            onAccepted: settings.saveProfile(text)
                    }


                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 30
                    spacing: 8

                    ComboBox {
                        id: profileCombo
                        width: 230
                        height: 30
                        model: profileModel
                        textRole: "name"
                        valueRole: "name"
                        displayText: currentIndex >= 0 ? currentText : "Профили не созданы"
                        contentItem: Text {
                            text: profileCombo.displayText
                            color: Config.text
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                            elide: Text.ElideRight
                        }
                        background: Rectangle {
                            color: Config.background
                            border.color: profileCombo.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: Config.frameRadius
                        }
                        currentIndex: {
                            var names = settings.profileNames()
                            var idx = names.indexOf(settings.activeProfile)
                            return idx >= 0 ? idx : (count > 0 ? 0 : -1)
                        }
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                    }

                    Button {
                        width: 95
                        height: 28
                        text: "Загрузить"
                        enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                        contentItem: Text { text: parent.text; color: Config.black; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: Config.accent; border.color: Config.baseColor; border.width: 1; radius: Config.radius }
                        onClicked: settings.loadProfile(profileCombo.currentText)
                    }

                    Button {
                        width: 95
                        height: 28
                        text: "Удалить"
                        enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                        contentItem: Text { text: parent.text; color: Config.black; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: Config.accent; border.color: Config.baseColor; border.width: 1; radius: Config.radius }
                        onClicked: settings.deleteProfile(profileCombo.currentText)
                    }
                }

                Text {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    text: settings.activeProfile ? "Текущий профиль: " + settings.activeProfile : "Текущий профиль: по умолчанию"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row {
                    visible: root.currentOtherTab === 8
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text {
                        width: parent.width - 38
                        text: "Сбросить все настройки"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        verticalAlignment: Text.AlignVCenter
                    }
                    SettingsResetButton {
                        tooltip: "Сбросить все параметры"
                        onClicked: settings.resetAllSettings()
                    }
                }
            }
        }
            }
        }

        // -------------------- Modules --------------------
        Flickable {
            id: modulesFlick
            visible: root.currentTab === 0
            width: parent.width
            height: parent.height - y
            contentWidth: width
            contentHeight: modulesColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: modulesColumn
                width: modulesFlick.width - 12
                spacing: 8

                Row {
                    width: parent.width
                    height: 30
                    Text {
                        width: parent.width - 38
                        text: "Модули и их расположение"
                        color: Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(15)
                        verticalAlignment: Text.AlignVCenter
                    }
                    SettingsResetButton {
                        tooltip: "Сбросить модули"
                        onClicked: settings.resetModules()
                    }
                }

                Row {
                    width: parent.width
                    height: 50
                    spacing: 10

                    Rectangle {
                        id: layoutEditButton
                        width: 270
                        height: 46
                        radius: Config.frameRadius
                        color: layoutEditMouse.containsMouse ? Config.text : Config.accent
                        border.color: Config.baseColor
                        border.width: Math.max(1, Config.frameBorderWidth)

                        Text {
                            anchors.fill: parent
                            text: "УМНОЕ РЕДАКТИРОВАНИЕ"
                            color: layoutEditMouse.containsMouse ? Config.black : Config.black
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: layoutEditMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.layoutEditRequested()
                        }
                    }

                    Text {
                        width: parent.width - 280
                        height: 46
                        text: "Скрывает окно настроек и позволяет перетаскивать видимые блоки мышью.
Esc — завершить редактирование и вернуться сюда."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Row {
                    width: parent.width
                    height: 18
                    spacing: 6

                    Item { width: 130; height: 18 }

                    Repeater {
                        model: ["X", "Y", "Width", "Height"]
                        delegate: Text {
                            width: 70
                            height: 18
                            text: modelData
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Repeater {
                    model: settings.moduleNames

                    delegate: Row {
                        id: moduleRow
                        width: parent.width
                        height: 30
                        spacing: 6
                        property string moduleName: modelData

                        CheckBox {
                            id: enabledBox
                            width: 130
                            height: 30
                            text: settings.moduleLabels[moduleRow.moduleName]
                            checked: settings[moduleRow.moduleName]
                            onToggled: {
                                settings[moduleRow.moduleName] = checked
                                settings.save()
                            }
                            contentItem: Text {
                                text: parent.text
                                color: Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(11)
                                leftPadding: parent.indicator.width + 5
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        Repeater {
                            model: ["X", "Y", "Width", "Height"]

                            delegate: TextField {
                                id: geometryField
                                width: 70
                                height: 28
                                text: String(settings.geometry[moduleRow.moduleName][index])
                                color: Config.text
                                selectionColor: Config.accent
                                selectedTextColor: Config.black
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                horizontalAlignment: Text.AlignHCenter
                                activeFocusOnTab: true
                                inputMethodHints: Qt.ImhDigitsOnly

                                background: Rectangle {
                                    color: Config.background
                                    border.color: geometryField.activeFocus ? Config.accent : Config.baseColor
                                    border.width: 1
                                    radius: 4
                                }

                                onEditingFinished: {
                                    var g = Object.assign({}, settings.geometry)
                                    var a = (g[moduleRow.moduleName] || [0, 0, 100, 100]).slice()
                                    var n = Number(text)
                                    if (!isNaN(n)) {
                                        if (index >= 2) n = Math.max(1, n)
                                        a[index] = n
                                        g[moduleRow.moduleName] = a
                                        settings.geometry = g
                                        settings.save()
                                        text = String(n)
                                    } else {
                                        text = String(settings.geometry[moduleRow.moduleName][index])
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    hoverEnabled: true
                                    onWheel: wheel => {
                                        var delta = root.wheelDelta(wheel, 1)
                                        settings.adjustGeometry(moduleRow.moduleName, index, delta)
                                        geometryField.text = String(settings.geometry[moduleRow.moduleName][index])
                                        wheel.accepted = true
                                    }
                                }

                                Connections {
                                    target: settings
                                    function onGeometryChanged() {
                                        geometryField.text = String(settings.geometry[moduleRow.moduleName][index])
                                    }
                                }

                                ToolTip.visible: hovered
                                ToolTip.text: ["X", "Y", "Width", "Height"][index]
                                ToolTip.delay: 500
                            }
                        }
                    }
                }
            }
        }

        // -------------------- Colors --------------------
        Flickable {
            id: colorsFlick
            visible: root.currentTab === 1
            width: parent.width
            height: parent.height - y
            contentWidth: width
            contentHeight: colorsColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: colorsColumn
                width: colorsFlick.width - 12
                spacing: 8

                Column {
                    width: parent.width
                    spacing: 7

                    Text {
                        text: "Цвета"
                        color: Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(15)
                    }

                    Text {
                        text: "Тема" + (settings.isCurrentThemeModified() ? " (Changed)" : "")
                        color: settings.isCurrentThemeModified() ? Config.tempWarm : Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                    }

                    ComboBox {
                        id: themeCombo
                        visible: !settings.isCurrentThemeModified()
                        width: parent.width
                        height: 32
                        model: settings.themeNames
                        currentIndex: Math.max(0, settings.themeNames.indexOf(settings.activeTheme))
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        onActivated: {
                            var name = currentText
                            if (name && name !== settings.activeTheme)
                                settings.applyTheme(name)
                        }
                        background: Rectangle {
                            color: Config.background
                            border.color: themeCombo.activeFocus ? Config.accent : Config.baseColor
                            border.width: 1
                            radius: Config.frameRadius
                        }
                        contentItem: Text {
                            leftPadding: 10
                            rightPadding: 30
                            text: themeCombo.currentText
                            color: Config.text
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        indicator: Text {
                            x: themeCombo.width - width - 10
                            y: (themeCombo.height - height) / 2
                            text: "▼"
                            color: Config.textMuted
                            font.pixelSize: Config.settingsUiSize(9)
                        }
                    }

                    TextField {
                        id: themeNameField
                        visible: settings.isCurrentThemeModified()
                        width: parent.width
                        height: 32
                        text: settings.activeTheme + " (Changed)"
                        placeholderText: "Название темы"
                        color: Config.text
                        selectionColor: Config.accent
                        selectedTextColor: Config.black
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        activeFocusOnTab: true
                        background: Rectangle {
                            color: Config.background
                            border.color: themeNameField.activeFocus ? Config.accent : Config.tempWarm
                            border.width: 1
                            radius: Config.frameRadius
                        }
                        function saveThemeFromField() {
                            var name = text.trim()
                            if (name.endsWith(" (Changed)"))
                                name = name.slice(0, -10).trim()
                            if (settings.saveCurrentTheme(name))
                                text = settings.activeTheme
                        }
                        Keys.onReturnPressed: saveThemeFromField()
                        Keys.onEnterPressed: saveThemeFromField()
                    }

                    Text {
                        width: parent.width
                        text: settings.isCurrentThemeModified()
                              ? "Цвета изменены. Измените название при необходимости и нажмите Enter для сохранения."
                              : "Выберите тему из списка."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(9)
                        wrapMode: Text.WordWrap
                    }

                    Connections {
                        target: settings
                        function onActiveThemeChanged() {
                            themeCombo.currentIndex = Math.max(0, settings.themeNames.indexOf(settings.activeTheme))
                            themeNameField.text = settings.activeTheme + (settings.isCurrentThemeModified() ? " (Changed)" : "")
                        }
                        function onThemeNamesChanged() {
                            themeCombo.currentIndex = Math.max(0, settings.themeNames.indexOf(settings.activeTheme))
                        }
                    }

                    Row {
                        width: parent.width
                        height: 24
                        spacing: 8

                        Text {
                            width: 112
                            text: settings.isCurrentThemeModified() ? "● изменена" : "● сохранена"
                            color: settings.isCurrentThemeModified() ? Config.tempWarm : Config.accent
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(9)
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            width: parent.width - 120
                            text: "Текущая тема: " + settings.activeTheme
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(9)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        width: parent.width
                        height: 24
                        spacing: 5

                        Repeater {
                            model: settings.themePreview(settings.activeTheme)
                            delegate: Rectangle {
                                width: 34
                                height: 18
                                radius: 3
                                color: modelData
                                border.color: Config.baseColor
                                border.width: 1
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    property var groups: [
                        { title: "Основные", colors: [
                            "baseColor", "accent", "background", "text", "textMuted",
                            "textDim", "textDisabled", "calendarBackground"
                        ]},
                        { title: "Настройки", colors: [
                            "settingsBackground", "settingsBorder"
                        ]},
                        { title: "Сети", colors: [
                            "activeNetworkBackground", "networkUpload", "networkDownload"
                        ]},
                        { title: "Громкость", colors: [
                            "volumeTrack", "volumeFill"
                        ]},
                        { title: "CPU и RAM полоски", colors: [
                            "cpu1", "cpu2", "cpu3", "cpu4", "cpu5", "cpu6", "cpu7", "cpu8",
                            "ram", "metricTrack", "ramTrack"
                        ]},
                        { title: "Плеер", colors: [
                            "playerOverlay", "playerProgressTrack", "playerProgressFill"
                        ]},
                        { title: "Погоды", colors: [
                            "currentWeather", "tempHot", "tempWarm", "tempMild", "tempCool", "tempZero",
                            "tempCold", "tempVeryCold", "tempFreezing"
                        ]}
                    ]

                    Repeater {
                        model: parent.groups

                        delegate: Column {
                            width: parent.width
                            spacing: 5

                            Row {
                                width: parent.width
                                height: 30
                                Text {
                                    width: parent.width - 38
                                    text: modelData.title
                                    color: Config.accent
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(14)
                                    verticalAlignment: Text.AlignVCenter
                                }
                                SettingsResetButton {
                                    tooltip: "Сбросить цвета: " + modelData.title
                                    onClicked: settings.resetColors(modelData.colors)
                                }
                            }

                            Text {
                                visible: modelData.title === "Громкость"
                                text: "Цвета полос громкости применяются ко всем слайдерам этого блока"
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(9)
                                elide: Text.ElideRight
                            }

                            Repeater {
                                model: modelData.colors

                                delegate: Row {
                                    width: parent.width
                                    height: 30
                                    spacing: 8
                                    property string colorName: modelData
                                    property var colorLabels: ({
                                        baseColor: "Основной цвет рамок", accent: "Акцентный цвет",
                                        currentWeather: "Цвет текущей погоды", background: "Полупрозрачный фон",
                                        text: "Основной текст", textMuted: "Приглушённый текст", textDim: "Вторичный текст",
                                        textDisabled: "Неактивный текст", calendarBackground: "Фон календаря",
                                        settingsBackground: "Фон окна настроек", settingsBorder: "Рамка окна настроек",
                                        volumeTrack: "Громкость: фон полосы", volumeFill: "Громкость: заполненная часть",
                                        playerOverlay: "Плеер: затемнение фона", playerProgressTrack: "Фон прогресса плеера",
                                        playerProgressFill: "Заполнение прогресса плеера", activeNetworkBackground: "Фон активной сети",
                                        cpu1: "CPU 1", cpu2: "CPU 2", cpu3: "CPU 3", cpu4: "CPU 4",
                                        cpu5: "CPU 5", cpu6: "CPU 6", cpu7: "CPU 7", cpu8: "CPU 8", ram: "RAM",
                                        metricTrack: "Фон полос CPU", ramTrack: "Фон полос RAM", networkUpload: "Сеть: загрузка",
                                        networkDownload: "Сеть: скачивание", tempHot: "Погода: очень тепло", tempWarm: "Погода: тепло",
                                        tempMild: "Погода: умеренно", tempCool: "Погода: прохладно", tempZero: "Погода: около 0°C",
                                        tempCold: "Погода: холодно", tempVeryCold: "Погода: очень холодно", tempFreezing: "Погода: мороз"
                                    })

                                    Rectangle {
                                        width: 24; height: 24; radius: 4
                                        color: Config[colorName]
                                        border.color: Config.baseColor; border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: 220
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            width: parent.width
                                            text: colorLabels[colorName] || colorName
                                            color: Config.text
                                            font.family: Config.settingsFont
                                            font.pixelSize: Config.settingsUiSize(11)
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: colorName
                                            color: Config.textMuted
                                            font.family: Config.settingsFont
                                            font.pixelSize: Config.settingsUiSize(9)
                                            elide: Text.ElideRight
                                        }
                                    }

                                    TextField {
                                        id: colorField
                                        width: 120; height: 28
                                        text: String(Config[colorName])
                                        color: Config.text
                                        selectionColor: Config.accent
                                        selectedTextColor: Config.black
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(11)
                                        activeFocusOnTab: true
                                        background: Rectangle {
                                            color: Config.background
                                            border.color: colorField.activeFocus ? Config.accent : Config.baseColor
                                            border.width: 1; radius: 4
                                        }
                                        onEditingFinished: {
                                            if (/^#[0-9a-fA-F]{6,8}$/.test(text) || text === "transparent") {
                                                Config[colorName] = text
                                                settings.save()
                                            } else {
                                                text = String(Config[colorName])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
}

}
