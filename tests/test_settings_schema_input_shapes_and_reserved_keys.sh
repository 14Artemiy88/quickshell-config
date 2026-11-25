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
const ApplyState = load('js/settings/SettingsApplyState.js', {Schema, Profiles, Themes});

// JSON.parse preserves these as own data keys, but plain assignment during
// normalization used to treat __proto__ as a prototype setter and drop it.
const rawProfiles = JSON.parse('{"__proto__":{"fontSize":17},"constructor":{"fontSize":18},"toString":{"fontSize":19}}');
const normalizedProfiles = Schema.normalizeProfiles(rawProfiles, false);
assert.deepStrictEqual(Array.from(Object.keys(normalizedProfiles)).sort(), ['__proto__','constructor','toString']);
for (const name of ['__proto__','constructor','toString'])
  assert.strictEqual(Object.prototype.hasOwnProperty.call(normalizedProfiles, name), true, `profile key ${name} survives normalization`);
assert.strictEqual(Object.getPrototypeOf(normalizedProfiles).fontSize, undefined, 'profile normalization must not mutate the catalog prototype');
assert.deepStrictEqual(Object.keys(Schema.normalizeProfiles([], false)), [], 'an array is not a valid profile catalog');
assert.strictEqual(Schema.normalizeProfile([], false), null, 'an array is not a valid profile record');

const fallback = {accent:'#000000', text:'#ffffff'};
const rawThemes = JSON.parse('{"__proto__":{"accent":"#abcdef"},"constructor":{"accent":"#123456"},"toString":{"accent":"#654321"}}');
const normalizedThemes = Schema.normalizeCustomThemes(rawThemes, fallback);
assert.deepStrictEqual(Array.from(Object.keys(normalizedThemes)).sort(), ['__proto__','constructor','toString']);
for (const name of ['__proto__','constructor','toString'])
  assert.strictEqual(Object.prototype.hasOwnProperty.call(normalizedThemes, name), true, `theme key ${name} survives normalization`);
assert.strictEqual(Object.getPrototypeOf(normalizedThemes).accent, undefined, 'theme normalization must not mutate the catalog prototype');
assert.deepStrictEqual(Object.keys(Schema.normalizeCustomThemes([], fallback)), [], 'an array is not a valid theme catalog');

function ownerForApply() {
  return {
    profileDefaults: {fontSize:12, colors:{accent:'#000000'}},
    profileStorageFormat:'', profiles:{}, profileList:[], profilesRevision:0,
    activeProfile:'', customThemes:{}, activeTheme:'14 Theme',
    moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{}, geometry:{},
    settingsGeometry:[0,0,500,700], settingsMonitorName:'', themeStateRevision:0,
    loaded:false, profileMigrationPending:false,
    rebuildProfileList() { this.profileList = Object.keys(this.profiles || {}).sort(); },
    changed() {}
  };
}
function applyProfileCatalog(storageFormat) {
  const owner = ownerForApply();
  const Config = {...Themes.palette('14 Theme', {}), fontSize:12};
  const profileData = JSON.parse('{"__proto__":{"fontSize":17},"constructor":{"fontSize":18},"toString":{"fontSize":19}}');
  const settings = {
    profiles: profileData,
    profileStorageFormat: storageFormat,
    settingsSchemaVersion: 1,
    modules:{}, moduleFrames:{}, moduleBackgrounds:{}, moduleMonitors:{}, geometry:{},
    colors:{accent:'#000000'}, customThemes:{}, activeTheme:'14 Theme'
  };
  ApplyState.apply(owner, Config, settings, [], {}, {}, ['accent']);
  assert.deepStrictEqual(Array.from(Object.keys(owner.profiles)).sort(), ['__proto__','constructor','toString']);
  for (const name of ['__proto__','constructor','toString'])
    assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.profiles, name), true, `${storageFormat} migration preserves ${name}`);
  assert.strictEqual(Object.getPrototypeOf(owner.profiles).fontSize, undefined, `${storageFormat} migration leaves catalog prototype intact`);
}

// Exercise the two startup branches that rebuild the catalog, including the
// sparse color-pinning branch and the legacy full-snapshot conversion branch.
applyProfileCatalog('sparse-v1');
applyProfileCatalog('legacy');
console.log('Settings schema input shapes and reserved catalog keys: OK');
JS
