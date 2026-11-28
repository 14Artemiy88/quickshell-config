#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
handler = qml.split("function handleAnimationStyleChange()", 1)[1].split("function handleAnimationProfileChange()", 1)[0]
assert "if (root.running) return" in handler
assert "activeAnimationStyle = root.animationStyle" in handler
assert "activeDuration = 0" in handler and "activeDuration = root.duration" in handler
assert "applyImmediate(root.shown)" in handler
assert "onAnimationStyleChanged: handleAnimationStyleChange()" in qml
assert "root.activeAnimationStyle" in qml and "root.activeDuration" in qml
assert 'property: "transitionProgress"' in qml
assert 'x: root.transitionProgress * root.activeHiddenX' in qml
assert 'y: root.transitionProgress * root.activeHiddenY' in qml
assert 'opacity: root.usesOpacity() ? Math.max(0, Math.min(1, 1 - root.transitionProgress)) : 1' in qml
assert qml.count('property: "transitionProgress"') == 2
duration_handler = qml.split("function handleDurationChange()", 1)[1].split("function startTransition()", 1)[0]
assert "if (root.running)" in duration_handler and "root.duration <= 0" in duration_handler
assert 'if (root.animationStyle === "none")' in handler
assert "applyImmediate(root.shown)" in duration_handler
start = qml.split("function startTransition()", 1)[1].split("NumberAnimation {\n        id: showTransition", 1)[0]
assert 'if (root.animationStyle === "none")' in start
assert start.index('if (root.animationStyle === "none")') < start.index("var wasRunning = root.running")
assert "var wasRunning = root.running" in start and "if (!wasRunning)" in start
assert "activeAnimationStyle = root.animationStyle" in start
assert "activeAnimationProfile = root.animationProfile" in start
assert "activeDuration = 0" in start and "activeDuration = root.duration" in start
print("AnimatedVisibility shared-progress and mid-transition stability: OK")
PY
