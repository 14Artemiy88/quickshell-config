#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="$ROOT/components/mopidy/Mopidy.qml"
LIBRARY="$ROOT/components/mopidy/MopidyLibraryView.qml"
PLAYLIST="$ROOT/components/mopidy/MopidyPlaylistContents.qml"

python3 - "$MAIN" "$LIBRARY" "$PLAYLIST" <<'PYCODE'
from pathlib import Path
import re
import sys

main, library, playlist = (Path(p).read_text(encoding="utf-8") for p in sys.argv[1:])

def function_body(source: str, name: str) -> str:
    match = re.search(r"function\s+" + re.escape(name) + r"\s*\([^)]*\)\s*\{", source)
    if not match:
        raise SystemExit(f"missing function {name}")
    start = match.end()
    depth = 1
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    i = start
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if line_comment:
            if c == "\n": line_comment = False
            i += 1; continue
        if block_comment:
            if c == "*" and n == "/": block_comment = False; i += 2; continue
            i += 1; continue
        if quote:
            if escaped: escaped = False
            elif c == "\\": escaped = True
            elif c == quote: quote = None
            i += 1; continue
        if c == "/" and n == "/": line_comment = True; i += 2; continue
        if c == "/" and n == "*": block_comment = True; i += 2; continue
        if c in ("'", '"', "`"): quote = c; i += 1; continue
        if c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0: return source[start:i]
        i += 1
    raise SystemExit(f"unterminated function {name}")

if not re.search(r"readonly property bool reorderInteractionLocked:[^\n]*queueReorderPending[^\n]*queueReorderDragging", main):
    raise SystemExit("reorder lock must include live queue pending/dragging state")
lock_tail = main.split("readonly property bool reorderInteractionLocked:", 1)[1].split("function updateStickyAlbum", 1)[0]
for required in ("playlistContentMoveBusy", "playlistContentMoveUri.length > 0", "playlistContentReorderDragging"):
    if required not in lock_tail:
        raise SystemExit(f"reorder lock missing {required}")

for name in (
    "toggleSearch", "openPlaylistAddMode", "openBrowseRoot", "browseUriAt", "browseBack",
    "closeLibraryBrowserToQueue", "showSearch", "showBrowse", "showPlaylists",
    "loadPlaylists", "openPlaylist", "backToPlaylists", "resetToInitialScreen",
    "switchPlaylist", "addPlaylist", "addPlaylistItem", "openCreatePlaylistDialog",
    "openRenamePlaylistDialog", "openDeletePlaylistDialog", "openDeletePlaylistFromListDialog",
    "submitPlaylistDialog", "addBrowseFolder", "addSearchResult",
):
    body = function_body(main, name)
    if "reorderInteractionLocked" not in body:
        raise SystemExit(f"{name} must refuse to change playlist/view context during reorder")

move_body = function_body(main, "movePlaylistItem")
if "root.reorderInteractionLocked" in move_body:
    raise SystemExit("movePlaylistItem must allow the active drag callback to commit before draggingChanged(false)")
for token in ("root.playlistContentMoveUri = moveUri", "expectedOrder[from] !== String(expectedUri)", "from === to"):
    if token not in move_body:
        raise SystemExit(f"movePlaylistItem missing validation/snapshot: {token}")

exit_block = main.split("id: playlistContentMoveProcess", 1)[1].split("Process {", 1)[0]
for token in ("var moveUri = String(root.playlistContentMoveUri", "root.playlistContentMoveUri = \"\"", "root.playlistUri === moveUri", '"items", moveUri'):
    if token not in exit_block:
        raise SystemExit(f"playlist move completion must remain bound to the source URI: {token}")

for token in (
    "enabled: !controller.reorderInteractionLocked", 
    "enabledState: !controller.browseBusy && !controller.playlistsBusy",
):
    if token not in library:
        raise SystemExit(f"Mopidy library navigation UI missing lock: {token}")
if "interactionEnabled: !controller.playlistContentMoveBusy" not in playlist:
    raise SystemExit("playlist row delete action must be disabled while move is pending")

print("Mopidy async reorder navigation locking and playlist-context isolation: OK")
PYCODE
