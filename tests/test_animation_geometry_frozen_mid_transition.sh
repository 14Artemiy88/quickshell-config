#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'property real activeHiddenX: 0' in qml
assert 'property real activeHiddenY: 0' in qml
assert 'x: root.transitionProgress * root.activeHiddenX' in qml
assert 'y: root.transitionProgress * root.activeHiddenY' in qml
assert 'function captureTransitionGeometry()' in qml
assert 'activeHiddenX = hiddenX()' in qml
assert 'activeHiddenY = hiddenY()' in qml
# Geometry is captured for a new transition, but not while reversing an
# already-running transition. This preserves the original path on reversal.
start = qml.split('function startTransition()', 1)[1].split('NumberAnimation {', 1)[0]
transition_start = start.split('var wasRunning = root.running', 1)[1]
assert 'if (!wasRunning)' in transition_start
assert transition_start.index('captureTransitionGeometry()') > transition_start.index('if (!wasRunning)')
assert 'if (!wasRunning) {\n            activeAnimationStyle = root.animationStyle' in start
# Resize refreshes geometry only when hidden and idle; active motion remains frozen.
assert qml.count('captureTransitionGeometry()') >= 6
print("AnimatedVisibility freezes slide geometry through resize and reversal: OK")
PY
