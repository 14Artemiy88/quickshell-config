pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// One in-memory view of the existing calendar-notes.json source. Calendar and
// Dashboard consume the same object so edits are immediately visible without
// introducing another file or starting a second reader process per widget.
Item {
    id: root

    property var entries: ({})
    property bool loaded: false
    property date now: new Date()

    function dateKeyForOffset(dayOffset) {
        const target = new Date(now.getFullYear(), now.getMonth(), now.getDate() + Number(dayOffset || 0))
        return String(target.getFullYear()) + "-"
            + String(target.getMonth() + 1).padStart(2, "0") + "-"
            + String(target.getDate()).padStart(2, "0")
    }

    readonly property string todayKey: dateKeyForOffset(0)
    readonly property string tomorrowKey: dateKeyForOffset(1)
    readonly property string todayNote: String(entries && entries[todayKey] !== undefined
        ? entries[todayKey] : "")
    readonly property string tomorrowNote: String(entries && entries[tomorrowKey] !== undefined
        ? entries[tomorrowKey] : "")

    function setFromJson(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}").trim() || "{}")
            root.entries = parsed && typeof parsed === "object" && !Array.isArray(parsed)
                ? parsed : ({})
        } catch (e) {
            root.entries = ({})
        }
        root.loaded = true
    }

    function setNote(key, text) {
        const dateKey = String(key || "")
        if (!/^\d{4}-\d{2}-\d{2}$/.test(dateKey)) return false

        const value = text === undefined || text === null ? "" : String(text)
        const next = Object.assign({}, root.entries || ({}))
        if (value.trim().length > 0)
            next[dateKey] = value
        else
            delete next[dateKey]
        root.entries = next

        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/calendar_notes",
            "set",
            dateKey,
            value.trim().length > 0 ? value : ""
        ])
        return true
    }

    Process {
        id: notesRead
        command: [Quickshell.shellDir + "/scripts/calendar_notes", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.setFromJson(this.text)
        }
        onExited: function(exitCode) {
            if (exitCode !== 0 && !root.loaded)
                root.setFromJson("{}")
        }
    }

    // Keep the local calendar date current while the shell remains open. This
    // lets consumers switch to the new day's note at midnight without polling
    // the storage script or creating another notes data source.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
