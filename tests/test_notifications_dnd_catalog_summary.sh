#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/notifications/NotificationAppCatalog.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const context = vm.createContext({});
vm.runInContext(source + '\nthis.api = { summarizeSenders, mergeConfiguredEntries, matchesAnyRule };', context);
const C = context.api;
const senders = [
  { id: 'org.mozilla.firefox', desktopEntry: 'org.mozilla.firefox', appName: 'Firefox', name: 'Firefox', notificationSender: true },
  { id: 'org.telegram.desktop', desktopEntry: 'org.telegram.desktop', appName: 'Telegram', name: 'Telegram', notificationSender: true },
  { id: 'org.example.mail-a', desktopEntry: 'org.example.mail-a', appName: 'Mail', name: 'Mail A', notificationSender: true },
  { id: 'org.example.mail-b', desktopEntry: 'org.example.mail-b', appName: 'Mail', name: 'Mail B', notificationSender: true }
];

let summary = C.summarizeSenders(senders,
  ['org.mozilla.firefox', 'Mail'],
  ['org.telegram.desktop', 'Mail']);
assert.strictEqual(summary.senderCount, 4, 'all observed sender identities are counted independently');
assert.strictEqual(summary.senderWithRulesCount, 2, 'only unambiguous canonical app rules count as configured senders');
assert.strictEqual(summary.senderWithoutRulesCount, 2, 'senders without applicable rules are counted');
assert.strictEqual(summary.ignoreDndCount, 1, 'allow-while-DND count follows canonical identity matching');
assert.strictEqual(summary.disabledOutsideDndCount, 1, 'suppress-while-DND-off count follows canonical identity matching');
assert.strictEqual(summary.savedOnlyCount, 1, 'ambiguous legacy name rule is counted as a saved-only entry');
assert.strictEqual(summary.unresolvedCount, 1, 'ambiguous persisted name rule is surfaced as requiring attention');
assert.strictEqual(summary.managedEntryCount, 5, 'summary also includes configured-only rules outside current sender catalog');

summary = C.summarizeSenders(senders.slice(0, 2), ['org.mozilla.firefox'], ['org.mozilla.firefox']);
assert.strictEqual(summary.senderWithRulesCount, 1, 'one sender may have both independent rules');
assert.strictEqual(summary.ignoreDndCount, 1);
assert.strictEqual(summary.disabledOutsideDndCount, 1);
assert.strictEqual(summary.senderWithoutRulesCount, 1);

const settings = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
assert(settings.includes('NotificationAppCatalog.summarizeSenders('), 'DND page binds catalog-wide summary to source data');
assert(settings.includes('Отправителей: ') && settings.includes('Игнор DND: ') && settings.includes('Отключить: '),
  'summary exposes sender and both rule-direction counts');
assert(settings.includes('Ранее настроено: ') && settings.includes('Неоднозначные: '),
  'summary distinguishes configured-only rules and unresolved identities');
assert(settings.includes('modelData.allowed\n'), 'allow tooltip reflects current checked state');
assert(settings.includes('modelData.blocked\n'), 'block tooltip reflects current checked state');
assert(!settings.includes('root.dndApplicationRows.length) + " · "'),
  'summary is not derived from the currently filtered/limited row model');
console.log('DND catalog summary: sender counts, independent rules, saved-only and ambiguous identities: OK');
JS
