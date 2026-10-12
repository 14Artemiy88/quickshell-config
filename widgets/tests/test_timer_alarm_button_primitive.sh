#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SURFACE="$ROOT/components/primitives/HoverButtonSurface.qml"
ALARM_BUTTON="$ROOT/components/TimerAlarmTimeButton.qml"
TIMER="$ROOT/components/TimerWidget.qml"

for file in "$SURFACE" "$ALARM_BUTTON" "$TIMER"; do test -f "$file"; done

grep -Fq 'Primitives.HoverButtonSurface {' "$ALARM_BUTTON"
grep -Fq 'acceptedButtons: root.acceptedButtons' "$ALARM_BUTTON"
grep -Fq 'wheelEnabled: root.wheelEnabled' "$ALARM_BUTTON"
grep -Fq 'onButtonClicked: button => root.buttonClicked(button)' "$ALARM_BUTTON"
grep -Fq 'onWheelRequested: wheelEvent => root.wheelRequested(wheelEvent)' "$ALARM_BUTTON"
grep -Fq 'font.family: Config.settingsFont' "$ALARM_BUTTON"
grep -Fq 'font.pixelSize: 11' "$ALARM_BUTTON"

grep -Fq 'function scheduleAlarmTarget()' "$TIMER"
grep -Fq 'function adjustAlarmTarget(unit, wheelEvent)' "$TIMER"
grep -Fq 'function resetAlarmTargetMinutes()' "$TIMER"
grep -Fq 'root.scheduleAlarmTarget()' "$TIMER"
grep -Fq 'root.adjustAlarmTarget("hours", wheelEvent)' "$TIMER"
grep -Fq 'root.adjustAlarmTarget("minutes", wheelEvent)' "$TIMER"
grep -Fq 'root.resetAlarmTargetMinutes()' "$TIMER"
grep -Fq 'acceptedButtons: Qt.LeftButton' "$TIMER"
grep -Fq 'acceptedButtons: Qt.LeftButton | Qt.MiddleButton' "$TIMER"

python3 - "$SURFACE" "$ALARM_BUTTON" "$TIMER" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for name in sys.argv[1:]:
    s=Path(name).read_text(encoding='utf-8')
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i < len(s):
        c=s[i]; n=s[i+1] if i+1 < len(s) else ''
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

source=Path(sys.argv[3]).read_text(encoding='utf-8')
# The alarm hour/minute rows must not maintain separate Rectangle/MouseArea implementations.
start=source.index('id: alarmButtonsVisibility')
end=source.index('id: timerList', start)
section=source[start:end]
if 'TimerAlarmTimeButton {' not in section or section.count('TimerAlarmTimeButton {') != 2:
    raise SystemExit('Expected both alarm time controls to use TimerAlarmTimeButton')
if 'Rectangle {' in section or 'MouseArea {' in section:
    raise SystemExit('Alarm hour/minute controls still duplicate Rectangle/MouseArea surface')
print('Alarm hour/minute controls use the shared button surface and preserve event hooks: OK')
PYCODE

echo 'Timer alarm hour/minute controls use the shared hover surface; click, middle-click and wheel routes are present: OK'
