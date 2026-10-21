#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEATHER="$ROOT/components/WeatherPlaceholder.qml"
BUTTON="$ROOT/components/primitives/StyledTextButton.qml"
CHECK="$ROOT/CHECK.sh"
for file in "$WEATHER" "$BUTTON"; do test -f "$file"; done

grep -Fq 'import "primitives" as Primitives' "$WEATHER"
grep -Fq 'Primitives.StyledTextButton {' "$WEATHER"
grep -Fq 'id: refreshButton' "$WEATHER"
grep -Fq 'enabled: root.tokenMissing || (root.weatherService !== null && !root.retryLocked)' "$WEATHER"
grep -Fq 'textFontFamily: Config.font' "$WEATHER"
grep -Fq 'textFontPixelSize: Config.uiFontSize(11)' "$WEATHER"
grep -Fq 'textColor: enabled ? Config.text : Config.textDisabled' "$WEATHER"
grep -Fq 'normalBackground: enabled ? Config.background : Config.playerOverlay' "$WEATHER"
grep -Fq 'cornerRadius: Config.radius' "$WEATHER"
grep -Fq 'root.settingsRequested()' "$WEATHER"
grep -Fq 'root.weatherService.manualRefresh()' "$WEATHER"

python3 - "$WEATHER" "$BUTTON" "$CHECK" <<'PYCODE'
from pathlib import Path
import re, sys
pairs={')':'(',']':'[','}':'{'}
def check_balance(name):
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
for name in sys.argv[1:3]: check_balance(name)
weather=Path(sys.argv[1]).read_text(encoding='utf-8')
button=Path(sys.argv[2]).read_text(encoding='utf-8')
check=Path(sys.argv[3]).read_text(encoding='utf-8')
if re.search(r'(?m)^\s*Button\s*\{', weather):
    raise SystemExit('WeatherPlaceholder still has a standalone Controls.Button')
if 'contentItem: Text {' in weather or 'background: Rectangle {' in weather:
    raise SystemExit('Weather button still duplicates content/background styling')
if 'property color textColor' not in button or 'property color normalBackground' not in button:
    raise SystemExit('StyledTextButton missing configurable text/background state')
if 'test_weather_placeholder_shared_button.sh' not in check:
    raise SystemExit('Weather placeholder test is not wired into CHECK.sh')
print('Weather placeholder refresh/settings action uses shared StyledTextButton and preserves disabled state: OK')
PYCODE

echo 'Weather placeholder shared button test: OK'
