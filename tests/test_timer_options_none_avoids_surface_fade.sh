#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
shell = (root / "shell.qml").read_text(encoding="utf-8")
options = (root / "components/TimerOptions.qml").read_text(encoding="utf-8")
block = shell.split('PopupWindow {\n            id: timerOptionsOverlay', 1)[1].split('            // The popup surface remains alive.', 1)[0]
assert 'property bool surfaceActive: false' in block
assert 'visible: surfaceActive' in block, 'native surface visibility must be independent from the popup content visibility'
assert 'surfaceActive = Settings.timer' in block, 'the native surface should be created when the Timer module is enabled'
assert 'grabFocus: shell.timerOptionsVisible && surfaceActive' in block
visible_handler = block.split('onVisibleChanged: {', 1)[1].split('            // The popup surface remains alive.', 1)[0]
assert 'if (!visible)' in visible_handler
assert visible_handler.index('surfaceActive = false') < visible_handler.index('surfaceActive = true'), 'native dismissals must re-arm the surface'
assert 'if (wasOptionsVisible && !timerOptionsPopup.closing)' in visible_handler
close_finished = block.split('onCloseFinished: {', 1)[1].split('\n                }', 1)[0]
assert 'timerOptionsOverlay.visible = false' not in close_finished
assert 'timerOptionsOverlay.surfaceActive = false' not in close_finished
assert 'var targetOpacity = hidden && (fadeEnabled || style === "none") ? 0 : 1' in options
none_branch = options.split('if (!animationsActive())', 1)[1].split('var baseDuration', 1)[0]
assert 'opacity = targetOpacity' in none_branch
assert 'finishCloseOnce()' in none_branch
# Normal selection/open/close paths must not toggle the native popup itself.
selection = shell.split('function onSelectedFileChanged() {', 1)[1].split('\n        }', 1)[0]
assert 'timerOptionsOverlay.visible =' not in selection
assert 'timerOptionsOverlay.surfaceActive = true' in selection
print('Timer options style none bypasses QML transitions and keeps the native surface alive across normal open/close: OK')
PYCODE
