#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "messaging clients remain recognized for image-data avatars": "function notificationIsMessenger(notification)" in source and "telegram|discord|signal|whatsapp|element|matrix|slack|mattermost" in source,
    "any application image-path is promoted to the common leading visual": "function notificationHasImagePath(notification)" in source and "root.notificationHasImagePath(notification) || root.notificationIsMessenger(notification)" in source,
    "leading image and app icon share one frame": "id: notificationVisualFrame" in source and "visible: card.hasLeadingVisual" in source,
    "leading image frame uses the configured square size": "width: root.notificationLeadingVisualSize\n                        height: root.notificationLeadingVisualSize" in source,
    "messenger avatars are cropped consistently": "root.notificationIsMessenger(card.notification)\n                                ? Image.PreserveAspectCrop : Image.PreserveAspectFit" in source,
    "all leading visuals reserve the configured text column": "hasLeadingVisual ? root.notificationLeadingVisualSize + root.notificationCardPadding * 3 : root.notificationCardPadding * 2" in source and "card.textColumnLeftMargin" in source,
    "leading images are not also rendered as wide body previews": "&& !hasLeadingImage" in source and "visible: card.hasNotificationImage && status === Image.Ready" in source,
    "failed leading images fall back to the application icon": "if (card.hasLeadingImage && status === Image.Error)" in source and "card.appIconSource" in source,
    "non-messenger image-data remains available as a body preview": "&& !hasLeadingImage" in source and "property bool hasNotificationImage" in source,
    "avatar and body-image source continue through existing validation": "source: card.imageSource" in source and "onImageHintsSnapshotChanged: resolveNotificationImageSource()" in source,
}
for description, ok in checks.items():
    assert ok, f"{description}: failed"
print("notifications common leading image and messenger avatar layout: OK")
PYCODE
