#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PANEL="$ROOT/components/mopidy/MopidyTopPanel.qml"
fail() { echo "Mopidy top-panel optional metadata MorphGeometry: FAIL: $*" >&2; exit 1; }

[[ -f "$ROOT/components/primitives/MorphGeometry.qml" ]] || fail 'shared MorphGeometry component missing'
grep -Fq 'import "../primitives" as Primitives' "$PANEL" || fail 'shared primitive import missing'

python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
root = Path(sys.argv[1])
panel_path = root / "components/mopidy/MopidyTopPanel.qml"
s = panel_path.read_text(encoding="utf-8")

def require(token: str, message: str) -> None:
    assert token in s, message

# Queue duration stays in a fixed outer slot. MorphGeometry animates only an
# unclipped inner item; the Text itself retains its complete width and is not faded.
for token, message in [
    ('id: queueDurationSlot', 'queue duration fixed slot missing'),
    ('x: topPanelRow.queueDurationRightEdge - 60', 'queue duration slot must stay 6px left of the icon cluster'),
    ('width: 60', 'queue duration outer slot width changed'),
    ('visible: topPanelRow.queueDurationTargetVisible || queueDurationMorph.normalizedProgress > 0.001', 'queue duration slot must remain visible during exit morph'),
    ('readonly property real queueDurationRightEdge: topIconStartX - (totalIconWidth() > 0 ? 6 : 0)', 'queue duration right edge must follow icon cluster'),
    ('id: queueDurationMorph', 'queue duration MorphGeometry missing'),
    ('fromGeometry: Config.mopidyQueueDurationAlignment === "left"', 'queue duration start geometry must follow text alignment'),
    ('? Qt.rect(-4, 0, 56, parent.height)', 'left-aligned queue duration must enter from its left offset'),
    (': Qt.rect(4, 0, 56, parent.height)', 'right-aligned queue duration must enter from its right offset'),
    ('toGeometry: Qt.rect(0, 0, 60, parent.height)', 'queue duration morph endpoint must restore full local width'),
    ('clip: false', 'queue duration morph must not clip its text'),
    ('id: queueDurationText', 'queue duration Text id missing'),
    ('width: 60', 'queue duration Text must keep full fixed width'),
    ('scale: 0.96 + 0.04 * queueDurationMorph.normalizedProgress', 'queue duration must use geometric scale rather than fade'),
    ('transformOrigin: Config.mopidyQueueDurationAlignment === "left" ? Item.Left : Item.Right', 'queue duration scale must originate at its aligned edge'),
    ('animationDuration: Config.animationDuration(180, "appearance")', 'queue duration must use shared appearance duration'),
    ('Config.animationEasingType("standard", topPanelRow.queueDurationTargetVisible ? "enter" : "exit")', 'queue duration must use directional shared easing'),
    ('Config.mopidyQueueDurationMode === "remaining" ? controller.formatDuration(controller.queueRemainingDuration, true) : controller.formatDuration(controller.queueTotalDuration, false)', 'queue duration formatting changed'),
    ('horizontalAlignment: Config.mopidyQueueDurationAlignment === "left" ? Text.AlignLeft : Text.AlignRight', 'queue duration alignment changed'),
]:
    require(token, message)
queue_start = s.find('id: queueDurationSlot')
queue_end = s.find('Widgets.MopidyHoverIcon', queue_start)
assert queue_start >= 0 and queue_end > queue_start, 'queue duration slot block is malformed'
queue_block = s[queue_start:queue_end]
assert 'clip: true' not in queue_block, 'queue duration must not clip text'
assert 'opacity:' not in queue_block and 'Behavior on opacity' not in queue_block, 'queue duration must not use fade opacity'
assert 'volumeControl.geometryWidth' not in queue_block and 'topIconStartX' not in queue_block, 'queue duration local animation must stay independent of icon geometry'
assert 'visible: topPanelRow.queueDurationTargetVisible\n' not in s, 'old instant queue-duration visibility remains'

# The volume slot reports its animated width to the icon layout. Its own
# MorphGeometry endpoints must use fixed-width endpoint calculations, otherwise
# geometryWidth -> iconXFor(volume) -> totalIconWidth -> geometryWidth loops.
for token, message in [
    ('id: volumeControl', 'volume morph id missing'),
    ('readonly property real volumeCollapsedX: volumeXForWidth(22)', 'collapsed volume X endpoint is not isolated'),
    ('readonly property real volumeExpandedX: volumeXForWidth(58)', 'expanded volume X endpoint is not isolated'),
    ('fromGeometry: Qt.rect(topPanelRow.volumeCollapsedX, 0, 22, parent.height)', 'volume collapsed endpoint missing'),
    ('toGeometry: Qt.rect(topPanelRow.volumeExpandedX, 0, 58, parent.height)', 'volume expanded endpoint missing'),
    ('progress: Config.mopidyShowVolumePercent ? 1 : 0', 'volume percentage target state not wired'),
    ('return id === "volume" ? volumeControl.geometryWidth : 22', 'icon row must use interpolated volume width'),
    ('visible: Config.mopidyShowVolumePercent || volumeControl.normalizedProgress > 0.001', 'percentage must persist during exit'),
    ('controller.toggleMixerMute()', 'volume click action changed'),
    ('controller.adjustMixerVolume(wheel.angleDelta.y > 0 ? step : -step)', 'volume wheel action changed'),
]:
    require(token, message)

assert 'width: Config.mopidyShowVolumePercent ? 58 : 22' not in s, 'old instant volume-width binding remains'
assert 'fromGeometry: Qt.rect(topPanelRow.iconXFor(\"volume\")' not in s, 'volume MorphGeometry endpoint must not depend on its own animated width'
assert 'toGeometry: Qt.rect(topPanelRow.iconXFor(\"volume\")' not in s, 'volume MorphGeometry endpoint must not depend on its own animated width'
volume_helper_start = s.find('function volumeXForWidth(volumeWidth) {')
assert volume_helper_start >= 0, 'fixed-width volume X helper missing'
volume_helper_end = s.find('\n            }', volume_helper_start)
assert volume_helper_end > volume_helper_start, 'fixed-width volume X helper is malformed'
volume_helper = s[volume_helper_start:volume_helper_end]
assert 'geometryWidth' not in volume_helper and 'iconXFor(' not in volume_helper, 'volume X helper must not read animated geometry'
assert 'visible: Config.mopidyShowQueueTotalDuration && controller.queueAvailable && controller.tracks.length > 0' not in s, 'old instant queue-duration visibility remains'

# Lightweight QML delimiter validation (ignores quoted strings and comments).
stack = []
pairs = {'}': '{', ')': '(', ']': '['}
quote = None
escaped = False
line_comment = False
block_comment = False
i = 0
line = 1
while i < len(s):
    c = s[i]
    n = s[i + 1] if i + 1 < len(s) else ''
    if c == '\n':
        line += 1
        line_comment = False
        i += 1
        continue
    if line_comment:
        i += 1
        continue
    if block_comment:
        if c == '*' and n == '/':
            block_comment = False
            i += 2
        else:
            i += 1
        continue
    if quote:
        if escaped:
            escaped = False
        elif c == '\\':
            escaped = True
        elif c == quote:
            quote = None
        i += 1
        continue
    if c == '/' and n == '/':
        line_comment = True
        i += 2
        continue
    if c == '/' and n == '*':
        block_comment = True
        i += 2
        continue
    if c in ("'", '"'):
        quote = c
    elif c in '({[':
        stack.append((c, line))
    elif c in ')}]':
        assert stack and stack[-1][0] == pairs[c], f'unexpected {c} at line {line}'
        stack.pop()
    i += 1
assert quote is None and not block_comment and not stack, f'unclosed QML construct: {stack[-1] if stack else quote}'

check = (root / 'CHECK.sh').read_text(encoding='utf-8')
assert 'run_test "$ROOT/tests/test_mopidy_top_panel_optional_metadata_morph.sh"' in check, 'test not registered in CHECK.sh'
print('Mopidy top-panel queue-duration and volume-percentage MorphGeometry: OK')
PYTEST
