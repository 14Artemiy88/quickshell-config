#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
s = (root / "components/Cava.qml").read_text(encoding="utf-8")
assert 'readonly property bool graphShouldBeVisible: !Config.cavaHideWhenSilent || root.soundActive' in s
assert 'property real graphVisibilityProgress: graphShouldBeVisible ? 1 : 0' in s
assert 'Behavior on graphVisibilityProgress' in s
assert 'duration: Config.animationDuration(180, "appearance")' in s
assert 'easing.type: Config.animationEasingType("standard", root.graphShouldBeVisible ? "enter" : "exit")' in s
assert 'id: cavaGraphMorph' in s
assert 'progress: root.graphVisibilityProgress' in s
assert 'visible: root.graphShouldBeVisible || normalizedProgress > 0.001' in s
assert 'opacity: cavaGraphMorph.normalizedProgress' in s
assert 'scale: 0.96 + 0.04 * cavaGraphMorph.normalizedProgress' in s
assert 'active: root.graphShouldBeVisible || cavaGraphMorph.normalizedProgress > 0.001' in s, "Loader must remain active until exit finishes"
assert 'visible: !Config.cavaHideWhenSilent || root.soundActive' not in s, "instant hide must not bypass the transition lifecycle"
assert 'acceptedButtons: Qt.LeftButton | Qt.RightButton' in s, "CAVA click handling must remain present"
print("CAVA silence MorphGeometry transition and delayed Loader release: OK")
PY
