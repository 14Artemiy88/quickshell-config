import QtQuick
import QtQuick.Controls
import "../.."

Flickable {
    id: root
    property var host
    property var settings: Settings
    visible: host && host.currentTab === 1
    width: parent ? parent.width : 0
    height: visible ? parent.height - y : 0
    property bool editingColors: false

    function resetScroll() { root.contentY = 0 }
    contentWidth: Math.max(width, colorsColumn.width)
    contentHeight: colorsColumn.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    interactive: contentHeight > height
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton
        onClicked: host.clearSettingsFocus()
    }
    ScrollBar.vertical: SettingsScrollBar { visible: root.contentHeight > root.height + 1 }

    Column {
        id: colorsColumn
        width: root.width - 12
        spacing: 10

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
                text: "Тема" + (settings.currentThemeModified ? " (Changed)" : "")
                color: settings.currentThemeModified ? Config.tempWarm : Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }

            SettingsComboBox {
                id: themeCombo
                width: parent.width
                visible: !settings.currentThemeModified || !root.editingColors
                height: 30
                model: settings.themeNames
                currentIndex: Math.max(0, settings.themeNames.indexOf(settings.activeTheme))
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                onItemChosen: function(index) {
                    var name = settings.themeNames[index]
                    if (name && name !== settings.activeTheme)
                        settings.applyTheme(name)
                }
                background: Rectangle {
                    color: Config.settingsBackground
                    border.color: (themeCombo.activeFocus || themeCombo.pointerHovered) ? Config.accent : Config.baseColor
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

            SettingsTextField {
                id: themeNameField
                visible: root.editingColors && settings.currentThemeModified
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
                    color: Config.settingsBackground
                    border.color: (themeNameField.activeFocus || themeNameField.pointerHovered) ? Config.accent : Config.tempWarm
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

            SettingsCheckBox {
                id: editColorsCheck
                text: "Редактировать цвета"
                checked: root.editingColors
                onToggled: root.editingColors = checked
            }

            Connections {
                target: settings
                function onActiveThemeChanged() {
                    themeCombo.currentIndex = Math.max(0, settings.themeNames.indexOf(settings.activeTheme))
                    themeNameField.text = settings.activeTheme + (settings.currentThemeModified ? " (Changed)" : "")
                    themeRenameField.text = settings.activeTheme
                }
                function onThemeNamesChanged() {
                    themeCombo.currentIndex = Math.max(0, settings.themeNames.indexOf(settings.activeTheme))
                }
            }

            Row {
                visible: root.editingColors && settings.isCustomTheme(settings.activeTheme) && !settings.currentThemeModified
                width: parent.width
                height: 30
                spacing: 6

                SettingsTextField {
                    id: themeRenameField
                    width: parent.width - 38
                    height: 30
                    text: settings.activeTheme
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    activeFocusOnTab: true
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (themeRenameField.activeFocus || themeRenameField.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: Config.frameRadius
                    }
                    function renameCurrentTheme() {
                        var name = themeRenameField.text.trim()
                        settings.renameCustomTheme(settings.activeTheme, name)
                        themeRenameField.text = settings.activeTheme
                    }
                    Keys.onReturnPressed: renameCurrentTheme()
                    Keys.onEnterPressed: renameCurrentTheme()
                }

                SettingsResetButton {
                    id: themeDeleteButton
                    width: 30
                    height: 30
                    label: "×"
                    tooltip: "Удалить пользовательскую тему"
                    emphasized: true
                    emphasizedHoverOnly: true
                    emphasizedColor: "#ff6666"
                    onClicked: settings.deleteCustomTheme(settings.activeTheme)
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
                    "settingsBackground", "settingsBorder", "settingsSubheading"
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
                    visible: root.editingColors
                    width: parent.width
                    height: visible ? implicitHeight : 0
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
                                settingsBackground: "Фон окна настроек", settingsBorder: "Рамка окна настроек", settingsSubheading: "Цвет мини-заголовков",
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

                            SettingsTextField {
                                id: colorField
                                width: 120; height: 30
                                text: String(Config[colorName])
                                color: Config.text
                                selectionColor: Config.accent
                                selectedTextColor: Config.black
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(11)
                                activeFocusOnTab: true
                                background: Rectangle {
                                    color: Config.settingsBackground
                                    border.color: (colorField.activeFocus || colorField.pointerHovered) ? Config.accent : Config.baseColor
                                    border.width: 1; radius: 4
                                }
                                onEditingFinished: {
                                    if (/^#[0-9a-fA-F]{6,8}$/.test(text) || text === "transparent") {
                                        Config[colorName] = text
                                        settings.bumpThemeStateRevision()
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
