#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "card height uses actual text layout measurement": "function notificationCardHeight(summaryHeight, bodyHeight, hasActions, hasBody, hasProgress, hasImage, hasAvatar)",
    "independent RichText implicit height drives the card": "root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasMessengerAvatar)",
    "measured text height includes body offset and action space": "Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace)",
    "body wraps within card width": "wrapMode: Text.Wrap",
    "body remains RichText": "textFormat: Text.RichText",
    "body is no longer constrained by action-row bottom anchor": "anchors.bottom: actionRow.top",
    "popup height follows ListView measured content": "notificationList.contentHeight",
    "popup caps to screen and leaves list scrollable": "screen.height - root.notificationCoordinate(1) - 16",
}
for description, needle in checks.items():
    if description == "body is no longer constrained by action-row bottom anchor":
        assert needle not in source, f"{description}: unexpected {needle!r}"
    else:
        assert needle in source, f"{description}: missing {needle!r}"
print("notifications measured body height: OK")
PYCODE
