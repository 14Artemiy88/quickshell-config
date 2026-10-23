#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
component = (root / "components/mopidy/Mopidy.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")
start = shell.index("MopidyComponents.Mopidy {")
end = shell.index("\n            }", start)
instance = shell[start:end]
assert "signal topPanelHideRequested()" in component, "Mopidy hide-request signal was removed"
assert "root.topPanelHideRequested()" in component, "pointer exit no longer requests top-panel hiding"
assert "if (mouseY > 24)" in component, "top-panel hide threshold changed unexpectedly"
assert "onTopPanelHideRequested: shell.mopidyTopReveal = false" in instance, \
    "shell must connect the Mopidy hide request to the hover reveal state"
print("Mopidy top-panel hide-request signal is wired to the shell state: OK")
PY
