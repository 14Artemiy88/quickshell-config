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
    "app icon scales inside the configurable leading visual frame": 'width: card.hasLeadingImage ? parent.width : Math.round(root.notificationLeadingVisualSize * 7 / 12)' in source and 'height: card.hasLeadingImage ? parent.height : Math.round(root.notificationLeadingVisualSize * 7 / 12)' in source,
    "application icon is selected when no leading image is available": 'source: card.hasLeadingImage ? card.imageSource : card.appIconSource' in source,
    "application name reserves the size-aware text column": 'anchors.leftMargin: card.textColumnLeftMargin' in source,
    "image decoding remains on the GUI thread": 'asynchronous: false' in source,
    "icon decode size follows the configured leading visual bounds": 'Qt.size(root.notificationLeadingVisualSize * 2, root.notificationLeadingVisualSize * 2)' in source and 'Qt.size(Math.round(root.notificationLeadingVisualSize * 7 / 6), Math.round(root.notificationLeadingVisualSize * 7 / 6))' in source,
}
for description, ok in checks.items():
    assert ok, f"{description}: failed"
print("notifications application icon rendering: OK")
PYCODE
