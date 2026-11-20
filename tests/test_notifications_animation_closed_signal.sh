#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
lock_start = source.index("RetainableLock {")
lock_end = source.index("// A single normalized transition", lock_start)
lock = source[lock_start:lock_end]
for fragment in ["object: card.notification", "locked: card.notification !== null"]:
    assert fragment in lock, f"notification delegate must retain its object: {fragment}"
closed = source.index('function onClosed(reason)')
start = source.index('card.startNotificationExit("notification-closed")', closed)
list_remove = source.index('ListView.onRemove: card.startNotificationExit("listview-remove")', start)
assert closed < start < list_remove, "Notification.closed must trigger exit before ListView removal fallback"
body_start = source.index('function startNotificationExit(trigger)')
body_end = source.index('function finishNotificationExit()', body_start)
body = source[body_start:body_end]
for fragment in [
    'if (removalPending)',
    'ListView.delayRemove = true',
    'root.activeNotificationExitCount += 1',
    'exitAnimation.start()',
]:
    assert fragment in body, f"exit lifecycle is missing: {fragment}"
assert 'if (removalPending)' in body, "duplicate close/remove events must be ignored"
print("notification object retained; closed signal starts exit before model removal; duplicate trigger is guarded: OK")
PY
