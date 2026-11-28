#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const strip = source => source.replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');

const catalogContext = vm.createContext({});
vm.runInContext(strip(fs.readFileSync(path.join(root, 'js/notifications/NotificationAppCatalog.js'), 'utf8')) +
  '\nthis.api = { legacyRuleIdsForDesktopEntry, legacyRuleIdsForAppName, isUniqueAppNameForDesktopEntry, isAmbiguousAppName };', catalogContext);
const dndContext = vm.createContext({ NotificationAppCatalog: catalogContext.api });
vm.runInContext(strip(fs.readFileSync(path.join(root, 'js/notifications/NotificationDnd.js'), 'utf8')) +
  '\nthis.api = { isHistoryIgnored, isAllowed, shouldSuppress, matchesApplicationRule };', dndContext);
const D = dndContext.api;
const senders = [
  { id: 'org.mozilla.firefox', desktopEntry: 'org.mozilla.firefox', appName: 'Firefox', appNameAliases: ['Firefox'] },
  { id: 'org.telegram.desktop', desktopEntry: 'org.telegram.desktop', appName: 'Telegram', appNameAliases: ['Telegram'] }
];
const firefox = { id: 1, desktopEntry: 'org.mozilla.firefox', appName: 'Firefox' };
const telegram = { id: 2, desktopEntry: 'org.telegram.desktop', appName: 'Telegram' };
assert.strictEqual(D.isHistoryIgnored(firefox, 'org.mozilla.firefox', senders), true,
  'history ignore rule matches the canonical desktop ID');
assert.strictEqual(D.isHistoryIgnored(telegram, 'org.mozilla.firefox', senders), false,
  'history ignore rule does not leak to another desktop ID');
assert.strictEqual(D.isHistoryIgnored(firefox, 'Firefox', senders), true,
  'a unique legacy appName rule remains compatible');
assert.strictEqual(D.isHistoryIgnored({ desktopEntry: '', appName: 'Firefox' }, 'Firefox', senders), true,
  'name-only event resolves to a unique observed sender alias');

const sameName = [
  { id: 'mail-a', desktopEntry: 'mail-a', appName: 'Mail', appNameAliases: ['Mail'] },
  { id: 'mail-b', desktopEntry: 'mail-b', appName: 'Mail', appNameAliases: ['Mail'] }
];
assert.strictEqual(D.isHistoryIgnored({ desktopEntry: 'mail-a', appName: 'Mail' }, 'Mail', sameName), false,
  'ambiguous legacy appName is not applied to multiple desktop identities');
assert.strictEqual(D.isHistoryIgnored({ desktopEntry: 'mail-a', appName: 'Mail' }, 'mail-a', sameName), true,
  'canonical identity remains deterministic when appName is shared');

// The history-only rule is deliberately not part of either popup DND rule set.
assert.strictEqual(D.shouldSuppress(firefox, false, '', '', senders), false,
  'history exclusion alone never suppresses a popup while DND is off');
assert.strictEqual(D.shouldSuppress(firefox, true, '', '', senders), true,
  'history exclusion alone does not bypass an enabled global DND');
assert.strictEqual(D.shouldSuppress(firefox, true, 'org.mozilla.firefox', '', senders), false,
  'the existing Ignore DND rule remains independent of history exclusion');
assert.strictEqual(D.shouldSuppress(firefox, false, '', 'org.mozilla.firefox', senders), true,
  'the existing Disable rule remains independent of history exclusion');

const config = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaults = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const persistence = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8');
const apply = fs.readFileSync(path.join(root, 'js/settings/SettingsApplyCore.js'), 'utf8');
const schema = fs.readFileSync(path.join(root, 'js/settings/SettingsSchema.js'), 'utf8');
const resets = fs.readFileSync(path.join(root, 'js/settings/SettingsResets.js'), 'utf8');
const nav = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const section = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsNotificationsSection.qml'), 'utf8');
const qml = fs.readFileSync(path.join(root, 'components/notifications/Notifications.qml'), 'utf8');
const check = fs.readFileSync(path.join(root, 'CHECK.sh'), 'utf8');
assert(config.includes('property string notificationsHistoryIgnoredApps: ""'), 'Config exposes the independent rule list');
assert(defaults.includes('notificationsHistoryIgnoredApps: ""'), 'new profiles default to no history exclusions');
assert(persistence.includes('notificationsHistoryIgnoredApps: String(config.notificationsHistoryIgnoredApps || "")'), 'the rule is persisted');
assert(apply.includes('o.notificationsHistoryIgnoredApps !== undefined'), 'the rule loads from settings');
assert(schema.includes('p.notificationsHistoryIgnoredApps'), 'the rule has schema validation');
assert(resets.includes('profile.notificationsHistoryIgnoredApps === undefined'), 'the rule follows active-profile defaults');
assert(resets.includes('"notificationsHistoryIgnoredApps"'), 'module and page resets include the rule');
assert(nav.includes('notificationsHistoryIgnoredApps'), 'DND subtab dirty/reset tracking includes the rule');
assert(section.includes('Config.notificationsHistoryIgnoredApps'), 'the DND settings UI binds the rule');
assert(section.includes('root.setDndApplicationRule("history"'), 'the third checkbox writes only the history rule list');
assert(section.includes('modelData.historyIgnored === true'), 'the third checkbox reflects the matched rule');
assert(section.includes('Игнорировать в истории'), 'the third checkbox is searchable by its label');
assert(section.includes('root.normalizedDndRuleIds(Config.notificationsHistoryIgnoredApps)'), 'the rule participates in app catalog search');
assert(section.includes('Config.notificationsHistoryIgnoredApps = nextHistoryIgnored'), 'removing a sender removes its history-ignore rule too');

const recordFunction = qml.slice(qml.indexOf('function recordNotificationHistory'), qml.indexOf('function findTrackedNotification'));
assert(recordFunction.indexOf('NotificationDnd.isHistoryIgnored(') >= 0, 'history insertion checks the per-app exclusion');
assert(recordFunction.indexOf('NotificationDnd.isHistoryIgnored(') < recordFunction.indexOf('NotificationDnd.snapshot('),
  'ignored events are rejected before making a history snapshot');
assert(recordFunction.includes('Config.notificationsHistoryIgnoredApps'), 'history exclusion uses its own rule list');
assert(qml.includes('root.recordNotificationHistory(notification, Date.now())'), 'initial and replacesId refresh paths use the common history gate');
assert(!recordFunction.includes('root.notificationHistory = []'), 'enabling the rule does not erase older history');
const acceptFunction = qml.slice(qml.indexOf('function acceptNotification'), qml.indexOf('function dismissTrackedNotifications'));
assert(acceptFunction.indexOf('root.recordNotificationSender(notification)') < acceptFunction.indexOf('root.recordNotificationHistory(notification, Date.now())'), 'sender identity and aliases are resolved before history exclusion');
assert(acceptFunction.indexOf('root.recordNotificationHistory(notification, Date.now())') < acceptFunction.indexOf('NotificationDnd.shouldSuppress('), 'history exclusion is independent from subsequent popup DND processing');
assert(qml.includes('root.recordNotificationHistory(current, Date.now())'), 'replacesId property updates pass through the same history exclusion gate');
assert(section.includes('historyIgnored = LauncherAppPreferences.setId(historyIgnored, removableIds[i], false)'), 'removing a sender also clears its third rule');
assert(check.includes('tests/test_notifications_history_ignore_app.sh'), 'the new regression test is registered in CHECK.sh');
console.log('Per-app history exclusion: independent rule matching, alias safety, popup DND independence and profile persistence: OK');
JS
