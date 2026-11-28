#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
curves = (root / "js/AnimationCurves.js").read_text(encoding="utf-8")
morph = (root / "components/primitives/MorphGeometry.qml").read_text(encoding="utf-8")
visibility = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
group = (root / "components/settings/primitives/SettingsAnimationGroup.qml").read_text(encoding="utf-8")
config = (root / "Config.qml").read_text(encoding="utf-8")
assert '"ease-in-out": [0.42, 0, 0.58, 1, 1, 1]' in curves
assert 'return Easing.BezierSpline' in config
assert 'opacity: 1' in morph and 'scale: 1' in morph
assert 'spatialProfileActive' not in morph and 'effectsProfileActive' not in morph
assert 'activeAnimationProfile === "effects"' not in visibility
assert 'activeAnimationProfile === "spatial"' not in visibility
assert 'root.usesOpacity() ? Math.max(0, Math.min(1, 1 - root.transitionProgress)) : 1' in visibility
assert 'root.activeAnimationStyle === "fade"' in visibility
assert 'Config.animationEasingType(root.activeAnimationProfile, "enter")' in visibility
assert 'Config.animationEasingType(root.activeAnimationProfile, "exit")' in visibility
assert 'Функция сглаживания' in group and 'cubic-bezier()' in group
print("CSS easing profiles control interpolation only; appearance style remains independent: OK")
PY
