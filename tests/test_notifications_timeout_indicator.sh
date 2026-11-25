#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
persistence = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
apply_core = (root / "js/settings/SettingsApplyCore.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
settings_ui = (root / "components/settings/sections/SettingsNotificationsSection.qml").read_text(encoding="utf-8")
notifications = (root / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
helper = (root / "js/notifications/NotificationTimeout.js").read_text(encoding="utf-8")

assert 'property bool notificationsShowTimeoutIndicator: false' in config
assert 'notificationsShowTimeoutIndicator: false' in defaults
assert 'notificationsShowTimeoutIndicator: config.notificationsShowTimeoutIndicator' in persistence
assert 'if (o.notificationsShowTimeoutIndicator !== undefined) Config.notificationsShowTimeoutIndicator = !!o.notificationsShowTimeoutIndicator' in apply_core
assert resets.count('"notificationsShowTimeoutIndicator"') >= 2, 'module and page Reset must restore the indicator setting'
assert 'function remainingFraction(elapsed, timeout)' in helper
assert 'NotificationTimeout.remainingFraction(visibleTimeoutElapsed, effectiveTimeout)' in notifications
assert 'visible: Config.notificationsShowTimeoutIndicator && card.notification !== null' in notifications
assert 'width: parent.width * card.remainingTimeoutFraction' in notifications
assert 'changeKeys: ({ keys: ["notificationsDefaultTimeout", "notificationsCriticalTimeout", "notificationsShowTimeoutIndicator"] })' in settings_ui
assert 'text: "Показывать время до закрытия"' in settings_ui
assert 'Config.notificationsShowTimeoutIndicator = checked' in settings_ui
assert 'Полоса показывает оставшееся время автоматического закрытия' in settings_ui
print("notification timeout indicator settings, persistence, Reset and rendering: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/notifications/NotificationTimeout.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.remainingFractionForTest = remainingFraction;', context);
const cases = [
  [0, 5000, 1],
  [2500, 5000, 0.5],
  [5000, 5000, 0],
  [6000, 5000, 0],
  [-100, 5000, 1],
  [100, 0, 0],
  [100, -1, 0],
  [100, Infinity, 0],
  [NaN, 5000, 0]
];
for (const [elapsed, timeout, expected] of cases) {
  const actual = context.remainingFractionForTest(elapsed, timeout);
  if (Math.abs(actual - expected) > 1e-9)
    throw new Error(`remainingFraction(${elapsed}, ${timeout}) = ${actual}, expected ${expected}`);
}
console.log('notification timeout indicator fraction boundaries: OK');
const profileSource = fs.readFileSync(root + '/js/settings/SettingsProfiles.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const profileContext = {};
vm.createContext(profileContext);
vm.runInContext(profileSource + '\nthis.profilePathMatchesForTest = profileSavePathMatches; this.modulePathMatchesForTest = modulePathMatches;', profileContext);
if (!profileContext.profilePathMatchesForTest({}, 'notifications', null, ['notificationsShowTimeoutIndicator']))
  throw new Error('notification module scoped save omitted the timeout indicator setting');
if (!profileContext.modulePathMatchesForTest(['notificationsShowTimeoutIndicator'], 'notifications'))
  throw new Error('notification module reset scope omitted the timeout indicator setting');
console.log('notification timeout indicator profile scoped save/reset: OK');
JS
