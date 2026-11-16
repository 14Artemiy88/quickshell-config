#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEATHER="$ROOT/components/WeatherPlaceholder.qml"
LIST="$ROOT/components/WeatherList.qml"

for file in "$WEATHER" "$LIST"; do test -f "$file"; done

grep -Fq 'import "primitives" as Primitives' "$WEATHER"
grep -Fq 'property bool active: true' "$WEATHER"
grep -Fq 'visible: active || placeholderMorph.normalizedProgress > 0.001' "$WEATHER"
grep -Fq 'id: placeholderMorph' "$WEATHER"
grep -Fq 'fromGeometry: Qt.rect(0, 0, root.width, root.height)' "$WEATHER"
grep -Fq 'toGeometry: Qt.rect(0, 0, root.width, root.height)' "$WEATHER"
grep -Fq 'progress: root.active ? 1 : 0' "$WEATHER"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$WEATHER"
grep -Fq 'animationEasing: Config.animationEasingType("standard", root.active ? "enter" : "exit")' "$WEATHER"
grep -Fq 'active: !root.hasData' "$LIST"

python3 - "$WEATHER" "$LIST" <<'PYCODE'
from pathlib import Path
import sys
weather, listing = (Path(x).read_text(encoding='utf-8') for x in sys.argv[1:])
assert 'clip: true' not in weather, 'placeholder must not clip text/button during scale morph'
assert 'opacity: placeholderMorph.normalizedProgress' in weather, 'placeholder must fade fully before its exit visibility drops'
assert 'scale: 0.97 + 0.03 * placeholderMorph.normalizedProgress' in weather
assert 'transformOrigin: Item.Center' in weather
assert 'Primitives.StyledTextButton {' in weather
assert 'root.weatherService.manualRefresh()' in weather
assert 'root.settingsRequested()' in weather
assert 'visible: !root.hasData' not in listing, 'outer visibility would interrupt the exit transition'
assert 'WeatherPlaceholder {' in listing
print('Weather placeholder entry/exit MorphGeometry and fixed parent layout: OK')
PYCODE

echo 'Weather placeholder MorphGeometry test: OK'
