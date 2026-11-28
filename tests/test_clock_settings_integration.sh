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
  for (const key of ['clockFont', 'clockDateFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize', 'clockTimeColor', 'clockDateColor', 'clockWeekdayColor', 'clockPaddingX', 'clockPaddingY', 'clockColumnSpacing', 'clockDetailsRightPadding'])
    assert.ok(source.includes(key), `${key} must have a persisted default`);
  assert.match(source, /modules: \[[^\]]*"time"/, 'default Modules navigation must include the clock page');
}
assert.match(configQml, /time: "Часы"/, 'Config must provide the default page label');
assert.match(applyCoreSource, /var SETTINGS_TAB_IDS = \[[^\]]*"time"/, 'settings normalization must accept the clock page ID');
assert.match(applyCoreSource, /time:"Часы"/, 'settings normalization must know the clock label');

for (const key of ['clockFont', 'clockDateFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize', 'clockTimeColor', 'clockDateColor', 'clockWeekdayColor', 'clockPaddingX', 'clockPaddingY', 'clockColumnSpacing', 'clockDetailsRightPadding']) {
  assert.ok(persistenceSource.includes(`${key}: config.${key}`), `${key} must be included in profile snapshots`);
}
assert.ok(pageContent.includes('SettingsTimeSection'), 'the clock page section must be mounted');
assert.ok(navigationController.includes('case "time": settings.resetClockSettings()'),
  'page reset must invoke the dedicated clock reset');
assert.ok(settings.includes('function resetClockSettings()'), 'Settings must expose the clock reset entry point');

assert.match(timeWidget, /font\.family: Config\.clockFont \|\| Config\.ledFont/,
  'time and date must inherit the shared LED family when no override is set');
assert.match(timeWidget, /effectiveTimeFontSize: Math\.max\(1, Math\.round\(\s*Config\.uiFontSize\(Config\.clockFontSize\) \* timePresentationScale \* effectiveCompactScale\)\)/,
  'time must retain its independent font size with presentation scaling');
assert.match(timeWidget, /font\.family: Config\.clockDateFont \|\| Config\.clockFont \|\| Config\.ledFont/,
  'date must support an independent font override with legacy shared-font fallback');
assert.match(timeWidget, /effectiveDateFontSize: Math\.max\(1, Math\.round\(\s*Config\.uiFontSize\(Config\.clockDateFontSize\) \* datePresentationScale\s*\* \(root\.compactPresentation \? effectiveCompactScale : effectiveDateLayoutScale\)\)\)/,
  'date must retain its independent font size with presentation scaling');
assert.match(timeWidget, /font\.family: Config\.clockWeekdayFont \|\| "Ubuntu"/,
  'weekday must use its independent font family');
assert.match(timeWidget, /effectiveWeekdayFontSize: Math\.max\(1, Math\.round\(\s*Config\.uiFontSize\(Config\.clockWeekdayFontSize\) \* datePresentationScale \* effectiveCompactScale\)\)/,
  'weekday must retain its independent font size with presentation scaling');

for (const id of ['clock-font', 'clock-date-font', 'clock-time-size', 'clock-date-size', 'clock-weekday-font', 'clock-weekday-size'])
  assert.ok(timeSettings.includes(`settingsSearchId: "${id}"`), `${id} must be discoverable through Settings search`);
assert.ok(timeSettings.includes('clockDateFontSize') && timeSettings.includes('clockWeekdayFontSize'));

// Page-level and module-level profile operations must target only clock keys.
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['clockFont']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['clockDateFont']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['clockTimeColor']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['clockPaddingX']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'clock', null, ['timerFont']), false);
assert.strictEqual(profiles.modulePathMatches(['clockFontSize'], 'time'), true);
assert.strictEqual(profiles.modulePathMatches(['clockDateFont'], 'time'), true);
assert.strictEqual(profiles.modulePathMatches(['clockPaddingX'], 'time'), true);
assert.strictEqual(profiles.modulePathMatches(['timerFontSize'], 'time'), false);

// Reset restores the active profile's clock values and does not touch timer values.
const config = {
  clockFont: 'Custom Clock', clockDateFont: 'Custom Date', clockFontSize: 68, clockDateFontSize: 33,
  clockWeekdayFont: 'Custom Weekday', clockWeekdayFontSize: 22,
  clockTimeColor: '#ff0000', clockDateColor: '#00ff00', clockWeekdayColor: '#0000ff',
  clockPaddingX: 10, clockPaddingY: 8, clockColumnSpacing: 12, clockDetailsRightPadding: 14,
  timerFont: 'Timer Font'
};
const profileClock = {
  clockFont: '', clockDateFont: '', clockFontSize: 55, clockDateFontSize: 25,
  clockWeekdayFont: 'Ubuntu', clockWeekdayFontSize: 15,
  clockTimeColor: '', clockDateColor: '', clockWeekdayColor: '',
  clockPaddingX: 2, clockPaddingY: 0, clockColumnSpacing: 4, clockDetailsRightPadding: 6
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
  ['clockFont', 'clockDateFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize', 'clockTimeColor', 'clockDateColor', 'clockWeekdayColor', 'clockPaddingX', 'clockPaddingY', 'clockColumnSpacing', 'clockDetailsRightPadding'].map(key => config[key]),
  ['', '', 55, 25, 'Ubuntu', 15, '', '', '', 2, 0, 4, 6],
  'clock reset must restore all clock-specific profile values'
);
assert.strictEqual(config.timerFont, 'Timer Font', 'clock reset must not modify timer settings');
assert.strictEqual(saved, 1, 'clock reset must persist once');

// Module-level reset must restore every clock-specific appearance control too.
const moduleConfig = {
  clockFont: 'Module Font', clockDateFont: 'Module Date', clockFontSize: 70, clockDateFontSize: 33,
  clockWeekdayFont: 'Module Weekday', clockWeekdayFontSize: 20,
  clockTimeColor: '#aaaaaa', clockDateColor: '#bbbbbb', clockWeekdayColor: '#cccccc',
  clockPaddingX: 20, clockPaddingY: 12, clockColumnSpacing: 18, clockDetailsRightPadding: 16
};
const moduleOwner = {
  activeProfile: 'Default', profiles: { Default: {} },
  expandedProfileData: () => profileClock,
  geometry: { time: [10, 20, 315, 55] }, defaultGeometry: { time: [10, 20, 315, 55] },
  moduleMonitors: {}, moduleFrames: { time: true }, defaultModuleFrames: { time: true },
  moduleBackgrounds: { time: true }, defaultModuleBackgrounds: { time: true },
  moduleBlurEnabled: {}, defaultModuleBlurEnabled: {},
  save: () => {}
};
resets.resetModule(moduleOwner, moduleConfig, 'time');
assert.deepStrictEqual(
  ['clockFont', 'clockDateFont', 'clockFontSize', 'clockDateFontSize', 'clockWeekdayFont', 'clockWeekdayFontSize', 'clockTimeColor', 'clockDateColor', 'clockWeekdayColor', 'clockPaddingX', 'clockPaddingY', 'clockColumnSpacing', 'clockDetailsRightPadding'].map(key => moduleConfig[key]),
  ['', '', 55, 25, 'Ubuntu', 15, '', '', '', 2, 0, 4, 6],
  'module reset must restore all clock-specific appearance values'
);

// Persisted values are normalized to safe, bounded font sizes and family strings.
const schema = { normalizeSavedColor: value => String(value) };
const applyCore = loadLibrary('js/settings/SettingsApplyCore.js', { Schema: schema });
const applyConfig = {};
applyCore.apply({}, applyConfig, {
  clockFont: '  Clock\nFont  ', clockDateFont: '  Date\tFont ', clockFontSize: 999, clockDateFontSize: 1,
  clockWeekdayFont: '  Week\tFont ', clockWeekdayFontSize: 100,
  clockTimeColor: '#12ab34', clockDateColor: '', clockWeekdayColor: '#123456',
  clockPaddingX: 99, clockPaddingY: -5, clockColumnSpacing: 999, clockDetailsRightPadding: 25
});
assert.strictEqual(applyConfig.clockFont, 'Clock Font');
assert.strictEqual(applyConfig.clockDateFont, 'Date Font');
assert.strictEqual(applyConfig.clockFontSize, 72);
assert.strictEqual(applyConfig.clockDateFontSize, 12);
assert.strictEqual(applyConfig.clockWeekdayFont, 'Week Font');
assert.strictEqual(applyConfig.clockWeekdayFontSize, 24);
assert.strictEqual(applyConfig.clockTimeColor, '#12ab34');
assert.strictEqual(applyConfig.clockDateColor, '');
assert.strictEqual(applyConfig.clockWeekdayColor, '#123456');
assert.strictEqual(applyConfig.clockPaddingX, 24);
assert.strictEqual(applyConfig.clockPaddingY, 0);
assert.strictEqual(applyConfig.clockColumnSpacing, 24);
assert.strictEqual(applyConfig.clockDetailsRightPadding, 24);
assert.ok(timeWidget.includes('color: Config.clockTimeColor || Config.text'));
assert.ok(timeWidget.includes('color: Config.clockDateColor || Config.text'));
assert.ok(timeWidget.includes('color: Config.clockWeekdayColor || Config.text'));
assert.ok(timeWidget.includes('anchors.leftMargin: Config.clockPaddingX'));
assert.ok(timeWidget.includes('anchors.topMargin: Config.clockPaddingY'));
assert.ok(timeWidget.includes('spacing: Config.clockColumnSpacing'));
assert.ok(timeWidget.includes('rightPadding: Config.clockDetailsRightPadding'));
for (const id of ['clock-time-color', 'clock-date-color', 'clock-weekday-color', 'clock-padding-x', 'clock-padding-y', 'clock-column-spacing', 'clock-details-right-padding'])
  assert.ok(timeSettings.includes(`settingsSearchId: "${id}"`), `${id} must be discoverable through Settings search`);

assert.ok(check.includes('run_test "$ROOT/tests/test_clock_settings_integration.sh"'),
  'clock integration test must be registered in CHECK.sh');
console.log('PASS: Clock settings navigation, rendering, search, persistence, profile scope, reset, and validation integration');
NODE
