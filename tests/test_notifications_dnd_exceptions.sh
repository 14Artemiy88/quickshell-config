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
helper = read('js/notifications/NotificationDnd.js')
check = read('CHECK.sh')
assert 'property string notificationsDndAllowedApps: ""' in config
assert 'property string notificationsDndBlockedApps: ""' in config
assert 'notificationsDndAllowedApps: ""' in defaults
assert 'notificationsDndBlockedApps: ""' in defaults
assert 'notificationsDndAllowedApps: String(config.notificationsDndAllowedApps || "")' in persistence
assert 'notificationsDndBlockedApps: String(config.notificationsDndBlockedApps || "")' in persistence
assert 'o.notificationsDndAllowedApps !== undefined' in apply_core
assert 'o.notificationsDndBlockedApps !== undefined' in apply_core
assert 'p.notificationsDndAllowedApps' in schema and 'slice(0, 4096)' in schema
assert 'p.notificationsDndBlockedApps' in schema
assert resets.count('"notificationsDndAllowedApps"') >= 2
assert resets.count('"notificationsDndBlockedApps"') >= 2, 'module and page reset scopes include app exceptions'
assert 'profile.notificationsDndAllowedApps === undefined' in resets
assert 'profile.notificationsDndBlockedApps === undefined' in resets
assert 'notificationsDndBlockedApps' in nav
assert 'dndApplicationRows' in section and 'setDndApplicationRule' in section
assert 'Игнор DND' in section and 'Отключить' in section and 'root.settings.save()' in section
rule_function = section[section.index('function setDndApplicationRule'):section.index('    // DND\'s catalog')]
assert 'Config.notificationsDndAllowedApps = nextAllowed' in rule_function
assert 'Config.notificationsDndBlockedApps = nextBlocked' in rule_function
assert 'Config.notificationsDndBlockedApps =' not in rule_function.split('if (kind === "allowed")')[1].split('} else if (kind === "blocked")')[0], 'allow-rule toggle never writes blocked-rule setting'
assert 'Config.notificationsDndAllowedApps =' not in rule_function.split('} else if (kind === "blocked")')[1].split('} else {')[0], 'block-rule toggle never writes allow-rule setting'
assert 'NotificationDnd.shouldSuppress(' in qml
assert 'Config.notificationsSeenSenders))' in qml, 'runtime DND matching receives the live sender catalog for appName ambiguity resolution'
assert 'function reconcileDndNotifications()' in qml
assert 'function onNotificationsDndAllowedAppsChanged()' in qml
assert 'function onNotificationsDndBlockedAppsChanged()' in qml
assert 'tests/test_notifications_dnd_exceptions.sh' in check
assert 'notificationsDndAllowedApps' not in read('js/settings/SettingsPersistence.js').split('dndMemoryHistory')[0] or 'dndMemoryHistory' not in read('js/settings/SettingsPersistence.js'), 'no DND history persistence'
print('DND app exceptions settings, profile persistence/reset, live reconciliation and UI wiring: OK')
PY
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const catalogSource = fs.readFileSync(root + '/js/notifications/NotificationAppCatalog.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const catalogContext = vm.createContext({});
vm.runInContext(catalogSource + '\nthis.api = { isUniqueAppNameForDesktopEntry, isAmbiguousAppName, legacyRuleIdsForDesktopEntry, legacyRuleIdsForAppName, migrateUniqueLegacyRules };', catalogContext);
const source = fs.readFileSync(root + '/js/notifications/NotificationDnd.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const context = { NotificationAppCatalog: catalogContext.api };
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { allowedAppTokens, isAllowed, shouldSuppress, visibleNotifications, notificationId };', context);
const api = context.api;
const allowed = ' org.telegram.desktop ; Firefox; firefox, Slack ';
assert.deepStrictEqual(Array.from(api.allowedAppTokens(allowed)), ['org.telegram.desktop', 'firefox', 'slack']);
assert.strictEqual(api.isAllowed({ id: 1, desktopEntry: 'org.telegram.desktop', appName: 'Telegram' }, allowed), true, 'desktop entry ID bypasses DND');
assert.strictEqual(api.isAllowed({ id: 2, desktopEntry: '', appName: 'FIREFOX' }, allowed), true, 'exact app-name fallback is case-insensitive');
assert.strictEqual(api.isAllowed({ id: 3, desktopEntry: 'org.telegram.desktop.beta', appName: 'Telegram Beta' }, allowed), false, 'similar identifiers do not match partially');
assert.strictEqual(api.isAllowed({ id: 4, desktopEntry: 'discord', appName: 'Discord' }, allowed), false);
assert.strictEqual(api.isAllowed({ id: 5, desktopEntry: 'firefox' }, ''), false);
assert.strictEqual(api.shouldSuppress({ desktopEntry: 'discord' }, true, allowed, ''), true, 'unlisted apps are suppressed while DND is on');
assert.strictEqual(api.shouldSuppress({ desktopEntry: 'firefox' }, true, allowed, ''), false, 'allowlisted apps bypass enabled DND');
assert.strictEqual(api.shouldSuppress({ desktopEntry: 'discord' }, false, '', 'discord'), true, 'blocklisted apps are suppressed while DND is off');
assert.strictEqual(api.shouldSuppress({ desktopEntry: 'firefox' }, false, '', 'discord'), false, 'other apps remain visible while DND is off');

const mailCatalog = [
  { id: 'org.example.mail-a', desktopEntry: 'org.example.mail-a', appName: 'Mail', appNameAliases: ['Mail'] },
  { id: 'org.example.mail-b', desktopEntry: 'org.example.mail-b', appName: 'Mail', appNameAliases: ['Mail'] }
];
assert.strictEqual(api.isAllowed({ desktopEntry: 'org.example.mail-a', appName: 'Mail' }, 'org.example.mail-a', mailCatalog), true,
  'canonical desktop ID allows only the selected app');
assert.strictEqual(api.isAllowed({ desktopEntry: 'org.example.mail-b', appName: 'Mail' }, 'org.example.mail-a', mailCatalog), false,
  'one desktop-entry rule never leaks to another app with the same appName');
assert.strictEqual(api.isAllowed({ desktopEntry: 'org.example.mail-a', appName: 'Mail' }, 'Mail', mailCatalog), false,
  'ambiguous legacy appName rule is not applied to either desktop-backed sender');
assert.strictEqual(api.isAllowed({ desktopEntry: 'org.example.mail-a', appName: 'Mail' }, 'Mail', [mailCatalog[0]]), true,
  'legacy appName rule remains compatible while that name uniquely identifies one sender');
const renamedCatalog = [{ id: 'org.example.renamed', desktopEntry: 'org.example.renamed', appName: 'New Name', appNameAliases: ['Old Name', 'New Name'] }];
assert.strictEqual(api.isAllowed({ desktopEntry: 'org.example.renamed', appName: 'New Name' }, 'Old Name', renamedCatalog), true,
  'legacy appName rule survives an appName change while desktop ID stays stable');
assert.strictEqual(api.isAllowed({ desktopEntry: '', appName: 'New Name' }, 'Old Name', renamedCatalog), true,
  'name-only notification can resolve a historical alias when exactly one observed sender owns the current name');
const nameOnly = { id: 'Mail', desktopEntry: '', appName: 'Mail', appNameAliases: ['Mail'] };
assert.strictEqual(api.isAllowed({ desktopEntry: '', appName: 'Mail' }, 'Mail', [nameOnly]), true,
  'appName remains the canonical fallback when the sender supplies no desktopEntry');
assert.strictEqual(api.isAllowed({ desktopEntry: '', appName: 'Mail' }, 'Mail', mailCatalog.concat([nameOnly])), false,
  'name-only sender becomes ambiguous when the same appName belongs to multiple identities');
assert.strictEqual(api.shouldSuppress({ desktopEntry: 'org.example.mail-b', appName: 'Mail' }, true,
  'org.example.mail-a', '', mailCatalog), true, 'DND runtime decision receives sender catalog for alias disambiguation');
const tracked = [
  { id: 1, desktopEntry: 'org.telegram.desktop', appName: 'Telegram' },
  { id: 2, desktopEntry: 'firefox', appName: 'Firefox' },
  { id: 3, desktopEntry: 'discord', appName: 'Discord' }
];
const suppressed = { '1': true, '2': true, '3': true };
const visible = api.visibleNotifications(tracked, { '2': true, '3': true });
assert.deepStrictEqual(Array.from(visible), [tracked[0]], 'allowlisted app remains visible while other DND notifications stay hidden');
console.log('DND exact app matching, normalization, duplicate removal and visible-model filtering: OK');
JS
