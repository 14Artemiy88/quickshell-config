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
assert "rowHeight: root.effectiveRowHeight" in widget, "Networks must pass its configured row height to each delegate"
assert "property int rowHeight: 32" in row, "row component must expose a defined rowHeight"
assert "height: root.rowHeight" in row, "morph content must have a defined, non-zero natural height"
print("Networks row height binding: parent height reaches delegate content: OK")
PYCODE
