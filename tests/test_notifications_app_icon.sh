#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "icon resolver exists": "function notificationIconSource(notification)",
    "theme icons are resolved only when they exist": 'Quickshell.iconPath(icon, true)',
    "desktop-entry is available as a fallback when explicit icon is invalid": 'String(notification.desktopEntry || "").trim()',
    "desktop-entry icon comes from the desktop entry registry": 'DesktopEntries.byId(desktopEntryId)',
    "desktop-entry icon is also checked for existence": 'Quickshell.iconPath(String(desktopEntry.icon), true)',
    "generic information icon is only the final fallback": 'return Quickshell.iconPath("dialog-information")',
    "absolute/URL paths are supported": '/^(file|qrc|image|https?):/i.test(icon)',
    "app icon image uses the notification icon source": 'source: card.notification ? root.notificationIconSource(card.notification) : ""',
    "icon image has a visible layout size": "width: 22\n                        height: 22",
    "application name reserves space when an icon is shown": "anchors.leftMargin: card.hasMessengerAvatar ? 72 : (appIconImage.visible ? 38 : 12)",
    "raster/SVG decode is kept on the GUI thread to avoid Qt pixmap-reader warnings": "asynchronous: false",
    "icon decode size is bounded": "sourceSize: Qt.size(44, 44)",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications app icon rendering: OK")
PYCODE
