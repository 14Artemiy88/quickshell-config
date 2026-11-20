#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/components/TimerWidget.qml"
CHECK="$ROOT/CHECK.sh"
test -f "$SOURCE"

grep -Fq 'timerModel.setProperty(i, "removing", true)' "$SOURCE"
grep -Fq 'timerModel.setProperty(i, "removing", false)' "$SOURCE"
grep -Fq 'inserted.removing = false' "$SOURCE"
grep -Fq 'inserted.appearing = true' "$SOURCE"
grep -Fq 'height: timerRowMorph.geometryHeight' "$SOURCE"
grep -Fq 'required property bool removing' "$SOURCE"
grep -Fq 'property real rowProgress: 0' "$SOURCE"
grep -Fq 'progress: timerRowSlot.rowProgress' "$SOURCE"
grep -Fq 'animationDuration: 0' "$SOURCE"
grep -Fq 'property bool transitionInitialized: false' "$SOURCE"
grep -Fq 'if (!timerRowSlot.transitionInitialized)' "$SOURCE"
grep -Fq 'if (timerRowSlot.removing)' "$SOURCE"
grep -Fq 'timerRowSlot.startExitTransition()' "$SOURCE"
grep -Fq 'timerRowSlot.startEntryTransition()' "$SOURCE"
grep -Fq 'onFinished: timerRowSlot.finishExitTransition()' "$SOURCE"
grep -Fq 'onFinished: root.finishTimerRowAppearance' "$SOURCE"
grep -Fq 'function finishTimerRowRemoval(file)' "$SOURCE"
grep -Fq 'function finishTimerRowAppearance(file)' "$SOURCE"
grep -Fq 'enabled: !timerRowSlot.removing' "$SOURCE"

python3 - "$SOURCE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding='utf-8')
start = source.index('function syncTimerModel(items)')
end = source.index('function finishTimerRowAppearance(file)', start)
sync = source[start:end]
if 'timerModel.remove(' in sync:
    raise SystemExit('syncTimerModel must retain outgoing rows until the delegate exit animation completes')
if 'timerModel.remove(i)' not in source[source.index('function finishTimerRowRemoval(file)'):source.index('\n    Process {', source.index('function finishTimerRowRemoval(file)'))]:
    raise SystemExit('outgoing timer rows must be removed after the delegate reports exit completion')
if 'running: !!timerData.removing' in source or 'interval: root.timerRowMorphDuration + 40' in source:
    raise SystemExit('timer row cleanup must be driven by the actual animation completion, not a guessed timer')
if 'Component.onCompleted:' not in source[source.index('id: timerRowSlot'):source.index('id: timerRowMorph')]:
    raise SystemExit('late-created tombstone delegates must initialize full-size before running exit')
row_delegate = source[source.index('id: timerRowSlot'):source.index('id: timerRowMorph')]
for role in ('file', 'comment', 'timer', 'color', 'sign', 'removing', 'appearing'):
    if f'required property string {role}' not in row_delegate and f'required property bool {role}' not in row_delegate:
        raise SystemExit(f'timer row delegate must explicitly bind the {role} ListModel role')
if 'property var timerData: model' in row_delegate or 'model.' in row_delegate:
    raise SystemExit('timer row delegate must not use the unavailable implicit model object with required properties')
if 'timerRowSlot.comment' not in row_delegate or 'timerRowSlot.color' not in row_delegate or 'timerRowSlot.sign' not in row_delegate:
    raise SystemExit('timer row data object must be assembled from explicitly bound ListModel roles')
# Reordering active rows while a middle tombstone is exiting makes ListModel.move()
# carry that tombstone across its neighbours. Verify the source defers all moves
# until the outgoing row has actually been removed.
if 'let hasOutgoingRows = false' not in sync or 'if (!hasOutgoingRows)' not in sync:
    raise SystemExit('server-order reordering must be deferred while outgoing timer rows remain')
reorder_guard = sync.index('if (!hasOutgoingRows)')
move_call = sync.index('timerModel.move(source, target, 1)', reorder_guard)
if move_call < reorder_guard or 'for (let target = 0; target < visible.length; ++target)' not in sync[reorder_guard:move_call]:
    raise SystemExit('timer row moves must remain inside the no-outgoing-rows guard')
# Regression scenario: deleting B from [A, B, C] must not move B to the end;
# after B's exit it is removed, leaving [A, C] in the expected order.
rows = [{'file': 'A', 'removing': False}, {'file': 'B', 'removing': True}, {'file': 'C', 'removing': False}]
visible = ['A', 'C']
if any(row['removing'] for row in rows):
    pass  # Deliberately defer moves and preserve the tombstone's original slot.
else:
    for target, file in enumerate(visible):
        source = next((i for i in range(target + 1, len(rows)) if rows[i]['file'] == file), -1)
        if source >= 0:
            rows.insert(target, rows.pop(source))
if [row['file'] for row in rows] != ['A', 'B', 'C']:
    raise SystemExit('middle timer tombstone must retain its original position during exit')
rows.pop(1)
if [row['file'] for row in rows] != visible:
    raise SystemExit('active timer order must be correct after the outgoing row is removed')
if 'layoutTimerCount' not in source or 'timerModel.count' not in source[source.index('readonly property int layoutTimerCount'):source.index('readonly property int timerRowHeight')]:
    raise SystemExit('adaptive timer surface height must include outgoing rows during collapse')
# Check delimiters while ignoring strings and comments.
pairs={')':'(',']':'[','}':'{'}; stack=[]; quote=None; escaped=False; line=False; block=False; i=0
while i < len(source):
    c=source[i]; n=source[i+1] if i+1 < len(source) else ''
    if line:
        if c=='\n': line=False
        i+=1; continue
    if block:
        if c=='*' and n=='/': block=False; i+=2; continue
        i+=1; continue
    if quote:
        if escaped: escaped=False
        elif c=='\\': escaped=True
        elif c==quote: quote=None
        i+=1; continue
    if c=='/' and n=='/': line=True; i+=2; continue
    if c=='/' and n=='*': block=True; i+=2; continue
    if c in ('"', "'", '`'): quote=c; i+=1; continue
    if c in '([{': stack.append((c,i))
    elif c in ')]}':
        if not stack or stack[-1][0] != pairs[c]: raise SystemExit(f'unbalanced {c} at {i}')
        stack.pop()
    i+=1
if stack: raise SystemExit(f'unclosed {stack[-1][0]} at {stack[-1][1]}')
print('Timer row delegate-owned MorphGeometry lifecycle, reversible entry/exit, completion-driven cleanup and QML structure: OK')
PYCODE

echo 'Timer rows delegate-owned MorphGeometry lifecycle test: OK'
