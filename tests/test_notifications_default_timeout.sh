#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "server default comes from the settings module": "readonly property int defaultNotificationTimeout: Math.max(0, Math.round(Number(Config.notificationsDefaultTimeout) || 0))",
    "critical default has an independent settings value": "readonly property int defaultCriticalNotificationTimeout: Math.max(0, Math.round(Number(Config.notificationsCriticalTimeout) || 0))",
    "timeout sentinel is normalized centrally": "function notificationTimeout(notification)",
    "malformed timeout falls back by urgency": "if (!isFinite(timeout))" and "? root.defaultCriticalNotificationTimeout : root.defaultNotificationTimeout",
    "explicit zero means persistent": "if (timeout === 0) return 0",
    "explicit positive timeout is preserved": "if (timeout > 0) return timeout",
    "default critical notification uses its own policy": "return root.defaultCriticalNotificationTimeout",
    "other default notifications use the server policy": "return root.defaultNotificationTimeout",
    "each card uses the normalized timeout": "property real effectiveTimeout: root.notificationTimeout(notification)",
    "only visible cards tick the normalized timeout": "running: card.notification !== null && !card.removalPending && !card.timeoutExpirationRequested && card.inViewport && card.effectiveTimeout > 0",
    "elapsed visible time compares to normalized timeout": "const timeout = card.effectiveTimeout",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications default timeout policy: OK")
PYCODE
