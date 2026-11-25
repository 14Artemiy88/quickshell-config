#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
CORE="$ROOT/js/settings/SettingsApplyCore.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"

node - "$CONFIG" "$CORE" "$PERSIST" "$CONTROLLER" "$WIDGET" "$REGISTRY" "$PROFILES" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [configPath, corePath, persistPath, controllerPath, widgetPath, registryPath, profilesPath] = process.argv.slice(2);
const read = path => fs.readFileSync(path, 'utf8');
const configSource = read(configPath);
const coreSource = read(corePath).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
const persistSource = read(persistPath).replace(/^\.pragma library\s*$/gm, '');
const controllerSource = read(controllerPath);
const widgetSource = read(widgetPath);
const registrySource = read(registryPath).replace(/^\.pragma library\s*$/gm, '');

assert(configSource.includes('property string settingsLastActivePageId: "general"'), 'first-run fallback is General');
assert(controllerSource.includes('property string currentPageId: "general"'), 'controller fallback is General');

const core = {};
vm.runInNewContext(coreSource, core, { filename: corePath });
assert.strictEqual(core.normalizeSettingsLastActivePageId('weather'), 'weather', 'known active page is retained');
assert.strictEqual(core.normalizeSettingsLastActivePageId('  player  '), 'player', 'saved page is trimmed');
assert.strictEqual(core.normalizeSettingsLastActivePageId('not-a-page'), 'general', 'unknown page falls back to General');
assert.strictEqual(core.normalizeSettingsLastActivePageId({ id: 'weather' }), 'general', 'malformed non-string page falls back to General');
const appliedConfig = { settingsLastActivePageId: 'general' };
core.apply({}, appliedConfig, { settingsLastActivePageId: 'weather' });
assert.strictEqual(appliedConfig.settingsLastActivePageId, 'weather', 'settings apply restores the root page preference');
core.apply({}, appliedConfig, { settingsLastActivePageId: 'removed-page' });
assert.strictEqual(appliedConfig.settingsLastActivePageId, 'general', 'settings apply normalizes removed page IDs');

const registry = {};
vm.runInNewContext(registrySource, registry, { filename: registryPath });
function functionBody(source, name) {
  const token = `function ${name}(`;
  const start = source.indexOf(token);
  assert(start >= 0, `missing ${name}()`);
  const open = source.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}' && --depth === 0) return source.slice(open + 1, i);
  }
  throw new Error(`unterminated ${name}()`);
}
const restore = new Function('root', 'Config', 'SettingsPageRegistry', functionBody(widgetSource, 'restoreSettingsLastActivePage'));
const persist = new Function('root', 'Config', 'SettingsPageRegistry', functionBody(widgetSource, 'persistCurrentSettingsPage'));

let saves = 0;
const Config = { settingsLastActivePageId: 'weather' };
const collapsed = { appearance: true, modules: true, launcher: false };
const root = {
  settings: { loaded: true, save() { saves++; } },
  settingsNavigationReady: false,
  currentPageId: 'general',
  currentPageSubTabIndex: 4,
  collapsedSettingsNavigationGroups: collapsed,
  expandCalls: [],
  expandSettingsNavigationGroupForPage(id) { this.expandCalls.push(id); }
};
assert.strictEqual(restore(root, Config, registry), true, 'restore succeeds once Settings is loaded');
assert.strictEqual(root.currentPageId, 'weather', 'last active page is restored');
assert.strictEqual(root.currentPageSubTabIndex, 0, 'subtab index resets to a safe first subtab');
assert.strictEqual(root.settingsNavigationReady, true, 'navigation is enabled after restore');
assert.deepStrictEqual(root.collapsedSettingsNavigationGroups, collapsed, 'restore leaves independently saved folder states untouched');
assert.deepStrictEqual(root.expandCalls, [], 'restore must not auto-expand the active page folder');
assert.strictEqual(saves, 0, 'valid saved page does not cause a startup rewrite');

const invalidConfig = { settingsLastActivePageId: 'deleted-page' };
const invalidRoot = {
  settings: { loaded: true, save() { saves++; } }, settingsNavigationReady: false,
  currentPageId: 'weather', currentPageSubTabIndex: 3,
  expandSettingsNavigationGroupForPage() { throw new Error('restore must not expand folders'); }
};
restore(invalidRoot, invalidConfig, registry);
assert.strictEqual(invalidRoot.currentPageId, 'general', 'removed page falls back to General');
assert.strictEqual(invalidConfig.settingsLastActivePageId, 'general', 'invalid root preference is repaired');
assert.strictEqual(saves, 1, 'repaired page preference is persisted once');

// A later user selection persists the new page and only expands its destination group.
Config.settingsLastActivePageId = 'weather';
root.currentPageId = 'player';
root.settingsNavigationReady = true;
persist(root, Config, registry);
assert.strictEqual(Config.settingsLastActivePageId, 'player', 'explicit page selection updates Config');
assert.deepStrictEqual(root.expandCalls, ['player'], 'explicit selection may reveal its parent group');
assert.strictEqual(saves, 2, 'explicit page change is persisted');
persist(root, Config, registry);
assert.strictEqual(saves, 2, 'same active page does not trigger redundant writes');
root.currentPageId = 'invalid-page';
persist(root, Config, registry);
assert.strictEqual(Config.settingsLastActivePageId, 'player', 'invalid runtime page IDs are never persisted');

// The UI preference is written at the root of settings.json and removed from profile snapshots/diffs.
const persistence = {};
vm.runInNewContext(persistSource, persistence, { filename: persistPath });
const config = { settingsLastActivePageId: 'weather', settingsNavigationCollapsedGroups: { appearance: true, modules: true, launcher: false } };
const owner = {
  moduleNames: [], colorNames: [], weatherToken: '', activeProfile: 'Default',
  profiles: { Default: { fontSize: 12 } }, profileDefaults: { fontSize: 12, settingsLastActivePageId: 'general' },
  customThemes: {}, profileStorageFormat: 'sparse-v1',
  snapshotObject: () => ({ fontSize: 12, settingsLastActivePageId: 'weather', settingsNavigationCollapsedGroups: { appearance: true } }),
  expandedProfileData: () => ({ fontSize: 12, settingsLastActivePageId: 'general' })
};
const payload = persistence.payloadObject(owner, config);
const profiles = {};
vm.runInNewContext(read(profilesPath).replace(/^\.pragma library\s*$/gm, ''), profiles, { filename: profilesPath });
const expanded = profiles.expandStoredSettings({ profileDefaults: { fontSize: 12 }, profileMigrationPending: false }, {
  settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1', activeProfile: 'Default', profiles: { Default: { fontSize: 12 } },
  profileOverrides: {}, customThemes: {}, settingsNavigationCollapsedGroups: { appearance: true, modules: true, launcher: false },
  settingsLastActivePageId: 'weather'
});
assert.strictEqual(expanded.settingsLastActivePageId, 'weather', 'stored root last-page preference survives sparse-profile expansion');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.settingsNavigationCollapsedGroups)),
  { appearance: true, modules: true, launcher: false }, 'collapsed groups restore independently beside the active page');
assert.strictEqual(payload.settingsLastActivePageId, 'weather', 'active page is persisted at settings.json root');
assert(payload.managedKeys.includes('settingsLastActivePageId'), 'active page root key is managed by writer');
assert.strictEqual(Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsLastActivePageId'), false,
  'active page never enters sparse profile overrides');
assert.strictEqual(Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsNavigationCollapsedGroups'), false,
  'folder state remains outside sparse profile overrides');
assert.strictEqual(Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsLastActivePageId'), false,
  'active page does not become an ordinary profile diff');

assert(widgetSource.includes('root.restoreSettingsLastActivePage()'), 'widget invokes restoration on completion and after settings load');
assert(widgetSource.includes('function onLoadedChanged()'), 'late Settings load is handled');
assert(widgetSource.includes('onCurrentPageIdChanged: root.persistCurrentSettingsPage()'), 'page changes persist through one handler');
const settingsSource = read(require('path').join(require('path').dirname(configPath), 'Settings.qml'));
assert(!settingsSource.includes('settingsLastActivePageId'), 'last page is not part of Settings profile Save/Reset scope detection');
console.log('settings last active page: restore, invalid fallback, collapsed-folder independence, profile exclusion and root persistence: OK');
NODE

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
  activeProfile:"Default",customThemes:{},settingsNavigationCollapsedGroups:{appearance:true,modules:false,launcher:true},
  settingsLastActivePageId:"weather",profileOverrides:{},
  managedKeys:["settingsNavigationCollapsedGroups","settingsLastActivePageId"],managedNestedKeys:{}
}')
"$ROOT/scripts/settings" set-json-ui "$payload" '' >/dev/null
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
jq -e '.settingsLastActivePageId == "weather" and .settingsNavigationCollapsedGroups == {appearance:true,modules:false,launcher:true} and .profileOverrides == {}' "$CFG" >/dev/null || {
  echo 'settings writer did not preserve active page and collapsed groups as root UI state' >&2
  exit 1
}
echo 'settings active-page writer persistence: OK'

