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
  const src = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/mg, '');
  const context = {...extra};
  vm.createContext(context);
  vm.runInContext(src, context, {filename:file});
  return context;
}
const Profiles = load('js/settings/SettingsProfiles.js');
const Themes = load('js/settings/SettingsThemes.js');
const ThemeManager = load('js/settings/SettingsThemeManager.js', {Profiles});
const clone = value => JSON.parse(JSON.stringify(value));
const colorNames = ['baseColor', 'accent', 'text', 'settingsBorder'];
const defaultPalette = Themes.palette('14 Theme', {});
const customPalette = {
  ...clone(defaultPalette),
  baseColor: '#123456', accent: '#234567', text: '#345678', settingsBorder: '#456789'
};
const base = {
  activeTheme: '14 Theme',
  colors: Object.fromEntries(colorNames.map(k => [k, defaultPalette[k]])),
  launcherItemRadius: 10,
  geometry: {launcher: [-999999, -999999, 720, 640]},
  moduleFrames: {launcher: true},
  moduleBackgrounds: {launcher: true},
  moduleMonitors: {}
};
const Config = Object.fromEntries(colorNames.map(k => [k, customPalette[k]]));
const owner = {
  profileDefaults: clone(base), profileStorageFormat: 'sparse-v1', profiles: {}, profileList: [],
  activeProfile: '', activeTheme: 'Work Palette', customThemes: {'Work Palette': clone(customPalette)}, colorNames,
  themeDraft: clone(customPalette), themeDraftSource: 'Work Palette', themeDraftRevision: 0,
  themeStateRevision: 0, snapshot: {...clone(base), activeTheme: 'Work Palette', colors: Object.fromEntries(colorNames.map(k => [k, customPalette[k]]))},
  saveCount: 0,
  snapshotObject() {
    const result = clone(this.snapshot);
    result.activeTheme = this.activeTheme;
    result.colors = Object.fromEntries(colorNames.map(k => [k, String(Config[k])]));
    return result;
  },
  applyObject(value) {
    this.snapshot = clone(value);
    this.activeTheme = String(value.activeTheme || '14 Theme');
    for (const key of colorNames) if (value.colors && value.colors[key] !== undefined) Config[key] = value.colors[key];
  },
  save() { this.saveCount++; },
  rebuildProfileList() { this.profileList = Object.keys(this.profiles).sort(); },
  expandedProfileData(name) { return Profiles.expandedProfileByName(this, name); }
};

// Save, rename twice, and save again: each profile must follow the same palette
// without setting Changed or replacing its colors during intermediate cycles.
assert.strictEqual(Profiles.saveProfile(owner, 'Visual work'), true);
assert.strictEqual(ThemeManager.renameCustomTheme(owner, Themes, Config, 'Work Palette', 'Work Palette v2'), true);
assert.strictEqual(owner.expandedProfileData('Visual work').activeTheme, 'Work Palette v2');
assert.deepStrictEqual(colorNames.map(k => Config[k]), colorNames.map(k => customPalette[k]));
assert.strictEqual(ThemeManager.renameCustomTheme(owner, Themes, Config, 'Work Palette v2', 'Work Palette final'), true);
assert.strictEqual(owner.expandedProfileData('Visual work').activeTheme, 'Work Palette final');
assert.strictEqual(Profiles.saveProfile(owner, 'Visual work'), true);
assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, Config), false);

// Deleting the active palette without an exact remaining match must retain
// the on-screen colors and represent them as Changed instead of resetting them.
assert.strictEqual(ThemeManager.deleteCustomTheme(owner, Themes, Config, 'Work Palette final'), true);
assert.strictEqual(owner.activeTheme, '14 Theme');
assert.deepStrictEqual(colorNames.map(k => Config[k]), colorNames.map(k => customPalette[k]), 'active colors survive deleting the active custom palette');
assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, Config), true, 'fallback theme represents retained custom colors as Changed');
const firstSnapshot = owner.expandedProfileData('Visual work');
assert.strictEqual(firstSnapshot.activeTheme, '14 Theme');
assert.deepStrictEqual(colorNames.map(k => firstSnapshot.colors[k]), colorNames.map(k => customPalette[k]), 'profile keeps colors after theme deletion');

// Repeat profile save/load cycles around switching to unrelated built-in themes.
for (let cycle = 0; cycle < 3; cycle++) {
  assert.strictEqual(Profiles.saveProfile(owner, 'Visual work'), true);
  ThemeManager.applyTheme(owner, Themes, Config, cycle % 2 ? 'Dracula' : 'Nord');
  assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, Config), false);
  assert.strictEqual(Profiles.loadProfile(owner, 'Visual work'), true);
  assert.strictEqual(owner.activeTheme, '14 Theme');
  assert.deepStrictEqual(colorNames.map(k => Config[k]), colorNames.map(k => customPalette[k]), `profile colors preserved in cycle ${cycle + 1}`);
  assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, Config), true, `Changed remains consistent in cycle ${cycle + 1}`);
}
const stable = owner.expandedProfileData('Visual work');
Profiles.saveProfile(owner, 'Visual work');
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.expandedProfileData('Visual work'))), JSON.parse(JSON.stringify(stable)), 'saving without changes is idempotent');

// If a deleted custom palette is exactly equivalent to a remaining built-in,
// both the live UI and the saved profile should resolve to that palette.
{
  const dracula = clone(Themes.palette('Dracula', {}));
  const exactColors = Object.fromEntries(colorNames.map(k => [k, dracula[k]]));
  const exactConfig = {...exactColors};
  const exactOwner = {
    profileDefaults: clone(base), profileStorageFormat: 'sparse-v1', profiles: {}, profileList: [],
    activeProfile: '', activeTheme: 'Dracula Copy', customThemes: {'Dracula Copy': dracula}, colorNames,
    themeDraft: clone(dracula), themeDraftSource: 'Dracula Copy', themeDraftRevision: 0, themeStateRevision: 0,
    snapshot: {...clone(base), activeTheme: 'Dracula Copy', colors: clone(exactColors)},
    snapshotObject() {
      const result = clone(this.snapshot);
      result.activeTheme = this.activeTheme;
      result.colors = Object.fromEntries(colorNames.map(k => [k, String(exactConfig[k])]));
      return result;
    },
    applyObject(value) {
      this.snapshot = clone(value);
      this.activeTheme = String(value.activeTheme || '14 Theme');
      for (const key of colorNames) if (value.colors && value.colors[key] !== undefined) exactConfig[key] = value.colors[key];
    },
    save() {}, rebuildProfileList() { this.profileList = Object.keys(this.profiles).sort(); }
  };
  Profiles.saveProfile(exactOwner, 'Equivalent');
  assert.strictEqual(ThemeManager.deleteCustomTheme(exactOwner, Themes, exactConfig, 'Dracula Copy'), true);
  assert.strictEqual(exactOwner.activeTheme, 'Dracula', 'exactly matching remaining theme should be selected');
  assert.deepStrictEqual(colorNames.map(k => exactConfig[k]), colorNames.map(k => dracula[k]), 'matching palette colors remain unchanged');
  assert.strictEqual(ThemeManager.isCurrentThemeModified(exactOwner, Themes, colorNames, exactConfig), false);
  assert.strictEqual(Profiles.expandedProfileByName(exactOwner, 'Equivalent').activeTheme, 'Dracula');
}
console.log('repeated profile/theme rename, delete, save and load lifecycle: OK');
JS
