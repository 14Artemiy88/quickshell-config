#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "empty summaries are recognized after trimming whitespace": [
        'function notificationHasSummary(notification)',
        'String(notification.summary || "").trim().length > 0',
    ],
    "empty summaries contribute zero measured height": [
        'property real measuredSummaryHeight: root.notificationHasSummary(notification) ? summaryMeasure.implicitHeight : 0',
    ],
    "summary Text is hidden when summary is empty": [
        'visible: root.notificationHasSummary(card.notification)',
    ],
    "body anchors directly below source label when summary is empty": [
        'anchors.top: root.notificationHasSummary(card.notification) ? summaryText.bottom : appLabel.bottom',
    ],
    "body offset avoids a phantom summary/body gap": [
        'summaryTopOffset + measuredSummaryHeight + (measuredSummaryHeight > 0 ? 3 : 0)',
    ],
    "empty-summary cards use a shorter minimum height": [
        'const minimumCardHeight = hasLeadingVisual\n            ? root.notificationLeadingVisualSize + root.notificationCardPadding * 2\n            : (measuredSummaryHeight > 0 ? summaryTopOffset + measuredSummaryHeight + root.notificationCardPadding : appNameBottomOffset + root.notificationCardPadding)',
        'return Math.max(minimumCardHeight, Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace))',
    ],
    "card height uses summary height after checking summary presence": [
        'root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasLeadingVisual)',
    ],
}
for description, fragments in checks.items():
    for needle in fragments:
        assert needle in source, f"{description}: missing expected source fragment {needle!r}"
print("notifications empty-summary compact card: OK")
PYCODE
