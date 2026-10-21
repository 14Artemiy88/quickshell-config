#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CALENDAR="$ROOT/components/CalendarWidget.qml"
BUTTON="$ROOT/components/primitives/StyledTextButton.qml"
CHECK="$ROOT/CHECK.sh"

for file in "$CALENDAR" "$BUTTON"; do test -f "$file"; done

grep -Fq 'import "primitives" as Primitives' "$CALENDAR"
grep -Fq 'Button {' "$BUTTON"
grep -Fq 'hoverEnabled: true' "$BUTTON"
grep -Fq 'root.down ? root.pressedBackground : (root.hovered && root.hoverMode === "background" ? root.hoverColor : root.normalBackground)' "$BUTTON"
grep -Fq 'root.hovered && root.hoverMode === "frame" ? root.hoverColor : root.outlineColor' "$BUTTON"
grep -Fq 'text: root.text' "$BUTTON"

python3 - "$CALENDAR" "$BUTTON" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
def check_balance(name):
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

for name in sys.argv[1:3]: check_balance(name)
calendar=Path(sys.argv[1]).read_text(encoding='utf-8')
button=Path(sys.argv[2]).read_text(encoding='utf-8')
check=Path(sys.argv[3]).read_text(encoding='utf-8')

ids=['noteSaveButton','noteDeleteButton','noteCancelButton','noteEditButton','noteCloseButton','calendarMarkButton']
if calendar.count('Primitives.StyledTextButton {') != len(ids):
    raise SystemExit('Expected six calendar-note and date-mark actions to use StyledTextButton')
if 'iconText: "×"' not in calendar or 'onClicked: root.closeNoteOverlay()' not in calendar:
    raise SystemExit('Calendar note overlay close control is not using the shared icon-button path')
for control_id in ids:
    if f'id: {control_id}' not in calendar:
        raise SystemExit(f'Missing calendar-note action {control_id}')
import re
if re.search(r'(?m)^\s*Button\s*\{', calendar):
    raise SystemExit('CalendarWidget still has a standalone Controls.Button rather than the shared text-button primitive')

routes=[
    'onClicked: root.saveCalendarNote()',
    'onClicked: { root.noteDraft = ""; root.saveCalendarNote() }',
    'onClicked: root.closeNoteOverlay()',
    'onClicked: root.openNoteEditor(root.noteDialogDate)',
]
for route in routes:
    if route not in calendar:
        raise SystemExit(f'Calendar note action route changed or missing: {route}')
if calendar.count('onClicked: root.closeNoteOverlay()') < 2:
    raise SystemExit('Expected separate Cancel and Close actions')
if 'mouse.button === Qt.RightButton' not in calendar or 'root.openNoteEditor(parent.dateKey)' not in calendar:
    raise SystemExit('Right-click creation/edit entry point changed')
if 'mouse.button === Qt.LeftButton' not in calendar or 'root.openNoteViewer(parent.dateKey)' not in calendar:
    raise SystemExit('Left-click view entry point changed')
if 'Quickshell.shellDir + "/scripts/calendar_notes"' not in calendar or '"set"' not in calendar:
    raise SystemExit('Calendar note persistence command changed')
if 'contentItem: Text {' in calendar:
    raise SystemExit('Calendar note button text styling is still duplicated inline')
if 'test_calendar_note_buttons_shared_primitive.sh' not in check:
    raise SystemExit('Calendar note button test is not wired into CHECK.sh')
print('Calendar note create/edit/save/delete/cancel/close routes use shared styled text buttons: OK')
PYCODE

echo 'Calendar note buttons shared primitive test: OK'
