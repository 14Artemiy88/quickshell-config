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
assert 'visible: Settings.timer' in panel, 'the stable layer-shell surface must stay alive while the timer module is enabled'
assert 'screen: timerWindow.screen' in panel
assert 'anchors.top: true' in panel and 'anchors.left: true' in panel
assert 'anchors.right: true' in panel and 'anchors.bottom: true' in panel
assert 'focusable: timerOptionsPopup.commentMode || timerOptionsPopup.durationMode || timerOptionsPopup.colorMode' in panel, 'keyboard focus must cover comment, duration and color editing'
assert 'WlrLayershell.layer: WlrLayer.Overlay' in panel
assert 'mask: Region { item: timerOptionsInputRegion }' in panel
assert 'width: shell.timerOptionsVisible ? parent.width : 0' in panel
assert 'height: shell.timerOptionsVisible ? parent.height : 0' in panel
outside = panel.split('MouseArea {', 1)[1].split('}', 1)[0]
assert 'anchors.fill: parent' in outside
assert 'enabled: shell.timerOptionsVisible && !timerOptionsPopup.closing' in outside
assert 'onClicked: timerOptionsOverlay.closeForOptions()' in outside
close = panel.split('function closeForOptions()', 1)[1].split('function hideAfterClose()', 1)[0]
assert 'shell.timerOptionsVisible = false' in close
assert 'timerOptionsPopup.commentMode = false' in close
assert 'timerOptionsPopup.closeColorEditor()' in close
assert 'timerOptionsPopup.startClose()' in close
assert 'setSurfaceVisible' not in panel and 'grabFocus' not in panel
assert 'TimerOptions {' in panel
assert 'x: Settings.geometry.timerOptions[0]' in panel
assert 'y: Settings.geometry.timerOptions[1]' in panel
assert 'z: 1' in panel, 'the card must be above the full-screen outside-click catcher'
assert 'onCloseFinished: {' in panel and 'timerOptionsOverlay.hideAfterClose()' in panel
assert 'openForOptions' not in panel and 'PopupWindow' not in shell.split('id: timerWindow', 1)[1].split('id: timerFinishedPopup', 1)[0]

window = shell.split('id: timerWindow', 1)[1].split('TimerWidget { id: timerWidget', 1)[0]
assert 'keyboardEnabled: timerOptionsPopup.commentMode' not in window, 'keyboard input is owned by the options surface while editing'
input_block = options.split('TextInput {\n                id: commentInput', 1)[1].split('\n            }', 1)[0]
for required in ('focus: root.commentMode', 'activeFocusOnPress: true', 'activeFocusOnTab: true', 'selectByMouse: true', 'onActiveFocusChanged:'):
    assert required in input_block, f'comment editor input behavior missing: {required}'
focus = options.split('function focusCommentInput()', 1)[1].split('onCommentModeChanged:', 1)[0]
assert focus.count('Qt.callLater(function() {') == 2
assert 'commentInput.forceActiveFocus(Qt.OtherFocusReason)' in focus
assert 'commentInput.cursorPosition = commentInput.text.length' in focus
assert 'commentInput.selectAll()' in focus
assert 'if (!root.commentMode || root.closing || !root.enabled) return' in focus
assert 'if (commentMode) focusCommentInput()' in options
assert 'if (colorMode) focusColorInput()' in options
assert 'colorInput.forceActiveFocus(Qt.OtherFocusReason)' in options
print('Timer options persistent input surface, outside-click dismissal, and comment/duration/color keyboard focus: OK')
PYCODE
