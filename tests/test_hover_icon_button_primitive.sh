#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SURFACE="$ROOT/components/primitives/HoverButtonSurface.qml"
PRIMITIVE="$ROOT/components/primitives/HoverIconButton.qml"
MOVE="$ROOT/components/primitives/MoveArrowButton.qml"
MOPIDY="$ROOT/components/mopidy/MopidyHoverIcon.qml"
NETWORKS="$ROOT/components/Networks.qml"
NETWORK_BUTTON="$ROOT/components/NetworkConnectionButton.qml"

for file in "$SURFACE" "$PRIMITIVE" "$MOVE" "$MOPIDY" "$NETWORKS" "$NETWORK_BUTTON"; do
    test -f "$file"
done

# The low-level primitive owns button hit-testing, hover surface and tooltip.
grep -Fq 'default property alias contentData: contentHost.data' "$SURFACE"
grep -Fq 'readonly property bool hovered: mouseArea.containsMouse' "$SURFACE"
grep -Fq 'signal clicked()' "$SURFACE"
grep -Fq 'property int cursorShape: Qt.PointingHandCursor' "$SURFACE"
grep -Fq 'cursorShape: root.interactionEnabled ? root.cursorShape : Qt.ArrowCursor' "$SURFACE"
grep -Fq 'ToolTip.visible:' "$SURFACE"
grep -Fq 'root.hovered && root.hoverBackgroundEnabled' "$SURFACE"
grep -Fq 'root.hovered && root.hoverBorderEnabled' "$SURFACE"

# Icon-only controls share the same lower-level hover/click primitive.
grep -Fq 'Primitives.HoverButtonSurface {' "$PRIMITIVE"
grep -Fq 'root.hoverMode === "background"' "$PRIMITIVE"
grep -Fq 'root.hoverMode === "frame"' "$PRIMITIVE"
grep -Fq 'root.hoverMode === "text"' "$PRIMITIVE"
grep -Fq 'Primitives.HoverIconButton {' "$MOVE"
grep -Fq 'visible: root.requestedVisible && (!root.hideWhenDisabled || root.interactionEnabled)' "$MOVE"
grep -Fq 'property bool hideWhenDisabled: true' "$MOVE"
grep -Fq 'requestedVisible: itemData.queueIndex > 0 && Config.mopidyShowMoveUpIcon' "$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
grep -Fq 'hideWhenDisabled: false' "$ROOT/components/mopidy/MopidyQueueTrackRow.qml"
grep -Fq 'requestedVisible: index > 0 && Config.mopidyShowMoveUpIcon' "$ROOT/components/mopidy/MopidyPlaylistContents.qml"
grep -Fq 'Primitives.HoverIconButton {' "$MOPIDY"
grep -Fq 'hoverMode: Config.mopidyHoverMode' "$MOPIDY"
grep -Fq 'hoverColor: Config.mopidyHoverColor' "$MOPIDY"
grep -Fq 'iconX: root.iconX' "$MOPIDY"
grep -Fq 'iconY: root.iconY' "$MOPIDY"

# Full-width Networks connection rows use the same surface but supply their own content.
grep -Fq 'delegate: NetworkConnectionButton {' "$NETWORKS"
grep -Fq 'network: modelData' "$NETWORKS"
grep -Fq 'model: root.monitor?.data?.network ?? []' "$NETWORKS"
grep -Fq 'Primitives.HoverButtonSurface {' "$NETWORK_BUTTON"
grep -Fq 'backgroundColor: root.active ? Config.activeNetworkBackground : Config.transparent' "$NETWORK_BUTTON"
grep -Fq 'hoverBorderEnabled: true' "$NETWORK_BUTTON"
grep -Fq 'hoverBorderColor: Config.accent' "$NETWORK_BUTTON"
grep -Fq 'onClicked: root.toggleConnection()' "$NETWORK_BUTTON"
grep -Fq 'root.active ? "down" : "up"' "$NETWORK_BUTTON"
grep -Fq 'verticalAlignment: Text.AlignVCenter' "$NETWORK_BUTTON"
grep -Fq 'horizontalAlignment: Text.AlignHCenter' "$NETWORK_BUTTON"
grep -Fq 'width: Math.max(0, parent.width - typeIcon.width - parent.spacing)' "$NETWORK_BUTTON"
if grep -Fq 'anchors.verticalCenterOffset: -3' "$NETWORK_BUTTON"; then
    echo 'Network type icon still uses a manual vertical offset' >&2
    exit 1
fi

# Consumers should not duplicate visual/interaction layers now owned by the primitive.
if grep -Eq 'MouseArea|ToolTip|Rectangle[[:space:]]*\{' "$PRIMITIVE" "$NETWORK_BUTTON"; then
    echo 'HoverIconButton or Networks connection row duplicates the shared surface primitive' >&2
    exit 1
fi
if grep -Eq 'MouseArea|ToolTip|Rectangle[[:space:]]*\{' "$MOVE" "$MOPIDY"; then
    echo 'HoverIconButton adapter duplicates primitive rendering/interaction' >&2
    exit 1
fi

python3 - "$SURFACE" "$PRIMITIVE" "$MOVE" "$MOPIDY" "$NETWORKS" "$NETWORK_BUTTON" <<'PYCODE'
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
print('Shared hover surface, icon buttons and Networks QML delimiters: OK')
PYCODE

echo 'Shared hover surface used by Mopidy, move-arrow and Networks controls: OK'
