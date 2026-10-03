import QtQuick
import QtQuick.Controls
import "../.."

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
    signal layoutEditRequested()
    signal settingsMoveRequested()
    signal closeRequested()
    clip: true

    Shortcut {
        sequence: "Esc"
        enabled: true
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
        if (modulesFlick) modulesFlick.contentY = 0
        if (colorsSectionSettingsSection) colorsSectionSettingsSection.resetScroll()
        if (otherFlick) otherFlick.contentY = 0
    }

    onCurrentOtherTabChanged: {
        if (otherFlick) otherFlick.contentY = 0
        if (currentOtherTab !== 3) currentOtherSubTab = 0
        root.currentOtherSubTab = 0
    }

    function otherSubTabNames() {
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
        case 9: return ["Интерфейс", "Окно настроек", "Профили", "Действия"]
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
            id: tabs
            width: parent.width
            height: 34
            spacing: 6

            Repeater {
                model: ["Модули", "Цвета", "Настройки"]

                delegate: Rectangle {
                    width: (tabs.width - 12) / 3
                    height: tabs.height
                    radius: Config.radius
                    color: root.currentTab === index ? Config.accent : Config.settingsBackground
                    property bool hovered: false
                    HoverHandler { onHoveredChanged: parent.hovered = hovered }
                    border.color: hovered ? Config.accent : Config.baseColor
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
                        onClicked: { root.clearSettingsFocus(); root.currentTab = index }
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
                        model: ["Общие", "Таймеры", "Плеер", "Погода", "CAVA", "CPU/RAM", "Сеть", "Громкость", "Календарь", "Настройки"]

                        delegate: Rectangle {
                            width: otherTabs.width
                            height: 34
                            radius: 4
                            color: root.currentOtherTab === index ? Config.accent : Config.settingsBackground
                            property bool hovered: false
                            HoverHandler { onHoveredChanged: parent.hovered = hovered }
                            border.color: hovered ? Config.accent : Config.baseColor
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
                                onClicked: { root.clearSettingsFocus(); root.currentOtherTab = index }
                            }
                        }
                    }
                }

                Flickable {
            id: otherFlick
            width: parent.width - otherTabs.width - 8
            height: parent.height
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
                        }
                    }
                }

                Row {
                    visible: root.otherSubTabNames().length > 0
                    width: parent.width
                    height: 34
                    spacing: 5

                    Repeater {
                        model: root.otherSubTabNames()

                        delegate: Rectangle {
                            width: (parent.width - (root.otherSubTabNames().length - 1) * 5) / root.otherSubTabNames().length
                            height: 34
                            radius: 4
                            color: root.currentOtherSubTab === index ? Config.accent : Config.settingsBackground
                            property bool hovered: false
                            HoverHandler { onHoveredChanged: parent.hovered = hovered }
                            border.color: hovered ? Config.accent : Config.baseColor
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                text: modelData
                                color: root.currentOtherSubTab === index ? Config.black : Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                font.bold: root.currentOtherSubTab === index
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.clearSettingsFocus()
                                    root.currentOtherSubTab = index
                                    otherFlick.contentY = 0
                                }
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

                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 6 && root.currentOtherSubTab === 0
                    Text { width: 210; text: "System Monitor (мс) — общие данные"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: systemIntervalField; width: 100; height: 30; text: String(Config.systemMonitorInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                        color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n = Number(text); if (!isFinite(n)) n = Config.systemMonitorInterval; n = Math.max(200, Math.min(10000, Math.round(n))); Config.systemMonitorInterval = n; text = String(n); settings.save() }
                        onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { var n = Math.max(200, Math.min(10000, Config.systemMonitorInterval + root.wheelDelta(wheel, 100))); Config.systemMonitorInterval=n; systemIntervalField.text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 5 && root.currentOtherSubTab === 0
                    Text { width: 210; text: "CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: cpuIntervalField; width: 100; height: 30; text: String(Config.cpuUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                        color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.cpuUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.cpuUpdateInterval=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(200,Math.min(10000,Config.cpuUpdateInterval+root.wheelDelta(wheel, 100))); Config.cpuUpdateInterval=n; cpuIntervalField.text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 2 && root.currentOtherSubTab === 0
                    Text { width: 210; text: "Плеер (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: playerIntervalField; width: 100; height: 30; text: String(Config.playerUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                        color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue() { var n=Number(text); if(!isFinite(n)) n=Config.playerUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.playerUpdateInterval=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ var n=Math.max(200,Math.min(10000,Config.playerUpdateInterval+root.wheelDelta(wheel, 100))); Config.playerUpdateInterval=n; playerIntervalField.text=String(n); settings.save(); wheel.accepted=true } }
                    }
                }

                SettingsPlayerSection {
                    id: playerSectionSettingsSection
                    visible: root.currentOtherTab === 2
                    width: parent.width
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
                Row {
                    visible: root.currentOtherTab === 1 && root.currentOtherSubTab === 3
                    width: parent.width
                    height: 30
                    spacing: 8
                    Text { width: 210; text: "Таймеры"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsTextField { id: timerRowSpacingField; width: 58; height: 30; text: String(Config.timerRowSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                                            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowSpacing; n=Math.max(0,Math.min(50,Math.round(n))); Config.timerRowSpacing=n; text=String(n); settings.save() }
                                            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowSpacingField.applyValue(Config.timerRowSpacing+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                                        }
                    SettingsTextField { id: timerRowTopField; width: 58; height: 30; text: String(Config.timerRowTopMargin); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                                            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowTopMargin; n=Math.max(0,Math.min(50,Math.round(n / 1) * 1)); Config.timerRowTopMargin=n; text=String(n); settings.save() }
                                            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowTopField.applyValue(Config.timerRowTopMargin+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                                        }
                    SettingsTextField { id: timerRowRightField; width: 58; height: 30; text: String(Config.timerRowRightMargin); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                                            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerRowRightMargin; n=Math.max(0,Math.min(50,Math.round(n / 1) * 1)); Config.timerRowRightMargin=n; text=String(n); settings.save() }
                                            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerRowRightField.applyValue(Config.timerRowRightMargin+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                                        }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1 && root.currentOtherSubTab === 3
                    Text { width: 210; text: "Анимация появления кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsTextField { id: timerFadeField; width: 100; height: 30; text: String(Config.timerButtonFadeDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                        color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonFadeDuration=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerFadeField.applyValue(Config.timerButtonFadeDuration+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1 && root.currentOtherSubTab === 3
                    Text { width: 210; text: "Сдвиг кнопок (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsTextField { id: timerSlideField; width: 100; height: 30; text: String(Config.timerButtonSlideDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                        color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonSlideDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonSlideDuration=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerSlideField.applyValue(Config.timerButtonSlideDuration+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: root.currentOtherTab === 1 && root.currentOtherSubTab === 3
                    Text { width: 210; text: "Исчезновение иконки (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsTextField { id: timerIconFadeField; width: 100; height: 30; text: String(Config.timerButtonIconFadeDuration); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
                        color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.timerButtonIconFadeDuration; n=Math.max(0,Math.min(5000,Math.round(n / 1) * 1)); Config.timerButtonIconFadeDuration=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ timerIconFadeField.applyValue(Config.timerButtonIconFadeDuration+root.wheelDelta(wheel, 1)); wheel.accepted=true } }
                    }
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

        // -------------------- Modules --------------------
        Flickable {
            id: modulesFlick
            visible: root.currentTab === 0
            width: parent.width
            height: parent.height - y
            contentWidth: Math.max(width, modulesColumn.width)
            contentHeight: modulesColumn.height
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
            ScrollBar.vertical: SettingsScrollBar { visible: modulesFlick.contentHeight > modulesFlick.height + 1 }

            Column {
                id: modulesColumn
                width: modulesFlick.width - 12
                spacing: 10

                Row {
                    width: parent.width
                    height: 32
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
                    height: 18
                    spacing: 6

                    Item { width: 110; height: 18 }

                    Repeater {
                        model: ["X", "Y", "Width", "Height"]
                        delegate: Text {
                            width: 60
                            height: 18
                            text: modelData
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text { width: 42; height: 18; text: "Рамка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 42; height: 18; text: "Фон"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 42; height: 18; text: "Сброс"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }

                Repeater {
                    model: settings.moduleNames

                    delegate: Row {
                        id: moduleRow
                        width: parent.width
                        height: 30
                        spacing: 6
                        property string moduleName: modelData

                        SettingsCheckBox {
                            id: enabledBox
                            width: 110
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

                            delegate: SettingsTextField {
                                id: geometryField
                                width: 60
                                height: 30
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
                                    color: Config.settingsBackground
                                    border.color: (geometryField.activeFocus || geometryField.pointerHovered) ? Config.accent : Config.baseColor
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

                        SettingsCheckBox {
                            id: frameBox
                            width: 42
                            height: 30
                            text: ""
                            indicatorOnly: true
                            checked: settings.moduleFrames[moduleRow.moduleName] !== false
                            onToggled: {
                                var values = Object.assign({}, settings.moduleFrames)
                                values[moduleRow.moduleName] = checked
                                settings.moduleFrames = values
                                settings.save()
                            }
                        }

                        SettingsCheckBox {
                            id: backgroundBox
                            width: 42
                            height: 30
                            text: ""
                            indicatorOnly: true
                            checked: settings.moduleBackgrounds[moduleRow.moduleName] !== false
                            onToggled: {
                                var values = Object.assign({}, settings.moduleBackgrounds)
                                values[moduleRow.moduleName] = checked
                                settings.moduleBackgrounds = values
                                settings.save()
                            }
                        }

                        SettingsResetButton {
                            width: 42
                            height: 30
                            tooltip: "Сбросить настройки модуля"
                            onClicked: settings.resetModule(moduleRow.moduleName)
                        }
                    }
                }

                Item { width: 1; height: 4 }

                Row {
                    width: parent.width
                    height: 46
                    spacing: 10

                    Rectangle {
                        id: layoutEditButton
                        width: 270
                        height: 46
                        radius: Config.frameRadius
                        color: layoutEditMouse.containsMouse ? Config.accent : "transparent"
                        border.color: Config.accent
                        border.width: Math.max(1, Config.frameBorderWidth)

                        Text {
                            anchors.fill: parent
                            text: "УМНОЕ РЕДАКТИРОВАНИЕ"
                            color: layoutEditMouse.containsMouse ? Config.black : Config.accent
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
                        text: "Скрывает окно настроек и позволяет перетаскивать видимые блоки мышью.\nEsc — завершить редактирование и вернуться сюда."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // -------------------- Colors --------------------
        SettingsColorsSection {
            id: colorsSectionSettingsSection
            host: root
            settings: root.settings
        }
}

}