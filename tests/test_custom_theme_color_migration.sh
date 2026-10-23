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
const ApplyState = load('js/settings/SettingsApplyState.js', {Schema, Profiles, Themes});
const fallback = Themes.palette('14 Theme', {});

// Old custom-theme palettes can store QColor objects, omit recently added keys,
// and contain a few invalid values. Valid colors should normalize; missing/new
// fields inherit from matching legacy colors where available, otherwise defaults.
const legacyPalette = {
  baseColor: '#123456',
  accent: {valid:true, a:1, r:0.2, g:0.4, b:0.6},
  ram: '#654321',
  metricTrack: '#7f112233',
  text: '#fefefe',
  background: {valid:false, a:NaN, r:0, g:0, b:0},
  futureColor: '#abcdef'
};
const normalized = Schema.normalizeCustomThemes({'Legacy Palette': legacyPalette, Bad: null}, fallback);
assert(normalized['Legacy Palette'], 'valid theme is retained');
assert.strictEqual(normalized['Legacy Palette'].accent, '#ff336699', 'legacy QColor object converts to canonical ARGB');
assert.strictEqual(normalized['Legacy Palette'].background, fallback.background, 'invalid legacy color falls back safely');
assert.strictEqual(normalized['Legacy Palette'].tempVeryCold, fallback.tempVeryCold, 'missing known palette keys inherit defaults');
assert.strictEqual(normalized['Legacy Palette'].topAppsCpuBarColor, '#ff336699', 'legacy CPU bar color inherits old accent');
assert.strictEqual(normalized['Legacy Palette'].topAppsRamBarColor, '#654321', 'legacy RAM bar color inherits old RAM color');
assert.strictEqual(normalized['Legacy Palette'].topAppsCpuBarTrackColor, '#7f112233', 'legacy Top Apps track inherits metricTrack');
assert.strictEqual(normalized['Legacy Palette'].futureColor, '#abcdef', 'unknown valid color keys are retained');
assert(!normalized.Bad, 'invalid custom theme entries are ignored');

// Apply-state migration: an old root color map lacks new Top Apps fields and its
// active theme name is stale. Resolve by the persisted legacy colors and fill
// only missing root colors from that palette, preserving custom theme identity.
const oldTheme = {...fallback, ...normalized['Legacy Palette']};
const oldColorNames = Object.keys(fallback).filter(k => !k.startsWith('topAppsCpuBar') && !k.startsWith('topAppsRamBar'));
const savedColors = {};
for (const key of oldColorNames) savedColors[key] = oldTheme[key];
const Config = {...fallback};
const owner = {
  moduleFrames: {launcher:true}, moduleBackgrounds: {launcher:true}, moduleMonitors: {},
  geometry: {}, settingsGeometry: [0,0,500,700], settingsMonitorName: '',
  profiles: {}, profileStorageFormat: '', customThemes: {}, activeTheme: '14 Theme', activeProfile: '',
  profileList: [], profilesRevision: 0, themeStateRevision: 0, loaded: false,
  rebuildProfileList() { this.profileList = Object.keys(this.profiles || {}).sort(); },
  changed() {}
};
const settings = {
  colors: savedColors,
  customThemes: {'Legacy Palette': legacyPalette},
  activeTheme: 'Deleted Old Name',
  modules: {launcher:true}, moduleFrames: {launcher:true}, moduleBackgrounds: {launcher:true},
  moduleMonitors: {}, geometry: {launcher:[0,0,720,640]}
};
ApplyState.apply(owner, Config, settings, ['launcher'], {launcher:true}, {launcher:true}, oldColorNames.concat(['topAppsCpuBarColor','topAppsRamBarColor','topAppsCpuBarTrackColor','topAppsRamBarTrackColor']));
assert.strictEqual(owner.activeTheme, 'Legacy Palette', 'stale active theme resolves to matching migrated custom palette');
assert.strictEqual(Config.topAppsCpuBarColor, '#ff336699', 'new root color is filled from legacy custom accent');
assert.strictEqual(Config.topAppsRamBarColor, '#654321', 'new root RAM bar color is filled from legacy custom RAM color');
assert.strictEqual(Config.topAppsCpuBarTrackColor, '#7f112233', 'new root track color is filled from legacy custom track color');
assert.strictEqual(Config.text, '#fefefe', 'existing root color stays intact');
assert.strictEqual(owner.loaded, true, 'settings state completes loading');

// If the old active-theme reference cannot match current colors, use a valid
// theme name without overwriting already-loaded custom colors.
const ConfigModified = {...fallback, accent:'#112233', text:'#445566'};
const ownerModified = {...owner, customThemes:{}, activeTheme:'Old Gone Theme', themeStateRevision:0, profiles:{}, moduleFrames:{launcher:true}, moduleBackgrounds:{launcher:true}, moduleMonitors:{}, geometry:{}, settingsGeometry:[0,0,500,700], loaded:false, changed(){}, rebuildProfileList(){this.profileList=[];}};
ApplyState.apply(ownerModified, ConfigModified, {colors:{accent:'#112233',text:'#445566'}, customThemes:{}, activeTheme:'Old Gone Theme'}, ['launcher'], {launcher:true}, {launcher:true}, ['accent','text']);
assert.strictEqual(ownerModified.activeTheme, '14 Theme', 'unresolvable active theme receives valid default name');
assert.strictEqual(ConfigModified.accent, '#112233', 'existing custom accent remains unchanged');
assert.strictEqual(ConfigModified.text, '#445566', 'existing custom text color remains unchanged');
console.log('custom theme color migration and active-theme fallback: OK');
JS
