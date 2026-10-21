#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPTIONS="$ROOT/components/TimerOptions.qml"
PRIMITIVE="$ROOT/components/primitives/HoverIconButton.qml"
SURFACE="$ROOT/components/primitives/HoverButtonSurface.qml"

for file in "$OPTIONS" "$PRIMITIVE" "$SURFACE"; do test -f "$file"; done

grep -Fq 'import "primitives" as Primitives' "$OPTIONS"
grep -Fq 'delegate: Primitives.HoverIconButton {' "$OPTIONS"
grep -Fq 'iconText: modelData[0]' "$OPTIONS"
grep -Fq 'iconSize: 22' "$OPTIONS"
grep -Fq 'baseColor: root.selected && root.selected.color ? root.selected.color : Config.text' "$OPTIONS"
grep -Fq 'iconFontFamily: Config.font' "$OPTIONS"
grep -Fq 'hoverMode: "none"' "$OPTIONS"
grep -Fq 'cursorShape: Qt.ArrowCursor' "$OPTIONS"
grep -Fq 'root.commentFile = root.selectedFile' "$OPTIONS"
grep -Fq 'root.commentText = root.selected ? String(root.selected.comment || "") : ""' "$OPTIONS"
grep -Fq 'root.commentMode = true' "$OPTIONS"
grep -Fq 'commentInput.forceActiveFocus()' "$OPTIONS"
grep -Fq 'commentInput.selectAll()' "$OPTIONS"
grep -Fq '"/scripts/timer", modelData[1], root.selectedFile' "$OPTIONS"
grep -Fq 'Primitives.HoverButtonSurface {' "$PRIMITIVE"

python3 - "$OPTIONS" "$PRIMITIVE" "$SURFACE" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for name in sys.argv[1:]:
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
                raise SystemExit(f'{name}: unmatched {c} at {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at {stack[-1][1]}')
print('TimerOptions action-button primitive QML delimiters: OK')
PYCODE

python3 - "$OPTIONS" <<'PYCODE'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text(encoding='utf-8')
needle='delegate: Primitives.HoverIconButton {'
start=s.index(needle)
level=0; found=False; quote=None; escaped=False; line_comment=False; block_comment=False
for i in range(s.index('{', start), len(s)):
    c=s[i]; n=s[i+1] if i+1<len(s) else ''
    if line_comment:
        if c=='\n': line_comment=False
        continue
    if block_comment:
        if c=='*' and n=='/': block_comment=False
        continue
    if quote:
        if escaped: escaped=False
        elif c=='\\': escaped=True
        elif c==quote: quote=None
        continue
    if c=='/' and n=='/': line_comment=True; continue
    if c=='/' and n=='*': block_comment=True; continue
    if c in ('"', "'", '`'): quote=c; continue
    if c=='{': level+=1
    elif c=='}':
        level-=1
        if level==0:
            block=s[start:i+1]
            found=True
            break
if not found: raise SystemExit('TimerOptions icon-button delegate could not be isolated')
if 'MouseArea {' in block or 'Rectangle {' in block or 'Text {' in block:
    raise SystemExit('TimerOptions action-button delegate still duplicates button surface/content')
if block.count('onClicked:') != 1:
    raise SystemExit('TimerOptions icon-button delegate must have exactly one click handler')
if 'modelData[1] === "comment"' not in block or 'else {' not in block:
    raise SystemExit('TimerOptions action routing is incomplete')
print('TimerOptions action buttons no longer duplicate their own MouseArea/Text surface: OK')
PYCODE

echo 'TimerOptions comment, refresh and pause buttons use HoverIconButton: OK'
