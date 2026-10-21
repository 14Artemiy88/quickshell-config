import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property string query: ""

    // How many applications to show when there is no search query.
    property int emptyQueryLimit: 8

    // Application launch counts, keyed by application name.
    property var usageCounts: ({})

    // Most recently launched applications, newest first.
    property var recentApplications: []

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
        text = normalize(text);
        query = normalize(query);

        if (query === "")
            return 0;

        if (text === query)
            return 10000;

        if (text.startsWith(query))
            return 9000 - text.length;

        if (text.includes(query))
            return 8000 - text.indexOf(query);

        let score = 0;
        let position = 0;
        let firstMatch = -1;
        let previousMatch = -1;

        for (let i = 0; i < query.length; ++i) {
            const character = query[i];

            const found = text.indexOf(character, position);

            if (found === -1)
                return -1;

            if (firstMatch === -1)
                firstMatch = found;

            /*
             * Бонус за последовательные символы.
             *
             * Например:
             *
             *   ff -> Firefox
             *
             * второй f находится недалеко от первого.
             */
            if (previousMatch >= 0) {
                const gap = found - previousMatch - 1;

                if (gap === 0)
                    score += 500;
                else
                    score += Math.max(0, 200 - gap * 30);
            }

            /*
             * Бонус за совпадение с началом слова.
             *
             * firefox
             * ^ ^
             */
            if (found === 0 || text[found - 1] === " " || text[found - 1] === "-" || text[found - 1] === "_" || text[found - 1] === ".") {
                score += 300;
            }

            /*
             * Чем раньше начинается совпадение,
             * тем лучше.
             */
            score += Math.max(0, 200 - found * 10);

            previousMatch = found;
            position = found + 1;
        }

        /*
         * Небольшой бонус за короткое имя.
         */
        score += Math.max(0, 100 - text.length);

        return score;
    }

    function scoreEntry(entry) {
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
        const result = []
        const query = normalize(root.query)

        for (const entry of DesktopEntries.applications.values) {
            if (query === "") {
                const usage = root.usageCounts[entry.name] || 0
                const recentIndex = root.recentApplications.indexOf(entry.name)
                const recency = recentIndex >= 0
                    ? Math.max(0, 1000 - recentIndex)
                    : 0

                result.push({
                    entry: entry,
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
                    score: score
                })
            }
        }

        if (query === "") {
            // Empty search: combine frequency and recency.
            // Frequency is intentionally much stronger, while recency
            // breaks ties and keeps recently used apps near the top.
            result.sort(function(a, b) {
                if (b.rank !== a.rank)
                    return b.rank - a.rank

                if (b.usage !== a.usage)
                    return b.usage - a.usage

                return String(a.entry.name).localeCompare(
                    String(b.entry.name)
                )
            })

            return result
                .slice(0, root.emptyQueryLimit)
                .map(function(item) { return item.entry })
        }

        // With a query, keep the existing fuzzy ranking and show all matches.
        result.sort(function(a, b) {
            return b.score - a.score
        })

        return result.map(function(item) { return item.entry })
    }

}
