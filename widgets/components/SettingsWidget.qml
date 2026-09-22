import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root
    property var settings: Settings
    property int currentTab: 0
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
        anchors.margins: 10
        spacing: 8

        Text {
            text: "НАСТРОЙКИ"
            color: Config.accent
            font.family: Config.font
            font.pixelSize: 20
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    font.family: Config.font
                    font.pixelSize: 15
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
                            font.family: Config.font
                            font.pixelSize: 10
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
                                font.family: Config.font
                                font.pixelSize: 11
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
                                font.family: Config.font
                                font.pixelSize: 10
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
                    font.family: Config.font
                    font.pixelSize: 15
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
                                font.family: Config.font
                                font.pixelSize: 14
                            }

                            Text {
                                visible: modelData.title === "Громкость"
                                text: "Цвета полос громкости применяются ко всем слайдерам этого блока"
                                color: Config.textMuted
                                font.family: Config.font
                                font.pixelSize: 9
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
                                            font.family: Config.font
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: colorName
                                            color: Config.textMuted
                                            font.family: Config.font
                                            font.pixelSize: 9
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
                                        font.family: Config.font
                                        font.pixelSize: 11
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
                    font.family: Config.font
                    font.pixelSize: 15
                }

                Text {
                    text: "Токен Gismeteo"
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: 13
                }

                TextField {
                    id: token
                    width: parent.width
                    height: 34
                    text: settings.weatherToken
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    placeholderText: "Введите токен Gismeteo"
                    placeholderTextColor: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: 12
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
                    text: "Рамки"
                    color: Config.accent
                    font.family: Config.font
                    font.pixelSize: 14
                }

                Text {
                    text: "Общие рамки виджетов. Толщина 0 полностью отключает рамку."
                    color: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        width: 210
                        text: "Толщина рамки (0 = выкл.)"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        width: 210
                        text: "Радиус скругления рамки"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    text: "Плеер"
                    color: Config.accent
                    font.family: Config.font
                    font.pixelSize: 14
                }

                Text {
                    text: "Тексты и шрифты плеера"
                    color: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: 10
                }

                Row {
                    width: parent.width
                    height: 34
                    spacing: 8

                    Text {
                        width: 210
                        text: "Текст при отсутствии воспроизведения"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    width: parent.width
                    height: 34
                    spacing: 8

                    Text {
                        width: 210
                        text: "Основной шрифт плеера"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    width: parent.width
                    height: 34
                    spacing: 8

                    Text {
                        width: 210
                        text: "Шрифт метаданных плеера"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    text: "CAVA"
                    color: Config.accent
                    font.family: Config.font
                    font.pixelSize: 14
                }

                Row {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        width: 210
                        text: "Количество полос CAVA"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        width: 210
                        text: "Частота обновления CAVA (FPS)"
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: 11
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
                        font.family: Config.font
                        font.pixelSize: 11
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
                    text: "Таймеры"
                    color: Config.accent
                    font.family: Config.font
                    font.pixelSize: 14
                }

                Text {
                    text: "Дефолтные значения кнопок таймера, в минутах"
                    color: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: 10
                }

                Column {
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
                                font.family: Config.font
                                font.pixelSize: 11
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
                                font.family: Config.font
                                font.pixelSize: 11
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
                                    font.family: Config.font
                                    font.pixelSize: 10
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
                            font.family: Config.font
                            font.pixelSize: 10
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
                    text: "Окно настроек"
                    color: Config.accent
                    font.family: Config.font
                    font.pixelSize: 14
                }

                Text {
                    text: "Координаты и размеры окна настроек"
                    color: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: 10
                }

                Row {
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
                            font.family: Config.font
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Row {
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
                            font.family: Config.font
                            font.pixelSize: 10
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
                    text: "Изменения применяются и сохраняются сразу. Для X/Y/Width/Height можно использовать колесо мыши с шагом 1."
                    color: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }
    }
}
