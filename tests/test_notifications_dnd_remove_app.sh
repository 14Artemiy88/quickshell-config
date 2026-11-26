#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const catalogSource = fs.readFileSync(root + '/js/notifications/NotificationAppCatalog.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const context = vm.createContext({});
vm.runInContext(catalogSource + '\nthis.api = { ruleIds, removeSenderById, removableRuleIds };', context);
const api = context.api;

const firefox = { id: 'org.mozilla.firefox', name: 'Firefox', desktopEntry: 'org.mozilla.firefox', appName: 'Firefox' };
const telegram = { id: 'org.telegram.desktop', name: 'Telegram', desktopEntry: 'org.telegram.desktop', appName: 'Telegram' };
const remaining = api.removeSenderById([firefox, telegram], 'org.mozilla.firefox');
assert.deepStrictEqual(Array.from(remaining, item => item.id), ['org.telegram.desktop'],
  'removeSenderById removes only the selected canonical sender');
assert.deepStrictEqual(Array.from(api.removeSenderById([firefox, telegram], 'missing')), [firefox, telegram],
  'unknown sender removal leaves the runtime catalog unchanged');

const mailA = { id: 'org.example.mail-a', desktopEntry: 'org.example.mail-a', appName: 'Mail', name: 'Mail A' };
const mailB = { id: 'org.example.mail-b', desktopEntry: 'org.example.mail-b', appName: 'Mail', name: 'Mail B' };
const afterA = api.removeSenderById([mailA, mailB], mailA.id);
assert.deepStrictEqual(Array.from(api.removableRuleIds(mailA, afterA)), ['org.example.mail-a'],
  'removing one of two senders with a shared appName retains the shared alias for the other sender');
assert.deepStrictEqual(Array.from(api.removableRuleIds(telegram, [firefox])),
  ['org.telegram.desktop', 'Telegram'], 'a unique sender removes both its desktop ID and app-name alias');

const configuredOnly = { id: 'orphan.desktop', name: 'orphan.desktop', configuredOnly: true };
assert.deepStrictEqual(Array.from(api.removableRuleIds(configuredOnly, [firefox])), ['orphan.desktop'],
  'a previously configured orphan row removes its persisted identity');

const section = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
const removeFunction = section.slice(section.indexOf('function removeDndApplication'), section.indexOf('    // DND\'s catalog'));
assert(removeFunction.includes('NotificationAppCatalog.removeSenderById'), 'DND remove action removes the runtime sender entry');
assert(removeFunction.includes('NotificationAppCatalog.removableRuleIds'), 'DND remove action resolves safe aliases');
assert(removeFunction.includes('LauncherAppPreferences.setId(allowed, removableIds[i], false)'), 'DND remove action clears allow rules');
assert(removeFunction.includes('LauncherAppPreferences.setId(blocked, removableIds[i], false)'), 'DND remove action clears block rules');
assert(removeFunction.includes('Config.notificationsSeenSenders = remainingSenders'), 'DND remove action updates the runtime-only catalog');
assert(removeFunction.includes('if (settingsChanged) root.settings.save()'), 'DND remove action persists rule removal only when rules change');
assert(section.includes('Удалить приложение из списка и снять оба его правила DND'), 'UI exposes an explicit remove action');
assert(section.includes('onClicked: root.removeDndApplication(modelData)'), 'row remove action is wired to the selected sender');
console.log('DND sender removal, safe alias handling, both rule lists and UI action: OK');
JS
