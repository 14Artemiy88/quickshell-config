#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
settings = (root / "components/settings/sections/SettingsNotificationsSection.qml").read_text(encoding="utf-8")
for path, source in (("Notifications.qml", qml), ("SettingsNotificationsSection.qml", settings)):
    assert "QSW-NOTIFY-ANIM" not in source, f"temporary notification diagnostics remain in {path}"
    assert "logNotificationAnimation" not in source, f"temporary logger helper/calls remain in {path}"
    assert "console.info" not in source, f"temporary info logging remains in {path}"
# Diagnostics are removed, but the real entry/exit and compositor workaround remain.
for fragment in (
    "function startNotificationEntry()",
    "function startNotificationExit(trigger)",
    'card.startNotificationExit("notification-closed")',
    'card.startNotificationExit("listview-remove")',
    "RetainableLock {",
    "ListView.delayRemove = true",
    "ListView.delayRemove = false",
    "root.notificationCardAnimationStyle",
    "root.notificationCardVisibilityDuration",
    "readonly property bool notificationSurfaceActive:",
    "visible: true",
    "implicitWidth: root.notificationSurfaceActive ? root.notificationCardWidth : 1",
    "if (!root.notificationSurfaceActive)\n                return 1",
):
    assert fragment in qml, f"notification runtime behavior regressed: {fragment}"
assert "Config.animationNotificationsVisibilityStyle = values[index]" in settings
assert "Config.animationNotificationsMorphProfile = value" in settings
print("temporary notification diagnostics removed; animation runtime wiring preserved: OK")
PY
