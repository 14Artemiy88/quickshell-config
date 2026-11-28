#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "default action lookup reads NotificationAction.identifier": 'String(action.identifier || "") === "default"',
    "default action remains invoked by clicking non-text card surface": 'if (card.defaultAction && typeof card.defaultAction.invoke === "function")' in source,
    "card-body hit area is enabled only when a default action exists": 'enabled: card.defaultAction !== null && !card.removalPending',
    "provider action buttons are not rendered": 'id: actionRow' not in source and 'model: card.buttonActions' not in source,
    "provider action button projection is removed": 'function notificationButtonActions(notification)' not in source and 'property var buttonActions:' not in source,
    "card sizing no longer reserves space for provider action buttons": 'function notificationCardHeight(summaryHeight, bodyHeight, hasBody, hasProgress, hasImage, hasLeadingVisual)' in source,
    "replaced default-action metadata is still observed": 'function onActionsChanged() { root.scheduleTrackedNotificationRefresh(modelData) }' in source,
}
for label, result in checks.items():
    assert result, f"{label}: missing required behavior"
print("notification default action and no-provider-buttons behavior: OK")
PYCODE
