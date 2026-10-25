#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const rootPath = process.argv[2];
function load(file) {
  const source = fs.readFileSync(path.join(rootPath, file), 'utf8').replace(/^\.pragma library\s*/m, '');
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context, {filename: file});
  return context;
}
const Persistence = load('js/settings/SettingsPersistence.js');
const Profiles = load('js/settings/SettingsProfiles.js');
const Resets = load('js/settings/SettingsResets.js');
const clone = value => JSON.parse(JSON.stringify(value));
const originalConfig = {
  launcherEnabled: true, launcherWidth: 720, launcherHeight: 640,
  launcherItemHeight: 42, launcherItemRadius: 8, launcherRadius: 12,
  launcherBackdropOpacity: 0.72, launcherBackground: '#22334455',
  launcherTitleY: -4, launcherTitleColor: '#aabbcc',
  launcherTitleText: 'LAUNCHER', launcherTitleFont: '', launcherTitleFontSize: 18,
  launcherTitleBold: true, launcherSearchFont: '', launcherSearchFontSize: 14,
  launcherSearchHeight: 34, launcherSearchRadius: 8, launcherSearchBackground: '#11223344',
  launcherDefaultMode: 0, launcherShowResultCount: true,
  launcherCrossSearchProjects: true, launcherCrossSearchRunHistory: true,
  launcherTabOrder: [0,1,2,3,4,5,6,7,8], launcherTabVisible: [true,true,true,true,true,true,true,true,true],
  launcherProjects: [{name: 'work', path: '/home/test/work', ide: 'code'}]
};
const config = clone(originalConfig);
const owner = {
  loaded: true, pendingWriteRequested: false,
  moduleNames: [], colorNames: ['baseColor','accent','text'],
  weatherToken: 'token-before-write', persistedWeatherToken: 'token-before-write',
  activeProfile: '', profileStorageFormat: 'sparse-v1', profiles: {}, profileList: [],
  customThemes: {}, activeTheme: '14 Theme',
  geometry: {launcher: [-999999,-999999,720,640]},
  moduleFrames: {launcher:false}, moduleBackgrounds: {launcher:true}, moduleMonitors: {launcher:'DP-1'},
  settingsGeometry: [640,40,560,850], settingsMonitorName: 'DP-1',
  defaultGeometry: {launcher: [-999999,-999999,720,640]},
  defaultConfig: clone(originalConfig),
  savedSignals: 0,
  writer: {
    running:true, processExited:false, tokenOutputFinished:false, writerExitCode:-1,
    commandMode:'set-json-ui', payload:'', tokenBaseline:'token-before-write',
    tokenRequested:'token-before-write', tokenResult:''
  },
  snapshotObject() {
    return {
      weatherToken: this.weatherToken,
      ...clone(config),
      activeTheme: this.activeTheme,
      colors: {baseColor:'#111111', accent:'#222222', text:'#eeeeee'},
      geometry: clone(this.geometry), moduleFrames: clone(this.moduleFrames),
      moduleBackgrounds: clone(this.moduleBackgrounds), moduleMonitors: clone(this.moduleMonitors),
      settingsGeometry: clone(this.settingsGeometry), settingsMonitorName:this.settingsMonitorName
    };
  },
  applyObject(value) {
    for (const key of Object.keys(config)) if (value[key] !== undefined) config[key] = clone(value[key]);
    for (const key of ['weatherToken','activeTheme','geometry','moduleFrames','moduleBackgrounds','moduleMonitors','settingsGeometry','settingsMonitorName']) {
      if (value[key] !== undefined && key !== 'weatherToken') this[key] = clone(value[key]);
      else if (key === 'weatherToken' && value[key] !== undefined) this.weatherToken = String(value[key]);
    }
  },
  saved() { this.savedSignals++; },
  save() { return Persistence.save(this, config); },
  rebuildProfileList() { Profiles.rebuildProfileList(this); },
  expandedProfileData(name) { return Profiles.expandedProfileByName(this, name); },
  resetUnavailable(message) { throw new Error(message); }
};
owner.profileDefaults = Profiles.captureDefaults(owner);
owner.writer.payload = JSON.stringify(Persistence.payloadObject(owner, config));
const originalInflightPayload = owner.writer.payload;

// Save the known-good profile while an earlier settings write is still active.
assert.strictEqual(Profiles.saveProfile(owner, 'Work'), true);
assert.strictEqual(owner.pendingWriteRequested, true, 'profile save should queue behind the active settings write');
const expectedProfile = owner.expandedProfileData('Work');

// Move away from the profile, reload it, then deliberately perturb launcher-only
// settings and invoke the same reset function used by the UI while the writer is busy.
config.launcherWidth = 980;
config.launcherHeight = 790;
config.launcherItemRadius = 29;
owner.geometry = {launcher:[120,240,980,790]};
owner.moduleFrames = {launcher:true};
owner.moduleBackgrounds = {launcher:false};
owner.moduleMonitors = {launcher:'DP-2'};
assert.strictEqual(Profiles.loadProfile(owner, 'Work'), true);
config.launcherWidth = 999;
config.launcherHeight = 888;
config.launcherItemRadius = 30;
owner.geometry = {launcher:[500,400,999,888]};
owner.moduleFrames = {launcher:true};
owner.moduleBackgrounds = {launcher:false};
owner.moduleMonitors = {launcher:'DP-3'};
Resets.resetLauncherSettings(owner, config);
assert.strictEqual(owner.pendingWriteRequested, true, 'reset should remain queued until both completion signals finish');
assert.strictEqual(owner.writer.payload, originalInflightPayload, 'active write snapshot must remain immutable while profile actions queue');

// Simulate an external token committed after the first UI snapshot was launched.
// Its committed value is returned by set-json-ui and reconciled before flushing the queue.
const externalToken = 'token-from-external-writer';
owner.writer.running = false;
owner.writer.processExited = true;
owner.writer.tokenOutputFinished = true;
owner.writer.writerExitCode = 0;
owner.writer.tokenResult = externalToken;
if (String(owner.weatherToken || '').trim() === String(owner.writer.tokenRequested || '').trim())
  owner.weatherToken = externalToken;
owner.persistedWeatherToken = externalToken;
owner.writer.processExited = false;
owner.writer.tokenOutputFinished = false;
owner.writer.writerExitCode = -1;

assert.strictEqual(Persistence.flushPendingWrite(owner, config), true, 'queued profile reset should start after the old write is finalized');
const finalPayload = JSON.parse(owner.writer.payload);
assert.strictEqual(finalPayload.activeProfile, 'Work', 'the latest active profile must be stored');
const effectiveState = Profiles.mergeValue(expectedProfile, finalPayload.profileOverrides || {});
assert.strictEqual(effectiveState.launcherWidth, expectedProfile.launcherWidth, 'launcher width must be restored from the active profile');
assert.strictEqual(effectiveState.launcherHeight, expectedProfile.launcherHeight, 'launcher height must be restored from the active profile');
assert.strictEqual(effectiveState.launcherItemRadius, expectedProfile.launcherItemRadius, 'launcher radius must be restored from the active profile');
assert.strictEqual(JSON.stringify(effectiveState.geometry.launcher), JSON.stringify(expectedProfile.geometry.launcher), 'launcher geometry must match the profile');
assert.strictEqual(effectiveState.moduleFrames.launcher, expectedProfile.moduleFrames.launcher, 'launcher frame flag must match the profile');
assert.strictEqual(effectiveState.moduleBackgrounds.launcher, expectedProfile.moduleBackgrounds.launcher, 'launcher background flag must match the profile');
assert.strictEqual(effectiveState.moduleMonitors.launcher, expectedProfile.moduleMonitors.launcher, 'launcher monitor must match the profile');
for (const key of ['launcherWidth','launcherHeight','launcherItemRadius','geometry','moduleFrames','moduleBackgrounds','moduleMonitors']) {
  assert.strictEqual(Object.prototype.hasOwnProperty.call(finalPayload.profileOverrides || {}, key), false, `${key} must not be duplicated when it matches the active profile`);
}
assert.strictEqual(finalPayload.weatherToken, externalToken, 'profile load/reset must not revert an external weather-token update');
assert.strictEqual(finalPayload.profiles.Work !== undefined, true, 'the saved profile itself must remain in the payload');
assert.strictEqual(owner.pendingWriteRequested, false, 'pending queue should clear after launching the coalesced snapshot');
console.log('Settings profile load/reset during pending write preserves final profile and external token: OK');
JS
