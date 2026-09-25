import QtQuick
import Niri 0.1

Item {
    id: root

    property var niri: null
    property string query: ""

    function normalize(text) {
        return String(text ?? "").toLowerCase().trim();
    }

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

            if (previousMatch >= 0) {
                const gap = found - previousMatch - 1;

                if (gap === 0)
                    score += 500;
                else
                    score += Math.max(0, 200 - gap * 30);
            }

            if (found === 0 || text[found - 1] === " " || text[found - 1] === "-" || text[found - 1] === "_" || text[found - 1] === ".") {
                score += 300;
            }

            score += Math.max(0, 200 - found * 10);

            previousMatch = found;
            position = found + 1;
        }

        score += Math.max(0, 100 - text.length);

        return score;
    }

    function scoreWindow(window) {
        const query = normalize(root.query);

        if (query === "")
            return window.isFocused ? 100000 : 0;

        const title = normalize(window.title);
        const appId = normalize(window.appId);

        let score = -1;

        score = Math.max(score, fuzzyScore(title, query));

        score = Math.max(score, fuzzyScore(appId, query) + 100);

        return score;
    }

    function rebuild() {
        const result = [];

        if (!root.niri)
            return result;

        for (let i = 0; i < root.niri.windows.rowCount; ++i) {
            const index = root.niri.windows.index(i, 0);

            const window = {
                id: root.niri.windows.data(index, 0),
                title: root.niri.windows.data(index, 1),
                appId: root.niri.windows.data(index, 2),
                pid: root.niri.windows.data(index, 3),
                workspaceId: root.niri.windows.data(index, 4),
                isFocused: root.niri.windows.data(index, 5),
                isFloating: root.niri.windows.data(index, 6),
                isUrgent: root.niri.windows.data(index, 7),
                iconPath: root.niri.windows.data(index, 8)
            };

            const score = scoreWindow(window);

            if (root.query === "" || score >= 0) {
                result.push({
                    window: window,
                    score: score
                });
            }
        }

        result.sort(function (a, b) {
            return b.score - a.score;
        });

        return result.map(function (item) {
            return item.window;
        });
    }

    property var windows: rebuild()

    Connections {
        target: root.niri ? root.niri.windows : null

        function onRowsInserted() {
            root.windows = root.rebuild();
        }

        function onRowsRemoved() {
            root.windows = root.rebuild();
        }

        function onDataChanged() {
            root.windows = root.rebuild();
        }

        function onModelReset() {
            root.windows = root.rebuild();
        }
    }

    onQueryChanged: {
        root.windows = root.rebuild();
    }

    onNiriChanged: {
        root.windows = root.rebuild();
    }
}
