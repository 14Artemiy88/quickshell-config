#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOVE="$ROOT/components/primitives/MoveArrowButton.qml"
QUEUE="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
PLAYLIST="$ROOT/components/mopidy/MopidyPlaylistContents.qml"
for file in "$MOVE" "$QUEUE" "$PLAYLIST"; do test -f "$file"; done

# The shared arrow primitive is opt-in: settings/launcher arrows keep their legacy behavior.
grep -Fq 'property bool morphVisibility: false' "$MOVE"
grep -Fq 'visible: root.morphVisibility || root.requestedVisible' "$MOVE"
grep -Fq 'enabled: root.requestedVisible && (!root.hideWhenDisabled || root.interactionEnabled)' "$MOVE"
grep -Fq 'Primitives.MorphGeometry {' "$MOVE"
grep -Fq 'progress: root.morphVisibility ? root.morphVisibilityProgress : 1' "$MOVE"
grep -Fq 'animationDuration: root.morphVisibility ? Config.animationDuration(180, "appearance") : 0' "$MOVE"
grep -Fq 'opacity: root.morphVisibility ? visibilityMorph.normalizedProgress : 1' "$MOVE"
grep -Fq 'interactionEnabled: root.interactionEnabled' "$MOVE"

# Only the runtime Mopidy queue and playlist controls opt into the transition.
[[ $(grep -Fc 'morphVisibility: true' "$QUEUE") -eq 2 ]]
[[ $(grep -Fc 'morphVisibility: true' "$PLAYLIST") -eq 2 ]]
[[ $(grep -Fc 'Primitives.MoveArrowButton {' "$QUEUE") -eq 2 ]]
[[ $(grep -Fc 'Primitives.MoveArrowButton {' "$PLAYLIST") -eq 2 ]]

# The queue track-number slot changes width on the shared progress value, so its text area reflows smoothly.
grep -Fq 'readonly property real numberWidth: trackNumberSlot.width' "$QUEUE"
grep -Fq 'width: trackNumberMorph.geometryWidth' "$QUEUE"
grep -Fq 'fromGeometry: Qt.rect(0, 0, 0, parent.height)' "$QUEUE"
grep -Fq 'toGeometry: Qt.rect(0, 0, 18, parent.height)' "$QUEUE"
grep -Fq 'progress: Config.mopidyShowTrackNumbers ? 1 : 0' "$QUEUE"
grep -Fq 'visible: Config.mopidyShowTrackNumbers || normalizedProgress > 0.001' "$QUEUE"
grep -Fq 'width: parent.width - trackRow.numberWidth - trackRow.durationWidth - trackRow.actionWidth - 15' "$QUEUE"
grep -Fq 'opacity: trackNumberMorph.normalizedProgress' "$QUEUE"
grep -Fq 'xScale: trackNumberMorph.normalizedProgress' "$QUEUE"
if sed -n '/id: trackNumberMorph/,/^            }/p' "$QUEUE" | grep -Fq 'clip: true'; then
    echo 'Mopidy track-number morph must not clip its text' >&2
    exit 1
fi

python3 - "$MOVE" "$QUEUE" "$PLAYLIST" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for name in sys.argv[1:]:
    s=Path(name).read_text(encoding='utf-8')
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
                raise SystemExit(f'{name}: unbalanced {c} at offset {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('Mopidy optional-control morph QML delimiters: OK')
PYCODE

echo 'Mopidy optional queue numbers and boundary arrows use independent morph transitions: OK'
