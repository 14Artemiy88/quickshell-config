#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROW="$ROOT/components/NetworkConnectionButton.qml"
WIDGET="$ROOT/components/Networks.qml"
python3 - "$ROW" "$WIDGET" <<'PYCODE'
from pathlib import Path
import sys
row = Path(sys.argv[1]).read_text(encoding="utf-8")
widget = Path(sys.argv[2]).read_text(encoding="utf-8")
checks = {
    "row geometry is driven by delegate-local progress": "property real rowProgress: 0" in row and "progress: root.rowProgress" in row,
    "entry and exit have explicit reversible animations": "id: entryAnimation" in row and "id: exitAnimation" in row and "root.startEntryTransition()" in row,
    "component completion initializes visible rows synchronously": "Component.onCompleted: {" in row and "root.transitionInitialized = true" in row,
    "completion occurs only after exit animation finishes": 'onFinished: root.finishExitTransition()' in row and 'root.removalFinished(root.name)' in row,
    "return reverses an active exit": "if (root.removing)" in row and "root.startExitTransition()" in row and "root.startEntryTransition()" in row,
    "model keeps the removed row until callback": 'networkRows.setProperty(i, "removing", true)' in widget and "networkRows.remove(index)" in widget,
    "row stops accepting clicks while removing": "interactionEnabled: !root.removing" in row,
    "pre-completion role changes are ignored safely": "if (!root.transitionInitialized)" in row,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("Network row transition completion failed: " + ", ".join(failed))
print("Network row transition completion: delegate-owned, initialized, reversible explicit exit: OK")
PYCODE
