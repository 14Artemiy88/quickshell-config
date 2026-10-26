#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
profiles = (root / "components/settings/sections/SettingsWindowSection.qml").read_text(encoding="utf-8")
weather = (root / "components/settings/sections/SettingsWeatherSection.qml").read_text(encoding="utf-8")

# Hide the entire reset-all row, not just its button, when nothing is overridden.
row_start = profiles.index('text: "Сбросить все настройки"')
start = profiles.rfind("Row {", 0, row_start)
end = profiles.index("\n                            }", row_start) + len("\n                            }")
row = profiles[start:end]
assert 'visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1 && settings.hasResetChanges("all")' in row
assert 'actionAvailable: settings.hasResetChanges("all")' in row

comfort = weather.split('heading: "Температура комфорта"', 1)[1].split('heading: "Положение элементов"', 1)[0]
assert 'text: "Положение Y"' in comfort
assert 'text: "Смещение X"' in comfort
assert 'text: "Смещение X / Y"' not in comfort
assert 'id: weatherComfortOffsetYField' not in comfort
assert 'value: Config.weatherComfortY + Config.weatherComfortOffsetY' in comfort
assert 'Config.weatherComfortY = baseY' in comfort
assert 'Config.weatherComfortOffsetY = n - baseY' in comfort
assert 'minimum: -120; maximum: 200' in comfort
print("Profiles reset-all visibility and single effective comfort-Y control: OK")
PY
