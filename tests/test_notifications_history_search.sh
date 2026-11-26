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
vm.runInContext(source + '\nthis.api = { groupedEntries, filterEntries };', context);
const api = context.api;
const history = [
  { id: 'mail-1', appName: 'KMail', desktopEntry: 'org.kde.kmail', summary: 'Login failed', body: 'Authentication token expired', receivedAt: 300 },
  { id: 'chat-1', appName: 'Telegram', desktopEntry: 'org.telegram.desktop', summary: 'Build finished', body: 'The deployment completed successfully', receivedAt: 250 },
  { id: 'browser-1', appName: 'Firefox', summary: 'Release notes', body: 'New browser features', receivedAt: 200 },
];
const grouped = api.groupedEntries(history);
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, '').map(x => x.id)), Array.from(grouped, x => x.id), 'empty search returns the full grouped history');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'kmail').map(x => x.id)), ['mail-1'], 'search matches the application name');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'org.kde.kmail').map(x => x.id)), ['mail-1'], 'search matches desktop entry');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'LOGIN').map(x => x.id)), ['mail-1'], 'search is case-insensitive and matches the notification title');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'token expired').map(x => x.id)), ['mail-1'], 'search matches terms in notification body');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'kmail expired').map(x => x.id)), ['mail-1'], 'all query terms may match across app and body fields');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'firefox deployment').map(x => x.id)), [], 'all terms are required');
const filtered = api.filterEntries(grouped, 'build');
assert.strictEqual(filtered[0].appGroup, 'Telegram', 'appGroup survives filtering for ListView sections');
assert.strictEqual(grouped.length, history.length, 'filtering does not mutate the input grouped model');

const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dash.includes('import "../js/notifications/NotificationHistory.js" as NotificationHistory'), 'Dashboard imports the shared history helper');
assert(dash.includes('readonly property var filteredNotificationHistoryModel: NotificationHistory.filterEntries('), 'Dashboard derives a filtered history model');
assert(dash.includes('placeholderText: "Поиск по приложению, заголовку или тексту уведомления…"'), 'history view exposes the intended search field');
assert(dash.includes('onTextChanged: root.notificationHistorySearchText = text'), 'search text updates the model immediately');
assert(dash.includes('model: root.filteredNotificationHistoryModel'), 'history ListView uses filtered results');
assert(dash.includes('text: root.notificationHistorySearchText.trim().length > 0\n                    ? "Ничего не найдено"'), 'empty search result has a distinct message');
assert(dash.includes('включая записи вне текущих фильтров'), 'group deletion remains explicit when filters narrow visible entries');
console.log('Notification history search by application, title and body: OK');
JS
