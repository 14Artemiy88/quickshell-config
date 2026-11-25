#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/shell.qml" "$ROOT/components/WidgetWindow.qml" <<'PY'
from pathlib import Path
import sys

shell = Path(sys.argv[1]).read_text(encoding="utf-8")
widget_window = Path(sys.argv[2]).read_text(encoding="utf-8")

def block_for(marker, next_marker):
    start = shell.index(marker)
    end = shell.index(next_marker, start)
    return shell[start:end]

calendar = block_for("id: calendarWindow", "\n    WidgetWindow {")


def widget_block_for_module(module_name):
    marker = f'moduleName: "{module_name}"'
    marker_pos = shell.index(marker)
    start = shell.rfind("    WidgetWindow {", 0, marker_pos)
    end = shell.find("\n    WidgetWindow {", marker_pos)
    if end < 0:
        end = len(shell)
    return shell[start:end]


networks = widget_block_for_module("networks")
weather_blocks = {
    module: widget_block_for_module(module)
    for module in ("weatherNow", "weatherHourly", "weatherDaily")
}

for name, block in (("calendar", calendar), ("networks", networks), *weather_blocks.items()):
    assert "bottomLayer: true" in block, f"{name} must stay below normal application windows"
    assert "bottomLayer: false" not in block, f"{name} must not be forced above normal windows"

# Weather's normal layer is explicit on all three independent windows, rather
# than relying only on WidgetWindow's default. Layout editing may promote them.
assert len(weather_blocks) == 3
assert all("bottomLayer: true" in block for block in weather_blocks.values())

# Verify that WidgetWindow maps normal widgets to the bottom layer, while the
# layout editor can temporarily raise the edited widget to the top layer.
assert "property int normalWlrLayer: bottomLayer ? WlrLayer.Bottom : WlrLayer.Top" in widget_window
assert "property int editWlrLayer: WlrLayer.Top" in widget_window
assert "WlrLayershell.layer: root.layoutEditMode ? root.editWlrLayer : root.normalWlrLayer" in widget_window

print("Calendar, Networks and all Weather windows remain below normal windows; layout editing can still raise them: OK")
PY
