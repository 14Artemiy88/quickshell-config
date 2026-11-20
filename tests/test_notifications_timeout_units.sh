#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "interval: 100" in source, "visible-time countdown must use a short repeating tick"
assert "function notificationTimeout(notification)" in source, "notification timeout needs a normalization path"
assert "const timeout = card.effectiveTimeout" in source, "the timer must use the normalized effective timeout"
assert "card.visibleTimeoutElapsed += interval" in source, "only elapsed visible time may be accumulated"
assert "card.visibleTimeoutElapsed >= timeout" in source, "notification must expire only after enough visible time"
assert "* 1000" not in source, "positive expireTimeout values must not be scaled again; runtime tests validate these units"
assert "notificationsDefaultTimeout" in source and "notificationsCriticalTimeout" in source, "server-default timeouts must be settings-backed"
assert "if (timeout === 0) return 0" in source, "explicit zero must keep notification persistent"
assert "return root.defaultCriticalNotificationTimeout" in source, "critical fallback timeout must be settings-backed"
assert "running: card.notification !== null && !card.removalPending && !card.timeoutExpirationRequested && card.inViewport && card.effectiveTimeout > 0" in source, "timeout must tick only while the notification is visible"
assert "if (card.notification) card.notification.expire()" not in source, "old one-shot timeout implementation must not return"
assert "card.notification.expire()" in source, "timeout must expire notification through the Quickshell API"
print("notifications visible-time timeout: OK")
PYCODE
