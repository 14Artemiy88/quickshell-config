#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "notification queue stays interactively scrollable": "interactive: true",
    "oversized list is bounded at its viewport": "boundsBehavior: Flickable.StopAtBounds",
    "scrollbar is shown only when content overflows": "policy: notificationList.contentHeight > notificationList.height",
    "scrollbar is kept available for oversized queues": "ScrollBar.AlwaysOn : ScrollBar.AlwaysOff",
    "mouse wheel and touchpad are supported": "acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad",
    "wheel moves ListView content rather than dismissing cards": "notificationList.contentY - delta",
    "visible viewport uses actual mapped coordinates": "card.mapToItem(notificationList, 0, 0)",
    "viewport reacts to scroll and relayout changes": "notificationList.contentY",
    "visible timeout is accumulated separately for each card": "property real visibleTimeoutElapsed: 0",
    "card timeout is paused outside the viewport": "running: card.notification !== null && !card.removalPending && !card.timeoutExpirationRequested && card.inViewport && !card.pointerHovered && card.effectiveTimeout > 0",
    "timeout timer repeats so paused time can resume": "repeat: true",
    "new notifications remain tracked in the model": "notification.tracked = true",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications scrollable queue and off-screen timeout: OK")
PYCODE
