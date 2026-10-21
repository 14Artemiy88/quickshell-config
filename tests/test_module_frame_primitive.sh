#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAME="$ROOT/components/primitives/ModuleFrame.qml"
test -f "$FRAME"
test ! -e "$ROOT/components/Frame.qml"
grep -Fq 'property string moduleName' "$FRAME"
grep -Fq 'Settings.moduleFrames[moduleName] !== false' "$FRAME"
grep -Fq 'Settings.moduleBackgrounds[moduleName] !== false' "$FRAME"
grep -Fq 'border.width: moduleFrameVisible ? Config.frameBorderWidth : 0' "$FRAME"
modules=(CalendarWidget Cava CpuGraph CpuWidget NetworkStat Networks Player TimeWidget TimerWidget Volumes WeatherList WeatherNow TopApps)
for module in "${modules[@]}"; do
    file="$ROOT/components/$module.qml"
    test -f "$file"
    grep -Fq 'import "primitives" as Primitives' "$file"
    grep -Fq 'Primitives.ModuleFrame {' "$file"
done
mopidy="$ROOT/components/mopidy/Mopidy.qml"
grep -Fq 'import "../primitives" as Primitives' "$mopidy"
grep -Fq 'Primitives.ModuleFrame {' "$mopidy"
if grep -R -E 'Widgets\.Frame|Components\.Frame|components/Frame\.qml' "$ROOT/components" --include='*.qml'; then
    echo 'Old Frame path/reference remains' >&2
    exit 1
fi
python3 - "$FRAME" <<'PYCODE'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False
pairs={')':'(',']':'[','}':'{'}; i=0
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
        if not stack or stack[-1][0] != pairs[c]: raise SystemExit(f'unbalanced {c} at offset {i}')
        stack.pop()
    i+=1
if stack: raise SystemExit(f'unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('ModuleFrame delimiters: OK')
PYCODE
echo 'Module frame primitive: OK'
