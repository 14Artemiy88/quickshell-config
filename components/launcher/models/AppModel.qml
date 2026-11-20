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
        const special = root.specialSearch
        if (special) {
            return LauncherAppSearch.scoreEntry(
                entry,
                special,
                function(searchText, searchQuery) {
                    return root.fuzzyScore(searchText, searchQuery)
                }
            )
        }

        const query = normalize(root.query);

        if (query === "")
            return 0;

        let score = -1;

        /*
         * Название приложения — самый важный параметр.
         */
        score = Math.max(score, fuzzyScore(entry.name, query));

        /*
         * Generic name немного менее важен.
         */
        score = Math.max(score, fuzzyScore(entry.genericName, query) - 100);

        /*
         * Description ещё менее важен.
         */
        score = Math.max(score, fuzzyScore(entry.comment, query) - 200);

        /*
         * Keywords.
         */
        if (entry.keywords) {
            for (const keyword of entry.keywords) {
                score = Math.max(score, fuzzyScore(keyword, query) - 150);
            }
        }

        return score;
    }

    property var applications: {
        // Read ObjectModel.values directly inside this binding. This is the
        // native reactive path used by Quickshell and the pre-preferences Apps model.
        const entries = DesktopEntries.applications.values || []
        const result = []
        const special = root.specialSearch
        const query = special ? normalize(special.query) : normalize(root.query)

        if (special && query === "")
            return []

        for (const entry of entries) {
            const appId = String(entry.id || "").trim()
            // Hidden applications stay out of every Apps result source, including
            // metadata-filter searches, but remain manageable from Settings.
            if (appId && root.hiddenAppIds.indexOf(appId) >= 0)
                continue

            const favoriteIndex = appId ? root.favoriteAppIds.indexOf(appId) : -1
            if (query === "") {
                const usage = root.usageCounts[entry.name] || 0
                const recentIndex = root.recentApplications.indexOf(entry.name)
                const recency = recentIndex >= 0
                    ? Math.max(0, 1000 - recentIndex)
                    : 0

                result.push({
                    entry: entry,
                    favoriteIndex: favoriteIndex,
                    usage: usage,
                    recency: recency,
                    rank: usage * 1000 + recency
                })
                continue
            }

            const score = scoreEntry(entry)
            if (score >= 0) {
                result.push({
                    entry: entry,
                    favoriteIndex: favoriteIndex,
                    score: score
                })
            }
        }

        if (query === "") {
            // Favorites are pinned in the user's saved order. Remaining slots
            // retain the existing frequency/recency ranking.
            result.sort(function(a, b) {
                const aFavorite = a.favoriteIndex >= 0
                const bFavorite = b.favoriteIndex >= 0
                if (aFavorite && bFavorite && a.favoriteIndex !== b.favoriteIndex)
                    return a.favoriteIndex - b.favoriteIndex
                if (aFavorite !== bFavorite)
                    return aFavorite ? -1 : 1
                if (b.rank !== a.rank)
                    return b.rank - a.rank

                if (b.usage !== a.usage)
                    return b.usage - a.usage

                return String(a.entry.name).localeCompare(
                    String(b.entry.name)
                )
            })

            let favoriteCount = 0
            for (let i = 0; i < result.length; ++i) {
                if (result[i].favoriteIndex >= 0)
                    favoriteCount++
            }
            return result
                .slice(0, Math.max(root.emptyQueryLimit, favoriteCount))
                .map(function(item) { return item.entry })
        }

        // With a query, keep the existing fuzzy ranking and show all matches.
        result.sort(function(a, b) {
            const aFavorite = a.favoriteIndex >= 0
            const bFavorite = b.favoriteIndex >= 0
            if (aFavorite !== bFavorite)
                return aFavorite ? -1 : 1
            if (aFavorite && bFavorite && a.favoriteIndex !== b.favoriteIndex)
                return a.favoriteIndex - b.favoriteIndex
            if (b.score !== a.score)
                return b.score - a.score
            return String(a.entry.name).localeCompare(String(b.entry.name))
        })

        return result.map(function(item) { return item.entry })
    }

}
