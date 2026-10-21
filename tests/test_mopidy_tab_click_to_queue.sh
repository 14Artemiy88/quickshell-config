#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/mopidy/Mopidy.qml"
LIBRARY="$ROOT/components/mopidy/MopidyLibraryView.qml"

grep -Fq 'function closeLibraryBrowserToQueue()' "$FILE"
grep -Fq 'root.searchOpen = false' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "browse" && root.browseStack.length === 0)' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "playlists")' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "search")' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "playlistItems")' "$FILE"
grep -A15 'text: "Поиск"' "$LIBRARY" | grep -Fq 'enabled: true'
echo 'Mopidy tab click-to-queue: OK'
