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
networks_start = shell.rfind('moduleName: "networks"')
networks_start = shell.rfind("    WidgetWindow {", 0, networks_start)
networks_end = shell.index("\n    WidgetWindow {", networks_start + 1)
networks = shell[networks_start:networks_end]

for name, block in (("calendar", calendar), ("networks", networks)):
    assert "bottomLayer: true" in block, f"{name} must stay below normal application windows"
    assert "bottomLayer: false" not in block, f"{name} must not be forced above normal windows"

# Verify that WidgetWindow maps normal widgets to the bottom layer, while the
# layout editor can temporarily raise the edited widget to the top layer.
assert "property int normalWlrLayer: bottomLayer ? WlrLayer.Bottom : WlrLayer.Top" in widget_window
assert "property int editWlrLayer: WlrLayer.Top" in widget_window
assert "WlrLayershell.layer: root.layoutEditMode ? root.editWlrLayer : root.normalWlrLayer" in widget_window

print("Calendar and Networks remain below normal windows; layout editing can still raise them: OK")
PY
