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

# A toggled-off Mopidy surface must not remain above desktop applications after
# the hide animation. Layout editing still needs the window for positioning.
assert 'visible: Settings.mopidy && (!Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible || mopidyVisibility.running || shell.layoutEditMode)' in window
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
