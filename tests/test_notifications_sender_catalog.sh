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
vm.runInContext(source + '\nthis.api = { valuesOf, normalizeDndRuleIds, upsertSender, makeSenderEntry, ruleIds, matchesAnyRule, mergeConfiguredEntries };', context);
const api = context.api;
assert.deepStrictEqual(Array.from(api.valuesOf('notify-send')), ['notify-send'],
  'a scalar QString sender value stays one item instead of being expanded into characters');
assert.deepStrictEqual(Array.from(api.normalizeDndRuleIds('n;o;t;i;f;y;-;s;e;n;d')), [],
  'legacy character-split DND identity fragments are discarded');
assert.deepStrictEqual(Array.from(api.normalizeDndRuleIds('org.mozilla.firefox;Telegram')), ['org.mozilla.firefox', 'Telegram'],
  'ordinary persisted multi-app DND rules are preserved');
assert.deepStrictEqual(Array.from(api.normalizeDndRuleIds('X')), ['X'],
  'a legitimate one-character sender identity is not discarded');
const desktopEntries = {
  'org.mozilla.firefox': {
    id: 'org.mozilla.firefox', name: 'Firefox', genericName: 'Web Browser',
    comment: 'Browse the web', keywords: ['Internet', 'Browser'],
    categories: ['Network', 'WebBrowser'], execString: 'firefox %u',
    startupClass: 'firefox', runInTerminal: false, icon: 'firefox'
  }
};
const lookup = id => desktopEntries[id] || null;

let catalog = api.upsertSender([], {
  desktopEntry: 'org.mozilla.firefox', appName: 'Firefox', appIcon: 'firefox'
}, lookup);
assert.strictEqual(catalog.length, 1, 'one real sender is registered');
assert.strictEqual(catalog[0].id, 'org.mozilla.firefox', 'desktop-entry ID is the canonical rule identity');
assert.strictEqual(catalog[0].name, 'Firefox', 'desktop metadata supplies the readable app name');
assert.deepStrictEqual(Array.from(catalog[0].categories), ['Network', 'WebBrowser'], 'desktop categories are retained for Launcher-style filtering');

catalog = api.upsertSender(catalog, {
  desktopEntry: 'org.mozilla.firefox', appName: 'Firefox'
}, lookup);
assert.strictEqual(catalog.length, 1, 'repeated notifications do not create duplicate sender entries');

const firstMail = api.upsertSender([], {
  desktopEntry: 'org.example.another-mail', appName: 'Mail'
}, lookup);
const secondMail = api.upsertSender(firstMail, {
  desktopEntry: 'org.example.other-mail', appName: 'Mail'
}, lookup);
assert.strictEqual(secondMail.length, 2, 'different desktop-entry IDs remain distinct even when their appName is identical');

catalog = api.upsertSender(catalog, {
  desktopEntry: '', appName: 'Name-only sender', appIcon: 'dialog-information'
}, lookup);
assert.strictEqual(catalog.length, 2, 'senders without desktopEntry are still discoverable');
assert.strictEqual(catalog[1].id, 'Name-only sender', 'appName is a fallback identity');
assert.strictEqual(catalog[1].name, 'Name-only sender', 'appName is readable without a desktop file');

const nameOnly = api.upsertSender([], { desktopEntry: '', appName: 'Promoted App' }, lookup);
const promoted = api.upsertSender(nameOnly, { desktopEntry: 'org.example.promoted', appName: 'Promoted App' }, lookup);
assert.strictEqual(promoted.length, 1, 'a name-only sender is promoted instead of duplicated when a desktop ID appears');
assert.strictEqual(promoted[0].id, 'org.example.promoted', 'the desktop ID replaces the weaker name-only identity');
assert.strictEqual(api.matchesAnyRule(promoted[0], ['Promoted App']), true, 'the old appName rule remains a valid alias after promotion');

catalog = api.upsertSender(catalog, { desktopEntry: '', appName: '   ' }, lookup);
assert.strictEqual(catalog.length, 2, 'anonymous notifications do not create unusable sender rows');

assert.deepStrictEqual(Array.from(api.ruleIds(catalog[0])).sort(),
  ['Firefox', 'org.mozilla.firefox'].sort(), 'DND rules support desktop-entry and app-name aliases');
assert.strictEqual(api.matchesAnyRule(catalog[0], ['Firefox']), true, 'legacy app-name rules remain recognized');

const merged = api.mergeConfiguredEntries(catalog, ['old.desktop'], ['Firefox']);
assert.strictEqual(merged.length, 3, 'configured sender identities are preserved across app restarts');
assert.strictEqual(merged[2].configuredOnly, true, 'prior-session rules are explicitly represented as configured-only rows');
const mergedWithLegacyFragments = api.mergeConfiguredEntries(catalog, 'n;o;t;i;f;y;-;s;e;n;d', '');
assert.strictEqual(mergedWithLegacyFragments.length, catalog.length,
  'legacy character fragments no longer create a row per character or bypass Show All');

const notifications = fs.readFileSync(root + '/components/notifications/Notifications.qml', 'utf8');
assert(notifications.includes('root.recordNotificationSender(notification)'), 'each incoming notification contributes its sender identity');
assert(notifications.includes('DesktopEntries.byId(desktopEntryId)'), 'sender identity uses exact DesktopEntries.byId lookup');
const settings = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
assert(settings.includes('Config.notificationsSeenSenders || []'), 'DND UI consumes runtime-only observed senders');
assert(!settings.includes('DesktopEntries.applications.values'), 'DND no longer enumerates every installed app');
const config = fs.readFileSync(root + '/Config.qml', 'utf8');
assert(config.includes('property var notificationsSeenSenders: []'), 'observed sender catalog starts empty on process startup');
const persistence = fs.readFileSync(root + '/js/settings/SettingsPersistence.js', 'utf8');
assert(!persistence.includes('notificationsSeenSenders'), 'sender catalog is never added to disk persistence');
console.log('Notification sender catalog: observed-only discovery, exact identity, name fallback, deduplication and runtime-only storage: OK');
JS
