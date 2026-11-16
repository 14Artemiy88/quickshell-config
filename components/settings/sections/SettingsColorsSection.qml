import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Flickable {
    id: root
    property var host
    property var settings: Settings
    visible: host && host.currentTab === 1
    width: parent ? parent.width : 0
    height: visible ? parent.height - y : 0
    property bool editingColors: false
    property bool themesExpanded: false

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

    SettingsGroup {
        visible: host && host.currentTab === 1
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

                Column {
                    width: parent.width
                    spacing: 7

                    Row {
                        width: parent.width
                        height: 30
                        Text {
                            width: parent.width
                                - (settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("all") ? 38 : 0)
                                - (settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("themes") ? 38 : 0)
                            text: "Темы"
                            color: Config.accent
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(15)
                            verticalAlignment: Text.AlignVCenter
                        }
                        SettingsButton {
                            width: 30
                            height: 30
                            visible: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("all")
                            enabled: visible
                            text: ""
                            iconText: "󰆔"
                            fontSize: 11
                            tooltip: "Сохранить всё в активный профиль"
                            backgroundColor: Config.settingsBackground
                            onClicked: settings.saveProfile(settings.activeProfile)
                        }
                        SettingsButton {
                            width: 30
                            height: 30
                            visible: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("themes")
                            enabled: visible
                            text: ""
                            iconText: "\uf0c7"
                            fontSize: 11
                            tooltip: "Сохранить тему в активный профиль"
                            backgroundColor: Config.settingsBackground
                            onClicked: settings.saveProfileScope(settings.activeProfile, "themes")
                        }
                    }

                    Text {
                        text: "Тема" + (settings.currentThemeModified ? " (Changed)" : "")
                        color: settings.currentThemeModified ? Config.tempWarm : Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                    }

                    SettingsCheckBox {
                        id: expandThemesCheck
                        text: "Развернуть"
                        checked: root.themesExpanded
                        onToggled: root.themesExpanded = checked
                    }



                    MorphGeometry {
                        id: expandedThemeList
                        clip: true
                        fromGeometry: Qt.rect(0, 0, parent.width, 0)
                        toGeometry: Qt.rect(0, 0, parent.width, expandedThemeContent.implicitHeight)
                        fromRadius: 0
                        toRadius: Config.frameRadius
                        progress: root.themesExpanded ? 1 : 0
                        animationDuration: Config.animationDuration(180, "appearance")
                        animationEasing: Config.animationEasingType("standard", root.themesExpanded ? "enter" : "exit")

                        Column {
                            id: expandedThemeContent
                            width: parent.width
                            spacing: 5

                        Repeater {
                            model: settings.themeNames
                            delegate: Rectangle {
                                id: themeCard
                                required property var modelData
                                property string themeName: String(modelData)
                                width: expandedThemeList.width
                                height: 42
                                radius: 5
                                color: Config.settingsBackground
                                border.color: themeName === settings.activeTheme ? Config.accent : Config.baseColor
                                border.width: themeName === settings.activeTheme ? 2 : 1
                                opacity: settings.currentThemeModified && root.editingColors ? 0.65 : 1

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 5

                                    Text {
                                        width: Math.min(205, Math.max(95, themeCard.width * 0.39))
                                        height: parent.height
                                        text: themeCard.themeName + (themeCard.themeName === settings.activeTheme && settings.currentThemeModified ? " (Changed)" : "")
                                        color: themeCard.themeName === settings.activeTheme ? Config.accent : Config.text
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(10)
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Repeater {
                                            model: settings.themePreview(themeCard.themeName)
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: Math.max(12, Math.min(27, (themeCard.width - 235) / 6))
                                                height: 23
                                                radius: 3
                                                color: modelData
                                                border.color: Config.baseColor
                                                border.width: 1
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !(settings.currentThemeModified && root.editingColors)
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (themeCard.themeName && themeCard.themeName !== settings.activeTheme)
                                            settings.applyTheme(themeCard.themeName)
                                    }
                                }
                            }
                        }
                        }
                    }

                    // Keep the theme selector and modified-theme input in one stable slot.
                    // Switching between them is intentionally immediate: animating this
                    // replacement while the palette expands makes the whole column jump.
                    Item {
                        id: themeSelectorSlot
                        width: parent.width
                        readonly property bool showThemeCombo: !root.themesExpanded
                            && expandedThemeList.normalizedProgress <= 0.001
                            && (!settings.currentThemeModified || !root.editingColors)
                        readonly property bool showModifiedThemeName: root.editingColors && settings.currentThemeModified
                        height: showThemeCombo || showModifiedThemeName ? 30 : 0

                        SettingsComboBox {
                            id: themeCombo
                            width: parent.width
                            height: 30
                            visible: themeSelectorSlot.showThemeCombo
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
                            width: parent.width
                            height: 30
                            visible: themeSelectorSlot.showModifiedThemeName
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
                    }




                    Row {
                        id: activeThemePreviewRow
                        width: parent.width
                        height: 24
                        spacing: 5
                        visible: !root.themesExpanded && expandedThemeList.normalizedProgress <= 0.001

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

                    MorphGeometry {
                        id: customThemeRenameMorph
                        width: parent.width
                        clip: true
                        visible: (root.editingColors && settings.isCustomTheme(settings.activeTheme) && !settings.currentThemeModified) || normalizedProgress > 0.001
                        fromGeometry: Qt.rect(0, 0, parent.width, 0)
                        toGeometry: Qt.rect(0, 0, parent.width, 30)
                        progress: root.editingColors && settings.isCustomTheme(settings.activeTheme) && !settings.currentThemeModified ? 1 : 0
                        animationDuration: Config.animationDuration(180, "appearance")
                        animationEasing: Config.animationEasingType("standard", root.editingColors && settings.isCustomTheme(settings.activeTheme) && !settings.currentThemeModified ? "enter" : "exit")

                        Row {
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
                                visible: actionAvailable && settings.customThemes && settings.customThemes[settings.activeTheme] !== undefined
                                width: 30
                                height: 30
                                label: "×"
                                tooltip: "Удалить пользовательскую тему"
                                emphasized: true
                                emphasizedHoverOnly: true
                                emphasizedColor: "#ff9999"
                                emphasizedHoverColor: "#ff6666"
                                onClicked: settings.deleteCustomTheme(settings.activeTheme)
                                }
                        }
                    }

                }
    }

    SettingsGroup {
        visible: host && host.currentTab === 1
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

                MorphGeometry {
                    id: customThemeColorsMorph
                    width: parent.width
                    clip: true
                    visible: root.editingColors || normalizedProgress > 0.001
                    fromGeometry: Qt.rect(0, 0, parent.width, 0)
                    toGeometry: Qt.rect(0, 0, parent.width, customThemeColorsContent.implicitHeight)
                    progress: root.editingColors ? 1 : 0
                    animationDuration: Config.animationDuration(180, "appearance")
                    animationEasing: Config.animationEasingType("standard", root.editingColors ? "enter" : "exit")

                    Column {
                        id: customThemeColorsContent
                        width: parent.width
                        spacing: 8

                        property var groups: [
                            { title: "Основные", colors: [
                                "baseColor", "accent", "background", "text", "textMuted",
                                "textDim", "textDisabled", "calendarBackground"
                            ]},
                            { title: "Настройки", colors: [
                                "settingsBorder", "settingsSubheading"
                            ]},
                            { title: "Сети", colors: [
                                "activeNetworkBackground", "networkUpload", "networkDownload"
                            ]},
                            { title: "Громкость", colors: [
                                "volumeTrack", "volumeFill"
                            ]},
                            { title: "Полосы CPU и RAM", colors: [
                                "cpu1", "cpu1Track", "cpu2", "cpu2Track",
                                "cpu3", "cpu3Track", "cpu4", "cpu4Track",
                                "cpu5", "cpu5Track", "cpu6", "cpu6Track",
                                "cpu7", "cpu7Track", "cpu8", "cpu8Track",
                                "ram", "ramTrack"
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

                            delegate: SettingsGroup {
                                width: parent.width
                                contentSpacing: 5
                                showFrame: false

                                Row {
                                    width: parent.width
                                    height: 30
                                    Text {
                                        width: parent.width - (settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("colors", modelData.colors) ? 76 : 38)
                                        text: modelData.title
                                        color: Config.accent
                                        font.family: Config.settingsFont
                                        font.pixelSize: Config.settingsUiSize(14)
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    SettingsButton {
                                        width: 30
                                        height: 30
                                        visible: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("colors", modelData.colors)
                                        enabled: visible
                                        text: ""
                                        iconText: "\uf0c7"
                                        fontSize: 11
                                        tooltip: "Сохранить цвета: " + modelData.title
                                        backgroundColor: Config.settingsBackground
                                        onClicked: settings.saveProfileScope(settings.activeProfile, "colors", modelData.colors)
                                    }
                                    SettingsResetButton {
                                        width: 30
                                        height: 30
                                        enabled: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined
                                        actionAvailable: settings.hasResetChanges("colors", modelData.colors)
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
                                            settingsBorder: "Рамка окна настроек", settingsSubheading: "Цвет мини-заголовков",
                                            volumeTrack: "Громкость: фон полосы", volumeFill: "Громкость: заполненная часть",
                                            playerOverlay: "Плеер: затемнение фона", playerProgressTrack: "Фон прогресса плеера",
                                            playerProgressFill: "Заполнение прогресса плеера", activeNetworkBackground: "Фон активной сети",
                                            cpu1: "CPU 1: заполнение", cpu1Track: "CPU 1: неактивный фон",
                                            cpu2: "CPU 2: заполнение", cpu2Track: "CPU 2: неактивный фон",
                                            cpu3: "CPU 3: заполнение", cpu3Track: "CPU 3: неактивный фон",
                                            cpu4: "CPU 4: заполнение", cpu4Track: "CPU 4: неактивный фон",
                                            cpu5: "CPU 5: заполнение", cpu5Track: "CPU 5: неактивный фон",
                                            cpu6: "CPU 6: заполнение", cpu6Track: "CPU 6: неактивный фон",
                                            cpu7: "CPU 7: заполнение", cpu7Track: "CPU 7: неактивный фон",
                                            cpu8: "CPU 8: заполнение", cpu8Track: "CPU 8: неактивный фон",
                                            ram: "RAM: заполнение", ramTrack: "RAM: неактивный фон",
                                            networkUpload: "Сеть: загрузка",
                                            networkDownload: "Сеть: скачивание",
                                            tempHot: "Погода: очень тепло", tempWarm: "Погода: тепло",
                                            tempMild: "Погода: умеренно", tempCool: "Погода: прохладно", tempZero: "Погода: около 0°C",
                                            tempCold: "Погода: холодно", tempVeryCold: "Погода: очень холодно", tempFreezing: "Погода: мороз"
                                        })

                                        SettingsColorField {
                                            width: parent.width
                                            label: colorLabels[colorName] || colorName
                                            value: String(Config[colorName])
                                            targetObject: Config
                                            targetProperty: colorName
                                            settingsObject: settings
                                            saveOnEdit: true
                                            allowAlpha: true
                                            allowTransparent: true
                                            fieldWidth: 120
                                            compact: false
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
