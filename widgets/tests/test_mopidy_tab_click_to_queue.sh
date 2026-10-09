#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/Mopidy.qml"

grep -Fq 'function closeLibraryBrowserToQueue()' "$FILE"
grep -Fq 'root.searchOpen = false' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "browse" && root.browseStack.length === 0)' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "playlists")' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "search")' "$FILE"
grep -Fq 'if (root.searchOpen && root.libraryMode === "playlistItems")' "$FILE"
grep -A5 'id: searchTabMouse' "$FILE" | grep -Fq 'enabled: true'
echo 'Mopidy tab click-to-queue: OK'
