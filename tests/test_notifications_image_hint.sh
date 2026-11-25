#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "notification server advertises image-hint support": "imageSupported: true" in source,
    "image source is held empty until local-path validation completes": 'property string imageSource: ""' in source and 'function resolveNotificationImageSource()' in source,
    "image path and payload hints remain reactive on in-place notification updates": 'property string imageHintsSnapshot:' in source and 'onImageHintsSnapshotChanged: resolveNotificationImageSource()' in source,
    "filesystem image hints bypass the icon provider missing-texture placeholder": 'return "file://" + rawPath' in source and 'function notificationLocalImagePath(notification)' in source,
    "local files are validated before Image.source assignment": r'test -f \"$1\" && test -r \"$1\"' in source and 'if (exitCode === 0 && candidateSource.length > 0)' in source,
    "unknown theme image hints return an empty source rather than a missing texture": 'Quickshell.iconPath(rawPath, true)' in source,
    "embedded image-data still uses Quickshell Notification.image": 'return String(notification.image || "").trim()' in source,
    "body image is rendered separately from the application icon": "id: bodyImage" in source and "source: card.imageSource" in source,
    "image preview preserves aspect ratio": "fillMode: Image.PreserveAspectFit" in source,
    "image is bounded to a compact preview height": "readonly property int notificationImageHeight: Math.max(0, Math.min(320, Number(Config.notificationsImageHeight) || 0))" in source,
    "image decode uses the GUI thread to avoid pixmap-reader thread warnings": "asynchronous: false" in source[source.index("id: bodyImage"):source.index("Rectangle {\n                        id: progressTrack")],
    "failed image loads stop reserving blank preview space": "if (status === Image.Error)" in source and "card.imageLoadFailed = true" in source,
    "card height accounts for optional image preview": "hasProgress, hasImage, hasLeadingVisual)" in source and "const imageSpace = hasImage ? notificationImageGap + notificationImageHeight : 0" in source,
    "image preview anchors below body, summary, or app label": "id: bodyImage" in source and "anchors.top: root.notificationHasBody(card.notification)" in source,
    "progress bar is laid out below a body image when present": "anchors.top: card.hasNotificationImage\n                            ? bodyImage.bottom" in source[source.index("id: progressTrack"):],
    "body image does not anchor to itself": "anchors.top: card.hasNotificationImage" not in source[source.index("id: bodyImage"):source.index("id: progressTrack")],
}
for description, ok in checks.items():
    assert ok, f"{description}: failed"
print("notifications image-path/image-data preview and adaptive height: OK")
PYCODE
