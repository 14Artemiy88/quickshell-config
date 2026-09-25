import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Niri 0.1
import qs.modules.common
import "./theme"


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
    focusable: true

    color: theme.transparent

    property int mode: modeApps

    readonly property int modeApps: 0
    readonly property int modeRun: 1
    readonly property int modeWindows: 2
    readonly property int modeClipboard: 3
    readonly property int modePower: 4
    readonly property int modeNetwork: 5
    readonly property int modeNix: 6

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
        default: return 0
        }
    }

    function showLauncher() {
        root.visible = true
        root.mode = root.modeApps
        searchField.clear()
        root.resetSelection()
        searchField.forceActiveFocus()
    }

    function hideLauncher() {
        root.visible = false
    }

    function toggleLauncher() {
        if (root.visible)
            hideLauncher()
        else
            showLauncher()
    }

    function setMode(newMode) {
        root.mode = newMode


        searchField.clear()
        root.resetSelection()

        if (root.mode === root.modeRun) {
            root.rebuildRunHistoryModel()
            root.rebuildRunModel()
            if (!runCommandsProcess.running && runCompletionModel.count === 0)
                runCommandsProcess.running = true
        }

        if (root.mode === root.modeWindows) {
            Qt.callLater(function() {
                root.rebuildWindowModel()
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

        searchField.forceActiveFocus()
    }

    // Reuse the Niri connection owned by the main shell.
    property var niriBackend: null

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

        Qt.quit()
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

        color: theme.backdrop
        opacity: theme.backdropOpacity

        MouseArea {
            anchors.fill: parent

            onClicked: {
                Qt.quit()
            }
        }
    }

    /*
     * LAUNCHER
     */

    Rectangle {
        id: launcherBox

        anchors.centerIn: parent

        width: 720
        height: 640

        radius: 22

        property bool entranceReady: false
        scale: entranceReady ? 1.0 : 0.97
        opacity: entranceReady ? 1.0 : 0.0

        Translate {
            id: entranceTranslate
            y: entranceReady ? 0 : 10

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

        color: theme.background

        border.color: theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
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
                    text: "LAUNCHER"
                    color: theme.textWhite
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
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
                    model: [
                        {
                            name: "1  Apps",
                            mode: root.modeApps
                        },
                        {
                            name: "2  Run",
                            mode: root.modeRun
                        },
                        {
                            name: "3  Windows",
                            mode: root.modeWindows
                        },
                        {
                            name: "4  Clipboard",
                            mode: root.modeClipboard
                        },
                        {
                            name: "5  Power",
                            mode: root.modePower
                        },
                        {
                            name: "6  Network",
                            mode: root.modeNetwork
                        },
                        {
                            name: "7  Nix",
                            mode: root.modeNix
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: modeText.implicitWidth + 24
                        height: 32

                        radius: 8

                        color: root.mode === modelData.mode
                            ? theme.modeSelected
                            : theme.modeNormal

                        border.color: root.mode === modelData.mode
                            ? theme.borderAccent
                            : theme.borderSubtle

                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }

                        Text {
                            id: modeText

                            anchors.centerIn: parent

                            text: modelData.name

                            color: root.mode === modelData.mode
                                ? theme.textWhite
                                : theme.modeNormalText

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.setMode(modelData.mode)
                            }
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
                Layout.fillWidth: true

                height: 58

                radius: 14

                color: theme.surface

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

                    font.pixelSize: 17

                    placeholderText: {
                        switch (root.mode) {
                        case root.modeApps:
                            return "Search applications..."

                        case root.modeRun:
                            return "Run command..."

                        case root.modeWindows:
                            return "Search windows..."

                        case root.modeClipboard:
                            return "Search clipboard..."

                        case root.modePower:
                            return "Power..."

                        case root.modeNetwork:
                            return "Search networks..."

                        case root.modeNix:
                            return "Search Nix packages..."

                        default:
                            return ""
                        }
                    }

                    placeholderTextColor: theme.textVeryDim

                    selectByMouse: true

                    echoMode: TextInput.Normal

                    Keys.priority: Keys.BeforeItem

                    // Handle Return/Enter before TextField consumes the key.
                    // in some QtQuick Controls versions. Use accepted as the
                    // canonical submit signal so Run executes the command
                    // from the search field instead of the selected result.
                    onAccepted: {
                        if (root.mode === root.modeRun) {
                            root.runCommand(searchField.text)
                        } else {
                            root.activate()
                        }
                    }

                    Keys.onReturnPressed: function(event) {
                        if (root.mode === root.modeRun) {
                            root.runCommand(searchField.text)
                            event.accepted = true
                        } else {
                            root.activate()
                            event.accepted = true
                        }
                    }

                    Keys.onEnterPressed: function(event) {
                        if (root.mode === root.modeRun) {
                            root.runCommand(searchField.text)
                            event.accepted = true
                        } else {
                            root.activate()
                            event.accepted = true
                        }
                    }

                    Keys.onPressed: function(event) {

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

                        /*
                         * CTRL+1..7 — direct mode switching.
                         */

                        if (event.modifiers & Qt.ControlModifier) {
                            // On some keyboard layouts Qt reports Ctrl+number
                            // as the shifted symbol key (for example ! instead
                            // of 1). Accept both forms so the shortcuts work
                            // regardless of the active layout.
                            let shortcutMode = -1

                            switch (event.key) {
                            case Qt.Key_1:
                            case Qt.Key_Exclam:
                                shortcutMode = root.modeApps
                                break
                            case Qt.Key_2:
                            case Qt.Key_At:
                                shortcutMode = root.modeRun
                                break
                            case Qt.Key_3:
                            case Qt.Key_NumberSign:
                                shortcutMode = root.modeWindows
                                break
                            case Qt.Key_4:
                            case Qt.Key_Dollar:
                                shortcutMode = root.modeClipboard
                                break
                            case Qt.Key_5:
                            case Qt.Key_Percent:
                                shortcutMode = root.modePower
                                break
                            case Qt.Key_6:
                            case Qt.Key_AsciiCircum:
                                shortcutMode = root.modeNetwork
                                break
                            case Qt.Key_7:
                            case Qt.Key_Ampersand:
                                shortcutMode = root.modeNix
                                break
                            }

                            if (shortcutMode >= 0) {
                                root.setMode(shortcutMode)
                                event.accepted = true
                                return
                            }
                        }

                        /*
                         * ALT+A/R/W/C/P/N — direct mode switching by
                         * the first letter of the tab name.
                         */
                        if (event.modifiers & Qt.AltModifier) {
                            let shortcutMode = -1

                            switch (event.key) {
                            case Qt.Key_A:
                                shortcutMode = root.modeApps
                                break
                            case Qt.Key_R:
                                shortcutMode = root.modeRun
                                break
                            case Qt.Key_W:
                                shortcutMode = root.modeWindows
                                break
                            case Qt.Key_C:
                                shortcutMode = root.modeClipboard
                                break
                            case Qt.Key_P:
                                shortcutMode = root.modeNix
                                break
                            case Qt.Key_N:
                                shortcutMode = root.modeNetwork
                                break
                            }

                            if (shortcutMode >= 0) {
                                root.setMode(shortcutMode)
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

                    model: appModel.applications

                    currentIndex: count > 0 ? 0 : -1

                    delegate: Rectangle {
                        id: appDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: false

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        width: appList.width
                        height: 56

                        radius: 12

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

                        property var entry: modelData

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
                                    anchors.fill: parent
                                    anchors.margins: 7

                                    source: {
                                        if (appDelegate.entry.icon)
                                            return "image://icon/" +
                                                   appDelegate.entry.icon

                                        return ""
                                    }

                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 2

                                Text {
                                    Layout.fillWidth: true

                                    text: root.highlightFuzzy(
                                        appDelegate.entry.name,
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

                                    text: {
                                        if (
                                            appDelegate.entry.genericName
                                        ) {
                                            return appDelegate.entry.genericName
                                        }

                                        if (
                                            appDelegate.entry.comment
                                        ) {
                                            return appDelegate.entry.comment
                                        }

                                        return ""
                                    }

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
                                appDelegate.hovered = true
                                appList.currentIndex =
                                    appDelegate.index
                            }

                            onExited: {
                                appDelegate.hovered = false
                            }

                            onClicked: {
                                root.launchEntry(
                                    appDelegate.entry
                                )
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

                    delegate: Rectangle {
                        id: runDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: false

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        width: runList.width
                        height: 52
                        radius: 11

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
                                runDelegate.hovered = true
                                runList.currentIndex =
                                    runDelegate.index
                            }

                            onExited: {
                                runDelegate.hovered = false
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

                    delegate: Rectangle {
                        id: windowDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: false

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        width: windowList.width
                        height: 62

                        radius: 12

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
                                property int recentIndex: root.windowRecentIds.indexOf(modelData.id)
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
                                windowDelegate.hovered = true
                                windowList.currentIndex = windowDelegate.index

                            }

                            onExited: {
                                windowDelegate.hovered = false
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

                        text: root.normalizeWindowText(searchField.text) === ""
                            ? "No open windows"
                            : "No matching windows"

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

                    delegate: Rectangle {
                        id: clipboardDelegate

                        required property var modelData
                        required property int index
                        property bool hovered: false

                        scale: ListView.isCurrentItem ? 1.0 : (hovered ? 0.998 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                        }

                        width: clipboardList.width
                        height: modelData.isImage ? 72 : 86

                        radius: 12

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
                                clipboardDelegate.hovered = true
                                clipboardList.currentIndex =
                                    clipboardDelegate.index
                            }

                            onExited: {
                                clipboardDelegate.hovered = false
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

                    delegate: Rectangle {
                        id: networkDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: false

                        width: networkList.width
                        height: 52
                        radius: 11

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
                                networkDelegate.hovered = true
                                networkList.currentIndex = networkDelegate.index
                            }

                            onExited: networkDelegate.hovered = false

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

                    delegate: Rectangle {
                        id: nixDelegate
                        required property var modelData
                        required property int index
                        property bool hovered: false

                        width: nixList.width
                        height: modelData.description !== "" ? 72 : 58
                        radius: 11

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
                                nixDelegate.hovered = true
                                nixList.currentIndex = nixDelegate.index
                            }

                            onExited: nixDelegate.hovered = false

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
                        property bool hovered: false

                        width: powerList.width

                        height: 52

                        radius: 11

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
                                powerDelegate.hovered = true
                                powerList.currentIndex =
                                    powerDelegate.index
                            }

                            onExited: {
                                powerDelegate.hovered = false
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
                    text: "Tab  mode"
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
     *
     * niri.windows остаётся исходным QAbstractListModel.
     * Скрытые delegates больше не используются для фильтрации.
     * Сначала собираем окна, затем строим обычный JS-массив
     * только из подходящих и отсортированных результатов.
     */

    property var windowModel: []
    property var recentWindowIds: []
    property var runResults: []
    property int runCompletionIndex: 0
    property string runCompletionPrefix: ""

    Repeater {
        id: windowSource

        model: root.mode === root.modeWindows ? niriBackend.windows : null

        delegate: Item {
            required property int index
            required property var id
            required property string title
            required property string appId
            required property int pid
            required property var workspaceId
            required property bool isFocused
            required property bool isFloating
            required property bool isUrgent
            required property string iconPath
        }
    }

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

    function scoreWindow(window) {
        const query = normalizeWindowText(searchField.text)

        if (query === "")
            return 0

        const titleScore = fuzzyWindowScore(window.title, query)
        const appScore = fuzzyWindowScore(window.appId, query)

        return Math.max(titleScore, appScore + 100)
    }

    function rebuildWindowModel() {
        const query = normalizeWindowText(searchField.text)
        const result = []

        for (let i = 0; i < windowSource.count; ++i) {
            const item = windowSource.itemAt(i)
            if (item && item.isFocused)
                rememberWindowFocus(item.id)
        }

        for (let i = 0; i < windowSource.count; ++i) {
            const item = windowSource.itemAt(i)
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

    Connections {
        target: niriBackend ? niriBackend.windows : null

        function onRowsInserted() {
            Qt.callLater(root.rebuildWindowModel)
        }

        function onRowsRemoved() {
            Qt.callLater(root.rebuildWindowModel)
        }

        function onDataChanged() {
            Qt.callLater(root.rebuildWindowModel)
        }

        function onModelReset() {
            Qt.callLater(root.rebuildWindowModel)
        }
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
        Quickshell.execDetached([
            "foot",
            "--",
            "zsh",
            "-ic",
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
        if (!appList.currentItem)
            return

        launchEntry(
            appList.currentItem.entry
        )
    }

    function focusWindow(windowId) {
        if (!niriBackend || !niriBackend.isConnected()) {
            console.error(
                "Launcher: niri is not connected"
            )

            return
        }

        rememberWindowFocus(windowId)

        console.info(
            "Launcher: focusing window:",
            windowId
        )

        const result =
            niriBackend.focusWindow(
                windowId
            )

        if (!result.ok) {
            console.error(
                "Launcher: failed to focus window:",
                result.error
            )

            return
        }

        root.hideLauncher()
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
                'exec foot -- zsh -ic "$1" ;; ' +
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
        root.setMode((root.mode + 1) % 7)
    }

    function previousMode() {
        root.setMode((root.mode + 6) % 7)
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
