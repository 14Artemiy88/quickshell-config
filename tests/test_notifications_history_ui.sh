#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / 'components/notifications/Notifications.qml').read_text(encoding='utf-8')
dash = (root / 'components/Dashboard.qml').read_text(encoding='utf-8')
shell = (root / 'shell.qml').read_text(encoding='utf-8')
helper = (root / 'js/notifications/NotificationDnd.js').read_text(encoding='utf-8')
assert 'property var notificationHistory: []' in qml
assert 'readonly property int notificationHistoryLimit: Math.max(1, Math.min(200, Number(Config.notificationsHistoryLimit) || 30))' in qml
assert 'function recordNotificationHistory(notification, receivedAt)' in qml
assert 'function acceptNotification(notification)' in qml and 'root.recordNotificationHistory(notification, Date.now())' in qml, 'accepted incoming notifications enter memory history'
assert 'NotificationDnd.snapshot(notification, receivedAt || Date.now())' in qml
assert 'NotificationHistory.upsertEntry(' in qml and 'slice(result.length - maxItems)' in (root / 'js/notifications/NotificationHistory.js').read_text(encoding='utf-8')
assert 'id: historyWindow' not in qml and 'property bool historyOpen' not in qml, 'history is not a separate PanelWindow'
assert 'property bool historyViewActive: false' in dash
assert 'property var notificationHistoryModel: []' in dash
assert 'История уведомлений' in dash and 'только в памяти' in dash
assert 'model: root.filteredNotificationHistoryModel' in dash and 'property var notificationHistoryModel: []' in dash, 'history list uses the searchable derived model'
assert 'section.property: "appGroup"' in dash, 'history is grouped into app sections'
assert 'notificationHistoryUnreadCount' in dash and 'История · ' in dash, 'Dashboard entry point displays unread count'
assert 'непрочитанных' in dash, 'history header shows unread count'
assert 'enabled: root.open && root.historyViewActive' in dash
assert 'signal historyRequested()' in dash
assert 'signal historyEntryDeleteRequested(string entryId)' in dash and 'root.historyEntryDeleteRequested(String(modelData.id || ""))' in dash, 'history cards expose a single-entry delete action'
assert 'id: notificationsHistoryButton' in dash and 'root.historyRequested()' in dash
assert 'visible: Settings.notifications && root.notificationHistoryModel.length > 0' in dash, 'history entry point is hidden while history is empty'
assert 'История · ' in dash, 'history button shows the retained item count'
assert 'Behavior on opacity' in dash and 'transform: Translate' in dash, 'overview/history transitions animate opacity and horizontal movement'
assert 'notificationHistoryModel: notificationsModuleLoader.item ? notificationsModuleLoader.item.notificationHistoryGrouped : []' in shell
assert 'onHistoryRequested:' in shell and 'markNotificationHistoryRead()' in shell, 'opening history marks retained notifications read'
assert 'onHistoryEntryDeleteRequested:' in shell and 'removeNotificationHistoryEntry(entryId)' in shell, 'history delete action reaches Notifications module'
assert 'function snapshot(notification, receivedAt)' in helper
history_helper = (root / 'js/notifications/NotificationHistory.js').read_text(encoding='utf-8')
assert 'function groupedEntries(history)' in history_helper and 'function unreadCount(history)' in history_helper and 'function markAllRead(history)' in history_helper
assert 'snapshot.unread = true' in qml
print('Notification history capture, configurable bounded memory storage, embedded Dashboard view: OK')
PY
