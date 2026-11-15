#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARENT="$ROOT/components/NetworkStat.qml"
ROW="$ROOT/components/NetworkStatRow.qml"
for file in "$PARENT" "$ROW"; do test -f "$file"; done

grep -Fq 'NetworkStatRow {' "$PARENT"
grep -Fq 'glyph: ""' "$PARENT"
grep -Fq 'glyph: ""' "$PARENT"
grep -Fq 'accentColor: Config.networkUpload' "$PARENT"
grep -Fq 'accentColor: Config.networkDownload' "$PARENT"
grep -Fq 'visible: Config.networkShowUpload' "$PARENT"
grep -Fq 'visible: Config.networkShowDownload' "$PARENT"
grep -Fq 'valueText: (root.monitor?.data?.net_stat?.speed_up ?? "0 B/s") + " / " + (root.monitor?.data?.net_stat?.up ?? "0 B")' "$PARENT"
grep -Fq 'valueText: (root.monitor?.data?.net_stat?.speed_down ?? "0 B/s") + " / " + (root.monitor?.data?.net_stat?.down ?? "0 B")' "$PARENT"
grep -Fq 'spacing: Config.networkSpacing' "$PARENT"
! grep -Fq 'networkHorizontalPadding' "$PARENT"
grep -Fq 'Config.networkIconLeftPadding' "$ROW"
grep -Fq 'Config.networkRightPadding' "$ROW"
grep -Fq 'Config.networkSpacing * 2' "$ROW"
grep -Fq 'Config.networkValueFontSize' "$ROW"
grep -Fq 'Config.networkFont' "$ROW"
grep -Fq 'Qt.application.font.family' "$ROW"
grep -Fq 'horizontalAlignment: Text.AlignRight' "$ROW"
! grep -Fq 'networkIconColumnWidth' "$ROW"

python3 - "$PARENT" "$ROW" <<'PYCODE'
from pathlib import Path
import sys
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
for name in sys.argv[1:]: check_balance(name)
parent=Path(sys.argv[1]).read_text(encoding='utf-8')
row=Path(sys.argv[2]).read_text(encoding='utf-8')
if parent.count('NetworkStatRow {') != 2:
    raise SystemExit('NetworkStat must contain exactly two shared upload/download rows')
import re
if re.search(r'(?m)^\s*(?:Text|Row) \{', parent):
    raise SystemExit('NetworkStat duplicates row layout instead of using NetworkStatRow')
if row.count('Text {') != 2:
    raise SystemExit('NetworkStatRow must keep one icon and one value text item')
if 'height: Math.max(iconPixelSize, valuePixelSize) + Config.networkSpacing * 2' not in row:
    raise SystemExit('Network spacing must control row height and internal padding')
print('Network stat row keeps derived icon column, shared spacing, and configurable value typography: OK')
PYCODE

echo 'Network stat row component test: OK'
