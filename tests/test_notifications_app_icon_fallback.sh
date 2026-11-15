#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
start = source.index("function notificationIconSource(notification)")
end = source.index("function notificationDefaultAction(notification)", start)
resolver = source[start:end]
checks = {
    "valid explicit theme icon keeps precedence": 'const resolvedExplicitIcon = Quickshell.iconPath(icon, true)' in resolver,
    "unknown explicit icon is treated as unresolved rather than accepted": 'if (String(resolvedExplicitIcon || "").length > 0)' in resolver,
    "desktop-entry lookup runs after explicit icon lookup": resolver.index('if (icon)') < resolver.index('DesktopEntries.byId(desktopEntryId)'),
    "desktop entry lookup uses notification desktopEntry property": 'String(notification.desktopEntry || "").trim()' in resolver,
    "desktop-entry icon name is resolved through icon theme": 'Quickshell.iconPath(String(desktopEntry.icon), true)' in resolver,
    "generic information icon is the final fallback": 'return Quickshell.iconPath("dialog-information")' in resolver,
    "absolute and URL icon sources remain supported": '/^(file|qrc|image|https?):/i.test(icon)' in resolver,
}
for label, ok in checks.items():
    assert ok, f"{label}: failed"
print("notifications invalid-icon desktop-entry fallback: OK")
PYCODE
