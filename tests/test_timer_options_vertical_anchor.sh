#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/TimerWidget.qml"
SHELL="$ROOT/shell.qml"
python3 - "$WIDGET" "$SHELL" <<'PY'
from pathlib import Path
import sys
widget = Path(sys.argv[1]).read_text(encoding="utf-8")
shell = Path(sys.argv[2]).read_text(encoding="utf-8")

assert "readonly property real selectedTimerRowCenterY" in widget, "TimerWidget must expose selected row center"
anchor = widget.split("readonly property real selectedTimerRowCenterY", 1)[1].split("readonly property int visibleTimerCount", 1)[0]
assert "root.selectedIndex" in anchor and "timerRowsRepeater.itemAt(index)" in anchor
assert "timerRowsColumn.y + row.y + row.height / 2" in anchor, "anchor must use actual live row geometry"
assert "id: timerRowsColumn" in widget, "timer row column origin must be explicit"

assert "function timerOptionsAnchoredY()" in shell, "shell must calculate popup anchor Y"
anchor = shell.split("function timerOptionsAnchoredY()", 1)[1].split("property bool timerCommentVisible", 1)[0]
for token in (
    "timerWidget.selectedFile", "timerWidget.selectedIndex", "timerWindow.offsetY",
    "timerWidget.selectedTimerRowCenterY", "timerWindow.surfaceScale",
    "timerOptionsScaleHost.height", "timerOptionsScaleHost.scale",
    "timerOptionsOverlay.screen.height", "Math.min", "Math.max"
):
    assert token in anchor, f"timer options anchor is missing {token}"
assert "screen: timerWindow.screen" in shell, "overlay must follow the timer monitor"
assert "x: Settings.geometry.timerOptions[0]" in shell, "configured horizontal position must be preserved"
assert "y: timerOptionsOverlay.timerOptionsAnchoredY()" in shell, "popup Y must use the dynamic selected-row anchor"
assert "y: Settings.geometry.timerOptions[1]" not in shell, "popup must not keep the old fixed Y binding"
print("TimerOptions vertical anchor follows selected live timer row, module scale and monitor bounds: OK")
PY
