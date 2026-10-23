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
const Themes = load('js/settings/SettingsThemes.js');
const Schema = load('js/settings/SettingsSchema.js');
const Profiles = load('js/settings/SettingsProfiles.js');
const ThemeManager = load('js/settings/SettingsThemeManager.js', {Profiles});
const ApplyState = load('js/settings/SettingsApplyState.js', {Schema, Profiles, Themes});

// Persisted hex colors must have one canonical representation. Otherwise a
// visually identical palette may be incorrectly marked Changed or fail exact
// theme matching after export/reload.
assert.strictEqual(Schema.normalizeSavedColor('#FFABCDEF', '#000000'), '#ffabcdef');
assert.strictEqual(Schema.normalizeSavedColor('#ABCDEF', '#000000'), '#abcdef');
assert.strictEqual(Schema.normalizeSavedColor('TRANSPARENT', '#000000'), 'transparent');
assert.strictEqual(Schema.normalizeSavedColor('#1234567', '#aabbcc'), '#aabbcc', 'seven-digit hex is invalid');

const builtin = Themes.palette('14 Theme', {});
const sourcePalette = {...builtin, accent: '#ab12cd'};
const uppercasePalette = {};
for (const [key, value] of Object.entries(sourcePalette))
  uppercasePalette[key] = typeof value === 'string' && value.startsWith('#') ? value.toUpperCase() : value;
const normalized = Schema.normalizeCustomThemes({'Exported Palette': uppercasePalette}, builtin);
for (const [key, value] of Object.entries(builtin)) {
  if (typeof value === 'string' && value.startsWith('#'))
    assert.strictEqual(normalized['Exported Palette'][key], sourcePalette[key].toLowerCase(), `canonical palette key ${key}`);
}

// Simulate saved settings exported with an obsolete active-theme name and an
// uppercase palette. Reload must resolve to the equivalent palette, not mark
// it as modified or fall back to a random built-in theme.
const colorNames = Object.keys(builtin);
const savedColors = {...uppercasePalette};
const config = {...builtin};
const owner = {
  moduleFrames: {}, moduleBackgrounds: {}, moduleMonitors: {}, geometry: {},
  settingsGeometry: [0, 0, 600, 700], settingsMonitorName: '',
  profiles: {}, profileStorageFormat: '', customThemes: {}, activeTheme: '14 Theme',
  activeProfile: '', profileList: [], profilesRevision: 0, themeStateRevision: 0,
  loaded: false,
  rebuildProfileList() { this.profileList = Object.keys(this.profiles || {}).sort(); },
  changed() {}
};
ApplyState.apply(owner, config, {
  colors: savedColors,
  customThemes: {'Exported Palette': uppercasePalette},
  activeTheme: 'Deleted/Old Palette Name',
  modules: {}, moduleFrames: {}, moduleBackgrounds: {}, moduleMonitors: {}, geometry: {}
}, [], {}, {}, colorNames);
assert.strictEqual(owner.activeTheme, 'Exported Palette', 'reload resolves a stale name to the equivalent canonical palette');
assert.strictEqual(ThemeManager.isCurrentThemeModified(owner, Themes, colorNames, config), false, 'canonical round-trip does not spuriously mark theme Changed');
assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.customThemes['Exported Palette'])), JSON.parse(JSON.stringify(normalized['Exported Palette'])));

// Draft editing must not accept seven-digit hex, and uppercase inputs should
// be canonicalized immediately rather than only after a future reload.
const draftOwner = {themeDraft:{accent:'#00cccc'}, themeDraftRevision:0};
assert.strictEqual(ThemeManager.setThemeDraftColor(draftOwner, 'accent', '#1234567'), false);
assert.strictEqual(draftOwner.themeDraft.accent, '#00cccc', 'invalid draft color leaves the existing value untouched');
assert.strictEqual(ThemeManager.setThemeDraftColor(draftOwner, 'accent', '#ABCDEF'), true);
assert.strictEqual(draftOwner.themeDraft.accent, '#abcdef');
assert.strictEqual(ThemeManager.setThemeDraftColor(draftOwner, 'accent', '#FFAABBCC'), true);
assert.strictEqual(draftOwner.themeDraft.accent, '#ffaabbcc');
assert.strictEqual(ThemeManager.setThemeDraftColor(draftOwner, 'accent', 'TRANSPARENT'), true);
assert.strictEqual(draftOwner.themeDraft.accent, 'transparent');
console.log('Theme palette round-trip canonicalization and valid color input: OK');
JS
