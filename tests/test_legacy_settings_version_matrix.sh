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
const Schema = load('js/settings/SettingsSchema.js');
const Profiles = load('js/settings/SettingsProfiles.js');
const Themes = load('js/settings/SettingsThemes.js');
const LauncherProjects = load('js/settings/SettingsLauncherProjects.js');
const Defaults = load('js/settings/SettingsDefaults.js', {LauncherProjects});
const Metadata = load('js/settings/SettingsMetadata.js');
const Core = load('js/settings/SettingsApplyCore.js', {Schema});
const Behaviour = load('js/settings/SettingsApplyBehaviour.js');
const SystemVisual = load('js/settings/SettingsApplySystemVisual.js', {Schema, LauncherProjects});
const TimerPlayer = load('js/settings/SettingsApplyTimerPlayer.js');
const Weather = load('js/settings/SettingsApplyWeather.js');
const State = load('js/settings/SettingsApplyState.js', {Schema, Profiles, Themes});
const Apply = load('js/settings/SettingsApply.js', {Core, Behaviour, SystemVisual, TimerPlayer, Weather, State});

const currentDefaults = {
  font: 'Current Font', fontSize: 12,
  timerPresetDefaults: [5, 7, 15],
  timerIconOrder: 'alarm-left', timerIconX: 45, timerAlarmIconX: 8,
  timerFinishedImageMargin: 10,
  mopidyShowMoveUpIcon: true, mopidyShowMoveDownIcon: true, mopidyAlbumBold: true,
  launcherItemRadius: 11, launcherTitleY: 0, launcherTitleColor: '#ffffff',
  modules: {player:true, mopidy:true, topAppsCpu:true, topAppsRam:true},
  moduleFrames: {player:true, mopidy:true, topAppsCpu:true, topAppsRam:true},
  moduleBackgrounds: {player:true, mopidy:true, topAppsCpu:true, topAppsRam:true},
  moduleMonitors: {},
  geometry: {
    player:[10,20,300,180], mopidy:[330,865,300,150],
    topAppsCpu:[5,329,315,96], topAppsRam:[5,430,315,96]
  },
  colors: {accent:'#00cccc', text:'#ffffff'}, activeTheme:'14 Theme'
};
function createOwner() {
  return {
    profileDefaults: JSON.parse(JSON.stringify(currentDefaults)),
    profileStorageFormat: 'legacy', profileMigrationPending: false,
    profiles: {}, profileList: [], profilesRevision: 0, activeProfile: 'stale-before-load',
    timerPresetDefaults:[5,7,15], timerPresets:[5,7,15],
    moduleFrames:{player:true,mopidy:true,topAppsCpu:true,topAppsRam:true},
    moduleBackgrounds:{player:true,mopidy:true,topAppsCpu:true,topAppsRam:true},
    moduleMonitors:{}, geometry: JSON.parse(JSON.stringify(currentDefaults.geometry)),
    settingsGeometry:[0,0,600,800], settingsMonitorName:'',
    customThemes:{}, activeTheme:'14 Theme',
    themeStateRevision:0, loaded:false, weatherToken:'', profileMigrationPending:false,
    rebuildProfileList() { this.profileList = Object.keys(this.profiles || {}).sort(); this.profilesRevision++; },
    changed() {}
  };
}

// v839-era full profile: old timer preset alias, missing icon-order field,
// combined Top Apps geometry/modules, old Mopidy move toggle, and pre-v408
// default Mopidy coordinates. The same old geometry also appears at root level.
const v839Profile = {
  font:'Legacy v839 Font', fontSize:16,
  timerPresets:[2, 9, 21], timerIconX:67, timerAlarmIconX:12,
  timerFinishedImageTopMargin:23, mopidyShowMoveButtons:false,
  playerControlIconSize:22,
  modules:{topApps:false, player:false},
  moduleFrames:{topApps:false, player:false},
  moduleBackgrounds:{topApps:false, player:false},
  moduleMonitors:{topApps:'Legacy-Monitor'},
  geometry:{topApps:[12,20,301,198], mopidy:[330,730,300,150], player:[111,122,333,188]},
  colors:{accent:'#AABBCC', text:'#fefefe'}, activeTheme:'14 Theme'
};
const owner = createOwner();
const Config = Object.assign({}, Themes.palette('14 Theme', {}), JSON.parse(JSON.stringify(Defaults.defaultConfig)));
const legacyRootSnapshot = {
  modules:{topApps:false, player:true},
  moduleFrames:{topApps:false, player:true},
  moduleBackgrounds:{topApps:false, player:true},
  moduleMonitors:{topApps:'Legacy-Monitor'},
  geometry:{topApps:[12,20,301,198], mopidy:[330,730,300,150]},
  timerPresets:[3, 8, 14], timerIconX:67, timerAlarmIconX:12, timerFinishedImageTopMargin:19,
  profiles:{'Legacy v839':v839Profile, 'Removed Profile':null},
  activeProfile:'Removed Profile', colors:{accent:'#AABBCC', text:'#fefefe'}, activeTheme:'14 Theme'
};
const vmSnapshot = vm.runInContext('JSON.parse(' + JSON.stringify(JSON.stringify(legacyRootSnapshot)) + ')', State);
Apply.applyObject(owner, Config, vmSnapshot, Metadata.moduleNames, Metadata.defaultModuleFrames, Metadata.defaultModuleBackgrounds, Metadata.colorNames);

assert.strictEqual(owner.activeProfile, '', 'stale activeProfile is cleared after invalid profile entries are filtered');
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.geometry.topAppsCpu)), [12,20,301,96], 'legacy root Top Apps geometry is split');
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.geometry.topAppsRam)), [12,121,301,96], 'legacy root Top Apps geometry is split into RAM geometry');
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.geometry.mopidy)), [330,865,300,150], 'legacy root Mopidy default is migrated');
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.timerPresetDefaults)), [3,8,14], 'legacy root timerPresets alias is migrated');
assert.strictEqual(Config.timerFinishedImageMargin, 19, 'legacy root timer margin alias is migrated');
assert.strictEqual(Config.timerIconX, 12, 'legacy root timer icon position migration still applies');
assert.strictEqual(Config.timerAlarmIconX, 67, 'legacy root timer icon position migration still applies');

const expanded = Profiles.expandedProfileByName(owner, 'Legacy v839');
assert(expanded, 'legacy full profile survives migration');
assert.strictEqual(expanded.font, 'Legacy v839 Font', 'explicit legacy value survives');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.timerPresetDefaults)), [2,9,21], 'profile timerPresets alias is migrated before defaults fill missing keys');
assert.strictEqual(expanded.timerIconOrder, 'alarm-left', 'legacy full profile receives current timer icon order');
assert.strictEqual(expanded.timerIconX, 12, 'legacy profile timer icon x positions are migrated');
assert.strictEqual(expanded.timerAlarmIconX, 67, 'legacy profile alarm icon x positions are migrated');
assert.strictEqual(expanded.timerFinishedImageMargin, 23, 'legacy profile finished-image margin is migrated');
assert.strictEqual(expanded.mopidyShowMoveUpIcon, false, 'legacy Mopidy move toggle maps to up icon');
assert.strictEqual(expanded.mopidyShowMoveDownIcon, false, 'legacy Mopidy move toggle maps to down icon');
assert.strictEqual(Object.prototype.hasOwnProperty.call(expanded, 'timerPresets'), false, 'old timer alias is removed from expanded profile');
assert.strictEqual(Object.prototype.hasOwnProperty.call(expanded, 'mopidyShowMoveButtons'), false, 'old Mopidy alias is removed from expanded profile');
assert.strictEqual(Object.prototype.hasOwnProperty.call(expanded, 'playerControlIconSize'), false, 'obsolete shared Player icon size is removed');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.geometry.mopidy)), [330,865,300,150], 'legacy profile Mopidy default receives same migration as root geometry');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.geometry.topAppsCpu)), [12,20,301,96], 'legacy profile Top Apps geometry is split');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.geometry.topAppsRam)), [12,121,301,96], 'legacy profile Top Apps geometry is split');
assert.strictEqual(expanded.modules.topAppsCpu, false, 'legacy Top Apps toggle maps to CPU');
assert.strictEqual(expanded.modules.topAppsRam, false, 'legacy Top Apps toggle maps to RAM');

// v841-era full profiles already carry explicit launcher appearance settings
// and an icon-order choice; those values must survive without legacy swaps.
const v841 = Schema.normalizeProfile({
  launcherItemRadius:18, launcherTitleY:-12, launcherTitleColor:'#abcdef',
  timerIconOrder:'timer-left', timerIconX:72, timerAlarmIconX:14,
  geometry:{mopidy:[330,865,300,150]}, timerPresetDefaults:[4,10,25]
}, false);
assert.strictEqual(v841.launcherItemRadius,18);
assert.strictEqual(v841.launcherTitleY,-12);
assert.strictEqual(v841.launcherTitleColor,'#abcdef');
assert.strictEqual(v841.timerIconX,72, 'explicit modern icon order prevents legacy position swap');
assert.strictEqual(v841.timerAlarmIconX,14, 'explicit modern alarm position remains intact');
assert.deepStrictEqual(JSON.parse(JSON.stringify(v841.geometry.mopidy)), [330,865,300,150]);

// v849+ sparse profiles are already in the current layout dialect: preserve
// explicit coordinates that happen to match the former Mopidy default.
const sparse = Schema.normalizeProfile({
  timerPresets:[6, 12],
  timerIconX:72, timerAlarmIconX:14,
  geometry:{mopidy:[330,730,300,150]}
}, true);
assert.deepStrictEqual(JSON.parse(JSON.stringify(sparse.timerPresetDefaults)), [6,12]);
assert.strictEqual(sparse.timerIconX,72, 'sparse profiles do not receive full-snapshot legacy icon swap');
assert.strictEqual(sparse.timerIconOrder, undefined, 'sparse missing order remains inherited from current defaults');
assert.deepStrictEqual(JSON.parse(JSON.stringify(sparse.geometry.mopidy)), [330,730,300,150], 'sparse explicit Mopidy geometry is not migrated as a default');

console.log('legacy settings version migration matrix: OK');
JS
