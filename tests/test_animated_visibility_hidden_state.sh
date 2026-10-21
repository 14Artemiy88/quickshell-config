#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY_CHECK'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
start = qml.split("function startTransition()", 1)[1].split("ParallelAnimation {\n        id: showTransition", 1)[0]

# Once hiding is complete, a style/duration change must not restart hide and
# briefly recreate a layer-shell surface that was meant to stay hidden.
guard = "if (!root.shown && !wasVisible) {\n            applyImmediate(false)\n            return\n        }"
assert guard in start, "a fully hidden component must stay hidden when transition settings change"
assert start.index(guard) < start.index("if (!animationAllowed())"), "hidden guard must run before starting any transition"
assert "onAnimationStyleChanged: handleAnimationStyleChange()" in qml
assert "onDurationChanged: handleDurationChange()" in qml

# Reopening during hide must reverse from the current transform rather than
# applying an immediate hidden state first.
show = start.split("if (root.shown) {", 1)[1].split("} else {", 1)[0]
assert "contentHost.visible = true" in show
assert "contentHost.enabled = true" in show
assert "showTransition.start()" in show
assert "if (!wasVisible)" in show

# Disabled/none/zero-duration settings must still choose the immediate path.
assert "if (!animationAllowed()) {\n            applyImmediate(root.shown)\n            return\n        }" in start
assert 'root.activeAnimationStyle !== "none"' in qml
assert "root.activeDuration > 0" in qml
print("AnimatedVisibility hidden-settings/reopen/disabled-mode regression: OK")
PY_CHECK
