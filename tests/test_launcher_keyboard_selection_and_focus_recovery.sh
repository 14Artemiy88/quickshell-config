#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
source = (root / "components/launcher/Launcher.qml").read_text()

# The highlight owns its geometry so both pointer and keyboard index changes
# animate through the same x/y/size Behaviors, including when key navigation
# scrolls the ListView or wallpaper GridView explicitly.
assert 'readonly property var selectedDelegate: GridView.view ? GridView.view.currentItem' in source
assert 'ListView.view ? ListView.view.currentItem : null)' in source
for prop in ("x", "y", "width", "height"):
    assert f"Behavior on {prop} {{" in source, f"selection-frame {prop} must animate"
assert source.count('highlightFollowsCurrentItem: false') == 10
assert source.count('highlight: launcherSelectionHighlight') == 10
assert 'highlightMoveDuration:' not in source and 'highlightResizeDuration:' not in source
for fn in ("moveSelectionDown()", "moveSelectionUp()"):
    start = source.index(f"function {fn}")
    end = source.find("\n    function ", start + 12)
    block = source[start:end if end >= 0 else len(source)]
    assert 'positionViewAtIndex' in block, f"{fn} should keep selected items visible while the frame animates"

# PanelWindow does not expose Window.active: use the active-focus state of
# the concrete keyboard targets, and defer closure to tolerate focus handoff
# between the search field and the Power-mode focus scope.
assert 'onActiveChanged:' not in source
assert not re.search(r'root\.active(?![A-Za-z0-9_])', source)
assert 'function launcherKeyboardFocusIsActive()' in source
assert 'return launcherBox.activeFocus' in source
assert 'return searchField.activeFocus' in source
assert source.count('onActiveFocusChanged: root.handleLauncherKeyboardFocusChanged()') == 2
assert 'function handleLauncherKeyboardFocusChanged()' in source
assert 'launcherFocusLossTimer.restart()' in source
assert 'interval: 100' in source
assert 'root.visible && !root.launcherKeyboardFocusIsActive()' in source
assert 'root.hideLauncher()' in source[source.index('id: launcherFocusLossTimer'):source.index('color: theme.transparent')]
assert 'function restoreLauncherKeyboardFocus()' in source
assert 'launcherBox.forceActiveFocus()' in source
assert 'searchField.forceActiveFocus()' in source
assert 'Qt.callLater(root.restoreLauncherKeyboardFocus)' in source
hide_start = source.index('function hideLauncher()')
hide_end = source.find('\n    function ', hide_start + 12)
hide_block = source[hide_start:hide_end if hide_end >= 0 else len(source)]
assert 'launcherFocusLossTimer.stop()' in hide_block
assert 'root.launcherSessionHadFocus = false' in hide_block
# Keyboard handling remains on the search field and list navigation still updates indices.
assert 'Keys.onPressed: function(event)' in source
assert 'function moveSelectionDown()' in source and 'function moveSelectionUp()' in source
print('Launcher keyboard selection animation and focus recovery wiring: OK')
PY
