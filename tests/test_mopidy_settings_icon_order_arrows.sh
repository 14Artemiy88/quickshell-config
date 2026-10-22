#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTION="$ROOT/components/settings/sections/mopidy/SettingsMopidyIconsSection.qml"
MOVE="$ROOT/components/primitives/MoveArrowButton.qml"
QUEUE="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
PLAYLIST="$ROOT/components/mopidy/MopidyPlaylistContents.qml"

for file in "$SECTION" "$MOVE" "$QUEUE" "$PLAYLIST"; do
    test -f "$file"
done

grep -Fq 'import "../../../primitives" as Primitives' "$SECTION"
grep -Fq 'visible: root.requestedVisible' "$MOVE"
grep -Fq 'property bool hideWhenDisabled: true' "$MOVE"

python3 - "$SECTION" <<'PY'
from pathlib import Path
import re, sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
start = s.index('Repeater {')
end_match = re.search(r'(?m)^\s*SettingsButton\s*\{\s*\n\s*width:\s*125\b', s[start:])
assert end_match, 'Could not locate the settings button after the icon-order repeater'
end = start + end_match.start()
order = s[start:end]
assert order.count('Primitives.MoveArrowButton {') == 2, 'Mopidy icon ordering should use the shared arrow primitive for both directions'
assert 'interactionEnabled: index > 0' in order, 'Move-up arrow must be disabled at the first position and hidden by the shared primitive'
assert 'interactionEnabled: index < orderColumn.orderIds.length - 1' in order, 'Move-down arrow must be disabled at the last position and hidden by the shared primitive'
assert 'SettingsButton {' not in order, 'Mopidy icon-order arrows must not use regular SettingsButton controls'
assert 'onClicked: orderColumn.moveItem(index, -1)' in order
assert 'onClicked: orderColumn.moveItem(index, 1)' in order
PY

# Mopidy runtime queue arrows intentionally remain visible while busy, but
# boundary arrows are still hidden through requestedVisible.
grep -Fq 'requestedVisible: itemData.queueIndex > 0 && Config.mopidyShowMoveUpIcon' "$QUEUE"
grep -Fq 'requestedVisible: itemData.queueIndex < controller.tracks.length - 1 && Config.mopidyShowMoveDownIcon' "$QUEUE"
grep -Fq 'hideWhenDisabled: false' "$QUEUE"
grep -Fq 'requestedVisible: index > 0 && Config.mopidyShowMoveUpIcon' "$PLAYLIST"
grep -Fq 'requestedVisible: index < controller.playlistItems.length - 1 && Config.mopidyShowMoveDownIcon' "$PLAYLIST"
grep -Fq 'hideWhenDisabled: false' "$PLAYLIST"

echo 'Mopidy settings icon-order arrows use the shared primitive and hide unavailable directions: OK'
