#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const root = process.argv[2];
const helperSource = fs.readFileSync(path.join(root, 'js/notifications/NotificationHistory.js'), 'utf8').replace(/^\.pragma library\s*$/gm, '');
const context = {};
vm.createContext(context);
vm.runInContext(helperSource + '\nthis.api = { upsertEntry, unreadCount };', context);
const api = context.api;
const original = [
  { id: 'mail-1', appName: 'Mail', summary: 'Old subject', body: 'Old body', receivedAt: 100, unread: false },
  { id: 'chat-1', appName: 'Chat', summary: 'Chat item', receivedAt: 90, unread: true }
];
const replaced = api.upsertEntry(original, {
  id: 'mail-1', appName: 'New Mail Name', summary: 'Updated subject', body: 'Updated body',
  desktopEntry: 'org.example.mail', receivedAt: 200, unread: true
}, 30);
assert.deepStrictEqual(Array.from(replaced, x => x.id), ['chat-1', 'mail-1'], 'replacement is moved to newest position without adding a duplicate');
assert.strictEqual(replaced.length, 2, 'replacement keeps one history entry per stable notification ID');
assert.strictEqual(replaced[1].summary, 'Updated subject', 'replacement refreshes the history summary');
assert.strictEqual(replaced[1].body, 'Updated body', 'replacement refreshes the history body');
assert.strictEqual(replaced[1].desktopEntry, 'org.example.mail', 'replacement refreshes sender identity');
assert.strictEqual(replaced[1].unread, true, 'a new replacement update becomes unread');
assert.strictEqual(api.unreadCount(replaced), 2, 'unread count reflects the replaced event');
assert.strictEqual(original[0].summary, 'Old subject', 'upsert does not mutate the original history array or entry');
const capped = api.upsertEntry(replaced, { id: 'mail-2', summary: 'New mail', receivedAt: 300 }, 2);
assert.deepStrictEqual(Array.from(capped, x => x.id), ['mail-1', 'mail-2'], 'history item limit remains enforced after replacement and insertion');
const noId = api.upsertEntry(replaced, { summary: 'No ID' }, 30);
assert.strictEqual(noId.length, replaced.length, 'invalid replacement IDs are ignored');
const duplicate = api.upsertEntry([{ id: 'same' }, { id: 'same' }, { id: 'other' }], { id: 'same', summary: 'canonical' }, 30);
assert.deepStrictEqual(Array.from(duplicate, x => x.id), ['other', 'same'], 'upsert also normalizes malformed duplicate IDs');
const qml = fs.readFileSync(path.join(root, 'components/notifications/Notifications.qml'), 'utf8');
assert(qml.includes('NotificationHistory.upsertEntry('), 'incoming and replaced notifications update history through ID-based upsert');
assert(qml.includes('function scheduleTrackedNotificationRefresh(notification)'), 'replacement refresh path exists');
assert(qml.includes('root.recordNotificationHistory(current, Date.now())'), 'replacement path snapshots refreshed notification properties');
assert(qml.includes('root.reconcileDndNotifications()'), 'replacement path reapplies the current DND rules');
console.log('Notification history replacement/upsert, duplicate IDs, unread state and bounded retention: OK');
JS
