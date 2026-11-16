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
    "source snapshot is copied into persistent UI ListModel": "ListModel {" in widget and "model: networkRows" in widget,
    "row lifecycle state is owned by persistent model": 'networkRows.setProperty(i, "removing", true)' in widget and 'required property bool removing' in row,
    "visual progress belongs to the live delegate": "property real rowProgress: 0" in row and "progress: root.rowProgress" in row,
    "source removal does not delete immediately": "function finishNetworkRowRemoval(name)" in widget and "networkRows.remove(index)" in widget,
    "entry starts from delegate completion": "Component.onCompleted: {" in row and "root.startEntryTransition();" in row,
    "exit removes only after NumberAnimation completion": "id: exitAnimation" in row and "onFinished: root.finishExitTransition()" in row,
    "connection returning reverses the tombstone": 'networkRows.setProperty(existingIndex, "removing", false)' in widget and "root.startEntryTransition()" in row,
    "only the matching tombstone is deleted": "root.finishNetworkRowRemoval(networkName)" in widget and "networkRows.remove(index)" in widget,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("Networks model-owned exit progress failed: " + ", ".join(failed))
print("Networks persistent tombstone and delegate-owned exit lifecycle: OK")
PYCODE
