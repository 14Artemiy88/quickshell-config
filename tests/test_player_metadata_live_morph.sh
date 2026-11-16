#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/Player.qml"
fail() { echo "Player metadata live MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "primitives" as Primitives' "$QML" || fail "shared primitive import missing"
for token in \
    'id: playerMetadataMorph' \
    'visible: root.playerMetadataTargetHeight > 0 || normalizedProgress > 0.001' \
    'progress: root.playerMetadataMaxHeight > 0 ? root.playerMetadataTargetHeight / root.playerMetadataMaxHeight : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'animationEasing: Config.animationEasingType("standard", root.playerMetadataExpanding ? "enter" : "exit")' \
    'readonly property int playerMetadataLineCount:' \
    'readonly property real playerMetadataTargetHeight:' \
    'readonly property real playerMetadataMaxHeight:' \
    'readonly property real playerMetadataClipSafety: 3' \
    'property bool playerMetadataExpanding: true' \
    'onPlayerMetadataTargetHeightChanged:' \
    'anchors.fill: parent' \
; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
root = Path(sys.argv[1])
s = (root / "components/Player.qml").read_text(encoding="utf-8")
assert s.count("readonly property real playerMetadataSpacing:") == 1
assert s.count("readonly property int playerMetadataLineCount:") == 1
start = s.find("Primitives.MorphGeometry {\n        id: playerMetadataMorph")
assert start >= 0, "metadata stack is not wrapped in MorphGeometry"
opening = s.find("{", start)
depth = 0
quote = None
escaped = False
end = None
for i in range(opening, len(s)):
    c = s[i]
    if quote:
        if escaped: escaped = False
        elif c == "\\": escaped = True
        elif c == quote: quote = None
        continue
    if c in ("'", '"'): quote = c
    elif c == "{": depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0:
            end = i + 1
            break
assert end is not None, "metadata morph braces are unbalanced"
block = s[start:end]
for token in (
    'parent.height - Config.playerMetadataY',
    'parent.height - Config.playerMetadataY - root.playerMetadataMaxHeight',
    'root.playerMetadataMaxHeight + root.playerMetadataClipSafety',
    'root.playerMetadataTargetHeight / root.playerMetadataMaxHeight',
    'visible: !!root.player.first_line',
    'visible: !!root.player.second_line',
    'visible: !!root.player.third_line',
    'styleColor: Config.playerTextOutlineColor',
):
    assert token in block, f"metadata layout/formatting contract missing: {token}"
assert 'anchors.bottom: parent.bottom' not in block, "old fixed-height bottom anchor remains"
assert 'root.playerMetadataMaxHeight + root.playerMetadataClipSafety' in block, "clip safety buffer is missing from expanded geometry"
assert 'readonly property real playerMetadataClipSafety: 3' in s, "3px trailing clip safety is missing"
# The interpolated clip height must exceed the nominal metadata content height
# by a positive trailing buffer at every non-zero animation progress.
for progress in (0.1, 0.25, 0.5, 0.75, 1.0):
    nominal = 54 * progress
    clip_height = (54 + 3) * progress
    assert clip_height >= nominal + 0.29, (progress, clip_height, nominal)
assert 'Text {\n        id: pauseButton' in s, "playback controls disappeared"
assert 'id: playbackToggleMouse' in s, "background playback click handling disappeared"
check = (root / "CHECK.sh").read_text(encoding="utf-8")
assert 'run_test "$ROOT/tests/test_player_metadata_live_morph.sh"' in check, "test is not registered in CHECK.sh"
print("Player metadata live MorphGeometry: OK")
PYTEST
