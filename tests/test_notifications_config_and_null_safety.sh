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
assert 'interval: Config.notificationsShowTimeoutIndicator ? 16 : 100' in source, 'visible-time timeout uses display-cadence ticks only when the indicator is enabled'
assert '* 1000)) : 1000' not in source, 'timeout must not be multiplied by 1000 again'
assert 'property var buttonActions:' not in source
assert 'id: actionRow' not in source
assert 'if (card.notification && !card.removalPending) card.notification.dismiss()' in source
assert 'running: card.notification !== null && !card.removalPending && !card.timeoutExpirationRequested && card.inViewport && !card.pointerHovered && card.effectiveTimeout > 0' in source, 'off-screen notification expiry timer must remain paused'
assert 'card.visibleTimeoutElapsed += tickElapsed' in source, 'visible timeout progress must use measured elapsed time and pause when off-screen'
assert 'card.mapToItem(notificationList, 0, 0)' in source, 'viewport visibility must use mapped viewport coordinates'
assert 'card.notification.expire()' in source
assert 'focusable: root.notificationTextFocusCard !== null' in source
assert 'notificationTextContextMenu' not in source
print("notifications Config import and null safety: OK")
PYCODE
