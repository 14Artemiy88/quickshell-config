#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
function load(name, extra = {}) {
  const source = read(name).replace(/^\s*\.pragma library\s*/m, '').replace(/^\s*\.import .*$/gm, '');
  const context = { ...extra };
  vm.runInNewContext(source, context, { filename: name });
  return context;
}

const configSource = read('Config.qml');
const defaultsSource = read('js/settings/SettingsDefaults.js');
const persistenceSource = read('js/settings/SettingsPersistence.js');
const weatherSource = read('components/WeatherNow.qml');
const settingsSource = read('components/settings/sections/SettingsWeatherSection.qml');
const checksSource = read('CHECK.sh');
const apply = load('js/settings/SettingsApplyWeather.js');
const resets = load('js/settings/SettingsResets.js');
const profiles = load('js/settings/SettingsProfiles.js');

assert.match(configSource, /property string weatherFont: ""/,
  'empty weatherFont must preserve the shared LED-font default');
assert.match(defaultsSource, /weatherFont: ""/,
  'weatherFont must be included in default profile snapshots');
assert.ok(persistenceSource.includes('weatherFont: config.weatherFont'),
  'weatherFont must survive profile save/load');
assert.ok(settingsSource.includes('targetProperty: "weatherFont"'),
  'weather settings must expose the font override');
assert.ok(settingsSource.includes('settingsSearchId: "weather-font"'),
  'weather font must be discoverable in Settings search');
assert.ok(settingsSource.includes('placeholderText: "Общий LED-шрифт"'),
  'empty field must explain the inherited font');
assert.ok(settingsSource.includes('heading: "Шрифт текущей погоды"'),
  'weather font must be grouped separately');

const currentWeather = weatherSource.match(/font\.family: Config\.weatherFont \|\| Config\.ledFont/g) || [];
assert.strictEqual(currentWeather.length, 7,
  'temperature, feels-like, wind speed/unit and pressure value/unit must use the override');
assert.ok(!/font\.family: Config\.weatherFont \|\| Config\.ledFont/.test(read('components/WeatherForecastItem.qml')),
  'forecast typography must remain unchanged by the current-weather font control');

// The loader trims control characters and bounds user-supplied font family names.
const config = { weatherFont: '' };
apply.apply(config, { weatherFont: '  Weather\nFont\tFamily  ' });
assert.strictEqual(config.weatherFont, 'Weather Font Family');
apply.apply(config, { weatherFont: 'x'.repeat(200) });
assert.strictEqual(config.weatherFont.length, 128);
apply.apply(config, { weatherFont: null });
assert.strictEqual(config.weatherFont, '');

// Weather module scope includes this key, without widening it to general settings.
assert.strictEqual(profiles.modulePathMatches(['weatherFont'], 'weatherNow'), true);
assert.strictEqual(profiles.modulePathMatches(['weatherFont'], 'weatherHourly'), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'weather', null, ['weatherFont']), true);
assert.strictEqual(profiles.profileSavePathMatches({}, 'general', null, ['weatherFont']), false);

// Both module reset and page-level reset restore the active profile value.
const profile = { weatherFont: 'Profile Weather Font' };
function makeOwner() {
  return {
    activeProfile: 'Default', profiles: { Default: {} },
    expandedProfileData: () => profile,
    geometry: { weatherNow: [1, 2, 3, 4] },
    moduleFrames: { weatherNow: true }, moduleBackgrounds: { weatherNow: true },
    moduleBlurEnabled: { weatherNow: false }, moduleMonitors: {},
    defaultModuleFrames: { weatherNow: true }, defaultModuleBackgrounds: { weatherNow: true },
    defaultModuleBlurEnabled: { weatherNow: false },
    weatherNow: true,
    saveCount: 0, save() { this.saveCount += 1; }
  };
}
let owner = makeOwner();
let resetConfig = { weatherFont: 'Edited Weather Font' };
resets.resetModule(owner, resetConfig, 'weatherNow');
assert.strictEqual(resetConfig.weatherFont, profile.weatherFont,
  'resetting the current-weather module must restore weatherFont');
assert.strictEqual(owner.saveCount, 1);

owner = makeOwner();
resetConfig = { weatherFont: 'Edited Weather Font' };
resets.resetWeatherSettings(owner, resetConfig);
assert.strictEqual(resetConfig.weatherFont, profile.weatherFont,
  'resetting the weather settings page must restore weatherFont');
assert.strictEqual(owner.saveCount, 1);

assert.ok(checksSource.includes('run_test "$ROOT/tests/test_weather_font_override.sh"'),
  'the integration test must be part of CHECK.sh');
console.log('Weather current-data font override: rendering, inherited default, validation, persistence, profile scope and reset: OK');
NODE
