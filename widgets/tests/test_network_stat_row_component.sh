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
grep -Fq 'root.monitor?.data?.net_stat?.speed_up' "$PARENT"
grep -Fq 'root.monitor?.data?.net_stat?.speed_down' "$PARENT"
grep -Fq 'Config.networkIconColumnWidth' "$ROW"
grep -Fq 'Config.networkIconLeftPadding' "$ROW"
grep -Fq 'Config.networkRightPadding' "$ROW"
grep -Fq 'Config.networkValueFontSize' "$ROW"

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
    raise SystemExit('NetworkStatRow must own exactly the icon and value text elements')
print('NetworkStat upload/download rows share layout and preserve config bindings: OK')
PYCODE

echo 'Network stat row component test: OK'
