#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
def read(rel): return (root / rel).read_text(encoding='utf-8')
def require(source, token, message):
    assert token in source, message

defaults = read('js/settings/SettingsDefaults.js')
apply_core = read('js/settings/SettingsApplyCore.js')
persistence = read('js/settings/SettingsPersistence.js')
resets = read('js/settings/SettingsResets.js')
settings = read('components/settings/sections/SettingsTimersSection.qml')
widget = read('components/TimerWidget.qml')
config = read('Config.qml')

for key in ('timerIconEnabled', 'timerAlarmIconEnabled'):
    require(defaults, f'{key}: true', f'{key} must default to enabled for backward-compatible appearance')
    require(config, f'property bool {key}: true', f'{key} must be a declared Config property with a notify signal')
    require(apply_core, f'o.{key} !== undefined) Config.{key} = !!o.{key}', f'{key} must load from saved settings')
    require(persistence, f'{key}: config.{key}', f'{key} must be persisted')
    assert resets.count(f'"{key}"') >= 2, f'{key} must participate in settings and profile reset'

require(settings, 'heading: "Иконки таймера и будильника"', 'Icon settings frame missing')
require(settings, 'text: "Вкл."', 'Enable column header missing')
require(settings, 'indicatorOnly: true', 'Compact visibility checkbox expected')
require(settings, 'checked: modelData === "timer" ? Config.timerIconEnabled : Config.timerAlarmIconEnabled', 'Checkbox must bind to the matching icon state')
require(settings, 'if (modelData === "timer") Config.timerIconEnabled = checked', 'Timer icon checkbox must update timer visibility')
require(settings, 'else Config.timerAlarmIconEnabled = checked', 'Alarm icon checkbox must update alarm visibility')

require(widget, 'opacity: Config.timerIconEnabled && root.controlsMode === 0 ? 1 : 0', 'Timer icon display must respect its enable flag')
require(widget, 'opacity: Config.timerAlarmIconEnabled && root.controlsMode === 0 ? 1 : 0', 'Alarm icon display must respect its enable flag')
require(widget, 'const inTimer = Config.timerIconEnabled', 'Disabled timer icon must not keep an invisible hover zone')
require(widget, 'const timerStartY = Config.timerIconY - minY', 'Timer hitbox Y offset must use enabled icon geometry')
require(widget, 'const inAlarm = Config.timerAlarmIconEnabled', 'Disabled alarm icon must not keep an invisible hover zone')
require(widget, 'const alarmStartY = Config.timerAlarmIconY - minY', 'Alarm hitbox Y offset must use enabled icon geometry')
require(widget, 'property bool hasAnyIcon: Config.timerIconEnabled || Config.timerAlarmIconEnabled', 'Interaction area must collapse when both icons are disabled')
require(widget, 'function onTimerIconEnabledChanged()', 'Turning off active timer icon must close its preset panel')
require(widget, 'function onTimerAlarmIconEnabledChanged()', 'Turning off active alarm icon must close its alarm panel')
print('Timer/alarm icon visibility settings, interaction zones, persistence and reset: OK')
PY
