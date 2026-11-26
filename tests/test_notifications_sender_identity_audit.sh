#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];

const catalogSource = fs.readFileSync(root + '/js/notifications/NotificationAppCatalog.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const catalogContext = vm.createContext({});
vm.runInContext(catalogSource + '\nthis.api = { upsertSender, ruleIds, canonicalRuleIds, uniqueLegacyRuleIds, matchesAnyRule, mergeConfiguredEntries, removeSenderById, removableRuleIds, isUniqueAppNameForDesktopEntry, isAmbiguousAppName, legacyRuleIdsForDesktopEntry, legacyRuleIdsForAppName, migrateUniqueLegacyRules };', catalogContext);
const C = catalogContext.api;

const lookup = id => ({ id, name: id, genericName: '', comment: '', keywords: [], categories: [], execString: '', startupClass: '', runInTerminal: false, icon: '' });
let senders = C.upsertSender([], { desktopEntry: 'org.example.mail-a', appName: 'Mail' }, lookup);
senders = C.upsertSender(senders, { desktopEntry: 'org.example.mail-b', appName: 'Mail' }, lookup);
assert.strictEqual(senders.length, 2, 'distinct desktop IDs must not merge by equal appName');
assert.deepStrictEqual(Array.from(C.canonicalRuleIds(senders[0])), ['org.example.mail-a']);
assert.deepStrictEqual(Array.from(C.uniqueLegacyRuleIds(senders[0], senders)), [], 'shared appName is not an editable alias');
assert.strictEqual(C.matchesAnyRule(senders[0], ['Mail'], senders), false, 'legacy shared name cannot enable the first app');
assert.strictEqual(C.matchesAnyRule(senders[1], ['Mail'], senders), false, 'legacy shared name cannot enable the second app');
assert.strictEqual(C.matchesAnyRule(senders[0], ['org.example.mail-a'], senders), true, 'desktop ID selects only its own app');

const mergedRules = C.mergeConfiguredEntries(senders, ['Mail'], []);
const ambiguousRule = mergedRules.find(entry => entry.id === 'Mail');
assert(ambiguousRule && ambiguousRule.configuredOnly && ambiguousRule.unusableRule,
  'ambiguous persisted name rule remains visible as a removable unsafe legacy row');
const afterRemoveA = C.removeSenderById(senders, 'org.example.mail-a');
assert.deepStrictEqual(Array.from(C.removableRuleIds(senders[0], afterRemoveA)), ['org.example.mail-a'],
  'deleting one sender retains shared appName rules for the remaining sender');

let renamed = C.upsertSender([], { desktopEntry: 'org.example.renamed', appName: 'Old Name' }, lookup);
renamed = C.upsertSender(renamed, { desktopEntry: 'org.example.renamed', appName: 'New Name' }, lookup);
assert.strictEqual(renamed.length, 1, 'appName changes do not duplicate a stable desktop identity');
assert.deepStrictEqual(Array.from(C.legacyRuleIdsForDesktopEntry('org.example.renamed', renamed)).sort(),
  ['New Name', 'Old Name'].sort(), 'both historical and current appName aliases resolve to the same desktop identity');
assert.deepStrictEqual(Array.from(C.migrateUniqueLegacyRules(renamed, ['Old Name'])), ['org.example.renamed'],
  'legacy appName settings migrate automatically to a stable desktop ID once observed');

let onlyA = C.upsertSender([], { desktopEntry: 'org.example.only-a', appName: 'Unique' }, lookup);
onlyA = C.upsertSender(onlyA, { desktopEntry: '', appName: 'Unique' }, lookup);
assert.strictEqual(onlyA.length, 1, 'name-only notification promotes into exactly one unambiguous desktop identity');
assert.strictEqual(onlyA[0].id, 'org.example.only-a', 'promotion never downgrades the canonical desktop ID');

let ambiguousNoDesktop = C.upsertSender(senders, { desktopEntry: '', appName: 'Mail' }, lookup);
assert.strictEqual(ambiguousNoDesktop.length, 3, 'name-only sender remains separate when multiple desktop IDs share the appName');
assert.strictEqual(C.isAmbiguousAppName('Mail', ambiguousNoDesktop), true);
assert.deepStrictEqual(Array.from(C.removableRuleIds(ambiguousNoDesktop[2], C.removeSenderById(ambiguousNoDesktop, 'Mail'))), ['Mail'],
  'deleting an ambiguous name-only row removes its orphan legacy rule while deleting a desktop-backed peer preserves shared aliases');

const dndSource = fs.readFileSync(root + '/js/notifications/NotificationDnd.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const dndContext = vm.createContext({ NotificationAppCatalog: C });
vm.runInContext(dndSource + '\nthis.api = { isAllowed, shouldSuppress };', dndContext);
const D = dndContext.api;
assert.strictEqual(D.isAllowed({ desktopEntry: 'org.example.mail-a', appName: 'Mail' }, 'org.example.mail-a', senders), true);
assert.strictEqual(D.isAllowed({ desktopEntry: 'org.example.mail-b', appName: 'Mail' }, 'org.example.mail-a', senders), false,
  'DND runtime uses desktop ID as authoritative sender identity');
assert.strictEqual(D.isAllowed({ desktopEntry: 'org.example.mail-a', appName: 'Mail' }, 'Mail', senders), false,
  'ambiguous legacy appName never leaks to desktop-backed senders');
assert.strictEqual(D.isAllowed({ desktopEntry: 'org.example.renamed', appName: 'New Name' }, 'Old Name', renamed), true,
  'old appName rule remains compatible for a stable unique desktop ID');
assert.strictEqual(D.isAllowed({ desktopEntry: '', appName: 'Unique' }, 'Unique', onlyA), true,
  'name-only fallback works while the sender name is unambiguous');
assert.strictEqual(D.isAllowed({ desktopEntry: '', appName: 'Mail' }, 'Mail', ambiguousNoDesktop), false,
  'name-only senders with colliding identities are not guessed');

const qml = fs.readFileSync(root + '/components/notifications/Notifications.qml', 'utf8');
const settings = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
assert((qml.match(/Config\.notificationsSeenSenders\)\)/g) || []).length >= 2,
  'both incoming and tracked notification DND decisions receive the live sender catalog');
assert(settings.includes('modelData.ruleIds || [modelData.id], checked, modelData.legacyRuleIds || []'),
  'checkboxes write canonical identities and pass only uniquely-resolvable legacy aliases');
assert(qml.includes('NotificationAppCatalog.migrateUniqueLegacyRules(') && qml.includes('if (rulesChanged) Settings.save()'),
  'unique legacy appName rules are migrated and saved when sender identity becomes known');
assert(settings.includes('enabled: modelData.unusableRule !== true'),
  'unresolvable name-only rules are visibly disabled rather than silently assigned');
console.log('DND sender identity/alias audit: canonical IDs, shared names, rename/promotion, safe legacy mapping and runtime/UI integration: OK');
JS
