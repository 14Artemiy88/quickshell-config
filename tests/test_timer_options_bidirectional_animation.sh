#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
options = (root / "components/TimerOptions.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")

assert 'property bool popupHasBeenShown: false' in options
assert 'if (!closing && selectedFile === "" && !popupHasBeenShown)' in options
selection = options.split('onSelectedFileChanged: {', 1)[1].split('onTimersChanged:', 1)[0]
assert 'popupHasBeenShown = true' in selection
assert 'else if (!closing && popupHasBeenShown)' in selection
assert 'startClose()' in selection, 'clearing a previously selected timer must run the actual exit transition'
finish = options.split('function finishCloseOnce()', 1)[1].split('function startClose()', 1)[0]
assert 'popupHasBeenShown = false' in finish
assert 'closeFinished()' in finish

visible = shell.split('onVisibleChanged: {', 1)[1].split('// The popup surface remains alive.', 1)[0]
assert 'if (!visible)' in visible
assert 'if (Settings.timer)' in visible
assert 'var wasOptionsVisible = shell.timerOptionsVisible' in visible
assert 'if (wasOptionsVisible && !timerOptionsPopup.closing)' in visible
assert visible.index('surfaceActive = false') < visible.index('surfaceActive = true'), 'native focus-grab dismissal must restore the popup surface before the configured close animation'
assert 'timerOptionsPopup.startClose()' in visible
assert 'timerWidget.selectedFile = ""' in visible, 'disabling Timer must still clean up selection'

changed = shell.split('function onSelectedFileChanged() {', 1)[1].split('\n        }', 1)[0]
assert 'timerOptionsPopup.startClose()' in changed
assert 'timerOptionsPopup.syncVisualState()' in changed
assert 'timerOptionsOverlay.visible = false' not in changed, 'selection clearing must not hide the native surface before slide/fade completion'
close_finished = shell.split('onCloseFinished: {', 1)[1].split('\n                }', 1)[0]
assert 'timerOptionsOverlay.visible = false' not in close_finished, 'keep the native surface alive so compositor effects cannot override style none'

none_branch = options.split('function syncVisualState()', 1)[1].split('var baseDuration', 1)[0]
assert 'if (!animationsActive())' in none_branch
for assignment in ('opacity = targetOpacity', 'scale = targetScale', 'popupTranslation.x = targetX', 'popupTranslation.y = targetY'):
    assert assignment in none_branch
print('Timer options animate both enter/exit directions; none is immediate; native dismissal waits for QML close: OK')
PYCODE
