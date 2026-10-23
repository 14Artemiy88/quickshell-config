#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
s = (Path(sys.argv[1]) / "components/launcher/Launcher.qml").read_text()

def section(start, end):
    a = s.index(start)
    b = s.index(end, a)
    return s[a:b]

assert "property int runHistoryGeneration: 0" in s
assert "property int runHistoryPendingGeneration: -1" in s
assert "property bool runHistoryLoadPending: false" in s
assert "property var runHistoryPendingMutations: []" in s
process = section("id: runHistoryProcess", "id: runCommandsProcess")
assert "__RUN_HISTORY_REQUEST__%s" in process
assert "String(root.runHistoryPendingGeneration)" in process
assert "root.acceptRunHistory(this.text)" in process

accept = section("function acceptRunHistory(", "function rebuildRunHistoryModel()")
assert "requestGeneration !== root.runHistoryPendingGeneration" in accept
assert "!root.runHistoryLoadPending" in accept
assert accept.index("requestGeneration !== root.runHistoryPendingGeneration") < accept.index("root.parseRunHistory(")
assert "root.runHistoryPendingMutations" in accept
for op in ('type === "clear"', 'type === "delete"', 'type === "remember"'):
    assert op in accept, f"pending mutation application missing: {op}"

load = section("function loadRunHistoryFromDisk()", "function persistRunHistory()")
assert load.index("root.runHistoryPendingGeneration = root.runHistoryGeneration") < load.index("runHistoryProcess.running = true")
assert "root.runHistoryLoadPending = true" in load
assert "root.runHistoryPendingMutations = []" in load

for name, end in (
    ("function deleteRunHistory(", "function clearRunHistory()"),
    ("function clearRunHistory()", "function rememberRunCommand("),
    ("function rememberRunCommand(", "function buildAppsUnifiedResults()"),
):
    body = section(name, end)
    assert 'root.recordRunHistoryMutation(' in body, f"{name}: user mutation not journaled"

# Model disk snapshot plus commands made while the initial read was pending.
def apply(disk, mutations):
    entries = list(reversed([x for x in disk.splitlines() if x]))
    entries = list(dict.fromkeys(entries))
    for action, command in mutations:
        if action == "clear":
            entries = []
        elif action == "delete":
            entries = [x for x in entries if x != command]
        elif action == "remember":
            entries = [command] + [x for x in entries if x != command]
    return entries[:100]
assert apply("old-a\nold-b\n", [("remember", "new-c")]) == ["new-c", "old-b", "old-a"]
assert apply("old-a\nold-b\n", [("clear", ""), ("remember", "new-c")]) == ["new-c"]
assert apply("old-a\nold-b\n", [("delete", "old-a")]) == ["old-b"]
print("Launcher run-history startup load merges concurrent user actions without restoring stale entries: OK")
PY
