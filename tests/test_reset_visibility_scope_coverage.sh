#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const rootPath = process.argv[2];
const qml = fs.readFileSync(path.join(rootPath, 'Settings.qml'), 'utf8');
const start = qml.indexOf('    function hasResetChanges(scope, argument) {');
const end = qml.indexOf('\n    function activeProfileData()', start);
assert(start >= 0 && end > start, 'extract the actual hasResetChanges implementation from Settings.qml');
const functionSource = qml.slice(start, end).trim();
const owner = {
  activeProfile: 'Work',
  profiles: { Work: {} },
  resetOverrides: {},
  colorNames: ['accent', 'settingsBackground', 'settingsBorder']
};
const context = { root: owner, activeProfile: owner.activeProfile, profiles: owner.profiles, colorNames: owner.colorNames };
vm.createContext(context);
vm.runInContext(functionSource + '\nthis.hasResetChanges = hasResetChanges;', context, { filename: 'Settings.qml#hasResetChanges' });
const has = (scope, argument) => context.hasResetChanges(scope, argument);
const withOverrides = overrides => { owner.resetOverrides = overrides; };

withOverrides({ moduleBlurEnabled: { settings: true } });
assert.strictEqual(has('modules'), false, 'module-list reset must stay hidden when only Settings-window blur differs');
assert.strictEqual(has('settingsWindow'), true, 'Settings-window reset must appear for Settings-window blur override');
assert.strictEqual(has('all'), true, 'reset-all must include Settings-window blur override');

withOverrides({ moduleBlurEnabled: { launcher: true } });
assert.strictEqual(has('modules'), true, 'module-list reset must include launcher module blur');
assert.strictEqual(has('module', 'launcher'), true, 'launcher reset must detect launcher blur');

withOverrides({ modules: { time: false }, moduleBlurEnabled: { settings: true } });
assert.strictEqual(has('modules'), true, 'module-list reset remains visible when a resettable module value differs');

withOverrides({ colors: { settingsBackground: '#111111' } });
assert.strictEqual(has('settingsWindow'), true, 'Settings-window reset must detect its nested background color');
assert.strictEqual(has('all'), true, 'reset-all must include nested Settings-window background color');
withOverrides({ colors: { settingsBorder: '#222222' } });
assert.strictEqual(has('settingsWindow'), true, 'Settings-window reset must detect its nested border color');
withOverrides({ colors: { accent: '#123456' } });
assert.strictEqual(has('settingsWindow'), false, 'unrelated color override must not enable Settings-window reset');

withOverrides({ activeTheme: 'Alternate Theme' });
assert.strictEqual(has('themes'), true, 'theme save/reset scope must detect activeTheme changes even if the resulting palette is unchanged');
assert.strictEqual(has('all'), true, 'reset-all must detect activeTheme changes even if the resulting palette is unchanged');
withOverrides({ colors: { accent: '#123456' } });
assert.strictEqual(has('themes'), true, 'theme-level save must detect any color override');

withOverrides({ timerWheelStep: 3 });
assert.strictEqual(has('module', 'time'), false, 'clock reset must not mistake timer settings for time settings');
assert.strictEqual(has('module', 'timer'), true, 'timer module reset must detect timer-prefixed settings');
withOverrides({ animationTimerVisibilityStyle: 'slide' });
assert.strictEqual(has('module', 'timer'), false, 'timer module reset must not claim to reset animation keys it leaves unchanged');
assert.strictEqual(has('timer'), true, 'Timer settings tab reset must detect animationTimer settings it does reset');
withOverrides({ animationTimerOptionsVisibilityStyle: 'slideUp' });
assert.strictEqual(has('module', 'timer'), false, 'timer module reset must not claim to reset the options-popup animation');
assert.strictEqual(has('timer'), true, 'Timer settings tab reset must include the independent options-popup animation');
withOverrides({ topAppsFontSize: 13 });
assert.strictEqual(has('module', 'cpu'), false, 'CPU module reset must not be enabled for Top Apps-only changes');
assert.strictEqual(has('module', 'topAppsCpu'), true, 'Top Apps row reset must detect Top Apps configuration');
assert.strictEqual(has('cpu'), true, 'CPU/RAM settings tab reset must include its Top Apps subsettings');
withOverrides({ cpuGraphMode: 'bars' });
assert.strictEqual(has('module', 'cpu'), false, 'CPU module reset must not be enabled for graph-mode-only changes');
assert.strictEqual(has('module', 'cpuGraph'), true, 'CPU Graph module reset must detect graph mode');
assert.strictEqual(has('cpu'), true, 'CPU/RAM settings tab reset must detect graph mode');
withOverrides({ cpuGraphBarWidth: 4 });
assert.strictEqual(has('module', 'cpu'), true, 'CPU module reset also restores the shared graph bar width');
assert.strictEqual(has('module', 'cpuGraph'), true, 'CPU Graph reset restores the same shared graph bar width');

const scopeSamples = [
  ['general', { fontSize: 15 }],
  ['timer', { timerWheelStep: 3 }],
  ['player', { playerFont: 'Custom Font' }],
  ['weather', { weatherIconSize: 34 }],
  ['cava', { cavaBars: 32 }],
  ['cpu', { topAppsFontSize: 12 }],
  ['network', { networkRowHeight: 24 }],
  ['volume', { volumeMainRowHeight: 22 }],
  ['calendar', { calendarDayFontSize: 12 }],
  ['mopidy', { mopidyHideTopPanel: true }],
  ['launcher', { launcherTitleText: 'Run' }],
  ['settingsWindow', { settingsTabOrder: ['launcher'] }],
  ['modules', { modules: { time: false } }]
];
for (const [scope, overrides] of scopeSamples) {
  withOverrides(overrides);
  assert.strictEqual(has(scope), true, `${scope} reset must detect a representative scoped override`);
  assert.strictEqual(has('all'), true, `reset-all must detect ${scope} override`);
}

withOverrides({ settingsTabLabels: { general: 'Workspace' } });
assert.strictEqual(has('settingsWindow'), true, 'Settings-window reset must include custom tab labels');
withOverrides({});
assert.strictEqual(has('settingsWindow'), false, 'Settings-window reset stays hidden without relevant overrides');
assert.strictEqual(has('all'), false, 'reset-all stays hidden when no sparse overrides remain');

console.log('Reset visibility scope coverage and nested settings regressions: OK');
JS
