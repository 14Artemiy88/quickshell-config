#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
resolver = source[source.index("function notificationIconSource(notification)"):source.index("function notificationDefaultAction(notification)")]
checks = {
    "icon resolver exists": "function notificationIconSource(notification)" in source,
    "theme icons are resolved only when they exist": 'Quickshell.iconPath(icon, true)' in resolver,
    "desktop-entry is available as a fallback when explicit icon is invalid": 'String(notification.desktopEntry || "").trim()' in resolver,
    "desktop-entry icon comes from the desktop entry registry": 'DesktopEntries.byId(desktopEntryId)' in resolver,
    "desktop-entry icon is also checked for existence": 'Quickshell.iconPath(String(desktopEntry.icon), true)' in resolver,
    "generic information icon is only the final fallback": 'return Quickshell.iconPath("dialog-information")' in resolver,
    "absolute/URL paths are supported": '/^(file|qrc|image|https?):/i.test(icon)' in resolver,
    "app icon and supplied image share a leading visual frame": 'id: notificationVisualFrame' in source and 'visible: card.hasLeadingVisual' in source,
    "app icon scales inside the smaller dimension of its clipped viewport": 'width: card.hasLeadingImage ? parent.width : Math.max(1, Math.round(Math.min(parent.width, parent.height) * 7 / 12))' in source and 'height: card.hasLeadingImage ? parent.height : Math.max(1, Math.round(Math.min(parent.width, parent.height) * 7 / 12))' in source,
    "application icon is selected when no leading image is available": 'source: card.hasLeadingImage ? card.imageSource : card.appIconSource' in source,
    "application name reserves the size-aware text column": 'anchors.leftMargin: card.textColumnLeftMargin' in source,
    "image decoding remains on the GUI thread": 'asynchronous: false' in source,
    "icon decode size follows its bounded rendered dimensions": 'Qt.size(Math.max(1, Math.round(width * 2)), Math.max(1, Math.round(height * 2)))' in source,
    "visual frame and inner viewport both clip overflowing content": 'id: notificationVisualFrame' in source and 'id: notificationVisualViewport' in source and source.count('clip: true') >= 2,
}
for description, ok in checks.items():
    assert ok, f"{description}: failed"
print("notifications application icon rendering: OK")
PYCODE
