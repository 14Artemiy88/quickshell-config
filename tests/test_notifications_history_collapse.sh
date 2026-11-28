#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const assert = require('assert');
const root = process.argv[2];
const helperPath = path.join(root, 'js/notifications/NotificationHistory.js');
const source = fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma library\s*$/gm, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { isGroupExpanded, toggleExpandedGroup, removeExpandedGroup };', context);
const api = context.api;

const initial = ['Mail', 'Chat'];
assert.strictEqual(api.isGroupExpanded(initial, 'mail'), true, 'expanded lookup is case-insensitive');
assert.strictEqual(api.isGroupExpanded(initial, 'Calendar'), false, 'new/unlisted app groups start collapsed');
assert.deepStrictEqual(Array.from(api.toggleExpandedGroup(initial, 'MAIL')), ['Chat'], 'toggle collapses an expanded group');
assert.deepStrictEqual(initial, ['Mail', 'Chat'], 'toggle does not mutate caller state');
assert.deepStrictEqual(Array.from(api.toggleExpandedGroup(initial, 'Calendar')), ['Mail', 'Chat', 'Calendar'], 'toggle expands a collapsed group');
assert.deepStrictEqual(Array.from(api.toggleExpandedGroup([], '')), [], 'empty labels cannot create expanded entries');
assert.deepStrictEqual(Array.from(api.removeExpandedGroup(initial, 'chat')), ['Mail'], 'deleting a group clears its expanded state');

const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dash.includes('property var notificationHistoryExpandedApps: []'), 'Dashboard starts with no expanded groups');
assert(dash.includes('function isNotificationHistoryGroupCollapsed(appGroup)') && dash.includes('return !NotificationHistory.isGroupExpanded('), 'groups absent from expanded list are collapsed by default');
assert(dash.includes('function toggleNotificationHistoryGroup(appGroup)') && dash.includes('NotificationHistory.toggleExpandedGroup('), 'Dashboard toggles groups immutably');
assert(dash.includes('historyGroupToggleMouse') && dash.includes('root.toggleNotificationHistoryGroup(String(section))'), 'whole app header is a clickable accessible toggle');
assert(dash.includes('text: root.isNotificationHistoryGroupCollapsed(String(section)) ? "⌄" : "⌃"'), 'header uses the settings-folder chevron indicator');
assert(dash.includes('text: section + "  ·  "') && dash.includes('historyGroupChevron'), 'app name/count and arrow are part of one clickable header');
assert(!dash.includes('id: historyGroupToggleMouse') || !dash.includes('width: 24\n                    height: 24'), 'separate square toggle button is removed');
assert(dash.includes('model: root.filteredNotificationHistoryModel') && dash.includes('section.property: "appGroup"'), 'the underlying grouped model remains intact so collapsed headers stay visible');
assert(dash.includes('height: groupCollapsed ? 0 : historyEntryCard.height + 7') && dash.includes('Behavior on height'), 'entry cards collapse to zero height with animation');
assert(dash.includes('root.forgetNotificationHistoryGroupCollapse(String(section))'), 'confirmed group deletion also clears expanded state');
console.log('Notification history collapsed-by-default groups, clickable folder-style headers, immutable toggles and animated rows: OK');
JS
