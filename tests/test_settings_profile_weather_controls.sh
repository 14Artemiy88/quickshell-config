#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
window = (root / "components/settings/sections/SettingsWindowSection.qml").read_text()
button = (root / "components/settings/primitives/SettingsButton.qml").read_text()
reset = (root / "components/settings/primitives/SettingsResetButton.qml").read_text()
weather = (root / "components/settings/sections/SettingsWeatherSection.qml").read_text()
general = (root / "components/settings/sections/SettingsGeneralSection.qml").read_text()

profile_area = window[window.index('text: "Активный профиль"'):window.index('id: profileActionFeedback')]
assert 'iconText: "\\uf019"' in profile_area, "Load profile button should use a Nerd Font download icon"
assert 'SettingsResetButton {' in profile_area and 'tooltip: "Удалить выбранный профиль"' in profile_area, "Profile deletion should use the red reset/delete primitive"
assert 'emphasizedHoverOnly: true' in profile_area and 'emphasizedColor: "#660000"' in profile_area and 'emphasizedHoverColor: "#aa0000"' in profile_area, "Profile deletion should use #660000 idle and #aa0000 on hover"
load_area = profile_area.split('iconText: \"\\uf019\"', 1)[0]
assert 'text: ""' in load_area and 'width: 30' in load_area, "Load profile button should be icon-only"
assert 'enabled: root.enabled' in reset, "Reset/delete primitive must forward its enabled state"
assert 'property string iconText' in button and 'property string iconFontFamily' in button, "SettingsButton should support optional Nerd Font icons"
assert 'Для работы блюра требуется поддержка композитора.' in general, "Keep the useful compositor support note"
assert 'Общий радиус для всех модулей' not in general, "Remove redundant shared blur-radius explanation"

wind_groups = [g for g in weather.split('SettingsGroup {')[1:] if 'heading: "Стрелка ветра"' in g.split('}', 1)[0]]
assert len(wind_groups) == 1, "Expected exactly one wind-arrow frame"
assert 'heading: "Размер стрелки ветра"' not in weather, "Separate wind-arrow size frame should be merged"
assert 'text: "X"' in wind_groups[0] and 'text: "Y"' in wind_groups[0] and 'text: "Размер"' in wind_groups[0], "Wind-arrow controls should be ordered X, Y, size"
assert wind_groups[0].index('text: "X"') < wind_groups[0].index('text: "Y"') < wind_groups[0].index('text: "Размер"'), "Wind-arrow column order must be X, Y, size"
assert 'Глиф направления' not in wind_groups[0] and 'weatherWindArrowWidthField' not in wind_groups[0] and 'weatherWindArrowHeightField' not in wind_groups[0], "Duplicate glyph geometry controls should be removed"
additional = weather.split('heading: "Дополнительные параметры"', 1)[1].split('SettingsGroup {', 1)[0]
assert 'text: "Значение"' not in additional, "Remove redundant Value column caption"
print("Settings profile buttons and weather wind-arrow layout: OK")
PY
