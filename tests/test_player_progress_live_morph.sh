#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/Player.qml"
fail() { echo "Player progress live MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "primitives" as Primitives' "$QML" || fail "shared MorphGeometry import missing"
for token in \
    'readonly property real playerProgressHeight: Math.max(1, Config.playerProgressTrackHeight)' \
    'id: playerProgressMorph' \
    'progress: Config.playerShowProgress ? 1 : 0' \
    'visible: Config.playerShowProgress || normalizedProgress > 0.001' \
    'enabled: Config.playerShowProgress' \
    'animationDuration: Config.animationDurationForProfile(Config.animationPlayerMorphEnabled, Config.animationPlayerMorphProfile, Config.animationPlayerMorphDuration, "appearance")' \
    'animationEasing: Config.animationEasingType(Config.animationPlayerMorphProfile, Config.playerShowProgress ? "enter" : "exit")' \
    'opacity: playerProgressMorph.normalizedProgress' \
    'scale: 0.96 + 0.04 * playerProgressMorph.normalizedProgress' \
    'anchors.fill: parent' \
    'id: progress'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text(encoding="utf-8")
start=s.find("Primitives.MorphGeometry {\n        id: playerProgressMorph")
assert start>=0, "player progress morph block missing"
opening=s.find("{",start); depth=0; quote=None; escaped=False; end=None
for i in range(opening,len(s)):
    c=s[i]
    if quote:
        if escaped: escaped=False
        elif c=="\\": escaped=True
        elif c==quote: quote=None
        continue
    if c in ("'", '"'): quote=c
    elif c=="{": depth+=1
    elif c=="}":
        depth-=1
        if depth==0: end=i+1; break
assert end is not None, "progress morph braces unbalanced"
block=s[start:end]
assert "fromGeometry: Qt.rect(0, root.height - Config.playerProgressY - root.playerProgressHeight, root.width, root.playerProgressHeight)" in block
assert "toGeometry: fromGeometry" in block, "outer progress slot must keep fixed geometry"
assert "Slider {\n                id: progress\n                anchors.fill: parent" in block
slider_start=block.find("Slider {\n                id: progress")
assert slider_start>=0, "nested player Slider missing"
slider_end=block.find("\n            }\n        }", slider_start)
assert slider_end>slider_start, "nested player Slider block is malformed"
slider=block[slider_start:slider_end]
assert "visible:" not in slider, "slider must remain alive until exit transition ends"
assert "anchors.bottom:" not in block, "slider must stay inside the fixed progress slot"
assert "root.requestSeek(target)" in block and "onMoved: root.requestSeek(value)" in block, "seek interaction changed"
print("Player progress live MorphGeometry structure and seek interactions: OK")
PYTEST

echo 'Player progress live MorphGeometry test: OK'
