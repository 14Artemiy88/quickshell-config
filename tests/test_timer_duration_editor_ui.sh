#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
WIDGET="$ROOT/components/TimerWidget.qml"
SHELL="$ROOT/shell.qml"
SCRIPT="$ROOT/scripts/timer"
DAEMON="$ROOT/scripts/timer.d/daemon.sh"

for file in "$OPTIONS" "$WIDGET" "$SHELL" "$SCRIPT" "$DAEMON"; do
    [[ -f "$file" ]] || { echo "Missing timer duration editor file: $file" >&2; exit 1; }
done

grep -Fq 'duration: { id: "duration", icon: Config.timerOptionsDurationIcon' "$OPTIONS" || { echo 'Timer options popup has no configurable duration-edit action' >&2; exit 1; }
grep -Fq 'modelData.id === "duration"' "$OPTIONS" || { echo 'Timer options duration edit action is not routed' >&2; exit 1; }
grep -Fq 'property bool durationMode: false' "$OPTIONS" || { echo 'Timer duration editor mode is missing' >&2; exit 1; }
grep -Fq 'validator: IntValidator { bottom: 1; top: 10080 }' "$OPTIONS" || { echo 'Timer duration field is not range-validated' >&2; exit 1; }
grep -Fq 'function openDurationEditor()' "$OPTIONS" || { echo 'Duration editor open action is missing' >&2; exit 1; }
grep -Fq 'function saveDuration()' "$OPTIONS" || { echo 'Duration editor save action is missing' >&2; exit 1; }
grep -Fq '"set_duration"' "$OPTIONS" || { echo 'Duration editor does not call the duration update action' >&2; exit 1; }
grep -Fq 'focusable: timerOptionsPopup.commentMode || timerOptionsPopup.durationMode' "$SHELL" || { echo 'Timer overlay does not enable keyboard focus for duration input' >&2; exit 1; }
grep -Fq '"duration_minutes"' "$WIDGET" || { echo 'Timer widget does not sync target duration from daemon data' >&2; exit 1; }
grep -Fq '"duration_minutes":%s' "$DAEMON" || { echo 'Timer daemon does not expose target duration' >&2; exit 1; }
grep -Fq 'set_duration)  timer_set_duration "$2" "$3";;' "$SCRIPT" || { echo 'Timer CLI does not expose set_duration' >&2; exit 1; }

python3 - "$OPTIONS" "$SHELL" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for name in sys.argv[1:]:
    s=Path(name).read_text(encoding='utf-8')
    stack=[]; quote=None; esc=False; line=False; block=False; i=0
    while i<len(s):
        c=s[i]; n=s[i+1] if i+1<len(s) else ''
        if line:
            if c=='\n': line=False
            i+=1; continue
        if block:
            if c=='*' and n=='/': block=False; i+=2; continue
            i+=1; continue
        if quote:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': line=True; i+=2; continue
        if c=='/' and n=='*': block=True; i+=2; continue
        if c in ('"', "'", '`'): quote=c; i+=1; continue
        if c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0]!=pairs[c]: raise SystemExit(f'{name}: unmatched {c} at {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at {stack[-1][1]}')
print('Timer duration editor and fullscreen overlay QML delimiters: OK')
PYCODE

echo 'Timer duration editor UI, keyboard focus, daemon data and command wiring: OK'
