import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root
    property var settings: Settings
    property int currentTab: 0
    property int currentOtherTab: 0
    clip: true

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

        Text {
            text: "НАСТРОЙКИ"
            color: Config.accent
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(20)
        }

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

        Row {
            id: otherTabs
            visible: root.currentTab === 2
            width: parent.width
            height: 30
            spacing: 5

            Repeater {
                model: ["Общие", "Таймеры", "Плеер", "Погода", "CAVA", "Настройки"]

                delegate: Rectangle {
                    width: (otherTabs.width - 25) / 6
                    height: otherTabs.height
                    radius: 4
                    color: root.currentOtherTab === index ? Config.accent : Config.background
                    border.color: Config.baseColor
                    border.width: 1

                    Text {
                        anchors.fill: parent
                        text: modelData
                        color: root.currentOtherTab === index ? Config.black : Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        font.bold: root.currentOtherTab === index
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.currentOtherTab = index
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

                Text {
                    text: "Модули и их расположение"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(15)
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
                                        var delta = wheel.angleDelta.y > 0 ? 1 : -1
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

                Text {
                    text: "Цвета"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(15)
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
                            "playerOverlay", "playerProgressTrack"
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

                            Text {
                                text: modelData.title
                                color: Config.accent
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(14)
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
                                        baseColor: "Основной цвет рамок",
                                        accent: "Акцентный цвет",
                                        currentWeather: "Цвет текущей погоды",
                                        background: "Полупрозрачный фон",
                                        text: "Основной текст",
                                        textMuted: "Приглушённый текст",
                                        textDim: "Вторичный текст",
                                        textDisabled: "Неактивный текст",
                                        calendarBackground: "Фон календаря",
                                        settingsBackground: "Фон окна настроек",
                                        settingsBorder: "Рамка окна настроек",
                                        volumeTrack: "Громкость: фон полосы",
                                        volumeFill: "Громкость: заполненная часть",
                                        playerOverlay: "Плеер: затемнение фона",
                                        playerProgressTrack: "Фон прогресса плеера",
                                        activeNetworkBackground: "Фон активной сети",
                                        cpu1: "CPU 1", cpu2: "CPU 2", cpu3: "CPU 3", cpu4: "CPU 4",
                                        cpu5: "CPU 5", cpu6: "CPU 6", cpu7: "CPU 7", cpu8: "CPU 8",
                                        ram: "RAM",
                                        metricTrack: "Фон полос CPU",
                                        ramTrack: "Фон полос RAM",
                                        networkUpload: "Сеть: загрузка",
                                        networkDownload: "Сеть: скачивание",
                                        tempHot: "Погода: очень тепло",
                                        tempWarm: "Погода: тепло",
                                        tempMild: "Погода: умеренно",
                                        tempCool: "Погода: прохладно",
                                        tempZero: "Погода: около 0°C",
                                        tempCold: "Погода: холодно",
                                        tempVeryCold: "Погода: очень холодно",
                                        tempFreezing: "Погода: мороз"
                                    })

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 4
                                        color: Config[colorName]
                                        border.color: Config.baseColor
                                        border.width: 1
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
                                        width: 120
                                        height: 28
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
                                            border.width: 1
                                            radius: 4
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

        // -------------------- Other settings --------------------
        Flickable {
            id: otherFlick
            visible: root.currentTab === 2
            width: parent.width
            height: parent.height - y
            contentWidth: width
            contentHeight: otherColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            Column {
                id: otherColumn
                width: otherFlick.width - 12
                spacing: 10

                Text {
                    text: "ПРОЧИЕ НАСТРОЙКИ"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(15)
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
                    text: "Основной шрифт интерфейса, анимации и общие параметры"
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
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { generalFontSizeField.applyValue(Config.fontSize + (wheel.angleDelta.y > 0 ? 1 : -1)); wheel.accepted = true } }
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

                Row {
                    visible: root.currentOtherTab === 0
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
                    visible: root.currentOtherTab === 0
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
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { animationSpeedField.applyValue(Number(Config.animationSpeed) + (wheel.angleDelta.y > 0 ? 0.25 : -0.25)); wheel.accepted = true } }
                    }
                }

                Text { visible: root.currentOtherTab === 0; text: "Обновление данных (мс / мин)"; color: Config.accent; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12) }

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 0
                    Text { width: 210; text: "System Monitor, CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: systemIntervalField; width: 100; height: 28; text: String(Config.systemMonitorInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n = Number(text); if (!isFinite(n)) n = Config.systemMonitorInterval; n = Math.max(200, Math.min(10000, Math.round(n))); Config.systemMonitorInterval = n; text = String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { var n = Math.max(200, Math.min(10000, Config.systemMonitorInterval + (wheel.angleDelta.y > 0 ? 100 : -100))); Config.systemMonitorInterval=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 0
                    Text { width: 210; text: "CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: cpuIntervalField; width: 100; height: 28; text: String(Config.cpuUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.cpuUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.cpuUpdateInterval=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(200,Math.min(10000,Config.cpuUpdateInterval+(wheel.angleDelta.y>0?100:-100))); Config.cpuUpdateInterval=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Плеер (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: playerIntervalField; width: 100; height: 28; text: String(Config.playerUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.playerUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.playerUpdateInterval=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(200,Math.min(10000,Config.playerUpdateInterval+(wheel.angleDelta.y>0?100:-100))); Config.playerUpdateInterval=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Погода сейчас (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherNowIntervalField; width: 100; height: 28; text: String(Config.weatherNowIntervalMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherNowIntervalMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherNowIntervalMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherNowIntervalMinutes+(wheel.angleDelta.y>0?1:-1))); Config.weatherNowIntervalMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Погода по часам (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherHourlyIntervalField; width: 100; height: 28; text: String(Config.weatherHourlyIntervalMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherHourlyIntervalMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherHourlyIntervalMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherHourlyIntervalMinutes+(wheel.angleDelta.y>0?1:-1))); Config.weatherHourlyIntervalMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Погода по дням (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: weatherDailyIntervalField; width: 100; height: 28; text: String(Config.weatherDailyIntervalMinutes); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.weatherDailyIntervalMinutes; n=Math.max(1,Math.min(1440,Math.round(n))); Config.weatherDailyIntervalMinutes=n; text=String(n); settings.save() } onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(1,Math.min(1440,Config.weatherDailyIntervalMinutes+(wheel.angleDelta.y>0?1:-1))); Config.weatherDailyIntervalMinutes=n; text=String(n); settings.save(); wheel.accepted=true } }
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
                                var n = Math.max(0, Math.min(20, Number(Config.frameBorderWidth) + (wheel.angleDelta.y > 0 ? 1 : -1)))
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
                                var n = Math.max(0, Math.min(50, Number(Config.frameRadius) + (wheel.angleDelta.y > 0 ? 1 : -1)))
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
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMinHeight; n=Math.max(30,Math.min(1000,Math.round(n))); Config.volumeMinHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMinHeightField.applyValue(Config.volumeMinHeight+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 0
                    Text { width: 210; text: "Максимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: volumeMaxHeightField; width: 100; height: 28; text: String(Config.volumeMaxHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMaxHeight; n=Math.max(100,Math.min(2000,Math.round(n))); Config.volumeMaxHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMaxHeightField.applyValue(Config.volumeMaxHeight+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
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
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceFontSize; n=Math.max(8,Math.min(100,Math.round(n))); Config.playerSilenceFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ silenceSizeField.applyValue(Config.playerSilenceFontSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер длинного Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: silenceLongSizeField; width: 100; height: 28; text: String(Config.playerSilenceLongFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceLongFontSize; n=Math.max(8,Math.min(100,Math.round(n))); Config.playerSilenceLongFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ silenceLongSizeField.applyValue(Config.playerSilenceLongFontSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер основной строки метаданных"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: metaSizeField; width: 100; height: 28; text: String(Config.playerMetaFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerMetaFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSizeField.applyValue(Config.playerMetaFontSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Размер остальных строк"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: metaSecondarySizeField; width: 100; height: 28; text: String(Config.playerMetaSecondaryFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaSecondaryFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerMetaSecondaryFontSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSecondarySizeField.applyValue(Config.playerMetaSecondaryFontSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2
                    Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    TextField { id: metaSpacingField; width: 100; height: 28; text: String(Config.playerMetaLineSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaLineSpacing; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerMetaLineSpacing=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSpacingField.applyValue(Config.playerMetaLineSpacing+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
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
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerControlIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.playerControlIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ controlIconSizeField.applyValue(Config.playerControlIconSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
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
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { playerBlurRadiusField.applyValue(Config.playerBlurRadius + (wheel.angleDelta.y > 0 ? 1 : -1)); wheel.accepted = true } }
                        Connections { target: Config; function onPlayerBlurRadiusChanged() { playerBlurRadiusField.text = String(Config.playerBlurRadius) } }
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
                                var n = Math.max(8, Math.min(120, Number(Config.cavaBars) + (wheel.angleDelta.y > 0 ? 1 : -1)))
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
                                var n = Math.max(1, Math.min(120, Number(Config.cavaFramerate) + (wheel.angleDelta.y > 0 ? 1 : -1)))
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
                                        settings.adjustTimerPresetDefault(timerPresetField.presetIndex, wheel.angleDelta.y > 0 ? 1 : -1)
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
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerMinHeight; n=Math.max(30,Math.min(1000,Math.round(n / 1) * 1)); Config.timerMinHeight=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerMinHeightField.applyValue(Config.timerMinHeight+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Шаг колеса таймера"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerWheelStepField; width: 100; height: 28; text: String(Config.timerWheelStep); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerWheelStep; n=Math.max(1,Math.min(60,Math.round(n / 1) * 1)); Config.timerWheelStep=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerWheelStepField.applyValue(Config.timerWheelStep+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Ширина комментария"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerCommentWidthField; width: 100; height: 28; text: String(Config.timerCommentWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentWidth; n=Math.max(40,Math.min(300,Math.round(n / 1) * 1)); Config.timerCommentWidth=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerCommentWidthField.applyValue(Config.timerCommentWidth+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Максимальная длина комментария"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerCommentMaxLengthField; width: 100; height: 28; text: String(Config.timerCommentMaxLength); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentMaxLength; n=Math.max(1,Math.min(30,Math.round(n / 1) * 1)); Config.timerCommentMaxLength=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerCommentMaxLengthField.applyValue(Config.timerCommentMaxLength+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Отступ комментария до отсчёта"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerCommentGapField; width: 100; height: 28; text: String(Config.timerCommentGap); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerCommentGap; n=Math.max(0,Math.min(40,Math.round(n / 1) * 1)); Config.timerCommentGap=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerCommentGapField.applyValue(Config.timerCommentGap+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Верхний отступ таймеров"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerRowTopField; width: 100; height: 28; text: String(Config.timerRowTopMargin); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowTopMargin; n=Math.max(0,Math.min(50,Math.round(n / 1) * 1)); Config.timerRowTopMargin=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowTopField.applyValue(Config.timerRowTopMargin+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Правый отступ таймеров"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerRowRightField; width: 100; height: 28; text: String(Config.timerRowRightMargin); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowRightMargin; n=Math.max(0,Math.min(50,Math.round(n / 1) * 1)); Config.timerRowRightMargin=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowRightField.applyValue(Config.timerRowRightMargin+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Анимация появления кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerFadeField; width: 100; height: 28; text: String(Config.timerButtonFadeDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonFadeDuration=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerFadeField.applyValue(Config.timerButtonFadeDuration+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Сдвиг кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerSlideField; width: 100; height: 28; text: String(Config.timerButtonSlideDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonSlideDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonSlideDuration=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerSlideField.applyValue(Config.timerButtonSlideDuration+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1
                    Text { width: 210; text: "Исчезновение иконки (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: timerIconFadeField; width: 100; height: 28; text: String(Config.timerButtonIconFadeDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonIconFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonIconFadeDuration=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerIconFadeField.applyValue(Config.timerButtonIconFadeDuration+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
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
                    text: "Количество элементов, размеры и положение элементов погодных блоков"
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
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherIconSize; n=Math.max(16,Math.min(128,Math.round(n / 1) * 1)); Config.weatherIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherIconSizeField.applyValue(Config.weatherIconSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Размер стрелки ветра"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherArrowSizeField; width: 100; height: 28; text: String(Config.weatherArrowSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherArrowSize; n=Math.max(8,Math.min(64,Math.round(n / 1) * 1)); Config.weatherArrowSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherArrowSizeField.applyValue(Config.weatherArrowSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Смещение стрелки ветра по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherArrowYField; width: 100; height: 28; text: String(Config.weatherArrowYOffset); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherArrowYOffset; n=Math.max(-40,Math.min(40,Math.round(n / 1) * 1)); Config.weatherArrowYOffset=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherArrowYField.applyValue(Config.weatherArrowYOffset+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Зазор стрелки до скорости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherWindGapField; width: 100; height: 28; text: String(Config.weatherWindArrowGap); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherWindArrowGap; n=Math.max(-20,Math.min(40,Math.round(n / 1) * 1)); Config.weatherWindArrowGap=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherWindGapField.applyValue(Config.weatherWindArrowGap+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Количество часов"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherHourlyCountField; width: 100; height: 28; text: String(Config.weatherHourlyCount); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherHourlyCount; n=Math.max(1,Math.min(12,Math.round(n / 1) * 1)); Config.weatherHourlyCount=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherHourlyCountField.applyValue(Config.weatherHourlyCount+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Количество дней"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherDailyCountField; width: 100; height: 28; text: String(Config.weatherDailyCount); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherDailyCount; n=Math.max(1,Math.min(10,Math.round(n / 1) * 1)); Config.weatherDailyCount=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherDailyCountField.applyValue(Config.weatherDailyCount+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 3
                    Text { width: 210; text: "Верхний отступ погодных списков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    TextField { id: weatherPaddingField; width: 100; height: 28; text: String(Config.weatherListTopPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.background; border.color: Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.weatherListTopPadding; n=Math.max(0,Math.min(40,Math.round(n / 1) * 1)); Config.weatherListTopPadding=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ weatherPaddingField.applyValue(Config.weatherListTopPadding+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                    }
                }
                Text {
                    visible: root.currentOtherTab === 5
                    text: "Настройки интерфейса настроек"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 5
                    text: "Отдельный шрифт, размер текста и внутренние отступы самого окна настроек."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: root.currentOtherTab === 5
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
                    visible: root.currentOtherTab === 5
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
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsFontSizeField.applyValue(Config.settingsFontSize+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                        Connections { target: Config; function onSettingsFontSizeChanged() { settingsFontSizeField.text = String(Config.settingsFontSize) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
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
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsPaddingField.applyValue(Config.settingsPadding+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                        Connections { target: Config; function onSettingsPaddingChanged() { settingsPaddingField.text = String(Config.settingsPadding) } }
                    }
                }

                Row {
                    visible: root.currentOtherTab === 5
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
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsSpacingField.applyValue(Config.settingsSpacing+(wheel.angleDelta.y>0?1:-1)); wheel.accepted=true } }
                        Connections { target: Config; function onSettingsSpacingChanged() { settingsSpacingField.text = String(Config.settingsSpacing) } }
                    }
                }

                Text {
                    visible: root.currentOtherTab === 5
                    text: "Окно настроек"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: root.currentOtherTab === 5
                    text: "Координаты и размеры окна настроек"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                Row {
                    visible: root.currentOtherTab === 5
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
                    visible: root.currentOtherTab === 5
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
                                    settings.adjustSettingsGeometry(settingsGeometryField.fieldIndex, wheel.angleDelta.y > 0 ? 1 : -1)
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
                    visible: root.currentOtherTab === 5
                    text: "Изменения применяются и сохраняются сразу. Для X/Y/Width/Height можно использовать колесо мыши с шагом 1."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(9)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }
    }
}
