#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")

handler = qml.split("function handleAnimationStyleChange()", 1)[1].split("function handleDurationChange()", 1)[0]
assert "if (root.running) return" in handler, "a style change must not restart the current transition"
assert "activeAnimationStyle = root.animationStyle" in handler
assert "activeDuration = root.duration" in handler
assert "applyImmediate(root.shown)" in handler, "idle components should normalize to the selected style without animating"
assert "onAnimationStyleChanged: handleAnimationStyleChange()" in qml
assert "root.activeAnimationStyle" in qml and "root.activeDuration" in qml
assert "duration: root.usesOpacity() ? root.activeDuration : 0" in qml
assert "duration: root.usesHorizontalSlide() ? root.activeDuration : 0" in qml
assert "duration: root.usesVerticalSlide() ? root.activeDuration : 0" in qml

# A zero duration or disabling animations mid-transition still settles instantly.
duration_handler = qml.split("function handleDurationChange()", 1)[1].split("function startTransition()", 1)[0]
assert "if (root.running)" in duration_handler
assert "root.duration <= 0" in duration_handler
assert "!Config.animationsEnabled || !Config.animationAppearanceEnabled" in duration_handler
assert "applyImmediate(root.shown)" in duration_handler

# The current transition's style and duration are captured before animation starts,
# and are not overwritten during a reversal while that same transition is active.
start = qml.split("function startTransition()", 1)[1].split("ParallelAnimation {\n        id: showTransition", 1)[0]
assert "var wasRunning = root.running" in start
assert "if (!wasRunning)" in start
assert "activeAnimationStyle = root.animationStyle" in start
assert "activeDuration = root.duration" in start
print("AnimatedVisibility mid-transition style/duration stability: OK")
PY
