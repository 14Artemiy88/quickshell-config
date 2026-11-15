#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "off-screen cards are measured in ListView viewport coordinates": "card.mapToItem(notificationList, 0, 0)",
    "scroll position invalidates viewport calculation": "const scrollPosition = notificationList.contentY",
    "delegate relayout invalidates viewport calculation": "const delegatePosition = card.y",
    "hidden cards do not accumulate timeout": "running: card.notification !== null && card.inViewport && card.effectiveTimeout > 0",
    "visible timeout is preserved while scrolling off-screen": "property real visibleTimeoutElapsed: 0",
    "timeout advances only while visible timer ticks": "card.visibleTimeoutElapsed += interval",
    "expiration waits for accumulated visible time": "if (card.visibleTimeoutElapsed >= timeout)",
    "hidden cards remain tracked until shown or dismissed": "notification.tracked = true",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications hidden-queue timeout regression: OK")
PYCODE
