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
checks = {
    "persistent ListModel is used": "ListModel {" in widget and "model: networkRows" in widget,
    "monitor data is not used as a Repeater model": "model: root.networkModel" not in widget and "model: root.monitor.data.network" not in widget,
    "existing rows are found by stable connection name": "function findNetworkRow(name)" in widget and "networkRows.get(i).name === name" in widget,
    "status and type update in place": 'networkRows.setProperty(existingIndex, "status", status)' in widget and 'networkRows.setProperty(existingIndex, "type", type)' in widget,
    "missing rows are retained as tombstones": 'networkRows.setProperty(i, "removing", true)' in widget,
    "tombstone is removed only after delegate exit signal": 'onRemovalFinished: function(networkName)' in widget and 'networkRows.remove(index)' in widget,
    "delegate owns transition progress": "property real rowProgress: 0" in row and "required property real rowProgress" not in row,
    "entry is started on delegate completion": "Component.onCompleted: {" in row and "root.startEntryTransition();" in row,
    "exit completion is explicit": "onFinished: root.finishExitTransition()" in row and "root.removalFinished(root.name)" in row,
    "poll refresh is observed": "function onDataChanged() { root.syncNetworkRows() }" in widget,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("Networks stable model/exit morph failed: " + ", ".join(failed))
print("Networks stable model and delegate-owned exit morph: OK")
PYCODE
