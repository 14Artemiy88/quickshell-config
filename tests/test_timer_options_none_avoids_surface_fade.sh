#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
shell = (root / "shell.qml").read_text(encoding="utf-8")
options = (root / "components/TimerOptions.qml").read_text(encoding="utf-8")
panel = shell.split('PanelWindow {\n            id: timerOptionsOverlay', 1)[1].split('\n        }\n\n\n        PanelWindow {\n            id: timerFinishedPopup', 1)[0]
assert 'visible: Settings.timer' in panel
assert 'TimerOptions {' in panel
assert 'MouseArea {' in panel and 'onClicked: timerOptionsOverlay.closeForOptions()' in panel
assert 'mask: Region { item: timerOptionsInputRegion }' in panel
assert 'width: shell.timerOptionsVisible ? parent.width : 0' in panel
assert 'height: shell.timerOptionsVisible ? parent.height : 0' in panel
assert 'focusable: timerOptionsPopup.commentMode' in panel
assert 'PopupWindow' not in panel and 'grabFocus' not in panel
assert 'visible: shell.timerOptionsVisible' not in panel
assert 'var targetOpacity = hidden && (fadeEnabled || style === "none") ? 0 : 1' in options
assert 'showOpacityAnimation.duration = fadeEnabled ? duration : 0' in options
assert 'Translate {' in options and 'clip: true' in options
assert 'slideXAnimation.duration = slideX ? duration : 0' in options
assert 'slideYAnimation.duration = slideY ? duration : 0' in options
assert 'popupCollapseScale' not in options
none_branch = options.split('if (!animationsActive())', 1)[1].split('var baseDuration', 1)[0]
assert 'opacity = targetOpacity' in none_branch and 'finishCloseOnce()' in none_branch
print('Timer options stays on a persistent surface; fade/none and true clipped slide are QML-driven: OK')
PYCODE
