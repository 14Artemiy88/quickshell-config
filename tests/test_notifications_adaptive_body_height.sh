#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "card height uses actual text layout measurement": "function notificationCardHeight(summaryHeight, bodyHeight, hasBody, hasProgress, hasImage, hasLeadingVisual)",
    "independent RichText implicit height drives the card": "root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasLeadingVisual)",
    "measured text height includes body offset and consistent bottom padding": "Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace)",
    "measurement wraps within card width": "wrapMode: Text.Wrap",
    "selectable body wraps within card width": "wrapMode: TextEdit.Wrap",
    "measurement remains RichText": "textFormat: Text.RichText",
    "selectable body remains RichText": "textFormat: TextEdit.RichText",
    "body has no removed action-row bottom anchor": "anchors.bottom: actionRow.top",
    "popup height follows ListView measured content": "notificationList.contentHeight",
    "popup caps to screen and leaves list scrollable": "screen.height - root.notificationCoordinate(1) - 16",
}
for description, needle in checks.items():
    if description == "body has no removed action-row bottom anchor":
        assert needle not in source, f"{description}: unexpected {needle!r}"
    else:
        assert needle in source, f"{description}: missing {needle!r}"
print("notifications measured body height: OK")
PYCODE
