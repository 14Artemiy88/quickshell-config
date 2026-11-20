#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'import "../.."' in source, "notification component must import the project root qmldir to resolve Config"
assert 'import ".."' not in source, "notification component must not stop at components/ for Config"
assert 'property var notification: modelData || null' in source, "delegate must tolerate null model data during model changes"
assert 'visible: notification !== null' in source, "empty transient delegates must remain hidden"
assert 'card.notification ? String(card.notification.appName || "Уведомление") : ""' in source
assert 'card.notification ? String(card.notification.summary || "") : ""' in source
assert 'property string formattedBody: notification ? root.formatNotificationBody(notification.body) : ""' in source
assert 'text: card.formattedBody' in source
assert 'interval: 100' in source, 'visible-time timeout uses a repeating timer tick'
assert '* 1000)) : 1000' not in source, 'timeout must not be multiplied by 1000 again'
assert 'property var buttonActions: root.notificationButtonActions(notification)' in source
assert 'model: card.buttonActions' in source
assert 'if (card.notification && !card.removalPending) card.notification.dismiss()' in source
assert 'running: card.notification !== null && !card.removalPending && !card.timeoutExpirationRequested && card.inViewport && card.effectiveTimeout > 0' in source, 'off-screen notification expiry timer must remain paused'
assert 'card.visibleTimeoutElapsed += interval' in source, 'visible timeout progress must pause when off-screen instead of restarting or expiring unseen'
assert 'card.mapToItem(notificationList, 0, 0)' in source, 'viewport visibility must use mapped viewport coordinates'
assert 'card.notification.expire()' in source
assert 'if (!card.removalPending && modelData && typeof modelData.invoke === "function") modelData.invoke()' in source
print("notifications Config import and null safety: OK")
PYCODE
