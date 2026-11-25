import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."
import "./modules/common"
import "./theme"
import "./models"
import "../../js/launcher/Calculator.js" as Calculator
import "../../js/launcher/CalculatorHistory.js" as CalculatorHistory
import "../../js/launcher/LauncherCustomActions.js" as LauncherCustomActions
import "../../js/launcher/LauncherSearchScoring.js" as LauncherSearchScoring
import "../../js/launcher/LauncherKeyboardLayout.js" as LauncherKeyboardLayout
import "../../js/launcher/LauncherEmojiPicker.js" as LauncherEmojiPicker
import "../../js/launcher/LauncherWallpaperPicker.js" as LauncherWallpaperPicker
import "../../js/launcher/LauncherSchemePicker.js" as LauncherSchemePicker
import "../../js/launcher/LauncherSchemeVariantPicker.js" as LauncherSchemeVariantPicker
import "../../js/launcher/LauncherDynamicScheme.js" as LauncherDynamicScheme
import "../../js/launcher/LauncherBuiltinActions.js" as LauncherBuiltinActions


PanelWindow {
    id: root

    // Internal hover/selection transitions share the launcher's local animation profile.
    // The separate launcher window entrance/exit animation below remains independent.
    readonly property int interactionAnimationDuration: Config.animationDurationForProfile(
        true, Config.animationLauncherMorphProfile,
        Config.animationLauncherMorphDuration, "appearance")
    readonly property int interactionAnimationEasing: Config.animationEasingType(
        Config.animationLauncherMorphProfile, "enter")
    readonly property var interactionAnimationBezierCurve: Config.animationBezierCurve(
        Config.animationLauncherMorphProfile, "enter")

    Theme { id: theme }

    // A single overlay frame is reused by each result view. It follows the
    // current item instead of fading separate borders on individual delegates.
    Component {
        id: launcherSelectionHighlight

        Rectangle {
            // Let the highlight follow the selected delegate itself. Keeping
            // the geometry animation here (rather than inside ListView) makes
            // keyboard-driven selection animate even when the key handlers
            // also scroll the view with positionViewAtIndex().
            readonly property var selectedDelegate: GridView.view ? GridView.view.currentItem
                : (ListView.view ? ListView.view.currentItem : null)

            x: selectedDelegate ? selectedDelegate.x : 0
            y: selectedDelegate ? selectedDelegate.y : 0
            width: selectedDelegate ? selectedDelegate.width : 0
            height: selectedDelegate ? selectedDelegate.height : 0

            z: 2
            color: "transparent"
            radius: Config.launcherItemRadius
            border.color: theme.borderAccent
            border.width: 1
            antialiasing: true

            Behavior on x {
                NumberAnimation {
                    duration: root.interactionAnimationDuration
                    easing.type: root.interactionAnimationEasing
                    easing.bezierCurve: root.interactionAnimationBezierCurve
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: root.interactionAnimationDuration
                    easing.type: root.interactionAnimationEasing
                    easing.bezierCurve: root.interactionAnimationBezierCurve
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: root.interactionAnimationDuration
                    easing.type: root.interactionAnimationEasing
                    easing.bezierCurve: root.interactionAnimationBezierCurve
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: root.interactionAnimationDuration
                    easing.type: root.interactionAnimationEasing
                    easing.bezierCurve: root.interactionAnimationBezierCurve
                }
            }
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: !root.layoutEditMode
    visible: false
    screen: root.resolveLauncherScreen()

    // PanelWindow/QsWindow does not expose Qt.Window.active. Track the
    // actual keyboard-focus items instead: the search field for result tabs
    // and launcherBox for the Power tab. This also works across monitors on
    // layer-shell compositors where a visible panel can lose keyboard focus.
    property bool launcherSessionHadFocus: false

    function launcherKeyboardFocusIsActive() {
        if (root.mode === root.modePower)
            return launcherBox.activeFocus
        return searchField.activeFocus
    }

    function handleLauncherKeyboardFocusChanged() {
        if (!root.visible || root.layoutEditMode)
            return

        if (root.launcherKeyboardFocusIsActive()) {
            launcherFocusLossTimer.stop()
            root.launcherSessionHadFocus = true
        } else if (root.launcherSessionHadFocus) {
            launcherFocusLossTimer.restart()
        }
    }

    Timer {
        id: launcherFocusLossTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.visible && !root.launcherKeyboardFocusIsActive()
                    && root.launcherSessionHadFocus && !root.layoutEditMode) {
                root.launcherSessionHadFocus = false
                root.hideLauncher()
            }
        }
    }

    color: theme.transparent

    property int mode: modeApps
    property bool layoutEditMode: false
    signal dashboardRequested()
    // Invalidates delayed asynchronous actions when the user closes, reopens,
    // or switches the launcher to another tab while a request is in flight.
    property int launcherInteractionGeneration: 0
    property int pendingFocusInteractionGeneration: -1
    property bool layoutEditWasVisible: false
    property int layoutEditSavedMode: modeApps
    property bool layoutDragging: false
    property bool layoutDragHidden: false
    property var layoutEditor: null
    property real layoutDragBaseGlobalX: 0
    property real layoutDragBaseGlobalY: 0
    property real layoutDragPressX: 0
    property real layoutDragPressY: 0

    readonly property var launcherGeometry: Settings.geometryForLayout("launcher")
    readonly property real launcherPositionX: {
        var position = Number(root.launcherGeometry && root.launcherGeometry[0])
        return isFinite(position) && position >= -10000
            ? position : Math.max(0, Math.round((root.width - Config.launcherWidth) / 2))
    }
    readonly property real launcherPositionY: {
        var position = Number(root.launcherGeometry && root.launcherGeometry[1])
        return isFinite(position) && position >= -10000
            ? position : Math.max(0, Math.round((root.height - Config.launcherHeight) / 2))
    }

    function resolveLauncherScreen() {
        var wanted = String((Settings.moduleMonitors || {}).launcher || Config.monitorName || "").trim().toLowerCase()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var candidate = Quickshell.screens[i]
            if (!candidate) continue
            if (wanted && (String(candidate.name || "").trim().toLowerCase() === wanted
                    || String(candidate.model || "").trim().toLowerCase() === wanted
                    || String(candidate).trim().toLowerCase() === wanted))
                return candidate
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function screenStorageName(screen) {
        if (!screen) return ""
        if (screen.name && String(screen.name).trim() !== "") return String(screen.name)
        if (screen.model && String(screen.model).trim() !== "") return String(screen.model)
        return ""
    }

    function findScreenForGlobalPoint(globalX, globalY) {
        var nearest = null
        var nearestDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var candidate = Quickshell.screens[i]
            if (!candidate) continue
            var sx = Number(candidate.x || 0)
            var sy = Number(candidate.y || 0)
            var sw = Number(candidate.width || 0)
            var sh = Number(candidate.height || 0)
            if (globalX >= sx && globalX < sx + sw && globalY >= sy && globalY < sy + sh)
                return candidate
            var cx = Math.max(sx, Math.min(globalX, sx + sw))
            var cy = Math.max(sy, Math.min(globalY, sy + sh))
            var dx = globalX - cx
            var dy = globalY - cy
            var distance = dx * dx + dy * dy
            if (distance < nearestDistance) {
                nearestDistance = distance
                nearest = candidate
            }
        }
        return nearest || root.screen || Quickshell.screens[0] || null
    }

    function beginLayoutEdit() {
        if (!Config.launcherEnabled || root.layoutEditMode) return
        root.launcherInteractionGeneration += 1
        root.invalidateAllAsyncRequests()
        root.layoutEditWasVisible = root.visible
        root.layoutEditSavedMode = root.mode
        root.layoutEditMode = true
        root.layoutDragHidden = false
        root.visible = true
        // Select a stable preview mode without asking this non-focusable window to take keyboard focus.
        root.mode = root.configuredDefaultMode()
    }

    function cancelLayoutDrag() {
        if (!root.layoutDragging) return
        if (root.layoutEditor) root.layoutEditor.endProxyDrag()
        Settings.cancelGeometryDrag("launcher")
        root.layoutDragging = false
        root.layoutDragHidden = false
    }

    function endLayoutEdit() {
        if (!root.layoutEditMode) return
        root.launcherInteractionGeneration += 1
        root.cancelLayoutDrag()
        root.layoutEditMode = false
        root.visible = root.layoutEditWasVisible
        if (root.visible) root.setMode(root.layoutEditSavedMode)
    }

    function beginLauncherDrag(mouse) {
        if (!root.layoutEditMode || root.layoutDragging || !root.layoutEditor) return
        root.layoutDragging = true
        root.layoutDragPressX = Number(mouse.x)
        root.layoutDragPressY = Number(mouse.y)
        root.layoutDragBaseGlobalX = Number(root.screen && root.screen.x || 0) + Number(launcherBox.x)
        root.layoutDragBaseGlobalY = Number(root.screen && root.screen.y || 0) + Number(launcherBox.y)
        Settings.beginGeometryDrag("launcher")
        root.layoutEditor.beginProxyDrag(
            "launcher", root.layoutDragBaseGlobalX, root.layoutDragBaseGlobalY,
            Config.launcherWidth, Config.launcherHeight
        )
        launcherBox.grabToImage(function(result) {
            if (!root.layoutDragging) return
            root.layoutDragHidden = true
            if (root.layoutEditor) root.layoutEditor.setProxySource(result.url)
        }, Qt.size(Math.max(1, Math.round(Config.launcherWidth)), Math.max(1, Math.round(Config.launcherHeight))))
    }

    function updateLauncherDrag(mouse) {
        if (!root.layoutEditMode || !root.layoutDragging || !root.layoutEditor) return
        var globalX = root.layoutDragBaseGlobalX + Number(mouse.x) - root.layoutDragPressX
        var globalY = root.layoutDragBaseGlobalY + Number(mouse.y) - root.layoutDragPressY
        root.layoutEditor.updateProxyDrag(globalX, globalY, Config.launcherWidth, Config.launcherHeight)
    }

    function finishLauncherDrag(mouse) {
        if (!root.layoutDragging) return
        var globalX = root.layoutDragBaseGlobalX + Number(mouse.x) - root.layoutDragPressX
        var globalY = root.layoutDragBaseGlobalY + Number(mouse.y) - root.layoutDragPressY
        var targetScreen = root.findScreenForGlobalPoint(
            globalX + Config.launcherWidth / 2, globalY + Config.launcherHeight / 2
        )
        var localX = globalX - Number(targetScreen && targetScreen.x || 0)
        var localY = globalY - Number(targetScreen && targetScreen.y || 0)
        if (root.layoutEditor) root.layoutEditor.endProxyDrag()
        Settings.endGeometryDrag("launcher", root.screenStorageName(targetScreen), localX, localY)
        root.layoutDragging = false
        root.layoutDragHidden = false
    }

    // One pointer identity for every list: no stale per-delegate hover flags.
    property real trackedPointerX: 0
    property real trackedPointerY: 0
    property real trackedGlobalPointerX: 0
    property real trackedGlobalPointerY: 0
    property bool pointerGlobalPositionKnown: false
    property bool pointerHoverMotionArmed: false
    property bool pointerInsideLauncher: false
    property int pointerHoveredMode: -1
    property int pointerHoveredIndex: -1

    onModeChanged: {
        root.disarmPointerHover()
        modeHoverRefreshTimer.restart()
    }

    Timer {
        id: modeHoverRefreshTimer
        interval: 20
        repeat: false
        onTriggered: root.refreshHoverVisualsForMode()
    }

    readonly property int modeApps: 0
    readonly property int modeRun: 1
    readonly property int modeWindows: 2
    readonly property int modeClipboard: 3
    readonly property int modePower: 4
    readonly property int modeNetwork: 5
    readonly property int modeNix: 6
    readonly property int modePass: 7
    readonly property int modeProjects: 8
    readonly property int modeCalculator: 9

    readonly property var defaultModeTabs: [
        { id: 0, icon: "󰀻", label: "Apps", mode: root.modeApps },
        { id: 1, icon: "", label: "Run", mode: root.modeRun },
        { id: 2, icon: "󰖯", label: "Windows", mode: root.modeWindows },
        { id: 3, icon: "󰅇", label: "Clipboard", mode: root.modeClipboard },
        { id: 4, icon: "", label: "Power", mode: root.modePower },
        { id: 5, icon: "󰖩", label: "Network", mode: root.modeNetwork },
        { id: 6, icon: "󱄅", label: "Packages", mode: root.modeNix },
        { id: 7, icon: "󰌋", label: "Pass", mode: root.modePass },
        { id: 8, icon: "", label: "Projects", mode: root.modeProjects },
        { id: 9, icon: "󰃬", label: "Calculator", mode: root.modeCalculator }
    ]

    readonly property var allModeTabs: {
        var labels = Config.launcherTabLabels instanceof Array ? Config.launcherTabLabels : []
        var icons = Config.launcherTabIcons instanceof Array ? Config.launcherTabIcons : []
        var result = []
        for (var i = 0; i < root.defaultModeTabs.length; ++i) {
            var fallback = root.defaultModeTabs[i]
            var label = labels[i] === undefined ? fallback.label : String(labels[i]).replace(/[\r\n\t]/g, " ").trim().slice(0, 32)
            var icon = icons[i] === undefined ? fallback.icon : String(icons[i]).replace(/[\r\n\t]/g, " ").slice(0, 16)
            result.push({ id: fallback.id, icon: icon, label: label || fallback.label, mode: fallback.mode })
        }
        return result
    }

    function normalizedModeTabOrder() {
        var result = []
        var saved = Config.launcherTabOrder
        if (saved instanceof Array) {
            for (var i = 0; i < saved.length; ++i) {
                var id = Number(saved[i])
                if (isFinite(id) && Math.floor(id) === id && id >= 0 && id < root.allModeTabs.length && result.indexOf(id) < 0)
                    result.push(id)
            }
        }
        for (var j = 0; j < root.allModeTabs.length; ++j) {
            if (result.indexOf(j) < 0) result.push(j)
        }
        return result
    }

    readonly property var displayedModeTabs: {
        var order = root.normalizedModeTabOrder()
        var visibility = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible : []
        var result = []
        for (var i = 0; i < order.length; ++i) {
            var id = order[i]
            if (visibility[id] !== false)
                result.push(root.allModeTabs[id])
        }
        return result
    }

    readonly property int selectedModeTabIndex: {
        var tabs = root.displayedModeTabs
        for (var i = 0; i < tabs.length; ++i) {
            if (tabs[i].mode === root.mode)
                return i
        }
        return -1
    }

    property string currentModeName: {
        var tabs = root.allModeTabs
        for (var i = 0; i < tabs.length; ++i) {
            if (tabs[i].mode === root.mode)
                return tabs[i].label
        }
        return "Apps"
    }

    property int currentResultCount: {
        switch (mode) {
        case modeApps: return appList.count
        case modeRun: return runList.count
        case modeWindows: return windowList.count
        case modeClipboard: return clipboardList.count
        case modePower: return powerList.count
        case modeNetwork: return networkList.count
        case modeNix: return nixList.count
        case modePass: return passList.count
        case modeProjects: return projectList.count
        case modeCalculator: return calculatorList.count
        default: return 0
        }
    }

    function configuredDefaultMode() {
        const value = Number(Config.launcherDefaultMode)
        if (!isFinite(value) || value < 0 || value > 9)
            return root.modeApps
        const modeValue = Math.round(value)
        const visibility = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible : []
        if (visibility[modeValue] === false) {
            const firstVisible = root.displayedModeTabs.length > 0 ? root.displayedModeTabs[0] : null
            return firstVisible ? firstVisible.mode : root.modeApps
        }
        return modeValue
    }

    function restoreLauncherKeyboardFocus() {
        if (!root.visible || root.layoutEditMode)
            return
        if (root.mode === root.modePower)
            launcherBox.forceActiveFocus()
        else
            searchField.forceActiveFocus()
    }

    function showLauncher() {
        root.visible = true
        root.setMode(root.configuredDefaultMode())
        Qt.callLater(root.restoreLauncherKeyboardFocus)
    }

    function hideLauncher() {
        launcherFocusLossTimer.stop()
        root.launcherSessionHadFocus = false
        // Invalidate completion callbacks from work started in the previous
        // visible session so they cannot close a launcher reopened meanwhile.
        root.launcherInteractionGeneration += 1
        // Keep the query while switching tabs, but start fresh after closing the launcher.
        searchField.text = ""
        // Drop any pending/in-flight Nix search so its response cannot replace
        // results from a later launcher session or a different query.
        root.nixSearchGeneration += 1
        nixSearchTimer.stop()
        if (nixSearchProcess.running)
            nixSearchProcess.running = false
        root.nixSearching = false
        root.invalidateAllAsyncRequests()
        root.visible = false
    }

    function toggleLauncher() {
        if (root.visible)
            hideLauncher()
        else
            showLauncher()
    }

    function modeFromName(modeName) {
        switch (String(modeName ?? "apps").toLowerCase()) {
        case "default": return root.configuredDefaultMode()
        case "apps": return root.modeApps
        case "run": return root.modeRun
        case "windows": return root.modeWindows
        case "clipboard": return root.modeClipboard
        case "power": return root.modePower
        case "network":
        case "networks": return root.modeNetwork
        case "nix":
        case "packages": return root.modeNix
        case "pass": return root.modePass
        case "project":
        case "projects": return root.modeProjects
        case "calculator":
        case "calc": return root.modeCalculator
        default: return root.modeApps
        }
    }

    // Async data processes carry request generations in their stdout. Leaving a
    // mode or closing the launcher invalidates any output that has not committed yet.
    function invalidateModeAsyncRequests(modeValue) {
        if (modeValue === root.modeWindows) {
            root.niriWindowsGeneration += 1
            if (niriWindowsProcess.running)
                niriWindowsProcess.running = false
        } else if (modeValue === root.modeClipboard) {
            root.clipboardGeneration += 1
            clipboardReloadTimer.stop()
            if (clipboardProcess.running)
                clipboardProcess.running = false
        } else if (modeValue === root.modePass) {
            root.passGeneration += 1
            root.passLoading = false
            if (passListProcess.running)
                passListProcess.running = false
        }
    }

    function invalidateAllAsyncRequests() {
        root.invalidateModeAsyncRequests(root.modeWindows)
        root.invalidateModeAsyncRequests(root.modeClipboard)
        root.invalidateModeAsyncRequests(root.modePass)
    }

    // Entry point called by the host shell's IpcHandler. This keeps one
    // Quickshell process and lets Niri bind a separate key to every mode.
    function openMode(modeName) {
        const requestedMode = root.modeFromName(modeName)
        root.visible = true
        root.setMode(requestedMode)
        Qt.callLater(root.restoreLauncherKeyboardFocus)
    }

    function setMode(newMode) {
        // A new tab selection is a new launcher interaction context; delayed
        // actions must not hide a different tab when they eventually complete.
        if (root.mode !== newMode)
            root.invalidateModeAsyncRequests(root.mode)
        root.launcherInteractionGeneration += 1
        // Results from the previous tab/search are no longer allowed to commit.
        root.nixSearchGeneration += 1
        nixSearchTimer.stop()
        if (newMode !== root.modeNix && nixSearchProcess.running) {
            nixSearchProcess.running = false
            root.nixSearching = false
        }
        root.mode = newMode

        // Keep a single query while switching tabs. Each tab applies the same
        // text to its own model instead of silently erasing the user's search.
        root.resetSelection()

        if (root.mode === root.modeRun) {
            root.rebuildRunHistoryModel()
            root.rebuildRunModel()
            if (!runCommandsProcess.running && runCompletionModel.count === 0)
                runCommandsProcess.running = true
        }

        if (root.mode === root.modeWindows) {
            Qt.callLater(function() {
                root.refreshNiriWindows()
                root.selectRecentWindow()
            })
        }

        if (root.mode === root.modeClipboard)
            root.loadClipboard()

        if (root.mode === root.modeNetwork) {
            Network.refresh()
            Qt.callLater(root.rebuildNetworkModel)
        }

        if (root.mode === root.modeNix) {
            Qt.callLater(root.searchNixPackages)
        }

        if (root.mode === root.modePass) {
            Qt.callLater(root.loadPassEntries)
        }

        if (root.mode === root.modeProjects)
            root.rebuildProjectsModel()

        if (root.mode === root.modeCalculator)
            calculatorList.currentIndex = root.calculatorDisplayResults.length > 0 ? 0 : -1

        if (root.mode === root.modePower)
            launcherBox.forceActiveFocus()
        else
            searchField.forceActiveFocus()
    }

    function activeListForMode(modeValue) {
        switch (modeValue) {
        case root.modeApps: return appList
        case root.modeRun: return runList
        case root.modeWindows: return windowList
        case root.modeClipboard: return clipboardList
        case root.modeNetwork: return networkList
        case root.modeNix: return nixList
        case root.modePass: return passList
        case root.modePower: return powerList
        case root.modeProjects: return projectList
        case root.modeCalculator: return calculatorList
        default: return null
        }
    }

    function clearPointerHover() {
        root.pointerHoveredMode = -1
        root.pointerHoveredIndex = -1
    }

    function disarmPointerHover() {
        // Geometry, filtering, scrolling and tab switches must not turn a row
        // under a stationary cursor into a hover target.
        root.pointerHoverMotionArmed = false
        root.clearPointerHover()
    }

    function pointerIndexForList(activeList) {
        if (!activeList || !activeList.visible || activeList.count <= 0)
            return -1
        const localPoint = activeList.mapFromItem(
            launcherBox, root.trackedPointerX, root.trackedPointerY
        )
        const index = activeList.indexAt(localPoint.x, localPoint.y)
        return index >= 0 && index < activeList.count ? index : -1
    }

    function activatePointerHoverAtCurrentPosition() {
        if (!root.visible || !root.pointerInsideLauncher || !root.pointerHoverMotionArmed) {
            root.clearPointerHover()
            return
        }
        const activeList = root.activeListForMode(root.mode)
        const hoveredIndex = root.pointerIndexForList(activeList)
        root.pointerHoveredMode = hoveredIndex >= 0 ? root.mode : -1
        root.pointerHoveredIndex = hoveredIndex
        if (hoveredIndex >= 0 && activeList.currentIndex !== hoveredIndex)
            activeList.currentIndex = hoveredIndex
    }

    // Retained for existing call sites; refreshing visuals never chooses a new
    // item. Only a physical pointer move may do that.
    function refreshHoverForMode() {
        root.refreshHoverVisualsForMode()
    }

    function refreshHoverVisualsForMode() {
        if (!root.visible || !root.pointerInsideLauncher || !root.pointerHoverMotionArmed) {
            root.clearPointerHover()
            return
        }
        const activeList = root.activeListForMode(root.mode)
        const hoveredIndex = root.pointerIndexForList(activeList)
        // If layout or scrolling moved a different row under the cursor, clear
        // the old hover instead of silently activating the new row.
        if (hoveredIndex < 0 || root.pointerHoveredMode !== root.mode || hoveredIndex !== root.pointerHoveredIndex) {
            root.disarmPointerHover()
            return
        }
        root.pointerHoveredMode = root.mode
    }

    function updatePointerPosition(point) {
        if (!point)
            return
        const localX = Number(point.position.x)
        const localY = Number(point.position.y)
        let globalX = NaN
        let globalY = NaN
        if (point.globalPosition) {
            globalX = Number(point.globalPosition.x)
            globalY = Number(point.globalPosition.y)
        } else if (point.scenePosition) {
            globalX = Number(point.scenePosition.x)
            globalY = Number(point.scenePosition.y)
        }
        const moved = root.pointerGlobalPositionKnown && isFinite(globalX) && isFinite(globalY)
            && (Math.abs(globalX - root.trackedGlobalPointerX) > 0.5
                || Math.abs(globalY - root.trackedGlobalPointerY) > 0.5)
        root.trackedPointerX = localX
        root.trackedPointerY = localY
        if (isFinite(globalX) && isFinite(globalY)) {
            root.trackedGlobalPointerX = globalX
            root.trackedGlobalPointerY = globalY
            root.pointerGlobalPositionKnown = true
        }
        if (moved && root.visible && root.pointerInsideLauncher) {
            root.pointerHoverMotionArmed = true
            root.activatePointerHoverAtCurrentPosition()
        }
        return moved
    }

    // Window discovery uses the niri CLI so the launcher has no hard QML
    // dependency on the external Niri 0.1 plugin. These processes only run
    // while the Windows tab is open.
    property var niriWindows: []
    property int niriWindowsGeneration: 0
    property int niriWindowsPendingGeneration: -1
    property string pendingFocusWindowId: ""
    property string niriCliError: ""

    Process {
        id: niriWindowsProcess
        command: [
            "zsh", "-ic",
            "niri msg -j windows; rc=$?; printf '\n__NIRI_WINDOWS_REQUEST__%s\n' \"$1\"; exit \"$rc\"",
            "qs-launcher-windows",
            String(root.niriWindowsPendingGeneration)
        ]

        stdout: StdioCollector {
            onStreamFinished: root.acceptNiriWindows(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text ?? "").trim()
                if (message !== "" && root.visible && root.mode === root.modeWindows)
                    console.warn("Launcher: niri window query reported:", message)
            }
        }

        onExited: function(exitCode) {
            // Result handling is generation-gated in acceptNiriWindows(). Do not
            // clear the current model here: an older process can exit late.
            if (exitCode !== 0 && root.visible && root.mode === root.modeWindows)
                console.warn("Launcher: niri msg -j windows exited with code", exitCode)
        }
    }

    Process {
        id: niriFocusProcess
        command: [
            "zsh", "-ic",
            "niri msg action focus-window --id \"$1\"",
            "qs-launcher-focus-window",
            root.pendingFocusWindowId
        ]

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text ?? "").trim()
                if (message !== "")
                    console.warn("Launcher: focus window failed:", message)
            }
        }

        onExited: function(exitCode) {
            if (exitCode === 0) {
                // niri focus-window is asynchronous. Only close the same
                // still-visible Windows launcher context that requested it;
                // otherwise a delayed response can close a newly reopened UI.
                if (root.visible && root.mode === root.modeWindows &&
                    root.pendingFocusInteractionGeneration === root.launcherInteractionGeneration) {
                    root.hideLauncher()
                }
            } else {
                console.warn("Launcher: focus-window action exited with code", exitCode)
            }
        }
    }

    Timer {
        id: windowRefreshTimer
        interval: 1500
        repeat: true
        running: root.visible && root.mode === root.modeWindows
        onTriggered: root.refreshNiriWindows()
    }

    /*
     * CALCULATOR HISTORY
     */

    property var calculatorHistoryEntries: []
    property int calculatorHistoryGeneration: 0
    property int calculatorHistoryPendingGeneration: -1
    property bool calculatorHistoryLoadPending: false
    property var calculatorHistoryPendingMutations: []
    property bool calculatorHistoryPersistAfterLoad: false
    property string calculatorHistoryWriteActivePayload: ""
    property string calculatorHistoryWriteQueuedPayload: ""
    property bool calculatorHistoryWriteHasQueuedPayload: false
    property int calculatorHistoryWriteSequence: 0
    property string calculatorHistoryFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-calculator-history.json"

    Process {
        id: calculatorHistoryProcess
        command: [
            "sh",
            "-c",
            "cat -- \"$1\" 2>/dev/null; status=$?; printf '\\n__CALCULATOR_HISTORY_REQUEST__%s\\n' \"$2\"; exit \"$status\"",
            "launcher-calculator-history",
            root.calculatorHistoryFile,
            String(root.calculatorHistoryPendingGeneration)
        ]
        stdout: StdioCollector {
            onStreamFinished: root.acceptCalculatorHistory(this.text)
        }
    }

    Process {
        id: calculatorHistoryWriteProcess
        command: [
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && tmp=\"$1.tmp.$$.$3\" && printf '%s\\n' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
            "launcher-calculator-history-write",
            root.calculatorHistoryFile,
            root.calculatorHistoryWriteActivePayload,
            String(root.calculatorHistoryWriteSequence)
        ]
        onExited: function(exitCode) {
            root.finishCalculatorHistoryWrite(exitCode)
        }
    }

    /*
     * RUN HISTORY
     */

    ListModel {
        id: runHistoryModel
    }

    ListModel {
        id: runCompletionModel
    }

    property var runHistoryEntries: []
    property int runHistoryGeneration: 0
    property int runHistoryPendingGeneration: -1
    property bool runHistoryLoadPending: false
    property var runHistoryPendingMutations: []
    property bool runHistoryPersistAfterLoad: false
    property string runHistoryWriteActivePayload: ""
    property string runHistoryWriteQueuedPayload: ""
    property bool runHistoryWriteHasQueuedPayload: false
    property int runHistoryWriteSequence: 0
    property string runHistoryFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-run-history"

    Process {
        id: runHistoryProcess

        command: [
            "sh",
            "-c",
            "cat -- \"$1\" 2>/dev/null; status=$?; printf '\\n__RUN_HISTORY_REQUEST__%s\\n' \"$2\"; exit \"$status\"",
            "launcher-history",
            root.runHistoryFile,
            String(root.runHistoryPendingGeneration)
        ]

        stdout: StdioCollector {
            onStreamFinished: root.acceptRunHistory(this.text)
        }
    }

    // Serialize persistence so concurrent edits cannot race on a shared temp
    // file or let an older full-history snapshot overwrite a newer one.
    Process {
        id: runHistoryWriteProcess

        command: [
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && tmp=\"$1.tmp.$$.$3\" && printf '%s\\n' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
            "launcher-history-write",
            root.runHistoryFile,
            root.runHistoryWriteActivePayload,
            String(root.runHistoryWriteSequence)
        ]

        onExited: function(exitCode) {
            root.finishRunHistoryWrite(exitCode)
        }
    }

    Process {
        id: runCommandsProcess

        command: [
            "zsh",
            "-ic",
            "print -rl -- ${(ok)commands} ${(ok)aliases} | sort -u"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.loadRunCommands(this.text)
            }
        }
    }

    function parseCalculatorHistory(output) {
        return CalculatorHistory.parseHistory(output)
    }

    function recordCalculatorHistoryMutation(type, entry) {
        root.calculatorHistoryGeneration += 1
        if (!root.calculatorHistoryLoadPending)
            return

        const mutations = Array.isArray(root.calculatorHistoryPendingMutations)
            ? root.calculatorHistoryPendingMutations.slice()
            : []
        mutations.push({ type: String(type), entry: entry ? { expression: String(entry.expression || ""), result: String(entry.result || "") } : null })
        root.calculatorHistoryPendingMutations = mutations
    }

    function acceptCalculatorHistory(output) {
        const text = String(output ?? "")
        const marker = "\n__CALCULATOR_HISTORY_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0)
            return

        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration)
                || requestGeneration !== root.calculatorHistoryPendingGeneration
                || !root.calculatorHistoryLoadPending) {
            return
        }

        const diskEntries = root.parseCalculatorHistory(text.slice(0, markerIndex))
        const mutations = Array.isArray(root.calculatorHistoryPendingMutations)
            ? root.calculatorHistoryPendingMutations.slice()
            : []
        const mergedEntries = CalculatorHistory.applyMutations(diskEntries, mutations)
        const shouldPersistMergedHistory = mutations.length > 0 || root.calculatorHistoryPersistAfterLoad

        root.calculatorHistoryEntries = mergedEntries
        root.calculatorHistoryLoadPending = false
        root.calculatorHistoryPendingMutations = []
        root.calculatorHistoryPersistAfterLoad = false
        if (shouldPersistMergedHistory)
            root.persistCalculatorHistory()
    }

    function loadCalculatorHistoryFromDisk() {
        if (calculatorHistoryProcess.running)
            calculatorHistoryProcess.running = false

        root.calculatorHistoryGeneration += 1
        root.calculatorHistoryPendingGeneration = root.calculatorHistoryGeneration
        root.calculatorHistoryLoadPending = true
        root.calculatorHistoryPendingMutations = []
        calculatorHistoryProcess.running = true
    }

    function startCalculatorHistoryWrite(payload) {
        root.calculatorHistoryWriteActivePayload = String(payload ?? "")
        root.calculatorHistoryWriteSequence += 1
        calculatorHistoryWriteProcess.running = true
    }

    function finishCalculatorHistoryWrite(exitCode) {
        if (exitCode !== 0)
            console.warn("Launcher: failed to persist Calculator history (exit code", exitCode, ")")

        if (!root.calculatorHistoryWriteHasQueuedPayload)
            return

        const latestPayload = root.calculatorHistoryWriteQueuedPayload
        root.calculatorHistoryWriteQueuedPayload = ""
        root.calculatorHistoryWriteHasQueuedPayload = false
        root.startCalculatorHistoryWrite(latestPayload)
    }

    function persistCalculatorHistory() {
        if (root.calculatorHistoryLoadPending) {
            root.calculatorHistoryPersistAfterLoad = true
            return
        }

        const data = CalculatorHistory.serialize(root.calculatorHistoryEntries)
        if (calculatorHistoryWriteProcess.running) {
            root.calculatorHistoryWriteQueuedPayload = data
            root.calculatorHistoryWriteHasQueuedPayload = true
            return
        }

        root.calculatorHistoryWriteQueuedPayload = ""
        root.calculatorHistoryWriteHasQueuedPayload = false
        root.startCalculatorHistoryWrite(data)
    }

    function rememberCalculatorCalculation(expression, result) {
        const entry = {
            expression: String(expression ?? "").trim(),
            result: String(result ?? "").trim()
        }
        const nextEntries = CalculatorHistory.remember(root.calculatorHistoryEntries, entry)
        root.recordCalculatorHistoryMutation("remember", entry)
        root.calculatorHistoryEntries = nextEntries
        root.persistCalculatorHistory()
    }

    function clearCalculatorHistory() {
        root.recordCalculatorHistoryMutation("clear", null)
        root.calculatorHistoryEntries = []
        root.persistCalculatorHistory()
    }

    function parseRunHistory(output) {
        const entries = []
        const seen = {}
        const lines = String(output ?? "").split("\n")

        // Newest first, with duplicates removed.
        for (let i = lines.length - 1; i >= 0; --i) {
            const command = lines[i].trim()
            if (command === "" || seen[command])
                continue
            seen[command] = true
            entries.push(command)
            if (entries.length >= 100)
                break
        }
        return entries
    }

    function recordRunHistoryMutation(type, command) {
        root.runHistoryGeneration += 1
        if (!root.runHistoryLoadPending)
            return

        const mutations = Array.isArray(root.runHistoryPendingMutations)
            ? root.runHistoryPendingMutations.slice()
            : []
        mutations.push({ type: String(type), command: String(command ?? "") })
        root.runHistoryPendingMutations = mutations
    }

    function acceptRunHistory(output) {
        const text = String(output ?? "")
        const marker = "\n__RUN_HISTORY_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0) return

        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration) ||
            requestGeneration !== root.runHistoryPendingGeneration ||
            !root.runHistoryLoadPending) {
            return
        }

        // The file read may have started before a user launched/deleted a
        // command or cleared history. Re-apply those recorded mutations to the
        // disk snapshot instead of replacing newer in-memory intent with stale data.
        const entries = root.parseRunHistory(text.slice(0, markerIndex))
        const mutations = Array.isArray(root.runHistoryPendingMutations)
            ? root.runHistoryPendingMutations.slice()
            : []

        for (const mutation of mutations) {
            const type = String(mutation.type ?? "")
            const command = String(mutation.command ?? "")

            if (type === "clear") {
                entries.length = 0
            } else if (type === "delete" && command !== "") {
                const index = entries.indexOf(command)
                if (index >= 0) entries.splice(index, 1)
            } else if (type === "remember" && command !== "") {
                const index = entries.indexOf(command)
                if (index >= 0) entries.splice(index, 1)
                entries.unshift(command)
                if (entries.length > 100) entries.length = 100
            }
        }

        const shouldPersistMergedHistory = mutations.length > 0 || root.runHistoryPersistAfterLoad
        root.runHistoryEntries = entries
        root.runHistoryLoadPending = false
        root.runHistoryPendingMutations = []
        root.runHistoryPersistAfterLoad = false
        root.rebuildRunHistoryModel()
        if (shouldPersistMergedHistory)
            root.persistRunHistory()
    }

    function rebuildRunHistoryModel() {
        runHistoryModel.clear()

        const query = normalizeWindowText(searchField.text)

        for (const command of root.runHistoryEntries) {
            const score = query === ""
                ? 0
                : fuzzyWindowScore(command, query)

            if (query === "" || score >= 0) {
                runHistoryModel.append({
                    command: command,
                    score: score
                })
            }
        }

        if (query !== "") {
            // ListModel does not provide a convenient JS sort, so rebuild
            // through an array when searching.
            const result = []

            for (let i = 0; i < runHistoryModel.count; ++i) {
                const item = runHistoryModel.get(i)
                result.push({
                    command: item.command,
                    score: item.score
                })
            }

            result.sort(function(a, b) {
                if (b.score !== a.score)
                    return b.score - a.score

                return a.command.localeCompare(b.command)
            })

            runHistoryModel.clear()

            for (const item of result)
                runHistoryModel.append(item)
        }

        if (runList.count > 0)
            runList.currentIndex = 0
        else
            runList.currentIndex = -1

        if (root.mode === root.modeRun)
            root.rebuildRunModel()
    }

    function loadRunHistoryFromDisk() {
        if (runHistoryProcess.running)
            runHistoryProcess.running = false

        root.runHistoryGeneration += 1
        root.runHistoryPendingGeneration = root.runHistoryGeneration
        root.runHistoryLoadPending = true
        root.runHistoryPendingMutations = []
        runHistoryProcess.running = true
    }

    function startRunHistoryWrite(payload) {
        root.runHistoryWriteActivePayload = String(payload ?? "")
        root.runHistoryWriteSequence += 1
        runHistoryWriteProcess.running = true
    }

    function finishRunHistoryWrite(exitCode) {
        if (exitCode !== 0)
            console.warn("Launcher: failed to persist Run history (exit code", exitCode, ")")

        if (!root.runHistoryWriteHasQueuedPayload)
            return

        const latestPayload = root.runHistoryWriteQueuedPayload
        root.runHistoryWriteQueuedPayload = ""
        root.runHistoryWriteHasQueuedPayload = false
        root.startRunHistoryWrite(latestPayload)
    }

    function persistRunHistory() {
        // Startup loading merges the disk snapshot with any user mutations.
        // Never write a partial in-memory list over the file before that merge.
        if (root.runHistoryLoadPending) {
            root.runHistoryPersistAfterLoad = true
            return
        }

        // The parser treats file lines as oldest-first, while the in-memory
        // model is newest-first; keep that disk format consistent for reloads.
        const data = root.runHistoryEntries.slice().reverse().join("\n")
        if (runHistoryWriteProcess.running) {
            // Keep only the latest snapshot. Intermediate snapshots would be
            // stale as soon as a later edit has already changed the model.
            root.runHistoryWriteQueuedPayload = data
            root.runHistoryWriteHasQueuedPayload = true
            return
        }

        // If the process just exited but its completion callback has not yet
        // consumed a queued payload, the current model snapshot takes priority.
        root.runHistoryWriteQueuedPayload = ""
        root.runHistoryWriteHasQueuedPayload = false
        root.startRunHistoryWrite(data)
    }

    function deleteRunHistory(index) {
        if (index < 0 || index >= root.runResults.length)
            return

        const item = root.runResults[index]
        if (!item || item.source !== "history")
            return

        const command = String(item.command ?? "")
        if (!command)
            return

        const entries = root.runHistoryEntries.slice()
        const historyIndex = entries.indexOf(command)
        if (historyIndex < 0)
            return

        entries.splice(historyIndex, 1)
        root.recordRunHistoryMutation("delete", command)
        root.runHistoryEntries = entries
        root.rebuildRunHistoryModel()
        root.rebuildRunModel()
        root.persistRunHistory()
    }

    function clearRunHistory() {
        root.recordRunHistoryMutation("clear", "")
        root.runHistoryEntries = []
        root.rebuildRunHistoryModel()
        root.rebuildRunModel()
        root.persistRunHistory()
    }

    function rememberRunCommand(command) {
        command = String(command ?? "").trim()

        if (command === "")
            return

        root.recordRunHistoryMutation("remember", command)
        const entries = [command]

        for (const oldCommand of root.runHistoryEntries) {
            if (oldCommand !== command)
                entries.push(oldCommand)

            if (entries.length >= 100)
                break
        }

        root.runHistoryEntries = entries
        root.rebuildRunHistoryModel()

        // Persist the whole canonical snapshot through the serialized writer;
        // concurrent command launches collapse to the newest queued snapshot.
        root.persistRunHistory()
    }

    readonly property var calculatorEvaluation: Calculator.evaluate(searchField.text)
    property var calculatorResults: root.buildCalculatorResults()
    property var calculatorDisplayResults: root.buildCalculatorDisplayResults()

    function buildCalculatorResults() {
        const parsed = root.calculatorEvaluation
        if (!parsed)
            return []
        return [{ kind: "calculator", expression: parsed.expression, result: parsed.text, value: parsed.value }]
    }

    function buildCalculatorDisplayResults() {
        if (root.calculatorResults.length > 0)
            return root.calculatorResults
        if (root.normalizeRunText(searchField.text) !== "")
            return []

        const entries = Array.isArray(root.calculatorHistoryEntries)
            ? root.calculatorHistoryEntries
            : []
        return entries.map(function(entry) {
            return {
                kind: "calculatorHistory",
                expression: String(entry.expression || ""),
                result: String(entry.result || "")
            }
        })
    }

    function activateCalculatorItem(item) {
        if (!item)
            return
        if (item.kind === "calculatorHistory") {
            searchField.text = String(item.expression || "")
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (item.kind === "calculator")
            root.copyCalculatorResult(item.result, item.expression)
    }

    readonly property var activeWallpaperQuery: LauncherWallpaperPicker.parseQuery(
        root.normalizeRunText(searchField.text).replace(/^\s*>\s*/, "")
    )
    readonly property bool wallpaperRandomMode: root.activeWallpaperQuery.active
        && root.activeWallpaperQuery.random === true
    readonly property var activeDynamicSchemeQuery: LauncherDynamicScheme.parseQuery(
        root.normalizeRunText(searchField.text).replace(/^\s*>\s*/, "")
    )
    readonly property var activeSchemeVariantQuery: LauncherSchemeVariantPicker.parseQuery(
        root.normalizeRunText(searchField.text).replace(/^\s*>\s*/, "")
    )
    readonly property bool wallpaperPickerActive: root.normalizeRunText(searchField.text).startsWith(">")
        && root.activeWallpaperQuery.active
    readonly property bool dynamicSchemePickerActive: root.normalizeRunText(searchField.text).startsWith(">")
        && root.activeDynamicSchemeQuery.active
    readonly property bool schemeVariantPickerActive: root.normalizeRunText(searchField.text).startsWith(">")
        && root.activeSchemeVariantQuery.active

    property var wallpaperCatalogEntries: []
    property int wallpaperCatalogGeneration: 0
    property int wallpaperCatalogPendingGeneration: -1
    property bool wallpaperCatalogLoading: false
    property bool wallpaperCatalogLoaded: false
    property string wallpaperCatalogRequestedDirectory: ""
    property string wallpaperCatalogError: ""
    property string wallpaperSelectedScreenName: root.screen
        ? LauncherWallpaperPicker.screenName(root.screen, 0) : ""
    property string wallpaperApplyPendingPath: ""
    property string wallpaperApplyPendingScreenName: ""
    property int wallpaperApplyPendingScreenIndex: -1
    property string wallpaperApplyError: ""
    property bool wallpaperApplyIsRestore: false
    property string wallpaperRestoreLastError: ""
    property var wallpaperRestoreQueue: []
    property var wallpaperRestoreCurrent: null
    property var wallpaperManualPendingApply: null
    property bool wallpaperRestoreStarted: false
    property int wallpaperRestoreScreenWaitAttempts: 0

    property string dynamicSchemePendingPath: ""
    property string dynamicSchemePendingScreenName: ""
    property string dynamicSchemePendingVariant: "scheme-tonal-spot"
    property bool dynamicSchemeBusy: false
    property bool dynamicSchemeApplied: false
    property string dynamicSchemeError: ""
    property string dynamicSchemeStdout: ""
    property string dynamicSchemeStderr: ""
    property bool dynamicSchemeStdoutReady: false
    property bool dynamicSchemeStderrReady: false
    property bool dynamicSchemeProcessExited: false
    property int dynamicSchemeExitCode: -1
    property int dynamicSchemeRevision: 0
    property string dynamicSchemeNotificationBody: ""
    property string dynamicSchemeNotificationCopyPayload: ""
    property int dynamicSchemeProgressNotificationId: 0
    property string dynamicSchemeProgressNotificationOutput: ""
    property bool dynamicSchemeProgressNotificationStdoutReady: true
    property bool dynamicSchemeProgressNotificationProcessExited: true
    property bool dynamicSchemeProgressNotificationReady: true
    property string dynamicSchemeNotificationPendingUpdate: ""

    property var wallpaperPickerData: LauncherWallpaperPicker.emptyData()
    property int wallpaperPickerGeneration: 0
    property int wallpaperPickerPendingGeneration: -1
    property bool wallpaperPickerLoadPending: false
    property var wallpaperPickerPendingMutations: []
    property bool wallpaperPickerPersistAfterLoad: false
    property string wallpaperPickerWriteActivePayload: ""
    property string wallpaperPickerWriteQueuedPayload: ""
    property bool wallpaperPickerWriteHasQueuedPayload: false
    property int wallpaperPickerWriteSequence: 0
    property string wallpaperPickerFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-wallpaper-data.json"

    function wallpaperScreenIndex(name) {
        return LauncherWallpaperPicker.screenIndex(Quickshell.screens, name)
    }

    function wallpaperSelectScreen(screen, index) {
        const name = LauncherWallpaperPicker.screenName(screen, index)
        if (name)
            root.wallpaperSelectedScreenName = name
    }

    function moveWallpaperSelection(direction) {
        const next = LauncherWallpaperPicker.moveGridIndex(
            appList.currentIndex, direction, appList.wallpaperColumnCount, appList.count
        )
        if (next < 0 || next === appList.currentIndex)
            return
        appList.currentIndex = next
        appList.positionViewAtIndex(next, GridView.Contain)
    }

    function loadWallpaperCatalog(force) {
        const directory = root.expandedWallpaperDirectory()
        if (!force && root.wallpaperCatalogRequestedDirectory === directory
                && (root.wallpaperCatalogLoaded || root.wallpaperCatalogLoading))
            return
        if (wallpaperCatalogProcess.running)
            wallpaperCatalogProcess.running = false
        root.wallpaperCatalogGeneration += 1
        root.wallpaperCatalogPendingGeneration = root.wallpaperCatalogGeneration
        root.wallpaperCatalogRequestedDirectory = directory
        root.wallpaperCatalogLoading = true
        root.wallpaperCatalogLoaded = false
        root.wallpaperCatalogError = ""
        wallpaperCatalogProcess.running = true
    }

    function acceptWallpaperCatalog(output) {
        const text = String(output || "").trim()
        if (!text) {
            root.wallpaperCatalogEntries = []
            root.wallpaperCatalogError = "invalid-response"
            root.wallpaperCatalogLoaded = true
            root.wallpaperCatalogLoading = false
            return
        }
        let parsed = null
        try {
            parsed = JSON.parse(text)
        } catch (error) {
            console.warn("Launcher: wallpaper catalog returned invalid JSON:", String(error))
            root.wallpaperCatalogEntries = []
            root.wallpaperCatalogError = "invalid-response"
            root.wallpaperCatalogLoaded = true
            root.wallpaperCatalogLoading = false
            return
        }
        if (!parsed || Number(parsed.generation) !== root.wallpaperCatalogPendingGeneration)
            return
        root.wallpaperCatalogEntries = LauncherWallpaperPicker.normalizeEntries(parsed.items)
        root.wallpaperCatalogError = String(parsed.error || "")
        root.wallpaperCatalogLoaded = true
        root.wallpaperCatalogLoading = false
    }

    function applyWallpaper(path) {
        const value = String(path || "").trim()
        const screenName = String(root.wallpaperSelectedScreenName || "").trim()
        const screenIndex = root.wallpaperScreenIndex(screenName)
        if (!value)
            return
        if (screenIndex < 0) {
            root.wallpaperApplyError = "Не удалось определить выбранный монитор. Выберите экран в панели над плитками."
            return
        }

        // A new manual choice must win over a queued startup restore for the
        // same output. If a restore process is already running, queue the
        // manual choice and apply it immediately after that process exits.
        root.wallpaperRestoreQueue = root.wallpaperRestoreQueue.filter(function(item) {
            return String(item.screenName || "").toLowerCase() !== screenName.toLowerCase()
        })
        if (wallpaperApplyProcess.running) {
            if (root.wallpaperApplyIsRestore) {
                root.wallpaperManualPendingApply = {
                    path: value,
                    screenName: screenName,
                    screenIndex: screenIndex
                }
            }
            return
        }
        root.wallpaperApplyPendingPath = value
        root.wallpaperApplyPendingScreenName = screenName
        root.wallpaperApplyPendingScreenIndex = screenIndex
        root.wallpaperApplyIsRestore = false
        root.wallpaperApplyError = ""
        wallpaperApplyProcess.running = true
    }


    function applyRandomWallpaper() {
        if (root.wallpaperCatalogLoading || !root.wallpaperCatalogLoaded) {
            root.wallpaperApplyError = "Каталог обоев ещё загружается. Повторите выбор после загрузки."
            return
        }
        const candidates = LauncherWallpaperPicker.buildResults(
            root.activeWallpaperQuery.query,
            root.wallpaperCatalogEntries,
            function(searchText, normalizedSearch) {
                return root.runFuzzyScore(searchText, normalizedSearch, root.fuzzyWallpaperSearchEnabled)
            },
            LauncherWallpaperPicker.MAX_WALLPAPERS,
            root.wallpaperPickerData,
            "all",
            root.wallpaperSelectedScreenName
        )
        const selected = LauncherWallpaperPicker.chooseRandomEntry(
            candidates,
            root.wallpaperPickerData,
            root.wallpaperSelectedScreenName,
            Math.random()
        )
        if (!selected) {
            root.wallpaperApplyError = LauncherWallpaperPicker.emptyStateMessage(
                false,
                root.wallpaperCatalogError,
                root.wallpaperCatalogRequestedDirectory,
                root.wallpaperCatalogEntries.length,
                root.activeWallpaperQuery.query,
                "all",
                root.wallpaperSelectedScreenName
            )
            return
        }
        root.applyWallpaper(selected.path)
    }

    function dynamicSchemeVariantLabel(value) {
        const normalized = LauncherSchemeVariantPicker.normalizeVariant(value)
        for (let i = 0; i < LauncherSchemeVariantPicker.variants.length; ++i) {
            const item = LauncherSchemeVariantPicker.variants[i]
            if (item.id === normalized)
                return item.name
        }
        return String(value || "Matugen")
    }

    function generateDynamicScheme(path, screenName, variant) {
        const value = String(path || "").trim()
        const screen = String(screenName || root.wallpaperSelectedScreenName || "").trim()
        const selectedVariant = variant === undefined || variant === null || String(variant).trim() === ""
            ? LauncherSchemeVariantPicker.normalizeVariant(Config.launcherDynamicSchemeVariant)
            : LauncherSchemeVariantPicker.normalizeVariant(variant)
        if (!LauncherWallpaperPicker.isValidLocalImagePath(value) || !selectedVariant
                || root.dynamicSchemeBusy || dynamicSchemeProcess.running
                || dynamicSchemeProgressNotificationProcess.running)
            return
        root.dynamicSchemePendingPath = value
        root.dynamicSchemePendingScreenName = screen
        root.dynamicSchemePendingVariant = selectedVariant
        root.dynamicSchemeBusy = true
        root.dynamicSchemeApplied = false
        root.dynamicSchemeError = ""
        root.dynamicSchemeStdout = ""
        root.dynamicSchemeStderr = ""
        root.dynamicSchemeStdoutReady = false
        root.dynamicSchemeStderrReady = false
        root.dynamicSchemeProcessExited = false
        root.dynamicSchemeExitCode = -1
        root.dynamicSchemeProgressNotificationId = 0
        root.dynamicSchemeProgressNotificationOutput = ""
        root.dynamicSchemeProgressNotificationStdoutReady = false
        root.dynamicSchemeProgressNotificationProcessExited = false
        root.dynamicSchemeProgressNotificationReady = false
        root.dynamicSchemeNotificationPendingUpdate = ""
        root.dynamicSchemeRevision += 1
        dynamicSchemeProgressNotificationProcess.running = true
        dynamicSchemeProcess.running = true
    }

    function finishDynamicSchemeProgressNotificationWhenReady() {
        if (!root.dynamicSchemeProgressNotificationProcessExited
                || !root.dynamicSchemeProgressNotificationStdoutReady)
            return
        const output = String(root.dynamicSchemeProgressNotificationOutput || "").trim()
        const parsedId = parseInt(output, 10)
        root.dynamicSchemeProgressNotificationId = Number.isFinite(parsedId) && parsedId > 0 ? parsedId : 0
        root.dynamicSchemeProgressNotificationReady = true
        root.finishPendingDynamicSchemeNotificationUpdate()
    }

    function finishPendingDynamicSchemeNotificationUpdate() {
        if (!root.dynamicSchemeProgressNotificationReady || !root.dynamicSchemeNotificationPendingUpdate)
            return
        const update = root.dynamicSchemeNotificationPendingUpdate
        root.dynamicSchemeNotificationPendingUpdate = ""
        if (update === "success") {
            if (!dynamicSchemeSuccessNotificationProcess.running)
                dynamicSchemeSuccessNotificationProcess.running = true
        } else if (update === "error") {
            if (!dynamicSchemeNotificationProcess.running)
                dynamicSchemeNotificationProcess.running = true
        }
    }

    function queueDynamicSchemeNotificationUpdate(update) {
        root.dynamicSchemeNotificationPendingUpdate = String(update || "")
        // Errors raised before generation starts (for example, when no wallpaper
        // exists for the selected monitor) do not have a progress notification
        // to wait for, so they are sent immediately as ordinary notifications.
        if (!root.dynamicSchemeBusy && !dynamicSchemeProgressNotificationProcess.running
                && !root.dynamicSchemeProgressNotificationStdoutReady
                && !root.dynamicSchemeProgressNotificationProcessExited)
            root.dynamicSchemeProgressNotificationReady = true
        root.finishPendingDynamicSchemeNotificationUpdate()
    }

    function reportDynamicSchemeError(message) {
        const detail = String(message || "Неизвестная ошибка Matugen.")
            .replace(/[\u0000-\u001f\u007f]+/g, " ")
            .replace(/\s+/g, " ").trim().slice(0, 360)
        root.dynamicSchemeError = detail || "Неизвестная ошибка Matugen."
        root.dynamicSchemeNotificationBody = root.dynamicSchemePendingVariant + " · " + root.dynamicSchemeError
        root.dynamicSchemeNotificationCopyPayload = root.dynamicSchemeNotificationBody
        root.dynamicSchemeRevision += 1
        root.queueDynamicSchemeNotificationUpdate("error")
    }

    function selectDynamicSchemeVariant(variant) {
        const selectedVariant = LauncherSchemeVariantPicker.normalizeVariant(variant)
        if (!selectedVariant) return
        root.dynamicSchemePendingVariant = selectedVariant
        // Even when the variant is already active, regenerate it from the
        // selected monitor: each output has its own wallpaper history.
        const source = LauncherDynamicScheme.latestWallpaperForScreen(root.wallpaperPickerData, root.wallpaperSelectedScreenName)
        if (!source) {
            root.reportDynamicSchemeError("Сначала установите обои через >wallpaper на выбранном мониторе. Вариант пока не изменён.")
            return
        }
        root.generateDynamicScheme(source.path, source.screenName, selectedVariant)
    }

    function finishDynamicSchemeWhenReady() {
        if (root.dynamicSchemeBusy && root.dynamicSchemeProcessExited
                && root.dynamicSchemeStdoutReady && root.dynamicSchemeStderrReady)
            root.finishDynamicScheme(root.dynamicSchemeExitCode)
    }

    function finishDynamicScheme(exitCode) {
        if (!root.dynamicSchemeBusy)
            return
        root.dynamicSchemeBusy = false
        if (Number(exitCode) !== 0) {
            const detail = String(root.dynamicSchemeStderr || "").trim()
            root.reportDynamicSchemeError(detail.indexOf("MATUGEN_NOT_FOUND") >= 0
                ? "Не найден Matugen. Установите его отдельно, чтобы использовать динамические темы."
                : (detail !== "" ? detail : "Matugen завершился с кодом " + String(exitCode) + "."))
            return
        }

        const generated = LauncherDynamicScheme.buildPaletteFromMatugen(
            root.dynamicSchemeStdout,
            Settings.currentThemeColors(),
            Settings.colorNames
        )
        if (!generated.ok) {
            root.reportDynamicSchemeError(String(generated.error || "Matugen не вернул корректную палитру."))
            return
        }

        const previousVariant = LauncherSchemeVariantPicker.normalizeVariant(Config.launcherDynamicSchemeVariant)
        Config.launcherDynamicSchemeVariant = root.dynamicSchemePendingVariant
        if (!Settings.applyGeneratedTheme(LauncherDynamicScheme.GENERATED_THEME_NAME, generated.palette)) {
            Config.launcherDynamicSchemeVariant = previousVariant || LauncherSchemeVariantPicker.DEFAULT_VARIANT
            root.reportDynamicSchemeError("Не удалось сохранить динамическую тему. Проверьте цветовую палитру.")
            return
        }
        root.dynamicSchemeApplied = true
        root.dynamicSchemeError = ""
        root.dynamicSchemeNotificationBody = LauncherDynamicScheme.GENERATED_THEME_NAME
            + " · " + root.dynamicSchemeVariantLabel(root.dynamicSchemePendingVariant)
        root.dynamicSchemeRevision += 1
        root.queueDynamicSchemeNotificationUpdate("success")
        root.hideLauncher()
    }

    function setWallpaperScope(scope) {
        const value = String(scope || "all")
        searchField.text = value === "favorites" ? ">wallpaper favorites"
            : (value === "recent" ? ">wallpaper recent" : ">wallpaper")
        searchField.cursorPosition = searchField.text.length
        searchField.forceActiveFocus()
    }

    function recordWallpaperPickerMutation(type, path, screenName, timestamp) {
        root.wallpaperPickerGeneration += 1
        if (!root.wallpaperPickerLoadPending)
            return
        const mutations = Array.isArray(root.wallpaperPickerPendingMutations)
            ? root.wallpaperPickerPendingMutations.slice() : []
        mutations.push({
            type: String(type),
            path: String(path === undefined || path === null ? "" : path),
            screenName: String(screenName === undefined || screenName === null ? "" : screenName),
            timestamp: Number(timestamp) || 0
        })
        root.wallpaperPickerPendingMutations = mutations
    }

    function acceptWallpaperPickerData(output) {
        const text = String(output ?? "")
        const marker = "\n__LAUNCHER_WALLPAPER_DATA_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0)
            return
        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration)
                || requestGeneration !== root.wallpaperPickerPendingGeneration
                || !root.wallpaperPickerLoadPending)
            return
        const diskData = LauncherWallpaperPicker.parseData(text.slice(0, markerIndex))
        const mutations = Array.isArray(root.wallpaperPickerPendingMutations)
            ? root.wallpaperPickerPendingMutations.slice() : []
        const mergedData = LauncherWallpaperPicker.applyMutations(diskData, mutations)
        const shouldPersist = mutations.length > 0 || root.wallpaperPickerPersistAfterLoad
        root.wallpaperPickerData = mergedData
        root.wallpaperPickerLoadPending = false
        root.wallpaperPickerPendingMutations = []
        root.wallpaperPickerPersistAfterLoad = false
        if (shouldPersist)
            root.persistWallpaperPickerData()
        root.scheduleWallpaperRestore()
    }

    function loadWallpaperPickerDataFromDisk() {
        if (wallpaperPickerReadProcess.running)
            wallpaperPickerReadProcess.running = false
        root.wallpaperPickerGeneration += 1
        root.wallpaperPickerPendingGeneration = root.wallpaperPickerGeneration
        root.wallpaperPickerLoadPending = true
        root.wallpaperPickerPendingMutations = []
        wallpaperPickerReadProcess.running = true
    }

    function startWallpaperPickerWrite(payload) {
        root.wallpaperPickerWriteActivePayload = String(payload ?? "")
        root.wallpaperPickerWriteSequence += 1
        wallpaperPickerWriteProcess.running = true
    }

    function finishWallpaperPickerWrite(exitCode) {
        if (exitCode !== 0)
            console.warn("Launcher: failed to persist Wallpaper picker data (exit code", exitCode, ")")
        if (!root.wallpaperPickerWriteHasQueuedPayload)
            return
        const latestPayload = root.wallpaperPickerWriteQueuedPayload
        root.wallpaperPickerWriteQueuedPayload = ""
        root.wallpaperPickerWriteHasQueuedPayload = false
        root.startWallpaperPickerWrite(latestPayload)
    }

    function persistWallpaperPickerData() {
        if (root.wallpaperPickerLoadPending) {
            root.wallpaperPickerPersistAfterLoad = true
            return
        }
        const data = LauncherWallpaperPicker.serializeData(root.wallpaperPickerData)
        if (wallpaperPickerWriteProcess.running) {
            root.wallpaperPickerWriteQueuedPayload = data
            root.wallpaperPickerWriteHasQueuedPayload = true
            return
        }
        root.wallpaperPickerWriteQueuedPayload = ""
        root.wallpaperPickerWriteHasQueuedPayload = false
        root.startWallpaperPickerWrite(data)
    }

    function toggleWallpaperFavorite(path) {
        const value = String(path === undefined || path === null ? "" : path).trim()
        if (!value)
            return
        root.recordWallpaperPickerMutation("toggleFavorite", value, "", 0)
        root.wallpaperPickerData = LauncherWallpaperPicker.toggleFavorite(root.wallpaperPickerData, value)
        root.persistWallpaperPickerData()
    }

    function rememberWallpaperUsage(path, screenName) {
        const value = String(path === undefined || path === null ? "" : path).trim()
        const screen = String(screenName === undefined || screenName === null ? "" : screenName).trim()
        if (!value || !screen)
            return
        const timestamp = Date.now()
        root.recordWallpaperPickerMutation("recordSuccessfulApply", value, screen, timestamp)
        root.wallpaperPickerData = LauncherWallpaperPicker.recordSuccessfulApply(
            root.wallpaperPickerData, value, screen, timestamp
        )
        root.persistWallpaperPickerData()
    }

    function scheduleWallpaperRestore() {
        if (root.wallpaperRestoreStarted || root.wallpaperPickerLoadPending)
            return
        root.wallpaperRestoreStarted = true
        root.wallpaperRestoreQueue = LauncherWallpaperPicker.appliedWallpapers(root.wallpaperPickerData).map(function(item) {
            return { path: item.path, screenName: item.screenName, attempt: 0 }
        })
        root.wallpaperRestoreScreenWaitAttempts = 0
        if (root.wallpaperRestoreQueue.length > 0)
            wallpaperRestoreTimer.start()
    }

    function restoreNextWallpaper() {
        if (root.wallpaperPickerLoadPending)
            return
        if (wallpaperApplyProcess.running) {
            wallpaperRestoreTimer.restart()
            return
        }
        if (!root.wallpaperRestoreQueue.length)
            return
        if (!Quickshell.screens || Quickshell.screens.length === 0) {
            root.wallpaperRestoreScreenWaitAttempts += 1
            if (root.wallpaperRestoreScreenWaitAttempts <= 12)
                wallpaperRestoreTimer.restart()
            else
                console.warn("Launcher: wallpaper restore skipped because no screens became available")
            return
        }
        root.wallpaperRestoreScreenWaitAttempts = 0

        const queue = root.wallpaperRestoreQueue.slice()
        let selected = null
        let selectedIndex = -1
        while (queue.length > 0 && !selected) {
            const candidate = queue.shift()
            const index = root.wallpaperScreenIndex(candidate.screenName)
            if (index < 0)
                continue
            selected = candidate
            selectedIndex = index
        }
        root.wallpaperRestoreQueue = queue
        if (!selected)
            return

        root.wallpaperRestoreCurrent = selected
        root.wallpaperApplyPendingPath = selected.path
        root.wallpaperApplyPendingScreenName = selected.screenName
        root.wallpaperApplyPendingScreenIndex = selectedIndex
        root.wallpaperApplyIsRestore = true
        root.wallpaperRestoreLastError = ""
        wallpaperApplyProcess.running = true
    }

    function finishWallpaperRestore(exitCode) {
        const current = root.wallpaperRestoreCurrent
        root.wallpaperApplyIsRestore = false
        root.wallpaperRestoreCurrent = null
        if (Number(exitCode) !== 0) {
            const detail = String(root.wallpaperRestoreLastError || "").trim()
            const attempts = Math.max(0, Math.floor(Number(current && current.attempt) || 0))
            if (attempts < 2 && detail.indexOf("image file not found or unreadable") < 0) {
                const retry = {
                    path: String(current && current.path || ""),
                    screenName: String(current && current.screenName || ""),
                    attempt: attempts + 1
                }
                if (retry.path && retry.screenName)
                    root.wallpaperRestoreQueue = root.wallpaperRestoreQueue.concat([retry])
            } else {
                console.warn("Launcher: could not restore wallpaper for", String(current && current.screenName || "unknown screen"), detail)
            }
        }
        root.wallpaperRestoreLastError = ""

        const manual = root.wallpaperManualPendingApply
        if (manual && manual.path && manual.screenName && Number(manual.screenIndex) >= 0) {
            root.wallpaperManualPendingApply = null
            root.wallpaperApplyPendingPath = String(manual.path)
            root.wallpaperApplyPendingScreenName = String(manual.screenName)
            root.wallpaperApplyPendingScreenIndex = Number(manual.screenIndex)
            root.wallpaperApplyError = ""
            root.wallpaperApplyIsRestore = false
            wallpaperApplyProcess.running = true
            return
        }

        if (root.wallpaperRestoreQueue.length) {
            wallpaperRestoreTimer.interval = Number(exitCode) === 0 ? 250 : 1800
            wallpaperRestoreTimer.restart()
        }
    }

    property var appsUnifiedResults: {
        // Keep launcher results reactive to wallpaper preference/catalog changes
        // as well as screen selection while the Wallpaper picker is open.
        const wallpaperData = root.wallpaperPickerData
        const wallpaperEntries = root.wallpaperCatalogEntries
        const wallpaperScreen = root.wallpaperSelectedScreenName
        const wallpaperScope = root.activeWallpaperQuery.scope
        const dynamicSchemeState = root.dynamicSchemeRevision
        const dynamicSchemeScreen = root.wallpaperSelectedScreenName
        const dynamicSchemeVariant = Config.launcherDynamicSchemeVariant
        return root.buildAppsUnifiedResults(
            appModel.applications, root.fuzzyCustomActionsEnabled, appModel.availableCategories,
            root.fuzzySchemeSearchEnabled, root.fuzzyWallpaperSearchEnabled
        )
    }

    // The `>` prefix exposes built-in Launcher navigation and tools without
    // adding another tab. Saved user commands are handled separately by `:`.
    function launcherActionAliases(mode) {
        switch (mode) {
        case root.modeApps:
            return ["app", "apps", "application", "applications", "приложение", "приложения", "поиск приложений"]
        case root.modeRun:
            return ["run", "command", "commands", "shell", "execute", "команда", "команды", "командная строка", "выполнить", "запуск"]
        case root.modeWindows:
            return ["window", "windows", "switch", "переключить", "переключение окон", "открытые окна", "окна"]
        case root.modeClipboard:
            return ["clip", "clipboard", "history", "paste", "буфер", "буфер обмена", "история буфера", "вставка"]
        case root.modePower:
            return ["power", "session", "logout", "shutdown", "reboot", "restart", "sleep", "питание", "выход", "выключение", "перезагрузка", "сон"]
        case root.modeNetwork:
            return ["network", "networks", "wifi", "wireless", "internet", "connection", "подключение", "подключения", "интернет", "сеть", "сети"]
        case root.modeNix:
            return ["package", "packages", "nix", "nixpkgs", "install", "search packages", "пакет", "пакеты", "поиск пакетов", "установка пакетов"]
        case root.modePass:
            return ["pass", "password", "passwords", "password-store", "secret", "secrets", "пароль", "пароли", "менеджер паролей", "секреты"]
        case root.modeProjects:
            return ["project", "projects", "workspace", "repository", "repositories", "проект", "проекты", "рабочая папка", "репозиторий", "репозитории"]
        case root.modeCalculator:
            return ["calculator", "calc", "math", "calculate", "expression", "вычислить", "вычисления", "математика", "калькулятор"]
        default: return []
        }
    }

    function launcherActionDescription(mode) {
        switch (mode) {
        case root.modeApps: return "Запуск установленных приложений и поиск по названию или метаданным"
        case root.modeRun: return "Выполнение shell-команд и повторный запуск сохранённых команд"
        case root.modeWindows: return "Поиск открытых окон и переключение между ними"
        case root.modeClipboard: return "История буфера обмена: поиск и повторная вставка элементов"
        case root.modePower: return "Управление сеансом: выход, сон, перезагрузка и выключение"
        case root.modeNetwork: return "Просмотр Wi-Fi и управление сетевыми подключениями"
        case root.modeNix: return "Поиск пакетов Nix и доступные действия с пакетами"
        case root.modePass: return "Поиск записей password-store и работа с сохранёнными паролями"
        case root.modeProjects: return "Открытие настроенных проектов и рабочих папок"
        case root.modeCalculator: return "Вычисление выражений со скобками, степенями и унарными знаками"
        default: return "Открыть раздел лаунчера"
        }
    }

    function builtinActionEnabled(actionId) {
        return LauncherBuiltinActions.isEnabled(Config.launcherDisabledBuiltinActions, actionId)
    }

    function builtinActionIdForMode(mode) {
        switch (mode) {
        case root.modeApps: return "tab.apps"
        case root.modeRun: return "tab.run"
        case root.modeWindows: return "tab.windows"
        case root.modeClipboard: return "tab.clipboard"
        case root.modePower: return "tab.power"
        case root.modeNetwork: return "tab.network"
        case root.modeNix: return "tab.packages"
        case root.modePass: return "tab.pass"
        case root.modeProjects: return "tab.projects"
        case root.modeCalculator: return "tab.calculator"
        default: return ""
        }
    }

    readonly property bool fuzzyCustomActionsEnabled: Config.launcherFuzzySearchActions !== false
    readonly property bool fuzzySchemeSearchEnabled: Config.launcherFuzzySearchSchemes !== false
    readonly property bool fuzzyWallpaperSearchEnabled: Config.launcherFuzzySearchWallpapers !== false

    function buildCustomActionResults(query, orderOffset, includeEmptyQuery, fuzzyEnabled) {
        return LauncherCustomActions.buildResults(
            Config.launcherCustomActions,
            query,
            function(searchText, normalizedQuery) {
                return LauncherSearchScoring.fuzzyScore(
                    searchText, normalizedQuery, fuzzyEnabled !== false
                )
            },
            orderOffset,
            includeEmptyQuery
        )
    }

    function buildLauncherActionResults(query, fuzzyActionsEnabled, fuzzySchemesEnabled, fuzzyWallpapersEnabled) {
        const normalizedQuery = root.normalizeRunText(query)
        const fuzzySchemes = fuzzySchemesEnabled !== false
        const fuzzyWallpapers = fuzzyWallpapersEnabled !== false
        const variantQuery = LauncherSchemeVariantPicker.parseQuery(normalizedQuery)
        if (variantQuery.active) {
            if (!root.builtinActionEnabled("tool.schemeVariants")) return []
            if (root.dynamicSchemeBusy)
                return []
            return LauncherSchemeVariantPicker.buildResults(
                variantQuery.query,
                Config.launcherDynamicSchemeVariant,
                function(searchText, normalizedSearch) {
                    return LauncherSearchScoring.fuzzyScore(searchText, normalizedSearch, fuzzySchemes)
                },
                100
            )
        }

        const dynamicSchemeQuery = LauncherDynamicScheme.parseQuery(normalizedQuery)
        if (dynamicSchemeQuery.active) {
            if (!root.builtinActionEnabled("tool.wallpaperDynamic")) return []
            return LauncherDynamicScheme.buildResults(
                root.wallpaperPickerData,
                root.wallpaperSelectedScreenName,
                root.dynamicSchemeBusy,
                root.dynamicSchemeError,
                dynamicSchemeQuery.query,
                function(searchText, normalizedSearch) {
                    return LauncherSearchScoring.fuzzyScore(searchText, normalizedSearch, fuzzySchemes)
                }
            )
        }

        const schemeQuery = LauncherSchemePicker.parseQuery(normalizedQuery)
        if (schemeQuery.active) {
            const schemeResults = root.builtinActionEnabled("tool.colorSchemes")
                ? LauncherSchemePicker.buildResults(
                    schemeQuery.query,
                    Settings.themeNames,
                    Settings.activeTheme,
                    function(name) { return Settings.themePreview(name) },
                    function(name) { return Settings.themeDescription(name) },
                    function(searchText, normalizedSearch) {
                        return LauncherSearchScoring.fuzzyScore(searchText, normalizedSearch, fuzzySchemes)
                    },
                    200
                ) : []
            const dynamicScore = root.builtinActionEnabled("tool.wallpaperDynamic")
                ? (schemeQuery.query === "" ? 0
                    : LauncherSearchScoring.fuzzyScore("dynamic wallpaper wallpaper-derived material palette обои динамическая динамика палитра из обоев", schemeQuery.query, fuzzySchemes))
                : -1
            if (dynamicScore >= 0) {
                schemeResults.push({
                    kind: "dynamicSchemeAction",
                    name: "Wallpaper Dynamic",
                    description: "Создать палитру из последних обоев выбранного монитора · >scheme dynamic",
                    score: dynamicScore,
                    order: 100000
                })
            }
            return schemeResults
        }
        const wallpaperQuery = LauncherWallpaperPicker.parseQuery(normalizedQuery)
        if (wallpaperQuery.active) {
            if (!root.builtinActionEnabled("tool.wallpapers")) return []
            if (wallpaperQuery.random) {
                const candidates = LauncherWallpaperPicker.buildResults(
                    wallpaperQuery.query,
                    root.wallpaperCatalogEntries,
                    function(searchText, normalizedSearch) {
                        return LauncherSearchScoring.fuzzyScore(searchText, normalizedSearch, fuzzyWallpapers)
                    },
                    LauncherWallpaperPicker.MAX_WALLPAPERS,
                    root.wallpaperPickerData,
                    "all",
                    root.wallpaperSelectedScreenName
                )
                let description = "Случайно выбрать обои для " + root.wallpaperSelectedScreenName
                if (root.wallpaperCatalogLoading || !root.wallpaperCatalogLoaded)
                    description = "Загрузка каталога обоев…"
                else if (candidates.length > 0)
                    description = "Случайный выбор из " + String(candidates.length) + " изображений · " + root.wallpaperSelectedScreenName
                else
                    description = LauncherWallpaperPicker.emptyStateMessage(
                        false,
                        root.wallpaperCatalogError,
                        root.wallpaperCatalogRequestedDirectory,
                        root.wallpaperCatalogEntries.length,
                        wallpaperQuery.query,
                        "all",
                        root.wallpaperSelectedScreenName
                    )
                return [{
                    kind: "wallpaperRandomAction",
                    name: "Случайные обои",
                    icon: "",
                    description: description,
                    available: !root.wallpaperCatalogLoading && root.wallpaperCatalogLoaded && candidates.length > 0,
                    score: 0,
                    order: -1
                }]
            }
            return LauncherWallpaperPicker.buildResults(
                wallpaperQuery.query,
                root.wallpaperCatalogEntries,
                function(searchText, normalizedSearch) {
                    return LauncherSearchScoring.fuzzyScore(searchText, normalizedSearch, fuzzyWallpapers)
                },
                200,
                root.wallpaperPickerData,
                wallpaperQuery.scope,
                root.wallpaperSelectedScreenName
            )
        }
        const emojiQuery = LauncherEmojiPicker.parseQuery(normalizedQuery)
        if (emojiQuery.active) {
            if (!root.builtinActionEnabled("tool.emoji")) return []
            return LauncherEmojiPicker.buildResults(
                emojiQuery.query,
                function(searchText, normalizedSearch) {
                    return root.runFuzzyScore(searchText, normalizedSearch)
                },
                200,
                root.emojiPickerData,
                emojiQuery.scope
            )
        }

        const results = []
        const dashboardActionScore = Settings.dashboard && root.builtinActionEnabled("tool.dashboard")
            ? (normalizedQuery === "" ? 0
                : root.runFuzzyScore("dashboard overview overview-panel system dashboard panel summary обзор обзорная панель сводка панель системы", normalizedQuery))
            : -1
        if (dashboardActionScore >= 0) {
            results.push({
                kind: "dashboardAction",
                name: "Dashboard",
                icon: "󰕮",
                description: "Открыть обзор системы · >dashboard",
                score: dashboardActionScore,
                order: -4
            })
        }
        const schemeActionScore = root.builtinActionEnabled("tool.colorSchemes")
            ? (normalizedQuery === "" ? 0
                : root.runFuzzyScore("scheme schemes theme themes color-scheme colour-scheme palette colors цвета тема темы палитра оформление", normalizedQuery))
            : -1
        if (schemeActionScore >= 0) {
            results.push({
                kind: "schemePickerAction",
                name: "Color schemes",
                icon: "󰏘",
                description: "Предпросмотр и выбор цветовой темы · >scheme",
                score: schemeActionScore,
                order: -3
            })
        }
        const variantActionScore = root.builtinActionEnabled("tool.schemeVariants")
            ? (normalizedQuery === "" ? 0
                : root.runFuzzyScore("variant variants scheme-variant scheme-variants material you type style варианты вариант стиль стили тип палитры", normalizedQuery))
            : -1
        if (variantActionScore >= 0) {
            results.push({
                kind: "schemeVariantPickerAction",
                name: "Scheme variants",
                icon: "󰏘",
                description: "Выбор алгоритма Material You для Wallpaper Dynamic · >scheme variants",
                score: variantActionScore,
                order: -2
            })
        }
        const wallpaperActionScore = root.builtinActionEnabled("tool.wallpapers")
            ? (normalizedQuery === "" ? 0
                : root.runFuzzyScore("wallpaper wallpapers обои фон", normalizedQuery))
            : -1
        if (wallpaperActionScore >= 0) {
            results.push({
                kind: "wallpaperPickerAction",
                name: "Wallpaper picker",
                icon: "󰸉",
                description: "Просмотр и установка обоев · >wallpaper",
                score: wallpaperActionScore,
                order: -1
            })
        }
        const emojiActionScore = root.builtinActionEnabled("tool.emoji")
            ? (normalizedQuery === "" ? 0
                : root.runFuzzyScore("emoji picker emoticons смайлы эмодзи", normalizedQuery))
            : -1
        if (emojiActionScore >= 0) {
            results.push({
                kind: "emojiPickerAction",
                name: "Emoji picker",
                icon: "😀",
                description: "Поиск и копирование эмодзи · >emoji",
                score: emojiActionScore,
                order: 0
            })
        }

        const tabs = root.displayedModeTabs
        for (let i = 0; i < tabs.length; ++i) {
            const tab = tabs[i]
            // Resolve a stable ID from the mode; displayed tab labels are editable.
            if (!root.builtinActionEnabled(root.builtinActionIdForMode(tab.mode))) continue
            const aliases = root.launcherActionAliases(tab.mode)
            const searchTerms = [tab.label].concat(aliases)
            let score = normalizedQuery === "" ? 0 : -1
            for (let j = 0; j < searchTerms.length; ++j) {
                score = Math.max(score, normalizedQuery === "" ? 0 : root.runFuzzyScore(searchTerms[j], normalizedQuery))
            }
            if (score < 0) continue
            results.push({
                kind: "action",
                actionId: tab.id,
                targetMode: tab.mode,
                name: tab.label,
                icon: tab.icon,
                description: root.launcherActionDescription(tab.mode),
                score: score,
                order: i
            })
        }

        // Saved user actions have their own `:` prefix and stay separate from
        // this built-in `>` navigation palette.
        results.sort(function(a, b) {
            if (b.score !== a.score) return b.score - a.score
            return a.order - b.order
        })
        return results
    }

    function russianApplicationCount(value) {
        const count = Math.max(0, Math.floor(Number(value) || 0))
        const tail = count % 100
        const last = count % 10
        let noun = "приложений"
        if (tail < 11 || tail > 14) {
            if (last === 1) noun = "приложение"
            else if (last >= 2 && last <= 4) noun = "приложения"
        }
        return count + " " + noun
    }

    function appsResultName(itemData, entry) {
        if (!itemData) return String(entry && entry.name || "")
        switch (String(itemData.kind || "")) {
        case "appCategory": return String(itemData.categoryLabel || itemData.category || "")
        case "emoji": return String(itemData.name || "")
        case "dashboardAction": return String(itemData.name || "Dashboard")
        case "emojiPickerAction": return String(itemData.name || "Emoji picker")
        case "schemePickerAction": return String(itemData.name || "Color schemes")
        case "schemeVariantPickerAction": return String(itemData.name || "Scheme variants")
        case "schemeVariant": return String(itemData.name || "")
        case "scheme": return String(itemData.name || "")
        case "dynamicSchemeAction": return String(itemData.name || "Wallpaper Dynamic")
        case "dynamicSchemeGenerate": return String(itemData.name || "Create wallpaper theme")
        case "dynamicSchemeUnavailable": return String(itemData.name || "Wallpaper unavailable")
        case "dynamicSchemeError": return String(itemData.name || "Dynamic theme error")
        case "dynamicSchemeWallpaperAction": return String(itemData.name || "Open wallpaper picker")
        case "wallpaperPickerAction": return String(itemData.name || "Wallpaper picker")
        case "wallpaperRandomAction": return String(itemData.name || "Случайные обои")
        case "wallpaper": return String(itemData.name || "")
        case "action":
        case "customAction": return String(itemData.name || "")
        case "project": return String(itemData.project && itemData.project.name || "")
        case "run": return String(itemData.command || "")
        case "calculator": return String(itemData.expression || "") + " = " + String(itemData.result || "")
        default: return String(entry && entry.name || "")
        }
    }

    function appsResultSubtitle(itemData, entry) {
        if (!itemData)
            return String(entry && (entry.genericName || entry.comment) || "")
        switch (String(itemData.kind || "")) {
        case "appCategory":
            return root.russianApplicationCount(itemData.count) + " · нажмите Enter, чтобы открыть категорию"
        case "dashboardAction":
            return "ОБЗОР · Быстрая сводка системы · >dashboard"
        case "action":
            return "ДЕЙСТВИЕ · " + String(itemData.description || "")
        case "customAction":
            return "КОМАНДА · " + (String(itemData.description || "").trim() !== ""
                ? String(itemData.description) + " · " + String(itemData.command || "")
                : String(itemData.command || ""))
        case "project":
            return "ПРОЕКТ · " + String(itemData.project && itemData.project.path || "")
        case "run":
            return "КОМАНДА · сохранённая"
        case "calculator":
            return "КАЛЬКУЛЯТОР · нажмите Enter, чтобы скопировать"
        case "emoji":
            if (itemData.isFavorite)
                return "Избранное · " + String(itemData.category || "Эмодзи") + " · звезда справа — убрать"
            if (Number(itemData.usageCount) > 0)
                return "Использовано: " + String(itemData.usageCount) + " · " + String(itemData.category || "Эмодзи") + " · звезда справа — в избранное"
            return String(itemData.category || "Эмодзи") + " · Enter или клик — скопировать · звезда справа — в избранное"
        case "emojiPickerAction":
            return "Встроенный каталог эмодзи · >emoji"
        case "schemePickerAction":
            return "Встроенные и пользовательские темы · >scheme"
        case "schemeVariantPickerAction":
            return "Алгоритмы Material You для динамической темы · >scheme variants"
        case "schemeVariant":
            return itemData.isActive ? "Текущий вариант · " + String(itemData.description || "") : "Применить к последним обоям выбранного монитора · " + String(itemData.description || "")
        case "dynamicSchemeAction":
            return "Палитра из последних обоев на выбранном мониторе · Matugen · >scheme dynamic"
        case "dynamicSchemeGenerate":
            return String(itemData.description || "Создать динамическую палитру из выбранных обоев")
        case "dynamicSchemeUnavailable":
        case "dynamicSchemeError":
        case "dynamicSchemeWallpaperAction":
            return String(itemData.description || "")
        case "scheme":
            return itemData.isActive
                ? "Текущая тема · " + String(itemData.description || "")
                : "Выбрать цветовую тему · " + String(itemData.description || "")
        case "wallpaperPickerAction":
            return "Карусель локальных изображений · >wallpaper"
        case "wallpaperRandomAction":
            return "ОБОИ · " + String(itemData.description || "Случайный выбор") + " · Enter — установить"
        case "wallpaper": {
            const labels = []
            if (itemData.isFavorite) labels.push("★ Избранное")
            if (Number(itemData.usageCount) > 0)
                labels.push("На " + String(itemData.recentScreenName || "этом экране") + ": " + String(itemData.usageCount) + " раз")
            labels.push("Enter или клик — установить")
            return labels.join(" · ")
        }
        default:
            return String(entry && (entry.genericName || entry.comment) || "")
        }
    }

    function buildAppsUnifiedResults(applicationEntries, fuzzyActionsEnabled, availableCategories, fuzzySchemesEnabled, fuzzyWallpapersEnabled) {
        const rawQuery = root.normalizeRunText(searchField.text)
        const customActionQuery = LauncherCustomActions.parseQuery(rawQuery)
        if (customActionQuery.active)
            return root.buildCustomActionResults(
                customActionQuery.query, 0, true, fuzzyActionsEnabled
            )
        if (rawQuery.startsWith(">"))
            return root.buildLauncherActionResults(
                rawQuery.slice(1).trim(), fuzzyActionsEnabled, fuzzySchemesEnabled, fuzzyWallpapersEnabled
            )

        const query = rawQuery
        const results = []
        const applications = applicationEntries || []

        // A bare `@c` opens a category browser. Selecting a category converts
        // it into the existing metadata search (`@c Category`), so app search
        // keeps using the same matching, favorite and hidden-app rules.
        if (appModel.specialSearch && appModel.specialSearch.code === "c"
                && appModel.specialSearch.query === "") {
            const categories = Array.isArray(availableCategories) ? availableCategories : []
            return categories.map(function(category, index) {
                return {
                    kind: "appCategory",
                    category: String(category.name || ""),
                    categoryLabel: String(category.label || category.name || ""),
                    count: Math.max(0, Number(category.count) || 0),
                    order: index
                }
            })
        }

        // AppModel returns ranked wrappers ({ entry, score/rank }). Keep its
        // actual DesktopEntry object for activation and preserve its rank.
        for (let i = 0; i < applications.length; ++i) {
            const application = applications[i]
            const appEntry = application && application.entry
                ? application.entry
                : application
            results.push({
                kind: "app",
                entry: appEntry,
                score: query === "" ? 0 : (
                    application && Number.isFinite(application.score)
                        ? application.score
                        : appModel.scoreEntry(appEntry)
                ),
                order: i
            })
        }

        // Special @ selectors are deliberately app-only. Do not mix in
        // calculator, project, saved-command or user-action cross-search hits.
        if (appModel.specialSearch)
            return results

        if (query === "")
            return results

        if (Config.launcherCrossSearchCalculator !== false && Calculator.hasOperators(query)) {
            const calculation = Calculator.evaluate(query)
            if (calculation) {
                results.push({
                    kind: "calculator",
                    expression: calculation.expression,
                    result: calculation.text,
                    value: calculation.value,
                    score: 1000000000,
                    order: -1
                })
            }
        }

        if (Config.launcherCrossSearchProjects !== false) {
            const projects = Array.isArray(Config.launcherProjects) ? Config.launcherProjects : []
            const matches = []
            for (let i = 0; i < projects.length; ++i) {
                const project = projects[i]
                if (!project || typeof project !== "object") continue
                const searchText = [project.name, project.path, project.ide, project.icon].join(" ")
                const score = root.runFuzzyScore(searchText, query)
                if (score >= 0) {
                    matches.push({
                        kind: "project",
                        project: {
                            icon: String(project.icon || ""),
                            name: String(project.name || ""),
                            path: String(project.path || ""),
                            ide: String(project.ide || "")
                        },
                        score: score,
                        order: i
                    })
                }
            }
            matches.sort(function(a, b) {
                if (b.score !== a.score) return b.score - a.score
                return a.order - b.order
            })
            for (let i = 0; i < matches.length; ++i) results.push(matches[i])
        }

        if (Config.launcherCrossSearchRunHistory !== false) {
            const commands = Array.isArray(root.runHistoryEntries) ? root.runHistoryEntries : []
            const matches = []
            const seen = ({})
            for (let i = 0; i < commands.length; ++i) {
                const command = String(commands[i] || "").trim()
                if (!command || seen[command]) continue
                const score = root.runFuzzyScore(command, query)
                if (score >= 0) {
                    matches.push({ kind: "run", command: command, score: score, order: i })
                    seen[command] = true
                }
            }
            matches.sort(function(a, b) {
                if (b.score !== a.score) return b.score - a.score
                return a.order - b.order
            })
            for (let i = 0; i < matches.length; ++i) results.push(matches[i])
        }

        // Named user actions also participate in ordinary Apps search, so users
        // can find saved aliases without remembering the > command-palette prefix.
        const customActionResults = root.buildCustomActionResults(
            query, results.length, false, fuzzyActionsEnabled
        )
        for (let i = 0; i < customActionResults.length; ++i)
            results.push(customActionResults[i])

        if (query !== "") {
            // Rank all result types together. AppModel's relative order is
            // preserved for equal-ranked app entries; a project/command can
            // only rise above an app when its own match is more relevant.
            const kindRank = { calculator: 0, app: 1, customAction: 2, project: 3, run: 4 }
            results.sort(function(a, b) {
                if (b.score !== a.score) return b.score - a.score
                if (a.kind === "app" && b.kind === "app") return a.order - b.order
                if (a.kind !== b.kind) return kindRank[a.kind] - kindRank[b.kind]
                return a.order - b.order
            })
        }
        return results
    }

    function activateAppsSearchResult(result) {
        if (!result) return
        if (result.kind === "dashboardAction") {
            root.hideLauncher()
            root.dashboardRequested()
            return
        }
        if (result.kind === "appCategory") {
            const category = String(result.category || "").trim()
            if (!category) return
            searchField.text = "@c " + category
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "emojiPickerAction") {
            searchField.text = ">emoji"
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "schemePickerAction") {
            searchField.text = ">scheme"
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "schemeVariantPickerAction") {
            root.dynamicSchemeError = ""
            searchField.text = ">scheme variants"
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "schemeVariant") {
            root.selectDynamicSchemeVariant(result.variant)
            return
        }
        if (result.kind === "dynamicSchemeAction") {
            root.dynamicSchemeError = ""
            searchField.text = ">scheme dynamic"
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "dynamicSchemeGenerate") {
            root.generateDynamicScheme(result.path, result.screenName)
            return
        }
        if (result.kind === "dynamicSchemeWallpaperAction") {
            searchField.text = ">wallpaper"
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "scheme") {
            const selectedName = String(result.name || "")
            if (!selectedName || !Array.isArray(Settings.themeNames)
                    || Settings.themeNames.indexOf(selectedName) < 0)
                return
            if (selectedName !== String(Settings.activeTheme || ""))
                Settings.applyTheme(selectedName)
            root.hideLauncher()
            return
        }
        if (result.kind === "wallpaperPickerAction") {
            root.wallpaperApplyError = ""
            searchField.text = ">wallpaper"
            searchField.cursorPosition = searchField.text.length
            searchField.forceActiveFocus()
            return
        }
        if (result.kind === "wallpaperRandomAction") {
            if (result.available === true)
                root.applyRandomWallpaper()
            else if (!root.wallpaperCatalogLoading && root.wallpaperCatalogLoaded)
                root.wallpaperApplyError = String(result.description || "Нет доступных обоев для случайного выбора.")
            return
        }
        if (result.kind === "wallpaper") {
            root.applyWallpaper(result.path)
            return
        }
        if (result.kind === "action") {
            searchField.text = ""
            root.setMode(result.targetMode)
            Qt.callLater(root.restoreLauncherKeyboardFocus)
            return
        }
        if (result.kind === "customAction") {
            root.runCommand(result.command)
            return
        }
        if (result.kind === "app") {
            root.launchEntry(result.entry)
            return
        }
        if (result.kind === "project") {
            root.launchProject(result.project)
            return
        }
        if (result.kind === "run") {
            root.runCommand(result.command)
            return
        }
        if (result.kind === "calculator") {
            root.copyCalculatorResult(result.result, result.expression)
            return
        }
        if (result.kind === "emoji")
            root.copyLauncherEmoji(result.emoji)
    }

    Timer {
        id: wallpaperRestoreTimer
        interval: 1200
        repeat: false
        onTriggered: root.restoreNextWallpaper()
    }

    Process {
        id: wallpaperCatalogProcess
        command: [
            Quickshell.shellDir + "/scripts/launcher_wallpapers",
            root.wallpaperCatalogRequestedDirectory,
            String(root.wallpaperCatalogPendingGeneration)
        ]
        stdout: StdioCollector {
            onStreamFinished: root.acceptWallpaperCatalog(this.text)
        }
        onExited: function(exitCode) {
            if (exitCode !== 0 && root.wallpaperCatalogLoading) {
                root.wallpaperCatalogError = "catalog-process-failed"
                root.wallpaperCatalogLoading = false
                root.wallpaperCatalogLoaded = true
            }
        }
    }

    Process {
        id: wallpaperPickerReadProcess
        command: [
            "sh",
            "-c",
            "cat -- \"$1\" 2>/dev/null; printf '\\n__LAUNCHER_WALLPAPER_DATA_REQUEST__%s\\n' \"$2\"",
            "launcher-wallpaper-data-read",
            root.wallpaperPickerFile,
            String(root.wallpaperPickerPendingGeneration)
        ]
        stdout: StdioCollector {
            onStreamFinished: root.acceptWallpaperPickerData(this.text)
        }
    }

    Process {
        id: wallpaperPickerWriteProcess
        command: [
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && tmp=\"$1.tmp.$$.$3\" && printf '%s\\n' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
            "launcher-wallpaper-data-write",
            root.wallpaperPickerFile,
            root.wallpaperPickerWriteActivePayload,
            String(root.wallpaperPickerWriteSequence)
        ]
        onExited: function(exitCode) {
            root.finishWallpaperPickerWrite(exitCode)
        }
    }

    Process {
        id: wallpaperApplyProcess
        command: [
            Quickshell.shellDir + "/scripts/set_wallpaper",
            root.wallpaperApplyPendingPath,
            root.wallpaperApplyPendingScreenName,
            String(root.wallpaperApplyPendingScreenIndex)
        ]
        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text || "").trim()
                if (message !== "") {
                    if (root.wallpaperApplyIsRestore)
                        root.wallpaperRestoreLastError = message
                    else
                        root.wallpaperApplyError = message
                }
            }
        }
        onExited: function(exitCode) {
            if (root.wallpaperApplyIsRestore) {
                root.finishWallpaperRestore(exitCode)
                return
            }
            if (exitCode === 0) {
                root.wallpaperApplyError = ""
                root.rememberWallpaperUsage(root.wallpaperApplyPendingPath, root.wallpaperApplyPendingScreenName)
                root.hideLauncher()
            } else if (root.wallpaperApplyError === "") {
                root.wallpaperApplyError = "Не удалось установить обои. Проверьте backend и системные сообщения."
            }
            if (root.wallpaperRestoreQueue.length)
                wallpaperRestoreTimer.restart()
        }
    }

    Process {
        id: dynamicSchemeProcess
        command: [
            Quickshell.shellDir + "/scripts/launcher_dynamic_scheme",
            root.dynamicSchemePendingPath,
            root.dynamicSchemePendingVariant
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.dynamicSchemeStdout = String(this.text || "")
                root.dynamicSchemeStdoutReady = true
                root.finishDynamicSchemeWhenReady()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.dynamicSchemeStderr = String(this.text || "")
                root.dynamicSchemeStderrReady = true
                root.finishDynamicSchemeWhenReady()
            }
        }
        onExited: function(exitCode) {
            root.dynamicSchemeExitCode = Number(exitCode)
            root.dynamicSchemeProcessExited = true
            root.finishDynamicSchemeWhenReady()
        }
    }

    // Progress and final states use the same freedesktop notification ID. The
    // existing Notifications module receives every update through its usual
    // NotificationServer, so no Launcher result row is needed.
    Process {
        id: dynamicSchemeProgressNotificationProcess
        command: [
            "notify-send",
            "--app-name=Quickshell Widgets",
            "--urgency=low",
            "--expire-time=60000",
            "--print-id",
            "Создаётся цветовая схема…",
            "Matugen · " + root.dynamicSchemeVariantLabel(root.dynamicSchemePendingVariant)
                + (root.dynamicSchemePendingScreenName ? " · " + root.dynamicSchemePendingScreenName : "")
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.dynamicSchemeProgressNotificationOutput = String(this.text || "").trim()
                root.dynamicSchemeProgressNotificationStdoutReady = true
                root.finishDynamicSchemeProgressNotificationWhenReady()
            }
        }
        onExited: function(exitCode) {
            root.dynamicSchemeProgressNotificationProcessExited = true
            root.finishDynamicSchemeProgressNotificationWhenReady()
        }
    }

    Process {
        id: dynamicSchemeSuccessNotificationProcess
        command: {
            var args = [
                "notify-send",
                "--app-name=Quickshell Widgets",
                "--urgency=normal",
                "--expire-time=5000"
            ]
            if (root.dynamicSchemeProgressNotificationId > 0)
                args.push("--replace-id=" + String(root.dynamicSchemeProgressNotificationId))
            args.push("Цветовая схема создана", root.dynamicSchemeNotificationBody)
            return args
        }
    }

    // Failures replace the in-progress toast and retain the existing copy action.
    Process {
        id: dynamicSchemeNotificationProcess
        command: {
            var args = [
                "notify-send",
                "--app-name=Quickshell Widgets",
                "--urgency=critical",
                "--expire-time=12000",
                "--action=copy-error=Копировать ошибку"
            ]
            if (root.dynamicSchemeProgressNotificationId > 0)
                args.push("--replace-id=" + String(root.dynamicSchemeProgressNotificationId))
            args.push("Не удалось применить вариант Matugen", root.dynamicSchemeNotificationBody)
            return args
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (String(this.text || "").trim() === "copy-error"
                        && !dynamicSchemeCopyErrorProcess.running)
                    dynamicSchemeCopyErrorProcess.running = true
            }
        }
    }

    Process {
        id: dynamicSchemeCopyErrorProcess
        command: [
            Quickshell.shellDir + "/scripts/copy_text",
            root.dynamicSchemeNotificationCopyPayload
        ]
    }

    Connections {
        target: Config
        function onLauncherWallpaperDirectoryChanged() {
            if (root.wallpaperPickerActive)
                root.loadWallpaperCatalog(true)
            else
                root.wallpaperCatalogLoaded = false
        }
    }

    /*
     * EMOJI PICKER PREFERENCES AND USAGE
     */

    property var emojiPickerData: LauncherEmojiPicker.emptyData()
    property int emojiPickerGeneration: 0
    property int emojiPickerPendingGeneration: -1
    property bool emojiPickerLoadPending: false
    property var emojiPickerPendingMutations: []
    property bool emojiPickerPersistAfterLoad: false
    property string emojiPickerWriteActivePayload: ""
    property string emojiPickerWriteQueuedPayload: ""
    property bool emojiPickerWriteHasQueuedPayload: false
    property int emojiPickerWriteSequence: 0
    property string emojiPickerFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-emoji-data.json"

    Process {
        id: emojiPickerReadProcess
        command: [
            "sh",
            "-c",
            "cat -- \"$1\" 2>/dev/null; printf '\\n__LAUNCHER_EMOJI_DATA_REQUEST__%s\\n' \"$2\"",
            "launcher-emoji-data-read",
            root.emojiPickerFile,
            String(root.emojiPickerPendingGeneration)
        ]
        stdout: StdioCollector {
            onStreamFinished: root.acceptEmojiPickerData(this.text)
        }
    }

    Process {
        id: emojiPickerWriteProcess
        command: [
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && tmp=\"$1.tmp.$$.$3\" && printf '%s\\n' \"$2\" > \"$tmp\" && mv \"$tmp\" \"$1\"",
            "launcher-emoji-data-write",
            root.emojiPickerFile,
            root.emojiPickerWriteActivePayload,
            String(root.emojiPickerWriteSequence)
        ]
        onExited: function(exitCode) {
            root.finishEmojiPickerWrite(exitCode)
        }
    }

    function recordEmojiPickerMutation(type, emoji, timestamp) {
        root.emojiPickerGeneration += 1
        if (!root.emojiPickerLoadPending)
            return

        const mutations = Array.isArray(root.emojiPickerPendingMutations)
            ? root.emojiPickerPendingMutations.slice()
            : []
        mutations.push({
            type: String(type),
            emoji: String(emoji === undefined || emoji === null ? "" : emoji),
            timestamp: Number(timestamp) || 0
        })
        root.emojiPickerPendingMutations = mutations
    }

    function acceptEmojiPickerData(output) {
        const text = String(output ?? "")
        const marker = "\n__LAUNCHER_EMOJI_DATA_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0)
            return

        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration)
                || requestGeneration !== root.emojiPickerPendingGeneration
                || !root.emojiPickerLoadPending) {
            return
        }

        const diskData = LauncherEmojiPicker.parseData(text.slice(0, markerIndex))
        const mutations = Array.isArray(root.emojiPickerPendingMutations)
            ? root.emojiPickerPendingMutations.slice()
            : []
        const mergedData = LauncherEmojiPicker.applyMutations(diskData, mutations)
        const shouldPersistMergedData = mutations.length > 0 || root.emojiPickerPersistAfterLoad

        root.emojiPickerData = mergedData
        root.emojiPickerLoadPending = false
        root.emojiPickerPendingMutations = []
        root.emojiPickerPersistAfterLoad = false
        if (shouldPersistMergedData)
            root.persistEmojiPickerData()
    }

    function loadEmojiPickerDataFromDisk() {
        if (emojiPickerReadProcess.running)
            emojiPickerReadProcess.running = false

        root.emojiPickerGeneration += 1
        root.emojiPickerPendingGeneration = root.emojiPickerGeneration
        root.emojiPickerLoadPending = true
        root.emojiPickerPendingMutations = []
        emojiPickerReadProcess.running = true
    }

    function startEmojiPickerWrite(payload) {
        root.emojiPickerWriteActivePayload = String(payload ?? "")
        root.emojiPickerWriteSequence += 1
        emojiPickerWriteProcess.running = true
    }

    function finishEmojiPickerWrite(exitCode) {
        if (exitCode !== 0)
            console.warn("Launcher: failed to persist Emoji picker data (exit code", exitCode, ")")

        if (!root.emojiPickerWriteHasQueuedPayload)
            return

        const latestPayload = root.emojiPickerWriteQueuedPayload
        root.emojiPickerWriteQueuedPayload = ""
        root.emojiPickerWriteHasQueuedPayload = false
        root.startEmojiPickerWrite(latestPayload)
    }

    function persistEmojiPickerData() {
        if (root.emojiPickerLoadPending) {
            root.emojiPickerPersistAfterLoad = true
            return
        }

        const data = LauncherEmojiPicker.serializeData(root.emojiPickerData)
        if (emojiPickerWriteProcess.running) {
            root.emojiPickerWriteQueuedPayload = data
            root.emojiPickerWriteHasQueuedPayload = true
            return
        }

        root.emojiPickerWriteQueuedPayload = ""
        root.emojiPickerWriteHasQueuedPayload = false
        root.startEmojiPickerWrite(data)
    }

    function toggleLauncherEmojiFavorite(value) {
        const emoji = String(value === undefined || value === null ? "" : value)
        if (!emoji)
            return
        root.recordEmojiPickerMutation("toggleFavorite", emoji, 0)
        root.emojiPickerData = LauncherEmojiPicker.toggleFavorite(root.emojiPickerData, emoji)
        root.persistEmojiPickerData()
    }

    function rememberLauncherEmojiUsage(value) {
        const emoji = String(value === undefined || value === null ? "" : value)
        if (!emoji)
            return
        const timestamp = Date.now()
        root.recordEmojiPickerMutation("recordUsage", emoji, timestamp)
        root.emojiPickerData = LauncherEmojiPicker.recordUsage(root.emojiPickerData, emoji, timestamp)
        root.persistEmojiPickerData()
    }

    function toggleCurrentLauncherEmojiFavorite() {
        const results = Array.isArray(root.appsUnifiedResults) ? root.appsUnifiedResults : []
        const index = appList.currentIndex
        if (index < 0 || index >= results.length || !results[index] || results[index].kind !== "emoji")
            return false
        root.toggleLauncherEmojiFavorite(results[index].emoji)
        return true
    }

    property string emojiCopyPending: ""

    function copyLauncherEmoji(value) {
        const emoji = String(value === undefined || value === null ? "" : value)
        if (!emoji || emojiCopyProcess.running)
            return
        root.emojiCopyPending = emoji
        emojiCopyProcess.running = true
    }

    Process {
        id: emojiCopyProcess
        command: ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "launcher-emoji-copy", root.emojiCopyPending]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.rememberLauncherEmojiUsage(root.emojiCopyPending)
                root.hideLauncher()
            } else {
                console.warn("Launcher: emoji copy failed with exit code", exitCode)
            }
        }
    }

    property string calculatorCopyPending: ""

    function copyCalculatorResult(value, expression) {
        const text = String(value === undefined || value === null ? "" : value).trim()
        if (!text || calculatorCopyProcess.running)
            return
        const acceptedExpression = String(expression === undefined || expression === null ? "" : expression).trim()
        if (acceptedExpression !== "")
            root.rememberCalculatorCalculation(acceptedExpression, text)
        root.calculatorCopyPending = text
        calculatorCopyProcess.running = true
        root.hideLauncher()
    }

    Process {
        id: calculatorCopyProcess
        command: ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "launcher-calculator-copy", root.calculatorCopyPending]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                console.warn("Launcher: calculator result copy failed with exit code", exitCode)
        }
    }
    AppModel {
        id: appModel

        query: searchField.text
    }

    /*
     * CLIPBOARD
     */

    ListModel {
        id: clipboardModel
    }

    property string clipboardOutput: ""
    property int clipboardGeneration: 0
    property int clipboardPendingGeneration: -1

    Process {
        id: clipboardProcess

        command: [
            "sh", "-c",
            "cliphist list -fields 'id,mime,preview'; status=$?; printf '\\n__CLIPHIST_REQUEST__%s\\n' \"$1\"; exit \"$status\"",
            "launcher-clipboard",
            String(root.clipboardPendingGeneration)
        ]

        stdout: StdioCollector {
            onStreamFinished: root.finishClipboardLoad(this.text)
        }
    }

    function finishClipboardLoad(output) {
        const text = String(output ?? "")
        const marker = "\n__CLIPHIST_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0) return
        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration) ||
            requestGeneration !== root.clipboardGeneration ||
            !root.visible || root.mode !== root.modeClipboard || root.layoutEditMode) {
            return
        }
        const payload = text.slice(0, markerIndex)
        root.clipboardOutput = payload
        root.updateClipboardModel(payload)
    }

    function updateClipboardModel(output) {
        clipboardModel.clear()

        const lines = String(output ?? "").split("\n")
        const query = searchField
            ? searchField.text.toLowerCase().trim()
            : ""
        const alternateQuery = LauncherKeyboardLayout.alternateLayoutQuery(query)

        for (const line of lines) {
            if (line.trim() === "")
                continue

            const firstTab = line.indexOf("\t")

            if (firstTab < 0)
                continue

            const id = line.slice(0, firstTab)
            const rest = line.slice(firstTab + 1)

            const secondTab = rest.indexOf("\t")

            let mime = ""
            let preview = rest

            if (secondTab >= 0) {
                mime = rest.slice(0, secondTab)
                preview = rest.slice(secondTab + 1)
            }

            const searchable =
                (mime + " " + preview).toLowerCase()

            if (
                query !== "" &&
                !searchable.includes(query) &&
                (alternateQuery === "" || !searchable.includes(alternateQuery))
            ) {
                continue
            }

            clipboardModel.append({
                id: id,
                mime: mime,
                preview: preview,
                isImage: mime.startsWith("image/"),
                raw: line
            })
        }

        clipboardList.currentIndex =
            clipboardModel.count > 0 ? 0 : -1
    }

    function loadClipboard() {
        if (!root.visible || root.mode !== root.modeClipboard || root.layoutEditMode)
            return
        root.clipboardGeneration += 1
        root.clipboardPendingGeneration = root.clipboardGeneration
        if (clipboardProcess.running)
            clipboardProcess.running = false
        clipboardProcess.running = true
    }

    function selectClipboard(index) {
        if (
            index < 0 ||
            index >= clipboardModel.count
        ) {
            return
        }

        const item = clipboardModel.get(index)

        Quickshell.execDetached([
            "sh",
            "-c",
            "printf '%s\\n' \"$1\" | cliphist decode | wl-copy",
            "launcher-clipboard",
            item.raw
        ])

        root.hideLauncher()
    }

    Timer {
        id: clipboardReloadTimer
        interval: 150
        repeat: false

        onTriggered: root.loadClipboard()
    }

    function deleteClipboard(index) {
        if (
            index < 0 ||
            index >= clipboardModel.count
        ) {
            return
        }

        const item = clipboardModel.get(index)

        Quickshell.execDetached([
            "sh",
            "-c",
            "printf '%s\\n' \"$1\" | cliphist delete",
            "launcher-clipboard-delete",
            item.raw
        ])

        clipboardReloadTimer.restart()
    }

    function clearClipboard() {
        Quickshell.execDetached([
            "cliphist",
            "wipe"
        ])

        clipboardReloadTimer.restart()
    }

    /*
     * BACKDROP
     */

    Rectangle {
        anchors.fill: parent
        visible: !root.layoutEditMode

        color: theme.backdrop
        opacity: theme.backdropOpacity

        MouseArea {
            anchors.fill: parent

            onClicked: root.hideLauncher()
        }
    }

    /*
     * LAUNCHER
     */

    Rectangle {
        id: launcherBox

        x: root.launcherPositionX
        y: root.launcherPositionY
        width: Config.launcherWidth
        height: Config.launcherHeight

        radius: Config.launcherRadius

        property bool entranceReady: false
        scale: entranceReady ? 1.0 : 0.97
        opacity: root.layoutDragHidden ? 0.0 : (entranceReady ? 1.0 : 0.0)

        Translate {
            id: entranceTranslate
            // The transform is a child of launcherBox, but its own QML
            // scope does not inherit launcherBox properties implicitly.
            y: launcherBox.entranceReady ? 0 : 10

            Behavior on y {
                NumberAnimation {
                    duration: Config.animationDuration(180, "movement")
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: Config.animationDuration(180, "size"); easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: Config.animationDuration(140, "appearance"); easing.type: Easing.OutCubic }
        }

        Component.onCompleted: entranceTimer.start()

        Timer {
            id: entranceTimer
            interval: 1
            repeat: false
            onTriggered: launcherBox.entranceReady = true
        }

        color: (!Settings.loaded || Settings.moduleBackgrounds.launcher !== false)
            ? theme.launcherBackground : theme.transparent

        border.color: theme.border
        border.width: (!Settings.loaded || Settings.moduleFrames.launcher !== false)
            ? Config.frameBorderWidth : 0
        focus: root.mode === root.modePower
        onActiveFocusChanged: root.handleLauncherKeyboardFocusChanged()

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (root.mode !== root.modePower)
                return

            if (event.key === Qt.Key_Escape) {
                root.hideLauncher()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Up) {
                root.moveSelectionUp()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Down) {
                root.moveSelectionDown()
                event.accepted = true
                return
            }
            if (Config.launcherVimKeybinds && (event.modifiers & Qt.ControlModifier)
                    && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier))) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    root.moveSelectionDown()
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    root.moveSelectionUp()
                    event.accepted = true
                    return
                }
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activate()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier))
                    root.previousMode()
                else
                    root.nextMode()
                event.accepted = true
                return
            }
            if ((event.modifiers & Qt.ControlModifier) &&
                (event.key === Qt.Key_0 || event.key === Qt.Key_ParenRight)) {
                root.setMode(root.modeApps)
                event.accepted = true
                return
            }
            if (event.modifiers & Qt.AltModifier) {
                var shortcutIndex = -1
                switch (event.key) {
                case Qt.Key_1:
                case Qt.Key_Exclam: shortcutIndex = 0; break
                case Qt.Key_2:
                case Qt.Key_At: shortcutIndex = 1; break
                case Qt.Key_3:
                case Qt.Key_NumberSign: shortcutIndex = 2; break
                case Qt.Key_4:
                case Qt.Key_Dollar: shortcutIndex = 3; break
                case Qt.Key_5:
                case Qt.Key_Percent: shortcutIndex = 4; break
                case Qt.Key_6:
                case Qt.Key_AsciiCircum: shortcutIndex = 5; break
                case Qt.Key_7:
                case Qt.Key_Ampersand: shortcutIndex = 6; break
                case Qt.Key_8:
                case Qt.Key_Asterisk: shortcutIndex = 7; break
                case Qt.Key_9:
                case Qt.Key_ParenLeft: shortcutIndex = 8; break
                case Qt.Key_0: shortcutIndex = 9; break
                }
                if (shortcutIndex >= 0 && shortcutIndex < root.displayedModeTabs.length) {
                    root.setMode(root.displayedModeTabs[shortcutIndex].mode)
                    event.accepted = true
                    return
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
        }

        HoverHandler {
            id: launcherPointerTracker

            onPointChanged: root.updatePointerPosition(point)

            onHoveredChanged: {
                root.pointerInsideLauncher = hovered
                if (hovered) {
                    const moved = root.updatePointerPosition(point)
                    if (!moved)
                        root.disarmPointerHover()
                } else {
                    root.disarmPointerHover()
                    if (!root.visible)
                        root.pointerGlobalPositionKnown = false
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.layoutEditMode && !root.layoutDragHidden
            z: 10000
            color: "transparent"
            border.color: Config.accent
            border.width: Math.max(2, Config.frameBorderWidth + 1)
            radius: Config.frameRadius
            antialiasing: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 5
                width: launcherEditLabel.implicitWidth + 14
                height: launcherEditLabel.implicitHeight + 8
                radius: 4
                color: Config.accent

                Text {
                    id: launcherEditLabel
                    anchors.centerIn: parent
                    text: "launcher"
                    color: Config.black
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    font.bold: true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: root.layoutEditMode
            z: 10001
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            onPressed: function(mouse) { root.beginLauncherDrag(mouse) }
            onPositionChanged: function(mouse) { if (pressed) root.updateLauncherDrag(mouse) }
            onReleased: function(mouse) { root.finishLauncherDrag(mouse) }
            onCanceled: root.cancelLayoutDrag()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20

            spacing: 10

            /*
             * HEADER
             */

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Text {
                    text: Config.launcherTitleText
                    color: Config.launcherTitleColor
                    font.family: Config.launcherTitleFont.trim() === "" ? "" : Config.launcherTitleFont
                    font.pixelSize: Config.launcherTitleFontSize
                    font.bold: Config.launcherTitleBold
                    font.letterSpacing: Config.launcherTitleLetterSpacing
                    transform: Translate { y: Config.launcherTitleY }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.currentModeName.toUpperCase()
                    color: theme.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                }

                Text {
                    visible: Config.launcherShowResultCount
                    text: root.currentResultCount + " RESULTS"
                    color: theme.textVeryDim
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
                }
            }

            /*
             * MODE SELECTOR
             */

            RowLayout {
                id: modeSelector

                Layout.fillWidth: true
                spacing: 0

                Item {
                    id: modeTabsContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    Layout.minimumHeight: 32
                    Layout.maximumHeight: 32

                    // This one frame glides horizontally between mode tabs.
                    Rectangle {
                        id: modeSelectionFrame
                        x: Math.max(0, root.selectedModeTabIndex) * 44
                        y: 0
                        width: 38
                        height: 32
                        radius: 8
                        color: theme.transparent
                        border.color: theme.borderAccent
                        border.width: root.selectedModeTabIndex >= 0 ? 1 : 0
                        visible: root.selectedModeTabIndex >= 0
                        z: 0

                        Behavior on x {
                            NumberAnimation {
                                duration: root.interactionAnimationDuration
                                easing.type: root.interactionAnimationEasing
                                easing.bezierCurve: root.interactionAnimationBezierCurve
                            }
                        }
                    }

                    Repeater {
                        model: root.displayedModeTabs

                        delegate: Item {
                            id: modeButton
                            required property var modelData
                            required property int index

                            x: index * 44
                            y: 0
                            width: 38
                            height: 32
                            z: 1

                            ToolTip.text: modelData.label
                            ToolTip.visible: modeMouse.containsMouse
                            ToolTip.delay: 450

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: root.mode === modeButton.modelData.mode
                                    ? theme.textWhite
                                    : theme.modeNormalText
                                font.family: theme.iconFontFamily
                                font.pixelSize: 17
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.setMode(modeButton.modelData.mode)
                            }
                        }
                    }
                }
            }

            /*
             * SEARCH
             */

            Rectangle {
                id: searchContainer
                visible: root.mode !== root.modePower
                Layout.fillWidth: true
                Layout.preferredHeight: Config.launcherSearchHeight
                Layout.minimumHeight: Config.launcherSearchHeight
                Layout.maximumHeight: Config.launcherSearchHeight

                radius: Config.launcherSearchRadius
                color: Config.launcherSearchBackground

                border.color: searchField.activeFocus
                    ? theme.borderAccent
                    : theme.border

                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                }


                TextField {
                    id: searchField
                    onActiveFocusChanged: root.handleLauncherKeyboardFocusChanged()

                    anchors.fill: parent

                    anchors.leftMargin: 18
                    anchors.rightMargin: 18

                    background: null

                    color: theme.textWhite

                    font.family: Config.launcherSearchFont.trim() === "" ? "" : Config.launcherSearchFont
                    font.pixelSize: Config.launcherSearchFontSize

                    placeholderText: {
                        if (Config.launcherSearchPlaceholder.trim() !== "")
                            return Config.launcherSearchPlaceholder
                        switch (root.mode) {
                        case root.modeApps:
                            return "Search apps, @ filters, > commands or : saved actions..."

                        case root.modeRun:
                            return "Run command..."

                        case root.modeWindows:
                            return "Search windows..."

                        case root.modeClipboard:
                            return "Search clipboard..."

                        case root.modeNetwork:
                            return "Search networks..."

                        case root.modeNix:
                            return "Search Nix packages..."

                        case root.modePass:
                            return "Search passwords..."

                        case root.modeProjects:
                            return "Search projects..."

                        default:
                            return ""
                        }
                    }

                    placeholderTextColor: theme.textVeryDim

                    selectByMouse: true

                    echoMode: TextInput.Normal

                    Keys.priority: Keys.BeforeItem

                    Keys.onPressed: function(event) {

                        // Ctrl+Shift+F toggles the selected emoji's favourite flag.
                        // A normal click on the star at the row's trailing edge does the same.
                        if (
                            root.mode === root.modeApps &&
                            event.key === Qt.Key_F &&
                            (event.modifiers & Qt.ControlModifier) &&
                            (event.modifiers & Qt.ShiftModifier) &&
                            root.toggleCurrentLauncherEmojiFavorite()
                        ) {
                            event.accepted = true
                            return
                        }

                        // Wallpaper tiles use explicit four-way navigation rather than
                        // moving the text cursor while the picker is active.
                        if (root.mode === root.modeApps && root.wallpaperPickerActive
                                && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                            root.moveWallpaperSelection(event.key === Qt.Key_Left ? "left" : "right")
                            event.accepted = true
                            return
                        }

                        // Apps: Enter/Return launches the currently selected
                        // application, matching the mouse-click activation path.
                        if (
                            root.mode === root.modeApps &&
                            (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        ) {
                            root.launchCurrent()
                            event.accepted = true
                            return
                        }

                        if (
                            root.mode === root.modeCalculator &&
                            (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        ) {
                            if (calculatorList.currentIndex >= 0 && calculatorList.currentIndex < root.calculatorDisplayResults.length)
                                root.activateCalculatorItem(root.calculatorDisplayResults[calculatorList.currentIndex])
                            event.accepted = true
                            return
                        }

                        // Pass: Enter copies the selected password entry just
                        // like a click on the selected row.
                        if (
                            root.mode === root.modePass &&
                            (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        ) {
                            root.copySelectedPass()
                            event.accepted = true
                            return
                        }

                        // Packages: Enter keeps the primary fast workflow
                        // (copy `name # description`). Ctrl+Enter opens the
                        // user's existing `add` alias in foot.
                        if (
                            root.mode === root.modeNix &&
                            (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) &&
                            (event.modifiers & Qt.ControlModifier)
                        ) {
                            root.openNixAddCommand()
                            event.accepted = true
                            return
                        }

                        /*
                         * RUN: Enter/Return always executes exactly what is
                         * currently in the search field. This is deliberately
                         * handled first in the main Keys.onPressed handler so
                         * it cannot fall through to list selection logic.
                         */
                        if (
                            root.mode === root.modeRun &&
                            (
                                event.key === Qt.Key_Return ||
                                event.key === Qt.Key_Enter
                            )
                        ) {
                            root.runCommand(searchField.text)
                            event.accepted = true
                            return
                        }

                        if (
                            root.mode === root.modeProjects &&
                            (
                                event.key === Qt.Key_Return ||
                                event.key === Qt.Key_Enter
                            )
                        ) {
                            root.launchCurrentProject()
                            event.accepted = true
                            return
                        }
                        // Ctrl+0 returns to Apps. Keep the numeric layout
                        // shortcuts on Alt so the launcher can be paired with
                        // independent Niri bindings for opening each tab.
                        if (
                            (event.modifiers & Qt.ControlModifier) &&
                            (event.key === Qt.Key_0 || event.key === Qt.Key_ParenRight)
                        ) {
                            root.setMode(root.modeApps)
                            event.accepted = true
                            return
                        }

                        // Optional Caelestia-style selection movement. Use Ctrl so
                        // ordinary j/k/n/p characters remain editable search text;
                        // Tab keeps its existing role of switching Launcher tabs.
                        if (Config.launcherVimKeybinds && (event.modifiers & Qt.ControlModifier)
                                && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier))) {
                            if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                                root.moveSelectionDown()
                                event.accepted = true
                                return
                            }
                            if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                                root.moveSelectionUp()
                                event.accepted = true
                                return
                            }
                        }

                        // Alt+1..9 and Alt+0 follow the visible tab order. Explicit IPC
                        // methods remain stable and can still open hidden tabs.
                        if (event.modifiers & Qt.AltModifier) {
                            let shortcutIndex = -1
                            switch (event.key) {
                            case Qt.Key_1:
                            case Qt.Key_Exclam: shortcutIndex = 0; break
                            case Qt.Key_2:
                            case Qt.Key_At: shortcutIndex = 1; break
                            case Qt.Key_3:
                            case Qt.Key_NumberSign: shortcutIndex = 2; break
                            case Qt.Key_4:
                            case Qt.Key_Dollar: shortcutIndex = 3; break
                            case Qt.Key_5:
                            case Qt.Key_Percent: shortcutIndex = 4; break
                            case Qt.Key_6:
                            case Qt.Key_AsciiCircum: shortcutIndex = 5; break
                            case Qt.Key_7:
                            case Qt.Key_Ampersand: shortcutIndex = 6; break
                            case Qt.Key_8:
                            case Qt.Key_Asterisk: shortcutIndex = 7; break
                            case Qt.Key_9:
                            case Qt.Key_ParenLeft: shortcutIndex = 8; break
                            case Qt.Key_0: shortcutIndex = 9; break
                            }
                            if (shortcutIndex >= 0 && shortcutIndex < root.displayedModeTabs.length) {
                                root.setMode(root.displayedModeTabs[shortcutIndex].mode)
                                event.accepted = true
                                return
                            }
                        }

                        /*
                         * CTRL+W — delete the previous word
                         * like in a terminal (readline).
                         */

                        if (
                            event.key === Qt.Key_W &&
                            (event.modifiers & Qt.ControlModifier)
                        ) {
                            const cursor = searchField.cursorPosition
                            const before = searchField.text.slice(0, cursor)
                            const after = searchField.text.slice(cursor)

                            // First remove whitespace directly before the cursor,
                            // then remove the preceding word.
                            const newBefore = before
                                .replace(/\s+$/, "")
                                .replace(/\S+$/, "")

                            searchField.text = newBefore + after
                            searchField.cursorPosition = newBefore.length

                            event.accepted = true
                            return
                        }

                        /*
                         * RUN: Right Arrow inserts the currently selected
                         * command into the search field. This is deliberately
                         * separate from Enter: Enter executes the text in the
                         * field, while Right Arrow accepts the suggestion so
                         * it can be edited first.
                         */

                        if (
                            root.mode === root.modeRun &&
                            event.key === Qt.Key_Right &&
                            runList.currentIndex >= 0 &&
                            runList.currentIndex < runList.count
                        ) {
                            const item = root.runResults[runList.currentIndex]
                            if (item && item.command) {
                                searchField.text = item.command
                                searchField.cursorPosition = searchField.text.length
                                searchField.forceActiveFocus()
                            }

                            event.accepted = true
                            return
                        }

                        /*
                         * TAB / SHIFT+TAB
                         */

                        if (
                            event.key === Qt.Key_Tab ||
                            event.key === Qt.Key_Backtab
                        ) {
                            if (
                                root.mode === root.modeRun &&
                                event.key === Qt.Key_Tab &&
                                !(event.modifiers & Qt.ShiftModifier) &&
                                searchField.text.trim() !== ""
                            ) {
                                root.completeRun()
                            } else if (
                                event.key === Qt.Key_Backtab ||
                                (
                                    event.modifiers &
                                    Qt.ShiftModifier
                                )
                            ) {
                                root.previousMode()
                            } else {
                                root.nextMode()
                            }

                            event.accepted = true
                            return
                        }

                        /*
                         * NETWORK: CTRL+R — rescan Wi-Fi networks.
                         */

                        if (
                            root.mode === root.modeNetwork &&
                            event.key === Qt.Key_R &&
                            (event.modifiers & Qt.ControlModifier) &&
                            !(event.modifiers & (Qt.AltModifier | Qt.ShiftModifier))
                        ) {
                            Network.refresh()
                            event.accepted = true
                            return
                        }

                        /*
                         * CLIPBOARD: Delete removes the selected entry.
                         * Ctrl+Delete clears the complete cliphist history.
                         */

                        if (
                            root.mode === root.modeClipboard &&
                            event.key === Qt.Key_Delete &&
                            (event.modifiers & Qt.ControlModifier) &&
                            !(event.modifiers & (Qt.AltModifier | Qt.ShiftModifier))
                        ) {
                            root.clearClipboard()
                            event.accepted = true
                            return
                        }

                        if (
                            root.mode === root.modeClipboard &&
                            event.key === Qt.Key_Delete &&
                            !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier))
                        ) {
                            root.deleteClipboard(clipboardList.currentIndex)
                            event.accepted = true
                            return
                        }

                        /*
                         * RUN: Delete removes the selected history entry.
                         * Ctrl+Delete clears the complete Run history.
                         * Shell/PATH suggestions are never deleted.
                         */

                        if (
                            root.mode === root.modeRun &&
                            event.key === Qt.Key_Delete &&
                            (event.modifiers & Qt.ControlModifier) &&
                            !(event.modifiers & (Qt.AltModifier | Qt.ShiftModifier))
                        ) {
                            root.clearRunHistory()
                            event.accepted = true
                            return
                        }

                        if (
                            root.mode === root.modeRun &&
                            event.key === Qt.Key_Delete &&
                            !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.ShiftModifier))
                        ) {
                            root.deleteRunHistory(runList.currentIndex)
                            event.accepted = true
                            return
                        }

                        /*
                         * ESC
                         */

                        if (event.key === Qt.Key_Escape) {
                            root.hideLauncher()
                            event.accepted = true
                            return
                        }

                        /*
                         * UP
                         */

                        if (event.key === Qt.Key_Up) {
                            root.moveSelectionUp()

                            event.accepted = true
                            return
                        }

                        /*
                         * DOWN
                         */

                        if (event.key === Qt.Key_Down) {
                            root.moveSelectionDown()

                            event.accepted = true
                            return
                        }

                    }

                    onTextChanged: {
                        root.disarmPointerHover()
                        // The built-in action palette (>) and saved-action catalog (:)
                        // are global Launcher searches from every tab.
                        const launcherQuery = root.normalizeRunText(searchField.text)
                        if (root.mode !== root.modeApps
                                && (launcherQuery.startsWith(">") || launcherQuery.startsWith(":"))) {
                            root.setMode(root.modeApps)
                            Qt.callLater(root.restoreLauncherKeyboardFocus)
                        }
                        if (root.mode === root.modeRun) {
                            // Rebuild the history model first. runResults is
                            // derived from it, so doing this in the opposite
                            // order leaves the Run list empty on first entry.
                            root.rebuildRunHistoryModel()
                            root.rebuildRunModel()
                        }

                        if (root.mode === root.modeWindows) {
                            root.rebuildWindowModel()
                        }

                        if (root.mode === root.modeClipboard) {
                            root.updateClipboardModel(
                                root.clipboardOutput
                            )
                        }

                        if (root.mode === root.modeNetwork) {
                            root.rebuildNetworkModel()
                        }

                        if (root.mode === root.modeNix) {
                            root.scheduleNixSearch()
                        }

                        if (root.mode === root.modePass) {
                            root.rebuildPassModel()
                        }

                        if (root.mode === root.modeProjects) {
                            root.rebuildProjectsModel()
                        }
                        const wallpaperQuery = LauncherWallpaperPicker.parseQuery(
                            root.normalizeRunText(searchField.text).replace(/^\s*>\s*/, "")
                        )
                        if (wallpaperQuery.active) {
                            root.loadWallpaperCatalog(false)
                        }
                    }
                }
            }

            /*
             * CONTENT
             */

            Item {
                id: contentArea

                Layout.fillWidth: true
                Layout.fillHeight: true

                /*
                 * APPS
                 */

                RowLayout {
                    id: wallpaperToolbar
                    anchors.top: contentArea.top
                    anchors.left: contentArea.left
                    anchors.right: contentArea.right
                    height: root.mode === root.modeApps && (root.wallpaperPickerActive || root.dynamicSchemePickerActive || root.schemeVariantPickerActive) ? 42 : 0
                    visible: height > 0
                    spacing: 7

                    Text {
                        text: (root.dynamicSchemePickerActive || root.schemeVariantPickerActive) ? "Источник:" : "Монитор:"
                        color: theme.textDim
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: Quickshell.screens
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            property string outputName: LauncherWallpaperPicker.screenName(modelData, index)
                            implicitWidth: outputLabel.implicitWidth + 22
                            implicitHeight: 29
                            radius: 7
                            color: root.wallpaperSelectedScreenName === outputName ? theme.accent : theme.surfaceAlt
                            border.color: root.wallpaperSelectedScreenName === outputName ? theme.borderAccent : theme.borderSubtle
                            border.width: 1

                            Text {
                                id: outputLabel
                                anchors.centerIn: parent
                                text: parent.outputName
                                color: root.wallpaperSelectedScreenName === parent.outputName ? theme.selectedText : theme.text
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.wallpaperSelectScreen(parent.modelData, parent.index)
                            }
                        }
                    }

                    Rectangle {
                        visible: !root.dynamicSchemePickerActive && !root.schemeVariantPickerActive && !root.wallpaperRandomMode
                        implicitWidth: scopeAllLabel.implicitWidth + 18
                        implicitHeight: 27
                        radius: 7
                        color: root.activeWallpaperQuery.scope === "all" ? theme.accent : theme.surfaceAlt
                        border.color: root.activeWallpaperQuery.scope === "all" ? theme.borderAccent : theme.borderSubtle
                        Text { id: scopeAllLabel; anchors.centerIn: parent; text: "Все"; color: root.activeWallpaperQuery.scope === "all" ? theme.selectedText : theme.text; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setWallpaperScope("all") }
                    }
                    Rectangle {
                        visible: !root.dynamicSchemePickerActive && !root.schemeVariantPickerActive && !root.wallpaperRandomMode
                        implicitWidth: scopeFavoritesLabel.implicitWidth + 18
                        implicitHeight: 27
                        radius: 7
                        color: root.activeWallpaperQuery.scope === "favorites" ? theme.accent : theme.surfaceAlt
                        border.color: root.activeWallpaperQuery.scope === "favorites" ? theme.borderAccent : theme.borderSubtle
                        Text { id: scopeFavoritesLabel; anchors.centerIn: parent; text: "★ Избранное"; color: root.activeWallpaperQuery.scope === "favorites" ? theme.selectedText : theme.accent; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setWallpaperScope("favorites") }
                    }
                    Rectangle {
                        visible: !root.dynamicSchemePickerActive && !root.schemeVariantPickerActive && !root.wallpaperRandomMode
                        implicitWidth: scopeRecentLabel.implicitWidth + 18
                        implicitHeight: 27
                        radius: 7
                        color: root.activeWallpaperQuery.scope === "recent" ? theme.accent : theme.surfaceAlt
                        border.color: root.activeWallpaperQuery.scope === "recent" ? theme.borderAccent : theme.borderSubtle
                        Text { id: scopeRecentLabel; anchors.centerIn: parent; text: "Недавние"; color: root.activeWallpaperQuery.scope === "recent" ? theme.selectedText : theme.text; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setWallpaperScope("recent") }
                    }

                    Text {
                        text: (root.dynamicSchemePickerActive ? "Палитра из " : (root.schemeVariantPickerActive ? "Обои для " : (root.wallpaperRandomMode ? "Случайные обои для " : "Для "))) + root.wallpaperSelectedScreenName
                        color: theme.textVeryDim
                        font.pixelSize: 10
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        Layout.maximumWidth: contentArea.width * 0.42
                        visible: root.wallpaperApplyError !== ""
                        text: root.wallpaperApplyError
                        color: "#ff9999"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                    }
                }

                GridView {
                    id: appList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.top: wallpaperToolbar.visible ? wallpaperToolbar.bottom : parent.top

                    visible: root.mode === root.modeApps

                    clip: true
                    flow: GridView.FlowLeftToRight
                    cellWidth: root.wallpaperPickerActive && !root.wallpaperRandomMode ? width / wallpaperColumnCount : width
                    cellHeight: root.wallpaperPickerActive && !root.wallpaperRandomMode ? 230 : Config.launcherItemHeight + 6
                    keyNavigationEnabled: false
                    keyNavigationWraps: false

                    property int wallpaperColumnCount: Math.max(1, Math.floor((width + 12) / 192))
                    property real wallpaperTileWidth: Math.max(1, width / wallpaperColumnCount - 12)

                    model: root.appsUnifiedResults

                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()
                    onContentXChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: appDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeApps && root.pointerHoveredIndex === index

                        scale: GridView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        width: root.wallpaperPickerActive && !root.wallpaperRandomMode ? appList.wallpaperTileWidth : appList.width
                        height: root.wallpaperPickerActive && !root.wallpaperRandomMode ? 218 : Config.launcherItemHeight

                        radius: Config.launcherItemRadius

                        color: GridView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: GridView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        Behavior on color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        property var itemData: modelData
                        property var entry: itemData && itemData.kind === "app" ? itemData.entry : null
                        property string displayName: root.appsResultName(itemData, entry)
                        property string displaySubtitle: root.appsResultSubtitle(itemData, entry)

                        RowLayout {
                            anchors.fill: parent
                            visible: !(appDelegate.itemData && appDelegate.itemData.kind === "wallpaper")

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter

                                radius: 10

                                color: GridView.isCurrentItem
                                    ? theme.accent
                                    : (appDelegate.hovered
                                        ? theme.surfaceAlt
                                        : theme.surface)

                                Behavior on color {
                                    ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                                }

                                Image {
                                    id: appIconImage

                                    anchors.fill: parent
                                    anchors.margins: 7

                                    // Resolve the desktop-entry icon before loading it.
                                    // Missing theme icons (for example, rofi or jockey)
                                    // then produce an empty source instead of a Qt warning.
                                    source: appDelegate.entry && appDelegate.entry.icon
                                        ? Quickshell.iconPath(String(appDelegate.entry.icon), true)
                                        : ""
                                    // This image is only for native application results. Projects and
                                    // saved commands use their own fallback icons below. Checking a
                                    // QML url against an empty string can be truthy even for an empty
                                    // url, which previously hid those fallback icons in Apps search.
                                    visible: appDelegate.itemData
                                        && appDelegate.itemData.kind === "app"
                                        && String(source).length > 0

                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                // A project without a reliable custom glyph uses a small
                                // vector folder. This keeps the result visibly identifiable
                                // even when a Nerd Font glyph is unavailable on the system.
                                Item {
                                    id: projectFolderFallback
                                    anchors.centerIn: parent
                                    width: 25
                                    height: 22
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "project"
                                        && String(appDelegate.itemData.project && appDelegate.itemData.project.icon || "") === ""

                                    property color glyphColor: GridView.isCurrentItem ? theme.selectedText : theme.textMuted

                                    Rectangle {
                                        x: 2
                                        y: 2
                                        width: 12
                                        height: 7
                                        radius: 2
                                        color: projectFolderFallback.glyphColor
                                    }
                                    Rectangle {
                                        x: 1
                                        y: 6
                                        width: 23
                                        height: 15
                                        radius: 3
                                        color: projectFolderFallback.glyphColor
                                    }
                                    Rectangle {
                                        x: 4
                                        y: 9
                                        width: 17
                                        height: 9
                                        radius: 2
                                        color: GridView.isCurrentItem ? theme.accent : theme.surface
                                    }
                                }

                                // Custom project glyphs remain supported. A vector folder
                                // is used for the default glyph above, rather than relying on
                                // a font's private-use Unicode mapping.
                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "project"
                                        && String(appDelegate.itemData.project && appDelegate.itemData.project.icon || "") !== ""
                                    text: String(appDelegate.itemData && appDelegate.itemData.project && appDelegate.itemData.project.icon || "")
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.textMuted
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }

                                // Draw the terminal marker with ordinary characters so it
                                // does not depend on Nerd Font glyph coverage.
                                Item {
                                    id: runCommandFallback
                                    anchors.centerIn: parent
                                    width: 25
                                    height: 21
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "run"

                                    property color glyphColor: GridView.isCurrentItem ? theme.selectedText : theme.textMuted

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 3
                                        color: "transparent"
                                        border.color: runCommandFallback.glyphColor
                                        border.width: 1.5
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: ">_"
                                        color: runCommandFallback.glyphColor
                                        font.family: "monospace"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "emojiPickerAction"
                                    text: "😀"
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.textWhite
                                    font.pixelSize: 25
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && (appDelegate.itemData.kind === "schemePickerAction"
                                            || appDelegate.itemData.kind === "schemeVariantPickerAction"
                                            || appDelegate.itemData.kind === "schemeVariant"
                                            || appDelegate.itemData.kind === "scheme"
                                            || appDelegate.itemData.kind === "dynamicSchemeAction"
                                            || appDelegate.itemData.kind === "dynamicSchemeGenerate"
                                            || appDelegate.itemData.kind === "dynamicSchemeUnavailable"
                                            || appDelegate.itemData.kind === "dynamicSchemeError"
                                            || appDelegate.itemData.kind === "dynamicSchemeWallpaperAction"
                                            || appDelegate.itemData.kind === "wallpaperRandomAction")
                                    text: appDelegate.itemData.kind === "wallpaperRandomAction" ? "" : "󰏘"
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.accent
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 23
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "emoji"
                                    text: String(appDelegate.itemData.emoji || "")
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.textWhite
                                    font.pixelSize: 25
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "appCategory"
                                    text: "▦"
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.accent
                                    font.pixelSize: 22
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "app"
                                    text: "󰀻"
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.textMuted
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && appDelegate.itemData.kind === "calculator"
                                    text: "󰃬"
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.accent
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImage.visible
                                        && appDelegate.itemData
                                        && (appDelegate.itemData.kind === "dashboardAction"
                                            || appDelegate.itemData.kind === "action" || appDelegate.itemData.kind === "customAction"
                                            || appDelegate.itemData.kind === "wallpaperPickerAction"
                                            || appDelegate.itemData.kind === "dynamicSchemeWallpaperAction")
                                    text: String(appDelegate.itemData.icon || "󰌌")
                                    color: GridView.isCurrentItem ? theme.selectedText : theme.textMuted
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true

                                        text: root.highlightFuzzy(
                                            appDelegate.displayName,
                                            appDelegate.itemData && appDelegate.itemData.kind === "emoji"
                                                ? LauncherEmojiPicker.parseQuery(searchField.text.replace(/^\s*>\s*/, "")).query
                                                : (appDelegate.itemData && appDelegate.itemData.kind === "scheme"
                                                    ? LauncherSchemePicker.parseQuery(searchField.text.replace(/^\s*>\s*/, "")).query
                                                    : (appDelegate.itemData && appDelegate.itemData.kind === "schemeVariant"
                                                        ? LauncherSchemeVariantPicker.parseQuery(searchField.text.replace(/^\s*>\s*/, "")).query
                                                    : (appDelegate.itemData && (appDelegate.itemData.kind === "action" || appDelegate.itemData.kind === "customAction" || appDelegate.itemData.kind === "emojiPickerAction" || appDelegate.itemData.kind === "schemePickerAction" || appDelegate.itemData.kind === "schemeVariantPickerAction" || appDelegate.itemData.kind === "schemeVariant" || appDelegate.itemData.kind === "dynamicSchemeAction" || appDelegate.itemData.kind === "dynamicSchemeGenerate" || appDelegate.itemData.kind === "dynamicSchemeUnavailable" || appDelegate.itemData.kind === "dynamicSchemeError" || appDelegate.itemData.kind === "dynamicSchemeWallpaperAction" || appDelegate.itemData.kind === "dashboardAction")
                                                        ? searchField.text.replace(/^\s*>\s*/, "")
                                                        : (appDelegate.itemData && appDelegate.itemData.kind === "app" && appModel.specialSearch
                                                            ? appModel.specialSearch.query
                                                            : searchField.text))))
                                        )

                                        textFormat: Text.StyledText
                                        color: GridView.isCurrentItem
                                            ? theme.selectedText
                                            : theme.textWhite

                                        font.pixelSize: 16

                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        // Keep the six dots beside the theme name so they
                                        // remain visible inside the card's existing text column.
                                        Layout.preferredWidth: appDelegate.itemData && appDelegate.itemData.kind === "scheme" ? 87 : 0
                                        Layout.preferredHeight: 14
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 3
                                        visible: appDelegate.itemData && appDelegate.itemData.kind === "scheme"

                                        Repeater {
                                            // Use the same live preview provider as Settings.
                                            // Do not pass the colors through an intermediate result object.
                                            model: appDelegate.itemData && appDelegate.itemData.kind === "scheme"
                                                ? Settings.themePreview(String(appDelegate.itemData.name || "")) : []
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 12
                                                height: 12
                                                radius: 6
                                                color: String(modelData || "transparent")
                                                border.color: theme.borderSubtle
                                                border.width: 0.5
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: appDelegate.displaySubtitle

                                    color: GridView.isCurrentItem
                                        ? theme.selectedSubtext
                                        : theme.textDim

                                    font.pixelSize: 12

                                    elide: Text.ElideRight
                                }
                            }

                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter
                                visible: appDelegate.itemData && appDelegate.itemData.kind === "emoji"

                                Text {
                                    anchors.centerIn: parent
                                    text: appDelegate.itemData && appDelegate.itemData.isFavorite ? "★" : "☆"
                                    color: GridView.isCurrentItem
                                        ? theme.selectedText
                                        : (appDelegate.itemData && appDelegate.itemData.isFavorite ? theme.accent : theme.textVeryDim)
                                    font.pixelSize: 20
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 5
                            visible: appDelegate.itemData && appDelegate.itemData.kind === "wallpaper"

                            Image {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 130
                                Layout.maximumHeight: 160
                                property string previewUrl: appDelegate.itemData
                                    ? root.wallpaperPreviewUrl(appDelegate.itemData.path)
                                    : ""
                                source: previewUrl
                                visible: previewUrl !== ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                cache: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: appDelegate.displayName
                                color: GridView.isCurrentItem ? theme.selectedText : theme.textWhite
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: !!(appDelegate.itemData && (appDelegate.itemData.isFavorite || Number(appDelegate.itemData.usageCount) > 0))
                                text: {
                                    const parts = []
                                    if (appDelegate.itemData && appDelegate.itemData.isFavorite) parts.push("★ Избранное")
                                    if (appDelegate.itemData && Number(appDelegate.itemData.usageCount) > 0)
                                        parts.push("На " + String(appDelegate.itemData.recentScreenName || root.wallpaperSelectedScreenName) + ": " + String(appDelegate.itemData.usageCount) + " раз")
                                    return parts.join(" · ")
                                }
                                color: GridView.isCurrentItem ? theme.selectedText : theme.accent
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: String(appDelegate.itemData && appDelegate.itemData.path || "")
                                color: GridView.isCurrentItem ? theme.selectedSubtext : theme.textDim
                                font.pixelSize: 9
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            visible: appDelegate.itemData && appDelegate.itemData.kind === "wallpaper"
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            width: 30
                            height: 30
                            radius: 8
                            color: theme.surfaceAlt
                            opacity: 0.94
                            z: 2
                            Text {
                                anchors.centerIn: parent
                                text: appDelegate.itemData && appDelegate.itemData.isFavorite ? "★" : "☆"
                                color: appDelegate.itemData && appDelegate.itemData.isFavorite ? theme.accent : theme.text
                                font.pixelSize: 20
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: function(mouse) {
                                if (appDelegate.itemData
                                        && appDelegate.itemData.kind === "emoji"
                                        && mouse.x >= width - 48) {
                                    root.toggleLauncherEmojiFavorite(appDelegate.itemData.emoji)
                                    return
                                }
                                if (appDelegate.itemData
                                        && appDelegate.itemData.kind === "wallpaper"
                                        && mouse.x >= width - 46 && mouse.y <= 46) {
                                    root.toggleWallpaperFavorite(appDelegate.itemData.path)
                                    return
                                }
                                root.activateAppsSearchResult(appDelegate.itemData)
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }

                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                        height: 5
                        contentItem: Rectangle {
                            implicitHeight: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }
                        background: Rectangle { color: theme.transparent }
                    }
                }

                Text {
                    anchors.centerIn: contentArea
                    width: Math.min(implicitWidth, Math.max(0, contentArea.width - 48))
                    visible: root.mode === root.modeApps
                        && appList.count === 0
                        && root.normalizeRunText(searchField.text).startsWith("@")
                    text: "@i ID\n@c category\n@d description\n@e command\n@w WM_CLASS\n@g generic name\n@k keywords\n@t apps inside terminal"
                    color: theme.textVeryDim
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    anchors.centerIn: contentArea
                    width: Math.min(implicitWidth + 24, Math.max(0, contentArea.width - 48))
                    visible: root.mode === root.modeApps
                        && appList.count === 0
                        && !root.normalizeRunText(searchField.text).startsWith("@")
                    text: LauncherCustomActions.parseQuery(root.normalizeRunText(searchField.text)).active
                        ? "Пользовательские действия не найдены."
                        : (root.wallpaperPickerActive
                        ? LauncherWallpaperPicker.emptyStateMessage(
                            root.wallpaperCatalogLoading,
                            root.wallpaperCatalogError,
                            root.wallpaperCatalogRequestedDirectory,
                            root.wallpaperCatalogEntries.length,
                            root.activeWallpaperQuery.query,
                            root.activeWallpaperQuery.scope,
                            root.wallpaperSelectedScreenName
                        )
                        : (LauncherEmojiPicker.parseQuery(root.normalizeRunText(searchField.text).replace(/^\s*>\s*/, "")).active
                            ? LauncherEmojiPicker.emptyStateMessage(LauncherEmojiPicker.parseQuery(root.normalizeRunText(searchField.text).replace(/^\s*>\s*/, "")).scope)
                            : (appModel.desktopEntryCount === 0 && !root.normalizeRunText(searchField.text).startsWith(">")
                            ? "Системный каталог приложений пуст."
                            : (root.normalizeRunText(searchField.text) === ""
                                ? "Нет доступных приложений. Проверьте избранное и скрытые приложения."
                                : "Приложения не найдены."))))
                    color: theme.textVeryDim
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }

                /*
                 * CALCULATOR
                 */

                ListView {
                    id: calculatorList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight
                    anchors.fill: parent
                    visible: root.mode === root.modeCalculator
                    clip: true
                    spacing: 6
                    model: root.calculatorDisplayResults
                    currentIndex: count > 0 ? 0 : -1
                    header: Item {
                        width: calculatorList.width
                        height: root.normalizeRunText(searchField.text) === "" && root.calculatorHistoryEntries.length > 0 ? 36 : 0
                        visible: height > 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 8
                            Text {
                                Layout.fillWidth: true
                                text: "Recent calculations"
                                color: theme.textDim
                                font.pixelSize: 12
                            }
                            Text {
                                text: "Clear history"
                                color: theme.textVeryDim
                                font.pixelSize: 11
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.clearCalculatorHistory()
                                }
                            }
                        }
                    }

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()
                    onCountChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: calculatorDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeCalculator && root.pointerHoveredIndex === index
                        width: calculatorList.width
                        height: Config.launcherItemHeight
                        radius: Config.launcherItemRadius
                        color: ListView.isCurrentItem ? theme.itemSelected : (hovered ? theme.itemHover : theme.item)
                        border.color: ListView.isCurrentItem ? theme.borderAccent : theme.borderSubtle
                        border.width: ListView.isCurrentItem ? 0 : 0.7

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: Math.max(6, Config.launcherItemRadius - 3)
                                color: ListView.isCurrentItem ? theme.accent : theme.surface
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰃬"
                                    color: ListView.isCurrentItem ? theme.selectedText : theme.accent
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: calculatorDelegate.modelData.expression + " = " + calculatorDelegate.modelData.result
                                    color: ListView.isCurrentItem ? theme.selectedText : theme.textWhite
                                    font.pixelSize: 16
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: calculatorDelegate.modelData.kind === "calculatorHistory"
                                        ? "Recent calculation · Enter or click to reuse"
                                        : "Calculator · Enter or click to copy result"
                                    color: ListView.isCurrentItem ? theme.selectedSubtext : theme.textDim
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.activateCalculatorItem(calculatorDelegate.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: calculatorList.count === 0
                        text: root.normalizeRunText(searchField.text) === ""
                            ? "Enter an arithmetic expression"
                            : "No valid calculation"
                        color: theme.textVeryDim
                        font.pixelSize: 13
                    }
                }

                /*
                 * RUN
                 */

                ListView {
                    id: runList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent
                    visible: root.mode === root.modeRun
                    clip: true
                    spacing: 4

                    model: root.runResults

                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: runDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeRun && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        width: runList.width
                        height: Config.launcherItemHeight
                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        Behavior on color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30

                                radius: 8

                                color: ListView.isCurrentItem
                                    ? theme.accent
                                    : theme.surfaceAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: ">"
                                    color: ListView.isCurrentItem
                                        ? theme.background
                                        : theme.textMuted
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.highlightRun(
                                    runDelegate.modelData.command,
                                    searchField.text
                                )
                                textFormat: Text.StyledText
                                color: theme.text
                                font.pixelSize: 15
                                elide: Text.ElideRight
                            }

                            Text {
                                text: runDelegate.modelData.source === "history"
                                    ? "history"
                                    : "shell"
                                color: ListView.isCurrentItem
                                    ? theme.selectedSubtext
                                    : theme.textVeryDim
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                searchField.text =
                                    runDelegate.modelData.command
                                searchField.cursorPosition =
                                    searchField.text.length
                                searchField.forceActiveFocus()
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: runList.count === 0

                        text: searchField.text.trim() === ""
                            ? "Type a command..."
                            : "No matching commands"

                        color: theme.textDisabled
                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }
                }

                /*
                 * WINDOWS
                 */

                ListView {
                    id: windowList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent

                    visible: root.mode === root.modeWindows

                    clip: true

                    spacing: 6

                    model: root.windowModel

                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: windowDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeWindows && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        width: windowList.width
                        height: Config.launcherItemHeight

                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: modelData.isFocused
                            ? theme.textDisabled
                            : (ListView.isCurrentItem
                                ? theme.borderAccent
                                : theme.borderSubtle)

                        border.width:
                            modelData.isFocused && !ListView.isCurrentItem ? 1 : 0

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter

                                radius: 10

                                color: modelData.isFocused
                                    ? theme.accent
                                    : (ListView.isCurrentItem
                                        ? theme.surfaceAlt
                                        : theme.surface)

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 7

                                    source: {
                                        if (modelData.iconPath)
                                            return "file://" + modelData.iconPath

                                        return ""
                                    }

                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !modelData.iconPath
                                    text: "󰖯"
                                    color: theme.textMuted
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true

                                    text: root.highlightFuzzy(
                                        modelData.title || modelData.appId || "Untitled",
                                        searchField.text
                                    )

                                    textFormat: Text.StyledText
                                    color: ListView.isCurrentItem
                                        ? theme.selectedText
                                        : theme.textWhite
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: root.highlightFuzzy(
                                        modelData.appId || "",
                                        searchField.text
                                    )

                                    textFormat: Text.StyledText
                                    color: ListView.isCurrentItem
                                        ? theme.selectedSubtext
                                        : theme.textDim
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: {
                                        let result = ""

                                        if (modelData.workspaceId !== undefined &&
                                            modelData.workspaceId !== null) {
                                            result += "workspace " + modelData.workspaceId
                                        }

                                        if (modelData.isFloating)
                                            result += (result ? "  •  " : "") + "floating"

                                        if (modelData.isUrgent)
                                            result += (result ? "  •  " : "") + "urgent"

                                        return result
                                    }

                                    color: theme.textVeryDim
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                property int recentIndex: root.recentWindowIds.indexOf(modelData.id)
                                property bool showRecent: !modelData.isFocused && recentIndex >= 0 && recentIndex < 3

                                Layout.preferredWidth: modelData.isFocused || showRecent ? 58 : 0
                                Layout.preferredHeight: modelData.isFocused || showRecent ? 24 : 0

                                visible: modelData.isFocused || showRecent

                                radius: 8
                                color: modelData.isFocused ? theme.accent : theme.surfaceAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.isFocused ? "FOCUSED" : "RECENT"
                                    color: modelData.isFocused ? theme.background : theme.textSecondary
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.focusWindow(modelData.id)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        visible: root.mode === root.modeWindows &&
                                 windowList.count === 0

                        text: root.niriCliError !== ""
                            ? "Niri CLI unavailable (see log)"
                            : (root.normalizeWindowText(searchField.text) === ""
                                ? "No open windows"
                                : "No matching windows")

                        color: theme.textDisabled
                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }
                }

                /*
                 * CLIPBOARD
                 */

                ListView {
                    id: clipboardList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent

                    visible:
                        root.mode === root.modeClipboard

                    clip: true

                    spacing: 6

                    model: clipboardModel

                    currentIndex:
                        count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()
                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: clipboardDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeClipboard && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        width: clipboardList.width
                        height: Math.max(Config.launcherItemHeight, modelData.isImage ? 72 : 86)

                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        Behavior on color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8

                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignTop

                                radius: 8

                                color: modelData.isImage
                                    ? theme.clipboardImage
                                    : theme.clipboardText

                                Text {
                                    anchors.centerIn: parent

                                    text: modelData.isImage
                                        ? "▧"
                                        : "T"

                                    color: modelData.isImage
                                        ? theme.textClipboard
                                        : theme.textMuted

                                    font.pixelSize: 17
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true

                                    spacing: 8

                                    Text {
                                        text: modelData.isImage
                                            ? "Image"
                                            : "Text"

                                        color: theme.textMuted

                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true

                                        text: modelData.mime ||
                                              "unknown"

                                        color: theme.textVeryDim

                                        font.pixelSize: 10

                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    text: root.highlightFuzzy(
                                        modelData.preview,
                                        searchField.text
                                    )

                                    textFormat: Text.StyledText

                                    color: ListView.isCurrentItem
                                        ? theme.selectedText
                                        : theme.text

                                    font.pixelSize: 14

                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {
                                root.selectClipboard(
                                    clipboardDelegate.index
                                )
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        visible: clipboardModel.count === 0

                        text: searchField.text.trim() === ""
                            ? "Clipboard history is empty"
                            : "No matching clipboard entries"

                        color: theme.textDisabled

                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }
                }

                /*
                 * NETWORK
                 */

                ListView {
                    id: networkList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent
                    visible: root.mode === root.modeNetwork
                    clip: true
                    spacing: 4

                    model: root.networkResults
                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: networkDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeNetwork && root.pointerHoveredIndex === index

                        width: networkList.width
                        height: Config.launcherItemHeight
                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 8
                                color: ListView.isCurrentItem
                                    ? theme.accent
                                    : theme.surfaceAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.inUse ? "✓" : ""
                                    color: ListView.isCurrentItem
                                        ? theme.background
                                        : theme.textMuted
                                    font.pixelSize: 15
                                    font.family: modelData.inUse ? "sans" : theme.fontFamily
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.highlightNetwork(modelData.ssid, searchField.text)
                                    textFormat: Text.StyledText
                                    color: theme.text
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.inUse
                                        ? "Connected"
                                        : (modelData.bars || "")
                                    color: ListView.isCurrentItem
                                        ? theme.selectedSubtext
                                        : theme.textVeryDim
                                    font.pixelSize: 10
                                }
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    Layout.alignment: Qt.AlignRight
                                    text: modelData.inUse
                                        ? "CONNECTED"
                                        : (modelData.security !== "" ? "LOCK" : "OPEN")
                                    color: modelData.inUse ? theme.accent : theme.textVeryDim
                                    font.pixelSize: 9
                                }

                                Text {
                                    Layout.alignment: Qt.AlignRight
                                    text: modelData.bars || ""
                                    color: ListView.isCurrentItem ? theme.selectedSubtext : theme.textVeryDim
                                    font.pixelSize: 10
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: root.connectSelectedNetwork(networkDelegate.index)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: networkList.count === 0
                        text: Network.scanning
                            ? "Scanning..."
                            : (searchField.text.trim() === ""
                                ? "No networks found"
                                : "No matching networks")
                        color: theme.textDisabled
                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }
                }

                /*
                 * NIX PACKAGES
                 */

                ListView {
                    id: nixList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent
                    visible: root.mode === root.modeNix
                    clip: true
                    spacing: 6

                    model: root.nixResults
                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: nixDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeNix && root.pointerHoveredIndex === index

                        width: nixList.width
                        height: Math.max(Config.launcherItemHeight, modelData.description !== "" ? 72 : 58)
                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignTop
                                radius: 9
                                color: ListView.isCurrentItem
                                    ? theme.accent
                                    : theme.surfaceAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: "N"
                                    color: ListView.isCurrentItem
                                        ? theme.background
                                        : theme.textMuted
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.highlightFuzzy(
                                            modelData.name,
                                            searchField.text
                                        )
                                        textFormat: Text.StyledText
                                        color: ListView.isCurrentItem
                                            ? theme.selectedText
                                            : theme.textWhite
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.version
                                        color: ListView.isCurrentItem
                                            ? theme.selectedSubtext
                                            : theme.textDim
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: modelData.description !== ""
                                    text: modelData.description
                                    color: ListView.isCurrentItem
                                        ? theme.selectedSubtext
                                        : theme.textDim
                                    font.pixelSize: 11
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: root.addSelectedNixPackage(nixDelegate.index)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: nixList.count === 0
                        text: root.nixSearching
                            ? "Searching nixpkgs..."
                            : (root.nixSearchError !== ""
                                ? root.nixSearchError
                                : (searchField.text.trim() === ""
                                    ? "Type a package name"
                                    : "No matching packages"))
                        color: theme.textDisabled
                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }
                }

                /*
                 * PASS
                 */

                ListView {
                    id: passList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent
                    visible: root.mode === root.modePass
                    clip: true
                    spacing: 6

                    model: root.passResults
                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: passDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modePass && root.pointerHoveredIndex === index

                        width: passList.width
                        height: Config.launcherItemHeight
                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignVCenter
                                radius: 9
                                color: ListView.isCurrentItem
                                    ? theme.accent
                                    : theme.surfaceAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌆"
                                    color: ListView.isCurrentItem
                                        ? theme.background
                                        : theme.textMuted
                                    font.pixelSize: 16
                                    font.family: theme.fontFamily
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.highlightFuzzy(
                                        modelData.name,
                                        searchField.text
                                    )
                                    textFormat: Text.StyledText
                                    color: ListView.isCurrentItem
                                        ? theme.selectedText
                                        : theme.textWhite
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "Password entry"
                                    color: ListView.isCurrentItem
                                        ? theme.selectedSubtext
                                        : theme.textVeryDim
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: "COPY"
                                color: ListView.isCurrentItem
                                    ? theme.accent
                                    : theme.textVeryDim
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: root.copySelectedPass(passDelegate.index)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: passList.count === 0
                        text: root.passLoading
                            ? "Loading password store..."
                            : (root.passError !== ""
                                ? root.passError
                                : (searchField.text.trim() === ""
                                    ? "No password entries"
                                    : "No matching passwords"))
                        color: theme.textDisabled
                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5

                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }

                        background: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.transparent
                        }
                    }
                }

                /*
                 * PROJECTS — all configured repositories in one searchable list.
                 */

                ListView {
                    id: projectList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight
                    anchors.fill: parent
                    visible: root.mode === root.modeProjects
                    clip: true
                    spacing: 5
                    model: root.projectResults
                    currentIndex: count > 0 ? 0 : -1

                    onCountChanged: root.disarmPointerHover()
                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    delegate: Rectangle {
                        id: projectDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeProjects && root.pointerHoveredIndex === index

                        width: projectList.width
                        height: Config.launcherItemHeight
                        radius: Config.launcherItemRadius
                        color: ListView.isCurrentItem ? theme.itemSelected : (hovered ? theme.itemHover : theme.item)
                        border.color: ListView.isCurrentItem ? theme.borderAccent : theme.borderSubtle
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve } }
                        Behavior on border.color { ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter
                                radius: 10
                                color: ListView.isCurrentItem ? theme.accent : theme.surface

                                Text {
                                    anchors.fill: parent
                                    text: String(projectDelegate.modelData.icon || "")
                                    color: ListView.isCurrentItem ? theme.background : theme.textMuted
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.highlightProjectMatch(
                                        String(projectDelegate.modelData.name || "Без названия"),
                                        searchField.text
                                    )
                                    textFormat: Text.StyledText
                                    color: ListView.isCurrentItem ? theme.selectedText : theme.textWhite
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.highlightProjectMatch(
                                        String(projectDelegate.modelData.path || "Путь не задан"),
                                        searchField.text
                                    )
                                    textFormat: Text.StyledText
                                    color: ListView.isCurrentItem ? theme.selectedSubtext : theme.textDim
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                }
                            }

                            Text {
                                Layout.maximumWidth: 90
                                text: root.highlightProjectMatch(
                                    root.projectIdeLabel(projectDelegate.modelData.ide),
                                    searchField.text
                                )
                                textFormat: Text.StyledText
                                color: ListView.isCurrentItem ? theme.accent : theme.textVeryDim
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launchProject(projectDelegate.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: projectList.count === 0
                        text: searchField.text.trim() === "" ? "Нет настроенных проектов" : "Проекты не найдены"
                        color: theme.textDisabled
                        font.pixelSize: 15
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 5
                        contentItem: Rectangle {
                            implicitWidth: 5
                            radius: 3
                            color: theme.borderStrong
                            opacity: 0.65
                        }
                        background: Rectangle { implicitWidth: 5; radius: 3; color: theme.transparent }
                    }
                }

                /*
                 * POWER
                 */

                ListView {
                    id: powerList
                    highlightFollowsCurrentItem: false
                    highlight: launcherSelectionHighlight

                    anchors.fill: parent

                    visible:
                        root.mode === root.modePower

                    clip: true

                    spacing: 6

                    currentIndex:
                        count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: root.disarmPointerHover()

                    model: [
                        {
                            name: "Lock",
                            command:
                                "loginctl lock-session"
                        },
                        {
                            name: "Logout",
                            command:
                                "niri msg action quit"
                        },
                        {
                            name: "Reboot",
                            command:
                                "systemctl reboot"
                        },
                        {
                            name: "Shutdown",
                            command:
                                "systemctl poweroff"
                        }
                    ]

                    delegate: Rectangle {
                        id: powerDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modePower && root.pointerHoveredIndex === index

                        width: powerList.width

                        height: Config.launcherItemHeight

                        radius: Config.launcherItemRadius

                        color:
                            ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: 0

                        Behavior on color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: root.interactionAnimationDuration; easing.type: root.interactionAnimationEasing; easing.bezierCurve: root.interactionAnimationBezierCurve }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter

                            width: 34
                            height: 34
                            radius: 9

                            color: ListView.isCurrentItem
                                ? theme.accent
                                : theme.surfaceAlt

                            Text {
                                anchors.centerIn: parent

                                text: {
                                    switch (powerDelegate.modelData.name) {
                                    case "Lock": return "L"
                                    case "Logout": return "↪"
                                    case "Reboot": return "↻"
                                    case "Shutdown": return "⏻"
                                    default: return "•"
                                    }
                                }

                                color: ListView.isCurrentItem
                                    ? theme.background
                                    : theme.textMuted

                                font.pixelSize: 15
                                font.bold: true
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 58
                            anchors.verticalCenter: parent.verticalCenter

                            text: powerDelegate.modelData.name

                            color: ListView.isCurrentItem
                                ? theme.selectedText
                                : theme.textWhite

                            font.pixelSize: 16
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {
                                root.runCommand(
                                    powerDelegate
                                    .modelData.command
                                )
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy:
                            ScrollBar.AsNeeded
                    }
                }
            }

            /*
             * FOOTER
             */

            RowLayout {
                visible: Config.launcherShowNavigationHints
                Layout.fillWidth: true
                Layout.minimumHeight: 0
                Layout.preferredHeight: Config.launcherNavigationHintsHeight

                Text {
                    text: "↑ ↓  navigate"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }

                Text {
                    text: "Enter  select"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }

                Text {
                    text: "Alt+1..9, 0  tabs"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }

                Text {
                    visible: Config.launcherVimKeybinds
                    text: "Ctrl+J/N ↓  Ctrl+K/P ↑"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }

                Text {
                    visible: root.mode === root.modeRun
                    text: "Del  remove history"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: root.mode === root.modeNix
                    text: "Enter  copy   click  actions"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }

                Text {
                    text: "Esc  close"
                    color: theme.textVeryDim
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Config.launcherNavigationHintsFontSize
                    transform: Translate { y: Config.launcherNavigationHintsTextY }
                }
            }
        }
    }

    /*
     * WINDOW SEARCH / RANKING
     * Window data arrives from `niri msg -j windows` only while the Windows
     * tab is visible; filtering and ranking remain local to the launcher.
     */

    property var windowModel: []
    property var recentWindowIds: []
    property var runResults: []
    property var projectResults: []
    property int runCompletionIndex: 0
    property string runCompletionPrefix: ""

    function normalizeWindowText(text) {
        return String(text ?? "")
            .toLowerCase()
            .trim()
    }

    function fuzzyWindowScoreCore(text, query) {
        text = normalizeWindowText(text)
        query = normalizeWindowText(query)

        if (query === "")
            return 0

        if (text === query)
            return 10000

        if (text.startsWith(query))
            return 9000 - text.length

        if (text.includes(query))
            return 8000 - text.indexOf(query)

        let score = 0
        let position = 0
        let previousMatch = -1

        for (let i = 0; i < query.length; ++i) {
            const found = text.indexOf(query[i], position)

            if (found === -1)
                return -1

            if (previousMatch >= 0) {
                const gap = found - previousMatch - 1

                if (gap === 0)
                    score += 500
                else
                    score += Math.max(0, 200 - gap * 30)
            }

            if (
                found === 0 ||
                text[found - 1] === " " ||
                text[found - 1] === "-" ||
                text[found - 1] === "_" ||
                text[found - 1] === "."
            ) {
                score += 300
            }

            score += Math.max(0, 200 - found * 10)

            previousMatch = found
            position = found + 1
        }

        return score
    }

    function fuzzyWindowScore(text, query) {
        return LauncherKeyboardLayout.scoreWithLayout(
            text, query,
            function(searchText, searchQuery) {
                return root.fuzzyWindowScoreCore(searchText, searchQuery)
            }
        )
    }

    function windowRecentIndex(windowId) {
        const index = root.recentWindowIds.indexOf(windowId)
        return index >= 0 ? index : 1000000
    }

    function rememberWindowFocus(windowId) {
        if (windowId === undefined || windowId === null)
            return

        const recent = Array.isArray(root.recentWindowIds)
            ? root.recentWindowIds.slice()
            : []

        const oldIndex = recent.indexOf(windowId)
        if (oldIndex >= 0)
            recent.splice(oldIndex, 1)

        recent.unshift(windowId)

        if (recent.length > 100)
            recent.length = 100

        root.recentWindowIds = recent
    }

    function rebuildProjectsModel() {
        const source = Array.isArray(Config.launcherProjects) ? Config.launcherProjects : []
        const query = normalizeRunText(searchField.text)
        const result = []

        for (let i = 0; i < source.length; ++i) {
            const project = source[i]
            if (!project || typeof project !== "object") continue
            const searchText = [project.name, project.path, project.ide, project.icon].join(" ")
            const score = query === "" ? 0 : runFuzzyScore(searchText, query)
            if (query === "" || score >= 0) {
                result.push({
                    project: {
                        icon: String(project.icon || ""),
                        name: String(project.name || ""),
                        path: String(project.path || ""),
                        ide: String(project.ide || "")
                    },
                    score: score,
                    order: i
                })
            }
        }

        if (query !== "") {
            result.sort(function(a, b) {
                if (b.score !== a.score) return b.score - a.score
                return a.order - b.order
            })
        }
        root.projectResults = result.map(function(item) { return item.project })
        projectList.currentIndex = root.projectResults.length > 0 ? 0 : -1
    }

    function expandedProjectPath(value) {
        let path = String(value ?? "").trim()
        const home = String(Quickshell.env("HOME") || "")
        if (path === "~") return home
        if (path.indexOf("~/") === 0) return home + path.slice(1)
        if (path === "$HOME") return home
        if (path.indexOf("$HOME/") === 0) return home + path.slice(5)
        return path
    }

    function projectIdeLabel(value) {
        const ide = String(value ?? "").trim().replace(/\\/g, "/")
        if (!ide) return "IDE?"
        const parts = ide.split("/").filter(function(part) { return part !== "" })
        const executable = parts.length > 0 ? parts[parts.length - 1] : ide
        return executable.replace(/\.sh$/i, "")
    }

    function launchProject(project) {
        if (!project) return
        const ide = String(project.ide ?? "").trim()
        const path = root.expandedProjectPath(project.path)
        if (ide === "" || path === "") {
            console.warn("Launcher: project has no IDE or path:", String(project.name || ""))
            return
        }
        console.info("Launcher: launching project:", String(project.name || ""), "with", ide)
        // Pass executable and project root as separate argv values: spaces and
        // shell metacharacters in paths are never evaluated by a shell.
        Quickshell.execDetached([ide, path])
        root.hideLauncher()
    }

    function launchCurrentProject() {
        const index = projectList.currentIndex
        if (index < 0 || index >= root.projectResults.length) return
        root.launchProject(root.projectResults[index])
    }

    Connections {
        target: Config
        function onLauncherProjectsChanged() {
            if (root.mode === root.modeProjects) Qt.callLater(root.rebuildProjectsModel)
        }
    }

    function scoreWindow(window) {
        const query = normalizeWindowText(searchField.text)

        if (query === "")
            return 0

        const titleScore = fuzzyWindowScore(window.title, query)
        const appScore = fuzzyWindowScore(window.appId, query)

        return Math.max(titleScore, appScore + 100)
    }

    function refreshNiriWindows() {
        if (!root.visible || root.mode !== root.modeWindows || root.layoutEditMode)
            return
        if (!niriWindowsProcess.running) {
            root.niriCliError = ""
            root.niriWindowsGeneration += 1
            root.niriWindowsPendingGeneration = root.niriWindowsGeneration
            niriWindowsProcess.running = true
        }
    }

    function acceptNiriWindows(output) {
        const text = String(output ?? "")
        const marker = "\n__NIRI_WINDOWS_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0) return
        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration) ||
            requestGeneration !== root.niriWindowsGeneration ||
            !root.visible || root.mode !== root.modeWindows || root.layoutEditMode) {
            return
        }
        const payload = text.slice(0, markerIndex).trim()
        try {
            const parsed = JSON.parse(payload)
            if (!Array.isArray(parsed))
                throw new Error("niri windows response is not an array")

            root.niriWindows = parsed.map(function(item) {
                return {
                    id: Number(item.id),
                    title: String(item.title ?? ""),
                    appId: String(item.app_id ?? ""),
                    pid: Number(item.pid ?? -1),
                    workspaceId: item.workspace_id ?? null,
                    isFocused: Boolean(item.is_focused),
                    isFloating: Boolean(item.is_floating),
                    isUrgent: Boolean(item.is_urgent),
                    // The niri CLI does not return resolved desktop icon paths.
                    iconPath: String(item.icon_path ?? "")
                }
            }).filter(function(item) {
                return Number.isFinite(item.id)
            })

            root.niriCliError = ""
            root.rebuildWindowModel()
        } catch (error) {
            root.niriCliError = String(error)
            console.warn("Launcher: could not parse niri windows:", error)
        }
    }

    function rebuildWindowModel() {
        const query = normalizeWindowText(searchField.text)
        const result = []
        const windows = Array.isArray(root.niriWindows) ? root.niriWindows : []

        for (let i = 0; i < windows.length; ++i) {
            const window = windows[i]
            if (window && window.isFocused)
                rememberWindowFocus(window.id)
        }

        for (let i = 0; i < windows.length; ++i) {
            const item = windows[i]
            if (!item)
                continue

            const window = {
                id: item.id,
                title: item.title,
                appId: item.appId,
                pid: item.pid,
                workspaceId: item.workspaceId,
                isFocused: item.isFocused,
                isFloating: item.isFloating,
                isUrgent: item.isUrgent,
                iconPath: item.iconPath
            }

            const score = scoreWindow(window)
            const recentIndex = windowRecentIndex(window.id)

            if (query === "" || score >= 0) {
                result.push({
                    window: window,
                    score: score,
                    recentIndex: recentIndex,
                    sourceIndex: i
                })
            }
        }

        result.sort(function(a, b) {
            if (a.window.isFocused !== b.window.isFocused)
                return a.window.isFocused ? -1 : 1
            if (b.score !== a.score)
                return b.score - a.score
            if (a.recentIndex !== b.recentIndex)
                return a.recentIndex - b.recentIndex
            return a.sourceIndex - b.sourceIndex
        })

        root.windowModel = result.map(function(item) {
            return item.window
        })

        if (root.mode === root.modeWindows)
            root.selectRecentWindow()
        else
            root.resetWindowSelection()
    }

    function resetWindowSelection() {
        if (windowList.count <= 0) {
            windowList.currentIndex = -1
            return
        }

        windowList.currentIndex = 0
        windowList.positionViewAtIndex(
            0,
            ListView.Beginning
        )
    }

    // Alt+Tab-like behavior: the focused window stays at index 0,
    // while the most recently used non-focused window becomes selected.
    // With a search query we keep the normal first-match selection.
    function selectRecentWindow() {
        if (windowList.count <= 0) {
            windowList.currentIndex = -1
            return
        }

        if (normalizeWindowText(searchField.text) !== "") {
            resetWindowSelection()
            return
        }

        let targetIndex = -1

        for (let i = 0; i < windowModel.length; ++i) {
            const item = windowModel[i]
            if (item && !item.isFocused) {
                targetIndex = i
                break
            }
        }

        if (targetIndex < 0)
            targetIndex = 0

        windowList.currentIndex = targetIndex
        windowList.positionViewAtIndex(
            targetIndex,
            ListView.Beginning
        )
    }


    property var nixResults: []
    property bool nixSearching: false
    property string nixSearchError: ""
    property int nixSchema: 48
    // Monotonic request identity prevents out-of-order HTTP responses from
    // overwriting results after query edits, tab switches, or launcher close.
    property int nixSearchGeneration: 0

    Timer {
        id: nixSearchTimer
        interval: 120
        repeat: false
        onTriggered: root.searchNixPackages()
    }

    Process {
        id: nixSearchProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.finishNixSearch(this.text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const errorText = String(this.text ?? "").trim()
                if (errorText !== "")
                    console.error("Nix package search:", errorText)
            }
        }
    }

    function scheduleNixSearch() {
        // Invalidate the in-flight result immediately, before the debounce
        // timer starts the request for the new query.
        root.nixSearchGeneration += 1
        nixSearchTimer.restart()
    }

    function nixSearchUrl(schema) {
        return "https://search.nixos.org/backend/latest-" +
            schema + "-nixos-unstable/_search"
    }

    function nixSearchPayload(query) {
        const normalizedQuery = String(query || "").toLowerCase().trim()
        const queryVariants = [normalizedQuery]
        const alternateQuery = LauncherKeyboardLayout.alternateLayoutQuery(normalizedQuery)
        if (alternateQuery !== "" && alternateQuery !== normalizedQuery)
            queryVariants.push(alternateQuery)

        const fields = [
            "package_attr_name^9",
            "package_attr_name.*^5.4",
            "package_pname^6",
            "package_pname.*^3.6",
            "package_description^1.3",
            "package_longDescription^1"
        ]

        const searchQueries = []
        for (let queryIndex = 0; queryIndex < queryVariants.length; ++queryIndex) {
            const positiveWords = queryVariants[queryIndex]
                .split(/\s+/)
                .filter(word => word !== "")
            const boost = queryIndex === 0 ? 1 : 0.8

            searchQueries.push({
                multi_match: {
                    type: "cross_fields",
                    query: positiveWords.join(" "),
                    analyzer: "whitespace",
                    auto_generate_synonyms_phrase_query: false,
                    operator: "and",
                    fields: fields,
                    boost: boost
                }
            })

            for (const word of positiveWords) {
                const variants = [word]
                if (word.indexOf("-") >= 0)
                    variants.push(word.replace(/-/g, "_"))
                if (word.indexOf("_") >= 0)
                    variants.push(word.replace(/_/g, "-"))
                for (const variant of variants) {
                    if (variant !== "") {
                        searchQueries.push({
                            wildcard: {
                                "package_attr_name": {
                                    value: "*" + variant + "*",
                                    case_insensitive: true,
                                    boost: boost
                                }
                            }
                        })
                    }
                }
            }
        }

        return JSON.stringify({
            from: 0,
            size: 50,
            sort: [
                { _score: "desc" },
                { package_attr_name: "asc" }
            ],
            query: {
                bool: {
                    filter: [
                        {
                            term: {
                                type: {
                                    value: "package"
                                }
                            }
                        }
                    ],
                    must: [
                        {
                            dis_max: {
                                tie_breaker: 0.7,
                                queries: searchQueries
                            }
                        }
                    ]
                }
            }
        })
    }

    function searchNixPackages() {
        if (root.mode !== root.modeNix)
            return

        const query = String(searchField.text ?? "").trim()
        if (query === "") {
            if (nixSearchProcess.running)
                nixSearchProcess.running = false
            root.nixResults = []
            root.nixSearching = false
            root.nixSearchError = ""
            return
        }

        if (nixSearchProcess.running)
            nixSearchProcess.running = false

        const requestGeneration = root.nixSearchGeneration
        const payload = root.nixSearchPayload(query)
        // search.nixos.org uses the Bonsai Elasticsearch cluster directly.
        // The index has a wildcard version prefix, so we do not need to guess
        // a schema number. Keep this shell script newline-based: joining the
        // commands with spaces makes `for ...; do` invalid in /bin/sh.
        const script = [
            'payload=$1',
            'request_id=$2',
            'username="aWVSALXpZv"',
            'password="X8gPHnzL52wFEekuxsfQ9cSh"',
            'url="https://nixos-search-7-1733963800.us-east-1.bonsaisearch.net:443/latest-*-nixos-unstable/_search?request_cache=true"',
            'response=$(curl -sSL --max-time 10 -u "$username:$password" -H "Content-Type: application/json" -H "Accept: application/json" -X POST --data-binary "$payload" "$url" -w "\\n__STATUS__%{http_code}")',
            'status=${response##*__STATUS__}',
            'body=${response%__STATUS__*}',
            'if [ "$status" = "200" ]; then',
            '    printf "%s\\n__SCHEMA__WILDCARD\\n__REQUEST__%s" "$body" "$request_id"',
            '    exit 0',
            'fi',
            'printf "%s\\n__SCHEMA__ERROR\\n__REQUEST__%s" "${body:-{\\"error\\":\\"NixOS search backend HTTP $status\\"}}" "$request_id"'
        ].join("\n")

        nixSearchProcess.command = [
            "sh",
            "-c",
            script,
            "launcher-nix-search",
            payload,
            String(requestGeneration)
        ]

        root.nixSearching = true
        root.nixSearchError = ""
        nixSearchProcess.running = true
    }

    function finishNixSearch(output) {
        const rawOutput = String(output ?? "")
        const requestMarker = "\n__REQUEST__"
        const requestMarkerIndex = rawOutput.lastIndexOf(requestMarker)
        if (requestMarkerIndex < 0)
            return

        const completedGeneration = Number(
            rawOutput.slice(requestMarkerIndex + requestMarker.length).trim()
        )
        if (!Number.isSafeInteger(completedGeneration) ||
            completedGeneration !== root.nixSearchGeneration) {
            return
        }
        if (root.mode !== root.modeNix)
            return

        const query = String(searchField.text ?? "").trim()
        if (query === "") {
            root.nixResults = []
            root.nixSearching = false
            return
        }

        const result = []

        try {
            const responseOutput = rawOutput.slice(0, requestMarkerIndex)
            const marker = "\n__SCHEMA__"
            const markerIndex = responseOutput.lastIndexOf(marker)
            const jsonOutput = markerIndex >= 0
                ? responseOutput.slice(0, markerIndex).trim()
                : responseOutput.trim()
            const schemaMarker = markerIndex >= 0
                ? responseOutput.slice(markerIndex + marker.length).trim()
                : ""
            if (schemaMarker !== "" && schemaMarker !== "ERROR")
                root.nixSchema = Number(schemaMarker) || root.nixSchema

            const data = JSON.parse(jsonOutput || "{}")
            if (schemaMarker === "ERROR") {
                root.nixSearchError = "NixOS search backend недоступен"
            } else {
                root.nixSearchError = ""
            }
            const hits = data && data.hits && Array.isArray(data.hits.hits)
                ? data.hits.hits
                : []

            for (const hit of hits) {
                const item = hit && hit._source ? hit._source : {}
                const attr = String(item.package_attr_name || "")
                const name = String(
                    item.package_pname ||
                    attr.split(".").pop() ||
                    attr
                )
                const version = String(item.package_pversion || "")
                const description = String(
                    item.package_description ||
                    item.package_longDescription ||
                    ""
                )
                const homepageValue = item.package_homepage
                let homepage = ""
                if (typeof homepageValue === "string") {
                    homepage = homepageValue
                } else if (homepageValue && typeof homepageValue === "object") {
                    homepage = String(
                        homepageValue.url ||
                        homepageValue.homepage ||
                        ""
                    )
                }

                if (name === "")
                    continue

                result.push({
                    attr: attr,
                    name: name,
                    version: version,
                    description: description,
                    homepage: homepage,
                    position: ""
                })
            }
        } catch (error) {
            root.nixSearchError = "Ошибка ответа NixOS Search"
            console.error("Failed to parse Nix search output:", error)
        }

        // Elasticsearch can return multiple indexed entries for the same
        // package name (for example, different historical/attribute variants)
        // with identical descriptions. For the launcher UI keep one entry per
        // package name + description, preserving Elasticsearch relevance order.
        const unique = []
        const seen = new Set()

        for (const item of result) {
            const key = String(item.name || "").trim().toLowerCase() + "\u001f" +
                String(item.description || "").trim().toLowerCase()

            if (seen.has(key))
                continue

            seen.add(key)
            unique.push(item)

            if (unique.length >= 50)
                break
        }

        root.nixResults = unique
        root.nixSearching = false
        nixList.currentIndex = root.nixResults.length > 0 ? 0 : -1
    }

    function addSelectedNixPackage(index) {
        copySelectedNixPackage(index)
    }

    function openNixAddCommand() {
        // Use the user's existing shell alias/workflow. `add` opens the
        // configured home-packages.nix file through the user's `n`/`nvim`
        // aliases; no package-install logic is duplicated in the launcher.
        console.info("Launcher: opening add workflow")

        // Use a login + interactive zsh so the same startup environment and
        // aliases as the user's normal terminal are available. The user's
        // `add` alias then resolves to their existing editor workflow.
        Quickshell.execDetached([
            "foot",
            "--",
            "zsh",
            "-lic",
            "add"
        ])
        root.hideLauncher()
    }

    function copySelectedNixPackage(index) {
        const selectedIndex = index === undefined
            ? nixList.currentIndex
            : index

        if (selectedIndex < 0 || selectedIndex >= root.nixResults.length)
            return

        const packageName = String(root.nixResults[selectedIndex].name || "").trim()
        const description = String(root.nixResults[selectedIndex].description || "")
            .replace(/[\r\n]+/g, " ")
            .replace(/\s+/g, " ")
            .trim()

        if (packageName === "")
            return

        const clipboardText = description !== ""
            ? packageName + " # " + description
            : packageName

        Quickshell.execDetached([
            "sh",
            "-c",
            "printf '%s' \"$1\" | wl-copy",
            "launcher-nix-copy",
            clipboardText
        ])

        root.hideLauncher()
    }

    function openNixHomepage(index) {
        const selectedIndex = index === undefined ? nixList.currentIndex : index
        if (selectedIndex < 0 || selectedIndex >= root.nixResults.length)
            return
        const url = String(root.nixResults[selectedIndex].homepage || "").trim()
        if (url !== "")
            Quickshell.execDetached(["xdg-open", url])
    }

    function openNixSource(index) {
        const selectedIndex = index === undefined ? nixList.currentIndex : index
        if (selectedIndex < 0 || selectedIndex >= root.nixResults.length)
            return

        const attr = String(root.nixResults[selectedIndex].attr || "").trim()
        if (attr === "")
            return

        const url = "https://search.nixos.org/packages?channel=unstable&show=" +
            encodeURIComponent(attr)
        Quickshell.execDetached(["xdg-open", url])
    }

    /*
     * PASS PASSWORD STORE
     */

    property var passEntries: []
    property var passResults: []
    property bool passLoading: false
    property string passError: ""
    property int passGeneration: 0
    property int passPendingGeneration: -1

    Process {
        id: passListProcess

        command: [
            "sh",
            "-c",
            [
                'store="${PASSWORD_STORE_DIR:-$HOME/.password-store}"',
                'if ! command -v pass >/dev/null 2>&1; then',
                "  printf '__PASS_ERROR__pass is not installed\n'",
                'elif [ ! -d "$store" ]; then',
                "  printf '__PASS_ERROR__password store not found: %s\n' \"$store\"",
                'else',
                "  find \"$store\" -type f -name '*.gpg' -printf '%P\\n' | sed 's/\\.gpg$//'",
                'fi',
                'printf "\\n__PASS_REQUEST__%s\\n" "$1"'
            ].join("\n"),
            "launcher-pass-list",
            String(root.passPendingGeneration)
        ]

        stdout: StdioCollector {
            onStreamFinished: root.finishPassEntries(this.text)
        }
    }

    function loadPassEntries() {
        if (!root.visible || root.mode !== root.modePass || root.layoutEditMode)
            return
        root.passGeneration += 1
        root.passPendingGeneration = root.passGeneration
        root.passError = ""
        root.passLoading = true

        if (passListProcess.running)
            passListProcess.running = false
        passListProcess.running = true
    }

    function finishPassEntries(output) {
        const text = String(output ?? "")
        const marker = "\n__PASS_REQUEST__"
        const markerIndex = text.lastIndexOf(marker)
        if (markerIndex < 0) return
        const requestGeneration = Number(text.slice(markerIndex + marker.length).trim())
        if (!Number.isFinite(requestGeneration) ||
            requestGeneration !== root.passGeneration ||
            !root.visible || root.mode !== root.modePass || root.layoutEditMode) {
            return
        }
        const lines = text.slice(0, markerIndex).split("\n")
        const entries = []
        const seen = {}
        let explicitError = ""

        for (const line of lines) {
            const raw = line.trim()

            if (raw === "")
                continue

            if (raw.indexOf("__PASS_ERROR__") === 0) {
                explicitError = raw.substring("__PASS_ERROR__".length).trim()
                continue
            }

            if (seen[raw])
                continue

            seen[raw] = true
            entries.push(raw)
        }

        root.passEntries = entries
        root.passLoading = false
        root.passError = explicitError

        if (entries.length === 0 && explicitError === "" && root.mode === root.modePass) {
            root.passError = "Password store contains no .gpg entries"
        }

        root.rebuildPassModel()
    }

    function rebuildPassModel() {
        const query = normalizeWindowText(searchField.text)
        const result = []

        for (let i = 0; i < root.passEntries.length; ++i) {
            const name = root.passEntries[i]
            const score = query === "" ? 0 : fuzzyWindowScore(name, query)

            if (query === "" || score >= 0) {
                result.push({
                    name: name,
                    score: score,
                    order: i
                })
            }
        }

        result.sort(function(a, b) {
            if (query !== "" && b.score !== a.score)
                return b.score - a.score

            return a.order - b.order
        })

        root.passResults = result.map(function(item) {
            return { name: item.name }
        })

        passList.currentIndex = root.passResults.length > 0 ? 0 : -1
    }

    function copySelectedPass(index) {
        const selectedIndex = index === undefined
            ? passList.currentIndex
            : index

        if (selectedIndex < 0 || selectedIndex >= root.passResults.length)
            return

        const entry = String(root.passResults[selectedIndex].name || "").trim()

        if (entry === "")
            return

        // Let pass itself handle GPG decryption and clipboard integration.
        // The plaintext password never enters QML, JS strings, or logs.
        Quickshell.execDetached([
            "pass",
            "show",
            "-c",
            "--",
            entry
        ])

        root.hideLauncher()
    }

    property var networkResults: []

    function fuzzyNetworkScoreCore(text, query) {
        text = String(text ?? "").toLowerCase()
        query = String(query ?? "").toLowerCase().trim()

        if (query === "") return 0
        if (text === query) return 10000
        if (text.startsWith(query)) return 9000 - text.length
        if (text.includes(query)) return 8000 - text.indexOf(query)

        let score = 0
        let position = 0
        let previous = -1
        for (let i = 0; i < query.length; ++i) {
            const found = text.indexOf(query[i], position)
            if (found === -1) return -1
            if (previous >= 0) {
                const gap = found - previous - 1
                score += gap === 0 ? 500 : Math.max(0, 200 - gap * 30)
            }
            score += Math.max(0, 200 - found * 10)
            previous = found
            position = found + 1
        }
        return score
    }

    function fuzzyNetworkScore(text, query) {
        return LauncherKeyboardLayout.scoreWithLayout(
            text, query,
            function(searchText, searchQuery) {
                return root.fuzzyNetworkScoreCore(searchText, searchQuery)
            }
        )
    }

    function rebuildNetworkModel() {
        const query = String(searchField.text ?? "").toLowerCase().trim()
        const result = []

        for (const network of Network.networks || []) {
            const score = fuzzyNetworkScore(network.ssid, query)
            if (query === "" || score >= 0) {
                result.push({
                    network: network,
                    score: score + (network.inUse ? 1000 : 0)
                })
            }
        }

        result.sort(function(a, b) {
            if (b.score !== a.score) return b.score - a.score
            return String(a.network.ssid).localeCompare(String(b.network.ssid))
        })

        root.networkResults = result.map(function(item) { return item.network })
        networkList.currentIndex = root.networkResults.length > 0 ? 0 : -1
    }

    function connectSelectedNetwork(index) {
        if (index < 0 || index >= root.networkResults.length) return

        const network = root.networkResults[index]
        Network.connectTo(network.ssid)
        Network.refresh()
        root.hideLauncher()
    }

    function highlightNetwork(text, query) {
        const value = String(text ?? "")
        const q = LauncherKeyboardLayout.bestMatchingQuery(
            value, query,
            function(searchText, searchQuery) {
                return root.fuzzyNetworkScoreCore(searchText, searchQuery)
            }
        )
        if (q === "") return root.escapeHtml(value)

        let result = ""
        let pos = 0
        const lower = value.toLowerCase()
        const lowerQ = q.toLowerCase()
        for (const ch of lowerQ) {
            const found = lower.indexOf(ch, pos)
            if (found === -1) return root.escapeHtml(value)
            result += root.escapeHtml(value.slice(pos, found))
            result += "<b><font color=\"" + theme.accent + "\">" + root.escapeHtml(value[found]) + "</font></b>"
            pos = found + 1
        }
        result += root.escapeHtml(value.slice(pos))
        return result
    }

    Connections {
        target: Network
        function onNetworksChanged() {
            if (root.mode === root.modeNetwork)
                Qt.callLater(root.rebuildNetworkModel)
        }
    }

    /*
     * RUN HISTORY / COMPLETION
     */

    function normalizeRunText(text) {
        return String(text ?? "")
            .toLowerCase()
            .trim()
    }

    function expandedWallpaperDirectory() {
        const configured = String(Config.launcherWallpaperDirectory || "").trim()
        if (configured === "")
            return Quickshell.env("HOME") + "/Pictures/Wallpapers"
        const home = String(Quickshell.env("HOME") || "")
        if (configured === "~") return home
        if (configured.startsWith("~/")) return home + "/" + configured.slice(2)
        if (configured === "$HOME") return home
        if (configured.startsWith("$HOME/")) return home + "/" + configured.slice(6)
        if (configured.startsWith("/")) return configured
        return home !== "" ? home + "/" + configured : configured
    }

    function wallpaperPreviewUrl(path) {
        // The shared helper rejects empty paths, directories, relative paths,
        // and unsupported extensions before a QQuickImage sees the URL.
        return LauncherWallpaperPicker.localFileUrl(path)
    }

    function runFuzzyScore(text, query) {
        return LauncherSearchScoring.fuzzyScore(text, query, true)
    }

    function loadRunCommands(output) {
        runCompletionModel.clear()

        const lines = String(output ?? "").split("\n")
        const seen = {}

        for (const line of lines) {
            const command = line.trim()

            if (command === "" || seen[command])
                continue

            seen[command] = true

            runCompletionModel.append({
                command: command
            })
        }

        if (root.mode === root.modeRun)
            root.rebuildRunModel()
    }

    function rebuildRunModel() {
        const query = normalizeRunText(searchField.text)
        const result = []
        const seen = {}

        // History is always available and gets priority over shell completion.
        for (let i = 0; i < runHistoryModel.count; ++i) {
            const item = runHistoryModel.get(i)
            const command = item.command
            const score = runFuzzyScore(command, query)

            if (query === "" || score >= 0) {
                result.push({
                    command: command,
                    source: "history",
                    score: score + 1000,
                    order: i
                })
                seen[command] = true
            }
        }

        // When searching, also show commands and aliases from the user's Zsh.
        // This is what makes entries such as alias "add=..." discoverable by
        // fuzzy queries like "dd".
        if (query !== "") {
            for (let i = 0; i < runCompletionModel.count; ++i) {
                const command = runCompletionModel.get(i).command
                if (seen[command])
                    continue

                const score = runFuzzyScore(command, query)
                if (score >= 0) {
                    result.push({
                        command: command,
                        source: "shell",
                        score: score,
                        order: i
                    })
                }
            }
        }

        result.sort(function(a, b) {
            if (b.score !== a.score)
                return b.score - a.score

            return a.order - b.order
        })

        root.runResults = result.map(function(item) {
            return {
                command: item.command,
                source: item.source
            }
        })

        runList.currentIndex =
            root.runResults.length > 0 ? 0 : -1
    }

    function saveRunCommand(command) {
        command = String(command ?? "").trim()

        if (command === "")
            return

        Quickshell.execDetached([
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\"; " +
            "touch \"$HOME/.cache/quickshell-launcher-run-history\"; " +
            "grep -Fxq -- \"$1\" \"$HOME/.cache/quickshell-launcher-run-history\" " +
            "&& { grep -Fxv -- \"$1\" \"$HOME/.cache/quickshell-launcher-run-history\" > " +
            "\"$HOME/.cache/quickshell-launcher-run-history.tmp\"; " +
            "mv \"$HOME/.cache/quickshell-launcher-run-history.tmp\" " +
            "\"$HOME/.cache/quickshell-launcher-run-history\"; } || true; " +
            "printf '%s\\n' \"$1\" >> \"$HOME/.cache/quickshell-launcher-run-history\"; " +
            "tail -n 100 \"$HOME/.cache/quickshell-launcher-run-history\" > " +
            "\"$HOME/.cache/quickshell-launcher-run-history.tmp\"; " +
            "mv \"$HOME/.cache/quickshell-launcher-run-history.tmp\" " +
            "\"$HOME/.cache/quickshell-launcher-run-history\"",
            "launcher-run-history",
            command
        ])

        root.rememberRunCommand(command)
    }

    function completeRun() {
        const current = searchField.text
        const trimmed = current.trim()

        if (trimmed === "") {
            if (runHistoryModel.count > 0) {
                searchField.text =
                    runHistoryModel.get(0).command
                searchField.cursorPosition =
                    searchField.text.length
            }
            return
        }

        const firstSpace = current.indexOf(" ")
        const prefix = firstSpace >= 0
            ? current.slice(0, firstSpace)
            : current

        const lowerPrefix = prefix.toLowerCase()
        const candidates = []

        for (let i = 0; i < runHistoryModel.count; ++i) {
            const command = runHistoryModel.get(i).command

            if (
                command.toLowerCase().startsWith(
                    lowerPrefix
                )
            ) {
                candidates.push(command)
            }
        }

        for (let i = 0; i < runCompletionModel.count; ++i) {
            const command = runCompletionModel.get(i).command

            if (
                command.toLowerCase().startsWith(
                    lowerPrefix
                ) &&
                candidates.indexOf(command) < 0
            ) {
                candidates.push(command)
            }
        }

        if (candidates.length === 0)
            return

        const currentCommand =
            firstSpace >= 0 ? prefix : current

        const currentIndex =
            candidates.indexOf(currentCommand)

        const selected =
            candidates[
                currentIndex >= 0
                    ? (currentIndex + 1) % candidates.length
                    : 0
            ]

        searchField.text =
            firstSpace >= 0
                ? selected + current.slice(firstSpace)
                : selected

        searchField.cursorPosition =
            searchField.text.length

        rebuildRunModel()
    }

    function highlightRun(text, query) {
        return highlightFuzzy(text, query)
    }

    /*
     * FUNCTIONS
     */

    function escapeHtml(text) {
        return String(text ?? "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
    }

    // Highlights fuzzy matches field-by-field. Query words are matched
    // independently so searches spanning name/path/IDE still show which
    // visible parts contributed to a project's match.
    function highlightProjectMatch(text, query) {
        text = String(text ?? "")
        const queryText = LauncherKeyboardLayout.bestMatchingQuery(
            text, query,
            function(searchText, searchQuery) {
                return LauncherSearchScoring.fuzzyScoreNative(searchText, searchQuery, true)
            }
        )
        if (queryText === "")
            return root.escapeHtml(text)

        const lower = text.toLowerCase()
        const highlighted = []
        for (let i = 0; i < text.length; ++i)
            highlighted.push(false)
        const tokens = queryText.split(/\s+/).filter(function(token) {
            return token !== ""
        })

        for (const token of tokens) {
            let position = 0
            const tokenMatches = []

            for (let i = 0; i < token.length; ++i) {
                const found = lower.indexOf(token[i], position)
                if (found === -1) {
                    tokenMatches.length = 0
                    break
                }
                tokenMatches.push(found)
                position = found + 1
            }

            // Only color a word when the entire token matches this field;
            // the overall search can still match tokens in different fields.
            if (tokenMatches.length === token.length) {
                for (const index of tokenMatches)
                    highlighted[index] = true
            }
        }

        let result = ""
        for (let i = 0; i < text.length; ++i) {
            const character = root.escapeHtml(text[i])
            if (highlighted[i]) {
                result += "<b><font color=\"" + theme.accent + "\">" +
                          character + "</font></b>"
            } else {
                result += character
            }
        }
        return result
    }

    function highlightFuzzy(text, query) {
        text = String(text ?? "")
        query = LauncherKeyboardLayout.bestMatchingQuery(
            text, query,
            function(searchText, searchQuery) {
                return LauncherSearchScoring.fuzzyScoreNative(searchText, searchQuery, true)
            }
        )

        if (query === "")
            return escapeHtml(text)

        const lower = text.toLowerCase()
        const matches = []
        let position = 0

        for (let i = 0; i < query.length; ++i) {
            const found = lower.indexOf(query[i], position)

            if (found === -1)
                return escapeHtml(text)

            matches.push(found)
            position = found + 1
        }

        let result = ""
        let matchIndex = 0

        for (let i = 0; i < text.length; ++i) {
            const character = escapeHtml(text[i])

            if (
                matchIndex < matches.length &&
                matches[matchIndex] === i
            ) {
                result += "<b><font color=\"" + theme.accent + "\">" +
                          character +
                          "</font></b>"
                matchIndex++
            } else {
                result += character
            }
        }

        return result
    }

    function rememberAppLaunch(entry) {
        if (!entry || !entry.name)
            return

        Quickshell.execDetached([
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && " +
            "printf '%s\\n' \"$1\" >> \"$HOME/.cache/quickshell-app-history\"",
            "launcher-app-history",
            entry.name
        ])

        // Update the in-memory ranking immediately, so the next open already
        // reflects the application that was just launched.
        const counts = Object.assign({}, appModel.usageCounts)
        counts[entry.name] = (counts[entry.name] || 0) + 1
        appModel.usageCounts = counts

        // Keep the in-memory recent list in sync immediately.
        const recent = Array.isArray(appModel.recentApplications)
            ? appModel.recentApplications.slice()
            : []
        const oldIndex = recent.indexOf(entry.name)
        if (oldIndex >= 0)
            recent.splice(oldIndex, 1)
        recent.unshift(entry.name)
        appModel.recentApplications = recent
    }

    function launchEntry(entry) {
        if (!entry)
            return

        console.info(
            "Launcher: launching:",
            entry.name
        )

        rememberAppLaunch(entry)
        entry.execute()
        root.hideLauncher()
    }

    function launchCurrent() {
        const index = appList.currentIndex
        if (index < 0 || index >= root.appsUnifiedResults.length)
            return
        root.activateAppsSearchResult(root.appsUnifiedResults[index])
    }

    function focusWindow(windowId) {
        const numericId = Number(windowId)
        if (!Number.isSafeInteger(numericId) || numericId <= 0) {
            console.warn("Launcher: invalid Niri window id:", windowId)
            return
        }

        if (niriFocusProcess.running) {
            console.warn("Launcher: another focus-window action is still running")
            return
        }

        rememberWindowFocus(numericId)
        root.pendingFocusWindowId = String(numericId)
        root.pendingFocusInteractionGeneration = root.launcherInteractionGeneration
        niriFocusProcess.running = true
    }

    function focusCurrentWindow() {
        if (windowList.currentIndex < 0 ||
            windowList.currentIndex >= windowModel.length)
            return

        const item = windowModel[windowList.currentIndex]

        if (!item || item.id === undefined)
            return

        focusWindow(item.id)
    }

    function runNeedsTerminal(command) {
        const text = String(command ?? "").trim()
        if (text === "")
            return false

        const first = text.split(/\s+/)[0]
            .replace(/^.*\//, "")
            .toLowerCase()

        return [
            "fastfetch", "btop", "htop", "top", "bpytop",
            "vim", "nvim", "vi", "nano", "micro",
            "less", "more", "man", "watch", "ssh", "mosh",
            "tmux", "screen", "fzf", "yazi", "ranger",
            "lazygit", "ncdu", "cava"
        ].indexOf(first) >= 0
    }

    function runCommand(command) {
        command = String(command ?? "").trim()

        if (!command)
            return

        console.info(
            "Launcher: executing:",
            command
        )

        root.rememberRunCommand(command)

        // Let Zsh resolve aliases recursively.  This handles chains such as:
        //   add -> n -> nvim
        // before deciding whether a real terminal is required.  The command
        // itself is still executed as the original user input, so aliases,
        // functions and .zshrc remain in control.
        const ttyCommands = [
            "fastfetch", "btop", "htop", "top", "bpytop",
            "vim", "nvim", "vi", "nano", "micro",
            "less", "more", "man", "watch", "ssh", "mosh",
            "tmux", "screen", "fzf", "yazi", "ranger",
            "lazygit", "ncdu", "cava"
        ].join(" ")

        const script =
            'cmd="$1"; ' +
            'name="${cmd%%[[:space:]]*}"; ' +
            'name="${name##*/}"; ' +
            'for i in {1..16}; do ' +
                'if [[ -n "${aliases[$name]-}" ]]; then ' +
                    'cmd="${aliases[$name]} ${cmd#*[[:space:]]}"; ' +
                    'name="${cmd%%[[:space:]]*}"; ' +
                    'name="${name##*/}"; ' +
                'else break; fi; ' +
            'done; ' +
            'case " ' + ttyCommands + ' " in *" $name "*) ' +
                // Keep the terminal open after one-shot TTY commands such
                // as fastfetch finish, leaving the result visible and a shell
                // prompt ready for the next command.
                'exec foot -- zsh -ic "$1; exec zsh -i" ;; ' +
            '*) eval "$1" ;; ' +
            'esac'

        Quickshell.execDetached([
            "zsh",
            "-ic",
            script,
            "launcher-run",
            command
        ])

        root.hideLauncher()
    }

    function moveSelectionDown() {

        if (root.mode === root.modeApps && root.wallpaperPickerActive) {
            root.moveWallpaperSelection("down")
            return
        }

        switch (root.mode) {

        case root.modeApps:

            if (appList.count > 0) {
                appList.currentIndex =
                    Math.min(
                        appList.currentIndex + 1,
                        appList.count - 1
                    )

                appList.positionViewAtIndex(
                    appList.currentIndex,
                    GridView.Contain
                )
            }

            break

        case root.modeRun:

            if (runList.count > 0) {
                runList.currentIndex =
                    Math.min(
                        runList.currentIndex + 1,
                        runList.count - 1
                    )

                runList.positionViewAtIndex(
                    runList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modeWindows:

            root.moveWindowSelection(
                1
            )

            break

        case root.modeNetwork:

            if (networkList.count > 0) {
                networkList.currentIndex =
                    Math.min(networkList.currentIndex + 1, networkList.count - 1)
                networkList.positionViewAtIndex(networkList.currentIndex, ListView.Contain)
            }

            break

        case root.modeNix:

            if (nixList.count > 0) {
                nixList.currentIndex =
                    Math.min(nixList.currentIndex + 1, nixList.count - 1)
                nixList.positionViewAtIndex(nixList.currentIndex, ListView.Contain)
            }

            break

        case root.modePass:

            if (passList.count > 0) {
                passList.currentIndex =
                    Math.min(passList.currentIndex + 1, passList.count - 1)
                passList.positionViewAtIndex(passList.currentIndex, ListView.Contain)
            }

            break

        case root.modeClipboard:

            if (clipboardList.count > 0) {
                clipboardList.currentIndex =
                    Math.min(
                        clipboardList.currentIndex + 1,
                        clipboardList.count - 1
                    )

                clipboardList.positionViewAtIndex(
                    clipboardList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modeCalculator:

            if (calculatorList.count > 0)
                calculatorList.currentIndex = 0
            break

        case root.modeProjects:

            if (projectList.count > 0) {
                projectList.currentIndex = Math.min(projectList.currentIndex + 1, projectList.count - 1)
                projectList.positionViewAtIndex(projectList.currentIndex, ListView.Contain)
            }

            break

        case root.modePower:

            if (powerList.count > 0) {
                powerList.currentIndex =
                    Math.min(
                        powerList.currentIndex + 1,
                        powerList.count - 1
                    )

                powerList.positionViewAtIndex(
                    powerList.currentIndex,
                    ListView.Contain
                )
            }

            break
        }
    }

    function moveSelectionUp() {

        if (root.mode === root.modeApps && root.wallpaperPickerActive) {
            root.moveWallpaperSelection("up")
            return
        }

        switch (root.mode) {

        case root.modeApps:

            if (appList.count > 0) {
                appList.currentIndex =
                    Math.max(
                        appList.currentIndex - 1,
                        0
                    )

                appList.positionViewAtIndex(
                    appList.currentIndex,
                    GridView.Contain
                )
            }

            break

        case root.modeRun:

            if (runList.count > 0) {
                runList.currentIndex =
                    Math.max(
                        runList.currentIndex - 1,
                        0
                    )

                runList.positionViewAtIndex(
                    runList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modeWindows:

            root.moveWindowSelection(
                -1
            )

            break

        case root.modeNetwork:

            if (networkList.count > 0) {
                networkList.currentIndex =
                    Math.max(networkList.currentIndex - 1, 0)
                networkList.positionViewAtIndex(
                    networkList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modeNix:

            if (nixList.count > 0) {
                nixList.currentIndex =
                    Math.max(nixList.currentIndex - 1, 0)
                nixList.positionViewAtIndex(
                    nixList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modePass:

            if (passList.count > 0) {
                passList.currentIndex =
                    Math.max(passList.currentIndex - 1, 0)
                passList.positionViewAtIndex(
                    passList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modeClipboard:

            if (clipboardList.count > 0) {
                clipboardList.currentIndex =
                    Math.max(
                        clipboardList.currentIndex - 1,
                        0
                    )

                clipboardList.positionViewAtIndex(
                    clipboardList.currentIndex,
                    ListView.Contain
                )
            }

            break

        case root.modeCalculator:

            if (calculatorList.count > 0)
                calculatorList.currentIndex = 0
            break

        case root.modeProjects:

            if (projectList.count > 0) {
                projectList.currentIndex = Math.max(projectList.currentIndex - 1, 0)
                projectList.positionViewAtIndex(projectList.currentIndex, ListView.Contain)
            }

            break

        case root.modePower:

            if (powerList.count > 0) {
                powerList.currentIndex =
                    Math.max(
                        powerList.currentIndex - 1,
                        0
                    )

                powerList.positionViewAtIndex(
                    powerList.currentIndex,
                    ListView.Contain
                )
            }

            break
        }
    }

    /*
     * Навигация Windows.
     * Здесь все элементы уже отфильтрованы и отсортированы.
     */

    function moveWindowSelection(direction) {
        const count = windowList.count

        if (count <= 0)
            return

        let index = windowList.currentIndex

        if (index < 0)
            index = direction > 0 ? 0 : count - 1
        else
            index = Math.max(
                0,
                Math.min(count - 1, index + direction)
            )

        windowList.currentIndex = index
        windowList.positionViewAtIndex(
            index,
            ListView.Contain
        )
    }

    function nextMode() {
        const tabs = root.displayedModeTabs
        if (!tabs || tabs.length === 0) return
        let index = -1
        for (let i = 0; i < tabs.length; ++i) {
            if (tabs[i].mode === root.mode) { index = i; break }
        }
        root.setMode(tabs[index < 0 ? 0 : (index + 1) % tabs.length].mode)
    }

    function previousMode() {
        const tabs = root.displayedModeTabs
        if (!tabs || tabs.length === 0) return
        let index = -1
        for (let i = 0; i < tabs.length; ++i) {
            if (tabs[i].mode === root.mode) { index = i; break }
        }
        root.setMode(tabs[index < 0 ? tabs.length - 1 : (index + tabs.length - 1) % tabs.length].mode)
    }

    function resetSelection() {

        if (appList.count > 0)
            appList.currentIndex = 0
        else
            appList.currentIndex = -1

        if (runList.count > 0)
            runList.currentIndex = 0
        else
            runList.currentIndex = -1

        /*
         * Для Windows учитываем поиск.
         */

        if (root.mode === root.modeWindows)
            root.selectRecentWindow()
        else if (windowList.count > 0)
            windowList.currentIndex = 0
        else
            windowList.currentIndex = -1

        if (networkList.count > 0)
            networkList.currentIndex = 0
        else
            networkList.currentIndex = -1

        if (nixList.count > 0)
            nixList.currentIndex = 0
        else
            nixList.currentIndex = -1

        if (passList.count > 0)
            passList.currentIndex = 0
        else
            passList.currentIndex = -1

        if (projectList.count > 0)
            projectList.currentIndex = 0
        else
            projectList.currentIndex = -1

        if (powerList.count > 0)
            powerList.currentIndex = 0
        else
            powerList.currentIndex = -1

        calculatorList.currentIndex = calculatorList.count > 0 ? 0 : -1
    }

    function activate() {

        switch (root.mode) {

        case root.modeApps:

            launchCurrent()

            break

        case root.modeRun:

            // In Run mode Enter always executes exactly what is in the
            // search field. A command shown in history is only a suggestion.
            // Clicking a history entry puts it into the search field first,
            // so it can be edited before pressing Enter.
            runCommand(searchField.text)

            break

        case root.modeWindows:

            focusCurrentWindow()

            break

        case root.modeClipboard:

            root.selectClipboard(
                clipboardList.currentIndex
            )

            break

        case root.modeNetwork:

            root.connectSelectedNetwork(networkList.currentIndex)

            break

        case root.modeNix:

            root.copySelectedNixPackage()

            break

        case root.modePass:

            root.copySelectedPass()

            break

        case root.modeProjects:

            root.launchCurrentProject()

            break

        case root.modeCalculator:

            if (calculatorList.currentIndex >= 0 && calculatorList.currentIndex < root.calculatorDisplayResults.length)
                root.activateCalculatorItem(root.calculatorDisplayResults[calculatorList.currentIndex])

            break

        case root.modePower:

            if (powerList.currentItem) {
                runCommand(
                    powerList.currentItem
                    .modelData
                    .command
                )
            }

            break
        }
    }

    Component.onCompleted: {
        loadRunHistoryFromDisk()
        loadCalculatorHistoryFromDisk()
        loadEmojiPickerDataFromDisk()
        loadWallpaperPickerDataFromDisk()
        appModel.refreshUsageHistory()
        resetSelection()
    }

    // Blur only behind the launcher card, never across the dimming backdrop.
    BackgroundEffect.blurRegion: Region {
        item: Settings.moduleBlurEnabled.launcher === true ? launcherBox : null
        radius: Math.max(0, Config.backgroundBlurRadius)
    }
}
