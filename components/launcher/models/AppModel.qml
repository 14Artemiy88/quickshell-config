import Quickshell
import Quickshell.Io
import QtQuick
import "../../../"
import "../../../js/launcher/LauncherAppSearch.js" as LauncherAppSearch
import "../../../js/launcher/LauncherAppPreferences.js" as LauncherAppPreferences

Item {
    id: root

    property string query: ""

    // Bind directly to the live ObjectModel values. Quickshell documents this
    // as the reactive list view: it updates when DesktopEntries inserts or
    // removes application entries, without taking a one-time JS snapshot.
    readonly property int desktopEntryCount: DesktopEntries.applications.values.length

    readonly property var specialSearch: LauncherAppSearch.parseSpecialQuery(root.query)
    readonly property bool fuzzySearchEnabled: Config.launcherFuzzySearchApps !== false

    // How many applications to show when there is no search query.
    property int emptyQueryLimit: 8

    // Application launch counts, keyed by application name.
    property var usageCounts: ({})

    // Most recently launched applications, newest first.
    property var recentApplications: []
    readonly property var favoriteAppIds: LauncherAppPreferences.normalizeIds(Config.launcherFavoriteApps || [])
    readonly property var hiddenAppIds: LauncherAppPreferences.normalizeIds(Config.launcherHiddenApps || [])

    // Categories are discovered from installed desktop entries and exposed
    // only for the bare `@c` browser in the Apps result list.
    readonly property var availableCategories: LauncherAppSearch.collectCategories(
        DesktopEntries.applications.values || [], root.hiddenAppIds
    )

    Process {
        id: usageHistoryProcess

        command: [
            "bash",
            "-lc",
            "cat \"$HOME/.cache/quickshell-app-history\" 2>/dev/null || true"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const counts = {}
                const lines = this.text.split("\n")
                const recent = []
                const seen = {}

                for (const line of lines) {
                    const name = line.trim()
                    if (!name)
                        continue

                    counts[name] = (counts[name] || 0) + 1

                    // Walk oldest -> newest, then keep the last occurrence
                    // of every application in the order it was most recently used.
                    if (seen[name]) {
                        const oldIndex = recent.indexOf(name)
                        if (oldIndex >= 0)
                            recent.splice(oldIndex, 1)
                    }

                    recent.push(name)
                    seen[name] = true
                }

                recent.reverse()

                root.usageCounts = counts
                root.recentApplications = recent
            }
        }
    }

    function refreshUsageHistory() {
        if (!usageHistoryProcess.running)
            usageHistoryProcess.running = true
    }

    function normalize(text) {
        return String(text ?? "").toLowerCase().trim();
    }

    /*
     * Fuzzy matching.
     *
     * Примеры:
     *
     *   "ff"       -> Firefox
     *   "fir"      -> Firefox
     *   "fox"      -> Firefox
     *   "nix"      -> NixOS
     *   "term"     -> Terminal
     *
     * Чем ближе найденные символы друг к другу
     * и чем раньше начинается совпадение,
     * тем выше score.
     */
    function fuzzyScore(text, query) {
        return LauncherAppSearch.fuzzyScore(text, query, root.fuzzySearchEnabled)
    }

    function scoreEntry(entry) {
        return LauncherAppSearch.scoreApplication(
            entry, root.query, root.fuzzySearchEnabled
        )
    }

    // App result filtering and ranking are shared with other application pickers
    // so DND and Launcher cannot drift into different matching behavior.
    property var applications: LauncherAppSearch.buildApplicationEntries(
        DesktopEntries.applications.values || [],
        root.query,
        root.fuzzySearchEnabled,
        root.favoriteAppIds,
        root.hiddenAppIds,
        root.usageCounts,
        root.recentApplications,
        root.emptyQueryLimit
    )

}
