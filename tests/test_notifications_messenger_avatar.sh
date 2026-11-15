#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "messaging clients are identified separately from ordinary image notifications": "function notificationIsMessenger(notification)" in source and "telegram|discord|signal|whatsapp|element|matrix|slack|mattermost" in source,
    "validated notification image is promoted to a dedicated avatar": "readonly property bool hasMessengerAvatar:" in source and "visible: card.hasMessengerAvatar" in source,
    "avatar is positioned on the left and cropped consistently": "id: messengerAvatarFrame" in source and "width: 48\n                        height: 48" in source and "fillMode: Image.PreserveAspectCrop" in source,
    "messenger text column reserves space beside the avatar": "hasMessengerAvatar ? 84 : 24" in source and "card.hasMessengerAvatar ? 72 : 12" in source,
    "messenger avatar does not also render as a wide image below the body": "!hasMessengerAvatar" in source and "visible: card.hasNotificationImage && status === Image.Ready" in source,
    "ordinary application icons remain visible when there is no messenger avatar": "!card.hasMessengerAvatar" in source and "Config.notificationsShowAppIcon" in source,
    "avatar receives enough room in compact cards": "Math.max(hasAvatar ? 64 : actionMinimum" in source and "hasAvatar ? 64 : (measuredSummaryHeight > 0 ? 68 : 52)" in source,
    "avatar and body-image source continue through existing validation": "source: card.imageSource" in source and "onImageHintsSnapshotChanged: resolveNotificationImageSource()" in source,
}
for description, ok in checks.items():
    assert ok, f"{description}: failed"
print("notifications messenger avatar layout: OK")
PYCODE
