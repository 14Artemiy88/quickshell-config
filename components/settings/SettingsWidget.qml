import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"
import "sections"
import "sections/mopidy" as MopidySettings

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

    // Internal IDs remain stable for section visibility, reset handlers and external callers.
    // The sidebar display order places Mopidy directly below Player.
    readonly property var otherTabLabels: ["Общие", "Таймеры", "Плеер", "Погода", "CAVA", "CPU/RAM", "Сеть", "Громкость", "Календарь", "Окно настроек", "Mopidy", "Лаунчер"]
    readonly property var otherTabDisplayOrder: [0, 1, 2, 10, 3, 4, 5, 6, 7, 8, 11, 9]

    function otherTabIdForDisplayIndex(index) {
        if (index < 0 || index >= root.otherTabDisplayOrder.length)
            return 0
        return root.otherTabDisplayOrder[index]
    }
    readonly property string currentOtherTabTitle: {
        var main = root.otherTabLabels[root.currentOtherTab] || "Настройки"
        var subtabs = root.currentOtherSubTabs
        var sub = subtabs[root.currentOtherSubTab] || ""
        return (main + (sub ? " · " + sub : "")).toLocaleUpperCase()
    }

    readonly property var currentOtherSubTabs: {
        switch (root.currentOtherTab) {
        case 0: return ["Интерфейс", "Анимации", "Профили"]
        case 1: return ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации"]
        case 2: return ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон"]
        case 3: return ["Общие", "Сейчас", "По часам", "По дням"]
        case 4: return ["Основные", "Полосы"]
        case 5: return ["Общие", "График CPU", "Top Apps"]
        case 6: return ["Обновления", "Сеть"]
        case 7: return ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность"]
        case 8: return ["Разметка", "Цвета", "Метки заметок", "Анимации"]
        case 9: return ["Интерфейс", "Окно настроек"]
        case 10: return ["Общее", "Время", "Иконки", "Пусто и недоступен"]
        case 11: return ["Общее", "Вкладки", "Проекты"]
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
            // Keep the settings text visually separated from the sidebar tabs.
            spacing: 16

            Column {
                id: mainSettingsTabs
                width: 128
                height: parent.height
                spacing: 5

                Repeater {
                    model: ["Модули", "Темы", "Общие", "Таймеры", "Плеер", "Mopidy", "Погода", "CAVA", "CPU/RAM", "Сеть", "Громкость", "Календарь", "Лаунчер", "Окно настроек"]

                    delegate: SettingsSubTab {
                        width: mainSettingsTabs.width
                        selected: {
                            if (index === 0) return root.currentTab === 0
                            if (index === 1) return root.currentTab === 1
                            return root.currentTab === 2 && root.currentOtherTab === root.otherTabIdForDisplayIndex(index - 2)
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
                                root.currentOtherTab = root.otherTabIdForDisplayIndex(index - 2)
                            }
                        }
                    }
                }
            }

            Item {
                id: settingsContentArea
                width: parent.width - mainSettingsTabs.width - 16
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
                                    text: root.currentOtherTabTitle
                                    color: Config.accent
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(15)
                                    verticalAlignment: Text.AlignVCenter
                                }
                                SettingsResetButton {
                                    visible: !(root.currentOtherTab === 0 && root.currentOtherSubTab === 2)
                                    tooltip: "Сбросить текущую вкладку"
                                    onClicked: {
                                        if (root.currentOtherTab === 0 && root.currentOtherSubTab === 0) settings.resetGeneralSettings()
                                        else if (root.currentOtherTab === 0 && root.currentOtherSubTab === 1) settings.resetAnimationSettings()
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
                                        else if (root.currentOtherTab === 11) settings.resetLauncherSettings()
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

                            SettingsGroup {
                                visible: root.currentOtherTab === 2 && root.currentOtherSubTab === 0
                                width: parent.width
                                showFrame: true
                                padding: 8
                                contentSpacing: 6

                                SettingsNumberField {
                                    visible: root.currentOtherTab === 2 && root.currentOtherSubTab === 0
                                    width: parent.width
                                    label: "Плеер (мс)"
                                    value: Config.playerUpdateInterval
                                    minimum: 50
                                    maximum: 5000
                                    step: 50
                                    wheelStep: 50
                                    onValueEdited: value => { Config.playerUpdateInterval = value; settings.save() }
                                }
                            }

                            SettingsPlayerSection {
                                id: playerSectionSettingsSection
                                visible: root.currentOtherTab === 2
                                width: parent.width
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidySection {
                                id: mopidySectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidyTimeSection {
                                id: mopidyTimeSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidyIconsSection {
                                id: mopidyIconsSectionSettingsSection
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidyStatusSection {
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
                            SettingsLauncherSection {
                                id: launcherSectionSettingsSection
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
