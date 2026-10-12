#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAYER="$ROOT/components/Player.qml"
VOLUMES="$ROOT/components/Volumes.qml"
ICON_BUTTON="$ROOT/components/primitives/HoverIconButton.qml"
SURFACE="$ROOT/components/primitives/HoverButtonSurface.qml"
CHECK="$ROOT/CHECK.sh"

for file in "$PLAYER" "$VOLUMES" "$ICON_BUTTON" "$SURFACE"; do test -f "$file"; done

grep -Fq 'Primitives.HoverIconButton {' "$PLAYER"
grep -Fq 'iconText: Config.playerNextIcon' "$PLAYER"
grep -Fq 'iconSize: Config.playerNextIconSize' "$PLAYER"
grep -Fq 'hoverMode: "none"' "$PLAYER"
grep -Fq 'cursorShape: Qt.PointingHandCursor' "$PLAYER"
grep -Fq 'visible: ["deadbeef", "mopidy", "spotify"].indexOf(String(root.player.player || "").toLowerCase()) !== -1' "$PLAYER"
grep -Fq '"next", root.player.player || ""' "$PLAYER"

# The mute glyph uses the generic button surface, not its own MouseArea.
grep -Fq 'Primitives.HoverButtonSurface {' "$VOLUMES"
grep -Fq 'id: mainVolumeIcon' "$VOLUMES"
grep -Fq 'Quickshell.shellDir + "/scripts/set_mute"' "$VOLUMES"
grep -Fq 'root.expectMainMuteState(nextMuted)' "$VOLUMES"
grep -Fq 'verticalAlignment: Text.AlignVCenter' "$VOLUMES"

# Drag-sensitive main and stream volume controls must keep their specialized handlers.
grep -Fq 'onPressed: mouse => {' "$VOLUMES"
grep -Fq 'onPositionChanged: mouse =>' "$VOLUMES"
grep -Fq 'onReleased:' "$VOLUMES"
grep -Fq 'onWheel: wheel =>' "$VOLUMES"

python3 - "$PLAYER" "$VOLUMES" "$CHECK" <<'PYCODE'
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

for name in sys.argv[1:3]: check_balance(name)
player=Path(sys.argv[1]).read_text(encoding='utf-8')
start=player.index('Primitives.HoverIconButton {')
end=player.index('property real pendingSeekPercent', start)
next_block=player[start:end]
if 'MouseArea {' in next_block:
    raise SystemExit('Player Next still owns a local MouseArea')
if 'onClicked: Quickshell.execDetached' not in next_block or '"next", root.player.player || ""' not in next_block:
    raise SystemExit('Player Next click route changed')
if 'deadbeef' not in next_block or 'mopidy' not in next_block or 'spotify' not in next_block:
    raise SystemExit('Player Next backend visibility changed')

volumes=Path(sys.argv[2]).read_text(encoding='utf-8')
start=volumes.index('Primitives.HoverButtonSurface {')
end=volumes.index('id: mainTrack', start)
mute_block=volumes[start:end]
if 'HoverButtonSurface {' not in mute_block:
    raise SystemExit('Volume mute button is not using the shared button surface')
if 'MouseArea {' in mute_block:
    raise SystemExit('Volume mute button still has a local MouseArea')
if 'set_mute' not in mute_block or 'volumeMuteRefreshTimer.restart()' not in mute_block:
    raise SystemExit('Volume mute behaviour / delayed confirmation poll changed')
if 'volumePoll.running = false' in mute_block or 'root.mainBackendMuted = root.mainMuted' in mute_block:
    raise SystemExit('Volume mute click must not restart polling immediately or fake backend-confirmed state')
if 'mainMuteHasPending' not in volumes or 'mainMutePendingUntil' not in volumes or 'mainPendingMuted' not in volumes:
    raise SystemExit('Volume mute pending state is missing')
# There should be exactly two MouseAreas in Volumes: the main and stream sliders.
if volumes.count('MouseArea {') != 2:
    raise SystemExit('Expected only the two specialized volume slider MouseAreas')
if 'test_media_controls_shared_button_primitives.sh' not in Path(sys.argv[3]).read_text(encoding='utf-8'):
    raise SystemExit('Media button test is not wired into CHECK.sh')
print('Player Next + Volume mute use shared button primitives; volume sliders retain specialized drag/wheel handling: OK')
PYCODE

echo 'Player and volume controls shared button primitive test: OK'
