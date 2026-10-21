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

# A top-layer calendar must not leave an invisible PanelWindow covering desktop
# input after its close animation has completed. Keep it alive while visible,
# animating, or in layout editing so both animation and repositioning still work.
assert 'visible: Settings.calendar && (shell.calendarVisible || calendarVisibility.running || shell.layoutEditMode)' in calendar
assert 'shown: shell.calendarVisible' in calendar
assert 'bottomLayer: false' in calendar
assert 'id: calendarVisibility' in calendar

# Regression guard: this problem belongs to the calendar, not CPU widgets.
assert 'clickThrough:' not in calendar
print('Calendar hidden-window input region: OK')
PY
