#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "empty bodies are recognized after trimming whitespace": [
        'function notificationHasBody(notification)',
        'String(notification.body || "").trim().length > 0',
    ],
    "body Text is hidden when no message body exists": [
        'visible: root.notificationHasBody(card.notification)',
    ],
    "height calculation receives body presence and summary layout": [
        'root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasMessengerAvatar)',
    ],
    "empty cards use compact minimum height": [
        'const actionMinimum = hasActions ? 76 : 52',
    ],
    "empty cards keep enough space for actions": [
        'const actionMinimum = hasActions ? 76 : 52',
    ],
    "regular body height calculation remains measured": [
        'Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace)',
    ],
    "empty-body branch bypasses the normal minimum body height": [
        'if (!hasBody && !hasImage)',
    ],
}
for description, fragments in checks.items():
    for needle in fragments:
        assert needle in source, f"{description}: missing expected source fragment {needle!r}"
print("notifications empty-body compact card: OK")
PYCODE
