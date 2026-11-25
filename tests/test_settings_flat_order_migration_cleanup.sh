#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
function load(relative, injected = {}, appended = '') {
  const source = fs.readFileSync(path.join(root, relative), 'utf8')
    .replace(/^\.pragma library\s*$/gm, '')
    .replace(/^\.import .*$/gm, '');
  const context = Object.assign({}, injected);
  vm.runInNewContext(source + '\n' + appended, context, { filename: relative });
  return context;
}
const configSource = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaultsSource = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const navigationSource = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const widgetSource = fs.readFileSync(path.join(root, 'components/settings/SettingsWidget.qml'), 'utf8');
const settingsSource = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
assert(!configSource.includes('property var settingsTabOrder:'), 'Config no longer declares a flat runtime property');
assert(!defaultsSource.includes('settingsTabOrder:'), 'new profiles/defaults no longer contain flat order');
assert(!navigationSource.includes('Config.settingsTabOrder'), 'live navigation never reads/writes the legacy key');
assert(!widgetSource.includes('settingsTabOrderNormalized'), 'SettingsWidget no longer exposes a flat-order adapter');
assert(!settingsSource.includes('function flattenSettingsNavigationOrder(value)'), 'Settings singleton no longer exposes the flat-order adapter');

const registry = load('js/settings/SettingsPageRegistry.js');
const profiles = load('js/settings/SettingsProfiles.js', { SettingsPageRegistry: registry });
const persistence = load('js/settings/SettingsPersistence.js');
const defaults = registry.defaultNavigationOrder();
const legacyRootOrder = ['weather','modules','settingsWindow','themes','calendar','notifications','dashboard','launcherSearch','launcher'];
const legacyProfileOrder = ['modules','weather','timers','settingsWindow','themes'];
const owner = {
  profileDefaults: { settingsNavigationOrder: defaults, settingsTabLabels: {}, colors: {}, weatherToken: '' },
  profileStorageFormat: 'sparse-v1', profileMigrationPending: false, resetOverrides: {},
  colorNames: [], activeProfile: 'Work',
  normalizeSettingsNavigationOrder: value => registry.normalizeNavigationOrder(value),
  settingsNavigationOrderFromLegacyTabOrder: value => registry.navigationOrderFromLegacyTabOrder(value)
};
const expanded = profiles.expandStoredSettings(owner, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1', activeProfile: 'Work',
  settingsTabOrder: legacyRootOrder,
  profiles: { Work: { settingsTabOrder: legacyProfileOrder } },
  profileOverrides: { settingsTabOrder: ['settingsWindow','themes','weather','modules'] },
  customThemes: {}
});
assert.deepStrictEqual(Array.from(expanded.settingsNavigationOrder.groupOrder), Array.from(defaults.groupOrder),
  'flat legacy order cannot invent frame ordering, so canonical frame order is applied');
assert.deepStrictEqual(Array.from(expanded.settingsNavigationOrder.pagesByGroup.modules.slice(0, 3)), ['weather','modules','timers'],
  'legacy profile order is preserved within the canonical Modules frame when it is the active base');
assert.strictEqual('settingsTabOrder' in expanded, false, 'expanded settings never recreate the old flat field');
assert.strictEqual('settingsTabOrder' in expanded.profiles.Work, false, 'migrated profiles no longer store flat order');
assert.strictEqual(owner.profileMigrationPending, true, 'legacy flat order schedules a one-time settings writeback');
assert(expanded.settingsNavigationOrder.pagesByGroup.appearance.includes('settingsWindow'), 'legacy pages remain in their canonical frame');

const snapshot = {
  settingsNavigationOrder: registry.normalizeNavigationOrder(expanded.settingsNavigationOrder),
  settingsTabLabels: {}, settingsNavigationCollapsedGroups: { appearance: false, modules: true, launcher: false },
  settingsLastActivePageId: 'weather'
};
const saveOwner = {
  profileDefaults: { settingsNavigationOrder: defaults, settingsTabLabels: {} },
  activeProfile: 'Work', profiles: { Work: expanded.profiles.Work }, customThemes: {},
  profileStorageFormat: 'sparse-v1', weatherToken: '',
  snapshotObject: () => JSON.parse(JSON.stringify(snapshot)),
  expandedProfileData: () => ({ settingsNavigationOrder: defaults, settingsTabLabels: {} })
};
const payload = persistence.payloadObject(saveOwner, {
  settingsNavigationCollapsedGroups: snapshot.settingsNavigationCollapsedGroups,
  settingsLastActivePageId: snapshot.settingsLastActivePageId
});
assert(payload.managedKeys.includes('settingsTabOrder'), 'writer marks the old root key for deletion');
assert(!Object.prototype.hasOwnProperty.call(payload, 'settingsTabOrder'), 'new payload does not write flat root order');
assert(!Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsTabOrder'), 'new sparse overrides do not write flat order');
assert(!Object.prototype.hasOwnProperty.call(payload.profiles.Work, 'settingsTabOrder'), 'new profile payload contains only hierarchical order');
assert(Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsNavigationOrder'), 'hierarchical order remains the canonical persisted field');
console.log('Settings flat-order migration: root/profile conversion, sparse writeback, runtime cleanup and stale-key pruning: OK');
NODE

# Exercise the real JSON writer against an existing file containing the obsolete root key.
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
mkdir -p "$(dirname "$CFG")"
jq -cn '{settingsPersistenceFormat:"profile-overrides-v1",settingsTabOrder:["weather","modules"],profiles:{Work:{settingsTabOrder:["modules","weather"]}},profileStorageFormat:"sparse-v1",activeProfile:"Work",profileOverrides:{},customThemes:{}}' > "$CFG"
payload=$(jq -cn '{settingsPersistenceFormat:"profile-overrides-v1",settingsSchemaVersion:1,weatherToken:"",profiles:{Work:{settingsNavigationOrder:{groupOrder:["appearance","modules","dashboard","launcher","general"],pagesByGroup:{appearance:["settingsWindow","themes"],modules:["weather","modules","timers","player","mopidy","cava","cpuRam","network","volume","calendar","notifications"],dashboard:["dashboard"],launcher:["launcher","launcherSearch","launcherTabs","launcherProjects","launcherActions","launcherAnimation","launcherApplications"],general:["general"]}}}},profileStorageFormat:"sparse-v1",activeProfile:"Work",customThemes:{},settingsNavigationCollapsedGroups:{appearance:false,modules:true,launcher:false},settingsLastActivePageId:"weather",profileOverrides:{settingsNavigationOrder:{pagesByGroup:{modules:["weather","modules","timers","player","mopidy","cava","cpuRam","network","volume","calendar","notifications"]}}},managedKeys:["settingsTabOrder","settingsNavigationOrder"],managedNestedKeys:{}}')
"$ROOT/scripts/settings" set-json-ui "$payload" '' >/dev/null
jq -e 'has("settingsTabOrder") == false and (.profiles.Work | has("settingsTabOrder") == false) and (.profileOverrides.settingsNavigationOrder.pagesByGroup.modules[0] == "weather")' "$CFG" >/dev/null || {
  echo 'settings writer failed to prune the obsolete flat root field or preserve hierarchical order' >&2
  exit 1
}
echo 'settings writer removes stale flat order and keeps hierarchical order: OK'
