#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/Networks.qml"
ROW="$ROOT/components/NetworkConnectionButton.qml"
python3 - "$WIDGET" "$ROW" <<'PYCODE'
from pathlib import Path
import sys
widget = Path(sys.argv[1]).read_text(encoding="utf-8")
row = Path(sys.argv[2]).read_text(encoding="utf-8")
assert 'networkRows.append({' in widget and 'removing: false' in widget, 'new connection must enter persistent UI model'
assert 'rowProgress: 0' not in widget and 'networkRows.setProperty(i, "rowProgress"' not in widget, 'visual progress must not be stored on ListModel rows'
assert 'required property real rowProgress' not in row and 'property real rowProgress: 0' in row, 'delegate must own its rendered progress'
assert 'root.transitionInitialized = true' in row, 'delegate must initialize lifecycle before reacting to changes'
assert 'if (!root.transitionInitialized)' in row, 'pre-completion model assignments must not fire premature removal'
assert 'root.rowProgress = 0;' in row and 'root.startEntryTransition();' in row, 'new delegate must enter from a collapsed state'
assert 'id: exitAnimation' in row and 'onFinished: root.finishExitTransition()' in row, 'tombstone removal must wait for actual exit animation completion'
assert 'networkRows.remove(index)' in widget and 'root.finishNetworkRowRemoval(networkName)' in widget, 'only the completed row tombstone should be removed'
print('Networks delegate-local transition lifecycle: OK')
PYCODE
