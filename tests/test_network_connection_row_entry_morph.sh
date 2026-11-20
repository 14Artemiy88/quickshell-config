#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROW="$ROOT/components/NetworkConnectionButton.qml"
WIDGET="$ROOT/components/Networks.qml"
python3 - "$ROW" "$WIDGET" <<'PYCODE'
from pathlib import Path
import sys
row = Path(sys.argv[1]).read_text(encoding='utf-8')
widget = Path(sys.argv[2]).read_text(encoding='utf-8')
checks = {
    'MorphGeometry row wrapper': 'id: networkRowMorph' in row,
    'row progress is local to a live delegate': 'property real rowProgress: 0' in row and 'required property real rowProgress' not in row,
    'entry starts synchronously when delegate completes': 'Component.onCompleted: {' in row and 'root.startEntryTransition();' in row,
    'new rows are appended as stable tombstones only when removed': 'networkRows.append({' in widget and 'removing: false' in widget and 'rowProgress: 0' not in widget,
    'row slot remains full size': 'toGeometry: Qt.rect(0, 0, parent.width, parent.height)' in row,
    'shared appearance duration': 'rowAnimationProfile === "none" ? 0 : Config.animationNetworkMorphDuration' in row,
    'entry and exit use explicit reversible animations': 'id: entryAnimation' in row and 'id: exitAnimation' in row and 'onFinished: root.finishExitTransition()' in row,
    'clicks disabled during exit': 'interactionEnabled: !root.removing' in row,
    'network action remains': 'onClicked: root.toggleConnection()' in row,
    'delegate remains backed by stable rows': 'model: networkRows' in widget,
    'delegate has removal role': 'required property bool removing' in row,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit('Network row lifecycle Morph failed: ' + ', '.join(failed))
print('Network row lifecycle Morph: delegate-owned progress with persistent tombstone model: OK')
PYCODE
