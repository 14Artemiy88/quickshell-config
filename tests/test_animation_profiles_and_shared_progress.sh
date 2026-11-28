#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
qml = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
curves = (root / "js/AnimationCurves.js").read_text(encoding="utf-8")
assert 'function animationEasingType(profile, phase)' in config
assert 'AnimationCurves.normalizeProfile(profile)' in config
assert 'return Easing.BezierSpline' in config
assert 'function easingType() { return animationEasingType("ease-out", "enter") }' in config
assert 'property string animationProfile: "ease-in-out"' in qml
assert 'property string activeAnimationProfile: "ease-in-out"' in qml
assert 'Config.animationEasingType(root.activeAnimationProfile, "enter")' in qml
assert 'Config.animationEasingType(root.activeAnimationProfile, "exit")' in qml
assert 'function handleAnimationProfileChange()' in qml
assert 'onAnimationProfileChanged: handleAnimationProfileChange()' in qml
assert 'property int duration: Config.animationDuration(250, "appearance")' in qml
assert 'Durations are controlled by each module' in config
assert qml.count('property: "transitionProgress"') == 2
assert 'x: root.transitionProgress * root.activeHiddenX' in qml
assert 'y: root.transitionProgress * root.activeHiddenY' in qml
assert 'opacity: root.usesOpacity() ? Math.max(0, Math.min(1, 1 - root.transitionProgress)) : 1' in qml
assert 'property: "opacity"' not in qml and 'property: "x"' not in qml and 'property: "y"' not in qml
assert 'function parseBezier(value)' in curves and 'function normalizeProfile(profile)' in curves
print("Shared CSS easing functions and synchronized transition progress remain wired: OK")
PY
