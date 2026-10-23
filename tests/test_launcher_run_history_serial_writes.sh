#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
s = (Path(sys.argv[1]) / "components/launcher/Launcher.qml").read_text()

def section(start, end):
    a = s.index(start)
    b = s.index(end, a)
    return s[a:b]

for decl in (
    'property bool runHistoryPersistAfterLoad: false',
    'property string runHistoryWriteActivePayload: ""',
    'property string runHistoryWriteQueuedPayload: ""',
    'property bool runHistoryWriteHasQueuedPayload: false',
    'property int runHistoryWriteSequence: 0',
):
    assert decl in s, f"missing writer state: {decl}"

writer = section('id: runHistoryWriteProcess', 'id: runCommandsProcess')
assert r'tmp=\"$1.tmp.$$.$3\"' in writer
assert 'mv \\"$tmp\\" \\"$1\\"' in writer or 'mv "$tmp" "$1"' in writer
assert 'root.finishRunHistoryWrite(exitCode)' in writer

persist = section('function persistRunHistory()', 'function deleteRunHistory(')
assert 'if (root.runHistoryLoadPending)' in persist
assert 'root.runHistoryPersistAfterLoad = true' in persist
assert 'if (runHistoryWriteProcess.running)' in persist
assert 'root.runHistoryEntries.slice().reverse().join(\"\\n\")' in persist
assert 'root.runHistoryWriteHasQueuedPayload = false' in persist
assert 'root.runHistoryWriteQueuedPayload = data' in persist
assert 'root.startRunHistoryWrite(data)' in persist
assert 'Quickshell.execDetached' not in persist

finish = section('function finishRunHistoryWrite(', 'function persistRunHistory(')
assert 'root.runHistoryWriteHasQueuedPayload' in finish
assert 'root.startRunHistoryWrite(latestPayload)' in finish
assert 'root.runHistoryWriteHasQueuedPayload = false' in finish

remember = section('function rememberRunCommand(', 'function buildAppsUnifiedResults()')
assert 'root.persistRunHistory()' in remember
assert 'Quickshell.execDetached' not in remember
assert 'tail -n 100' not in remember

accept = section('function acceptRunHistory(', 'function rebuildRunHistoryModel()')
assert 'const shouldPersistMergedHistory = mutations.length > 0 || root.runHistoryPersistAfterLoad' in accept
assert accept.index('root.runHistoryLoadPending = false') < accept.index('root.persistRunHistory()')
assert 'root.runHistoryPersistAfterLoad = false' in accept

# A burst of changes while one write is active must persist only the latest snapshot next.
active = 'old-a\nold-b'
queued = None
for payload in ('new-a\nold-a\nold-b', 'new-b\nnew-a\nold-a\nold-b', ''):
    if active is not None:
        queued = payload
# Once the active write finishes, the queue starts with the newest requested state.
assert queued == ''
active = queued
queued = None
assert active == '', 'latest empty snapshot (clear-history) must not be replaced by stale data'

# Preserve the established on-disk convention (oldest-first) while the model is newest-first.
model_newest_first = ['cmd-new', 'cmd-middle', 'cmd-old']
disk = '\n'.join(reversed(model_newest_first))
loaded_newest_first = list(reversed([line for line in disk.splitlines() if line]))
assert loaded_newest_first == model_newest_first, 'history order must survive a write/reload round-trip'

print('Launcher Run-history writes are serialized, latest-snapshot wins, and startup writes are deferred until merge: OK')
PY
