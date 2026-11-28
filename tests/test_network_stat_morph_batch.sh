#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/NetworkStat.qml"
fail() { echo "Network stat MorphGeometry batch: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "primitives" as Primitives' "$QML" || fail "shared primitive import missing"
for token in \
    'id: uploadRowMorph' \
    'id: downloadRowMorph' \
    'visible: Config.networkShowUpload || normalizedProgress > 0.001' \
    'visible: Config.networkShowDownload || normalizedProgress > 0.001' \
    'progress: Config.networkShowUpload ? 1 : 0' \
    'progress: Config.networkShowDownload ? 1 : 0' \
    'animationDuration: Config.animationDuration(180, "appearance")' \
    'readonly property real networkStatRowHeight:' \
    'readonly property real networkStatRowGap:' \
    'y: uploadRowMorph.geometryHeight + root.networkStatRowGap' \
    'root.effectiveNetworkSpacing * uploadRowMorph.geometryHeight / networkStatRowHeight' \
    'anchors.topMargin: root.effectiveTopPadding' \
    'anchors.bottomMargin: root.effectiveBottomPadding'; do
    grep -Fq "$token" "$QML" || fail "missing $token"
done

python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
root=Path(sys.argv[1])
qml=(root/'components/NetworkStat.qml').read_text(encoding='utf-8')
assert qml.count('Primitives.MorphGeometry {') == 2, 'expected independent morphs for upload and download rows'
assert qml.count('NetworkStatRow {') == 2, 'shared row component must remain reused twice'
assert 'visible: Config.networkShowUpload\n' not in qml and 'visible: Config.networkShowDownload\n' not in qml, 'instant visibility toggles must not remain on row contents'
assert qml.index('id: uploadRowMorph') < qml.index('id: downloadRowMorph'), 'upload row must remain above download row'
assert 'y: uploadRowMorph.geometryHeight + root.networkStatRowGap' in qml, 'download row must follow the animated upload geometry'
row=(root/'components/NetworkStatRow.qml').read_text(encoding='utf-8')
assert 'height: Math.max(iconPixelSize, valuePixelSize) + root.effectiveNetworkSpacing * 2' in row, 'row height formula changed unexpectedly'
check=(root/'CHECK.sh').read_text(encoding='utf-8')
assert 'run_test "$ROOT/tests/test_network_stat_morph_batch.sh"' in check, 'batch test is not registered'
# Basic delimiter validation for the edited QML file.
pairs={')':'(',']':'[','}':'{'}
stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
while i<len(qml):
    c=qml[i]; n=qml[i+1] if i+1<len(qml) else ''
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
    if c in ('"', "'"): quote=c
    elif c in '([{': stack.append((c,i))
    elif c in ')]}':
        assert stack and stack[-1][0]==pairs[c], f'unbalanced delimiter {c} at {i}'
        stack.pop()
    i+=1
assert not stack, f'unclosed delimiter(s): {stack[-3:]}'
print('Network stat MorphGeometry batch structure: OK')
PYTEST

echo 'Network stat MorphGeometry batch: OK'
