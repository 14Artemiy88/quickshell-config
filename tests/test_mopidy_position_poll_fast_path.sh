#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACKLIST="$ROOT/scripts/mopidy/tracklist.sh"
MAIN="$ROOT/components/mopidy/Mopidy.qml"
fail() { echo "Mopidy lightweight position polling: FAIL: $*" >&2; exit 1; }

python3 - "$TRACKLIST" "$MAIN" <<'PYCODE'
from pathlib import Path
import sys
tracklist = Path(sys.argv[1]).read_text()
main = Path(sys.argv[2]).read_text()

poll_start = tracklist.index('get_position_state() {')
poll_end = tracklist.index('\nplay_track() {', poll_start)
poll = tracklist[poll_start:poll_end]
for method in ('core.tracklist.get_version', 'core.playback.get_current_tl_track', 'core.playback.get_time_position'):
    assert method in poll, f'lightweight poll omitted {method}'
assert 'core.tracklist.get_tl_tracks' not in poll, 'position poll must not request the full tracklist'
assert 'position)' in tracklist and 'get_position_state' in tracklist, 'position subcommand is not exposed'
assert 'tracklist_version:' in poll and 'position_ms:' in poll and 'current_tlid:' in poll

assert 'property int tracklistVersion: -1' in main, 'last-known Mopidy tracklist version is not cached'
assert 'function refreshPlaybackPosition()' in main, 'lightweight poll trigger function is missing'
assert '[Quickshell.shellDir + "/scripts/mopidy/tracklist.sh", "position"]' in main, 'QML is not invoking lightweight position mode'
assert 'function applyPlaybackPositionSnapshot(data)' in main, 'position snapshot logic is not isolated for regression testing'
assert 'refreshFullQueue = root.applyPlaybackPositionSnapshot(data)' in main, 'position process does not use validated snapshot logic'
assert 'root.tracklistVersion = isFinite(version) && version >= 0 ? version : -1' in main, 'full queue response does not update version cache'

marker = 'onTriggered: root.refreshPlaybackPosition()'
idx = main.find(marker)
assert idx >= 0, 'one-second timer is not connected to the lightweight poll'
start = main.rfind('Timer {', 0, idx)
block = main[start:idx]
assert 'interval: 1000' in block, 'remaining-time tick must remain one second'
assert 'root.refreshQueue()' not in block, 'one-second timer still downloads the full queue'
print('Mopidy compact position polling and version-gated full-queue refresh: OK')
PYCODE

node - "$MAIN" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8');
const start = source.indexOf('function applyPlaybackPositionSnapshot(data) {');
const end = source.indexOf('\n    function requestMopidyStart()', start);
if (start < 0 || end < 0) throw new Error('cannot isolate Mopidy position snapshot function');
const fn = source.slice(start, end);
function apply(initial, data) {
  const root = { ...initial };
  const context = { root };
  vm.runInNewContext(`${fn}\nthis.applyPlaybackPositionSnapshot = applyPlaybackPositionSnapshot;`, context);
  const refresh = context.applyPlaybackPositionSnapshot(data);
  return { root, refresh };
}
let state = apply({ queueAvailable: true, currentTlid: 7, currentPositionMs: 1000, tracklistVersion: 42 },
  { ok: true, current_tlid: 7, position_ms: 14000, tracklist_version: 42 });
if (state.refresh !== false || state.root.currentPositionMs !== 14000)
  throw new Error('normal countdown tick should update position without fetching full queue');
state = apply({ queueAvailable: true, currentTlid: 7, currentPositionMs: 1000, tracklistVersion: 42 },
  { ok: true, current_tlid: 7, position_ms: 15000, tracklist_version: 43 });
if (state.refresh !== true || state.root.tracklistVersion !== 43)
  throw new Error('tracklist version change should request full queue refresh');
state = apply({ queueAvailable: true, currentTlid: 7, currentPositionMs: 1000, tracklistVersion: 42 },
  { ok: true, current_tlid: 8, position_ms: 0, tracklist_version: 42 });
if (state.refresh !== true || state.root.currentTlid !== 8)
  throw new Error('current track change should request full queue refresh');
state = apply({ queueAvailable: false, currentTlid: -1, currentPositionMs: 0, tracklistVersion: -1 },
  { ok: true, current_tlid: -1, position_ms: 0, tracklist_version: 42 });
if (state.refresh !== true)
  throw new Error('offline-to-online transition should request a full queue refresh');
state = apply({ queueAvailable: true, currentTlid: 7, currentPositionMs: 1000, tracklistVersion: 42 },
  { ok: false, current_tlid: null, position_ms: 0, tracklist_version: null });
if (state.refresh !== false || state.root.currentTlid !== 7 || state.root.currentPositionMs !== 1000 || state.root.tracklistVersion !== 42)
  throw new Error('invalid poll must preserve last good snapshot');
console.log('Mopidy position snapshot state transitions: OK');
NODE
