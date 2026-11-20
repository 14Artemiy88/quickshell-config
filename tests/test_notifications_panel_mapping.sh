#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
panel_start = source.index("PanelWindow {\n        id: popupWindow")
panel_end = source.index("Item {\n            id: notificationContent", panel_start)
panel = source[panel_start:panel_end]
content_start = panel_end
content_end = source.index("ListView {\n                id: notificationList", content_start)
content = source[content_start:content_end]
assert "visible: true" in panel, "PanelWindow must remain mapped to avoid compositor window fades per toast"
assert "implicitWidth: root.notificationSurfaceActive ? root.notificationCardWidth : 1" in panel, "idle panel must shrink to one pixel wide"
assert "if (!root.notificationSurfaceActive)\n                return 1" in panel, "idle panel must shrink to one pixel high"
assert "visible: root.notificationSurfaceActive" in content, "notification visuals must be hidden while the mapped panel is idle"
assert "onNotificationSurfaceActiveChanged:" not in source, "temporary surface diagnostics must not remain in the runtime"
assert "onHeightChanged: Settings.notificationsWindowHeight = root.notificationSurfaceActive ? height : 0" in panel, "idle 1x1 surface must not be recorded as notification stack height"
assert "Component.onCompleted: Settings.notificationsWindowHeight = root.notificationSurfaceActive ? height : 0" in panel, "initial idle surface must not pollute stored notification stack height"
assert "readonly property bool notificationSurfaceActive:" in source, "surface activity must include tracked cards, exit retention and layout editing"
assert "activeNotificationExitCount > 0 || layoutEditMode" in source, "exit and smart-edit states must keep the panel at full size"
assert "visible: notificationServer.trackedNotifications.values.length > 0" not in panel, "per-toast visibility binding would re-trigger compositor fades"
print("notification PanelWindow remains mapped; idle surface is 1x1; content visibility is controlled independently: OK")
PY
