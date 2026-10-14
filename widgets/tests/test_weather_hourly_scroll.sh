#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$ROOT/components/WeatherList.qml"
CHECK="$ROOT/CHECK.sh"
test -f "$LIST"

grep -Fq 'property int temporaryHourlyCount: -1' "$LIST"
grep -Fq 'property int availableHourlyCount: 12' "$LIST"
grep -Fq 'Config.weatherHourlyCount' "$LIST"
grep -Fq 'function adjustHourlyCount(direction)' "$LIST"
grep -Fq 'wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y' "$LIST"
grep -Fq 'root.adjustHourlyCount(delta > 0 ? 1 : -1)' "$LIST"
grep -Fq 'temporaryHourlyCount = next === Config.weatherHourlyCount ? -1 : next' "$LIST"
grep -Fq 'function onWeatherHourlyCountChanged()' "$LIST"
grep -Fq 'acceptedButtons: Qt.NoButton' "$LIST"
grep -Fq 'visible: root.hourly' "$LIST"
grep -Fq 'test_weather_hourly_scroll.sh' "$CHECK"

python3 - "$LIST" <<'PYCODE'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
# Keep wheel handling ephemeral: do not write the temporary count into persisted Config.
if 'Config.weatherHourlyCount =' in s:
    raise SystemExit('hourly wheel handling must not modify the persisted Config count')
if 'next === Config.weatherHourlyCount ? -1 : next' not in s:
    raise SystemExit('returning to configured count must clear the temporary override')
if 'Math.min(12, Math.max(1, future.length))' not in s:
    raise SystemExit('hourly scroll upper bound must reflect available forecast data and configured maximum')
# Basic delimiter balance across this QML source.
pairs={')':'(',']':'[','}':'{'}
stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
while i < len(s):
    c=s[i]; n=s[i+1] if i+1 < len(s) else ''
    if line_comment:
        if c=='\n': line_comment=False
        i+=1; continue
    if block_comment:
        if c=='*' and n=='/': block_comment=False; i+=2; continue
        i+=1; continue
    if quote:
        if escaped: escaped=False
        elif c=='\\': escaped=True
        elif c==quote: quote=None
        i+=1; continue
    if c=='/' and n=='/': line_comment=True; i+=2; continue
    if c=='/' and n=='*': block_comment=True; i+=2; continue
    if c in ('"', "'", '`'): quote=c; i+=1; continue
    if c in '([{': stack.append((c,i))
    elif c in ')]}':
        if not stack or stack[-1][0] != pairs[c]:
            raise SystemExit(f'unbalanced {c} at offset {i}')
        stack.pop()
    i+=1
if stack: raise SystemExit(f'unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('Weather hourly scroll transient state, limits, persistence isolation and QML structure: OK')
PYCODE

echo 'Weather hourly scroll test: OK'
