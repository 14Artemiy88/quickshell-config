#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import math
import sys

root = Path(sys.argv[1])
qml = (root / "components/WeatherNow.qml").read_text(encoding="utf-8")
module_frame = (root / "components/primitives/ModuleFrame.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

assert 'readonly property real contentScale: Math.max(0.01, Math.min(1,' in qml
assert 'Number(root.width) / 315' in qml and 'Number(root.height) / 80' in qml
assert 'id: weatherContent' in qml and 'width: 315' in qml and 'height: root.height' in qml
assert 'scale: root.contentScale' in qml
assert 'transformOrigin: Item.TopLeft' in qml, "scaled composition must keep its top-left origin"
assert 'x: root.widePresentation ? Math.max(0, (root.width - width * scale) / 2) : 0' in qml
assert 'y: Math.max(0, (root.height - height * scale) / 2)' in qml
assert 'readonly property bool widePresentation: root.presentationMode === "wide"' in module_frame
assert 'WeatherPlaceholder {\n        active: !root.hasData' in qml
assert 'MouseArea {\n        anchors.fill: parent' in qml
assert 'Qt.rect(Config.weatherWindColumnX, Config.weatherWindColumnY, Config.weatherWindColumnWidth, root.height)' in qml
for key in (
    'weatherTempColumnWidth', 'weatherMiddleBlockWidth', 'weatherWindColumnX',
    'weatherWindColumnWidth', 'weatherIconX', 'weatherDescriptionX', 'weatherDescriptionWidth'
):
    assert f'Config.{key}' in qml, f"user geometry field {key} must remain in use"
assert check.count('run_test "$ROOT/tests/test_weather_now_adaptive_presentation.sh"') == 1

# Exercise the intended scale/placement at representative surface sizes.
def scale(width, height):
    return max(0.01, min(1.0, width / 315.0, height / 80.0))
def wide_x(width, height):
    s = scale(width, height)
    return max(0.0, (width - 315.0 * s) / 2.0)
def y(width, height):
    s = scale(width, height)
    return max(0.0, (height - height * s) / 2.0)

assert math.isclose(scale(315, 80), 1.0)
assert math.isclose(scale(250, 80), 250 / 315)
assert math.isclose(315 * scale(250, 80), 250), "compact content must fit surface width"
assert math.isclose(y(250, 80), (80 - 80 * (250 / 315)) / 2)
assert math.isclose(scale(315, 80), 1.0), "regular default geometry must remain unchanged"
assert math.isclose(wide_x(420, 80), 52.5), "wide composition should be centered without changing user geometry"
assert math.isclose(scale(315, 64), 0.8), "short surfaces should fit vertically too"
assert math.isclose(64 * scale(315, 64), 51.2)
assert math.isclose(y(315, 64), 6.4)
print("Weather Now compact fit, regular baseline, wide centering and user geometry preservation: OK")
PY
