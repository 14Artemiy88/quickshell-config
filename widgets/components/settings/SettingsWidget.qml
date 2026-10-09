import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"
import "sections"

Item {
    id: root
    objectName: "quickshellSettingsWidget"

    function wheelDelta(wheel, step) {
        var direction = wheel.angleDelta.y > 0 ? 1 : -1
        var multiplier = (wheel.modifiers & Qt.ShiftModifier) ? 10 : 1
        return direction * step * multiplier
    }
    property var settings: Settings
    property int currentTab: 0
    property int currentOtherTab: 0
    property int currentOtherSubTab: 0
    property bool settingsMoveMode: false
    signal layoutEditRequested()
    signal settingsMoveRequested()
    signal closeRequested()
    clip: true

    Shortcut {
        sequence: "Esc"
        enabled: !root.settingsMoveMode
        onActivated: root.closeRequested()
    }

    function clearSettingsFocus() {
        root.forceActiveFocus()
    }

    function openWeatherSettings() {
        root.currentTab = 2
        root.currentOtherTab = 3
        root.currentOtherSubTab = 0
        root.clearSettingsFocus()
    }

    // Background click catcher. It stays behind the settings content,
    // so controls and tabs keep receiving their own mouse events.
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton
        onClicked: root.clearSettingsFocus()
    }

    onCurrentTabChanged: {
        if (modulesSectionSettingsSection) modulesSectionSettingsSection.resetScroll()
        if (colorsSectionSettingsSection) colorsSectionSettingsSection.resetScroll()
        if (otherFlick) otherFlick.contentY = 0
    }

    onCurrentOtherTabChanged: {
        if (otherFlick) otherFlick.contentY = 0
        root.currentOtherSubTab = 0
    }

    readonly property var currentOtherSubTabs: {
        switch (root.currentOtherTab) {
        case 0: return ["Интерфейс", "Рамки", "Анимации"]
        case 1: return ["Основные", "Окно окончания", "Иконки", "Разметка"]
        case 2: return ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон"]
        case 3: return ["Общие", "Сейчас", "По часам", "По дням"]
        case 4: return ["Основные", "Полосы"]
        case 5: return ["Общие", "График CPU"]
        case 6: return ["Обновления", "Сеть"]
        case 7: return ["Иконки", "Полосы", "Потоки", "Адаптивность"]
        case 8: return ["Общие"]
        case 9: return ["Интерфейс", "Окно настроек", "Профили"]
        case 10: return ["Общее", "Время", "Иконки", "Пусто и недоступен"]
        default: return []
        }
    }

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
                width: parent.width - 260
                text: "НАСТРОЙКИ"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(20)
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: resetIndicator
                width: 140
                text: "Сначала сохраните профиль"
                color: Config.accent
                opacity: 0
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                horizontalAlignment: Text.AlignRight
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
            PropertyAnimation { target: saveIndicator; property: "opacity"; to: 0.9; duration: Config.animationDuration(100, "appearance"); easing.type: Config.easingType() }
            PauseAnimation { duration: Config.animationDuration(500, "appearance") }
            PropertyAnimation { target: saveIndicator; property: "opacity"; to: 0; duration: Config.animationDuration(350, "appearance"); easing.type: Config.easingType() }
        }
        Connections { target: settings; function onSaved() { savePulse.restart() } }
        SequentialAnimation {
            id: resetPulse
            PropertyAnimation { target: resetIndicator; property: "opacity"; to: 1; duration: Config.animationDuration(100, "appearance"); easing.type: Config.easingType() }
            PauseAnimation { duration: Config.animationDuration(1300, "appearance") }
            PropertyAnimation { target: resetIndicator; property: "opacity"; to: 0; duration: Config.animationDuration(250, "appearance"); easing.type: Config.easingType() }
        }
        Connections { target: settings; function onResetUnavailable(message) { resetIndicator.text = message; resetPulse.restart() } }

        Row {
            id: settingsBody
            width: parent.width
            height: parent.height - y
            spacing: 8

            Column {
                id: mainSettingsTabs
                width: 128
                height: parent.height
                spacing: 5

                Repeater {
                    model: ["Модули", "Темы", "Общие", "Таймеры", "Плеер", "Погода", "CAVA", "CPU/RAM", "Сеть", "Громкость", "Календарь", "Окно настроек", "Mopidy"]

                    delegate: SettingsSubTab {
                        width: mainSettingsTabs.width
                        selected: {
                            if (index === 0) return root.currentTab === 0
                            if (index === 1) return root.currentTab === 1
                            return root.currentTab === 2 && root.currentOtherTab === index - 2
                        }
                        text: modelData
                        leftAligned: true
                        horizontalPadding: 8
                        onClicked: {
                            root.clearSettingsFocus()
                            if (index === 0) {
                                root.currentTab = 0
                            } else if (index === 1) {
                                root.currentTab = 1
                            } else {
                                root.currentTab = 2
                                root.currentOtherTab = index - 2
                            }
                        }
                    }
                }
            }

            Item {
                id: settingsContentArea
                width: parent.width - mainSettingsTabs.width - 8
                height: parent.height

                SettingsModulesSection {
                    id: modulesSectionSettingsSection
                    host: root
                    settings: root.settings
                }

                SettingsColorsSection {
                    id: colorsSectionSettingsSection
                    host: root
                    settings: root.settings
                }

                Item {
                    id: otherSettingsArea
                    visible: root.currentTab === 2
                    width: parent.width
                    height: parent.height

                    Flickable {
                        id: otherFlick
                        anchors.fill: parent
                        contentWidth: Math.max(width, otherColumn.width)
                        contentHeight: otherColumn.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.VerticalFlick
                        interactive: contentHeight > height
                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            acceptedButtons: Qt.LeftButton
                            onClicked: root.clearSettingsFocus()
                        }
                        ScrollBar.vertical: SettingsScrollBar { visible: otherFlick.contentHeight > otherFlick.height + 1 }

                        Column {
                            id: otherColumn
                            width: otherFlick.width - 12
                            spacing: 10

                            Row {
                                width: parent.width
                                height: 30
                                Text {
                                    width: parent.width - 38
                                    text: "НАСТРОЙКИ"
                                    color: Config.accent
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(15)
                                    verticalAlignment: Text.AlignVCenter
                                }
                                SettingsResetButton {
                                    tooltip: "Сбросить текущую вкладку"
                                    onClicked: {
                                        if (root.currentOtherTab === 0) { settings.resetGeneralSettings(); settings.resetAnimationSettings() }
                                        else if (root.currentOtherTab === 1) settings.resetTimerSettings()
                                        else if (root.currentOtherTab === 2) settings.resetPlayerSettings()
                                        else if (root.currentOtherTab === 3) settings.resetWeatherSettings()
                                        else if (root.currentOtherTab === 4) settings.resetCavaSettings()
                                        else if (root.currentOtherTab === 5) settings.resetCpuSettings()
                                        else if (root.currentOtherTab === 6) settings.resetNetworkSettings()
                                        else if (root.currentOtherTab === 7) settings.resetVolumeSettings()
                                        else if (root.currentOtherTab === 8) settings.resetCalendarSettings()
                                        else if (root.currentOtherTab === 9) settings.resetSettingsWindow()
                                        else if (root.currentOtherTab === 10) settings.resetMopidySettings()
                                    }
                                }
                            }

                            Row {
                                visible: root.currentOtherSubTabs.length > 0
                                width: parent.width
                                height: 34
                                spacing: 5

                                Repeater {
                                    model: root.currentOtherSubTabs

                                    delegate: SettingsSubTab {
                                        width: (parent.width - (root.currentOtherSubTabs.length - 1) * 5) / root.currentOtherSubTabs.length
                                        selected: root.currentOtherSubTab === index
                                        text: modelData
                                        onClicked: {
                                            root.clearSettingsFocus()
                                            root.currentOtherSubTab = index
                                            otherFlick.contentY = 0
                                        }
                                    }
                                }
                            }

                            SettingsCalendarSection {
                                id: calendarSectionSettingsSection
                                host: root
                                settings: root.settings
                            }

                            SettingsWeatherSection {
                                id: weatherSectionSettingsSection
                                host: root
                                settings: root.settings
                            }

                            SettingsGeneralSection {
                                id: generalSectionSettingsSection
                                host: root
                                settings: root.settings
                            }

                            Text { visible: root.currentOtherTab === 6 && root.currentOtherSubTab === 0; text: "Обновление общих данных"; color: Config.accent; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12) }

                            SettingsNumberField {
                                visible: root.currentOtherTab === 6 && root.currentOtherSubTab === 0
                                label: "System Monitor (мс) — общие данные"
                                value: Config.systemMonitorInterval
                                minimum: 200
                                maximum: 10000
                                step: 100
                                wheelStep: 100
                                onValueEdited: value => { Config.systemMonitorInterval = value; settings.save() }
                            }
                            SettingsNumberField {
                                visible: root.currentOtherTab === 5 && root.currentOtherSubTab === 0
                                label: "CPU (мс)"
                                value: Config.cpuUpdateInterval
                                minimum: 200
                                maximum: 10000
                                step: 100
                                wheelStep: 100
                                onValueEdited: value => { Config.cpuUpdateInterval = value; settings.save() }
                            }
                            SettingsNumberField {
                                visible: root.currentOtherTab === 2 && root.currentOtherSubTab === 0
                                label: "Плеер (мс)"
                                value: Config.playerUpdateInterval
                                minimum: 50
                                maximum: 5000
                                step: 50
                                wheelStep: 50
                                onValueEdited: value => { Config.playerUpdateInterval = value; settings.save() }
                            }

                            SettingsPlayerSection {
                                id: playerSectionSettingsSection
                                visible: root.currentOtherTab === 2
                                width: parent.width
                                host: root
                                settings: root.settings
                            }
                            SettingsMopidySection {
                                id: mopidySectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsMopidyTimeSection {
                                id: mopidyTimeSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsMopidyIconsSection {
                                id: mopidyIconsSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsMopidyStatusSection {
                                id: mopidyStatusSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsCavaSection {
                                id: cavaSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsCpuRamSection {
                                id: cpuRamSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsNetworkSection {
                                id: networkSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsVolumeSection {
                                id: volumeSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            SettingsTimersSection {
                                id: timersSectionSettingsSection
                                visible: root.currentOtherTab === 1
                                width: parent.width
                                host: root
                                settings: root.settings
                            }
                            SettingsWindowSection {
                                id: settingsWindowSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                        }
                    }
                }
            }
        }

}

}
