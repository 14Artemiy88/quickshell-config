#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
qml = (root / "components/WeatherNow.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

# The air-temperature label keeps its configured offset while the comfort
# row is fully present, then moves upward into an optically corrected center
# as the comfort row collapses. The morph progress is animated by MorphGeometry.
expected = "y: Config.weatherTempOffsetY + Math.max(0, (root.height - height) / 2 - 6) * (1 - weatherComfortMorph.normalizedProgress)"
assert expected in qml, "air temperature must move to the optically corrected center as the comfort row hides"
assert 'progress: weatherComfortLabel.shouldShow ? 1 : 0' in qml, "comfort visibility must drive the shared morph progress"
assert 'readonly property bool shouldShow: Config.weatherShowComfort && comfortValue !== ""' in qml, "comfort setting and value equality must both control visibility"
assert 'return Number(comfort.replace(",", ".")) !== Number(air.replace(",", "."))' in qml, "equal air/comfort values must hide the comfort row"
assert 'run_test "$ROOT/tests/test_weather_now_temperature_vertical_center.sh"' in check, "vertical-centering test must be registered in CHECK.sh"

# Verify the position math for visible, hidden, and transitioning states.
# The default Weather Now module is 80 px high and the temperature field is 55 px.
def y(offset: float, module_height: float, text_height: float, progress: float) -> float:
    corrected_center = max(0, (module_height - text_height) / 2 - 6)
    return offset + corrected_center * (1 - progress)

assert y(3, 80, 55, 1) == 3, "visible comfort row must preserve the manual Y offset"
assert y(3, 80, 55, 0) == 9.5, "hidden comfort row must use the optically corrected center"
assert y(3, 80, 55, 0.5) == 6.25, "temperature should follow the comfort-row exit morph"
assert y(0, 80, 55, 0) == 6.5, "default hidden temperature should shift upward by 6 px from geometric center"

print("Weather Now air temperature vertical centering for hidden/equal comfort state: OK")
PYTEST
