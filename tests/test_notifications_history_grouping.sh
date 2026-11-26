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
vm.runInContext(source + '\nthis.api = { groupedEntries, unreadCount, markAllRead, pruneEntries };', context);
const api = context.api;
const history = [
  { id: '1', appName: 'Mail', receivedAt: 100, unread: true },
  { id: '2', appName: 'Chat', receivedAt: 200, unread: true },
  { id: '3', appName: 'mail', receivedAt: 300, unread: false },
  { id: '4', desktopEntry: 'calendar.desktop', receivedAt: 150, unread: true },
  { id: '5', appName: 'Chat', receivedAt: 250, unread: false },
];
const grouped = api.groupedEntries(history);
assert.deepStrictEqual(Array.from(grouped, x => x.id), ['3', '1', '5', '2', '4'], 'groups follow most-recent app activity and entries are newest-first');
assert.deepStrictEqual(Array.from(grouped, x => x.appGroup), ['Mail', 'Mail', 'Chat', 'Chat', 'calendar.desktop']);
assert.strictEqual(api.unreadCount(history), 3, 'unread count includes only unread entries');
const read = api.markAllRead(history);
assert.strictEqual(api.unreadCount(read), 0, 'opening history marks all retained entries read');
assert.strictEqual(history[0].unread, true, 'marking read is immutable');
assert.strictEqual(api.groupedEntries([]).length, 0, 'empty history yields no groups');
console.log('Notification history grouping by app, recent-first ordering and unread state: OK');
JS
