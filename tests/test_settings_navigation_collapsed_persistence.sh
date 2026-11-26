#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplyCore.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
SETTINGS="$ROOT/Settings.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"

grep -Fq 'property var settingsNavigationCollapsedGroups: ({ appearance: false, modules: false, launcher: false, notifications: false })' "$CONFIG"
grep -Fq 'settingsNavigationCollapsedGroups: ({ appearance: false, modules: false, launcher: false, notifications: false })' "$DEFAULTS"
grep -Fq 'readonly property var collapsedSettingsNavigationGroups: Config.settingsNavigationCollapsedGroups' "$WIDGET"
grep -Fq 'root.settings.save()' "$WIDGET"
# Expansion state is persisted globally, not treated as a profile edit.
grep -Fq 'settingsNavigationCollapsedGroups: cloneValue(config.settingsNavigationCollapsedGroups' "$PERSIST"
grep -Fq 'settingsNavigationCollapsedGroups' "$PERSIST"
grep -Fq 'Schema.normalizeSettingsNavigationCollapsedGroups(' "$APPLY"
if grep -Fq 'settingsNavigationCollapsedGroups' "$SETTINGS"; then
  echo 'Navigation expansion still participates in Settings.qml Save/Reset scope detection' >&2
  exit 1
fi
if grep -Fq 'settingsNavigationCollapsedGroups' "$RESETS"; then
  echo 'Settings-window reset still owns navigation expansion state' >&2
  exit 1
fi

node - "$SCHEMA" "$PERSIST" "$APPLY" "$PROFILES" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
function load(path) {
  const source = fs.readFileSync(path, 'utf8').replace(/^\.pragma library\s*/, '');
  const sandbox = {};
  vm.runInNewContext(source, sandbox, { filename: path });
  return sandbox;
}
const schema = load(process.argv[2]);
const normalize = schema.normalizeSettingsNavigationCollapsedGroups;
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize({}, { appearance: true, modules: false, launcher: true, notifications: false }))), {
  appearance: true, modules: false, launcher: true, notifications: false
}, 'partial input preserves the current group state');
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize({ appearance: false, modules: true, launcher: true, stale: true }, {}))), {
  appearance: false, modules: true, launcher: true, notifications: false
}, 'unknown group IDs are discarded');
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize({ appearance: 'yes', modules: 1, launcher: 'yes' }, {}))), {
  appearance: false, modules: false, launcher: false, notifications: false
}, 'non-boolean values fall back to expanded');

const persistence = load(process.argv[3]);
const config = { settingsNavigationCollapsedGroups: { appearance: true, modules: false, launcher: true, notifications: false } };
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, config);
assert.strictEqual(Object.prototype.hasOwnProperty.call(snapshot, 'settingsNavigationCollapsedGroups'), false,
  'navigation expansion is excluded from the profile snapshot');
const owner = {
  moduleNames: [], colorNames: [], weatherToken: '', activeProfile: 'Default',
  profiles: { Default: {} }, profileDefaults: { fontSize: 12 }, customThemes: {},
  snapshotObject: () => ({ fontSize: 12, settingsNavigationCollapsedGroups: { appearance: true, modules: false, launcher: true, notifications: false } }),
  expandedProfileData: () => ({ fontSize: 12 })
};
const payload = persistence.payloadObject(owner, config);
assert.deepStrictEqual(JSON.parse(JSON.stringify(payload.settingsNavigationCollapsedGroups)), {
  appearance: true, modules: false, launcher: true, notifications: false
}, 'navigation expansion persists as a root settings.json preference');
assert.strictEqual(Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsNavigationCollapsedGroups'), false,
  'navigation expansion never enters sparse profile overrides');
assert(payload.managedKeys.includes('settingsNavigationCollapsedGroups'),
  'legacy root value is managed and replaced with the current standalone preference');

const applySource = fs.readFileSync(process.argv[4], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const applySandbox = { Schema: schema };
vm.runInNewContext(applySource, applySandbox, { filename: process.argv[4] });
const restored = { settingsNavigationCollapsedGroups: { appearance: false, modules: false, launcher: false, notifications: false } };
applySandbox.apply({}, restored, { settingsNavigationCollapsedGroups: { appearance: true, modules: true, launcher: true, stale: true } });
assert.deepStrictEqual(JSON.parse(JSON.stringify(restored.settingsNavigationCollapsedGroups)), {
  appearance: true, modules: true, launcher: true, notifications: false
}, 'standalone UI state restores through the existing schema normalizer');

const profiles = load(process.argv[5]);
assert.strictEqual(profiles.profileSavePathMatches({}, 'settingsWindow', null, ['settingsNavigationCollapsedGroups', 'modules']), false,
  'navigation expansion is excluded from settings-window scoped profile saves');
const profileOwner = {
  profileDefaults: { fontSize: 12 }, colorNames: [], resetOverrides: {}, profileMigrationPending: false,
  defaultConfig: { settingsNavigationCollapsedGroups: { appearance: false, modules: false, launcher: false, notifications: false } }
};
const migrated = profiles.expandStoredSettings(profileOwner, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1', activeProfile: 'Default', customThemes: {},
  profiles: { Default: { fontSize: 14, settingsNavigationCollapsedGroups: { appearance: false, modules: true, launcher: false, notifications: false } } },
  profileOverrides: { settingsNavigationCollapsedGroups: { appearance: true, modules: false, launcher: true, notifications: false } }
});
assert.deepStrictEqual(JSON.parse(JSON.stringify(migrated.settingsNavigationCollapsedGroups)), {
  appearance: true, modules: false, launcher: true, notifications: false
}, 'migration preserves the most recently persisted legacy expansion state');
assert.strictEqual(Object.prototype.hasOwnProperty.call(migrated.profiles.Default, 'settingsNavigationCollapsedGroups'), false,
  'migration strips navigation expansion from existing saved profiles');
assert.strictEqual(profileOwner.profileMigrationPending, true,
  'legacy profile-scoped navigation state schedules a one-time settings migration write');
assert.strictEqual(Object.prototype.hasOwnProperty.call(profileOwner.resetOverrides, 'settingsNavigationCollapsedGroups'), false,
  'cached reset-button state is reconciled before the Settings window is shown');

const rootWins = profiles.expandStoredSettings(profileOwner, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1', activeProfile: 'Default', customThemes: {},
  settingsNavigationCollapsedGroups: { appearance: false, modules: true, launcher: false, notifications: false },
  profiles: { Default: { settingsNavigationCollapsedGroups: { appearance: true, modules: false, launcher: true, notifications: false } } },
  profileOverrides: { settingsNavigationCollapsedGroups: { appearance: true, modules: false, launcher: true, notifications: false } }
});
assert.deepStrictEqual(JSON.parse(JSON.stringify(rootWins.settingsNavigationCollapsedGroups)), {
  appearance: false, modules: true, launcher: false, notifications: false
}, 'standalone root state takes precedence after migration');

const profileOnly = profiles.expandStoredSettings(profileOwner, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1', activeProfile: 'Default', customThemes: {},
  profiles: { Default: { fontSize: 14, settingsNavigationCollapsedGroups: { appearance: false, modules: true, launcher: true, notifications: false } } },
  profileOverrides: {}
});
assert.deepStrictEqual(JSON.parse(JSON.stringify(profileOnly.settingsNavigationCollapsedGroups)), {
  appearance: false, modules: true, launcher: true, notifications: false
}, 'legacy state in the active sparse profile is recovered when no newer override exists');
assert.strictEqual(Object.prototype.hasOwnProperty.call(profileOnly.profiles.Default, 'settingsNavigationCollapsedGroups'), false,
  'state recovered from the legacy profile is then removed from that profile');

const fullLegacy = profiles.expandStoredSettings(profileOwner, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
  profileStorageFormat: 'legacy-full', activeProfile: 'Default', customThemes: {},
  profiles: { Default: { fontSize: 13, settingsNavigationCollapsedGroups: { appearance: true, modules: true, launcher: false, notifications: false } } },
  profileOverrides: {}
});
assert.deepStrictEqual(JSON.parse(JSON.stringify(fullLegacy.settingsNavigationCollapsedGroups)), {
  appearance: true, modules: true, launcher: false, notifications: false
}, 'legacy full-snapshot profile state is recovered before profile migration');
assert.strictEqual(Object.prototype.hasOwnProperty.call(fullLegacy.profiles.Default, 'settingsNavigationCollapsedGroups'), false,
  'legacy full profile is migrated without navigation UI state');
console.log('settings navigation expansion: standalone persistence, sparse-profile exclusion and legacy migration: OK');
NODE

# Exercise the real settings writer: the standalone preference must survive
# the managed-key pruning/merge path without becoming a profile override.
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
payload=$(jq -cn '{
  settingsPersistenceFormat:"profile-overrides-v1",settingsSchemaVersion:1,
  weatherToken:"",profiles:{Default:{}},profileStorageFormat:"sparse-v1",
  activeProfile:"Default",customThemes:{},
  settingsNavigationCollapsedGroups:{appearance:true,modules:false,launcher:true},
  profileOverrides:{},managedKeys:["settingsNavigationCollapsedGroups"],managedNestedKeys:{}
}')
"$ROOT/scripts/settings" set-json-ui "$payload" '' >/dev/null
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
jq -e '.settingsNavigationCollapsedGroups == {appearance:true,modules:false,launcher:true} and .profileOverrides == {}' "$CFG" >/dev/null || {
  echo 'settings writer did not retain standalone navigation state outside profile overrides' >&2
  exit 1
}
echo 'settings navigation collapsed-state persistence: OK'
