#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
s = (root / "components/launcher/Launcher.qml").read_text()
assert "property int launcherInteractionGeneration: 0" in s
assert "property int pendingFocusInteractionGeneration: -1" in s
# Open/close, mode switching, and Smart Moving invalidate older completions.
for fn in ("beginLayoutEdit", "endLayoutEdit", "hideLauncher", "setMode"):
    start = s.index(f"function {fn}(")
    end = s.index("\n    }", start)
    assert "launcherInteractionGeneration += 1" in s[start:end], f"{fn} must invalidate pending callbacks"
# Focus request captures the current interaction generation.
focus_start = s.index("function focusWindow(windowId)")
focus_end = s.index("function focusCurrentWindow()", focus_start)
assert "pendingFocusInteractionGeneration = root.launcherInteractionGeneration" in s[focus_start:focus_end]
# The async completion must be tied to the same still-visible Windows context.
proc_start = s.index("id: niriFocusProcess")
proc_end = s.index("Timer {", proc_start)
handler = s[proc_start:proc_end]
assert "root.visible && root.mode === root.modeWindows" in handler
assert "root.pendingFocusInteractionGeneration === root.launcherInteractionGeneration" in handler
assert handler.index("root.pendingFocusInteractionGeneration === root.launcherInteractionGeneration") < handler.index("root.hideLauncher()")
print("Launcher async Niri focus completion cannot close a newer launcher session: OK")
PY
