#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
function load(file) {
  const source = fs.readFileSync(path.join(root, file), 'utf8').replace(/^\.pragma library\s*/m, '');
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context, {filename:file});
  return context;
}
const Profiles = load('js/settings/SettingsProfiles.js');
const Persistence = load('js/settings/SettingsPersistence.js');
const settingsQml = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
assert(settingsQml.includes('SettingsProfiles.expandStoredSettings(root, diskObject)'), 'startup must expand compact profile overlays before applying settings');
assert(settingsQml.includes('storageFormatNeedsMigration'), 'legacy flat snapshots must be marked for compact-format migration');
assert(settingsQml.includes('schemaNeedsMigration'), 'old compact settings must be marked for schema migration');
assert(Persistence.SETTINGS_SCHEMA_VERSION === 1, 'settings schema version should be exposed to the loader');
const clone = value => JSON.parse(JSON.stringify(value));
const defaults = {
  font:'JetBrainsMono Nerd Font', fontSize:12, activeTheme:'14 Theme',
  modules:{time:true,calendar:true}, geometry:{time:[1,2,300,60]},
  colors:{accent:'#00cccc',text:'#ffffff'}
};
const savedWork = {...clone(defaults), fontSize:15, modules:{time:true,calendar:false}, geometry:{time:[20,30,300,60]}};
const current = {...clone(savedWork), fontSize:17, modules:{time:false,calendar:false}, weatherToken:'global-token'};
const owner = {
  profileDefaults:clone(defaults), profileStorageFormat:'sparse-v1',
  profiles:{}, activeProfile:'Work', customThemes:{Custom:{accent:'#abcdef'}},
  activeTheme:current.activeTheme, weatherToken:'global-token',
  moduleNames:['time','calendar'], colorNames:['accent','text'], timerPresetDefaults:[],
  moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{}, geometry:current.geometry,
  snapshotObject(){return clone(current)},
  expandedProfileData(name){return Profiles.expandedProfileByName(this,name)},
  save(){}, rebuildProfileList(){}, applyObject(value){this.applied=clone(value)}
};
owner.profiles.Work = Profiles.sparseProfile(owner, savedWork);
const payload = Persistence.payloadObject(owner, {});
assert.strictEqual(payload.settingsPersistenceFormat, 'profile-overrides-v1');
assert.strictEqual(payload.settingsSchemaVersion, 1, 'settings schema version must persist to disk');
assert.strictEqual(payload.activeProfile, 'Work');
assert.strictEqual(payload.weatherToken, 'global-token', 'credentials remain installation-global');
assert.strictEqual(payload.fontSize, undefined, 'effective setting must not remain duplicated at root');
assert.strictEqual(payload.modules, undefined, 'module flags must not remain duplicated at root');
assert.strictEqual(payload.geometry, undefined, 'geometry must not remain duplicated at root');
assert.strictEqual(payload.profileOverrides.fontSize, 17, 'only the value different from the active profile should be stored as an override');
assert.strictEqual(payload.profileOverrides.modules.time, false, 'nested differences should be sparse too');
assert.strictEqual(payload.profileOverrides.modules.calendar, undefined, 'matching nested values should not be duplicated');
const expanded = Profiles.expandStoredSettings(owner, payload);
assert.strictEqual(expanded.fontSize, 17, 'compact storage must restore the full effective state');
assert.strictEqual(expanded.modules.time, false, 'compact storage must restore nested overrides');
assert.strictEqual(expanded.modules.calendar, false, 'profile values must remain inherited when not overridden');
assert.strictEqual(expanded.geometry.time[0], 20, 'matching profile geometry must be inherited');
assert.strictEqual(expanded.weatherToken, 'global-token');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.customThemes)), owner.customThemes, 'custom theme catalog remains global');

// Saving current effective values as the active profile should remove all
// profile-managed overrides, leaving only globally scoped data in the file.
assert.strictEqual(Profiles.saveProfile(owner, 'Current'), true);
const savedPayload = Persistence.payloadObject(owner, {});
assert.deepStrictEqual(JSON.parse(JSON.stringify(savedPayload.profileOverrides)), {}, 'saving into a profile must clear redundant overrides');
assert.strictEqual(savedPayload.weatherToken, 'global-token');
console.log('profile overlay storage format and active-profile source of truth: OK');
JS
