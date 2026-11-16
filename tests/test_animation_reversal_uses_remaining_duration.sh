#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'property int activeTransitionDuration: 250' in qml
assert 'function transitionDurationFor(targetProgress)' in qml
assert 'Math.abs(Number(targetProgress) - Number(root.transitionProgress))' in qml
assert 'Math.round(root.activeDuration * remaining)' in qml
start = qml.split('function startTransition()', 1)[1].split('NumberAnimation {', 1)[0]
show = start.split('if (root.shown) {', 1)[1].split('} else {', 1)[0]
hide = start.split('} else {', 1)[1]
assert 'activeTransitionDuration = transitionDurationFor(0)' in show
assert 'activeTransitionDuration = transitionDurationFor(1)' in hide
assert qml.count('duration: root.activeTransitionDuration') == 2
assert 'duration: root.activeDuration' not in qml
print("AnimatedVisibility scales reversal duration to remaining transition distance: OK")
PY
