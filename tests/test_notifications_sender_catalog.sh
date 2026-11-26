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
vm.runInContext(source + '\nthis.api = { valuesOf, normalizeDndRuleIds, upsertSender, makeSenderEntry, ruleIds, canonicalRuleIds, uniqueLegacyRuleIds, uniqueRuleIds, matchesAnyRule, isUniqueAppNameForDesktopEntry, isAmbiguousAppName, legacyRuleIdsForDesktopEntry, legacyRuleIdsForAppName, migrateUniqueLegacyRules, mergeConfiguredEntries };', context);
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
  },
  'org.example.mail-a': {
    id: 'org.example.mail-a', name: 'Mail A', genericName: 'Mail Client',
    comment: 'Mail application A', keywords: ['Email'], categories: ['Network'],
    execString: 'mail-a', startupClass: 'mail-a', runInTerminal: false, icon: 'mail'
  },
  'org.example.mail-b': {
    id: 'org.example.mail-b', name: 'Mail B', genericName: 'Mail Client',
    comment: 'Mail application B', keywords: ['Email'], categories: ['Network'],
    execString: 'mail-b', startupClass: 'mail-b', runInTerminal: false, icon: 'mail'
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

// Same desktop ID is one sender even when its appName changes. Preserve old
// appName values as aliases, but keep the desktop ID as the editable identity.
let renamed = api.upsertSender([], {
  desktopEntry: 'org.example.renamed', appName: 'Old Mail Name'
}, lookup);
renamed = api.upsertSender(renamed, {
  desktopEntry: 'org.example.renamed', appName: 'New Mail Name'
}, lookup);
assert.strictEqual(renamed.length, 1, 'same desktop ID remains one sender when appName changes');
assert.deepStrictEqual(Array.from(api.ruleIds(renamed[0])).sort(),
  ['New Mail Name', 'Old Mail Name', 'org.example.renamed'].sort(), 'old and current appName aliases are retained');
assert.deepStrictEqual(Array.from(api.canonicalRuleIds(renamed[0])), ['org.example.renamed'],
  'desktop ID remains the sole canonical rule identity');
assert.deepStrictEqual(Array.from(api.uniqueLegacyRuleIds(renamed[0], renamed)).sort(),
  ['New Mail Name', 'Old Mail Name'].sort(), 'unique legacy aliases remain discoverable for migration');
assert.deepStrictEqual(Array.from(api.legacyRuleIdsForDesktopEntry('org.example.renamed', renamed)).sort(),
  ['New Mail Name', 'Old Mail Name'].sort(), 'runtime DND can resolve historical appName aliases from the canonical desktop ID');
assert.deepStrictEqual(Array.from(api.legacyRuleIdsForAppName('New Mail Name', renamed)).sort(),
  ['New Mail Name', 'Old Mail Name', 'org.example.renamed'].sort(), 'name-only notifications can resolve the canonical desktop ID and aliases only through one unique sender identity');
assert.deepStrictEqual(Array.from(api.migrateUniqueLegacyRules(renamed, ['Old Mail Name', 'other.desktop'])),
  ['other.desktop', 'org.example.renamed'], 'unique legacy aliases are migrated to the stable desktop ID without losing unrelated rules');

// An appName shared by different desktop IDs must not connect their DND rules.
const mailA = api.upsertSender([], { desktopEntry: 'org.example.mail-a', appName: 'Mail' }, lookup);
const mailBoth = api.upsertSender(mailA, { desktopEntry: 'org.example.mail-b', appName: 'Mail' }, lookup);
assert.strictEqual(mailBoth.length, 2, 'different desktop IDs stay distinct when appName is identical');
assert.strictEqual(api.matchesAnyRule(mailBoth[0], ['Mail'], mailBoth), false,
  'ambiguous appName legacy rule does not affect the first desktop-backed sender');
assert.strictEqual(api.matchesAnyRule(mailBoth[1], ['Mail'], mailBoth), false,
  'ambiguous appName legacy rule does not affect the second desktop-backed sender');
assert.strictEqual(api.matchesAnyRule(mailBoth[0], ['org.example.mail-a'], mailBoth), true,
  'canonical desktop ID still selects only its own sender');
assert.deepStrictEqual(Array.from(api.uniqueLegacyRuleIds(mailBoth[0], mailBoth)), [],
  'shared appName is not offered as a per-app editable alias');
const ambiguousRows = api.mergeConfiguredEntries(mailBoth, ['Mail'], []);
assert.strictEqual(ambiguousRows.length, 3, 'ambiguous legacy rule remains separately manageable instead of binding to both apps');
assert.strictEqual(ambiguousRows[2].configuredOnly, true, 'ambiguous legacy name is represented as a configured-only row');
assert.strictEqual(ambiguousRows[2].unusableRule, true, 'ambiguous legacy rule is marked unsafe to apply');

// A name-only event merges into one unambiguous desktop sender, but is kept
// separate when two desktop identities already share the same name.
const oneMail = api.upsertSender([], { desktopEntry: 'org.example.mail-a', appName: 'Mail' }, lookup);
const oneMailNoDesktop = api.upsertSender(oneMail, { desktopEntry: '', appName: 'Mail' }, lookup);
assert.strictEqual(oneMailNoDesktop.length, 1, 'name-only notification is associated when exactly one desktop identity owns the name');
assert.strictEqual(oneMailNoDesktop[0].id, 'org.example.mail-a', 'the stronger desktop identity remains canonical');
assert.strictEqual(oneMailNoDesktop[0].name, 'Mail A', 'name-only metadata does not overwrite a resolved desktop application name');
assert.strictEqual(oneMailNoDesktop[0].desktopEntry, 'org.example.mail-a', 'name-only updates cannot erase an existing desktopEntry');
const twoMailNoDesktop = api.upsertSender(mailBoth, { desktopEntry: '', appName: 'Mail' }, lookup);
assert.strictEqual(twoMailNoDesktop.length, 3, 'ambiguous name-only notification remains separate from two desktop-backed apps');
assert.strictEqual(api.isAmbiguousAppName('Mail', twoMailNoDesktop), true, 'ambiguous appName is detectable');
assert.deepStrictEqual(Array.from(api.migrateUniqueLegacyRules(twoMailNoDesktop, ['Mail'])), ['Mail'],
  'ambiguous legacy names are never guessed or migrated to one of several desktop IDs');
const noDuplicateAmbiguous = api.mergeConfiguredEntries(twoMailNoDesktop, ['Mail'], []);
assert.strictEqual(noDuplicateAmbiguous.length, 3, 'an observed ambiguous name-only sender is not duplicated by a second configured-only row');
assert.strictEqual(api.isUniqueAppNameForDesktopEntry('Mail', 'org.example.mail-a', mailBoth), false,
  'legacy appName does not resolve uniquely when multiple desktop IDs share it');

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
