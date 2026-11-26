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
vm.runInContext(helperSource + '\nthis.api = { removeEntryById, unreadCount, groupedEntries };', context);
const api = context.api;
const history = [
  { id: 'mail-1', appName: 'Mail', summary: 'Unread item', receivedAt: 300, unread: true },
  { id: 'chat-1', appName: 'Chat', summary: 'Chat item', receivedAt: 250, unread: false },
  { id: 'mail-2', appName: 'Mail', summary: 'Read item', receivedAt: 200, unread: false },
  { id: 'mail-3', appName: 'Mail', summary: 'Another unread item', receivedAt: 100, unread: true },
];
const afterOneDelete = api.removeEntryById(history, 'mail-1');
assert.deepStrictEqual(Array.from(afterOneDelete, x => x.id), ['chat-1', 'mail-2', 'mail-3'], 'deleting one entry leaves every other notification intact');
assert.strictEqual(api.unreadCount(afterOneDelete), 1, 'unread count is recalculated after deleting an unread entry');
assert.deepStrictEqual(Array.from(api.groupedEntries(afterOneDelete), x => x.id), ['chat-1', 'mail-2', 'mail-3'], 'remaining groups and entries are regenerated from retained history');
assert.strictEqual(api.groupedEntries(afterOneDelete).filter(x => x.appGroup === 'Mail').length, 2, 'app group count reflects the deleted entry');
assert.strictEqual(history.length, 4, 'removal does not mutate the original history');
const afterLastGroupEntry = api.removeEntryById(afterOneDelete, 'mail-2');
const afterFinalMail = api.removeEntryById(afterLastGroupEntry, 'mail-3');
assert.deepStrictEqual(Array.from(api.groupedEntries(afterFinalMail), x => x.appGroup), ['Chat'], 'group disappears when its final entry is deleted');
assert.strictEqual(api.removeEntryById(history, 'missing').length, history.length, 'unknown IDs do not remove entries');
assert.strictEqual(api.removeEntryById(history, '').length, history.length, 'empty IDs cannot delete history entries');
const duplicateIds = [{ id: 'same', summary: 'first' }, { id: 'same', summary: 'second' }];
const afterDuplicateDelete = api.removeEntryById(duplicateIds, 'same');
assert.strictEqual(afterDuplicateDelete.length, 1, 'only one entry is removed when malformed duplicate IDs exist');
assert.strictEqual(afterDuplicateDelete[0].summary, 'second', 'the first matching duplicate is removed deterministically');

const qml = fs.readFileSync(path.join(root, 'components/notifications/Notifications.qml'), 'utf8');
const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const shell = fs.readFileSync(path.join(root, 'shell.qml'), 'utf8');
assert(qml.includes('function removeNotificationHistoryEntry(entryId)') && qml.includes('NotificationHistory.removeEntryById(current, entryId)'), 'Notifications exposes a single-entry removal operation');
assert(dash.includes('signal historyEntryDeleteRequested(string entryId)'), 'Dashboard exposes an entry-delete signal');
assert(dash.includes('root.historyEntryDeleteRequested(String(modelData.id || ""))'), 'each history card emits its own notification ID');
assert(dash.includes('Accessible.name: "Удалить уведомление: "'), 'delete action has an accessible name');
assert(shell.includes('onHistoryEntryDeleteRequested: function(entryId)') && shell.includes('removeNotificationHistoryEntry(entryId)'), 'shell forwards deletion to Notifications module');
console.log('Notification history single-entry deletion, unread counts and app grouping: OK');
JS
