#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
SHELL="$ROOT/shell.qml"
python3 - "$OPTIONS" "$SHELL" <<'PY'
from pathlib import Path
import sys
options=Path(sys.argv[1]).read_text(encoding='utf-8')
shell=Path(sys.argv[2]).read_text(encoding='utf-8')
assert 'ParallelAnimation {\n        id: visualTransition' in options, 'opacity and scale must share one visual transition'
assert 'showOpacityAnimation.start()' not in options and 'showScaleAnimation.start()' not in options, 'child animations must not run independently'
assert 'visualTransition.start()' in options and 'visualTransition.stop()' in options
assert 'onFinished: root.finishCloseOnce()' in options, 'close lifecycle must follow actual animation completion'
assert 'function finishCloseOnce()' in options
finish=options.split('function finishCloseOnce()',1)[1].split('function startClose()',1)[0]
assert 'if (!closing || closeSignalSent) return' in finish, 'close completion must be emitted at most once'
assert 'closeSignalSent = true' in finish
close=options.split('function startClose()',1)[1].split('function updateSelected()',1)[0]
assert 'closeSignalSent = false' in close and 'closing = true' in close and 'syncVisualState()' in close
assert 'closeTimer' not in options, 'separate timing source must be removed'
assert 'function onAnimationsEnabledChanged() { root.syncVisualState() }' in options
assert 'function onAnimationExpansionEnabledChanged() { root.syncVisualState() }' in options
# The host still waits for the closeFinished signal before removing the popup surface.
assert 'onCloseFinished: {' in shell and 'shell.timerOptionsVisible = false' in shell
print('TimerOptions animation lifecycle and popup-close synchronization: OK')
PY
