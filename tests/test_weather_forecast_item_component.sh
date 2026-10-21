#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST="$ROOT/components/WeatherList.qml"
ITEM="$ROOT/components/WeatherForecastItem.qml"
test -f "$LIST"
test -f "$ITEM"

grep -Fq 'delegate: WeatherForecastItem {' "$LIST"
grep -Fq 'entry: modelData' "$LIST"
grep -Fq 'hourly: root.hourly' "$LIST"
grep -Fq 'days: root.days' "$LIST"
grep -Fq 'model: root.displayEntries' "$LIST"
grep -Fq 'WeatherPlaceholder {' "$LIST"

grep -Fq 'property var entry: ({})' "$ITEM"
grep -Fq 'property bool hourly: true' "$ITEM"
grep -Fq 'Config.weatherHourlyDayY' "$ITEM"
grep -Fq 'Config.weatherDailyDayY' "$ITEM"
grep -Fq 'Config.weatherHourlyIconWidth' "$ITEM"
grep -Fq 'Config.weatherDailyIconWidth' "$ITEM"
grep -Fq 'Config.weatherHourlyTempFontSize' "$ITEM"
grep -Fq 'Config.weatherDailyHighTempFontSize' "$ITEM"
grep -Fq 'visible: !root.hourly' "$ITEM"
grep -Fq 'Config.tempHot' "$ITEM"
grep -Fq 'Config.tempFreezing' "$ITEM"
grep -Fq 'Quickshell.shellDir' "$ITEM"

python3 - "$LIST" "$ITEM" <<'PYCODE'
from pathlib import Path
import re, sys
pairs={')':'(',']':'[','}':'{'}
def balanced(name):
    source=Path(name).read_text(encoding='utf-8')
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1 < len(source) else ''
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
                raise SystemExit(f'{name}: unbalanced {c} at offset {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')
for name in sys.argv[1:]: balanced(name)
parent=Path(sys.argv[1]).read_text(encoding='utf-8')
item=Path(sys.argv[2]).read_text(encoding='utf-8')
if 'function tempColor(' in parent or 'function highText(' in parent or 'function lowText(' in parent:
    raise SystemExit('WeatherList still duplicates forecast formatting logic')
if item.count('Text {') != 3 or item.count('Image {') != 1:
    raise SystemExit('WeatherForecastItem must own day, high/low temperature and icon display')
for name in ('weatherHourlyDayY','weatherDailyDayY','weatherHourlyIconWidth','weatherDailyIconWidth','weatherHourlyTempY','weatherDailyHighTempY','weatherDailyLowTempY'):
    if name not in item: raise SystemExit(f'WeatherForecastItem missing layout binding {name}')
print('Weather forecast delegate extracted; hourly/daily layout and formatting bindings preserved: OK')
PYCODE

echo 'Weather forecast item component test: OK'
