#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}
function loadLibrary(relativePath, extra = {}) {
  const source = read(relativePath)
    .replace(/^\s*\.pragma library\s*/m, '')
    .replace(/^\s*\.import .*$/gm, '');
  const context = { ...extra };
  vm.runInNewContext(source, context, { filename: relativePath });
  return context;
}

const configQml = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const applyCoreSource = read('js/settings/SettingsApplyCore.js');
const persistenceSource = read('js/settings/SettingsPersistence.js');
const registry = loadLibrary('js/settings/SettingsPageRegistry.js');
const profiles = loadLibrary('js/settings/SettingsProfiles.js');
const resets = loadLibrary('js/settings/SettingsResets.js');
const timeWidget = read('components/TimeWidget.qml');
const timeSettings = read('components/settings/sections/SettingsTimeSection.qml');
const pageContent = read('components/settings/SettingsPageContent.qml');
const navigationController = read('components/settings/SettingsNavigationController.qml');
const settings = read('Settings.qml');
const check = read('CHECK.sh');

const page = registry.TAB_DEFINITIONS.find(item => item.id === 'time');
assert.ok(page, 'clock settings page must be registered');
assert.strictEqual(page.groupId, 'modules', 'clock settings must live in Modules');
assert.strictEqual(registry.OTHER_PAGE_DEFINITIONS.find(item => item.id === 'time').saveScope, 'clock',
  'clock page must use an isolated profile save scope');

for (const source of [configQml, defaults]) {
  for (const key of ['clockFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize'])
    assert.ok(source.includes(key), `${key} must have a persisted default`);
  assert.match(source, /modules: \[[^\]]*"time"/, 'default Modules navigation must include the clock page');
}
assert.match(configQml, /time: "Часы"/, 'Config must provide the default page label');
assert.match(applyCoreSource, /var SETTINGS_TAB_IDS = \[[^\]]*"time"/, 'settings normalization must accept the clock page ID');
assert.match(applyCoreSource, /time:"Часы"/, 'settings normalization must know the clock label');

for (const key of ['clockFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize']) {
  assert.ok(persistenceSource.includes(`${key}: config.${key}`), `${key} must be included in profile snapshots`);
}
assert.ok(pageContent.includes('SettingsTimeSection'), 'the clock page section must be mounted');
assert.ok(navigationController.includes('case "time": settings.resetClockSettings()'),
  'page reset must invoke the dedicated clock reset');
assert.ok(settings.includes('function resetClockSettings()'), 'Settings must expose the clock reset entry point');

assert.match(timeWidget, /font\.family: Config\.clockFont \|\| Config\.ledFont/,
  'time and date must inherit the shared LED family when no override is set');
assert.match(timeWidget, /font\.pixelSize: Config\.clockFontSize/,
  'time must use its independent font size');
assert.match(timeWidget, /font\.pixelSize: Config\.clockDateFontSize/,
  'date must use its independent font size');
assert.match(timeWidget, /font\.family: Config\.clockWeekdayFont \|\| "Ubuntu"/,
  'weekday must use its independent font family');
assert.match(timeWidget, /font\.pixelSize: Config\.clockWeekdayFontSize/,
  'weekday must use its independent font size');

for (const id of ['clock-font', 'clock-time-size', 'clock-date-size', 'clock-weekday-font', 'clock-weekday-size'])
  assert.ok(timeSettings.includes(`settingsSearchId: "${id}"`), `${id} must be discoverable through Settings search`);
assert.ok(timeSettings.includes('clockDateFontSize') && timeSettings.includes('clockWeekdayFontSize'));

// Page-level and module-level profile operations must target only clock keys.
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['clockFont']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['timerFont']), false);
assert.strictEqual(profiles.modulePathMatches(['clockFontSize'], 'time'), true);
assert.strictEqual(profiles.modulePathMatches(['timerFontSize'], 'time'), false);

// Reset restores the active profile's clock values and does not touch timer values.
const config = {
  clockFont: 'Custom Clock', clockFontSize: 68, clockDateFontSize: 33,
  clockWeekdayFont: 'Custom Weekday', clockWeekdayFontSize: 22,
  timerFont: 'Timer Font'
};
const profileClock = {
  clockFont: '', clockFontSize: 55, clockDateFontSize: 25,
  clockWeekdayFont: 'Ubuntu', clockWeekdayFontSize: 15
};
let saved = 0;
const owner = {
  activeProfile: 'Default', profiles: { Default: {} },
  expandedProfileData: () => profileClock,
  save: () => { saved += 1; },
  resetUnavailable: message => { throw new Error(message); }
};
resets.resetClockSettings(owner, config);
assert.deepStrictEqual(
  ['clockFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize'].map(key => config[key]),
  ['', 55, 25, 'Ubuntu', 15],
  'clock reset must restore all clock-specific profile values'
);
assert.strictEqual(config.timerFont, 'Timer Font', 'clock reset must not modify timer settings');
assert.strictEqual(saved, 1, 'clock reset must persist once');

// Persisted values are normalized to safe, bounded font sizes and family strings.
const schema = { normalizeSavedColor: value => String(value) };
const applyCore = loadLibrary('js/settings/SettingsApplyCore.js', { Schema: schema });
const applyConfig = {};
applyCore.apply({}, applyConfig, {
  clockFont: '  Clock\nFont  ', clockFontSize: 999, clockDateFontSize: 1,
  clockWeekdayFont: '  Week\tFont ', clockWeekdayFontSize: 100
});
assert.strictEqual(applyConfig.clockFont, 'Clock Font');
assert.strictEqual(applyConfig.clockFontSize, 72);
assert.strictEqual(applyConfig.clockDateFontSize, 12);
assert.strictEqual(applyConfig.clockWeekdayFont, 'Week Font');
assert.strictEqual(applyConfig.clockWeekdayFontSize, 24);

assert.ok(check.includes('run_test "$ROOT/tests/test_clock_settings_integration.sh"'),
  'clock integration test must be registered in CHECK.sh');
console.log('PASS: Clock settings navigation, rendering, search, persistence, profile scope, reset, and validation integration');
NODE
