import QtQuick
import QtQuick.Controls
import "../.."
import "primitives"
import "sections"
import "../../js/settings/SettingsSearch.js" as SettingsSearch
import "../../js/settings/SettingsPageRegistry.js" as SettingsPageRegistry
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
    property string currentPageId: "modules"
    property int currentPageSubTabIndex: 0
    property bool settingsMoveMode: false
    readonly property bool quickSaveProfileAvailable: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && settings.hasResetChanges("all")
    readonly property string currentPageSaveScope: SettingsPageRegistry.saveScopeForPageId(
        root.currentPageId, root.currentPageSubTabIndex)
    readonly property bool quickSavePageAvailable: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && root.currentPageSaveScope !== "" && settings.hasResetChanges(root.currentPageSaveScope)
    readonly property bool currentPageResetAvailable: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined && !(root.currentPageId === "general" && (root.currentPageSubTabIndex === 1 || root.currentPageSubTabIndex === 2)) && root.currentPageSaveScope !== "" && settings.hasResetChanges(root.currentPageSaveScope)
    property var settingsSearchIndex: []
    property var settingsSearchResults: []
    property string settingsSearchQuery: ""
    property int settingsSearchSelectedIndex: 0
    property int settingsSearchCandidateSubTab: 0
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
        root.currentPageId = "weather"
        root.currentPageSubTabIndex = 0
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

    onCurrentPageIdChanged: {
        if (modulesSectionSettingsSection) modulesSectionSettingsSection.resetScroll()
        if (colorsSectionSettingsSection) colorsSectionSettingsSection.resetScroll()
        if (otherFlick) otherFlick.contentY = 0
        root.currentPageSubTabIndex = 0
    }

    // Stable page IDs, labels and non-core routes are owned by a dedicated
    // registry. User-customized labels/order remain in Config and profiles.
    readonly property var settingsTabDefinitions: SettingsPageRegistry.tabDefinitions()

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
        return root.currentPageId === String(id)
    }

    // Subtabs and frames use narrow selectors against the same cached sparse
    // overrides as sidebar indicators. Keep selectors explicit so unrelated
    // sibling fields don't light up every subtab.
    function settingsSubTabChangeSpec(pageId, sub) {
        var specs = {
            "general": [
                { keys: ["font", "fontSize", "ledFont", "frameBorderWidth", "frameRadius", "backgroundBlurRadius"] },
                null,
                null
            ],
            "timers": [
                { keys: ["timerWheelStep", "timerMinHeight", "timerRowRightMargin", "timerRowSpacing", "timerRowTopMargin", "timerPresetDefaults", "timerRandomColorMode", "timerRandomColorMin", "timerRandomColorMax"] },
                { prefixes: ["timerFinished"] },
                { prefixes: ["timerIcon", "timerAlarmIcon"], keys: ["timerIconOrder"] },
                { keys: ["timerMinHeight", "timerRowRightMargin", "timerRowSpacing", "timerRowTopMargin", "timerCommentAlignFurthest", "timerCommentGap", "timerCommentMaxLength", "timerCommentWidth"] },
                { prefixes: ["animationTimer", "timerButton"], exclude: ["animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration"] },
                { prefixes: ["timerOptionsCommentIcon", "timerOptionsDurationIcon", "timerOptionsRefreshIcon", "timerOptionsPauseIcon", "timerOptionsColorIcon"], keys: ["timerOptionsActionIconOrder", "animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration"] }
            ],
            "player": [
                { keys: ["playerPriority", "playerFont", "playerBoldArtist", "playerUpdateInterval"] },
                { prefixes: ["playerSilence"] },
                { prefixes: ["playerTime"] },
                { prefixes: ["playerMeta", "playerMetadata"], keys: ["playerFont", "playerBoldArtist", "playerTextOutlineColor", "playerTextOutlineEnabled"] },
                { prefixes: ["playerNextIcon", "playerPausedIcon", "playerPlayingIcon"] },
                { prefixes: ["playerProgress"], keys: ["playerShowProgress"], nested: { colors: ["playerProgressFill", "playerProgressTrack"] } },
                { prefixes: ["playerCover"], nested: { colors: ["playerOverlay"] } }
            ],
            "weather": [
                { keys: ["weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes", "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds"] },
                { prefixes: ["weatherIcon", "weatherWind", "weatherArrow", "weatherTemp", "weatherPressure", "weatherDescription"], keys: ["weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherComfortY", "weatherMiddleBlockWidth", "weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment", "weatherShowComfort"] },
                { prefixes: ["weatherHourly"], exclude: ["weatherHourlyIntervalMinutes"] },
                { prefixes: ["weatherDaily"], exclude: ["weatherDailyIntervalMinutes"] }
            ],
            "cava": [
                { keys: ["cavaMode", "cavaFramerate", "cavaHideWhenSilent", "cavaHideZeroBars"] },
                { keys: ["cavaBars", "cavaRowSpacing", "cavaBarWidthRatio"] }
            ],
            "cpuRam": [
                { keys: ["cpuUpdateInterval", "cpuShowRam", "cpuBarDirection", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarThickness", "cpuBarWidth", "cpuLabelLeftPadding", "cpuRowHeight", "cpuRowSpacing"] },
                { prefixes: ["cpuGraph"] },
                { prefixes: ["topApps"], nested: { colors: ["topAppsCpuBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarColor", "topAppsRamBarTrackColor"] } }
            ],
            "network": [
                { keys: ["systemMonitorInterval"] },
                { prefixes: ["network"], keys: ["networksAlwaysVisible"] }
            ],
            "volume": [
                { keys: ["volumeIcon", "volumeMutedIcon"] },
                { keys: ["volumeUpdateInterval", "volumeShowStreams", "volumeMaxHeight", "volumeMinHeight"] },
                { prefixes: ["volumeMainTrack", "volumeStreamTrack", "volumeTrack"], keys: ["volumeMainIconWidth", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeStreamLabelFontSize"], nested: { colors: ["volumeTrack", "volumeFill"] } },
                { prefixes: ["volumeStream"] , keys: ["volumeShowStreams"] },
                { keys: ["volumeMinHeight", "volumeMaxHeight", "volumeHorizontalPadding", "volumeVerticalPadding"] },
                { keys: ["animationVolumeStreamsVisibilityStyle", "volumeStreamsAnimationDuration"] }
            ],
            "calendar": [
                { keys: ["calendarAlwaysVisible", "calendarArrowY", "calendarNextIcon", "calendarNextSize", "calendarNextX", "calendarPreviousIcon", "calendarPreviousSize", "calendarPreviousX", "calendarTitleFont", "calendarTitleFontSize", "calendarTitleY", "calendarDayFont", "calendarDayFontSize", "calendarDayY", "calendarWeekdayFont", "calendarWeekdayFontSize", "calendarWeekdayY"] },
                { keys: ["calendarAdjacentDaysColor", "calendarPastDaysColor", "calendarPastDaysColorEnabled", "calendarWeekendColor", "calendarNoteFrameColor"], nested: { colors: ["calendarBackground"] } },
                { prefixes: ["calendarNote"], keys: ["calendarNoteMarkerPosition", "calendarNoteMarkerStyle", "calendarNoteFrameColor"] },
                { prefixes: ["animationCalendar"] }
            ],
            "settingsWindow": [
                { keys: ["settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing"] },
                { keys: ["settingsGeometry", "settingsMonitorName", "settingsBackground", "settingsBorder", "animationSettingsVisibilityStyle"], nested: { colors: ["settingsBackground", "settingsBorder"], moduleBlurEnabled: ["settings"] } },
                { keys: ["settingsTabOrder", "settingsTabLabels"] }
            ],
            "mopidy": [
                { keys: ["mopidyAlbumBold", "mopidyAlbumSeparator", "mopidyBackground", "mopidyGroupAlbums", "mopidyHoverColor", "mopidyHoverMode", "mopidyShowTrackNumbers", "mopidyShowVolumePercent", "mopidyToggleWithPlayerRightClick", "mopidyVolumeStep", "animationMopidyVisibilityStyle"] },
                { prefixes: ["mopidyTrack", "mopidyArtist", "mopidyAlbum", "mopidyDuration", "mopidyQueueDuration"], keys: ["mopidyShowAlbumRemaining", "mopidyShowQueueTotalDuration", "mopidyShowTrackRemaining"] },
                { prefixes: ["mopidyAddIcon", "mopidyClearIcon", "mopidyMoveDownIcon", "mopidyMoveUpIcon", "mopidyOpenAddIcon", "mopidyPlaylistDeleteIcon", "mopidyRefreshIcon", "mopidyRepeatIcon", "mopidyShuffleIcon", "mopidyStopIcon", "mopidySwitchPlaylistIcon", "mopidyVolumeIcon"], keys: ["mopidyTopIconOrder", "mopidyHideTopPanel", "mopidyTopPanelHoverHeight", "mopidyTopPanelOffsetY", "mopidyControlIconColor"] },
                { prefixes: ["mopidyStatus"], keys: ["mopidyEmptyQueueText", "mopidyUnavailableText"] }
            ],
            "launcher": [
                { keys: ["launcherBackdropOpacity", "launcherBackground", "launcherDefaultMode", "launcherItemHeight", "launcherItemRadius", "launcherRadius", "launcherSearchBackground", "launcherSearchFont", "launcherSearchFontSize", "launcherSearchHeight", "launcherSearchPlaceholder", "launcherSearchRadius", "launcherShowResultCount", "launcherTitleBold", "launcherTitleColor", "launcherTitleFont", "launcherTitleFontSize", "launcherTitleLetterSpacing", "launcherTitleText", "launcherTitleY"] },
                { keys: ["launcherTabIcons", "launcherTabLabels", "launcherTabOrder", "launcherTabVisible", "launcherCrossSearchCalculator", "launcherCrossSearchProjects", "launcherCrossSearchRunHistory"] },
                { keys: ["launcherProjects"] }
            ],
            "notifications": [
                { keys: ["notificationsDefaultTimeout", "notificationsCriticalTimeout"] },
                { keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] },
                { keys: ["notificationsVerticalAnchor"] }
            ]
        }
        var row = specs[String(pageId)]
        if (!row || Number(sub) < 0 || Number(sub) >= row.length) return null
        return row[Number(sub)]
    }

    function settingsSubTabHasChanges(pageId, sub) {
        var spec = root.settingsSubTabChangeSpec(pageId, sub)
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
            launcher: "launcher", notifications: "notifications", settingsWindow: "settingsWindow"
        }
        var scope = scopes[String(id)] || ""
        return scope !== "" && settings.hasResetChanges(scope)
    }

    function settingsSearchPageInfo(item, inheritedPageId, inheritedPageRoot) {
        var pageId = inheritedPageId || ""
        var pageRoot = inheritedPageRoot || null
        var objectName = item && item.objectName !== undefined ? String(item.objectName) : ""
        var prefix = "settings-search-page:"
        if (objectName.indexOf(prefix) === 0) {
            pageId = objectName.slice(prefix.length)
            pageRoot = item
        }
        return { id: pageId, root: pageRoot }
    }

    function settingsSearchSiblingLabel(item) {
        if (!item || !item.parent || !item.parent.children)
            return ""
        var siblings = item.parent.children
        var itemIndex = -1
        for (var i = 0; i < siblings.length; ++i) {
            if (siblings[i] === item) { itemIndex = i; break }
        }
        if (itemIndex < 0)
            return ""
        for (var j = itemIndex - 1; j >= 0; --j) {
            var candidate = siblings[j]
            if (!candidate || candidate.text === undefined || candidate.font === undefined)
                continue
            var text = String(candidate.text || "").trim()
            if (text.length > 0 && candidate.visible !== false)
                return text
        }
        return ""
    }

    function settingsSearchItemLabel(item) {
        if (!item)
            return ""
        if (item.settingsSearchLabel !== undefined && String(item.settingsSearchLabel).trim().length > 0)
            return String(item.settingsSearchLabel).trim()
        var preferSibling = item.settingsSearchUseSiblingLabel === true
        if (preferSibling) {
            var siblingLabel = root.settingsSearchSiblingLabel(item)
            if (siblingLabel.length > 0)
                return siblingLabel
        }
        if (item.label !== undefined && String(item.label).trim().length > 0)
            return String(item.label).trim()
        if (item.text !== undefined && String(item.text).trim().length > 0 && !preferSibling)
            return String(item.text).trim()
        var fallbackSibling = root.settingsSearchSiblingLabel(item)
        if (fallbackSibling.length > 0)
            return fallbackSibling
        if (item.placeholderText !== undefined && String(item.placeholderText).trim().length > 0)
            return String(item.placeholderText).trim()
        return ""
    }

    function settingsSearchGroupHeading(item, pageRoot) {
        var current = item ? item.parent : null
        while (current && current !== pageRoot) {
            if (current.heading !== undefined && String(current.heading).trim().length > 0)
                return String(current.heading).trim()
            if (current.renderedHeading !== undefined && String(current.renderedHeading).trim().length > 0)
                return String(current.renderedHeading).trim()
            current = current.parent
        }
        return ""
    }

    function collectSettingsSearchItems(item, pageId, pageRoot, entries, ordinalByPage, idCounts) {
        if (!item)
            return
        var pageInfo = root.settingsSearchPageInfo(item, pageId, pageRoot)
        var activePageId = pageInfo.id
        var activePageRoot = pageInfo.root

        if (activePageId && activePageRoot && item.settingsSearchable === true) {
            var label = root.settingsSearchItemLabel(item)
            var targetKey = item.targetProperty !== undefined ? String(item.targetProperty || "") : ""
            var explicitId = item.settingsSearchId !== undefined ? String(item.settingsSearchId || "").trim() : ""
            if (label.length === 0)
                label = SettingsSearch.humanizeKey(targetKey || explicitId)
            if (label.length > 0) {
                var baseId = explicitId || targetKey || (activePageId + "/control-" + String(ordinalByPage[activePageId] || 0))
                ordinalByPage[activePageId] = Number(ordinalByPage[activePageId] || 0) + 1
                var occurrence = Number(idCounts[baseId] || 0)
                idCounts[baseId] = occurrence + 1
                var stableId = occurrence === 0 ? baseId : baseId + "#" + String(occurrence + 1)
                var group = root.settingsSearchGroupHeading(item, activePageRoot)
                var pageLabel = root.settingsTabLabelForId(activePageId)
                var keywords = item.settingsSearchKeywords !== undefined ? String(item.settingsSearchKeywords || "") : ""
                var keyTerms = SettingsSearch.keyTerms([label, group, activePageId, targetKey, explicitId].join(" "))
                var searchable = [label, group, pageLabel, activePageId, targetKey, explicitId, keywords, keyTerms].join(" ")
                entries.push({
                    id: stableId,
                    label: label,
                    group: group,
                    pageId: activePageId,
                    pageLabel: pageLabel,
                    target: item,
                    pageRoot: activePageRoot,
                    targetKey: targetKey,
                    keyTerms: [targetKey, explicitId, keyTerms].join(" "),
                    searchText: searchable
                })
            }
        }

        var children = item.children
        if (!children)
            return
        for (var childIndex = 0; childIndex < children.length; ++childIndex)
            root.collectSettingsSearchItems(children[childIndex], activePageId, activePageRoot, entries, ordinalByPage, idCounts)
    }

    function rebuildSettingsSearchIndex() {
        var entries = []
        root.collectSettingsSearchItems(root, "", null, entries, ({}), ({}))
        root.settingsSearchIndex = entries
        root.updateSettingsSearchResults(root.settingsSearchQuery)
    }

    function updateSettingsSearchResults(query) {
        root.settingsSearchQuery = String(query === undefined || query === null ? "" : query)
        root.settingsSearchResults = SettingsSearch.search(root.settingsSearchIndex, root.settingsSearchQuery, 7)
        root.settingsSearchSelectedIndex = 0
    }

    function isSettingsSearchTargetVisible(entry) {
        if (!entry || !entry.target || !entry.pageRoot)
            return false
        var current = entry.target
        while (current) {
            if (current.visible === false)
                return false
            if (current === entry.target && (Number(current.width) <= 0 || Number(current.height) <= 0))
                return false
            if (current === entry.pageRoot)
                return true
            current = current.parent
        }
        return false
    }

    function openSettingsSearchResult(entry) {
        if (!entry || !entry.target)
            return
        root.settingsSearchQuery = ""
        root.settingsSearchResults = []
        if (settingsSearchInput)
            settingsSearchInput.text = ""
        if (entry.pageId === "modules" || entry.pageId === "themes") {
            root.currentPageId = entry.pageId
            Qt.callLater(function() { root.finishSettingsSearchNavigation(entry) })
            return
        }
        if (!SettingsPageRegistry.hasOtherPageId(entry.pageId))
            return
        root.currentPageId = entry.pageId
        Qt.callLater(function() {
            root.settingsSearchCandidateSubTab = 0
            root.trySettingsSearchSubTab(entry)
        })
    }

    function trySettingsSearchSubTab(entry) {
        if (!entry || !entry.target)
            return
        var count = root.currentPageSubTabs.length
        if (root.settingsSearchCandidateSubTab >= count) {
            root.currentPageSubTabIndex = 0
            Qt.callLater(function() { root.finishSettingsSearchNavigation(entry) })
            return
        }
        root.currentPageSubTabIndex = root.settingsSearchCandidateSubTab
        Qt.callLater(function() {
            if (root.isSettingsSearchTargetVisible(entry)) {
                root.finishSettingsSearchNavigation(entry)
                return
            }
            root.settingsSearchCandidateSubTab += 1
            root.trySettingsSearchSubTab(entry)
        })
    }

    function findSettingsSearchFlickable(target) {
        var current = target ? target.parent : null
        while (current && current !== root) {
            if (current.contentY !== undefined && current.contentHeight !== undefined && current.contentItem)
                return current
            current = current.parent
        }
        return null
    }

    function finishSettingsSearchNavigation(entry) {
        if (!entry || !entry.target || !root.isSettingsSearchTargetVisible(entry))
            return
        var flickable = root.findSettingsSearchFlickable(entry.target)
        if (flickable) {
            var localPosition = entry.target.mapToItem(flickable.contentItem, 0, 0)
            var wantedY = Math.max(0, localPosition.y - 42)
            var maximumY = Math.max(0, flickable.contentHeight - flickable.height)
            flickable.contentY = Math.min(maximumY, wantedY)
        }
        Qt.callLater(function() { root.showSettingsSearchHighlight(entry.target) })
    }

    function showSettingsSearchHighlight(target) {
        if (!target || target.visible === false || target.width <= 0 || target.height <= 0)
            return
        var position = target.mapToItem(root, 0, 0)
        settingsSearchHighlight.x = Math.max(0, position.x - 3)
        settingsSearchHighlight.y = Math.max(0, position.y - 3)
        settingsSearchHighlight.width = Math.min(root.width, target.width + 6)
        settingsSearchHighlight.height = target.height + 6
        settingsSearchHighlight.visible = true
        settingsSearchHighlightTimer.restart()
    }

    function handleSettingsSearchKey(event) {
        if (event.key === Qt.Key_Down) {
            if (root.settingsSearchResults.length > 0)
                root.settingsSearchSelectedIndex = Math.min(root.settingsSearchResults.length - 1, root.settingsSearchSelectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (root.settingsSearchResults.length > 0)
                root.settingsSearchSelectedIndex = Math.max(0, root.settingsSearchSelectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.settingsSearchResults.length > 0)
                root.openSettingsSearchResult(root.settingsSearchResults[root.settingsSearchSelectedIndex])
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            root.settingsSearchQuery = ""
            root.settingsSearchResults = []
            if (settingsSearchInput)
                settingsSearchInput.text = ""
            root.clearSettingsFocus()
            event.accepted = true
        }
    }

    function selectSettingsTab(id) {
        var pageId = String(id || "")
        if (pageId !== "modules" && pageId !== "themes" && !SettingsPageRegistry.hasOtherPageId(pageId))
            return
        root.clearSettingsFocus()
        root.currentPageId = pageId
    }

    function resetCurrentSettingsPage() {
        switch (root.currentPageId) {
        case "general": settings.resetGeneralSettings(); break
        case "timers": settings.resetTimerSettings(); break
        case "player": settings.resetPlayerSettings(); break
        case "weather": settings.resetWeatherSettings(); break
        case "cava": settings.resetCavaSettings(); break
        case "cpuRam": settings.resetCpuSettings(); break
        case "network": settings.resetNetworkSettings(); break
        case "volume": settings.resetVolumeSettings(); break
        case "calendar": settings.resetCalendarSettings(); break
        case "settingsWindow": settings.resetSettingsWindow(); break
        case "mopidy": settings.resetMopidySettings(); break
        case "launcher": settings.resetLauncherSettings(); break
        case "notifications": settings.resetNotificationsSettings(); break
        }
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

    readonly property string currentPageTitle: {
        var main = root.settingsTabLabelForId(root.currentPageId) || "Настройки"
        var subtabs = root.currentPageSubTabs
        var sub = subtabs[root.currentPageSubTabIndex] || ""
        return (main + (sub ? " · " + sub : "")).toLocaleUpperCase()
    }

    readonly property var currentPageSubTabs: SettingsPageRegistry.subtabsForPageId(
        root.currentPageId)

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

    Connections {
        target: Config
        function onSettingsTabLabelsChanged() { Qt.callLater(root.rebuildSettingsSearchIndex) }
    }

    Component.onCompleted: {
        root.refreshProfileModel()
        Qt.callLater(root.rebuildSettingsSearchIndex)
    }

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
                width: Math.max(70, parent.width - settingsSearchInput.width - 260)
                text: "НАСТРОЙКИ"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(20)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsInputField {
                id: settingsSearchInput
                width: Math.min(220, Math.max(145, parent.width * 0.30))
                height: 28
                placeholderText: "Поиск настроек…"
                selectByMouse: true
                activeFocusOnTab: true
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                onTextChanged: root.updateSettingsSearchResults(text)
                onActiveFocusChanged: if (activeFocus) Qt.callLater(root.rebuildSettingsSearchIndex)
                Keys.onPressed: event => root.handleSettingsSearchKey(event)
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
                    objectName: "settings-search-page:modules"
                    host: root
                    settings: root.settings
                }

                SettingsColorsSection {
                    id: colorsSectionSettingsSection
                    objectName: "settings-search-page:themes"
                    host: root
                    settings: root.settings
                }

                Item {
                    id: otherSettingsArea
                    visible: root.currentPageId !== "modules" && root.currentPageId !== "themes"
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
                                    width: parent.width - (root.quickSaveProfileAvailable ? 38 : 0) - (root.quickSavePageAvailable ? 38 : 0) - (root.currentPageResetAvailable ? 38 : 0)
                                    text: root.currentPageTitle
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
                                    visible: root.quickSavePageAvailable
                                    enabled: visible
                                    text: ""
                                    iconText: "\uf0c7"
                                    fontSize: 11
                                    tooltip: "Сохранить изменения этого раздела в активный профиль"
                                    backgroundColor: Config.settingsBackground
                                    onClicked: settings.saveProfileScope(settings.activeProfile, root.currentPageSaveScope)
                                }
                                SettingsResetButton {
                                    enabled: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined
                                    visible: root.currentPageResetAvailable
                                    actionAvailable: root.currentPageSaveScope !== "" && settings.hasResetChanges(root.currentPageSaveScope)
                                    tooltip: "Сбросить текущую вкладку"
                                    onClicked: root.resetCurrentSettingsPage()
                                }
                            }

                            Row {
                                visible: root.currentPageSubTabs.length > 0
                                width: parent.width
                                height: 34
                                spacing: 5

                                Repeater {
                                    model: root.currentPageSubTabs

                                    delegate: SettingsSubTab {
                                        width: (parent.width - (root.currentPageSubTabs.length - 1) * 5) / root.currentPageSubTabs.length
                                        selected: root.currentPageSubTabIndex === index
                                        modified: root.settingsSubTabHasChanges(root.currentPageId, index)
                                        text: modelData
                                        onClicked: {
                                            root.clearSettingsFocus()
                                            root.currentPageSubTabIndex = index
                                            otherFlick.contentY = 0
                                        }
                                    }
                                }
                            }

                            SettingsCalendarSection {
                                id: calendarSectionSettingsSection
                                objectName: "settings-search-page:calendar"
                                host: root
                                settings: root.settings
                            }

                            SettingsWeatherSection {
                                id: weatherSectionSettingsSection
                                objectName: "settings-search-page:weather"
                                host: root
                                settings: root.settings
                            }

                            SettingsGeneralSection {
                                id: generalSectionSettingsSection
                                objectName: "settings-search-page:general"
                                host: root
                                settings: root.settings
                            }

                            SettingsGroup {
                                visible: root.currentPageId === "player" && root.currentPageSubTabIndex === 0
                                objectName: "settings-search-page:player"
                                width: parent.width
                                showFrame: true
                                padding: 8
                                contentSpacing: 6

                                SettingsNumberField {
                                    visible: root.currentPageId === "player" && root.currentPageSubTabIndex === 0
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
                                objectName: "settings-search-page:player"
                                visible: root.currentPageId === "player"
                                width: parent.width
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidySection {
                                id: mopidySectionSettingsSection
                                objectName: "settings-search-page:mopidy"
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidyTimeSection {
                                id: mopidyTimeSectionSettingsSection
                                objectName: "settings-search-page:mopidy"
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidyIconsSection {
                                id: mopidyIconsSectionSettingsSection
                                objectName: "settings-search-page:mopidy"
                                host: root
                                settings: root.settings
                            }
                            MopidySettings.SettingsMopidyStatusSection {
                                id: mopidyStatusSectionSettingsSection
                                objectName: "settings-search-page:mopidy"
                                host: root
                                settings: root.settings
                            }
                            SettingsCavaSection {
                                id: cavaSectionSettingsSection
                                objectName: "settings-search-page:cava"
                                host: root
                                settings: root.settings
                            }
                            SettingsCpuRamSection {
                                id: cpuRamSectionSettingsSection
                                objectName: "settings-search-page:cpuRam"
                                host: root
                                settings: root.settings
                            }
                            SettingsNetworkSection {
                                id: networkSectionSettingsSection
                                objectName: "settings-search-page:network"
                                host: root
                                settings: root.settings
                            }
                            SettingsVolumeSection {
                                id: volumeSectionSettingsSection
                                objectName: "settings-search-page:volume"
                                host: root
                                settings: root.settings
                            }
                            SettingsTimersSection {
                                id: timersSectionSettingsSection
                                objectName: "settings-search-page:timers"
                                visible: root.currentPageId === "timers"
                                width: parent.width
                                host: root
                                settings: root.settings
                            }
                            SettingsLauncherSection {
                                id: launcherSectionSettingsSection
                                objectName: "settings-search-page:launcher"
                                host: root
                                settings: root.settings
                            }
                            SettingsWindowSection {
                                id: settingsWindowSectionSettingsSection
                                objectName: "settings-search-page:settingsWindow"
                                host: root
                                settings: root.settings
                            }
                            SettingsNotificationsSection {
                                id: notificationsSectionSettingsSection
                                objectName: "settings-search-page:notifications"
                                host: root
                                settings: root.settings
                            }
                        }
                    }
                }
            }
        }
    }

    // Search results are rendered above the settings pages so they remain
    // usable regardless of the active page's own Flickable/scroll container.
    Rectangle {
        id: settingsSearchPopup
        z: 1000
        visible: settingsSearchInput.activeFocus && root.settingsSearchQuery.trim().length > 0
        x: {
            var inputPosition = settingsSearchInput.mapToItem(root, 0, 0)
            return Math.max(8, Math.min(root.width - width - 8, inputPosition.x + settingsSearchInput.width - width))
        }
        y: settingsSearchInput.mapToItem(root, 0, 0).y + settingsSearchInput.height + 4
        width: Math.min(360, root.width - 16)
        height: Math.min(7 * 46 + 8, Math.max(42, root.settingsSearchResults.length * 46 + 8))
        color: Config.settingsBackground
        border.color: Config.accent
        border.width: 1
        radius: Config.frameRadius
        clip: true

        ListView {
            id: settingsSearchList
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            spacing: 2
            model: root.settingsSearchResults
            visible: root.settingsSearchResults.length > 0
            currentIndex: root.settingsSearchSelectedIndex

            delegate: Item {
                id: searchResultDelegate
                required property var modelData
                required property int index
                width: settingsSearchList.width
                height: 44

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: index === root.settingsSearchSelectedIndex ? Config.accent : "transparent"
                    border.width: index === root.settingsSearchSelectedIndex ? 1 : 0
                    border.color: Config.accent
                }

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 1

                    Text {
                        width: parent.width
                        height: 17
                        text: modelData.label
                        color: index === root.settingsSearchSelectedIndex ? Config.black : Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        font.bold: index === root.settingsSearchSelectedIndex
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        height: 15
                        text: modelData.pageLabel + (modelData.group ? " · " + modelData.group : "")
                        color: index === root.settingsSearchSelectedIndex ? Config.black : Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(9)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.settingsSearchSelectedIndex = index
                    onClicked: root.openSettingsSearchResult(modelData)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.settingsSearchResults.length === 0
            text: "Ничего не найдено"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
    }

    Rectangle {
        id: settingsSearchHighlight
        z: 1100
        visible: false
        color: "transparent"
        border.color: Config.accent
        border.width: 2
        radius: 4
        antialiasing: true
    }

    Timer {
        id: settingsSearchHighlightTimer
        interval: 1600
        repeat: false
        onTriggered: settingsSearchHighlight.visible = false
    }

}
