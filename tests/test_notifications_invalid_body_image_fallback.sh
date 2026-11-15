#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "image hints are available to the path validator": 'import Quickshell.Io' in source and 'function notificationLocalImagePath(notification)' in source,
    "absolute image paths are held in state before assignment": 'property string imageSource: ""' in source and 'property string pendingImageSource: ""' in source,
    "absolute file paths are not assigned directly before validation": 'const localPath = root.notificationLocalImagePath(notification)' in source and 'imagePathValidationProcess.running = true' in source,
    "file URLs and absolute paths are normalized for preflight": 'rawPath.startsWith("/")' in source and 'file:\\/\\/(?:localhost)?' in source,
    "preflight checks file existence and readability safely": r'test -f \"$1\" && test -r \"$1\"' in source and 'card.pendingImagePath]' in source,
    "the checked source is assigned only after a successful check": 'if (exitCode === 0 && candidateSource.length > 0)' in source and 'card.imageSource = candidateSource' in source,
    "a missing local file leaves an empty source": 'card.imageSource = ""' in source and 'card.imageLoadFailed = true' in source,
    "failed image decodes still hide preview and reserve no space": 'if (status === Image.Error)' in source and 'card.imageLoadFailed = true' in source and 'imageSource.length > 0 && !imageLoadFailed' in source,
    "unknown theme image hints resolve empty rather than to a missing texture": 'Quickshell.iconPath(rawPath, true)' in source and 'return String(checkedIconSource || "")' in source,
    "embedded image-data keeps the native notification image source": 'return String(notification.image || "").trim()' in source,
    "body image is separate and preserves aspect ratio": 'id: bodyImage' in source and 'source: card.imageSource' in source and 'fillMode: Image.PreserveAspectFit' in source,
    "preview is bounded and card height accounts for it": 'readonly property int notificationImageHeight: Math.max(0, Math.min(320, Number(Config.notificationsImageHeight) || 0))' in source and 'const imageSpace = hasImage ? notificationImageGap + notificationImageHeight : 0' in source,
    "progress track remains below a successfully loaded image": 'anchors.top: card.hasNotificationImage\n                            ? bodyImage.bottom' in source[source.index('id: progressTrack'):],
}

for description, ok in checks.items():
    assert ok, f"{description}: failed"
print("notifications invalid image path fallback: OK")
PYCODE
