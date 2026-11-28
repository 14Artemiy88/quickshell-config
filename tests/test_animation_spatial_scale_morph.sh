#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
morph = (root / "components/primitives/MorphGeometry.qml").read_text(encoding="utf-8")
curves = (root / "js/AnimationCurves.js").read_text(encoding="utf-8")
assert 'property string animationProfile: "ease-in-out"' in qml
assert 'property string activeAnimationProfile: "ease-in-out"' in qml
assert qml.count('property: "transitionProgress"') == 2
assert 'x: root.transitionProgress * root.activeHiddenX' in qml
assert 'y: root.transitionProgress * root.activeHiddenY' in qml
assert 'root.usesOpacity() ? Math.max(0, Math.min(1, 1 - root.transitionProgress)) : 1' in qml
assert 'property: "scale"' not in qml
assert 'spatialScale' not in qml and 'effectsProfile' not in qml
assert 'opacity: 1' in morph and 'scale: 1' in morph
assert 'function normalizeProfile(profile)' in curves and 'function parseBezier(value)' in curves
print("Legacy spatial/effects transforms are removed; CSS easing only changes transition timing: OK")
PY
