#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
qml = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
assert 'function animationEasingType(profile, phase)' in config
assert 'name === "spatial"' in config and 'name === "effects"' in config
assert 'direction === "exit" ? Easing.InCubic : Easing.OutCubic' in config
assert 'direction === "exit" ? Easing.InQuad : Easing.OutQuad' in config
assert 'function easingType() { return animationEasingType("standard", "enter") }' in config
assert 'property string animationProfile: "standard"' in qml
assert 'property string activeAnimationProfile: "standard"' in qml
assert 'Config.animationEasingType(root.activeAnimationProfile, "enter")' in qml
assert 'Config.animationEasingType(root.activeAnimationProfile, "exit")' in qml
assert 'function handleAnimationProfileChange()' in qml
assert 'onAnimationProfileChanged: handleAnimationProfileChange()' in qml
assert 'property int duration: Config.animationDuration(250, "appearance")' in qml
assert 'Durations remain owned by each module' in config
assert qml.count('property: "transitionProgress"') == 2
assert 'x: root.transitionProgress * root.activeHiddenX' in qml
assert 'y: root.transitionProgress * root.activeHiddenY' in qml
assert 'opacity: root.usesOpacity() ? 1 - root.transitionProgress : 1' in qml
assert 'property: "opacity"' not in qml and 'property: "x"' not in qml and 'property: "y"' not in qml
print("Shared animation profiles and synchronized transition progress: OK")
PY
