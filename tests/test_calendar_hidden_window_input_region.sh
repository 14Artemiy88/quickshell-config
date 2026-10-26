#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/shell.qml" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
start = source.index('id: calendarWindow')
end = source.index('\n    WidgetWindow {', start)
calendar = source[start:end]

# Keep the layer-shell surface alive while the module is enabled to avoid
# compositor-owned fade animations. Its explicit input mask goes empty when the
# content is hidden, and the blur region follows the animated child item.
assert 'visible: Settings.calendar' in calendar
assert 'manageInputMask: true' in calendar
assert 'inputMaskEnabled: shell.calendarVisible || Config.calendarAlwaysVisible || calendarVisibility.running || shell.layoutEditMode' in calendar
assert 'backgroundBlurVisible: shell.calendarVisible || Config.calendarAlwaysVisible || calendarVisibility.running' in calendar
assert 'backgroundBlurItem: calendarVisibility.blurRegionItem' in calendar
assert 'shown: shell.calendarVisible || Config.calendarAlwaysVisible' in calendar
assert 'bottomLayer: false' in calendar
assert 'id: calendarVisibility' in calendar

# Regression guard: this problem belongs to the calendar, not CPU widgets.
assert 'clickThrough:' not in calendar
print('Calendar hidden-window input region: OK')
PY
