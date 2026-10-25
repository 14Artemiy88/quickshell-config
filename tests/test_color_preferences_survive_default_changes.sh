#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
function load(file, extra = {}) {
  const source = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/mg, '');
  const context = {...extra};
  vm.createContext(context);
  vm.runInContext(source, context, {filename:file});
  return context;
}
const Profiles = load('js/settings/SettingsProfiles.js');
const Persistence = load('js/settings/SettingsPersistence.js', {Profiles});
const Themes = load('js/settings/SettingsThemes.js');
const Schema = load('js/settings/SettingsSchema.js');
const ApplyState = load('js/settings/SettingsApplyState.js', {Schema, Profiles, Themes});
const clone = value => JSON.parse(JSON.stringify(value));
const colorNames = ['settingsBackground', 'settingsBorder', 'playerProgressFill', 'topAppsRamBarColor'];
const oldColors = {
  settingsBackground: '#e6000000', settingsBorder: '#00cccc',
  playerProgressFill: '#ff12ab34', topAppsRamBarColor: '#ff3daee9'
};
const newDefaults = {...oldColors, settingsBackground:'#e6121212', settingsBorder:'#abcdef', playerProgressFill:'#ff00cccc', topAppsRamBarColor:'#ff00aaff'};
const makeDefaults = colors => ({activeTheme:'14 Theme', modules:{}, geometry:{}, colors:clone(colors)});

// Profile colors that matched the previous defaults must be explicit in the
// sparse profile so a later release changing defaults cannot rewrite them.
const oldDefaults = makeDefaults(oldColors);
const profile = {...clone(oldDefaults), colors:clone(oldColors)};
const profileOwner = {profileDefaults:clone(oldDefaults), colorNames, profileStorageFormat:'sparse-v1'};
const storedProfile = Profiles.sparseProfile(profileOwner, profile);
assert.deepStrictEqual(clone(storedProfile.colors), oldColors, 'saved profile pins every color');
const newerProfileOwner = {profileDefaults:makeDefaults(newDefaults), profileStorageFormat:'sparse-v1'};
const expandedProfile = Profiles.expandProfile(newerProfileOwner, storedProfile);
for (const key of colorNames) assert.strictEqual(expandedProfile.colors[key], oldColors[key], `profile preserves ${key} after default change`);

// With no active profile, all current colors are persisted as installation
// preferences, including values equal to the defaults at the time of saving.
const rootOwner = {
  profileDefaults:clone(oldDefaults), profileStorageFormat:'sparse-v1', profiles:{}, activeProfile:'',
  customThemes:{}, activeTheme:'14 Theme', weatherToken:'', colorNames, moduleNames:[],
  timerPresetDefaults:[], moduleFrames:{}, moduleBackgrounds:{}, moduleBlurEnabled:{}, moduleMonitors:{},
  geometry:{}, snapshotObject(){ return {...clone(oldDefaults), colors:clone(oldColors)}; }
};
const payload = Persistence.payloadObject(rootOwner, {});
assert.deepStrictEqual(clone(payload.profileOverrides.colors), oldColors, 'no-profile payload pins all colors');
const newerRootOwner = {profileDefaults:makeDefaults(newDefaults)};
const expanded = Profiles.expandStoredSettings(newerRootOwner, payload);
for (const key of colorNames) assert.strictEqual(expanded.colors[key], oldColors[key], `root settings preserve ${key} after default change`);

// Existing sparse profiles without a full color map are upgraded once and
// flagged for persistence, using their currently resolved colors as baseline.
const migrationOwner = {
  profileDefaults:makeDefaults(newDefaults), profiles:{Work:{fontSize:14}}, profileStorageFormat:'sparse-v1',
  activeProfile:'Work', customThemes:{}, activeTheme:'14 Theme', colorNames, moduleNames:[],
  defaultModuleBlurEnabled:{}, moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{}, geometry:{},
  settingsGeometry:[0,0,600,700], settingsMonitorName:'', profileList:[], profilesRevision:0,
  rebuildProfileList(){this.profileList=Object.keys(this.profiles||{}).sort();}, changed(){}
};
const config = {...newDefaults};
ApplyState.apply(migrationOwner, config, {
  profileStorageFormat:'sparse-v1', profiles:{Work:{fontSize:14}}, activeProfile:'Work', activeTheme:'14 Theme',
  colors:clone(newDefaults), modules:{}, moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{}, geometry:{}, customThemes:{}
}, [], {}, {}, colorNames);
assert.strictEqual(migrationOwner.profileMigrationPending, true, 'legacy sparse profiles trigger one-time color pinning');
for (const key of colorNames) assert.strictEqual(migrationOwner.profiles.Work.colors[key], newDefaults[key], `legacy profile pins ${key}`);
console.log('Color preferences survive default changes and legacy sparse-profile migration: OK');
JS
