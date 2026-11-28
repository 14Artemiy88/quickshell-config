#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/CalendarWidget.qml"

test -f "$QML"
grep -Fq 'import "primitives" as Primitives' "$QML"
grep -Fq 'id: noteOverlayMorph' "$QML"
grep -Fq 'fromGeometry: Qt.rect(0, 0, root.width, root.height)' "$QML"
grep -Fq 'toGeometry: Qt.rect(0, 0, root.width, root.height)' "$QML"
grep -Fq 'fromRadius: Config.frameRadius + 4' "$QML"
grep -Fq 'toRadius: Config.frameRadius' "$QML"
grep -Fq 'progress: root.noteOverlayMode !== "" ? 1 : 0' "$QML"
grep -Fq 'visible: root.noteOverlayMode !== "" || root.noteOverlayOpacityProgress > 0.001' "$QML"
grep -Fq 'animationDuration: Config.animationDurationForProfile(true, Config.animationCalendarMorphProfile, Config.animationCalendarMorphDuration, "appearance")' "$QML"
grep -Fq 'animationProfile: Config.animationCalendarMorphProfile' "$QML"

python3 - "$QML" <<'PYCODE'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
assert 'property real noteOverlayOpacityProgress: noteOverlayMode !== "" ? 1 : 0' in s
assert 'Behavior on noteOverlayOpacityProgress' in s
assert 'easing.type: Easing.Linear' in s
start = s.index('Primitives.MorphGeometry {\n        id: noteOverlayMorph')
end = s.index('\n    function shiftMonth', start)
block = s[start:end]
assert 'opacity: root.noteOverlayOpacityProgress' in block, 'linear opacity must remain visible for the full easing transition'
assert 'scale: 0.90 + 0.10 * noteOverlayMorph.animatedProgress' in block, 'calendar note overlay scale must preserve cubic-bezier overshoot'
assert 'animationEasing: Config.animationEasingType(Config.animationCalendarMorphProfile' in block
assert 'animationBezierCurve: Config.animationBezierCurve(Config.animationCalendarMorphProfile' in block
assert 'transformOrigin: Item.Center' in block
assert 'MouseArea {' in block and 'acceptedButtons: Qt.AllButtons' in block
assert 'color: "#e6000000"' in block
assert 'radius: noteOverlayMorph.geometryRadius' in block
assert 'TextArea {' in block and 'readOnly: root.noteOverlayMode === "view"' in block
for control in ('noteSaveButton', 'noteDeleteButton', 'noteCancelButton', 'noteEditButton', 'noteCloseButton', 'calendarMarkButton'):
    assert f'id: {control}' in block, f'{control} missing from animated overlay'
assert 'clip: true' not in block, 'note editor content must not be clipped during morph'
# Fixed full-size geometry must be independent of editor content, avoiding reflow/binding loops.
assert block.count('fromGeometry: Qt.rect(0, 0, root.width, root.height)') == 1
assert block.count('toGeometry: Qt.rect(0, 0, root.width, root.height)') == 1
print('Calendar note overlay MorphGeometry; full-size interaction shield and editor actions preserved: OK')
PYCODE

echo 'Calendar note overlay MorphGeometry test: OK'
