#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
start = source.index("function notificationHasImagePath(notification)")
end = source.index("function notificationLocalImagePath(notification)", start)
resolver = source[start:end]
assert 'hints["image-path"]' in resolver and 'hints["image_path"]' in resolver
assert 'return String(' in resolver and '.trim().length > 0' in resolver
card_start = source.index('readonly property bool hasLeadingImage:')
card_end = source.index('readonly property bool hasNotificationImage:', card_start)
leading = source[card_start:card_end]
assert 'root.notificationHasImagePath(notification)' in leading
assert 'root.notificationIsMessenger(notification)' in leading
assert 'imageDataLooksLikeLeadingIcon' in leading
assert 'imageSource.length > 0' in leading and '!imageLoadFailed' in leading
assert 'readonly property bool hasLeadingVisual: hasLeadingImage || hasAppIcon' in source
assert 'visible: card.hasLeadingVisual' in source
assert 'anchors.leftMargin: card.textColumnLeftMargin' in source
assert 'hasLeadingVisual ? root.notificationLeadingVisualSize + root.notificationCardPadding * 3 : root.notificationCardPadding * 2' in source
# Generic image-paths are promoted independently of the sending application's identity.
assert 'root.notificationHasImagePath(notification)' in leading
assert 'imageDataLooksLikeLeadingIcon' in leading
body_image_start = source.index('readonly property bool hasNotificationImage:')
body_image_end = source.index('function startNotificationEntry()', body_image_start)
assert '!hasLeadingImage' in source[body_image_start:body_image_end]
# Unrecognized image-data still retains the independent body-preview route.
assert 'return String(notification.image || "").trim()' in source
assert 'visible: card.hasNotificationImage && status === Image.Ready' in source
print('notifications uniform leading visual layout: OK')
PYCODE
