#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsProfiles.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '');
const ctx = {};
vm.runInNewContext(source + '\nthis.api = { sparseProfile, expandedProfileByName, saveProfileScope, saveProfile };', ctx, {filename:'SettingsProfiles.js'});
const api = ctx.api;
const persistenceSource = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '');
const persistenceContext = {};
vm.runInNewContext(persistenceSource + '\nthis.api = { payloadObject };', persistenceContext, {filename:'SettingsPersistence.js'});
const persistence = persistenceContext.api;
const clone = v => JSON.parse(JSON.stringify(v));
const defaults = {
  font:'Nerd Font', fontSize:12, ledFont:'Nerd Font', frameBorderWidth:1, frameRadius:6, backgroundBlurRadius:8,
  activeTheme:'Default', playerFont:'Nerd Font', playerSilenceText:'Silence',
  colors:{accent:'#00aaaa', text:'#ffffff', settingsBackground:'#222222', settingsBorder:'#555555', baseColor:'#444444'},
  timerWheelStep:1, timerRowSpacing:4, animationTimerVisibilityStyle:'fade', animationTimerOptionsVisibilityStyle:'fade', timerPresetDefaults:[5,7,15],
  weatherNowIntervalMinutes:30, weatherIconSize:30, weatherRetryDelayMinutes:5, weatherToken:'installation-only',
  launcherWidth:720, launcherHeight:640,
  modules:{time:true, calendar:true, player:true, launcher:true},
  moduleFrames:{time:true, calendar:true, player:true, launcher:true},
  moduleBackgrounds:{time:true, calendar:true, player:true, launcher:true},
  moduleBlurEnabled:{time:false, calendar:false, player:false, launcher:false, settings:false},
  moduleMonitors:{}, geometry:{time:[1,2,300,60], calendar:[3,4,300,200], player:[5,6,300,200], launcher:[7,8,720,640]},
  settingsGeometry:[10,20,560,800], settingsMonitorName:'DP-1', settingsFont:'Nerd Font', settingsFontSize:11,
  settingsPadding:8, settingsSpacing:6, settingsTabOrder:['modules','themes','general'], settingsTabLabels:{modules:'Modules'},
  animationSettingsVisibilityStyle:'fade'
};
let current = clone(defaults);
const owner = {
  profileDefaults: clone(defaults), profileStorageFormat:'sparse-v1', profiles:{}, activeProfile:'Work',
  profileList:[], profilesRevision:0, colorNames:Object.keys(defaults.colors),
  snapshotObject(){ return clone(current); },
  expandedProfileData(name){ return api.expandedProfileByName(this, name); },
  save(){ this.saveCount=(this.saveCount||0)+1; },
  rebuildProfileList(){ this.profileList=Object.keys(this.profiles).sort(); this.profilesRevision++; }
};
owner.profiles.Work = api.sparseProfile(owner, clone(defaults));
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'weather'), false, 'save action is a no-op when this section has no changes');

// Saving Weather must preserve an unrelated unsaved Timer change.
current.weatherIconSize = 42;
current.timerRowSpacing = 9;
current.weatherToken = 'new-global-token';
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'weather'), true);
let saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.weatherIconSize, 42, 'scoped save captures changed weather setting');
assert.strictEqual(saved.timerRowSpacing, defaults.timerRowSpacing, 'scoped save must preserve the unsaved timer baseline');
assert.strictEqual(current.timerRowSpacing, 9, 'scoped save must not alter live unrelated settings');
assert.strictEqual(saved.weatherToken, undefined, 'installation token must never be written into a profile');
assert.strictEqual(owner.resetOverrides.weatherIconSize, undefined, 'successfully saved scope disappears from the reset/save-change cache');
assert.strictEqual(owner.resetOverrides.timerRowSpacing, 9, 'unrelated unsaved scope remains in the reset/save-change cache');
const firstPayload = persistence.payloadObject(owner, {});
assert.deepStrictEqual(clone(firstPayload.profileOverrides), clone(owner.resetOverrides), 'cached visibility state matches the exact payload that would be written to settings.json');

// A Timer save then captures timer changes and timer preset defaults only.
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'timer'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.timerRowSpacing, 9);
assert.strictEqual(saved.weatherIconSize, 42, 'saving timer cannot revert or change saved weather');

// General and Launcher sections save their own key ranges without absorbing player edits.
current.fontSize = 14;
current.playerFont = 'Custom Player Font';
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'general'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.fontSize, 14);
assert.strictEqual(saved.playerFont, defaults.playerFont, 'general save must leave unsaved player options alone');
current.launcherWidth = 810;
current.moduleBlurEnabled.launcher = true;
current.geometry.launcher = [44,55,810,640];
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'launcher'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.launcherWidth, 810);
assert.deepStrictEqual(Array.from(saved.geometry.launcher), [44,55,810,640]);
assert.strictEqual(saved.moduleBlurEnabled.launcher, true);
assert.strictEqual(saved.playerFont, defaults.playerFont, 'launcher save must leave unsaved player options alone');

// A color group save must not commit a separate unsaved color group or theme identity.
current.colors.accent = '#123456';
current.colors.text = '#eeeeee';
current.activeTheme = 'Changed Theme';
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'colors', ['accent']), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.colors.accent, '#123456');
assert.strictEqual(saved.colors.text, defaults.colors.text, 'one color group does not save colors outside the requested list');
assert.strictEqual(saved.activeTheme, defaults.activeTheme, 'a color-group save does not silently change selected theme');

// Saving the entire theme commits identity and every changed palette color.
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'themes'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.colors.text, '#eeeeee');
assert.strictEqual(saved.activeTheme, 'Changed Theme');

// Module-row saving is precise, including the module geometry and maps, but not Settings blur.
current.geometry.player = [50, 60, 300, 200];
current.moduleFrames.player = false;
current.moduleBlurEnabled.settings = true;
current.moduleBlurEnabled.player = true;
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'module', 'player'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.deepStrictEqual(Array.from(saved.geometry.player), [50,60,300,200]);
assert.strictEqual(saved.moduleFrames.player, false);
assert.strictEqual(saved.moduleBlurEnabled.player, true);
assert.strictEqual(saved.moduleBlurEnabled.settings, false, 'module save does not capture Settings-window blur');

// Timer widget-row Save only commits timer module options; the separate animation-tab Save owns animation settings.
current.timerRowSpacing = 11;
current.animationTimerVisibilityStyle = 'slideLeft';
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'module', 'timer'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.timerRowSpacing, 11);
assert.strictEqual(saved.animationTimerVisibilityStyle, defaults.animationTimerVisibilityStyle, 'timer module save must not swallow independent animation-section edits');
assert.strictEqual(owner.resetOverrides.animationTimerVisibilityStyle, 'slideLeft', 'the independent animation edit remains unsaved and visible');
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'timer'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.animationTimerVisibilityStyle, 'slideLeft', 'Timer settings section can then save the animation change explicitly');

// Saving module layout includes module geometry, while preserving detailed widget settings.
current.geometry.calendar = [31, 41, 300, 200];
current.weatherIconSize = 48;
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'modules'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.deepStrictEqual(Array.from(saved.geometry.calendar), [31,41,300,200]);
assert.strictEqual(saved.weatherIconSize, 42, 'module-layout save cannot save other widget settings');

// Settings-window scoped save includes the nested window colors and its blur flag only.
current.colors.settingsBackground = '#333333';
current.colors.settingsBorder = '#777777';
current.colors.accent = '#abcdef';
current.settingsGeometry = [100, 120, 600, 850];
current.moduleBlurEnabled.settings = true;
assert.strictEqual(api.saveProfileScope(owner, 'Work', 'settingsWindow'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.colors.settingsBackground, '#333333');
assert.strictEqual(saved.colors.settingsBorder, '#777777');
assert.strictEqual(saved.colors.accent, '#123456', 'window save must preserve unsaved unrelated palette changes');
assert.deepStrictEqual(Array.from(saved.settingsGeometry), [100,120,600,850]);
assert.strictEqual(saved.moduleBlurEnabled.settings, true);

// Full Save All remains the existing operation and includes every current change.
current.fontSize = 19;
current.launcherWidth = 810;
assert.strictEqual(api.saveProfile(owner, 'Work'), true);
saved = api.expandedProfileByName(owner, 'Work');
assert.strictEqual(saved.fontSize, 19);
assert.strictEqual(saved.launcherWidth, 810);
assert.strictEqual(owner.saveCount >= 7, true, 'each scoped save queues one settings write');
console.log('scoped profile saves: selected section only, cache reconciliation, unrelated edits retained, and Save All: OK');
NODE
