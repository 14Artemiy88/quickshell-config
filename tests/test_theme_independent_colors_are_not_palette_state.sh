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
const Metadata = load('js/settings/SettingsMetadata.js');
const Themes = load('js/settings/SettingsThemes.js');
const Profiles = load('js/settings/SettingsProfiles.js', {Metadata});
const ThemeManager = load('js/settings/SettingsThemeManager.js', {Metadata, Profiles});
const Resets = load('js/settings/SettingsResets.js', {Metadata});
const clone = value => JSON.parse(JSON.stringify(value));
const independent = Metadata.independentThemeColorNames;
const managed = Metadata.themeManagedColorNames;
const colorNames = Metadata.colorNames;
assert.strictEqual(managed.length + independent.length, colorNames.length,
  'theme-managed and independent color roles partition the canonical color list');
assert.deepStrictEqual(JSON.parse(JSON.stringify([...managed, ...independent].sort())), JSON.parse(JSON.stringify(colorNames.slice().sort())),
  'every color has exactly one theme role');
assert(independent.includes('playerProgressTrack') && independent.includes('topAppsCpuBarColor'));

const nord = Themes.palette('Nord', {});
const config = clone(nord);
for (const key of independent) config[key] = '#123456';
const owner = {
  activeTheme: 'Nord', customThemes: {}, colorNames,
  themeManagedColorNames: managed, independentThemeColorNames: independent,
  themeDraft: {}, themeDraftSource: '', themeDraftRevision: 0, themeStateRevision: 0,
  saveCount: 0, save() { this.saveCount++; }
};
assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, config), false,
  'independent component colors do not mark the selected global theme as Changed');
config.accent = '#010203';
assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, config), true,
  'a genuinely theme-managed color still marks the palette as Changed');

// Applying a different theme must preserve independent component colors and
// must not leave the selected theme falsely marked as modified.
for (const key of independent) config[key] = '#654321';
ThemeManager.applyTheme(owner, Themes, config, 'Dracula');
for (const key of independent)
  assert.strictEqual(config[key], '#654321', `${key} remains profile/module scoped when a theme is applied`);
assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, config), false,
  'theme switching with preserved independent colors remains unmodified');

// Saving a changed palette persists only theme-owned colors.
config.accent = '#abcdef';
assert.strictEqual(ThemeManager.saveCurrentTheme(owner, colorNames, config, 'Saved Palette'), true);
for (const key of independent)
  assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.customThemes['Saved Palette'], key), false,
    `${key} is excluded from a saved global palette`);
assert.strictEqual(owner.customThemes['Saved Palette'].accent, '#abcdef');

// The custom theme editor also ignores independent colors in its draft and
// does not overwrite their current component values on save.
const draft = clone(Themes.palette('Nord', {}));
for (const key of independent) draft[key] = '#fedcba';
draft.accent = '#102030';
owner.themeDraft = draft;
owner.themeDraftSource = 'Nord';
for (const key of independent) config[key] = '#778899';
assert.strictEqual(ThemeManager.saveCustomTheme(owner, Themes, config, 'Custom Palette'), true);
for (const key of independent) {
  assert.strictEqual(config[key], '#778899', `${key} is not overwritten when saving a custom theme`);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.customThemes['Custom Palette'], key), false,
    `${key} is not stored in the custom theme palette`);
}
assert.strictEqual(config.accent, '#102030');

// Deleting a palette should match a replacement by theme-managed colors even
// when profile-scoped component colors differ from that palette.
const profileColors = clone(nord);
for (const key of independent) profileColors[key] = '#a1b2c3';
const profileOwner = {
  colorNames, themeManagedColorNames: managed, customThemes: {},
  profileStorageFormat: 'legacy-full',
  profiles: {Work: {activeTheme: 'Deleted Palette', colors: profileColors}},
  save() {}
};
assert.strictEqual(Profiles.rewriteThemeReferences(profileOwner, Themes, 'Deleted Palette', ''), true);
assert.strictEqual(profileOwner.profiles.Work.activeTheme, 'Nord',
  'profile theme fallback matches the managed palette despite independent color differences');

// The reset fallback must use the same palette ownership rule.
const resetOwner = {
  colorNames, themeManagedColorNames: managed, customThemes: {}, activeTheme: 'Missing Theme',
  themeStateRevision: 0, themeDraftRevision: 0
};
Resets.restoreProfileTheme(resetOwner, {colors: profileColors}, Themes, colorNames);
assert.strictEqual(resetOwner.activeTheme, 'Nord',
  'reset theme fallback ignores independent component colors');

// Player progress colors have a dedicated Player page and should not be
// duplicated in the global theme editor.
const colorsSection = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsColorsSection.qml'), 'utf8');
const playerGroup = colorsSection.match(/\{ title: "Плеер", colors: \[([\s\S]*?)\]\}/);
assert(playerGroup, 'theme editor keeps the Player color group');
assert(playerGroup[1].includes('playerOverlay'));
assert(!playerGroup[1].includes('playerProgressTrack') && !playerGroup[1].includes('playerProgressFill'),
  'independent Player progress colors are edited only on the Player page');
const playerSection = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsPlayerSection.qml'), 'utf8');
assert(playerSection.includes('targetProperty: "playerProgressTrack"'));
assert(playerSection.includes('targetProperty: "playerProgressFill"'));
console.log('Theme ownership: independent colors excluded from Changed/save/apply/fallback; duplicate Player progress controls removed: OK');
JS
