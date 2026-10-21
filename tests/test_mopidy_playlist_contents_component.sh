#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="$ROOT/components/mopidy/Mopidy.qml"
LIBRARY="$ROOT/components/mopidy/MopidyLibraryView.qml"
VIEW="$ROOT/components/mopidy/MopidyPlaylistContents.qml"

grep -Fq 'MopidyWidgets.MopidyPlaylistContents {' "$LIBRARY"
grep -Fq 'controller: libraryRoot.controller' "$LIBRARY"
if grep -Fq 'controller: controller' "$LIBRARY"; then echo 'Self-referential controller binding in MopidyLibraryView.qml' >&2; exit 1; fi
grep -Fq 'readonly property bool playlistContentMoveBusy: playlistContentMoveProcess.running' "$MAIN"
grep -Fq 'property var controller' "$VIEW"
grep -Fq 'model: controller.playlistItems' "$VIEW"
grep -Fq 'controller.movePlaylistItem(index, index - 1, modelData.name)' "$VIEW"
grep -Fq 'controller.movePlaylistItem(index, index + 1, modelData.name)' "$VIEW"
grep -Fq 'controller.removePlaylistItem(index, modelData.name)' "$VIEW"
grep -Fq 'controller.addPlaylistItem(modelData.uri, modelData.name)' "$VIEW"
grep -Fq '!controller.playlistContentMoveBusy' "$VIEW"
if grep -Eq '\broot\.|playlistContentMoveProcess' "$VIEW"; then
    echo 'Unexpected parent-local reference in MopidyPlaylistContents.qml' >&2
    exit 1
fi
# Keep the new component syntactically balanced without requiring qmllint.
python3 - "$VIEW" <<'PYCODE'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
stack = []
quote = None
escaped = False
line_comment = False
block_comment = False
pairs = {')': '(', ']': '[', '}': '{'}
i = 0
while i < len(s):
    c = s[i]
    n = s[i + 1] if i + 1 < len(s) else ''
    if line_comment:
        if c == '\n': line_comment = False
        i += 1; continue
    if block_comment:
        if c == '*' and n == '/': block_comment = False; i += 2; continue
        i += 1; continue
    if quote:
        if escaped: escaped = False
        elif c == '\\': escaped = True
        elif c == quote: quote = None
        i += 1; continue
    if c == '/' and n == '/': line_comment = True; i += 2; continue
    if c == '/' and n == '*': block_comment = True; i += 2; continue
    if c in ('"', "'", '`'): quote = c; i += 1; continue
    if c in '([{': stack.append((c, i))
    elif c in ')]}':
        if not stack or stack[-1][0] != pairs[c]:
            raise SystemExit(f'unbalanced {c} at offset {i}')
        stack.pop()
    i += 1
if stack: raise SystemExit(f'unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('Mopidy playlist contents component delimiters: OK')
PYCODE
echo 'Mopidy playlist contents component: OK'
