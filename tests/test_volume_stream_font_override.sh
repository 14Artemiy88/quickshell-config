#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const applySource = read('js/settings/SettingsApplySystemVisual.js');
const persistence = read('js/settings/SettingsPersistence.js');
const resetsSource = read('js/settings/SettingsResets.js');
const profilesSource = read('js/settings/SettingsProfiles.js');
const volumeQml = read('components/Volumes.qml');
const volumeSettings = read('components/settings/sections/SettingsVolumeSection.qml');
const navigation = read('components/settings/SettingsNavigationController.qml');
const check = read('CHECK.sh');

assert.match(config, /property string volumeStreamLabelFont: ""/,
  'new font family must default to the application/system family');
assert.match(defaults, /volumeStreamLabelFont: ""/,
  'new font family must have a profile default');
assert.match(volumeQml, /font\.family: Config\.volumeStreamLabelFont\.trim\(\) === "" \? Qt\.application\.font\.family : Config\.volumeStreamLabelFont/,
  'stream labels must use the optional override without changing the default family');
assert.match(volumeSettings, /targetProperty: "volumeStreamLabelFont"/,
  'volume Settings must expose the family field');
assert.match(volumeSettings, /settingsSearchId: "volume-stream-font"/,
  'font field must be available in Settings search');
assert.match(volumeSettings, /Config\.volumeShowStreams \|\| normalizedProgress > 0\.001/,
  'the stream typography controls must collapse with stream visibility');
assert.match(navigation, /"volumeStreamLabelFont", "volumeStreamLabelFontSize"/,
  'the volume appearance subtab dirty state must include the font family');

// Exercise the same apply function used by profile loading, with imports stripped.
const applyContext = {};
const applyCode = applySource
  .replace(/^\s*\.pragma library\s*/m, '')
  .replace(/^\s*\.import .*$/gm, '');
vm.runInNewContext(applyCode, applyContext, { filename: 'SettingsApplySystemVisual.js' });
const liveConfig = {};
applyContext.apply(liveConfig, { volumeStreamLabelFont: '  App\nStream\tFont  ' });
assert.strictEqual(liveConfig.volumeStreamLabelFont, 'App Stream Font',
  'loaded font family must trim and normalize control characters');
applyContext.apply(liveConfig, { volumeStreamLabelFont: 'x'.repeat(200) });
assert.strictEqual(liveConfig.volumeStreamLabelFont.length, 128,
  'loaded font family must be bounded');
applyContext.apply(liveConfig, { volumeStreamLabelFont: null });
assert.strictEqual(liveConfig.volumeStreamLabelFont, '',
  'invalid font-family values must restore inherited default');

assert.match(persistence, /volumeStreamLabelFont: config\.volumeStreamLabelFont/,
  'profile snapshots must persist the stream font override');
assert.match(resetsSource, /"volumeMutedIcon", "volumeStreamLabelFont", "volumeStreamLabelFontSize"/,
  'module reset must restore the stream font family');
const resetPage = resetsSource.slice(resetsSource.indexOf('function resetVolumeSettings'), resetsSource.indexOf('function resetTimerSettings'));
assert.ok(resetPage.includes('"volumeStreamLabelFont"'),
  'page reset must restore the stream font family');

const profileContext = {};
const profileCode = profilesSource
  .replace(/^\s*\.pragma library\s*/m, '')
  .replace(/^\s*\.import .*$/gm, '');
vm.runInNewContext(profileCode, profileContext, { filename: 'SettingsProfiles.js' });
assert.strictEqual(profileContext.modulePathMatches(['volumeStreamLabelFont'], 'volumes'), true,
  'font family must belong to the independent volume module scope');
assert.strictEqual(profileContext.modulePathMatches(['volumeStreamLabelFont'], 'player'), false,
  'volume font must not leak into another module profile scope');
assert.strictEqual(profileContext.profileSavePathMatches({}, 'volume', null, ['volumeStreamLabelFont']), true,
  'the dedicated Volume page save must capture the font family');
assert.strictEqual(profileContext.profileSavePathMatches({}, 'general', null, ['volumeStreamLabelFont']), false,
  'the stream font must not leak into General saves');
assert.ok(check.includes('run_test "$ROOT/tests/test_volume_stream_font_override.sh"'),
  'new integration test must be registered in CHECK.sh');
console.log('PASS: Volume stream font override rendering, defaults, validation, persistence, search, profile scope and reset');
NODE
