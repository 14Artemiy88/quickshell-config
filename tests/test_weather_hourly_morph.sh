#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$ROOT/components/WeatherList.qml"
ITEM="$ROOT/components/WeatherForecastItem.qml"
CHECK="$ROOT/CHECK.sh"
test -f "$LIST" && test -f "$ITEM"

grep -Fq 'model: root.hourly ? Math.min(12, root.availableEntries.length) : root.displayEntries.length' "$LIST"
grep -Fq 'readonly property bool slotActive: !root.hourly || index < root.itemCount' "$LIST"
grep -Fq 'width: forecastSlotMorph.geometryWidth' "$LIST"
grep -Fq 'toGeometry: Qt.rect(0, 0, forecastSlot.animatedTargetWidth, parent.height)' "$LIST"
grep -Fq 'progress: forecastSlot.slotActive ? 1 : 0' "$LIST"
grep -Fq 'animationPhase: forecastSlot.slotActive ? "enter" : "exit"' "$LIST"
grep -Fq 'root.hourlyMorphPhase = root.itemCount > root.previousHourlyItemCount ? "enter" : "exit"' "$LIST"
grep -Fq 'easing.bezierCurve: Config.animationBezierCurve(Config.animationWeatherMorphProfile, root.hourlyMorphPhase)' "$LIST"
grep -Fq 'entry: (root.hourly ? root.availableEntries[index] : root.displayEntries[index]) || ({})' "$LIST"
grep -Fq 'acceptedButtons: Qt.NoButton' "$LIST"
grep -Fq 'root.adjustHourlyCount(delta > 0 ? 1 : -1)' "$LIST"
grep -Fq 'test_weather_hourly_morph.sh' "$CHECK"

python3 - "$LIST" "$ITEM" <<'PYCODE'
from pathlib import Path
import sys
listing, item = [Path(p).read_text(encoding='utf-8') for p in sys.argv[1:]]
if 'availableEntries = future' not in listing:
    raise SystemExit('hourly outgoing delegates must keep their source entries while collapsing')
if 'Config.weatherHourlyCount =' in listing:
    raise SystemExit('hourly wheel transitions must not persist temporary count changes')
if 'WeatherForecastItem {' not in listing or 'Keep WeatherForecastItem (and its Image) outside MorphGeometry' not in listing:
    raise SystemExit('forecast images must stay outside MorphGeometry to preserve their direct rendering path')
if 'Image {' not in item:
    raise SystemExit('WeatherForecastItem lost its direct Image element')
print('Weather hourly MorphGeometry add/remove, retained entry data and image rendering path: OK')
PYCODE

echo 'Weather hourly MorphGeometry test: OK'
