#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/WeatherNow.qml"
fail() { echo "Weather comfort live MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "primitives" as Primitives' "$QML" || fail "shared primitive import missing"
for token in \
    'id: weatherComfortMorph' \
    'visible: weatherComfortLabel.shouldShow || normalizedProgress > 0.001' \
    'progress: weatherComfortLabel.shouldShow ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'animationEasing: Config.animationEasingType("standard", weatherComfortLabel.shouldShow ? "enter" : "exit")' \
    'readonly property bool shouldShow: Config.weatherShowComfort && comfortValue !== ""' \
    'Config.weatherComfortHeight)' \
    'model: weatherComfortLabel.outlineOffsets' \
    'color: Config.weatherComfortOutlineColor'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
root = Path(sys.argv[1])
s = (root / "components/WeatherNow.qml").read_text(encoding="utf-8")
start = s.find("Primitives.MorphGeometry {\n            id: weatherComfortMorph")
assert start >= 0, "comfort label is not wrapped in MorphGeometry"
opening = s.find("{", start)
stack = []
pairs = {"}": "{", ")": "(", "]": "["}
quote = None
escaped = False
line_comment = False
block_comment = False
line = 1
end = None
i = opening
while i < len(s):
    c = s[i]
    n = s[i + 1] if i + 1 < len(s) else ""
    if c == "\n":
        line += 1
        line_comment = False
        i += 1
        continue
    if line_comment:
        i += 1
        continue
    if block_comment:
        if c == "*" and n == "/":
            block_comment = False
            i += 2
        else:
            i += 1
        continue
    if quote:
        if escaped: escaped = False
        elif c == "\\": escaped = True
        elif c == quote: quote = None
        i += 1
        continue
    if c == "/" and n == "/": line_comment = True; i += 2; continue
    if c == "/" and n == "*": block_comment = True; i += 2; continue
    if c in ("'", '"'): quote = c
    elif c in "{([": stack.append(c)
    elif c in "})]":
        assert stack and stack[-1] == pairs[c], f"unexpected delimiter {c} at line {line}"
        stack.pop()
        if not stack:
            end = i + 1
            break
    i += 1
assert end is not None, "weather comfort morph block is unbalanced"
block = s[start:end]
assert 'fromGeometry: Qt.rect(' in block and 'toGeometry: Qt.rect(' in block
assert 'Config.weatherComfortHeight)' in block, "target geometry must use configured row height"
assert 'anchors.fill: parent' in block, "comfort content must track animated bounds"
assert 'visible: Config.weatherShowComfort && comfortValue !== ""' not in block, "old instant label visibility remains"
assert 'WeatherPlaceholder {' in s and 'MouseArea {' in s, "weather refresh and placeholder layers must remain"
check = (root / "CHECK.sh").read_text(encoding="utf-8")
assert 'run_test "$ROOT/tests/test_weather_comfort_live_morph.sh"' in check, "test is not registered in CHECK.sh"
print("Weather comfort live MorphGeometry: OK")
PYTEST
