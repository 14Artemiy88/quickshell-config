#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
function loadJs(file, extra = {}) {
  let src = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/mg, '');
  const context = {...extra};
  vm.createContext(context);
  vm.runInContext(src, context, {filename:file});
  return context;
}
const Profiles = loadJs('js/settings/SettingsProfiles.js');
const Themes = loadJs('js/settings/SettingsThemes.js');
const ThemeManager = loadJs('js/settings/SettingsThemeManager.js', {Profiles});
const Resets = loadJs('js/settings/SettingsResets.js');
const colorNames = ['baseColor', 'accent', 'text', 'settingsBorder'];
const clone = value => JSON.parse(JSON.stringify(value));
const builtin = Themes.palette('14 Theme', {});
const base = {
  activeTheme: '14 Theme',
  colors: Object.fromEntries(colorNames.map(k => [k, builtin[k]])),
  launcherEnabled: true,
  launcherWidth: 720,
  launcherHeight: 640,
  launcherItemHeight: 52,
  launcherItemRadius: 11,
  launcherRadius: 16,
  launcherBackdropOpacity: 0.55,
  launcherTitleY: 0,
  launcherTitleColor: '#ffffff',
  launcherBackground: '#e6000000',
  launcherCrossSearchProjects: true,
  launcherCrossSearchRunHistory: true,
  launcherProjects: [],
  geometry: {launcher: [-999999, -999999, 720, 640]},
  moduleFrames: {launcher: true},
  moduleBackgrounds: {launcher: true},
  moduleMonitors: {}
};
function makeOwner(customThemes = {}) {
  const owner = {
    profileDefaults: clone(base), profileStorageFormat: 'sparse-v1', profiles: {}, profileList: [],
    activeProfile: '', activeTheme: '14 Theme', customThemes: clone(customThemes), colorNames,
    themeDraft: {}, themeDraftSource: '14 Theme', themeDraftRevision: 0, themeStateRevision: 0,
    snapshot: clone(base), saveCount: 0,
    geometry: clone(base.geometry), moduleFrames: clone(base.moduleFrames),
    moduleBackgrounds: clone(base.moduleBackgrounds), moduleMonitors: {},
    defaultGeometry: {launcher: [-999999, -999999, 720, 640]},
    resetUnavailable() {},
    snapshotObject() { return clone(this.snapshot); },
    applyObject(value) { this.snapshot = clone(value); this.activeTheme = String(value.activeTheme || '14 Theme'); },
    save() { this.saveCount++; },
    rebuildProfileList() { this.profileList = Object.keys(this.profiles).sort(); },
    expandedProfileData(name) { return Profiles.expandedProfileByName(this, name); }
  };
  return owner;
}
function fullColors(palette) {
  const result = {};
  for (const key of colorNames) result[key] = String(palette[key]);
  return result;
}

// Profile round-trip: all launcher appearance fields, module flags, monitor and geometry survive.
{
  const owner = makeOwner();
  owner.snapshot = {
    ...clone(base), activeTheme: 'Dracula', colors: fullColors(Themes.palette('Dracula', {})),
    launcherEnabled: false, launcherWidth: 913, launcherHeight: 777, launcherItemHeight: 61,
    launcherItemRadius: 27, launcherRadius: 23, launcherBackdropOpacity: 0.72,
    launcherTitleY: -17, launcherTitleColor: '#123456', launcherBackground: '#aa112233',
    launcherCrossSearchProjects: false, launcherCrossSearchRunHistory: false,
    launcherProjects: [{name: 'orders', path: '/tmp/orders', ide: 'code'}],
    geometry: {launcher: [234, 156, 913, 777]},
    moduleFrames: {launcher: false}, moduleBackgrounds: {launcher: false},
    moduleMonitors: {launcher: 'DP-1'}
  };
  assert.strictEqual(Profiles.saveProfile(owner, 'Profile A'), true);
  owner.snapshot = clone(base);
  owner.snapshot.launcherItemRadius = 2;
  assert.strictEqual(Profiles.loadProfile(owner, 'Profile A'), true);
  const loaded = owner.snapshot;
  for (const key of ['launcherEnabled','launcherWidth','launcherHeight','launcherItemHeight','launcherItemRadius','launcherRadius','launcherBackdropOpacity','launcherTitleY','launcherTitleColor','launcherBackground','launcherCrossSearchProjects','launcherCrossSearchRunHistory']) {
    assert.deepStrictEqual(loaded[key], owner.expandedProfileData('Profile A')[key], `${key} profile round-trip`);
  }
  assert.strictEqual(loaded.launcherItemRadius, 27);
  assert.strictEqual(loaded.launcherTitleY, -17);
  assert.strictEqual(loaded.launcherTitleColor, '#123456');
  assert.deepStrictEqual(loaded.geometry.launcher, [234,156,913,777]);
  assert.strictEqual(loaded.moduleFrames.launcher, false);
  assert.strictEqual(loaded.moduleBackgrounds.launcher, false);
  assert.strictEqual(loaded.moduleMonitors.launcher, 'DP-1');
  assert.deepStrictEqual(JSON.parse(JSON.stringify(loaded.launcherProjects)), [{name:'orders',path:'/tmp/orders',ide:'code'}]);

  // Reset Launcher settings must restore the entire profile-scoped launcher surface.
  const resetConfig = {
    launcherEnabled: true, launcherWidth: 500, launcherHeight: 400, launcherItemHeight: 36,
    launcherItemRadius: 0, launcherRadius: 0, launcherBackdropOpacity: 0,
    launcherTitleY: 0, launcherTitleColor: '#ffffff', launcherBackground: '#00000000',
    launcherCrossSearchProjects: true, launcherCrossSearchRunHistory: true,
    launcherProjects: [], launcherTitleText: 'OTHER', launcherTitleFont: '', launcherTitleFontSize: 10,
    launcherTitleLetterSpacing: 0, launcherTitleBold: false, launcherSearchFont: '',
    launcherSearchFontSize: 10, launcherSearchHeight: 36, launcherSearchRadius: 0,
    launcherSearchBackground: '#00000000', launcherSearchPlaceholder: 'Other', launcherDefaultMode: 0,
    launcherShowResultCount: false, launcherTabOrder: [], launcherTabVisible: []
  };
  Resets.resetLauncherSettings(owner, resetConfig);
  assert.strictEqual(resetConfig.launcherItemRadius, 27);
  assert.strictEqual(resetConfig.launcherTitleY, -17);
  assert.strictEqual(resetConfig.launcherTitleColor, '#123456');
  assert.strictEqual(resetConfig.launcherWidth, 913);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.geometry.launcher)), [234,156,913,777]);
  assert.strictEqual(owner.moduleFrames.launcher, false);
  assert.strictEqual(owner.moduleBackgrounds.launcher, false);
  assert.strictEqual(owner.moduleMonitors.launcher, 'DP-1');
}

// Renaming a custom theme updates saved profile references without overwriting their saved colors.
{
  const originalPalette = {...builtin, accent: '#234567', text: '#abcdef'};
  const owner = makeOwner({'Work Palette': originalPalette});
  owner.activeTheme = 'Work Palette';
  owner.snapshot = {...clone(base), activeTheme: 'Work Palette', colors: fullColors(originalPalette), launcherItemRadius: 24, launcherTitleY: 6};
  Profiles.saveProfile(owner, 'Work');
  const config = Object.fromEntries(colorNames.map(k => [k, originalPalette[k]]));
  assert.strictEqual(ThemeManager.renameCustomTheme(owner, Themes, config, 'Work Palette', 'Renamed Palette'), true);
  const profile = owner.expandedProfileData('Work');
  assert.strictEqual(profile.activeTheme, 'Renamed Palette');
  assert.strictEqual(profile.launcherItemRadius, 24);
  assert.strictEqual(profile.launcherTitleY, 6);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(profile.colors)), fullColors(originalPalette));
  assert.strictEqual(owner.customThemes['Renamed Palette'].accent, '#234567');
}

// Deleting a referenced theme resolves exact palette matches; modified colors fall back to a valid name and stay intact.
{
  const gonePalette = {...builtin, accent: '#101010', text: '#eeeeee'};
  const owner = makeOwner({'Gone Palette': gonePalette});
  const matching = {...clone(base), activeTheme: 'Gone Palette', colors: fullColors(Themes.palette('Dracula', {})), launcherItemRadius: 21, launcherTitleY: -9};
  const customColors = fullColors(gonePalette);
  customColors.accent = '#987654'; // no longer matches the deleted palette
  const modified = {...clone(base), activeTheme: 'Gone Palette', colors: customColors, launcherItemRadius: 19, launcherTitleY: 12};
  owner.snapshot = matching;
  Profiles.saveProfile(owner, 'Matching');
  owner.snapshot = modified;
  Profiles.saveProfile(owner, 'Modified');
  const config = Object.fromEntries(colorNames.map(k => [k, builtin[k]]));
  assert.strictEqual(ThemeManager.deleteCustomTheme(owner, Themes, config, 'Gone Palette'), true);
  const matchingProfile = owner.expandedProfileData('Matching');
  const modifiedProfile = owner.expandedProfileData('Modified');
  assert.strictEqual(matchingProfile.activeTheme, 'Dracula');
  assert.strictEqual(modifiedProfile.activeTheme, '14 Theme');
  assert.deepStrictEqual(JSON.parse(JSON.stringify(modifiedProfile.colors)), customColors);
  assert.strictEqual(modifiedProfile.launcherItemRadius, 19);
  assert.strictEqual(modifiedProfile.launcherTitleY, 12);
  assert.strictEqual(Profiles.loadProfile(owner, 'Modified'), true);
  assert.strictEqual(owner.activeTheme, '14 Theme', 'loading a profile after theme deletion uses a valid theme name');
  assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.snapshot.colors)), customColors, 'profile custom colors survive fallback');
  assert.strictEqual(owner.snapshot.launcherItemRadius, 19, 'launcher settings survive theme fallback');
}
console.log('profile launcher round-trip and custom-theme rename/delete lifecycle: OK');
JS
