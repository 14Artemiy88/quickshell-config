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
vm.runInContext(source + '\nthis.api = { pruneEntries };', context);
const now = 40 * 86400000;
const history = [
  { id: 'old', receivedAt: now - 10 * 86400000 },
  { id: 'recent-1', receivedAt: now - 2 * 86400000 },
  { id: 'recent-2', receivedAt: now - 86400000 },
  { id: 'recent-3', receivedAt: now },
];
assert.deepStrictEqual(Array.from(context.api.pruneEntries(history, now, 3, 200), x => x.id), ['recent-1', 'recent-2', 'recent-3'], 'age retention removes only entries older than configured days');
assert.deepStrictEqual(Array.from(context.api.pruneEntries(history, now, 0, 2), x => x.id), ['recent-2', 'recent-3'], 'zero disables age expiry while count limit remains active');
assert.deepStrictEqual(Array.from(context.api.pruneEntries(history, now, 365, 1), x => x.id), ['recent-3'], 'count limit keeps newest entries');
assert.deepStrictEqual(Array.from(context.api.pruneEntries([], now, 7, 30)), [], 'empty history remains empty');

const qml = fs.readFileSync(path.join(root, 'components/notifications/Notifications.qml'), 'utf8');
const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const shell = fs.readFileSync(path.join(root, 'shell.qml'), 'utf8');
const settings = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsNotificationsSection.qml'), 'utf8');
const config = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaults = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const persist = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8');
const apply = fs.readFileSync(path.join(root, 'js/settings/SettingsApplyCore.js'), 'utf8');
const schema = fs.readFileSync(path.join(root, 'js/settings/SettingsSchema.js'), 'utf8');
assert(qml.includes('function clearNotificationHistory()') && qml.includes('root.notificationHistory = []'), 'history exposes a clear operation');
assert(qml.includes('NotificationHistory.pruneEntries(') && qml.includes('interval: 60000'), 'history is pruned on a periodic timer');
assert(dash.includes('signal historyClearRequested()') && dash.includes('Точно очистить?'), 'Dashboard requires a second confirmation before clearing');
assert(shell.includes('onHistoryClearRequested:') && shell.includes('clearNotificationHistory()'), 'Dashboard clear action reaches Notifications module');
assert(config.includes('property int notificationsHistoryRetentionDays: 0'), 'retention defaults to unlimited age');
assert(defaults.includes('notificationsHistoryRetentionDays: 0'), 'profile defaults include retention');
assert(settings.includes('notificationsHistoryRetentionDays') && settings.includes('maximum: 365'), 'settings expose a bounded retention control');
assert(persist.includes('notificationsHistoryRetentionDays: config.notificationsHistoryRetentionDays'), 'retention is persisted');
assert(apply.includes('o.notificationsHistoryRetentionDays !== undefined'), 'retention is restored from settings');
assert(schema.includes('p.notificationsHistoryRetentionDays'), 'retention is schema-normalized');
console.log('Notification history clear confirmation, age retention, item limit and settings persistence: OK');
JS
