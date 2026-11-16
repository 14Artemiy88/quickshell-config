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
    "row content collapses vertically to its center": "fromGeometry: Qt.rect(0, parent.height / 2, parent.width, 0)" in row,
    "row expands to its fixed full-height slot": "toGeometry: Qt.rect(0, 0, parent.width, parent.height)" in row,
    "morph content is clipped to its animated bounds": "clip: true" in row,
    "exit and entry use shared appearance duration": 'Config.animationDuration(220, "appearance")' in row,
    "exit has a dedicated completion callback": 'easing.type: Config.animationEasingType("standard", "exit")' in row and 'onFinished: root.finishExitTransition()' in row,
    "row content retains natural height during collapse": "height: root.rowHeight" in row and "y: (networkRowMorph.height - height) / 2" in row,
    "morph viewport reveals fixed content geometrically": "id: rowContent" in row and "clip: true" in row,
    "row does not use fade or scale for disappearance": "opacity: networkRowMorph.normalizedProgress" not in row and "scale: 0.96 + 0.04 * networkRowMorph.normalizedProgress" not in row,
    "delegate height stays fixed during inner morph": "height: root.rowHeight" in widget and "implicitHeight: 32" in row,
    "row remains in ListModel until exit callback": 'networkRows.setProperty(i, "removing", true)' in widget and 'networkRows.remove(index)' in widget and 'onRemovalFinished: function(networkName)' in widget,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("Network row exit geometry morph failed: " + ", ".join(failed))
print("Networks row exit geometry morph: delegate-owned center collapse and deferred model removal: OK")
PYCODE
