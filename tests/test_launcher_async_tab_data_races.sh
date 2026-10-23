#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
s = (root / "components/launcher/Launcher.qml").read_text()

def section(start, end):
    a = s.index(start)
    b = s.index(end, a)
    return s[a:b]

# Each local async list query returns the generation token passed at launch.
assert "property int niriWindowsGeneration: 0" in s
assert "property int clipboardGeneration: 0" in s
assert "property int passGeneration: 0" in s
assert "__NIRI_WINDOWS_REQUEST__%s" in s
assert "__CLIPHIST_REQUEST__%s" in s
assert "__PASS_REQUEST__%s" in s
assert "String(root.niriWindowsPendingGeneration)" in s
assert "String(root.clipboardPendingGeneration)" in s
assert "String(root.passPendingGeneration)" in s

# Stale output is rejected before any associated result model is replaced.
for name, marker, end in (
    ("acceptNiriWindows", "__NIRI_WINDOWS_REQUEST__", "function rebuildWindowModel("),
    ("finishClipboardLoad", "__CLIPHIST_REQUEST__", "function updateClipboardModel("),
    ("finishPassEntries", "__PASS_REQUEST__", "function rebuildPassModel("),
):
    body = section(f"function {name}(", end)
    assert marker in body, f"{name}: request marker missing"
    assert "requestGeneration !== root." in body, f"{name}: generation guard missing"
    assert "!root.visible" in body and "root.layoutEditMode" in body, f"{name}: visible/edit context guard missing"
    guard = body.index("requestGeneration !== root.")
    first_mutation = min((i for i in [body.find("root.niriWindows ="), body.find("root.clipboardOutput ="), body.find("root.passEntries =")] if i >= 0), default=-1)
    if first_mutation >= 0:
        assert guard < first_mutation, f"{name}: mutation precedes stale-response guard"

# Tab changes, close, and Smart Moving invalidate in-flight list requests.
invalidator = section("function invalidateModeAsyncRequests(", "// Entry point called by the host shell's IpcHandler")
for token in ("root.niriWindowsGeneration += 1", "root.clipboardGeneration += 1", "root.passGeneration += 1"):
    assert token in invalidator
hide = section("function hideLauncher()", "function toggleLauncher()")
assert "root.invalidateAllAsyncRequests()" in hide
set_mode = section("function setMode(newMode)", "function activeListForMode(")
assert "root.invalidateModeAsyncRequests(root.mode)" in set_mode
layout = section("function beginLayoutEdit()", "function cancelLayoutDrag()")
assert "root.invalidateAllAsyncRequests()" in layout

# Unit-model the response-token policy, including a late response after reopening.
def accepts(response, generation, visible=True, active=True, editing=False):
    marker = response[0]
    token = response[1]
    return token == generation and visible and active and not editing
assert accepts(("clipboard", 8), 8)
assert not accepts(("clipboard", 7), 8)  # prior run completed late
assert not accepts(("pass", 8), 8, visible=False)
assert not accepts(("windows", 8), 8, active=False)
assert not accepts(("clipboard", 8), 8, editing=True)
print("Launcher async Pass/Clipboard/Windows results are guarded by context generations: OK")
PY
