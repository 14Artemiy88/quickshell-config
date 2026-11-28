#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/primitives/AnimatedVisibility.qml" "$ROOT/shell.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
shell = Path(sys.argv[2]).read_text(encoding="utf-8")
assert 'readonly property Item blurRegionItem: contentHost' in qml
assert 'x: root.transitionProgress * root.activeHiddenX' in qml
assert 'y: root.transitionProgress * root.activeHiddenY' in qml
assert 'contentTransform' not in qml
show = qml.split('id: showTransition', 1)[1].split('id: hideTransition', 1)[0]
hide = qml.split('id: hideTransition', 1)[1].split('onShownChanged:', 1)[0]
for block in (show, hide):
    assert 'target: root' in block
    assert 'property: "transitionProgress"' in block
    assert 'duration: root.activeTransitionDuration' in block
assert 'to: 0' in show and 'easing.type: Config.animationEasingType(root.activeAnimationProfile, "enter")' in show
assert 'to: 1' in hide and 'easing.type: Config.animationEasingType(root.activeAnimationProfile, "exit")' in hide
assert 'opacity: root.usesOpacity() ? Math.max(0, Math.min(1, 1 - root.transitionProgress)) : 1' in qml
for marker, expected in (
    ('id: calendarWindow', 'visible: Settings.calendar'),
    ('id: mopidyWindow', 'visible: Settings.mopidy'),
    ('id: settingsWindow', 'visible: true'),
):
    start = shell.index(marker)
    chunk = shell[start:start + 3000]
    assert expected in chunk, f"surface lifetime must not follow content visibility: {marker}"
    assert 'manageInputMask: true' in chunk
    assert 'backgroundBlurItem:' in chunk
print("AnimatedVisibility shared progress, compositor surface lifetime, and blur geometry: OK")
PY
