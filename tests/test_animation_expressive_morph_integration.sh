#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
morph = (root / "components/primitives/MorphGeometry.qml").read_text(encoding="utf-8")
visibility = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
weather = (root / "components/WeatherPlaceholder.qml").read_text(encoding="utf-8")
network = (root / "components/NetworkStat.qml").read_text(encoding="utf-8")
assert 'import "js/AnimationCurves.js" as AnimationCurves' in config
assert 'import "../.."' in morph
assert 'property string animationProfile: "standard"' in morph
assert 'property string animationPhase: "enter"' in morph
assert 'property var animationBezierCurve: Config.animationBezierCurve(root.animationProfile, root.animationPhase)' in morph
assert 'easing.bezierCurve: root.animationBezierCurve' in morph
assert 'easing.bezierCurve: Config.animationBezierCurve(root.activeAnimationProfile, "enter")' in visibility
assert 'easing.bezierCurve: Config.animationBezierCurve(root.activeAnimationProfile, "exit")' in visibility
assert 'animationProfile: Config.animationWeatherMorphProfile' in weather and 'animationPhase: root.active ? "enter" : "exit"' in weather
assert network.count('animationProfile: "expressive"') == 2
assert 'animationPhase: Config.networkShowUpload ? "enter" : "exit"' in network
assert 'animationPhase: Config.networkShowDownload ? "enter" : "exit"' in network
# Keep the existing morph progress and visibility lifecycle as the sole drivers.
assert 'Behavior on progress' in morph
assert 'property: "transitionProgress"' in visibility
assert visibility.count('property: "transitionProgress"') == 2
print("Expressive easing is wired into both shared morph primitives and two pilot components: OK")
PY
