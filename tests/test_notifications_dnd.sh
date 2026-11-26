#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
read = lambda name: (root / name).read_text(encoding='utf-8')
config = read('Config.qml')
defaults = read('js/settings/SettingsDefaults.js')
persistence = read('js/settings/SettingsPersistence.js')
apply_core = read('js/settings/SettingsApplyCore.js')
schema = read('js/settings/SettingsSchema.js')
resets = read('js/settings/SettingsResets.js')
nav = read('components/settings/SettingsNavigationController.qml')
section = read('components/settings/sections/SettingsNotificationsSection.qml')
qml = read('components/notifications/Notifications.qml')
check = read('CHECK.sh')
assert 'property bool notificationsDoNotDisturb: false' in config
assert 'notificationsDoNotDisturb: false' in defaults
assert 'notificationsDoNotDisturb: config.notificationsDoNotDisturb' in persistence
assert 'o.notificationsDoNotDisturb !== undefined' in apply_core and 'Config.notificationsDoNotDisturb = o.notificationsDoNotDisturb === true' in apply_core
assert 'p.notificationsDoNotDisturb' in schema and 'else if (!isSparse)' in schema
assert resets.count('"notificationsDoNotDisturb"') >= 2, 'module and page reset scopes include DND'
assert 'function resetNotificationDndDefaults' in resets, 'legacy profiles reset DND to its false default'
assert 'notificationsDoNotDisturb' in nav, 'Behavior subtab has an independent DND dirty marker'
assert 'notificationsDoNotDisturbCheck' in section and 'settingsSearchId: "notifications-do-not-disturb"' in section
assert 'text: "Не беспокоить"' in section and 'root.settings.save()' in section
assert 'property var dndMemoryHistory: []' in qml and 'dndMemoryHistoryLimit: 200' in qml
assert 'ScriptModel {' in qml and 'comparisonMode: ObjectComparison.Identity' in qml and 'NotificationDnd.visibleNotifications(' in qml
assert 'model: visibleNotificationModel' in qml
assert 'readonly property int visibleNotificationCount: visibleNotificationModel.values.length' in qml
assert 'notification.tracked = true' in qml, 'incoming notifications remain tracked by NotificationServer'
assert 'root.suppressNotification(notification)' in qml, 'DND arrivals are snapshotted and hidden before tracking'
assert 'function onNotificationsDoNotDisturbChanged()' in qml and 'root.reconcileDndNotifications()' in qml
assert 'function expireSuppressedNotifications()' in qml and 'notification.expire()' in qml
assert 'root.dndSuppressedRecords.some(function(record) { return Number(record.expiresAt) > 0 })' in qml, 'the DND expiry timer runs only when a finite timeout is pending'
assert 'notification.tracked = false' not in qml, 'DND must not dismiss incoming notifications just to hide them'
assert 'dndMemoryHistory' not in persistence, 'DND memory snapshots must never be persisted to disk'
assert 'else root.dndSuppressedNotificationIds' not in qml, 'turning DND off must not replay old suppressed notifications as popups'
assert 'Config.notificationsDndBlockedApps' in qml, 'DND-off blocklist is evaluated for incoming and tracked notifications'
assert 'tests/test_notifications_dnd.sh' in check, 'DND test is registered in CHECK'
print('notification DND Config, settings/profile lifecycle, hidden toast model and in-memory-only policy: OK')
PY
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2] + '/js/notifications/NotificationDnd.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { notificationId, isSuppressed, visibleNotifications, snapshot, trackedIdSet, pruneSuppressedIds, pruneRecords, dueRecords };', context);
const api = context.api;
const first = { id: 1, appName: 'GitLab', desktopEntry: 'firefox', appIcon: 'firefox', summary: 'Merge request', body: 'Review needed', image: 'file:///tmp/avatar.png', urgency: 1 };
const second = { id: 2, appName: 'Telegram', summary: 'Message', body: 'Hello', urgency: 0 };
const suppressed = { '1': true };
assert.strictEqual(api.isSuppressed(first, suppressed), true);
assert.strictEqual(api.isSuppressed(second, suppressed), false);
assert.deepStrictEqual(Array.from(api.visibleNotifications([first, second], suppressed)), [second], 'DND filters only suppressed notifications from visible model');
const saved = api.snapshot(first, 12345);
assert.deepStrictEqual({ id: saved.id, appName: saved.appName, summary: saved.summary, body: saved.body, receivedAt: saved.receivedAt },
  { id: '1', appName: 'GitLab', summary: 'Merge request', body: 'Review needed', receivedAt: 12345 });
assert.strictEqual(typeof saved.image, 'string', 'in-memory snapshot may retain the image URI for future history previews');
const large = api.snapshot({ id: 3, appName: 'A'.repeat(400), summary: 'S'.repeat(900), body: 'B'.repeat(10000), image: 'data:image/png;base64,' + 'x'.repeat(10000) }, 1);
assert.strictEqual(large.appName.length, 256, 'sender label is bounded');
assert.strictEqual(large.summary.length, 512, 'summary is bounded');
assert.strictEqual(large.body.length, 8192, 'body snapshot is bounded');
assert.strictEqual(large.image, '', 'large inline data images are not copied into the memory history');
const tracked = [first, second];
const qmlTrackedList = { 0: first, 1: second, length: 2 };
assert.deepStrictEqual(Array.from(api.visibleNotifications(qmlTrackedList, suppressed)), [second], 'QML-style indexed model values are filtered without requiring native Array');
const ids = api.trackedIdSet(tracked);
assert.strictEqual(api.trackedIdSet(qmlTrackedList)['1'], true, 'QML-style tracked values retain notification IDs for pruning');
assert.strictEqual(ids['1'], true);
assert.deepStrictEqual(Object.keys(api.pruneSuppressedIds({ '1': true, '3': true }, tracked)), ['1']);
const records = [{ id: '1', expiresAt: 100 }, { id: '2', expiresAt: 0 }, { id: '3', expiresAt: 250 }];
assert.deepStrictEqual(Array.from(api.dueRecords(records, 200)), [records[0]], 'only finite expired DND notifications are closed');
assert.deepStrictEqual(Array.from(api.pruneRecords(records, tracked)), records.slice(0, 2), 'records are pruned when NotificationServer releases a notification');
console.log('notification DND filtering, bounded record helpers and timeout contract: OK');
const schemaSource = fs.readFileSync(process.argv[2] + '/js/settings/SettingsSchema.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const schemaContext = {};
vm.createContext(schemaContext);
vm.runInContext(schemaSource + '\nthis.normalizeProfileForTest = normalizeProfile;', schemaContext);
assert.strictEqual(schemaContext.normalizeProfileForTest({ notificationsTimeoutIndicatorStyle: 'bar' }, false).notificationsDoNotDisturb, false, 'legacy full profiles default DND to off');
assert.strictEqual(schemaContext.normalizeProfileForTest({ notificationsDoNotDisturb: true }, true).notificationsDoNotDisturb, true, 'sparse profiles preserve enabled DND');
assert(!Object.prototype.hasOwnProperty.call(schemaContext.normalizeProfileForTest({ notificationsDoNotDisturb: 'yes' }, true), 'notificationsDoNotDisturb'), 'invalid sparse DND value is discarded');
assert.strictEqual(schemaContext.normalizeProfileForTest({ notificationsDoNotDisturb: 'yes' }, false).notificationsDoNotDisturb, false, 'invalid full-profile DND falls back to off');
console.log('notification DND profile migration defaults and sparse override behavior: OK');
const profilesSource = fs.readFileSync(process.argv[2] + '/js/settings/SettingsProfiles.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const profilesContext = {};
vm.createContext(profilesContext);
vm.runInContext(profilesSource + '\nthis.profileSavePathMatchesForTest = profileSavePathMatches;', profilesContext);
assert.strictEqual(profilesContext.profileSavePathMatchesForTest({}, 'notifications', null, ['notificationsDoNotDisturb']), true, 'notification profile scope saves DND');
console.log('notification DND profile scoped saving: OK');
JS
