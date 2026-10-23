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
  const ctx = {...extra};
  vm.createContext(ctx);
  vm.runInContext(source, ctx, {filename:file});
  return ctx;
}
const Profiles = load('js/settings/SettingsProfiles.js');
const Schema = load('js/settings/SettingsSchema.js');
const Themes = load('js/settings/SettingsThemes.js');
const State = load('js/settings/SettingsApplyState.js', {Profiles, Schema, Themes});
const defaults = {
  font: 'Default Font', fontSize: 12,
  launcherWidth: 720, launcherHeight: 640, launcherItemRadius: 11,
  launcherTitleY: 0, launcherTitleColor: '#ffffff',
  launcherCrossSearchProjects: true, launcherCrossSearchRunHistory: true,
  launcherTabVisible: [true, true, true, true, true, true, true, true, true],
  launcherProjects: [],
  modules: {player: true, networks: true, launcher: true},
  moduleFrames: {player: true, networks: true, launcher: true},
  moduleBackgrounds: {player: true, networks: true, launcher: true},
  moduleMonitors: {},
  geometry: {
    player: [10, 20, 300, 180], networks: [20, 30, 250, 120],
    launcher: [-999999, -999999, 720, 640]
  },
  colors: {accent: '#00cccc', text: '#ffffff'},
  activeTheme: '14 Theme'
};
const legacyFullProfile = {
  // Values that existed when the old full snapshot was made must survive.
  font: 'Legacy Font', fontSize: 16, launcherWidth: 910,
  modules: {player: false}, moduleFrames: {player: false},
  moduleBackgrounds: {player: false}, moduleMonitors: {},
  geometry: {player: [111, 122, 333, 188]},
  colors: {accent: '#123456'}, activeTheme: '14 Theme'
  // Missing: newly introduced launcher appearance fields and launcher geometry.
};
const owner = {
  profileDefaults: JSON.parse(JSON.stringify(defaults)),
  profiles: {}, profileStorageFormat: 'legacy', profileMigrationPending: false,
  profileList: [], profilesRevision: 0, activeProfile: '',
  timerPresetDefaults: [], timerPresets: [],
  moduleNames: ['player', 'networks', 'launcher'],
  moduleFrames: {player: true, networks: true, launcher: true},
  moduleBackgrounds: {player: true, networks: true, launcher: true},
  moduleMonitors: {},
  geometry: JSON.parse(JSON.stringify(defaults.geometry)),
  settingsGeometry: [0, 0, 600, 800], settingsMonitorName: '',
  loaded: false,
  rebuildProfileList() { this.profileList = Object.keys(this.profiles).sort(); },
  changed() {}
};
const config = {accent: '#00cccc', text: '#ffffff'};
State.apply(owner, config, {
  profiles: {Legacy: legacyFullProfile},
  modules: {player: true, networks: true, launcher: true},
  moduleFrames: {player: true, networks: true, launcher: true},
  moduleBackgrounds: {player: true, networks: true, launcher: true},
  moduleMonitors: {}, geometry: defaults.geometry, colors: defaults.colors
}, owner.moduleNames, {player:true, networks:true, launcher:true}, {player:true, networks:true, launcher:true}, ['accent', 'text']);
assert.strictEqual(owner.profileStorageFormat, 'sparse-v1');
assert.strictEqual(owner.profileMigrationPending, true);
const expanded = Profiles.expandedProfileByName(owner, 'Legacy');
assert(expanded, 'legacy profile remains loadable after migration');
assert.strictEqual(expanded.font, 'Legacy Font', 'explicit legacy font is retained');
assert.strictEqual(expanded.fontSize, 16, 'explicit legacy scalar is retained');
assert.strictEqual(expanded.launcherWidth, 910, 'explicit legacy launcher width is retained');
assert.strictEqual(expanded.launcherItemRadius, 11, 'new launcher radius inherits current default');
assert.strictEqual(expanded.launcherTitleY, 0, 'new launcher title Y inherits current default');
assert.strictEqual(expanded.launcherTitleColor, '#ffffff', 'new launcher title color inherits current default');
assert.strictEqual(expanded.launcherCrossSearchProjects, true, 'new cross-search setting inherits current default');
assert.strictEqual(expanded.modules.launcher, true, 'new launcher module toggle is inherited');
assert.strictEqual(expanded.moduleFrames.launcher, true, 'new launcher frame toggle is inherited');
assert.strictEqual(expanded.moduleBackgrounds.launcher, true, 'new launcher background toggle is inherited');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.geometry.launcher)), [-999999, -999999, 720, 640], 'new launcher geometry is inherited');
assert.deepStrictEqual(JSON.parse(JSON.stringify(expanded.geometry.player)), [111, 122, 333, 188], 'legacy geometry remains intact');
assert.strictEqual(expanded.moduleFrames.player, false, 'explicit legacy module flags are retained');
assert.strictEqual(expanded.colors.accent, '#123456', 'explicit legacy color is retained');
console.log('legacy full-profile defaults migration: OK');
JS
