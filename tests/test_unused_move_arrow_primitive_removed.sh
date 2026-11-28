#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
retired = root / "components/primitives/MoveArrowButton.qml"
assert not retired.exists(), "unused MoveArrowButton.qml must be removed"
manifest = (root / "qmldir").read_text(encoding="utf-8")
assert "MoveArrowButton" not in manifest, "retired primitive remains registered in qmldir"
for path in (root / "components").rglob("*.qml"):
    source = path.read_text(encoding="utf-8")
    assert "MoveArrowButton" not in source, f"runtime QML still references retired primitive: {path.relative_to(root)}"
print("Unused MoveArrowButton primitive removed from source, manifest and runtime QML: OK")
PY
