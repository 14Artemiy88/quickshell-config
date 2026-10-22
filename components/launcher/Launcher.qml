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


PanelWindow {
    id: root

    Theme { id: theme }

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

    color: theme.transparent

    property int mode: modeApps
    property bool layoutEditMode: false
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
    property bool pointerInsideLauncher: false
    property int pointerHoveredMode: -1
    property int pointerHoveredIndex: -1

    onModeChanged: modeHoverRefreshTimer.restart()

    Timer {
        id: modeHoverRefreshTimer
        interval: 20
        repeat: false
        onTriggered: root.refreshHoverForMode()
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

    readonly property var allModeTabs: [
        { id: 0, icon: "󰀻", label: "Apps", mode: root.modeApps },
        { id: 1, icon: "", label: "Run", mode: root.modeRun },
        { id: 2, icon: "󰖯", label: "Windows", mode: root.modeWindows },
        { id: 3, icon: "󰅇", label: "Clipboard", mode: root.modeClipboard },
        { id: 4, icon: "", label: "Power", mode: root.modePower },
        { id: 5, icon: "󰖩", label: "Network", mode: root.modeNetwork },
        { id: 6, icon: "󱄅", label: "Packages", mode: root.modeNix },
        { id: 7, icon: "󰌋", label: "Pass", mode: root.modePass },
        { id: 8, icon: "", label: "Projects", mode: root.modeProjects }
    ]

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

    property string currentModeName: {
        switch (mode) {
        case modeApps:
            return "Apps"
        case modeRun:
            return "Run"
        case modeWindows:
            return "Windows"
        case modeClipboard:
            return "Clipboard"
        case modePower:
            return "Power"
        case modeNetwork:
            return "Network"
        case modeNix:
            return "Nix"
        case modePass:
            return "Pass"
        case modeProjects:
            return "Projects"
        default:
            return "Apps"
        }
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
        default: return 0
        }
    }

    function configuredDefaultMode() {
        const value = Number(Config.launcherDefaultMode)
        if (!isFinite(value) || value < 0 || value > 8)
            return root.modeApps
        const modeValue = Math.round(value)
        const visibility = Config.launcherTabVisible instanceof Array ? Config.launcherTabVisible : []
        if (visibility[modeValue] === false) {
            const firstVisible = root.displayedModeTabs.length > 0 ? root.displayedModeTabs[0] : null
            return firstVisible ? firstVisible.mode : root.modeApps
        }
        return modeValue
    }

    function showLauncher() {
        root.visible = true
        root.setMode(root.configuredDefaultMode())
    }

    function hideLauncher() {
        // Keep the query while switching tabs, but start fresh after closing the launcher.
        searchField.text = ""
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
        default: return root.modeApps
        }
    }

    // Entry point called by the host shell's IpcHandler. This keeps one
    // Quickshell process and lets Niri bind a separate key to every mode.
    function openMode(modeName) {
        const requestedMode = root.modeFromName(modeName)
        root.visible = true
        root.setMode(requestedMode)
    }

    function setMode(newMode) {
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
        default: return null
        }
    }

    function setPointerHoveredItem(modeValue, indexValue) {
        if (root.mode !== modeValue)
            return
        root.pointerHoveredMode = modeValue
        root.pointerHoveredIndex = indexValue
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

    function refreshHoverForMode() {
        if (!root.visible || !root.pointerInsideLauncher) {
            root.pointerHoveredMode = -1
            root.pointerHoveredIndex = -1
            return
        }
        const activeList = root.activeListForMode(root.mode)
        const hoveredIndex = root.pointerIndexForList(activeList)
        root.pointerHoveredMode = hoveredIndex >= 0 ? root.mode : -1
        root.pointerHoveredIndex = hoveredIndex
        // When a tab changes under a stationary pointer, select the item now
        // beneath it. Later keyboard movement remains independent of hover.
        if (hoveredIndex >= 0)
            activeList.currentIndex = hoveredIndex
    }

    function refreshHoverVisualsForMode() {
        if (!root.visible || !root.pointerInsideLauncher) {
            root.pointerHoveredMode = -1
            root.pointerHoveredIndex = -1
            return
        }
        const activeList = root.activeListForMode(root.mode)
        const hoveredIndex = root.pointerIndexForList(activeList)
        root.pointerHoveredMode = hoveredIndex >= 0 ? root.mode : -1
        root.pointerHoveredIndex = hoveredIndex
    }

    // Window discovery uses the niri CLI so the launcher has no hard QML
    // dependency on the external Niri 0.1 plugin. These processes only run
    // while the Windows tab is open.
    property var niriWindows: []
    property string pendingFocusWindowId: ""
    property string niriCliError: ""

    Process {
        id: niriWindowsProcess
        command: ["zsh", "-ic", "niri msg -j windows"]

        stdout: StdioCollector {
            onStreamFinished: root.acceptNiriWindows(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = String(this.text ?? "").trim()
                if (message !== "")
                    root.niriCliError = message
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                if (root.niriCliError === "")
                    root.niriCliError = "niri msg -j windows exited with code " + exitCode
                console.warn("Launcher: window list unavailable:", root.niriCliError)
                root.niriWindows = []
                root.rebuildWindowModel()
            }
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
                root.hideLauncher()
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
     * RUN HISTORY
     */

    ListModel {
        id: runHistoryModel
    }

    ListModel {
        id: runCompletionModel
    }

    property var runHistoryEntries: []
    property string runHistoryFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-run-history"

    Process {
        id: runHistoryProcess

        command: [
            "sh",
            "-c",
            "cat -- \"$1\" 2>/dev/null",
            "launcher-history",
            root.runHistoryFile
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.loadRunHistory(this.text)
            }
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

    function loadRunHistory(output) {
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

        root.runHistoryEntries = entries
        root.rebuildRunHistoryModel()
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

        runHistoryProcess.running = true
    }

    function persistRunHistory() {
        const data = root.runHistoryEntries.join("\n")

        Quickshell.execDetached([
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && " +
            "printf '%s\\n' \"$2\" > \"$1.tmp\" && " +
            "mv \"$1.tmp\" \"$1\"",
            "launcher-history-rewrite",
            root.runHistoryFile,
            data
        ])
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
        root.runHistoryEntries = entries
        root.rebuildRunHistoryModel()
        root.rebuildRunModel()
        root.persistRunHistory()
    }

    function clearRunHistory() {
        root.runHistoryEntries = []
        root.rebuildRunHistoryModel()
        root.rebuildRunModel()
        root.persistRunHistory()
    }

    function rememberRunCommand(command) {
        command = String(command ?? "").trim()

        if (command === "")
            return

        const entries = [command]

        for (const oldCommand of root.runHistoryEntries) {
            if (oldCommand !== command)
                entries.push(oldCommand)

            if (entries.length >= 100)
                break
        }

        root.runHistoryEntries = entries
        root.rebuildRunHistoryModel()

        // The command is passed as $1, so shell metacharacters inside the
        // actual command are not interpreted by this shell invocation.
        Quickshell.execDetached([
            "sh",
            "-c",
            "mkdir -p \"$HOME/.cache\" && " +
            "printf '%s\n' \"$2\" >> \"$1\" && " +
            "tail -n 100 \"$1\" > \"$1.tmp\" && " +
            "mv \"$1.tmp\" \"$1\"",
            "launcher-history-write",
            root.runHistoryFile,
            command
        ])
    }

    property var appsUnifiedResults: root.buildAppsUnifiedResults()

    function buildAppsUnifiedResults() {
        const query = root.normalizeRunText(searchField.text)
        const results = []
        const applications = appModel.applications || []

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

        if (query === "")
            return results

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

        if (query !== "") {
            // Rank all result types together. AppModel's relative order is
            // preserved for equal-ranked app entries; a project/command can
            // only rise above an app when its own match is more relevant.
            const kindRank = { app: 0, project: 1, run: 2 }
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

    Process {
        id: clipboardProcess

        command: [
            "cliphist",
            "list",
            "-fields",
            "id,mime,preview"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.clipboardOutput = this.text
                root.updateClipboardModel(this.text)
            }
        }
    }

    function updateClipboardModel(output) {
        clipboardModel.clear()

        const lines = String(output ?? "").split("\n")
        const query = searchField
            ? searchField.text.toLowerCase().trim()
            : ""

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
                !searchable.includes(query)
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
            "printf '%s\n' \"$1\" | cliphist decode | wl-copy",
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
            "printf '%s\n' \"$1\" | cliphist delete",
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
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
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

            onPointChanged: {
                root.trackedPointerX = point.position.x
                root.trackedPointerY = point.position.y
                root.refreshHoverVisualsForMode()
            }

            onHoveredChanged: {
                root.pointerInsideLauncher = hovered
                if (hovered) {
                    root.trackedPointerX = point.position.x
                    root.trackedPointerY = point.position.y
                } else {
                    root.pointerHoveredMode = -1
                    root.pointerHoveredIndex = -1
                }
                root.refreshHoverVisualsForMode()
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

                spacing: 6

                Repeater {
                    model: root.displayedModeTabs

                    delegate: Rectangle {
                        id: modeButton
                        required property var modelData

                        width: 38
                        height: 32
                        radius: 8
                        color: theme.transparent
                        border.color: root.mode === modelData.mode
                            ? theme.borderAccent
                            : theme.transparent
                        border.width: root.mode === modelData.mode ? 1 : 0

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }

                        ToolTip.text: modelData.label
                        ToolTip.visible: modeMouse.containsMouse
                        ToolTip.delay: 450

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: root.mode === modelData.mode
                                ? theme.textWhite
                                : theme.modeNormalText
                            font.family: theme.iconFontFamily
                            font.pixelSize: 17
                        }

                        MouseArea {
                            id: modeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.setMode(modelData.mode)
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
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
                    ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
                }


                TextField {
                    id: searchField

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
                            return "Search applications..."

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

                        // Alt+1..9 follow the visible tab order. Explicit IPC
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

                ListView {
                    id: appList

                    anchors.fill: parent

                    visible: root.mode === root.modeApps

                    clip: true

                    spacing: 6

                    model: root.appsUnifiedResults

                    currentIndex: count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

                    delegate: Rectangle {
                        id: appDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeApps && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        width: appList.width
                        height: Config.launcherItemHeight

                        radius: Config.launcherItemRadius

                        color: ListView.isCurrentItem
                            ? theme.itemSelected
                            : (hovered ? theme.itemHover : theme.item)

                        border.color: ListView.isCurrentItem
                            ? theme.borderAccent
                            : theme.borderSubtle
                        border.width: ListView.isCurrentItem ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }

                        property var itemData: modelData
                        property var entry: itemData && itemData.kind === "app" ? itemData.entry : null
                        property string displayName: itemData && itemData.kind === "project"
                            ? String(itemData.project.name || "")
                            : (itemData && itemData.kind === "run" ? String(itemData.command || "") : String(entry && entry.name || ""))
                        property string displaySubtitle: itemData && itemData.kind === "project"
                            ? ("ПРОЕКТ · " + String(itemData.project.path || ""))
                            : (itemData && itemData.kind === "run" ? "КОМАНДА · сохранённая" : String(entry && (entry.genericName || entry.comment) || ""))

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

                                color: ListView.isCurrentItem
                                    ? theme.accent
                                    : (appDelegate.hovered
                                        ? theme.surfaceAlt
                                        : theme.surface)

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Image {
                                    id: appIconImage

                                    anchors.fill: parent
                                    anchors.margins: 7

                                    // Resolve the desktop-entry icon before loading it.
                                    // Missing theme icons (for example, rofi or jockey)
                                    // then produce an empty source instead of a Qt warning.
                                    source: appDelegate.entry && appDelegate.entry.icon
                                        ? Quickshell.iconPath(String(appDelegate.entry.icon))
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

                                    property color glyphColor: ListView.isCurrentItem ? theme.selectedText : theme.textMuted

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
                                        color: ListView.isCurrentItem ? theme.accent : theme.surface
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
                                    color: ListView.isCurrentItem ? theme.selectedText : theme.textMuted
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

                                    property color glyphColor: ListView.isCurrentItem ? theme.selectedText : theme.textMuted

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
                                        && appDelegate.itemData.kind === "app"
                                    text: "󰀻"
                                    color: ListView.isCurrentItem ? theme.selectedText : theme.textMuted
                                    font.family: theme.iconFontFamily
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 2

                                Text {
                                    Layout.fillWidth: true

                                    text: root.highlightFuzzy(
                                        appDelegate.displayName,
                                        searchField.text
                                    )

                                    textFormat: Text.StyledText
                                    color: ListView.isCurrentItem
                                        ? theme.selectedText
                                        : theme.textWhite

                                    font.pixelSize: 16

                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: appDelegate.displaySubtitle

                                    color: ListView.isCurrentItem
                                        ? theme.selectedSubtext
                                        : theme.textDim

                                    font.pixelSize: 12

                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onEntered: {
                                root.setPointerHoveredItem(root.modeApps, appDelegate.index)
                                appList.currentIndex = appDelegate.index
                            }

                            onClicked: root.activateAppsSearchResult(appDelegate.itemData)
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
                }

                /*
                 * RUN
                 */

                ListView {
                    id: runList

                    anchors.fill: parent
                    visible: root.mode === root.modeRun
                    clip: true
                    spacing: 4

                    model: root.runResults

                    currentIndex: count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

                    delegate: Rectangle {
                        id: runDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeRun && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
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
                        border.width: ListView.isCurrentItem ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
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

                            onEntered: {
                                root.setPointerHoveredItem(root.modeRun, runDelegate.index)
                                runList.currentIndex = runDelegate.index
                            }

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

                    anchors.fill: parent

                    visible: root.mode === root.modeWindows

                    clip: true

                    spacing: 6

                    model: root.windowModel

                    currentIndex: count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

                    delegate: Rectangle {
                        id: windowDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeWindows && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
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
                            modelData.isFocused || ListView.isCurrentItem ? 1 : 0

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

                            onEntered: {
                                root.setPointerHoveredItem(root.modeWindows, windowDelegate.index)
                                windowList.currentIndex = windowDelegate.index
                            }

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

                    anchors.fill: parent

                    visible:
                        root.mode === root.modeClipboard

                    clip: true

                    spacing: 6

                    model: clipboardModel

                    currentIndex:
                        count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

                    delegate: Rectangle {
                        id: clipboardDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: root.pointerHoveredMode === root.modeClipboard && root.pointerHoveredIndex === index

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
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
                        border.width: ListView.isCurrentItem ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
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

                            onEntered: {
                                root.setPointerHoveredItem(root.modeClipboard, clipboardDelegate.index)
                                clipboardList.currentIndex = clipboardDelegate.index
                            }

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

                    anchors.fill: parent
                    visible: root.mode === root.modeNetwork
                    clip: true
                    spacing: 4

                    model: root.networkResults
                    currentIndex: count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

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
                        border.width: ListView.isCurrentItem ? 1 : 0

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

                            onEntered: {
                                root.setPointerHoveredItem(root.modeNetwork, networkDelegate.index)
                                networkList.currentIndex = networkDelegate.index
                            }

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

                    anchors.fill: parent
                    visible: root.mode === root.modeNix
                    clip: true
                    spacing: 6

                    model: root.nixResults
                    currentIndex: count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

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
                        border.width: ListView.isCurrentItem ? 1 : 0

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

                            onEntered: {
                                root.setPointerHoveredItem(root.modeNix, nixDelegate.index)
                                nixList.currentIndex = nixDelegate.index
                            }

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

                    anchors.fill: parent
                    visible: root.mode === root.modePass
                    clip: true
                    spacing: 6

                    model: root.passResults
                    currentIndex: count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

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
                        border.width: ListView.isCurrentItem ? 1 : 0

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

                            onEntered: {
                                root.setPointerHoveredItem(root.modePass, passDelegate.index)
                                passList.currentIndex = passDelegate.index
                            }

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
                    anchors.fill: parent
                    visible: root.mode === root.modeProjects
                    clip: true
                    spacing: 5
                    model: root.projectResults
                    currentIndex: count > 0 ? 0 : -1
                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

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
                        border.width: ListView.isCurrentItem ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

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
                            onEntered: {
                                root.setPointerHoveredItem(root.modeProjects, projectDelegate.index)
                                projectList.currentIndex = projectDelegate.index
                            }
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

                    anchors.fill: parent

                    visible:
                        root.mode === root.modePower

                    clip: true

                    spacing: 6

                    currentIndex:
                        count > 0 ? 0 : -1

                    onCurrentIndexChanged: Qt.callLater(root.refreshHoverVisualsForMode)
                    onContentYChanged: Qt.callLater(root.refreshHoverVisualsForMode)

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
                        border.width: ListView.isCurrentItem ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
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

                            onEntered: {
                                root.setPointerHoveredItem(root.modePower, powerDelegate.index)
                                powerList.currentIndex = powerDelegate.index
                            }

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
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                Text {
                    text: "↑ ↓  navigate"
                    color: theme.textVeryDim
                    font.pixelSize: 11
                }

                Text {
                    text: "Enter  select"
                    color: theme.textVeryDim
                    font.pixelSize: 11
                }

                Text {
                    text: "Alt+1..9  tabs"
                    color: theme.textVeryDim
                    font.pixelSize: 11
                }

                Text {
                    visible: root.mode === root.modeRun
                    text: "Del  remove history"
                    color: theme.textVeryDim
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: root.mode === root.modeNix
                    text: "Enter  copy   click  actions"
                    color: theme.textVeryDim
                    font.pixelSize: 11
                }

                Text {
                    text: "Esc  close"
                    color: theme.textVeryDim
                    font.pixelSize: 11
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

    function fuzzyWindowScore(text, query) {
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
        if (!root.visible || root.mode !== root.modeWindows)
            return
        if (!niriWindowsProcess.running) {
            root.niriCliError = ""
            niriWindowsProcess.running = true
        }
    }

    function acceptNiriWindows(output) {
        try {
            const parsed = JSON.parse(String(output ?? "").trim())
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
        nixSearchTimer.restart()
    }

    function nixSearchUrl(schema) {
        return "https://search.nixos.org/backend/latest-" +
            schema + "-nixos-unstable/_search"
    }

    function nixSearchPayload(query) {
        const positiveWords = String(query || "")
            .toLowerCase()
            .split(/\s+/)
            .filter(word => word !== "")

        const wildcardQueries = []
        for (const word of positiveWords) {
            const variants = [word]
            if (word.indexOf("-") >= 0)
                variants.push(word.replace(/-/g, "_"))
            if (word.indexOf("_") >= 0)
                variants.push(word.replace(/_/g, "-"))
            for (const variant of variants) {
                if (variant !== "")
                    wildcardQueries.push({
                        wildcard: {
                            "package_attr_name": {
                                value: "*" + variant + "*",
                                case_insensitive: true
                            }
                        }
                    })
            }
        }

        const fields = [
            "package_attr_name^9",
            "package_attr_name.*^5.4",
            "package_pname^6",
            "package_pname.*^3.6",
            "package_description^1.3",
            "package_longDescription^1"
        ]

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
                                queries: [
                                    {
                                        multi_match: {
                                            type: "cross_fields",
                                            query: positiveWords.join(" "),
                                            analyzer: "whitespace",
                                            auto_generate_synonyms_phrase_query: false,
                                            operator: "and",
                                            fields: fields
                                        }
                                    },
                                    ...wildcardQueries
                                ]
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
            root.nixResults = []
            root.nixSearching = false
            root.nixSearchError = ""
            return
        }

        if (nixSearchProcess.running)
            nixSearchProcess.running = false

        const payload = root.nixSearchPayload(query)
        // search.nixos.org uses the Bonsai Elasticsearch cluster directly.
        // The index has a wildcard version prefix, so we do not need to guess
        // a schema number. Keep this shell script newline-based: joining the
        // commands with spaces makes `for ...; do` invalid in /bin/sh.
        const script = [
            'payload=$1',
            'username="aWVSALXpZv"',
            'password="X8gPHnzL52wFEekuxsfQ9cSh"',
            'url="https://nixos-search-7-1733963800.us-east-1.bonsaisearch.net:443/latest-*-nixos-unstable/_search?request_cache=true"',
            'response=$(curl -sSL --max-time 10 -u "$username:$password" -H "Content-Type: application/json" -H "Accept: application/json" -X POST --data-binary "$payload" "$url" -w "\\n__STATUS__%{http_code}")',
            'status=${response##*__STATUS__}',
            'body=${response%__STATUS__*}',
            'if [ "$status" = "200" ]; then',
            '    printf "%s\\n__SCHEMA__WILDCARD" "$body"',
            '    exit 0',
            'fi',
            'printf "%s\\n__SCHEMA__ERROR" "${body:-{\\"error\\":\\"NixOS search backend HTTP $status\\"}}"'
        ].join("\n")

        nixSearchProcess.command = [
            "sh",
            "-c",
            script,
            "launcher-nix-search",
            payload
        ]

        root.nixSearching = true
        root.nixSearchError = ""
        nixSearchProcess.running = true
    }

    function finishNixSearch(output) {
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
            const rawOutput = String(output ?? "")
            const marker = "\n__SCHEMA__"
            const markerIndex = rawOutput.lastIndexOf(marker)
            const jsonOutput = markerIndex >= 0
                ? rawOutput.slice(0, markerIndex).trim()
                : rawOutput.trim()
            const schemaMarker = markerIndex >= 0
                ? rawOutput.slice(markerIndex + marker.length).trim()
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
                'fi'
            ].join("\n"),
            "launcher-pass-list"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.finishPassEntries(this.text)
            }
        }
    }

    function loadPassEntries() {
        root.passError = ""
        root.passLoading = true

        passListProcess.running = false
        passListProcess.running = true
    }

    function finishPassEntries(output) {
        const lines = String(output ?? "").split("\n")
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

    function fuzzyNetworkScore(text, query) {
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
        const q = String(query ?? "").trim()
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

    function runFuzzyScore(text, query) {
        text = normalizeRunText(text)
        query = normalizeRunText(query)

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
                score += gap === 0
                    ? 500
                    : Math.max(0, 200 - gap * 30)
            }

            if (
                found === 0 ||
                text[found - 1] === " " ||
                text[found - 1] === "/" ||
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
        const queryText = String(query ?? "").toLowerCase().trim()
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
        query = normalizeWindowText(query)

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
            "printf '%s\n' \"$1\" >> \"$HOME/.cache/quickshell-app-history\"",
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
                    ListView.Contain
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
                    ListView.Contain
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
        appModel.refreshUsageHistory()
        resetSelection()
    }
}
