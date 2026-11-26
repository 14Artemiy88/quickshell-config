#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NOTIFS="$ROOT/components/notifications/Notifications.qml"
SHELL="$ROOT/shell.qml"
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -f "$NOTIFS" ]] || fail 'notification component missing'
grep -Fq 'import Quickshell.Services.Notifications' "$NOTIFS" || fail 'notification service import missing'
grep -Fq 'NotificationServer {' "$NOTIFS" || fail 'NotificationServer missing'
grep -Fq 'notification.tracked = true' "$NOTIFS" || fail 'incoming notifications are not tracked'
grep -Fq 'notificationServer.trackedNotifications' "$NOTIFS" || fail 'tracked notification queue is not rendered'
grep -Fq 'readonly property int visibleNotificationCount: visibleNotificationModel.values.length' "$NOTIFS" || fail 'popup visibility must use the filtered visible count'
grep -Fq 'ScriptModel {' "$NOTIFS" || fail 'visible tracked notifications must pass through ScriptModel'
grep -Fq 'NotificationDnd.visibleNotifications(' "$NOTIFS" || fail 'DND-suppressed notifications must be removed from the toast model'
grep -Fq 'notificationList.contentHeight' "$NOTIFS" || fail 'popup height must follow actual ListView content height'
grep -Fq 'screen.height - root.notificationCoordinate(1) - 16' "$NOTIFS" || fail 'popup height must be capped to screen height'
if grep -Fq 'notificationServer.trackedNotifications.count' "$NOTIFS"; then fail 'ObjectModel has no count property; use values.length'; fi
grep -Fq 'card.notification.expire()' "$NOTIFS" || fail 'notification timeout handling missing'
grep -Fq 'card.notification.dismiss()' "$NOTIFS" || fail 'notification dismiss handling missing'
grep -Fq 'modelData.invoke()' "$NOTIFS" || fail 'notification actions are not invoked'
grep -Fq 'active: Settings.loaded && Settings.notifications' "$SHELL" || fail 'notification module does not control server lifecycle'
grep -Fq 'NotificationComponents.Notifications {}' "$SHELL" || fail 'notification service component is not loaded by shell'
echo 'PASS: custom notification server stage 1 wiring'
