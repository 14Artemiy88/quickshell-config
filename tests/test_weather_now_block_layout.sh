#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
apply = (root / "js/settings/SettingsApplyWeather.js").read_text(encoding="utf-8")
persist = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
widget = (root / "components/settings/SettingsNavigationController.qml").read_text(encoding="utf-8")
section = (root / "components/settings/sections/SettingsWeatherSection.qml").read_text(encoding="utf-8")
weather = (root / "components/WeatherNow.qml").read_text(encoding="utf-8")

keys = {
    "weatherWindColumnY": "0",
    "weatherPressureX": "0",
    "weatherDescriptionX": "0",
    "weatherDescriptionWidth": "135",
    "weatherMiddleBlockWidth": "55",
    "weatherLeftBlockAlignment": '"center"',
    "weatherMiddleBlockAlignment": '"center"',
    "weatherRightBlockAlignment": '"right"',
    "weatherIconPlacement": '"center"',
}
for key, value in keys.items():
    assert re.search(rf'property (?:int|string) {key}:\s*{re.escape(value)}', config), f"Config missing {key}"
    assert re.search(rf'\b{key}:\s*{re.escape(value)}', defaults), f"defaults missing {key}"
    assert f"{key}: config.{key}" in persist, f"snapshot missing {key}"
    assert f'"{key}"' in resets, f"reset/profile restoration missing {key}"

for key, low, high in [
    ("weatherWindColumnY", -100, 100),
    ("weatherPressureX", -100, 300),
    ("weatherDescriptionX", -300, 300),
    ("weatherDescriptionWidth", 20, 400),
    ("weatherMiddleBlockWidth", 16, 180),
]:
    assert f'["{key}", {low}, {high}]' in apply, f"missing bounds for {key}"
for key in ("weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment"):
    assert key in apply and '["left", "center", "right"]' in apply
assert '["left", "center", "off"]' in apply

for heading in ("Ширина блоков", "Выравнивание блоков", "Иконка текущей погоды", "Описание погоды", "Положение элементов"):
    assert f'heading: "{heading}"' in section, f"missing settings frame {heading}"
for key in ("weatherTempColumnWidth", "weatherMiddleBlockWidth", "weatherWindColumnWidth"):
    assert f'targetProperty: "{key}"' in section, f"missing width editor {key}"
for key in ("weatherLeftBlockAlignment", "weatherMiddleBlockAlignment", "weatherRightBlockAlignment", "weatherIconPlacement"):
    assert key in section, f"missing combo control {key}"

assert 'Config.weatherIconPlacement !== "off"' in weather
assert 'Config.weatherIconPlacement === "left"' in weather
assert 'root.textAlignment(Config.weatherLeftBlockAlignment)' in weather
assert 'root.textAlignment(Config.weatherRightBlockAlignment)' in weather
assert 'Qt.rect(Config.weatherWindColumnX, Config.weatherWindColumnY, Config.weatherWindColumnWidth, root.height)' in weather, 'wind column position must remain configured'
assert 'x: Config.weatherPressureX' in weather
assert 'x: Config.weatherDescriptionX' in weather and 'width: Config.weatherDescriptionWidth' in weather
assert 'wrapMode: Text.NoWrap' in weather and 'elide: Text.ElideNone' in weather and 'clip: false' in weather
assert 'weatherMiddleBlockWidth' in widget and 'weatherDescription' in widget, "dirty/scope detection must include new Weather Now fields"
print("Weather Now block widths, alignment, icon composition, description overflow, persistence and reset: OK")
PY
