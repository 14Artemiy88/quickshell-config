#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SURFACE="$ROOT/components/primitives/HoverButtonSurface.qml"
BUTTON="$ROOT/components/TimerPresetButton.qml"
TIMER="$ROOT/components/TimerWidget.qml"

for file in "$SURFACE" "$BUTTON" "$TIMER"; do test -f "$file"; done

grep -Fq 'property int acceptedButtons: Qt.LeftButton' "$SURFACE"
grep -Fq 'property bool wheelEnabled: false' "$SURFACE"
grep -Fq 'signal buttonClicked(int button)' "$SURFACE"
grep -Fq 'signal wheelRequested(var wheelEvent)' "$SURFACE"
grep -Fq 'acceptedButtons: root.acceptedButtons' "$SURFACE"
grep -Fq 'if (!root.wheelEnabled)' "$SURFACE"

grep -Fq 'Primitives.HoverButtonSurface {' "$BUTTON"
grep -Fq 'acceptedButtons: Qt.LeftButton | Qt.MiddleButton' "$BUTTON"
grep -Fq 'cursorShape: Qt.ArrowCursor' "$BUTTON"
grep -Fq 'wheelEnabled: true' "$BUTTON"
grep -Fq 'root.wheelAdjusted(' "$BUTTON"

grep -Fq 'delegate: TimerPresetButton {' "$TIMER"
grep -Fq 'Settings.resetTimerPreset(index)' "$TIMER"
grep -Fq '"/scripts/timer", "add", String(modelData)' "$TIMER"
grep -Fq 'Settings.adjustTimerPreset(index, direction * Config.timerWheelStep * multiplier)' "$TIMER"
if grep -A32 -F 'delegate: TimerPresetButton {' "$TIMER" | grep -Eq 'MouseArea|Rectangle[[:space:]]*\{'; then
    echo 'Timer preset delegate duplicates button surface implementation' >&2
    exit 1
fi

python3 - "$SURFACE" "$BUTTON" "$TIMER" <<'PYCODE'
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
print('Shared button surface and timer preset component delimiters: OK')
PYCODE

echo 'Timer preset buttons use the shared hover surface and preserve left/middle/wheel actions: OK'
