#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'property real spatialScale: 0.97' in qml
assert 'property real activeSpatialScale: 0.97' in qml
assert 'scale: root.activeAnimationProfile === "spatial" ? 1 - root.transitionProgress * (1 - root.activeSpatialScale) : 1' in qml
assert 'transformOrigin: Item.Center' in qml
assert 'function normalizedSpatialScale()' in qml
assert 'function handleSpatialScaleChange()' in qml
assert 'onSpatialScaleChanged: handleSpatialScaleChange()' in qml
assert 'activeSpatialScale = root.normalizedSpatialScale()' in qml
assert qml.count('property: "transitionProgress"') == 2
assert 'property: "scale"' not in qml
# Standard and Effects keep scale at 1; Spatial derives it from the same
# progress signal as translation/opacity, so no second animation can drift.
assert 'root.activeAnimationProfile === "spatial"' in qml
assert 'transitionProgress * (1 - root.activeSpatialScale)' in qml
print("Spatial profile scale morph shares transition progress and leaves other profiles unchanged: OK")
PY
