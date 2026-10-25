#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/shell.qml" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
start = source.index('id: mopidyWindow')
end = source.index('\n    WidgetWindow {', start)
window = source[start:end]

# Keep a transparent layer surface while Mopidy is enabled so the compositor
# cannot override module `none` with its own fade. Empty mask is click-through;
# blur follows the actual animated content item.
assert 'visible: Settings.mopidy' in window
assert 'manageInputMask: true' in window
assert 'inputMaskEnabled: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running || shell.layoutEditMode' in window
assert 'backgroundBlurVisible: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running' in window
assert 'backgroundBlurItem: mopidyVisibility.blurRegionItem' in window
assert 'shown: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible' in window
assert 'id: mopidyVisibility' in window

# The hidden-panel hover region is also a real input surface. It must disappear
# when the whole Mopidy module is toggled off, while preserving the hover reveal
# feature whenever Mopidy is enabled/shown.
hover_start = source.index('id: mopidyTopHoverWindow')
hover_end = source.index('\n    WidgetWindow {', hover_start)
hover = source[hover_start:hover_end]
assert 'visible: Settings.mopidy && (!Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible) && Config.mopidyHideTopPanel && !shell.mopidyTopReveal' in hover
assert 'onEntered: shell.mopidyTopReveal = true' in hover
# Closing via either Player or CAVA resets the auto-hidden top panel state.
assert source.count('shell.mopidyTopReveal = false') >= 4
print('Mopidy hidden-window input region: OK')
PY
