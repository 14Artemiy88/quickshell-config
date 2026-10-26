#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const base = process.argv[2];
const settingsQml = fs.readFileSync(path.join(base, 'Settings.qml'), 'utf8');
const widget = fs.readFileSync(path.join(base, 'components/settings/SettingsWidget.qml'), 'utf8');
const group = fs.readFileSync(path.join(base, 'components/settings/primitives/SettingsGroup.qml'), 'utf8');
const main = fs.readFileSync(path.join(base, 'components/settings/SettingsWidget.qml'), 'utf8');
// QML rejects duplicate methods on a single Item at load time.
assert.strictEqual((widget.match(/^\s*function settingsSubTabChangeSpec\(/gm) || []).length, 1, 'SettingsWidget has exactly one settingsSubTabChangeSpec method');
assert.strictEqual((widget.match(/^\s*function settingsSubTabHasChanges\(/gm) || []).length, 1, 'SettingsWidget has exactly one settingsSubTabHasChanges method');

const saveFiles = [
  main,
  fs.readFileSync(path.join(base, 'components/settings/sections/SettingsModulesSection.qml'), 'utf8'),
  fs.readFileSync(path.join(base, 'components/settings/sections/SettingsColorsSection.qml'), 'utf8'),
];

const hs = settingsQml.indexOf('    function hasResetChanges(scope, argument) {');
const he = settingsQml.indexOf('\n    function activeProfileData()', hs);
assert(hs >= 0 && he > hs, 'extract hasResetChanges implementation');
const hasSource = settingsQml.slice(hs, he).trim();
const ss = widget.indexOf('    function settingsSubTabChangeSpec(tab, sub) {');
const se = widget.indexOf('\n    function settingsSubTabHasChanges', ss);
assert(ss >= 0 && se > ss, 'extract subtab scope mapping');
const specSource = widget.slice(ss, se).trim();
const owner = {activeProfile:'Work', profiles:{Work:{}}, resetOverrides:{}, colorNames:['accent','settingsBackground','settingsBorder']};
const context = {root:owner, activeProfile:owner.activeProfile, profiles:owner.profiles, colorNames:owner.colorNames};
vm.createContext(context);
vm.runInContext(hasSource + '\nthis.hasResetChanges = hasResetChanges;', context, {filename:'Settings.qml#hasResetChanges'});
vm.runInContext(specSource + '\nthis.settingsSubTabChangeSpec = settingsSubTabChangeSpec;', context, {filename:'SettingsWidget.qml#settingsSubTabChangeSpec'});
const has = (scope, arg) => context.hasResetChanges(scope, arg);
const spec = (tab, sub) => context.settingsSubTabChangeSpec(tab, sub);
const overrides = value => { owner.resetOverrides = value; };

// Exact keys and prefixes must be read from the sparse cache only.
overrides({weatherIconSize: 48});
assert.strictEqual(has('keys', spec(3,1)), true, 'weather Now subtab sees its changed icon setting');
assert.strictEqual(has('keys', spec(3,2)), false, 'weather Hourly subtab does not inherit a Now-only change');
overrides({weatherHourlyIntervalMinutes: 90});
assert.strictEqual(has('keys', spec(3,2)), false, 'hourly refresh interval belongs to General, not the Hourly layout subtab');
overrides({weatherHourlyCount: 8});
assert.strictEqual(has('keys', spec(3,2)), true, 'hourly layout subtab sees its own keys');
overrides({animationTimerOptionsDuration: 500});
assert.strictEqual(has('keys', spec(1,5)), true, 'timer options subtab sees options-window animation changes');
assert.strictEqual(has('keys', spec(1,4)), false, 'timer options animation does not light the timer Animations subtab');
overrides({topAppsCpuBarColor:'#123456'});
assert.strictEqual(has('keys', spec(5,2)), true, 'Top Apps subtab sees changed colors stored in nested color map');
overrides({settingsTabLabels:{weather:'Forecast'}});
assert.strictEqual(has('keys', spec(9,2)), true, 'Settings Window > Tabs detects tab labels');
assert.strictEqual(has('keys', spec(9,1)), false, 'tab labels do not light the Window subtab');
overrides({colors:{settingsBackground:'#202020'}});
assert.strictEqual(has('keys', spec(9,1)), true, 'nested settings background marks the Settings Window subtab');
overrides({moduleBlurEnabled:{settings:true}});
assert.strictEqual(has('keys', spec(9,1)), true, 'nested settings blur marks the Settings Window subtab');
overrides({colors:{topAppsCpuBarColor:'#123456'}});
const cpuSection = fs.readFileSync(path.join(base,'components/settings/sections/SettingsCpuRamSection.qml'),'utf8');
assert(cpuSection.includes('changeKeys: ({ nested: { colors: ["topAppsCpuBarColor"'), 'Top Apps color frame detects colors stored in the nested color map');

// Frame indicators opt into precise keys; headings render the marker only when modified.
assert(group.includes('property var changeKeys: null'), 'SettingsGroup exposes optional change selector');
assert(group.includes('root.settings.hasResetChanges("keys", root.changeKeys)'), 'frame marker reuses sparse override cache');
assert(group.includes('visible: root.hasHeading && root.modified'), 'frame marker only displays beside a visible heading');
for (const [file, heading] of [
  ['components/settings/sections/SettingsWeatherSection.qml','heading: "Температура комфорта"'],
  ['components/settings/sections/SettingsWeatherSection.qml','heading: "Стрелка ветра"'],
  ['components/settings/sections/SettingsTimersSection.qml','heading: "Анимация окна опций"'],
  ['components/settings/sections/SettingsCalendarSection.qml','heading: "Показ"'],
  ['components/settings/sections/SettingsWindowSection.qml','heading: "Вкладки панели настроек"'],
]) {
  assert(fs.readFileSync(path.join(base,file),'utf8').includes(heading+'\n        changeKeys:'), `${heading} has a frame-level change selector`);
}

// All Save All buttons are compact and icon-only; single-save buttons retain their floppy icon.
for (const file of saveFiles) {
  assert(!file.includes('text: "Всё"'), 'Save All no longer renders the word Всё');
  assert(file.includes('iconText: "󰆔"'), 'Save All keeps the paired-diskette glyph');
}
assert(widget.includes('modified: root.settingsSubTabHasChanges(root.currentOtherTab, index)'), 'subtabs bind modified state to their precise scope');
assert(widget.includes('width: 30\n                                    height: 30\n                                    visible: root.quickSaveProfileAvailable'), 'Save All is icon-width in the common header');

console.log('Settings subtab/frame dirty indicators and icon-only Save All: OK');
JS
