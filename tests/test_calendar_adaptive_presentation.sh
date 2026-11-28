#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CALENDAR="$ROOT/components/CalendarWidget.qml"
MODULE_FRAME="$ROOT/components/primitives/ModuleFrame.qml"
CHECK="$ROOT/CHECK.sh"
for path in "$CALENDAR" "$MODULE_FRAME" "$CHECK"; do test -f "$path"; done

grep -Fq 'readonly property real calendarPresentationScale:' "$CALENDAR"
grep -Fq 'root.compactPresentation' "$CALENDAR"
grep -Fq 'root.widePresentation ? 1.04 : 1' "$CALENDAR"
grep -Fq 'readonly property int effectiveCalendarDayHeight:' "$CALENDAR"
grep -Fq 'height: root.effectiveCalendarDayHeight' "$CALENDAR"
grep -Fq 'rowSpacing: root.effectiveCalendarGridSpacing' "$CALENDAR"
grep -Fq 'columns: 7' "$CALENDAR"
grep -Fq 'model: root.gridCellCount()' "$CALENDAR"
grep -Fq 'root.openNoteEditor(parent.dateKey)' "$CALENDAR"
grep -Fq 'root.openNoteViewer(parent.dateKey)' "$CALENDAR"
grep -Fq 'root.isCurrentMarkedDate(dayCell.dateKey)' "$CALENDAR"
grep -Fq 'test_calendar_adaptive_presentation.sh' "$CHECK"

python3 - "$CALENDAR" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
# Regular mode is deliberately the original geometry.
assert 'root.compactPresentation ? 4 : 5' in s
assert 'root.compactPresentation ? 23 : 25' in s
assert 'root.compactPresentation ? 22 : 25' in s
assert 'root.compactPresentation ? 27' in s and ': 30' in s
assert 'root.compactPresentation ? 2' in s and ': 3' in s
# Calendar semantics and note interactions are unchanged.
for token in ['function gridCellCount()', 'columns: 7', 'onWheel:', 'root.shiftMonth(1)',
              'root.shiftMonth(-1)', 'Qt.LeftButton | Qt.RightButton',
              'root.openNoteEditor(parent.dateKey)', 'root.openNoteViewer(parent.dateKey)',
              'function isCurrentMarkedDate(key)', 'CalendarNotes.setNote(key, text)']:
    assert token in s, token
# Adaptive values are presentation-only: no Config assignment is introduced.
assert 'Config.calendarDayFontSize =' not in s
assert 'Config.calendarWeekdayFontSize =' not in s
print('Calendar adaptive layout and preserved behavior: OK')
PY
