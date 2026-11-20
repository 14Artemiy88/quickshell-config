#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/WeatherForecastItem.qml"
fail() { echo "Weather forecast live MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "primitives" as Primitives' "$QML" || fail "shared MorphGeometry import missing"
for token in \
    'id: forecastHighTemperatureMorph' \
    'id: forecastLowTemperatureMorph' \
    'progress: root.hasHighTemperature ? 1 : 0' \
    'progress: root.hasLowTemperature ? 1 : 0' \
    'visible: root.hasHighTemperature || normalizedProgress > 0.001' \
    'visible: root.hasLowTemperature || normalizedProgress > 0.001' \
    'opacity: forecastHighTemperatureMorph.normalizedProgress' \
    'opacity: forecastLowTemperatureMorph.normalizedProgress' \
    'animationDuration: root.forecastMorphDuration' \
    'Config.animationEasingType(Config.animationWeatherMorphProfile'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding="utf-8")
pairs={")":"(","]":"[","}":"{"}
stack=[]; quote=None; escaped=False; line=False; block=False; i=0
while i < len(s):
    c=s[i]; n=s[i+1] if i+1<len(s) else ""
    if line:
        if c=="\n": line=False
        i+=1; continue
    if block:
        if c=="*" and n=="/": block=False; i+=2; continue
        i+=1; continue
    if quote:
        if escaped: escaped=False
        elif c=="\\": escaped=True
        elif c==quote: quote=None
        i+=1; continue
    if c=="/" and n=="/": line=True; i+=2; continue
    if c=="/" and n=="*": block=True; i+=2; continue
    if c in ("'", '"', '`'): quote=c; i+=1; continue
    if c in "([{": stack.append(c)
    elif c in ")]}":
        assert stack and stack[-1]==pairs[c], f"unbalanced {c} at {i}"
        stack.pop()
    i+=1
assert not stack, "unclosed QML delimiter"
assert s.count("MorphGeometry {") == 2, "only high/low temperatures should use MorphGeometry"
assert s.count("Image {") == 1, "forecast icon must remain a single direct Image"
assert s.count("Text {") == 3, "day/high/low text nodes must remain separate"
assert 'source: Quickshell.shellDir + "/assets/gismeteo/new_png/" + (root.entry.icon || "") + ".png"' in s, "original forecast icon source binding must be preserved"
assert 'width: root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth' in s, "original icon width binding missing"
assert 'height: root.hourly ? Config.weatherHourlyIconHeight : Config.weatherDailyIconHeight' in s, "original icon height binding missing"
for name in ("weatherHourlyIconY", "weatherDailyIconY", "weatherHourlyTempY", "weatherDailyHighTempY", "weatherDailyLowTempY"):
    assert name in s, f"layout binding lost: {name}"
assert "clip: true" not in s, "forecast morphs must not clip their content"
print("Weather forecast icon and temperature morph structure: OK")
PYTEST

echo 'Weather forecast live MorphGeometry test: OK'
