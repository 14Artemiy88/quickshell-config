#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsWeatherSection.qml"

# The nine-direction editor stays under its existing header and uses the
# shared geometry primitive for a clipped expand/collapse transition.
grep -Fq 'import "../../primitives"' "$QML"
grep -Fq 'id: windDirectionSettingsHeader' "$QML"
grep -Fq 'onClicked: weatherSection.windDirectionSettingsExpanded = !weatherSection.windDirectionSettingsExpanded' "$QML"
grep -Fq 'id: windDirectionRowsMorph' "$QML"
grep -Fq 'visible: weatherSection.windDirectionSettingsExpanded || normalizedProgress > 0.001' "$QML"
grep -Fq 'fromGeometry: Qt.rect(0, 0, parent.width, 0)' "$QML"
grep -Fq 'toGeometry: Qt.rect(0, 0, parent.width, windDirectionRowsContent.implicitHeight)' "$QML"
grep -Fq 'progress: weatherSection.windDirectionSettingsExpanded ? 1 : 0' "$QML"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$QML"
grep -Fq 'animationEasing: Config.animationEasingType("standard", weatherSection.windDirectionSettingsExpanded ? "enter" : "exit")' "$QML"

# All nine direction rows remain present and are no longer independently
# toggled with visible, so their parent height can animate as one unit.
for label in 'Без направления (0)' 'Север (1)' 'Северо-восток (2)' 'Восток (3)' 'Юго-восток (4)' 'Юг (5)' 'Юго-запад (6)' 'Запад (7)' 'Северо-запад (8)'; do
    grep -Fq "label: \"$label\"" "$QML"
done
python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('id: windDirectionRowsMorph')
end = s.index('\n    }\n    SettingsGroup {', start)
block = s[start:end]
assert block.count('visible:') == 1, 'only the MorphGeometry wrapper should control visibility'
assert block.count('WeatherWindDirectionSettingsRow {') == 9, 'all nine direction rows should remain in the animated content'
PYTEST

printf 'Weather wind-direction editor MorphGeometry integration: OK\n'
