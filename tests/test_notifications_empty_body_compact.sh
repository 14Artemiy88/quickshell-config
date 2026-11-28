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
    "body TextEdit is hidden when no message body exists": [
        'visible: root.notificationHasBody(card.notification)',
    ],
    "height calculation receives body presence and summary layout": [
        'root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasLeadingVisual)',
    ],
    "empty cards use compact minimum height without action buttons": [
        'return Math.max(leadingVisualMinimum, Math.round(52 * root.notificationUiScale), Math.ceil(summaryTopOffset + measuredSummaryHeight + summaryBottomSpace + progressSpace))',
    ],
    "empty cards do not reserve action-row space": [
        'const summaryBottomSpace = root.notificationCardPadding',
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
