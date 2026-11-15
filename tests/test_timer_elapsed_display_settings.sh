#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PYTHON'
from pathlib import Path
import sys
root = Path(sys.argv[1])
def read(rel): return (root / rel).read_text(encoding="utf-8")
def require(source, token, message):
    assert token in source, message

config = read("Config.qml")
defaults = read("js/settings/SettingsDefaults.js")
apply = read("js/settings/SettingsApplyTimerPlayer.js")
persistence = read("js/settings/SettingsPersistence.js")
resets = read("js/settings/SettingsResets.js")
widget = read("components/TimerWidget.qml")
settings = read("components/settings/sections/SettingsTimersSection.qml")

require(config, 'property string timerElapsedFont: "LED"', "Timer elapsed font must be a reactive Config property")
require(config, 'property int timerElapsedFontSize: 35', "Timer elapsed base size must preserve the previous default")
require(defaults, 'timerElapsedFont: "LED"', "Timer elapsed font default must preserve the previous display")
require(defaults, 'timerElapsedFontSize: 35', "Timer elapsed size default must preserve the previous display")
require(apply, 'o.timerElapsedFont !== undefined) Config.timerElapsedFont = String(o.timerElapsedFont)', "Timer elapsed font must load, including empty system-font override")
require(apply, '["timerElapsedFontSize", 8, 60]', "Timer elapsed size must be range-limited")
require(persistence, 'timerElapsedFont: config.timerElapsedFont', "Timer elapsed font must be persisted")
require(persistence, 'timerElapsedFontSize: config.timerElapsedFontSize', "Timer elapsed size must be persisted")
assert resets.count('"timerElapsedFont"') >= 2, "Timer elapsed font must participate in module and timer reset scopes"
assert resets.count('"timerElapsedFontSize"') >= 2, "Timer elapsed size must participate in module and timer reset scopes"

require(settings, 'heading: "Отображение времени"', "Elapsed time settings frame missing")
require(settings, 'targetProperty: "timerElapsedFont"', "Shared font field must target the timer elapsed font")
require(settings, 'targetProperty: "timerElapsedFontSize"', "Size field must target the timer elapsed font size")
require(widget, 'font.family: Config.timerElapsedFont', "Timer countdown must use its own font setting")
require(widget, 'readonly property int elapsedTimeDisplaySize', "Adaptive timer display size helper missing")
require(widget, 'Config.timerElapsedFontSize', "Adaptive timer display must use its configured base size")
require(widget, 'root.elapsedTimeDisplaySize', "Rendered timer and width metrics must use the configured size")
print("Timer elapsed display font/size settings, adaptive sizing, persistence and reset: OK")
PYTHON
