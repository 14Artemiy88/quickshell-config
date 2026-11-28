#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsPlayerSection.qml"
fail() { echo "Player text outline color MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
for token in \
    'id: playerTextOutlineColorMorph' \
    'id: playerTextOutlineColorContent' \
    'visible: Config.playerTextOutlineEnabled || normalizedProgress > 0.001' \
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)' \
    'toGeometry: Qt.rect(0, 0, parent.width, playerTextOutlineColorContent.implicitHeight)' \
    'progress: Config.playerTextOutlineEnabled ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'animationEasing: Config.animationEasingType("ease-out", Config.playerTextOutlineEnabled ? "enter" : "exit")'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding="utf-8")
start = s.find("MorphGeometry {\n                id: playerTextOutlineColorMorph")
assert start >= 0, "player text outline morph block missing"
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
    if c in ("\"", "'"):
        quote = c
    elif c == "{":
        depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0:
            end = i + 1
            break
assert end is not None, "player text outline morph braces are unbalanced"
block = s[start:end]
for token in (
    'label: "Цвет обводки"',
    'value: Config.playerTextOutlineColor',
    'targetProperty: "playerTextOutlineColor"',
    'saveOnEdit: true',
    'allowAlpha: false',
    'allowTransparent: false',
):
    assert token in block, f"color setting behavior changed: {token}"
assert 'visible: Config.playerTextOutlineEnabled &&' not in block, "content must remain alive during exit morph"
checkbox = s[s.rfind('text: "Обводка текста"', 0, start):start]
assert 'checked: Config.playerTextOutlineEnabled' in checkbox, "outline toggle binding changed"
assert 'Config.playerTextOutlineEnabled = checked; settings.save()' in checkbox, "outline toggle save path changed"
print("Player text outline color MorphGeometry integration: OK")
PYTEST
