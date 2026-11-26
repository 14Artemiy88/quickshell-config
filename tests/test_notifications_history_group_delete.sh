#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/notifications/NotificationHistory.js'), 'utf8').replace(/^\.pragma library\s*$/gm, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { removeGroupByApp, groupedEntries, unreadCount };', context);
const api = context.api;
const history = [
  { id: 'mail-1', appName: 'Mail', summary: 'Unread mail', receivedAt: 400, unread: true },
  { id: 'chat-1', appName: 'Chat', summary: 'Chat', receivedAt: 350, unread: true },
  { id: 'mail-2', appName: 'mail', summary: 'Read mail', receivedAt: 300, unread: false },
  { id: 'calendar-1', desktopEntry: 'org.example.calendar', summary: 'Calendar', receivedAt: 200, unread: true },
  { id: 'chat-2', appName: 'Chat', summary: 'Older chat', receivedAt: 100, unread: false },
];
const remaining = api.removeGroupByApp(history, 'MAIL');
assert.deepStrictEqual(Array.from(remaining, entry => entry.id), ['chat-1', 'calendar-1', 'chat-2'], 'removing an app group removes all entries matching its visible label case-insensitively');
assert.strictEqual(api.unreadCount(remaining), 2, 'unread count recalculates after removing the app group');
assert.deepStrictEqual(Array.from(api.groupedEntries(remaining), entry => entry.appGroup), ['Chat', 'Chat', 'org.example.calendar'], 'the removed group disappears while other groups remain');
assert.strictEqual(history.length, 5, 'group removal does not mutate the original history');
assert.deepStrictEqual(Array.from(api.removeGroupByApp(history, 'missing'), entry => entry.id), history.map(entry => entry.id), 'unknown group is a no-op');
assert.strictEqual(api.removeGroupByApp(history, '').length, history.length, 'empty group labels cannot clear history');
assert.strictEqual(api.removeGroupByApp([], 'Mail').length, 0, 'empty history remains empty');

const qml = fs.readFileSync(path.join(root, 'components/notifications/Notifications.qml'), 'utf8');
const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const shell = fs.readFileSync(path.join(root, 'shell.qml'), 'utf8');
assert(qml.includes('function removeNotificationHistoryGroup(appGroup)') && qml.includes('NotificationHistory.removeGroupByApp(current, appGroup)'), 'Notifications exposes a group removal operation');
assert(dash.includes('signal historyGroupDeleteRequested(string appGroup)'), 'Dashboard exposes an app-group delete signal');
assert(dash.includes('root.historyGroupDeleteRequested(String(section))'), 'each app-group header emits its own label');
assert(dash.includes('Удалить всю историю приложения '), 'group delete action has an accessible name');
assert(dash.includes('Подтвердить удаление истории приложения '), 'group delete action requires explicit second-step confirmation');
assert(shell.includes('onHistoryGroupDeleteRequested: function(appGroup)') && shell.includes('removeNotificationHistoryGroup(appGroup)'), 'shell forwards group deletion to Notifications module');
console.log('Notification history app-group deletion, unread counts and confirmation: OK');
JS
