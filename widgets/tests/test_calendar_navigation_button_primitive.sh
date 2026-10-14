#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CALENDAR="$ROOT/components/CalendarWidget.qml"
ICON_BUTTON="$ROOT/components/primitives/HoverIconButton.qml"
CHECK="$ROOT/CHECK.sh"

for file in "$CALENDAR" "$ICON_BUTTON"; do
    test -f "$file"
done

# The two month-navigation controls must use the common icon button primitive.
grep -Fq 'property int cursorShape: Qt.PointingHandCursor' "$ICON_BUTTON"
grep -Fq 'cursorShape: root.cursorShape' "$ICON_BUTTON"
grep -Fq 'color: root.hovered && root.hoverMode === "text" ? root.hoverColor : root.baseColor' "$ICON_BUTTON"
grep -Fq 'Primitives.HoverIconButton {' "$CALENDAR"
grep -Fq 'iconText: Config.calendarPreviousIcon' "$CALENDAR"
grep -Fq 'iconText: Config.calendarNextIcon' "$CALENDAR"
grep -Fq 'iconSize: Config.calendarPreviousSize' "$CALENDAR"
grep -Fq 'iconSize: Config.calendarNextSize' "$CALENDAR"
grep -Fq 'iconX: Config.calendarPreviousX' "$CALENDAR"
grep -Fq 'iconX: Config.calendarNextX' "$CALENDAR"
grep -Fq 'iconY: Config.calendarArrowY' "$CALENDAR"
grep -Fq 'iconFontFamily: Config.font' "$CALENDAR"
grep -Fq 'cursorShape: Qt.PointingHandCursor' "$CALENDAR"
grep -Fq 'hoverMode: "text"' "$CALENDAR"
grep -Fq 'hoverColor: Config.accent' "$CALENDAR"
grep -Fq 'onClicked: root.shiftMonth(-1)' "$CALENDAR"
grep -Fq 'onClicked: root.shiftMonth(1)' "$CALENDAR"

python3 - "$CALENDAR" "$ICON_BUTTON" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for name in sys.argv[1:3]:
    source=Path(name).read_text(encoding='utf-8')
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1 < len(source) else ''
        if line_comment:
            if c=='\n': line_comment=False
            i+=1; continue
        if block_comment:
            if c=='*' and n=='/': block_comment=False; i+=2; continue
            i+=1; continue
        if quote:
            if escaped: escaped=False
            elif c=='\\': escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': line_comment=True; i+=2; continue
        if c=='/' and n=='*': block_comment=True; i+=2; continue
        if c in ('"', "'", '`'): quote=c; i+=1; continue
        if c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0] != pairs[c]:
                raise SystemExit(f'{name}: unbalanced {c} at offset {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')

calendar=Path(sys.argv[1]).read_text(encoding='utf-8')
# Restrict the assertion to the month-navigation row: day cells/overlays have
# distinct left/right click semantics and are intentionally not migrated here.
header=calendar.index('height: 25\n                spacing: 4')
weekdays=calendar.index('model: root.names', header)
nav=calendar[header:weekdays]
if nav.count('Primitives.HoverIconButton {') != 2:
    raise SystemExit('Expected exactly two shared icon buttons in the calendar navigation row')
if 'MouseArea {' in nav:
    raise SystemExit('Month navigation still has its own MouseArea')
if nav.count('cursorShape: Qt.PointingHandCursor') != 2:
    raise SystemExit('Month navigation must use a pointing-hand cursor')
if nav.count('hoverMode: "text"') != 2 or nav.count('hoverColor: Config.accent') != 2:
    raise SystemExit('Month navigation buttons must highlight their icons in the accent color on hover')
if 'onClicked: root.shiftMonth(-1)' not in nav or 'onClicked: root.shiftMonth(1)' not in nav:
    raise SystemExit('Month navigation click routing changed')
check=Path(sys.argv[3]).read_text(encoding='utf-8')
if 'test_calendar_navigation_button_primitive.sh' not in check:
    raise SystemExit('Calendar navigation test is not wired into CHECK.sh')
print('Calendar month navigation uses shared icon buttons with accent hover; click routes preserved: OK')
PYCODE

echo 'Calendar previous/next month buttons use HoverIconButton with hover feedback: OK'
