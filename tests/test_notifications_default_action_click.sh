#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "default action lookup reads NotificationAction.identifier": 'String(action.identifier || "") === "default"',
    "default action is invoked on card-body click": 'if (card.defaultAction && typeof card.defaultAction.invoke === "function")' in source,
    "card-body hit area is enabled only when a default action exists": 'enabled: card.defaultAction !== null && !card.removalPending',
    "default action is not rendered as an explicit button": 'String(action.identifier || "") !== "default"' in source,
    "explicit action row uses filtered actions": 'model: card.buttonActions' in source,
    "explicit action buttons remain invokable": 'if (!card.removalPending && modelData && typeof modelData.invoke === "function") modelData.invoke()' in source,
    "card sizing reserves room only for visible action buttons": 'card.buttonActions.length > 0, root.notificationHasBody' in source,
}
for label, result in checks.items():
    if isinstance(result, str):
        result = result in source
    assert result, f"{label}: missing required wiring"
print("notification default action click behavior: OK")
PYCODE
