#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN="$ROOT/components/mopidy/Mopidy.qml"
QUEUE="$ROOT/components/mopidy/MopidyTopPanel.qml"
TRACK="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
ALBUM="$ROOT/components/mopidy/MopidyAlbumHeader.qml"
fail() { echo "Mopidy remaining-time sign: FAIL: $*" >&2; exit 1; }

grep -Fq 'function trackShowsRemainingTime(track)' "$MAIN" || fail 'current-track remaining predicate is missing'
grep -Fq 'function albumShowsRemainingTime(itemData)' "$MAIN" || fail 'current-album remaining predicate is missing'
grep -Fq 'return remaining ? "-" + formatted : formatted' "$MAIN" || fail 'duration formatter does not mark remaining values'
grep -Fq 'controller.formatDuration(controller.queueRemainingDuration, true)' "$QUEUE" || fail 'queue remaining mode does not add sign'
grep -Fq 'controller.formatDuration(controller.trackDisplayDuration(itemData.track), controller.trackShowsRemainingTime(itemData.track))' "$TRACK" || fail 'track remaining condition is not wired to display'
grep -Fq 'controller.formatDuration(controller.albumDisplayDuration(itemData), controller.albumShowsRemainingTime(itemData))' "$ALBUM" || fail 'album remaining condition is not wired to display'
grep -Fq 'controller.formatDuration(controller.queueTotalDuration, false)' "$QUEUE" || fail 'total queue duration must remain unsigned'
python3 - "$MAIN" "$ROOT/Config.qml" "$ROOT/components/Player.qml" <<'PYCODE'
from pathlib import Path
import sys
main, config, player = (Path(p).read_text() for p in sys.argv[1:])
marker = 'onTriggered: root.refreshPlaybackPosition()'
index = main.find(marker)
if index < 0:
    raise SystemExit('Mopidy lightweight position poll timer is missing')
block_start = main.rfind('Timer {', 0, index)
block = main[block_start:index]
if 'interval: 1000' not in block:
    raise SystemExit('Mopidy position poll is not configured for 1000 ms')
if 'property int playerUpdateInterval: 1000' not in config:
    raise SystemExit('Player default refresh interval is not 1000 ms')
if 'interval: Config.playerUpdateInterval' not in player:
    raise SystemExit('Player timer is no longer bound to the configurable update interval')
print('Mopidy/Player remaining-time polling cadence: OK')
PYCODE

# Verify the mpv backend marks only known remaining-time values and keeps the
# unknown-duration/live-stream path empty.
grep -Fq 'timeleft="-$timeleft"' "$ROOT/scripts/player.d/backend_mpv.sh" || fail 'mpv remaining-time sign is missing'
grep -Fq 'time_left="-$time_left"' "$ROOT/scripts/mopidy/player_backend.sh" || fail 'Mopidy Player countdown sign is missing'
grep -Fq '(( current_length > 0 ))' "$ROOT/scripts/mopidy/player_backend.sh" || fail 'unknown-duration guard is missing'
grep -Fq 'timeleft=""' "$ROOT/scripts/player.d/backend_mpv.sh" || fail 'unknown duration should remain blank'

python3 - "$QUEUE" "$TRACK" "$ALBUM" <<'PYCODE'
from pathlib import Path
import sys
for name in sys.argv[1:]:
    text = Path(name).read_text()
    stack = []
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    pairs = {')': '(', ']': '[', '}': '{'}
    i = 0
    while i < len(text):
        c = text[i]
        n = text[i+1] if i+1 < len(text) else ''
        if line_comment:
            if c == '\n': line_comment = False
            i += 1; continue
        if block_comment:
            if c == '*' and n == '/': block_comment = False; i += 2; continue
            i += 1; continue
        if quote:
            if escaped: escaped = False
            elif c == '\\': escaped = True
            elif c == quote: quote = None
            i += 1; continue
        if c == '/' and n == '/': line_comment = True; i += 2; continue
        if c == '/' and n == '*': block_comment = True; i += 2; continue
        if c in ('"', "'", '`'): quote = c; i += 1; continue
        if c in '([{': stack.append((c, i))
        elif c in ')]}':
            if not stack or stack[-1][0] != pairs[c]:
                raise SystemExit(f'{name}: unbalanced {c} at offset {i}')
            stack.pop()
        i += 1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('Mopidy remaining-time sign: QML delimiters OK')
PYCODE
printf 'Mopidy remaining-time sign: OK\n'
