#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / 'Config.qml').read_text()
defaults = (root / 'js/settings/SettingsDefaults.js').read_text()
persistence = (root / 'js/settings/SettingsPersistence.js').read_text()
apply_weather = (root / 'js/settings/SettingsApplyWeather.js').read_text()
resets = (root / 'js/settings/SettingsResets.js').read_text()
ui = (root / 'components/settings/sections/SettingsWeatherSection.qml').read_text()

assert 'property string weatherComfortOutlineColor: "#000000"' in config
assert 'property int weatherComfortOutlineWidth: 1' in config
assert 'weatherComfortOutlineColor: "#000000"' in defaults
assert 'weatherComfortOutlineWidth: 1' in defaults
assert 'weatherComfortOutlineColor: String(config.weatherComfortOutlineColor)' in persistence
assert 'weatherComfortOutlineWidth: config.weatherComfortOutlineWidth' in persistence
assert '["weatherComfortOutlineWidth", 0, 4]' in apply_weather
assert 'Config.weatherComfortOutlineColor = comfortOutlineColor' in apply_weather
assert '"weatherComfortOutlineColor", "weatherComfortOutlineWidth"' in resets
assert 'label: "Цвет обводки комфортной температуры"' in ui
assert 'targetProperty: "weatherComfortOutlineColor"' in ui
assert 'text: "Толщина обводки"' in ui
assert 'targetProperty: "weatherComfortOutlineWidth"' in ui
assert 'minimum: 0; maximum: 4' in ui
print('Weather comfort outline settings/profile/reset wiring: OK')
PY
