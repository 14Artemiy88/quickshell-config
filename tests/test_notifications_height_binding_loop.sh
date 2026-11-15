#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "card body has a shared formatted-text value": 'property string formattedBody: notification ? root.formatNotificationBody(notification.body) : ""',
    "body measurement is separate from the displayed Text item": "id: bodyMeasure",
    "measurement width is independent of delegate geometry": "width: card.textColumnWidth",
    "card height uses the independent measurement": "root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasMessengerAvatar)",
    "visible body uses the same formatted value": "text: card.formattedBody",
    "measurement and display both support rich text": "textFormat: Text.RichText",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
assert "notificationCardHeight(bodyText.implicitHeight" not in source, "card height must not measure the displayed Text item"
height_binding = source.split("height: notification !== null ? root.notificationCardHeight(", 1)[1].split("\n", 1)[0]
assert "bodyText.y" not in height_binding, "card height must not depend on bodyText.y"
assert "summaryText.y" not in height_binding, "card height must not depend on summaryText.y"
print("notifications height binding loop regression: OK")
PYCODE
