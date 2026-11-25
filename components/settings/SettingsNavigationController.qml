import QtQuick
import "../.." // Import Config/Settings singletons in this component's own QML scope.
import "../../js/settings/SettingsPageRegistry.js" as SettingsPageRegistry
import "../../js/utils/DragReorder.js" as DragReorder

// Owns stable page routing, sidebar order/labels, subtab metadata, dirty markers and reset dispatch.
// SettingsWidget remains the composition root and exposes this API to page/search/profile UI.
Item {
    id: root
    visible: false

    property var host: null
    property var settings: Settings
    property string currentPageId: "general"
    property int currentPageSubTabIndex: 0

    // Stable page IDs, labels and non-core routes are owned by a dedicated
    // registry. User-customized labels/order remain in Config and profiles.
    readonly property var settingsTabDefinitions: SettingsPageRegistry.tabDefinitions()
    readonly property var settingsNavigationGroupDefinitions: SettingsPageRegistry.navigationGroupDefinitions()

    function defaultSettingsTabLabel(id) {
        var metadata = SettingsPageRegistry.pageMetadataForId(id)
        return metadata ? metadata.defaultLabel : "Настройки"
    }

    function settingsTabLabelForId(id) {
        var labels = Config.settingsTabLabels || ({})
        var label = labels[id] === undefined || labels[id] === null ? "" : String(labels[id]).trim()
        return label || root.defaultSettingsTabLabel(id)
    }

    function settingsNavigationOrderNormalized() {
        // The hierarchical object is the only runtime representation. Legacy
        // flat arrays are accepted once by the settings-file migration layer.
        return SettingsPageRegistry.normalizeNavigationOrder(Config.settingsNavigationOrder)
    }

    function settingsNavigationGroupOrderNormalized() {
        return settingsNavigationOrderNormalized().groupOrder.slice()
    }

    function settingsNavigationPageIdsNormalized() {
        return SettingsPageRegistry.flattenNavigationOrder(settingsNavigationOrderNormalized())
    }

    readonly property var settingsNavigationItems: SettingsPageRegistry.navigationItemsForOrder(
        root.settingsNavigationPageIdsNormalized(), Config.settingsTabLabels || ({}))

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
                { prefixes: ["animationTimer", "timerButton"], exclude: ["animationTimerMorphEnabled", "animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration"] },
                { prefixes: ["timerOptionsCommentIcon", "timerOptionsDurationIcon", "timerOptionsRefreshIcon", "timerOptionsPauseIcon", "timerOptionsColorIcon"], keys: ["timerOptionsActionIconOrder", "animationTimerOptionsVisibilityStyle", "animationTimerOptionsDuration"] }
            ],
            "player": [
                { keys: ["playerPriority", "playerFont", "playerBoldArtist", "playerUpdateInterval"] },
                { prefixes: ["playerSilence"] },
                { prefixes: ["playerTime"] },
                { prefixes: ["playerMeta", "playerMetadata"], keys: ["playerFont", "playerBoldArtist", "playerTextOutlineColor", "playerTextOutlineEnabled"] },
                { prefixes: ["playerNextIcon", "playerPausedIcon", "playerPlayingIcon"] },
                { prefixes: ["playerProgress"], keys: ["playerShowProgress"], nested: { colors: ["playerProgressFill", "playerProgressTrack"] } },
                { prefixes: ["playerCover"], nested: { colors: ["playerOverlay"] } },
                { keys: ["animationPlayerMorphDuration", "animationPlayerMorphProfile"] }
            ],
            "weather": [
                { keys: ["weatherNowIntervalMinutes", "weatherHourlyIntervalMinutes", "weatherDailyIntervalMinutes", "weatherRetryDelayMinutes", "weatherManualRefreshCooldownSeconds"] },
                { prefixes: ["weatherIcon", "weatherWind", "weatherArrow", "weatherTemp", "weatherPressure", "weatherDescription"], keys: ["weatherComfortOffsetX", "weatherComfortOffsetY", "weatherComfortOutlineColor", "weatherComfortOutlineWidth", "weatherComfortY", "weatherMiddleBlockWidth", "weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment", "weatherShowComfort"] },
                { prefixes: ["weatherHourly"], exclude: ["weatherHourlyIntervalMinutes"] },
                { prefixes: ["weatherDaily"], exclude: ["weatherDailyIntervalMinutes"] },
                { keys: ["animationWeatherMorphDuration", "animationWeatherHourlyDuration", "animationWeatherMorphProfile"] }
            ],
            "cava": [
                { keys: ["cavaMode", "cavaFramerate", "cavaHideWhenSilent", "cavaHideZeroBars"] },
                { keys: ["cavaBars", "cavaRowSpacing", "cavaBarWidthRatio"] },
                { keys: ["animationCavaMorphDuration", "animationCavaMorphProfile"] }
            ],
            "cpuRam": [
                { keys: ["cpuUpdateInterval", "cpuShowRam", "cpuBarDirection", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarThickness", "cpuBarWidth", "cpuLabelLeftPadding", "cpuRowHeight", "cpuRowSpacing"] },
                { prefixes: ["cpuGraph"] },
                { prefixes: ["topApps"], nested: { colors: ["topAppsCpuBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarColor", "topAppsRamBarTrackColor"] } },
                { keys: ["animationCpuMorphDuration", "animationCpuMorphProfile"] }
            ],
            "network": [
                { keys: ["systemMonitorInterval"] },
                { prefixes: ["network"], keys: ["networksAlwaysVisible"] },
                { keys: ["animationNetworkVisibilityStyle", "animationNetworkVisibilityDuration", "animationNetworkMorphDuration", "animationNetworkMorphProfile"] }
            ],
            "volume": [
                { keys: ["volumeIcon", "volumeMutedIcon"] },
                { keys: ["volumeUpdateInterval", "volumeShowStreams", "volumeMaxHeight", "volumeMinHeight"] },
                { prefixes: ["volumeMainTrack", "volumeStreamTrack", "volumeTrack"], keys: ["volumeMainIconWidth", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeStreamLabelFont", "volumeStreamLabelFontSize"], nested: { colors: ["volumeTrack", "volumeFill"] } },
                { prefixes: ["volumeStream"] , keys: ["volumeShowStreams"] },
                { keys: ["volumeMinHeight", "volumeMaxHeight", "volumeHorizontalPadding", "volumeVerticalPadding"] },
                { keys: ["animationVolumeStreamsVisibilityStyle", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"] }
            ],
            "calendar": [
                { keys: ["calendarAlwaysVisible", "calendarArrowY", "calendarNextIcon", "calendarNextSize", "calendarNextX", "calendarPreviousIcon", "calendarPreviousSize", "calendarPreviousX", "calendarTitleFont", "calendarTitleFontSize", "calendarTitleY", "calendarDayFont", "calendarDayFontSize", "calendarDayY", "calendarWeekdayFont", "calendarWeekdayFontSize", "calendarWeekdayY"] },
                { keys: ["calendarAdjacentDaysColor", "calendarPastDaysColor", "calendarPastDaysColorEnabled", "calendarWeekendColor", "calendarNoteFrameColor"], nested: { colors: ["calendarBackground"] } },
                { prefixes: ["calendarNote"], keys: ["calendarNoteMarkerPosition", "calendarNoteMarkerStyle", "calendarNoteFrameColor"] },
                { prefixes: ["animationCalendar"] }
            ],
            "settingsWindow": [
                { keys: ["settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing", "settingsSearchHighlightColor", "settingsSearchHighlightBorderWidth", "settingsSearchMatchCountFontSize"] },
                { keys: ["settingsGeometry", "settingsMonitorName", "settingsBackground", "settingsBorder", "animationSettingsVisibilityStyle"], nested: { colors: ["settingsBackground", "settingsBorder"], moduleBlurEnabled: ["settings"] } },
                { keys: ["settingsNavigationOrder", "settingsTabLabels"] }
            ],
            "mopidy": [
                { keys: ["mopidyAlbumBold", "mopidyAlbumSeparator", "mopidyBackground", "mopidyGroupAlbums", "mopidyHoverColor", "mopidyHoverMode", "mopidyShowTrackNumbers", "mopidyShowVolumePercent", "mopidyToggleWithPlayerRightClick", "mopidyVolumeStep", "mopidyBrowseCoverMode", "mopidyBrowseCoverKeepSelectedVisible"] },
                { prefixes: ["mopidyTrack", "mopidyArtist", "mopidyAlbum", "mopidyDuration", "mopidyQueueDuration"], keys: ["mopidyShowAlbumRemaining", "mopidyShowQueueTotalDuration", "mopidyShowTrackRemaining"] },
                { prefixes: ["mopidyAddIcon", "mopidyClearIcon", "mopidyOpenAddIcon", "mopidyPlaylistDeleteIcon", "mopidyRefreshIcon", "mopidyRepeatIcon", "mopidyShuffleIcon", "mopidyStopIcon", "mopidySwitchPlaylistIcon", "mopidyVolumeIcon"], keys: ["mopidyTopIconOrder", "mopidyHideTopPanel", "mopidyTopPanelHoverHeight", "mopidyTopPanelOffsetY", "mopidyControlIconColor"] },
                { prefixes: ["mopidyStatus"], keys: ["mopidyEmptyQueueText", "mopidyUnavailableText"] },
                { keys: ["animationMopidyVisibilityStyle", "animationMopidyMorphDuration", "animationMopidyMorphProfile"] }
            ],
            "launcher": [
                { keys: ["launcherDefaultMode", "launcherShowResultCount"] },
                { keys: ["launcherVimKeybinds", "launcherShowNavigationHints", "launcherNavigationHintsHeight", "launcherNavigationHintsFontSize", "launcherNavigationHintsTextY"] },
                { keys: ["launcherBackdropOpacity", "launcherBackground", "launcherItemHeight", "launcherItemRadius", "launcherRadius", "launcherSearchBackground", "launcherSearchFont", "launcherSearchFontSize", "launcherSearchHeight", "launcherSearchPlaceholder", "launcherSearchRadius", "launcherTitleBold", "launcherTitleColor", "launcherTitleFont", "launcherTitleFontSize", "launcherTitleLetterSpacing", "launcherTitleText", "launcherTitleY"] },
                { keys: ["launcherCrossSearchCalculator", "launcherCrossSearchProjects", "launcherCrossSearchRunHistory"] }
            ],
            "launcherSearch": [
                { keys: ["launcherFuzzySearchApps"] },
                { keys: ["launcherFuzzySearchActions"] },
                { keys: ["launcherFuzzySearchSchemes", "launcherDynamicSchemeVariant"] },
                { keys: ["launcherFuzzySearchWallpapers", "launcherWallpaperDirectory"] }
            ],
            "launcherActions": [
                { arrayContains: { launcherDisabledBuiltinActions: [
                    "tab.apps", "tab.run", "tab.windows", "tab.clipboard", "tab.power",
                    "tab.network", "tab.packages", "tab.pass", "tab.projects", "tab.calculator"
                ] } },
                { arrayContains: { launcherDisabledBuiltinActions: [
                    "tool.colorSchemes", "tool.schemeVariants", "tool.wallpapers", "tool.emoji", "tool.wallpaperDynamic", "tool.dashboard"
                ] } },
                { keys: ["launcherCustomActions"] }
            ],
            "notifications": [
                { keys: ["notificationsDefaultTimeout", "notificationsCriticalTimeout", "notificationsShowTimeoutIndicator", "notificationsTimeoutIndicatorColor", "notificationsTimeoutIndicatorStyle", "notificationsTimeoutIndicatorDirection"] },
                { keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsBackgroundColor", "notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold", "notificationsLeadingVisualSize", "notificationsLeadingVisualRadius", "notificationsCardPadding", "notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] },
                { keys: ["notificationsVerticalAnchor"] },
                { keys: ["animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle"] }
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

    // Launcher shares one save/reset profile scope, but sidebar dirty markers
    // must stay local to each child page instead of lighting every Launcher page.
    // Pages with horizontal subtabs aggregate only those exact subtab selectors.
    function launcherPageHasChanges(pageId) {
        var pageSubTabCounts = { launcher: 4, launcherSearch: 4, launcherActions: 3 }
        var subTabCount = pageSubTabCounts[String(pageId)]
        if (subTabCount !== undefined) {
            for (var sub = 0; sub < subTabCount; ++sub) {
                var subSpec = root.settingsSubTabChangeSpec(pageId, sub)
                if (subSpec !== null && settings.hasResetChanges("keys", subSpec))
                    return true
            }
            return false
        }

        var pageSpecs = {
            launcherTabs: { keys: ["launcherTabOrder", "launcherTabVisible", "launcherTabLabels", "launcherTabIcons"] },
            launcherProjects: { keys: ["launcherProjects"] },
            launcherAnimation: { keys: ["animationLauncherMorphDuration", "animationLauncherMorphProfile"] },
            launcherApplications: { keys: ["launcherFavoriteApps", "launcherHiddenApps"] }
        }
        var pageSpec = pageSpecs[String(pageId)]
        return pageSpec !== undefined && settings.hasResetChanges("keys", pageSpec)
    }

    // Use the cached sparse profile overrides to mark sections with changes.
    // This deliberately reuses hasResetChanges() so indicators do not trigger
    // their own full settings snapshot/diff calculations.
    function settingsTabHasChanges(id) {
        if (!root.host || !root.host.profileController.hasActiveProfile)
            return false
        var pageId = String(id || "")
        if (["launcher", "launcherSearch", "launcherTabs", "launcherProjects", "launcherActions", "launcherAnimation", "launcherApplications"].indexOf(pageId) >= 0)
            return root.launcherPageHasChanges(pageId)

        var scopes = {
            modules: "modules", dashboard: "dashboard", themes: "themes", general: "general",
            timers: "timer", player: "player", mopidy: "mopidy",
            weather: "weather", cava: "cava", cpuRam: "cpu",
            network: "network", volume: "volume", calendar: "calendar",
            time: "clock", notifications: "notifications", settingsWindow: "settingsWindow"
        }
        var scope = scopes[pageId] || ""
        return scope !== "" && settings.hasResetChanges(scope)
    }

    function selectSettingsTab(id) {
        var pageId = String(id || "")
        if (pageId !== "modules" && pageId !== "themes" && !SettingsPageRegistry.hasOtherPageId(pageId))
            return
        // The invoking navigation control already owns active focus (mouse,
        // keyboard or accessibility activation). Keep it there across the page
        // switch instead of sending focus to the invisible SettingsWidget root.
        root.currentPageId = pageId
    }

    function resetCurrentSettingsPage() {
        switch (root.currentPageId) {
        case "time": settings.resetClockSettings(); break
        case "dashboard": settings.resetDashboardSettings(); break
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
        case "launcher":
        case "launcherSearch":
        case "launcherTabs":
        case "launcherProjects":
        case "launcherActions":
        case "launcherAnimation":
        case "launcherApplications": settings.resetLauncherSettings(); break
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

    // Page ordering is explicitly scoped to one canonical navigation frame.
    // The legacy page-only wrappers remain for existing callers, but editor
    // controls use the group-scoped API so a page can never cross a frame.
    function settingsTabCanMoveWithinGroup(groupId, id, delta) {
        var pageId = String(id)
        var targetGroupId = String(groupId)
        var step = Number(delta)
        if (step !== -1 && step !== 1)
            return false
        if (SettingsPageRegistry.navigationGroupIdForTabId(pageId) !== targetGroupId)
            return false
        var order = root.settingsNavigationOrderNormalized()
        var pageOrder = order.pagesByGroup[targetGroupId] || []
        var from = pageOrder.indexOf(pageId)
        var to = from + step
        return from >= 0 && to >= 0 && to < pageOrder.length && to !== from
    }

    function settingsTabCanMove(id, delta) {
        var pageId = String(id)
        return root.settingsTabCanMoveWithinGroup(
            SettingsPageRegistry.navigationGroupIdForTabId(pageId), pageId, delta)
    }

    function moveSettingsTabWithinGroupTo(groupId, id, toIndex) {
        var pageId = String(id)
        var targetGroupId = String(groupId)
        if (SettingsPageRegistry.navigationGroupIdForTabId(pageId) !== targetGroupId)
            return false
        var order = root.settingsNavigationOrderNormalized()
        var pageOrder = (order.pagesByGroup[targetGroupId] || []).slice()
        var fromIndex = pageOrder.indexOf(pageId)
        var destination = Number(toIndex)
        if (fromIndex < 0 || !isFinite(destination) || Math.floor(destination) !== destination
                || destination < 0 || destination >= pageOrder.length || fromIndex === destination)
            return false
        order.pagesByGroup[targetGroupId] = DragReorder.move(pageOrder, fromIndex, destination)
        Config.settingsNavigationOrder = SettingsPageRegistry.normalizeNavigationOrder(order)
        root.settings.save()
        return true
    }

    function moveSettingsTabWithinGroup(groupId, id, delta) {
        var pageId = String(id)
        var targetGroupId = String(groupId)
        if (!root.settingsTabCanMoveWithinGroup(targetGroupId, pageId, delta)) return false
        var order = root.settingsNavigationOrderNormalized()
        var pageOrder = (order.pagesByGroup[targetGroupId] || []).slice()
        var from = pageOrder.indexOf(pageId)
        var destination = from + Number(delta)
        if (from < 0 || destination < 0 || destination >= pageOrder.length || destination === from)
            return false
        order.pagesByGroup[targetGroupId] = DragReorder.move(pageOrder, from, destination)
        Config.settingsNavigationOrder = SettingsPageRegistry.normalizeNavigationOrder(order)
        root.settings.save()
        return true
    }

    function moveSettingsTab(id, delta) {
        var pageId = String(id)
        root.moveSettingsTabWithinGroup(
            SettingsPageRegistry.navigationGroupIdForTabId(pageId), pageId, delta)
    }

    function settingsNavigationGroupCanMove(id, delta) {
        var step = Number(delta)
        if (step !== -1 && step !== 1)
            return false
        var groupOrder = root.settingsNavigationGroupOrderNormalized()
        var from = groupOrder.indexOf(String(id))
        var to = from + step
        return from >= 0 && to >= 0 && to < groupOrder.length && to !== from
    }

    function moveSettingsNavigationGroupTo(id, toIndex) {
        var groupId = String(id)
        var order = root.settingsNavigationOrderNormalized()
        var groupOrder = order.groupOrder.slice()
        var fromIndex = groupOrder.indexOf(groupId)
        var destination = Number(toIndex)
        if (fromIndex < 0 || !isFinite(destination) || Math.floor(destination) !== destination
                || destination < 0 || destination >= groupOrder.length || fromIndex === destination)
            return false
        order.groupOrder = DragReorder.move(groupOrder, fromIndex, destination)
        Config.settingsNavigationOrder = SettingsPageRegistry.normalizeNavigationOrder(order)
        root.settings.save()
        return true
    }

    function moveSettingsNavigationGroup(id, delta) {
        if (!root.settingsNavigationGroupCanMove(id, delta)) return false
        var order = root.settingsNavigationOrderNormalized()
        var groupOrder = order.groupOrder.slice()
        var from = groupOrder.indexOf(String(id))
        var destination = from + Number(delta)
        if (from < 0 || destination < 0 || destination >= groupOrder.length || destination === from)
            return false
        order.groupOrder = DragReorder.move(groupOrder, from, destination)
        Config.settingsNavigationOrder = SettingsPageRegistry.normalizeNavigationOrder(order)
        root.settings.save()
        return true
    }

    readonly property string currentPageTitle: {
        var main = root.settingsTabLabelForId(root.currentPageId) || "Настройки"
        var subtabs = root.currentPageSubTabs
        var sub = subtabs[root.currentPageSubTabIndex] || ""
        return (main + (sub ? " · " + sub : "")).toLocaleUpperCase()
    }

    readonly property var currentPageSubTabs: SettingsPageRegistry.subtabsForPageId(
        root.currentPageId)

    Connections {
        target: Config
        function onSettingsTabLabelsChanged() { if (root.host) Qt.callLater(root.host.rebuildSettingsSearchIndex) }
    }

    onCurrentPageIdChanged: {
        if (root.host) root.host.resetSettingsPageScroll()
        root.currentPageSubTabIndex = 0
    }

}
