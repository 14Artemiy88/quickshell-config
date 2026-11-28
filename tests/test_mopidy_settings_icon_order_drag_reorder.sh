#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTION="$ROOT/components/settings/sections/mopidy/SettingsMopidyIconsSection.qml"
QUEUE="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
PLAYLIST="$ROOT/components/mopidy/MopidyPlaylistContents.qml"

for file in "$SECTION" "$QUEUE" "$PLAYLIST"; do
    test -f "$file"
done

grep -Fq 'import "../../../primitives" as Primitives' "$SECTION"

python3 - "$SECTION" <<'PY'
from pathlib import Path
import re, sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
start = s.index('Repeater {')
end_match = re.search(r'(?m)^\s*SettingsButton\s*\{\s*\n\s*width:\s*125\b', s[start:])
assert end_match, 'Could not locate the settings button after the icon-order repeater'
end = start + end_match.start()
order = s[start:end]
assert order.count('Primitives.DragReorderHandle {') == 1, 'Mopidy icon ordering should use the shared drag-reorder primitive'
assert 'listRepeater: mopidyTopIconOrderRepeater' in order, 'Mopidy icon rows must be used as drop targets'
assert 'SettingsButton {' not in order, 'Mopidy icon-order arrows must not use regular SettingsButton controls'
assert 'onReorderRequested: function(fromIndex, toIndex)' in order
assert 'orderColumn.moveItemTo(fromIndex, toIndex)' in order
PY

# Queue tracks and playlist entries use backend-aware drag reorder. There are
# no runtime arrow controls left; legacy Config values remain only for old profiles.
grep -Fq 'Primitives.DragReorderHandle {' "$QUEUE"
grep -Fq 'controller.moveTrack(Number(itemData.track.tlid), toIndex)' "$QUEUE"
grep -Fq 'Primitives.DragReorderHandle {' "$PLAYLIST"
grep -Fq 'controller.movePlaylistItem(fromIndex, toIndex, modelData.name, modelData.uri)' "$PLAYLIST"
! grep -Fq 'Primitives.MoveArrowButton {' "$QUEUE"
! grep -Fq 'Primitives.MoveArrowButton {' "$PLAYLIST"
grep -Fq 'Порядок треков очереди и записей плейлистов меняется перетаскиванием' "$SECTION"
for legacy_key in mopidyMoveUpIcon mopidyMoveDownIcon mopidyShowMoveUpIcon mopidyShowMoveDownIcon; do
    grep -Fq "$legacy_key" "$ROOT/Config.qml" || { echo "missing legacy compatibility key $legacy_key" >&2; exit 1; }
done

echo 'Mopidy queue and playlist use backend-aware shared drag reorder: OK'
