#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CALENDAR="$ROOT/components/CalendarWidget.qml"
NAV_TEST="$ROOT/tests/test_calendar_navigation_button_primitive.sh"
CHECK="$ROOT/CHECK.sh"
test -f "$CALENDAR"
test -f "$NAV_TEST"
# Dates in the visible month and adjacent-month cells show hover feedback; adjacent
# dates keep their configured base color when not hovered.
grep -Fq 'color: dayMouse.containsMouse' "$CALENDAR"
grep -Fq '? Config.accent' "$CALENDAR"
grep -Fq 'color: dayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Config.transparent' "$CALENDAR"
python3 - "$CALENDAR" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
calendar = Path(sys.argv[1]).read_text(encoding='utf-8')
check = Path(sys.argv[2]).read_text(encoding='utf-8')
# Ensure the hover feedback is bound to the day's actual MouseArea and that
# note click semantics stay intact.
assert 'color: dayMouse.containsMouse' in calendar
assert 'onClicked: function(mouse)' in calendar
assert 'root.openNoteEditor(parent.dateKey)' in calendar
assert 'root.openNoteViewer(parent.dateKey)' in calendar
assert 'test_calendar_hover_feedback.sh' in check
print('Calendar date-number hover and note click semantics: OK')
PYCODE
bash "$NAV_TEST"
echo 'Calendar hover feedback test: OK'
