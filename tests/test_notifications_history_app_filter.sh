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
vm.runInContext(source + '\nthis.api = { groupedEntries, applicationNames, filterEntries };', context);
const api = context.api;
const history = [
  { id: 'mail-1', appName: 'KMail', desktopEntry: 'org.kde.kmail', summary: 'Login failed', body: 'Authentication token expired', receivedAt: 300 },
  { id: 'chat-1', appName: 'Telegram', desktopEntry: 'org.telegram.desktop', summary: 'Build finished', body: 'Deployment completed', receivedAt: 250 },
  { id: 'chat-2', appName: 'Telegram', desktopEntry: 'org.telegram.desktop', summary: 'New message', body: 'Hello', receivedAt: 240 },
  { id: 'browser-1', appName: 'Firefox', summary: 'Release notes', body: 'New browser features', receivedAt: 200 },
];
const grouped = api.groupedEntries(history);
assert.deepStrictEqual(Array.from(api.applicationNames(history)), ['KMail', 'Telegram', 'Firefox'], 'application options follow newest-group ordering and are unique');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, '', []).map(x => x.id)), Array.from(grouped, x => x.id), 'empty query and filter return the full grouped history');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, '', ['telegram']).map(x => x.id)), ['chat-1', 'chat-2'], 'single-app filtering is case-insensitive and keeps all app records');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'build', ['TELEGRAM']).map(x => x.id)), ['chat-1'], 'text search and application filter combine with AND semantics');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, '', ['KMail', 'Firefox']).map(x => x.id)), ['mail-1', 'browser-1'], 'multiple selected apps are included');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, 'build', ['Firefox']).map(x => x.id)), [], 'text and app filters cannot cross-match different apps');
assert.deepStrictEqual(Array.from(api.filterEntries(grouped, '', ['Missing']).map(x => x.id)), [], 'unknown selected app returns no entries');
assert.strictEqual(grouped.length, history.length, 'filtering leaves the grouped source unchanged');

const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dash.includes('property var notificationHistorySelectedApps: []'), 'Dashboard tracks transient selected app filters');
assert(dash.includes('NotificationHistory.applicationNames(root.notificationHistoryModel)'), 'Dashboard derives app filter options from history only');
assert(dash.includes('root.notificationHistoryModel, root.notificationHistorySearchText, root.notificationHistorySelectedApps'), 'search and app filters share one derived model');
assert(dash.includes('Accessible.name: root.notificationHistorySelectedApps.length > 0'), 'app filter control exposes selected state accessibly');
assert(dash.includes('text: "Фильтр по приложениям"'), 'app picker exposes a descriptive heading');
assert(dash.includes('text: "Сбросить"'), 'app picker exposes a reset action');
assert(dash.includes('onToggled: root.setHistoryAppSelected(modelData, checked)'), 'each app checkbox updates its own selection');
assert(dash.includes('function clearHistoryAppFilters()'), 'app filter selections can be cleared');
assert(dash.includes('Нет уведомлений для выбранных приложений'), 'empty filtered result has a distinct message');
assert(dash.includes('включая записи вне текущих фильтров'), 'group deletion remains explicit outside current filters');
console.log('Notification history multi-app filtering and combined search: OK');
JS
