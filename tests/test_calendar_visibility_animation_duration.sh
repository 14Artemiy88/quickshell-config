#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/shell.qml" "$ROOT/components/settings/sections/SettingsCalendarSection.qml" "$ROOT/Config.qml" <<'PY'
from pathlib import Path
import sys
shell = Path(sys.argv[1]).read_text(encoding="utf-8")
settings = Path(sys.argv[2]).read_text(encoding="utf-8")
config = Path(sys.argv[3]).read_text(encoding="utf-8")
start = shell.index('id: calendarVisibility')
chunk = shell[start:start + 900]
expected = 'duration: Config.animationDuration(Config.animationCalendarVisibilityStyle === "fade" ? Config.animationCalendarFadeDuration : Config.animationCalendarSlideDuration, "appearance")'
assert expected in chunk, "Calendar must use the duration belonging to the selected animation style"
assert 'Math.max(Config.animationCalendarSlideDuration, Config.animationCalendarFadeDuration)' not in chunk, "Calendar duration must not be forced to the maximum of both settings"
assert 'property int animationCalendarSlideDuration: 350' in config
assert 'property int animationCalendarFadeDuration: 250' in config
assert 'targetProperty: "animationCalendarSlideDuration"' in settings
assert 'targetProperty: "animationCalendarFadeDuration"' in settings
styles = '["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]'
assert styles in settings, "Keep all supported animation choices"
print("Calendar animation duration follows selected style: OK")
PY
