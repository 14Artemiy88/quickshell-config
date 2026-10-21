#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "function handleAnimationAvailabilityChange()" in qml
block = qml.split("function handleAnimationAvailabilityChange()", 1)[1].split("function startTransition()", 1)[0]
assert "if (root.running && (!Config.animationsEnabled || !Config.animationAppearanceEnabled))" in block
assert "applyImmediate(root.shown)" in block
assert "target: Config" in block
assert "function onAnimationsEnabledChanged()" in block
assert "function onAnimationAppearanceEnabledChanged()" in block
assert "root.handleAnimationAvailabilityChange()" in block
duration = qml.split("function handleDurationChange()", 1)[1].split("function handleAnimationAvailabilityChange()", 1)[0]
assert "root.duration <= 0" in duration
assert "applyImmediate(root.shown)" in duration
print("AnimatedVisibility global animation-disable transition guard: OK")
PY
