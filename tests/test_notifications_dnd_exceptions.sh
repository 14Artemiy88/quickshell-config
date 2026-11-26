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
const source = fs.readFileSync(process.argv[2] + '/js/notifications/NotificationDnd.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
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
