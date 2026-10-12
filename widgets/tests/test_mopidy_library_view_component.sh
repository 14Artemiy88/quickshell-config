#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="$ROOT/components/mopidy/Mopidy.qml"
VIEW="$ROOT/components/mopidy/MopidyLibraryView.qml"

grep -Fq 'MopidyWidgets.MopidyLibraryView {' "$MAIN"
grep -Fq 'controller: root' "$MAIN"
grep -Fq 'property var controller' "$VIEW"
grep -Fq 'visible: controller.searchOpen' "$VIEW"
grep -Fq 'MopidyWidgets.MopidyFileBrowser {' "$VIEW"
grep -Fq 'MopidyWidgets.MopidyPlaylistContents {' "$VIEW"
grep -Fq 'visible: libraryRoot.controller.libraryMode === "browse"' "$VIEW"
grep -Fq 'visible: libraryRoot.controller.libraryMode === "playlistItems"' "$VIEW"
grep -Fq 'controller: libraryRoot.controller' "$VIEW"
if grep -Fq 'controller: controller' "$VIEW"; then echo 'Self-referential controller binding in MopidyLibraryView.qml' >&2; exit 1; fi
grep -Fq 'controller.addSearchResult(modelData.uri, modelData.name)' "$VIEW"
grep -Fq 'function focusBrowsePanel()' "$VIEW"
grep -Fq 'function focusFileFilter()' "$VIEW"
grep -Fq 'function clearFileFilterField()' "$VIEW"
grep -Fq 'function focusSearchField()' "$VIEW"
grep -Fq 'libraryView.focusBrowsePanel()' "$MAIN"
grep -Fq 'libraryView.focusSearchField()' "$MAIN"
if grep -Eq '\broot\.|controller: root' "$VIEW"; then
    echo 'Unexpected parent-local reference in MopidyLibraryView.qml' >&2
    exit 1
fi
python3 - "$VIEW" <<'PYCODE'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(encoding='utf-8')
stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False
pairs={')':'(',']':'[','}':'{'}; i=0
while i<len(s):
    c=s[i]; n=s[i+1] if i+1<len(s) else ''
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
        if not stack or stack[-1][0]!=pairs[c]: raise SystemExit(f'unbalanced {c} at offset {i}')
        stack.pop()
    i+=1
if stack: raise SystemExit(f'unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('Mopidy library view delimiters: OK')
PYCODE
echo 'Mopidy library view component: OK'
