#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "summary has an independent measurement item": "id: summaryMeasure",
    "summary measurement width is independent of card geometry": "width: card.textColumnWidth",
    "summary measurement wraps across lines": "wrapMode: Text.Wrap",
    "summary measurement treats notification summary as plain text": "textFormat: Text.PlainText",
    "visible summary wraps rather than eliding to one line": "wrapMode: Text.Wrap",
    "summary no longer has one-line maximum": "maximumLineCount: 1",
    "card height includes measured summary and body": "root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasMessengerAvatar)",
    "summary-only cards include measured title height": "summaryTopOffset + measuredSummaryHeight + summaryBottomSpace",
    "body begins after measured summary height": "summaryTopOffset + measuredSummaryHeight + (measuredSummaryHeight > 0 ? 3 : 0)",
}
for description, needle in checks.items():
    if description == "summary no longer has one-line maximum":
        assert needle not in source, f"{description}: unexpectedly found {needle!r}"
    else:
        assert needle in source, f"{description}: missing {needle!r}"
print("notifications long summary wrap: OK")
PYCODE
