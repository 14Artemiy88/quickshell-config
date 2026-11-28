#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/WeatherNow.qml"
fail() { echo "Weather Now live data MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "primitives" as Primitives' "$QML" || fail "shared primitive import missing"
for token in \
    'id: weatherIconMorph' \
    'progress: root.hasData && root.normalizedIconCode !== "" && Config.weatherIconPlacement !== "off" ? 1 : 0' \
    'visible: (root.hasData && root.normalizedIconCode !== "" && Config.weatherIconPlacement !== "off") || normalizedProgress > 0.001' \
    'id: weatherWindMorph' \
    'progress: root.hasData ? 1 : 0' \
    'visible: root.hasData || normalizedProgress > 0.001' \
    'animationDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, "appearance")' \
    'scale: 0.96 + 0.04 * weatherIconMorph.normalizedProgress' \
    'scale: 0.96 + 0.04 * weatherWindMorph.normalizedProgress' \
    'active: !root.hasData'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / "components/WeatherNow.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

def extract_block(source, marker):
    start = source.find(marker)
    assert start >= 0, f"missing block: {marker}"
    opening = source.find("{", start)
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=opening
    pairs={")":"(", "]":"[", "}":"{"}
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1 < len(source) else ""
        if line_comment:
            if c=="\n": line_comment=False
            i+=1; continue
        if block_comment:
            if c=="*" and n=="/": block_comment=False; i+=2; continue
            i+=1; continue
        if quote:
            if escaped: escaped=False
            elif c=="\\": escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=="/" and n=="/": line_comment=True; i+=2; continue
        if c=="/" and n=="*": block_comment=True; i+=2; continue
        if c in ("'", '"', '`'): quote=c; i+=1; continue
        if c in "([{": stack.append(c)
        elif c in ")]}":
            assert stack and stack[-1]==pairs[c], f"unexpected {c} in {marker}"
            stack.pop()
            if not stack: return source[start:i+1]
        i+=1
    raise AssertionError(f"unclosed block: {marker}")

icon=extract_block(qml, "Primitives.MorphGeometry {\n            id: weatherIconMorph")
wind=extract_block(qml, "Primitives.MorphGeometry {\n            id: weatherWindMorph")
placeholder=extract_block(qml, "WeatherPlaceholder {")
assert 'fromGeometry: Qt.rect(' in icon and 'toGeometry: Qt.rect(' in icon
assert icon.count('Config.weatherIconSize') >= 4
assert 'Image {' in icon and 'anchors.fill: parent' in icon
assert 'opacity: weatherIconMorph.normalizedProgress' in icon
assert 'root.normalizedIconCode !== ""' in icon
assert 'weatherNowIconImage.status !== Image.Ready' in icon
assert 'text: "☁"' in icon
assert 'DashboardCards.normalizeWeatherIconCode(root.weather && root.weather.icon)' in qml
assert 'clip: true' not in icon, 'icon transition must not clip its image'
assert 'fromGeometry: Qt.rect(Config.weatherWindColumnX, Config.weatherWindColumnY, Config.weatherWindColumnWidth, root.height)' in wind
assert 'toGeometry: Qt.rect(Config.weatherWindColumnX, Config.weatherWindColumnY, Config.weatherWindColumnWidth, root.height)' in wind
for field in ('windArrow', 'windSpeed', 'weatherPressureX', 'weatherDescriptionX', 'weatherDescriptionWidth'):
    assert field in wind, f"wind column lost {field}"
assert 'opacity: weatherWindMorph.normalizedProgress' in wind
assert '\n                visible: root.hasData\n' not in wind, 'instant child visibility would interrupt exit'
assert 'active: !root.hasData' in placeholder
assert 'visible: !root.hasData' not in placeholder
assert check.count('run_test "$ROOT/tests/test_weather_now_live_data_morph.sh"') == 1, 'test must be registered exactly once'
print('Weather Now icon, wind column, placeholder and fixed parent geometry: OK')
PY

echo 'Weather Now live data MorphGeometry test: OK'
