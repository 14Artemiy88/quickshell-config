#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
SHELL="$ROOT/shell.qml"
python3 - "$OPTIONS" "$SHELL" <<'PYCODE'
from pathlib import Path
import sys
options=Path(sys.argv[1]).read_text(encoding="utf-8")
shell=Path(sys.argv[2]).read_text(encoding="utf-8")
assert 'property bool popupHasBeenShown: false' in options
assert 'if (!closing && selectedFile === "" && !popupHasBeenShown)' in options
selection = options.split('onSelectedFileChanged: {', 1)[1].split('onTimersChanged:', 1)[0]
assert 'popupHasBeenShown = true' in selection
assert 'else if (!closing && popupHasBeenShown)' in selection
assert 'closeRequested()' in selection
assert 'slideOffsetX = slideTargetX(true, style)' in selection
assert 'slideOffsetY = slideTargetY(true, style)' in selection
finish=options.split('function finishCloseOnce()',1)[1].split('function startClose()',1)[0]
assert 'popupHasBeenShown = false' in finish and 'closeFinished()' in finish
panel = shell.split('PanelWindow {\n            id: timerOptionsOverlay', 1)[1].split('\n        }\n\n\n        PanelWindow {\n            id: timerFinishedPopup', 1)[0]
assert 'visible: Settings.timer' in panel
assert 'function closeForOptions()' in panel and 'timerOptionsPopup.startClose()' in panel
assert 'timerOptionsOverlay.hideAfterClose()' in panel and 'TimerOptions {' in panel
assert 'z: 1' in panel and 'PopupWindow' not in panel
assert 'timerOptionsOverlay.openForOptions()' not in shell
assert 'timerOptionsOverlay.closeForOptions()' in shell
assert 'Translate {' in options and 'popupTranslation' in options
assert 'slideXAnimation.duration = slideX ? duration : 0' in options
assert 'slideYAnimation.duration = slideY ? duration : 0' in options
print('Timer options enters and exits through the same clipped translation on a persistent layer-shell surface: OK')
PYCODE
