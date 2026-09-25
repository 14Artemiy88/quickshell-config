import Quickshell
import QtQuick

Item {
    id: root

    property string query: ""

    // Desktop entries are expensive to enumerate. Do it once and keep the
    // original entry objects around; searching then only works on this cache.
    property var allApplications: []
    property bool loaded: false

    function normalize(text) {
        return String(text ?? "").toLowerCase().trim()
    }

    function loadApplications() {
        if (root.loaded)
            return

        const result = []
        for (const entry of DesktopEntries.applications.values)
            result.push(entry)

        root.allApplications = result
        root.loaded = true
    }

    function fuzzyScore(text, query) {
        text = normalize(text)
        query = normalize(query)

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

        return score + Math.max(0, 100 - text.length)
    }

    function scoreEntry(entry, query) {
        let score = fuzzyScore(entry.name, query)

        if (entry.genericName)
            score = Math.max(score, fuzzyScore(entry.genericName, query) - 100)

        if (entry.comment)
            score = Math.max(score, fuzzyScore(entry.comment, query) - 200)

        if (entry.keywords) {
            for (const keyword of entry.keywords)
                score = Math.max(score, fuzzyScore(keyword, query) - 150)
        }

        return score
    }

    property var applications: {
        if (!root.loaded)
            return []

        const query = normalize(root.query)

        if (query === "")
            return root.allApplications

        const result = []

        for (const entry of root.allApplications) {
            const score = root.scoreEntry(entry, query)

            if (score >= 0)
                result.push({ entry: entry, score: score })
        }

        result.sort(function(a, b) {
            return b.score - a.score
        })

        return result.map(function(item) {
            return item.entry
        })
    }

    Component.onCompleted: loadApplications()
}
