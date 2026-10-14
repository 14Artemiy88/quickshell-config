#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="$ROOT/components/mopidy/Mopidy.qml"
ALBUM="$ROOT/components/mopidy/MopidyAlbumHeader.qml"
TRACK="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"

grep -Fq 'MopidyWidgets.MopidyAlbumHeader {' "$MAIN"
grep -Fq 'MopidyWidgets.MopidyQueueTrackRow {' "$MAIN"
grep -Fq 'model: root.queueItems' "$MAIN"
grep -Fq 'onContentYChanged: root.updateStickyAlbum()' "$MAIN"
grep -Fq 'property var controller' "$ALBUM"
grep -Fq 'property bool stickyHeader: false' "$ALBUM"
grep -Fq 'controller.removeAlbum(itemData.tlids)' "$ALBUM"
grep -Fq 'property var controller' "$TRACK"
# RichText disables Text.elide in Qt Quick; StyledText preserves basic artist markup and supports elision.
grep -Fq 'textFormat: Config.mopidyTrackArtistDisplayMode === "one-line" ? Text.StyledText : Text.PlainText' "$TRACK"
grep -Fq 'elide: Text.ElideRight' "$TRACK"
if grep -Fq 'Text.RichText' "$TRACK"; then
    echo 'Mopidy queue title uses RichText, which disables eliding' >&2
    exit 1
fi
grep -Fq 'controller.moveTrack(Number(itemData.track.tlid), itemData.queueIndex - 1)' "$TRACK"
grep -Fq 'controller.moveTrack(Number(itemData.track.tlid), itemData.queueIndex + 1)' "$TRACK"
grep -Fq 'controller.removeTrack(Number(itemData.track.tlid))' "$TRACK"
grep -Fq 'controller.playTrack(Number(itemData.track.tlid))' "$TRACK"
if grep -Eq '\broot\.|queueView\.' "$ALBUM" "$TRACK"; then
    echo 'Unexpected parent-local reference in extracted Mopidy queue-row components' >&2
    exit 1
fi
python3 - "$ALBUM" "$TRACK" <<'PYCODE'
from pathlib import Path
import sys
for filename in sys.argv[1:]:
    s=Path(filename).read_text()
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
            if not stack or stack[-1][0]!=pairs[c]:
                raise SystemExit(f'{filename}: unbalanced {c} at offset {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{filename}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')
    print(Path(filename).name + ': delimiters OK')
PYCODE
echo 'Mopidy queue row components: OK'
