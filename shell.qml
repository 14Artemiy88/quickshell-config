import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"
import "components/mopidy" as MopidyComponents
import "components/settings"
import "services"
import "components/primitives" as Primitives
import "components/notifications" as NotificationComponents
import "components/osd"

ShellRoot {
    id: shell

    // Prune only old, redundant launcher-recovery snapshots. The script is
    // deliberately conservative and never removes active locks or user data.
    Process {
        id: storageCleanupProcess
        command: [Quickshell.shellDir + "/scripts/cleanup_storage"]
    }
    Component.onCompleted: storageCleanupProcess.running = true
    Clock { id: clock; active: Settings.loaded && (Settings.time || shell.dashboardVisible || ((shell.calendarVisible || Config.calendarAlwaysVisible) && Settings.calendar)) }
    SystemMonitor { id: monitor }
    SystemOsd { id: systemOsd }
    // Keep the NotificationServer QML bridge alive for the whole shell session.
    // Quickshell 0.3.1 backs it with a process-wide C++ singleton that keeps
    // org.freedesktop.Notifications registered even if this Loader is destroyed.
    // Settings.notifications therefore gates receipt/presentation inside the
    // component; it cannot hand the D-Bus name to another daemon at runtime.
    Loader {
        id: notificationsModuleLoader
        active: Settings.loaded
        sourceComponent: Component { NotificationComponents.Notifications {} }
        onLoaded: {
            item.layoutEditor = moduleLayoutEditorWindow
            item.layoutEditMode = shell.layoutEditMode
        }
    }
    Connections {
        target: shell
        function onLayoutEditModeChanged() {
            if (notificationsModuleLoader.item)
                notificationsModuleLoader.item.layoutEditMode = shell.layoutEditMode
        }
    }
    Loader {
        id: weatherLoader
        active: Settings.loaded && (Settings.weatherNow || Settings.weatherHourly || Settings.weatherDaily)
        sourceComponent: Component { Weather {} }
    }
    property bool calendarVisible: false
    property bool dashboardVisible: false
    property bool mopidyVisible: false
    property bool settingsVisible: false
    property bool layoutEditMode: false
    property bool settingsMoveMode: false
    property bool mopidyTopReveal: false
    property bool networksVisible: false
    property string pendingLauncherMode: ""

    Connections {
        target: Settings
        function onDashboardChanged() {
            if (!Settings.dashboard)
                shell.dashboardVisible = false
        }
    }

    function showLauncherMode(modeName) {
        if (!Config.launcherEnabled) return
        pendingLauncherMode = String(modeName || "apps")
        if (launcherLoader.status === Loader.Ready && launcherLoader.item) {
            const requestedMode = pendingLauncherMode
            pendingLauncherMode = ""
            launcherLoader.item.openMode(requestedMode)
            return
        }
        launcherLoader.active = true
    }

    function toggleLauncher() {
        if (!Config.launcherEnabled) return
        if (launcherLoader.status === Loader.Ready && launcherLoader.item && launcherLoader.item.visible) {
            launcherLoader.item.hideLauncher()
            return
        }
        showLauncherMode("default")
    }

    Connections {
        target: mopidyWidget
        function onTopPanelHideRequested() {
            shell.mopidyTopReveal = false
        }
    }

    onLayoutEditModeChanged: {
        if (layoutEditMode) {
            settingsMoveMode = false
            settingsVisible = false
            if (Config.launcherEnabled) {
                launcherLoader.active = true
                Qt.callLater(function() {
                    if (shell.layoutEditMode && launcherLoader.status === Loader.Ready && launcherLoader.item)
                        launcherLoader.item.beginLayoutEdit()
                })
            }
        } else if (launcherLoader.status === Loader.Ready && launcherLoader.item) {
            launcherLoader.item.endLayoutEdit()
        }
    }

    onSettingsMoveModeChanged: {
        if (settingsMoveMode) {
            layoutEditMode = false
            settingsVisible = false
        }
    }

    Connections {
        target: Settings
        function onNetworksChanged() {
            if (!Settings.networks)
                shell.networksVisible = false
        }
    }

    Connections {
        target: Config
        function onNetworksAlwaysVisibleChanged() {
            if (Config.networksAlwaysVisible)
                shell.networksVisible = false
        }
    }

    Connections {
        target: Settings
        function onMopidyChanged() {
            if (!Settings.mopidy) {
                shell.mopidyVisible = false
                shell.mopidyTopReveal = false
            }
        }
    }

    Connections {
        target: Config
        function onMopidyToggleWithPlayerRightClickChanged() {
            if (Config.mopidyToggleWithPlayerRightClick) {
                shell.mopidyVisible = false
                shell.mopidyTopReveal = false
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: shell.settingsMoveMode
        onActivated: {
            shell.settingsMoveMode = false
            shell.settingsVisible = true
        }
    }

    Connections {
        target: Config
        function onLauncherEnabledChanged() {
            if (!Config.launcherEnabled) {
                shell.pendingLauncherMode = ""
                if (launcherLoader.status === Loader.Ready && launcherLoader.item)
                    launcherLoader.item.hideLauncher()
            }
        }
    }

    // Keep the launcher out of the critical shell startup path, then warm its
    // QML component asynchronously after the settings snapshot is ready. Its
    // user data/process initialization remains deferred until the first open.
    Timer {
        id: launcherWarmupTimer
        interval: 1800
        repeat: false
        running: Settings.loaded && Config.launcherEnabled && launcherLoader.status === Loader.Null
        onTriggered: {
            if (Settings.loaded && Config.launcherEnabled && launcherLoader.status === Loader.Null)
                launcherLoader.active = true
        }
    }

    Loader {
        id: launcherLoader
        active: false
        asynchronous: true
        source: "components/launcher/Launcher.qml"
        onLoaded: {
            item.layoutEditor = moduleLayoutEditorWindow
            if (!Config.launcherEnabled) {
                shell.pendingLauncherMode = ""
                item.hideLauncher()
                return
            }
            if (shell.layoutEditMode) {
                item.beginLayoutEdit()
                return
            }
            if (shell.pendingLauncherMode !== "") {
                const requestedMode = shell.pendingLauncherMode
                shell.pendingLauncherMode = ""
                item.openMode(requestedMode)
            }
        }
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("Launcher could not be loaded. Inspect the Quickshell log for QML errors.")
        }
    }

    Connections {
        target: launcherLoader.status === Loader.Ready ? launcherLoader.item : null
        function onDashboardRequested() { if (Settings.dashboard) shell.dashboardVisible = true }
    }

    IpcHandler {
        target: "networks"

        function toggle(): void {
            if (Settings.networks && !Config.networksAlwaysVisible)
                shell.networksVisible = !shell.networksVisible
        }
        function show(): void {
            if (Settings.networks)
                shell.networksVisible = true
        }
        function hide(): void { shell.networksVisible = false }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            if (Settings.dashboard)
                shell.dashboardVisible = !shell.dashboardVisible
        }
        function show(): void {
            if (Settings.dashboard)
                shell.dashboardVisible = true
        }
        function hide(): void { shell.dashboardVisible = false }
    }

    Dashboard {
        id: dashboardPanel
        open: Settings.dashboard && shell.dashboardVisible
        layoutEditMode: Settings.dashboard && shell.layoutEditMode
        layoutEditor: moduleLayoutEditorWindow
        clock: clock
        cpuSource: cpuWidget
        playerSource: playerWidget
        weatherSource: weatherLoader.item
        monitorSource: monitor
        notificationHistoryModel: notificationsModuleLoader.item ? notificationsModuleLoader.item.notificationHistoryGrouped : []
        notificationHistoryUnreadCount: notificationsModuleLoader.item ? notificationsModuleLoader.item.notificationHistoryUnreadCount : 0
        notificationHistoryLimit: Config.notificationsHistoryLimit
        notificationHistoryRetentionDays: Config.notificationsHistoryRetentionDays
        onCloseRequested: shell.dashboardVisible = false
        onSettingsRequested: shell.settingsVisible = true
        onHistoryRequested: {
            if (notificationsModuleLoader.item) notificationsModuleLoader.item.markNotificationHistoryRead()
            dashboardPanel.historyViewActive = true
        }
        onHistoryClearRequested: {
            if (notificationsModuleLoader.item) notificationsModuleLoader.item.clearNotificationHistory()
        }
        onHistoryEntryDeleteRequested: function(entryId) {
            if (notificationsModuleLoader.item) notificationsModuleLoader.item.removeNotificationHistoryEntry(entryId)
        }
        onHistoryGroupDeleteRequested: function(appGroup) {
            if (notificationsModuleLoader.item) notificationsModuleLoader.item.removeNotificationHistoryGroup(appGroup)
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { shell.toggleLauncher() }
        function openTab(modeName: string): void { shell.showLauncherMode(modeName) }
        function openApps(): void { shell.showLauncherMode("apps") }
        function openRun(): void { shell.showLauncherMode("run") }
        function openWindows(): void { shell.showLauncherMode("windows") }
        function openClipboard(): void { shell.showLauncherMode("clipboard") }
        function openPower(): void { shell.showLauncherMode("power") }
        function openNetwork(): void { shell.showLauncherMode("network") }
        function openPackages(): void { shell.showLauncherMode("packages") }
        function openPass(): void { shell.showLauncherMode("pass") }
        function openProjects(): void { shell.showLauncherMode("projects") }
        function openCalculator(): void { shell.showLauncherMode("calculator") }
    }

    property bool timerOptionsVisible: false
    property bool timerCommentVisible: false
    property bool timerFinishedVisible: false
    property string timerCommentFile: ""
    property string timerCommentText: ""
    property string timerFinishedComment: ""
    property string timerFinishedTitle: ""
    property string timerFinishedColor: Config.text
    readonly property string timerFinishedImageSource: {
        var p = String(Config.timerFinishedImagePath || "").trim()
        if (p === "") return ""
        if (p.indexOf("~/") === 0) p = Quickshell.env("HOME") + p.slice(1)
        if (/^[A-Za-z][A-Za-z0-9+.-]*:/.test(p)) return p
        return "file://" + p
    }
    property string focusedOutputName: ""
    property var focusedOutputScreen: Quickshell.screens[0]

    WidgetWindow { visible: Settings.time; moduleName: "time"; layoutEditMode: shell.layoutEditMode; layoutEditor: moduleLayoutEditorWindow; offsetX: Settings.geometryForLayout("time")[0]; offsetY: Settings.geometryForLayout("time")[1]; contentWidth: Settings.geometry.time[2]; contentHeight: Settings.geometry.time[3]
        TimeWidget { anchors.fill: parent; clock: clock; onCalendarRequested: shell.calendarVisible = !shell.calendarVisible; onSettingsRequested: shell.settingsVisible = !shell.settingsVisible }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "cpu"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.cpu
        offsetX: Settings.geometryForLayout("cpu")[0]
        offsetY: Settings.geometryForLayout("cpu")[1]
        contentWidth: Settings.geometry.cpu[2]
        contentHeight: Settings.geometry.cpu[3]
        CpuWidget { id: cpuWidget; anchors.fill: parent }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "cpuGraph"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.cpuGraph
        offsetX: Settings.geometryForLayout("cpuGraph")[0]
        offsetY: Settings.geometryForLayout("cpuGraph")[1]
        contentWidth: Settings.geometry.cpuGraph[2]
        contentHeight: Settings.geometry.cpuGraph[3]
        CpuGraph { anchors.fill: parent }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "topAppsCpu"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.topAppsCpu
        offsetX: Settings.geometryForLayout("topAppsCpu")[0]
        offsetY: Settings.geometryForLayout("topAppsCpu")[1]
        contentWidth: Settings.geometry.topAppsCpu[2]
        contentHeight: Settings.geometry.topAppsCpu[3]
        TopApps { id: topAppsCpuView; anchors.fill: parent; monitor: monitor; sectionType: "cpu" }
    }
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "topAppsRam"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.topAppsRam
        offsetX: Settings.geometryForLayout("topAppsRam")[0]
        offsetY: Settings.geometryForLayout("topAppsRam")[1]
        contentWidth: Settings.geometry.topAppsRam[2]
        contentHeight: Settings.geometry.topAppsRam[3]
        TopApps { id: topAppsRamView; anchors.fill: parent; monitor: monitor; sectionType: "ram" }
    }
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "networkStat"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.networkStat
        offsetX: Settings.geometryForLayout("networkStat")[0]
        offsetY: Settings.geometryForLayout("networkStat")[1]
        contentWidth: Settings.geometry.networkStat[2]
        contentHeight: Settings.geometry.networkStat[3]
        NetworkStat {
            anchors.fill: parent
            monitor: monitor
            onNetworksRequested: {
                if (Settings.networks && !Config.networksAlwaysVisible)
                    shell.networksVisible = !shell.networksVisible
            }
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "weatherNow"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.weatherNow
        // Weather surfaces stay below normal application windows; layout editing raises them temporarily.
        bottomLayer: true
        offsetX: Settings.geometryForLayout("weatherNow")[0]
        offsetY: Settings.geometryForLayout("weatherNow")[1]
        contentWidth: Settings.geometry.weatherNow[2]
        contentHeight: Settings.geometry.weatherNow[3]
        WeatherNow {
            anchors.fill: parent
            weather: weatherLoader.item ? weatherLoader.item.now : ({})
            weatherService: weatherLoader.item
            onSettingsRequested: {
                shell.settingsVisible = true
                settingsWidget.openWeatherSettings()
            }
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "weatherHourly"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.weatherHourly
        // Weather surfaces stay below normal application windows; layout editing raises them temporarily.
        bottomLayer: true
        offsetX: Settings.geometryForLayout("weatherHourly")[0]
        offsetY: Settings.geometryForLayout("weatherHourly")[1]
        contentWidth: Settings.geometry.weatherHourly[2]
        contentHeight: Settings.geometry.weatherHourly[3]
        WeatherList {
            anchors.fill: parent
            entries: weatherLoader.item ? weatherLoader.item.day : []
            hourly: true
            weatherService: weatherLoader.item
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "weatherDaily"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.weatherDaily
        // Weather surfaces stay below normal application windows; layout editing raises them temporarily.
        bottomLayer: true
        offsetX: Settings.geometryForLayout("weatherDaily")[0]
        offsetY: Settings.geometryForLayout("weatherDaily")[1]
        contentWidth: Settings.geometry.weatherDaily[2]
        contentHeight: Settings.geometry.weatherDaily[3]
        WeatherList {
            anchors.fill: parent
            entries: weatherLoader.item ? weatherLoader.item.week : []
            hourly: false
            weatherService: weatherLoader.item
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        id: timerWindow
        moduleName: "timer"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.timer
        offsetX: Settings.geometryForLayout("timer")[0]
        offsetY: Settings.geometryForLayout("timer")[1]
        contentWidth: Settings.geometry.timer[2]
        contentHeight: timerWidget.adaptiveHeight
        TimerWidget { id: timerWidget; anchors.fill: parent }

        // Keep a transparent fullscreen layer-shell surface alive while the
        // timer module is enabled. The options card itself is a small QML item
        // on this stable surface, so the selected QML slide/fade animation is
        // not replaced by a compositor transition when the card is dismissed.
        // The input mask is empty while closed and covers the screen only while
        // options are open. The card is stacked above the outside-click catcher.
        PanelWindow {
            id: timerOptionsOverlay
            visible: Settings.timer
            screen: timerWindow.screen
            color: Config.transparent
            focusable: timerOptionsPopup.commentMode || timerOptionsPopup.durationMode || timerOptionsPopup.colorMode
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region { item: timerOptionsInputRegion }

            Item {
                id: timerOptionsInputRegion
                width: shell.timerOptionsVisible ? parent.width : 0
                height: shell.timerOptionsVisible ? parent.height : 0
            }

            MouseArea {
                anchors.fill: parent
                enabled: shell.timerOptionsVisible && !timerOptionsPopup.closing
                acceptedButtons: Qt.AllButtons
                z: 0
                onClicked: timerOptionsOverlay.closeForOptions()
            }

            function closeForOptions() {
                if (timerOptionsPopup.closing || !shell.timerOptionsVisible) return
                shell.timerOptionsVisible = false
                timerOptionsPopup.commentMode = false
                timerOptionsPopup.closeDurationEditor()
                timerOptionsPopup.closeColorEditor()
                timerOptionsPopup.startClose()
            }

            function hideAfterClose() {
                shell.timerOptionsVisible = false
                timerOptionsPopup.commentMode = false
                timerOptionsPopup.closeDurationEditor()
                timerOptionsPopup.closeColorEditor()
                timerOptionsPopup.closing = false
            }

            // Keep the user-configured horizontal position, but vertically
            // anchor the options card to the selected timer row. The anchor is
            // derived from the live delegate geometry and clamped to this
            // monitor so a timer near an edge cannot push the popup off-screen.
            function timerOptionsAnchoredY() {
                if (!timerWidget.selectedFile || timerWidget.selectedIndex < 0)
                    return Number(Settings.geometry.timerOptions[1]) || 0

                var scale = Math.max(0.1, Number(timerWindow.surfaceScale) || 1)
                var popupScale = Math.max(0.1, Number(timerOptionsScaleHost.scale) || 1)
                var timerTop = Number(timerWindow.offsetY) || 0
                var rowCenter = Number(timerWidget.selectedTimerRowCenterY) || 0
                var popupHeight = Math.max(0, Number(timerOptionsScaleHost.height) || 95) * popupScale
                var targetY = timerTop + rowCenter * scale - popupHeight / 2
                var availableHeight = Number(timerOptionsOverlay.screen && timerOptionsOverlay.screen.height) || 0
                if (availableHeight > 0)
                    targetY = Math.max(0, Math.min(Math.max(0, availableHeight - popupHeight), targetY))
                return Math.round(targetY)
            }

            // Keep persisted timerOptions geometry logical while scaling the
            // complete popup surface and its hit targets with ordinary modules.
            Item {
                id: timerOptionsScaleHost
                x: Settings.geometry.timerOptions[0]
                y: timerOptionsOverlay.timerOptionsAnchoredY()
                width: Math.max(110, Settings.geometry.timerOptions[2])
                height: Settings.geometry.timerOptions[3]
                scale: Config.moduleUiScale()
                transformOrigin: Item.TopLeft
                z: 1

                TimerOptions {
                    id: timerOptionsPopup
                    anchors.fill: parent
                    timers: timerWidget.timers
                    selectedFile: timerWidget.selectedFile
                    onCloseRequested: timerOptionsOverlay.closeForOptions()
                    onCommentRequested: file => {
                        timerOptionsPopup.commentFile = file
                        timerOptionsPopup.commentText = timerWidget.commentForFile(file)
                        timerOptionsPopup.commentMode = true
                        timerOptionsPopup.focusCommentInput()
                    }
                    onCloseFinished: {
                        timerWidget.selectedFile = ""
                        timerOptionsOverlay.hideAfterClose()
                    }
                }
            }
        }

        PanelWindow {
            id: timerFinishedPopup
            visible: shell.timerFinishedVisible
            screen: shell.focusedOutputScreen || Quickshell.screens[0]
            color: Config.transparent
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            anchors.left: true
            anchors.right: true
            anchors.top: true
            anchors.bottom: true
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                id: timerFinishedCard
                anchors.centerIn: parent
                readonly property bool imageMode: Config.timerFinishedImageEnabled && shell.timerFinishedImageSource !== ""
                                width: imageMode ? Math.max(305, Config.timerFinishedImageWidth + Config.timerFinishedImageMargin * 2) : 305
                height: imageMode
                    ? timerFinishedImageTitle.y + timerFinishedImageTitle.height + Config.timerFinishedImageMargin + timerFinishedImage.height + Config.timerFinishedImageMargin
                    : 102
                color: Config.timerFinishedBackgroundUsesTimerColor ? shell.timerFinishedColor : Config.timerFinishedBackgroundColor
                scale: Config.moduleUiScale()
                transformOrigin: Item.Center
                focus: true

                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Space) {
                        shell.timerFinishedVisible = false
                        event.accepted = true
                    }
                }
                radius: Config.scaledCornerRadius(Config.frameRadius)
                border.color: Config.timerFinishedBorderUsesTimerColor ? shell.timerFinishedColor : Config.baseColor
                border.width: Config.popupBordersEnabled ? Config.frameBorderWidth : 0
                antialiasing: true

                Image {
                    id: timerFinishedImage
                    visible: timerFinishedCard.imageMode
                    source: visible ? shell.timerFinishedImageSource : ""
                    x: (parent.width - width) / 2
                    y: timerFinishedImageTitle.y + timerFinishedImageTitle.height + Config.timerFinishedImageMargin
                    width: Math.min(Config.timerFinishedImageWidth, parent.width - Config.timerFinishedImageMargin * 2)
                    height: implicitWidth > 0 && implicitHeight > 0 ? width * (implicitHeight / implicitWidth) : 0
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Text {
                    id: timerFinishedImageTitle
                    visible: timerFinishedCard.imageMode
                    x: Config.timerFinishedImageMargin
                    y: Config.timerFinishedImageMargin
                    width: parent.width - Config.timerFinishedImageMargin * 2
                    height: Math.max(24, Config.timerFinishedTitleFontSize + 4)
                    text: shell.timerFinishedTitle || "Время вышло"
                    color: Config.timerFinishedTitleUsesTimerColor ? shell.timerFinishedColor : Config.timerFinishedTitleColor
                    font.family: Config.timerFinishedTitleFont
                    font.pixelSize: Config.uiFontSize(Config.timerFinishedTitleFontSize)
                    horizontalAlignment: Config.timerFinishedTitleAlignment === 0
                        ? Text.AlignLeft
                        : (Config.timerFinishedTitleAlignment === 2 ? Text.AlignRight : Text.AlignHCenter)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Text {
                    visible: !timerFinishedCard.imageMode
                    x: 12
                    y: 10
                    width: parent.width - 24
                    height: 24
                    text: "󰀠  Таймер завершён"
                    color: shell.timerFinishedColor
                    font.family: Config.ledFont
                    font.pixelSize: Config.uiFontSize(18)
                }

                Text {
                    visible: !timerFinishedCard.imageMode
                    x: 12
                    y: 39
                    width: parent.width - 24
                    height: 20
                    text: shell.timerFinishedComment || "Время вышло"
                    color: Config.text
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.uiFontSize(13)
                    elide: Text.ElideRight
                }

                Text {
                    visible: !timerFinishedCard.imageMode
                    x: 12
                    y: 68
                    width: parent.width - 24
                    height: 18
                    text: "динь-динь"
                    color: Config.textDim
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.uiFontSize(10)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: shell.timerFinishedVisible = false
                }
            }
        }
    }

    Process {
        id: focusedOutputProcess
        command: ["zsh", "-ic", "niri msg -j focused-output"]
        stdout: StdioCollector {
            id: focusedOutputCollector
        }
        onExited: {
            try {
                const data = JSON.parse(focusedOutputCollector.text)
                shell.focusedOutputName = data.name || ""
                shell.focusedOutputScreen = Quickshell.screens.find(s =>
                    s.name === shell.focusedOutputName ||
                    s.model === shell.focusedOutputName ||
                    s.toString() === shell.focusedOutputName
                ) || Quickshell.screens[0]
            } catch (e) {
                shell.focusedOutputName = ""
                shell.focusedOutputScreen = Quickshell.screens[0]
            }
        }
    }

    Connections {
        target: timerWidget
        function onTimerFinished(file, comment, color, timerText) {
            shell.timerFinishedComment = comment
            shell.timerFinishedTitle = String(comment || timerText || "Время вышло")
            shell.timerFinishedColor = color || Config.text
            shell.timerFinishedVisible = true
            focusedOutputProcess.running = true
        }
        function onSelectedFileChanged() {
            if (timerWidget.selectedFile !== "") {
                shell.timerOptionsVisible = true
                timerOptionsPopup.closing = false
                timerOptionsPopup.syncVisualState()
            } else if (shell.timerOptionsVisible && !timerOptionsPopup.closing) {
                timerOptionsOverlay.closeForOptions()
            }
        }
    }

    Connections {
        target: Settings
        function onTimerChanged() {
            if (!Settings.timer) {
                shell.timerOptionsVisible = false
                timerOptionsPopup.popupHasBeenShown = false
                timerOptionsPopup.closing = false
                timerOptionsPopup.commentMode = false
                timerWidget.selectedFile = ""
                timerOptionsOverlay.hideAfterClose()
            }
        }
    }
    WidgetWindow {
        id: calendarWindow
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "calendar"
        visibilityAnimationStyle: Config.animationCalendarVisibilityStyle
        visibilityAnimationProfile: Config.animationCalendarVisibilityProfile
        layoutEditMode: shell.layoutEditMode
        // Keep this transparent surface alive while the module is enabled.
        // Otherwise the compositor can animate the layer-shell window itself,
        // making the module's explicit "none" style look like a fade.
        visible: Settings.calendar
        manageInputMask: true
        inputMaskEnabled: shell.calendarVisible || Config.calendarAlwaysVisible || calendarVisibility.running || shell.layoutEditMode
        backgroundBlurVisible: shell.calendarVisible || Config.calendarAlwaysVisible || calendarVisibility.running
        backgroundBlurItem: calendarVisibility.blurRegionItem
        offsetX: Settings.geometryForLayout("calendar")[0]
        offsetY: Settings.geometryForLayout("calendar")[1]
        contentWidth: Settings.geometry.calendar[2]
        contentHeight: Settings.geometry.calendar[3]
        // Keep the calendar below normal application windows; layout editing
        // temporarily promotes it through WidgetWindow.editWlrLayer.
        bottomLayer: true
        // The calendar becomes keyboard-focusable while editing a date note.
        // Layer-shell windows default to non-focusable, so TextArea.forceActiveFocus()
        // alone cannot receive key events until this is enabled.
        keyboardEnabled: calendarNotesWidget.noteOverlayMode === "edit"
        Primitives.AnimatedVisibility {
            id: calendarVisibility
            anchors.fill: parent
            shown: shell.calendarVisible || Config.calendarAlwaysVisible
            animationStyle: Config.animationCalendarVisibilityStyle
            animationProfile: Config.animationCalendarVisibilityProfile
            duration: Config.animationCalendarVisibilityStyle === "none" ? 0 : Config.animationDuration(Config.animationCalendarVisibilityStyle === "fade" ? Config.animationCalendarFadeDuration : Config.animationCalendarSlideDuration, "appearance")
            CalendarWidget { id: calendarNotesWidget; anchors.fill: parent; date: clock.now; open: true }
        }
    }

    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "volumes"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.volumes
        offsetX: Settings.geometryForLayout("volumes")[0]
        offsetY: Settings.geometryForLayout("volumes")[1]
        contentWidth: Settings.geometry.volumes[2]
        contentHeight: Math.min(Config.volumeMaxHeight, volumesWidget.animatedAdaptiveHeight)
        Volumes { id: volumesWidget; anchors.fill: parent; monitor: monitor }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "player"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.player
        offsetX: Settings.geometryForLayout("player")[0]
        offsetY: Settings.geometryForLayout("player")[1]
        contentWidth: Settings.geometry.player[2]
        contentHeight: Settings.geometry.player[3]
        Player {
            id: playerWidget
            anchors.fill: parent
            anchors.margins: 0
            dashboardActive: Settings.dashboard && shell.dashboardVisible
            onMediaTrackChanged: function(snapshot) { systemOsd.showMediaOsd(snapshot) }
            onMopidyToggleRequested: {
                if (Settings.mopidy && Config.mopidyToggleWithPlayerRightClick) {
                    if (shell.mopidyVisible) {
                        mopidyWidget.resetToInitialScreen()
                        shell.mopidyTopReveal = false
                    }
                    shell.mopidyVisible = !shell.mopidyVisible
                }
            }
        }
}
    WidgetWindow {
        id: mopidyWindow
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "mopidy"
        visibilityAnimationStyle: Config.animationMopidyVisibilityStyle
        visibilityAnimationProfile: Config.animationMopidyVisibilityProfile
        layoutEditMode: shell.layoutEditMode
        // Keep the transparent surface alive while Mopidy is enabled; only
        // its input and blur regions follow the module's visible/animated item.
        visible: Settings.mopidy
        manageInputMask: true
        inputMaskEnabled: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running || shell.layoutEditMode
        backgroundBlurVisible: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running
        backgroundBlurItem: mopidyVisibility.blurRegionItem
        offsetX: Settings.geometryForLayout("mopidy")[0]
        offsetY: Settings.geometryForLayout("mopidy")[1]
        contentWidth: Settings.geometry.mopidy[2]
        contentHeight: Settings.geometry.mopidy[3]
        keyboardEnabled: true
        bottomLayer: !(Config.mopidyHideTopPanel && shell.mopidyTopReveal)
        Primitives.AnimatedVisibility {
            id: mopidyVisibility
            anchors.fill: parent
            shown: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible
            animationStyle: Config.animationMopidyVisibilityStyle
            animationProfile: Config.animationMopidyVisibilityProfile
            duration: Config.animationMopidyVisibilityStyle === "none" ? 0 : Config.animationDuration(280, "appearance")
            MopidyComponents.Mopidy {
                id: mopidyWidget
                anchors.fill: parent
                externalTopPanelHover: shell.mopidyTopReveal
                onTopPanelHideRequested: shell.mopidyTopReveal = false
            }
        }
    }
    PanelWindow {
        id: mopidyTopHoverWindow
        // The invisible hover strip is only needed while the Mopidy module itself
        // is available; otherwise it would remain an input-blocking surface too.
        visible: Settings.mopidy && (!Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible) && Config.mopidyHideTopPanel && !shell.mopidyTopReveal
        screen: mopidyWindow.screen
        implicitWidth: Math.round(Settings.geometry.mopidy[2] * Config.moduleUiScale())
        implicitHeight: Math.round(Config.mopidyTopPanelHoverHeight * Config.moduleUiScale())
        color: Config.transparent
        focusable: false
        exclusionMode: ExclusionMode.Ignore
        anchors.left: true
        anchors.top: true
        margins.left: Settings.geometryForLayout("mopidy")[0]
        margins.top: Settings.geometryForLayout("mopidy")[1]
        WlrLayershell.layer: WlrLayer.Top

        MouseArea {
            id: mopidyTopRevealMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onEntered: shell.mopidyTopReveal = true
        }
    }

    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "cava"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.cava
        offsetX: Settings.geometryForLayout("cava")[0]
        offsetY: Settings.geometryForLayout("cava")[1]
        contentWidth: Settings.geometry.cava[2]
        contentHeight: Settings.geometry.cava[3]
        Cava {
            anchors.fill: parent
            onPlaybackToggleRequested: {
                var backend = String(playerWidget.player.player || "").trim().toLowerCase()
                if (backend !== "")
                    Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "pause", backend])
            }
            onMopidyToggleRequested: {
                if (Settings.mopidy && Config.mopidyToggleWithPlayerRightClick) {
                    if (shell.mopidyVisible) {
                        mopidyWidget.resetToInitialScreen()
                        shell.mopidyTopReveal = false
                    }
                    shell.mopidyVisible = !shell.mopidyVisible
                }
            }
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "networks"
        visibilityAnimationStyle: Config.animationNetworkVisibilityStyle
        visibilityAnimationProfile: Config.animationNetworkVisibilityProfile
        layoutEditMode: shell.layoutEditMode
        visible: Settings.networks
        manageInputMask: true
        inputMaskEnabled: Config.networksAlwaysVisible || shell.networksVisible || networksVisibility.running || shell.layoutEditMode
        backgroundBlurVisible: Config.networksAlwaysVisible || shell.networksVisible || networksVisibility.running
        backgroundBlurItem: networksVisibility.blurRegionItem
        offsetX: Settings.geometryForLayout("networks")[0]
        offsetY: Settings.geometryForLayout("networks")[1]
        contentWidth: Settings.geometry.networks[2]
        contentHeight: networksContent.implicitHeight
        // Keep the selector below normal application windows like other widgets.
        // Layout editing still promotes it to the top layer temporarily.
        bottomLayer: true
        Primitives.AnimatedVisibility {
            id: networksVisibility
            anchors.fill: parent
            shown: Config.networksAlwaysVisible || shell.networksVisible || shell.layoutEditMode
            animationStyle: Config.animationNetworkVisibilityStyle
            animationProfile: Config.animationNetworkVisibilityProfile
            duration: Config.animationNetworkVisibilityDuration
            Networks {
                id: networksContent
                anchors.fill: parent
                monitor: monitor
                maxContentHeight: Settings.geometry.networks[3]
            }
        }
    }

    WidgetWindow {
        id: settingsWindow
        moduleName: "settings"
        visibilityAnimationStyle: Config.animationSettingsVisibilityStyle
        visibilityAnimationProfile: Config.animationSettingsVisibilityProfile
        settingsDragMode: shell.settingsMoveMode
        layoutEditMode: shell.settingsMoveMode
        layoutEditor: layoutEditorWindow
        normalWlrLayer: WlrLayer.Overlay
        editWlrLayer: WlrLayer.Overlay
        // Keep the transparent overlay surface alive to avoid compositor-owned
        // fade-in/out animations; an empty mask passes all input through while
        // the settings content is closed.
        visible: true
        manageInputMask: true
        inputMaskEnabled: shell.settingsVisible || settingsVisibility.running
        backgroundBlurVisible: shell.settingsVisible || settingsVisibility.running
        backgroundBlurItem: settingsVisibility.blurRegionItem
        keyboardEnabled: shell.settingsVisible || settingsVisibility.running
        offsetX: Settings.settingsGeometry[0]
        offsetY: Settings.settingsGeometry[1]
        screenName: Settings.settingsMonitorName
        contentWidth: Settings.settingsGeometry[2]
        contentHeight: Settings.settingsGeometry[3]
        bottomLayer: false
        Primitives.AnimatedVisibility {
            id: settingsVisibility
            anchors.fill: parent
            shown: shell.settingsVisible
            cacheContent: true
            animationStyle: Config.animationSettingsVisibilityStyle
            animationProfile: Config.animationSettingsVisibilityProfile
            duration: Config.animationSettingsVisibilityStyle === "none" ? 0 : Config.animationDuration(300, "appearance")
            SettingsWidget {
                id: settingsWidget
            settingsMoveMode: shell.settingsMoveMode
            anchors.fill: parent
            onCloseRequested: {
                shell.settingsVisible = false
            }
            onLayoutEditRequested: {
                shell.settingsMoveMode = false
                shell.settingsVisible = false
                shell.layoutEditMode = true
            }
            onSettingsMoveRequested: {
                shell.layoutEditMode = false
                shell.settingsVisible = false
                shell.settingsMoveMode = true
                Qt.callLater(function() {
                    if (!shell.settingsMoveMode)
                        return
                    var moveScreen = settingsWindow.resolveScreen(Settings.settingsMonitorName || Config.monitorName)
                    if (!moveScreen)
                        return
                    var geometry = Settings.settingsGeometry || [0, 0, 560, 850]
                    layoutEditorWindow.beginProxyDrag(
                        "settings",
                        Number(moveScreen.x || 0) + Number(geometry[0] || 0),
                        Number(moveScreen.y || 0) + Number(geometry[1] || 0),
                        Number(geometry[2] || settingsWindow.visualContentWidth || 560),
                        Number(geometry[3] || settingsWindow.visualContentHeight || 850),
                        settingsWindow.screenStorageName(moveScreen)
                    )
                })
                }
            }
        }
    }

    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null }
    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 1 ? Quickshell.screens[1] : null }
    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 2 ? Quickshell.screens[2] : null }
    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 3 ? Quickshell.screens[3] : null }

    ModuleLayoutEditorWindow {
        id: moduleLayoutEditorWindow
        active: shell.layoutEditMode
        onExitRequested: {
            shell.layoutEditMode = false
            shell.settingsVisible = true
        }
    }

    LayoutEditorWindow {
        id: layoutEditorWindow
        active: shell.settingsMoveMode
        onExitRequested: {
            shell.settingsMoveMode = false
            shell.settingsVisible = true
        }
    }

}
