#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsPlayerSection.qml"
fail() { echo "Player progress settings MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
for token in \
    'id: playerProgressOptionsMorph' \
    'id: playerProgressOptionsContent' \
    'visible: Config.playerShowProgress || normalizedProgress > 0.001' \
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)' \
    'toGeometry: Qt.rect(0, 0, parent.width, playerProgressOptionsContent.implicitHeight)' \
    'progress: Config.playerShowProgress ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'animationEasing: Config.animationEasingType("standard", Config.playerShowProgress ? "enter" : "exit")'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding="utf-8")
start = s.find("MorphGeometry {\n            id: playerProgressOptionsMorph")
assert start >= 0, "player progress morph block missing"
opening = s.find("{", start)
depth = 0
quote = None
escaped = False
end = None
for i in range(opening, len(s)):
    c = s[i]
    if quote:
        if escaped:
            escaped = False
        elif c == "\\":
            escaped = True
        elif c == quote:
            quote = None
        continue
    if c in ('"', "'"):
        quote = c
    elif c == "{":
        depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0:
            end = i + 1
            break
assert end is not None, "player progress morph braces are unbalanced"
block = s[start:end]
for token in (
    'value: Config.playerProgressY',
    'value: Config.playerProgressTrackHeight',
    'value: Config.playerProgressTrackOffsetY',
    'targetProperty: "playerProgressTrack"',
    'targetProperty: "playerProgressFill"',
    'label: "Цвет дорожки"',
    'label: "Цвет заполнения"',
):
    assert token in block, f"dependent progress setting missing: {token}"
assert 'visible: Config.playerShowProgress &&' not in block, "child controls must remain alive during the exit morph"
checkbox = s[s.rfind('SettingsGroup {', 0, start):start]
assert 'text: "Показывать прогресс"' in checkbox, "progress toggle moved or removed"
assert 'checked: Config.playerShowProgress' in checkbox, "progress toggle binding changed"
assert 'Config.playerShowProgress=checked; settings.save()' in checkbox, "progress toggle save path changed"
print("Player progress settings MorphGeometry integration: OK")
PYTEST
