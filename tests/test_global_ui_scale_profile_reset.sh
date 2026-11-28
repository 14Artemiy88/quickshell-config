#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = process.argv[2];
const defaults = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const persistence = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8');
const resets = fs.readFileSync(path.join(root, 'js/settings/SettingsResets.js'), 'utf8');
const settings = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
const general = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsInterfaceSection.qml'), 'utf8');
const settingsWindow = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsWindowSection.qml'), 'utf8');
const vm = require('node:vm');
const expected = ['uiScale', 'fontScale', 'settingsUiScale', 'settingsFontScale'];
for (const key of expected) {
  assert.match(defaults, new RegExp(`${key}: 100`), `${key} uses neutral default`);
  assert.ok(persistence.includes(`${key}: config.${key}`), `${key} is in the complete profile snapshot`);
  assert.ok(resets.includes(`"${key}"`), `${key} restores from the active profile on reset`);
}
assert.ok(general.includes('changeKeys: ({ keys: ["uiScale", "fontScale"] })'),
  'module scales have their own Interface page save/reset scope');
assert.match(settings, /if \(scope === "general"\)[\s\S]*?return hasAny\(\[[^\]]*\"fontScale\"[^\]]*\"uiScale\"/ ,
  'the General page action scope detects module UI and font scale overrides');
assert.ok(settingsWindow.includes('"settingsFontScale", "settingsUiScale"'),
  'settings scales belong to the Settings-window save/reset scope');

function loadLibrary(file, extra = {}) {
  const source = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/gm, '');
  const sandbox = { ...extra };
  vm.runInNewContext(source, sandbox, { filename: file });
  return sandbox;
}
const schema = loadLibrary('js/settings/SettingsSchema.js');
const apply = loadLibrary('js/settings/SettingsApplyCore.js', { Schema: schema });
const config = { uiScale: 100, fontScale: 100, settingsUiScale: 100, settingsFontScale: 100 };
apply.apply({}, config, { uiScale: 125, fontScale: 90, settingsUiScale: 110, settingsFontScale: 120 });
assert.deepEqual(
  [config.uiScale, config.fontScale, config.settingsUiScale, config.settingsFontScale],
  [125, 90, 110, 120],
  'all four scale values restore from a saved profile'
);
apply.apply({}, config, { uiScale: 1, fontScale: 999, settingsUiScale: 74, settingsFontScale: 151 });
assert.deepEqual(
  [config.uiScale, config.fontScale, config.settingsUiScale, config.settingsFontScale],
  [75, 150, 75, 150],
  'all four persisted scale values are clamped to the supported range'
);
const legacyFull = schema.normalizeProfile({ fontSize: 12 }, false);
assert.deepEqual(
  [legacyFull.uiScale, legacyFull.fontScale, legacyFull.settingsUiScale, legacyFull.settingsFontScale],
  [100, 100, 100, 100],
  'legacy full profiles without scale keys restore neutral values instead of inheriting another profile'
);
const sparse = schema.normalizeProfile({}, true);
for (const key of expected) assert.equal(sparse[key], undefined, `${key} stays absent in a sparse profile`);
const profiles = loadLibrary('js/settings/SettingsProfiles.js');
for (const key of ['uiScale', 'fontScale'])
  assert.equal(profiles.profileSavePathMatches({}, 'general', null, [key]), true, `${key} belongs to Interface page General profile scope`);
for (const key of ['settingsUiScale', 'settingsFontScale'])
  assert.equal(profiles.profileSavePathMatches({}, 'settingsWindow', null, [key]), true, `${key} belongs to Settings-window scoped profile save`);
const malformedFull = schema.normalizeProfile({ uiScale: 999, fontScale: -10, settingsUiScale: 'bad', settingsFontScale: 125 }, false);
assert.deepEqual(
  [malformedFull.uiScale, malformedFull.fontScale, malformedFull.settingsUiScale, malformedFull.settingsFontScale],
  [150, 75, 100, 125],
  'profile normalization clamps malformed legacy/full values and uses neutral fallbacks'
);
console.log('PASS: all four scale settings have profile/reset integration; module scales activate the Interface page Save/Reset actions.');
NODE
