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
    readonly property bool quickSaveProfileAvailable: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("all")
    readonly property string currentOtherSaveScope: {
        if (root.currentOtherTab === 0) return root.currentOtherSubTab === 0 ? "general" : ""
        return ["general", "timer", "player", "weather", "cava", "cpu", "network", "volume", "calendar", "settingsWindow", "mopidy", "launcher"][root.currentOtherTab] || ""
    }
    readonly property bool quickSaveSectionAvailable: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && root.currentOtherSaveScope !== "" && settings.hasResetChanges(root.currentOtherSaveScope)
    readonly property bool currentOtherResetAvailable: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && !(root.currentOtherTab === 0 && (root.currentOtherSubTab === 1 || root.currentOtherSubTab === 2)) && root.currentOtherSaveScope !== "" && settings.hasResetChanges(root.currentOtherSaveScope)
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

    // Stable IDs keep the internal routing fixed while users customize sidebar labels/order.
    readonly property var settingsTabDefinitions: [
        { id: "modules", defaultLabel: "Модули" },
        { id: "themes", defaultLabel: "Темы" },
        { id: "general", defaultLabel: "Общие" },
        { id: "timers", defaultLabel: "Таймеры" },
        { id: "player", defaultLabel: "Плеер" },
        { id: "mopidy", defaultLabel: "Mopidy" },
        { id: "weather", defaultLabel: "Погода" },
        { id: "cava", defaultLabel: "CAVA" },
        { id: "cpuRam", defaultLabel: "CPU/RAM" },
        { id: "network", defaultLabel: "Сеть" },
        { id: "volume", defaultLabel: "Громкость" },
        { id: "calendar", defaultLabel: "Календарь" },
        { id: "launcher", defaultLabel: "Лаунчер" },
        { id: "settingsWindow", defaultLabel: "Окно настроек" }
    ]
    readonly property var otherTabSettingsIds: ["general", "timers", "player", "weather", "cava", "cpuRam", "network", "volume", "calendar", "settingsWindow", "mopidy", "launcher"]

    function defaultSettingsTabLabel(id) {
        for (var i = 0; i < root.settingsTabDefinitions.length; ++i)
            if (root.settingsTabDefinitions[i].id === id) return root.settingsTabDefinitions[i].defaultLabel
        return "Настройки"
    }

    function settingsTabLabelForId(id) {
        var labels = Config.settingsTabLabels || ({})
        var label = labels[id] === undefined || labels[id] === null ? "" : String(labels[id]).trim()
        return label || root.defaultSettingsTabLabel(id)
    }

    function settingsTabOrderNormalized() {
        var result = []
        var seen = ({})
        var saved = Config.settingsTabOrder
        if (saved instanceof Array) {
            for (var i = 0; i < saved.length; ++i) {
                // Runtime guard mirrors the loader normalization in case a
                // damaged settings object is assigned before normalization.
                if (typeof saved[i] !== "string") continue
                var id = saved[i]
                var known = false
                for (var d = 0; d < root.settingsTabDefinitions.length; ++d)
                    if (root.settingsTabDefinitions[d].id === id) { known = true; break }
                if (known && !seen[id]) { seen[id] = true; result.push(id) }
            }
        }
        for (var j = 0; j < root.settingsTabDefinitions.length; ++j) {
            var fallbackId = root.settingsTabDefinitions[j].id
            if (!seen[fallbackId]) result.push(fallbackId)
        }
        return result
    }

    readonly property var settingsNavigationItems: {
        var order = root.settingsTabOrderNormalized()
        var rows = []
        for (var i = 0; i < order.length; ++i)
            rows.push({ id: order[i], label: root.settingsTabLabelForId(order[i]) })
        return rows
    }

    function isSettingsTabSelected(id) {
        if (id === "modules") return root.currentTab === 0
        if (id === "themes") return root.currentTab === 1
        return root.currentTab === 2 && root.otherTabSettingsIds.indexOf(id) === root.currentOtherTab
    }

    // Subtabs and frames use narrow selectors against the same cached sparse
    // overrides as sidebar indicators. Keep selectors explicit so unrelated
    // sibling fields don't light up every subtab.
    function settingsSubTabChangeSpec(tab, sub) {
        var specs = {
            0: [
                { keys: ["font", "fontSize", "ledFont", "frameBorderWidth", "frameRadius", "backgroundBlurRadius"] },
                null,
                null
            ],
            1: [
                { keys: ["timerWheelStep", "timerMinHeight", "timerRowRightMargin", "timerRowSpacing", "timerRowTopMargin", "timerPresetDefaults"] },
                { prefixes: ["timerFinished"] },
                { prefixes: ["timerIcon", "timerAlarmIcon"], keys: ["timerIconOrder"] },
                { keys: ["timerMinHeight", "timerRowRightMargin", "timerRowSpacing", "timerRowTopMargin", "timerCommentAlignFurthest", "timerCommentGap", "timerCommentMaxLength", "timerCommentWidth"] },
                { prefixes: ["animationTimer", "timerButton"], exclude: ["animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration"] },
                { keys: ["animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration"] }
            ],
            2: [
                { keys: ["playerPriority", "playerFont", "playerBoldArtist", "playerUpdateInterval"] },
                { prefixes: ["playerSilence"] },
                { prefixes: ["playerTime"] },
                { prefixes: ["playerMeta", "playerMetadata"], keys: ["playerFont", "playerBoldArtist", "playerTextOutlineColor", "playerTextOutlineEnabled"] },
                { prefixes: ["playerNextIcon", "playerPausedIcon", "playerPlayingIcon"] },
                { prefixes: ["playerProgress"], keys: ["playerShowProgress"], nested: { colors: ["playerProgressFill", "playerProgressTrack"] } },
                { prefixes: ["playerCover"], nested: { colors: ["playerOverlay"] } }
            ],
            3: [
                { keys: ["weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes", "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds"] },
                { prefixes: ["weatherIcon", "weatherWind", "weatherArrow"], keys: ["weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherComfortY", "weatherDescriptionFontSize", "weatherShowComfort", "weatherPressureFontSize", "weatherPressureUnitFontSize", "weatherPressureUnitX", "weatherPressureUnitY", "weatherPressureValueWidth", "weatherTempOffsetX", "weatherTempOffsetY", "weatherTempWidth", "weatherTempX"] },
                { prefixes: ["weatherHourly"], exclude: ["weatherHourlyIntervalMinutes"] },
                { prefixes: ["weatherDaily"], exclude: ["weatherDailyIntervalMinutes"] }
            ],
            4: [
                { keys: ["cavaMode", "cavaFramerate", "cavaHideWhenSilent", "cavaHideZeroBars"] },
                { keys: ["cavaBars", "cavaRowSpacing", "cavaBarWidthRatio"] }
            ],
            5: [
                { keys: ["cpuUpdateInterval", "cpuShowRam", "cpuBarDirection", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarThickness", "cpuBarWidth", "cpuLabelLeftPadding", "cpuRowHeight", "cpuRowSpacing"] },
                { prefixes: ["cpuGraph"] },
                { prefixes: ["topApps"], nested: { colors: ["topAppsCpuBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarColor", "topAppsRamBarTrackColor"] } }
            ],
            6: [
                { keys: ["systemMonitorInterval"] },
                { prefixes: ["network"] }
            ],
            7: [
                { keys: ["volumeIcon", "volumeMutedIcon"] },
                { keys: ["volumeUpdateInterval", "volumeShowStreams", "volumeMaxHeight", "volumeMinHeight"] },
                { prefixes: ["volumeMainTrack", "volumeStreamTrack", "volumeTrack"], keys: ["volumeMainIconWidth", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeStreamLabelFontSize"], nested: { colors: ["volumeTrack", "volumeFill"] } },
                { prefixes: ["volumeStream"] , keys: ["volumeShowStreams"] },
                { keys: ["volumeMinHeight", "volumeMaxHeight", "volumeHorizontalPadding", "volumeVerticalPadding"] }
            ],
            8: [
                { keys: ["calendarAlwaysVisible", "calendarArrowY", "calendarNextIcon", "calendarNextSize", "calendarNextX", "calendarPreviousIcon", "calendarPreviousSize", "calendarPreviousX", "calendarTitleFont", "calendarTitleFontSize", "calendarTitleY", "calendarDayFont", "calendarDayFontSize", "calendarDayY", "calendarWeekdayFont", "calendarWeekdayFontSize", "calendarWeekdayY"] },
                { keys: ["calendarAdjacentDaysColor", "calendarPastDaysColor", "calendarPastDaysColorEnabled", "calendarWeekendColor", "calendarNoteFrameColor"], nested: { colors: ["calendarBackground"] } },
                { prefixes: ["calendarNote"], keys: ["calendarNoteMarkerPosition", "calendarNoteMarkerStyle", "calendarNoteFrameColor"] },
                { prefixes: ["animationCalendar"] }
            ],
            9: [
                { keys: ["settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing"] },
                { keys: ["settingsGeometry", "settingsMonitorName", "settingsBackground", "settingsBorder", "animationSettingsVisibilityStyle"], nested: { colors: ["settingsBackground", "settingsBorder"], moduleBlurEnabled: ["settings"] } },
                { keys: ["settingsTabOrder", "settingsTabLabels"] }
            ],
            10: [
                { keys: ["mopidyAlbumBold", "mopidyAlbumSeparator", "mopidyBackground", "mopidyGroupAlbums", "mopidyHoverColor", "mopidyHoverMode", "mopidyShowTrackNumbers", "mopidyShowVolumePercent", "mopidyToggleWithPlayerRightClick", "mopidyVolumeStep", "animationMopidyVisibilityStyle"] },
                { prefixes: ["mopidyTrack", "mopidyArtist", "mopidyAlbum", "mopidyDuration", "mopidyQueueDuration"], keys: ["mopidyShowAlbumRemaining", "mopidyShowQueueTotalDuration", "mopidyShowTrackRemaining"] },
                { prefixes: ["mopidyAddIcon", "mopidyClearIcon", "mopidyMoveDownIcon", "mopidyMoveUpIcon", "mopidyOpenAddIcon", "mopidyPlaylistDeleteIcon", "mopidyRefreshIcon", "mopidyRepeatIcon", "mopidyShuffleIcon", "mopidyStopIcon", "mopidySwitchPlaylistIcon", "mopidyVolumeIcon"], keys: ["mopidyTopIconOrder", "mopidyHideTopPanel", "mopidyTopPanelHoverHeight", "mopidyTopPanelOffsetY", "mopidyControlIconColor"] },
                { prefixes: ["mopidyStatus"], keys: ["mopidyEmptyQueueText", "mopidyUnavailableText"] }
            ],
            11: [
                { keys: ["launcherBackdropOpacity", "launcherBackground", "launcherDefaultMode", "launcherItemHeight", "launcherItemRadius", "launcherRadius", "launcherSearchBackground", "launcherSearchFont", "launcherSearchFontSize", "launcherSearchHeight", "launcherSearchPlaceholder", "launcherSearchRadius", "launcherShowResultCount", "launcherTitleBold", "launcherTitleColor", "launcherTitleFont", "launcherTitleFontSize", "launcherTitleLetterSpacing", "launcherTitleText", "launcherTitleY"] },
                { keys: ["launcherTabIcons", "launcherTabLabels", "launcherTabOrder", "launcherTabVisible", "launcherCrossSearchCalculator", "launcherCrossSearchProjects", "launcherCrossSearchRunHistory"] },
                { keys: ["launcherProjects"] }
            ]
        }
        var row = specs[Number(tab)]
        if (!row || Number(sub) < 0 || Number(sub) >= row.length) return null
        return row[Number(sub)]
    }

    function settingsSubTabHasChanges(tab, sub) {
        var spec = root.settingsSubTabChangeSpec(tab, sub)
        return spec !== null && settings.hasResetChanges("keys", spec)
    }

    // Use the cached sparse profile overrides to mark sections with changes.
    // This deliberately reuses hasResetChanges() so indicators do not trigger
    // their own full settings snapshot/diff calculations.
    function settingsTabHasChanges(id) {
        if (!settings || !settings.activeProfile || !settings.profiles
                || settings.activeProfile.length === 0
                || settings.profiles[settings.activeProfile] === undefined)
            return false
        var scopes = {
            modules: "modules", themes: "themes", general: "general",
            timers: "timer", player: "player", mopidy: "mopidy",
            weather: "weather", cava: "cava", cpuRam: "cpu",
            network: "network", volume: "volume", calendar: "calendar",
            launcher: "launcher", settingsWindow: "settingsWindow"
        }
        var scope = scopes[String(id)] || ""
        return scope !== "" && settings.hasResetChanges(scope)
    }

    function selectSettingsTab(id) {
        root.clearSettingsFocus()
        if (id === "modules") { root.currentTab = 0; return }
        if (id === "themes") { root.currentTab = 1; return }
        var index = root.otherTabSettingsIds.indexOf(id)
        if (index < 0) return
        root.currentTab = 2
        root.currentOtherTab = index
    }

    function setSettingsTabLabel(id, value) {
        if (root.defaultSettingsTabLabel(id) === "Настройки" && id !== "settingsWindow") return
        var labels = Object.assign({}, Config.settingsTabLabels || ({}))
        var label = String(value === undefined || value === null ? "" : value).trim().slice(0, 32)
        labels[id] = label || root.defaultSettingsTabLabel(id)
        Config.settingsTabLabels = labels
        root.settings.save()
    }

    function moveSettingsTab(id, delta) {
        var order = root.settingsTabOrderNormalized()
        var from = order.indexOf(id)
        var to = from + Number(delta)
        if (from < 0 || to < 0 || to >= order.length || to === from) return
        var temporary = order[from]
        order[from] = order[to]
        order[to] = temporary
        Config.settingsTabOrder = order
        root.settings.save()
    }

    readonly property string currentOtherTabTitle: {
        var main = root.settingsTabLabelForId(root.otherTabSettingsIds[root.currentOtherTab]) || "Настройки"
        var subtabs = root.currentOtherSubTabs
        var sub = subtabs[root.currentOtherSubTab] || ""
        return (main + (sub ? " · " + sub : "")).toLocaleUpperCase()
    }

    readonly property var currentOtherSubTabs: {
        switch (root.currentOtherTab) {
        case 0: return ["Интерфейс", "Профили", "Хранилища"]
        case 1: return ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации", "Опции таймера"]
        case 2: return ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон"]
        case 3: return ["Общие", "Сейчас", "По часам", "По дням"]
        case 4: return ["Основные", "Полосы"]
        case 5: return ["Общие", "График CPU", "Top Apps"]
        case 6: return ["Обновления", "Сеть"]
        case 7: return ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность"]
        case 8: return ["Разметка", "Цвета", "Метки заметок", "Анимации"]
        case 9: return ["Интерфейс", "Окно настроек", "Вкладки"]
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
                    model: root.settingsNavigationItems

                    delegate: SettingsSubTab {
                        width: mainSettingsTabs.width
                        selected: root.isSettingsTabSelected(modelData.id)
                        modified: root.settingsTabHasChanges(modelData.id)
                        text: modelData.label
                        leftAligned: true
                        horizontalPadding: 8
                        onClicked: root.selectSettingsTab(modelData.id)
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
                                    width: parent.width - (root.quickSaveProfileAvailable ? 38 : 0) - (root.quickSaveSectionAvailable ? 38 : 0) - (root.currentOtherResetAvailable ? 38 : 0)
                                    text: root.currentOtherTabTitle
                                    color: Config.accent
                                    font.family: Config.settingsFont
                                    font.pixelSize: Config.settingsUiSize(15)
                                    verticalAlignment: Text.AlignVCenter
                                }
                                SettingsButton {
                                    width: 30
                                    height: 30
                                    visible: root.quickSaveProfileAvailable
                                    enabled: root.quickSaveProfileAvailable
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
                                    visible: root.quickSaveSectionAvailable
                                    enabled: visible
                                    text: ""
                                    iconText: "\uf0c7"
                                    fontSize: 11
                                    tooltip: "Сохранить изменения этого раздела в активный профиль"
                                    backgroundColor: Config.settingsBackground
                                    onClicked: settings.saveProfileScope(settings.activeProfile, root.currentOtherSaveScope)
                                }
                                SettingsResetButton {
                                    enabled: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined
                                    visible: root.currentOtherResetAvailable
                                    actionAvailable: root.currentOtherTab === 0 ? settings.hasResetChanges("general")
                                        : root.currentOtherTab === 1 ? settings.hasResetChanges("timer")
                                        : root.currentOtherTab === 2 ? settings.hasResetChanges("player")
                                        : root.currentOtherTab === 3 ? settings.hasResetChanges("weather")
                                        : root.currentOtherTab === 4 ? settings.hasResetChanges("cava")
                                        : root.currentOtherTab === 5 ? settings.hasResetChanges("cpu")
                                        : root.currentOtherTab === 6 ? settings.hasResetChanges("network")
                                        : root.currentOtherTab === 7 ? settings.hasResetChanges("volume")
                                        : root.currentOtherTab === 8 ? settings.hasResetChanges("calendar")
                                        : root.currentOtherTab === 9 ? settings.hasResetChanges("settingsWindow")
                                        : root.currentOtherTab === 10 ? settings.hasResetChanges("mopidy")
                                        : root.currentOtherTab === 11 ? settings.hasResetChanges("launcher") : false
                                    tooltip: "Сбросить текущую вкладку"
                                    onClicked: {
                                        if (root.currentOtherTab === 0 && root.currentOtherSubTab === 0) settings.resetGeneralSettings()
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
                                        modified: root.settingsSubTabHasChanges(root.currentOtherTab, index)
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
