#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/Networks.qml"
ROW="$ROOT/components/NetworkConnectionButton.qml"
python3 - "$QML" "$ROW" <<'PYCODE'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
row = Path(sys.argv[2]).read_text(encoding="utf-8")
checks = {
    "panel keeps content-driven target height": "implicitHeight: root.contentDrivenHeight" in qml,
    "panel height is animated": "Behavior on implicitHeight" in qml and 'duration: root.internalAnimationDuration' in qml,
    "panel uses direction-aware standard easing": 'Config.animationEasingType(Config.animationNetworkMorphProfile, root.contentDrivenHeight > root.implicitHeight ? "enter" : "exit")' in qml,
    "delegate model identity is persistent": "ListModel {" in qml and "model: networkRows" in qml,
    "monitor refresh is diffed": "function syncNetworkRows()" in qml and "root.findNetworkRow(name)" in qml,
    "removed row is retained with tombstone": 'networkRows.setProperty(i, "removing", true)' in qml and "networkRows.remove(index)" in qml,
    "row removed only after explicit exit completion": "function finishNetworkRowRemoval(name)" in qml and "onRemovalFinished: function(networkName)" in qml and "onFinished: root.finishExitTransition()" in row,
    "column displaced rows move smoothly": "move: Transition" in qml and 'properties: "x,y"' in qml,
    "displaced rows use shared duration": 'duration: root.internalAnimationDuration' in qml,
    "row outer slot remains fixed": "height: root.effectiveRowHeight" in qml and "implicitHeight: 32" in row,
    "row geometry follows delegate-local progress": "id: networkRowMorph" in row and "property real rowProgress: 0" in row and "progress: root.rowProgress" in row,
    "row click behavior remains": "onClicked: root.toggleConnection()" in row,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("Networks connection layout morph failed: " + ", ".join(failed))
print("Networks connection layout morph: stable model rows, delegate exit, animated panel: OK")
PYCODE
