#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY_CHECK'
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
qml = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")

# Animation state and both animation drivers belong to each component instance.
# There must not be a singleton/global progress property shared by all panels.
assert 'property real transitionProgress: 0' in qml
assert qml.count('target: root') == 2
assert qml.count('property: "transitionProgress"') == 2
assert 'target: Config' not in qml and 'target: Settings' not in qml

# These independently animated windows may be visible together. Each window
# observes its own transition's running state and supplies its own blur region.
instances = {
    "calendarVisibility": ("calendarWindow", "calendarVisibility.blurRegionItem", "calendarVisibility.running"),
    "mopidyVisibility": ("mopidyWindow", "mopidyVisibility.blurRegionItem", "mopidyVisibility.running"),
    "networksVisibility": (None, "networksVisibility.blurRegionItem", "networksVisibility.running"),
    "settingsVisibility": ("settingsWindow", "settingsVisibility.blurRegionItem", "settingsVisibility.running"),
}
for instance, (_, blur_ref, running_ref) in instances.items():
    assert f'id: {instance}' in shell, f"missing independent AnimatedVisibility instance: {instance}"
    assert f'backgroundBlurItem: {blur_ref}' in shell, f"{instance} must own its blur geometry"
    assert running_ref in shell, f"{instance} must expose its own running state to its window"

# The shell owns distinct state flags for these independently visible panels.
for flag in ("calendarVisible", "mopidyVisible", "networksVisible", "settingsVisible"):
    assert re.search(rf"property bool {flag}: false", shell), f"missing per-panel visibility state: {flag}"
print("Concurrent panel animations keep independent progress, blur and visibility state: OK")
PY_CHECK
