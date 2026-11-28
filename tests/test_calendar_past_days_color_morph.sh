#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsCalendarSection.qml"
fail() { echo "Calendar past-days color MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
MORPH_PATH="$(realpath -m "$(dirname "$QML")/../../primitives/MorphGeometry.qml")"
[[ -f "$MORPH_PATH" ]] || fail "MorphGeometry import does not resolve to components/primitives/MorphGeometry.qml"
for token in \
    'id: calendarPastDaysColorMorph' \
    'id: calendarPastDaysColorContent' \
    'visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1' \
    '&& (Config.calendarPastDaysColorEnabled || normalizedProgress > 0.001)' \
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)' \
    'toGeometry: Qt.rect(0, 0, parent.width, calendarPastDaysColorContent.implicitHeight)' \
    'progress: Config.calendarPastDaysColorEnabled ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'animationEasing: Config.animationEasingType("ease-out", Config.calendarPastDaysColorEnabled ? "enter" : "exit")'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding="utf-8")
start = s.find("MorphGeometry {\n            id: calendarPastDaysColorMorph")
assert start >= 0, "calendar past-days color MorphGeometry missing"
brace = s.find("{", start)
depth = 0
quote = None
escaped = False
end = None
for i in range(brace, len(s)):
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
assert end is not None, "MorphGeometry braces are unbalanced"
block = s[start:end]
assert block.count("SettingsColorField {") == 1, "past-days color field should exist exactly once inside morph"
assert 'label: "Цвет прошедших дней и меток заметок"' in block, "color field label changed"
assert 'targetProperty: "calendarPastDaysColor"' in block, "existing setting binding changed"
assert "visible: Config.calendarPastDaysColorEnabled" not in block, "content must remain alive during exit morph"
checkbox_start = s.rfind('id: pastDaysColorCheck', 0, start)
assert checkbox_start >= 0, "enable checkbox moved or removed"
checkbox_end = s.find("MorphGeometry {", checkbox_start)
checkbox = s[checkbox_start:checkbox_end]
assert 'checked: Config.calendarPastDaysColorEnabled' in checkbox, "checkbox binding changed"
assert 'Config.calendarPastDaysColorEnabled = checked' in checkbox, "checkbox write path changed"
assert 'settings.save()' in checkbox, "checkbox persistence changed"
print("Calendar past-days color MorphGeometry integration: OK")
PYTEST

grep -Fq 'test_calendar_past_days_color_morph.sh' "$ROOT/CHECK.sh" || fail "test not registered in CHECK.sh"
printf 'Calendar past-days color MorphGeometry: OK\n'
