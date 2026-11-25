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
const navigation = fs.readFileSync(path.join(base, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const group = fs.readFileSync(path.join(base, 'components/settings/primitives/SettingsGroup.qml'), 'utf8');
const pageHost = fs.readFileSync(path.join(base, 'components/settings/SettingsPageHost.qml'), 'utf8');
const main = fs.readFileSync(path.join(base, 'components/settings/SettingsWidget.qml'), 'utf8');
// QML rejects duplicate methods on a single Item at load time.
assert.strictEqual((navigation.match(/^\s*function settingsSubTabChangeSpec\(/gm) || []).length, 1, 'navigation controller has exactly one settingsSubTabChangeSpec method');
assert.strictEqual((navigation.match(/^\s*function settingsSubTabHasChanges\(/gm) || []).length, 1, 'navigation controller has exactly one settingsSubTabHasChanges method');
assert(widget.includes('function settingsSubTabHasChanges(pageId, sub) { return settingsNavigationController.settingsSubTabHasChanges(pageId, sub) }'), 'SettingsWidget preserves its host API as a delegate');

const saveFiles = [
  pageHost,
  fs.readFileSync(path.join(base, 'components/settings/sections/SettingsModulesSection.qml'), 'utf8'),
  fs.readFileSync(path.join(base, 'components/settings/sections/SettingsColorsSection.qml'), 'utf8'),
];

const hs = settingsQml.indexOf('    function hasResetChanges(scope, argument) {');
const he = settingsQml.indexOf('\n    function activeProfileData()', hs);
assert(hs >= 0 && he > hs, 'extract hasResetChanges implementation');
const hasSource = settingsQml.slice(hs, he).trim();
const ss = navigation.indexOf('    function settingsSubTabChangeSpec(pageId, sub) {');
const se = navigation.indexOf('\n    function settingsSubTabHasChanges', ss);
assert(ss >= 0 && se > ss, 'extract subtab scope mapping');
const specSource = navigation.slice(ss, se).trim();
const owner = {activeProfile:'Work', profiles:{Work:{}}, resetOverrides:{}, colorNames:['accent','settingsBackground','settingsBorder']};
const context = {root:owner, activeProfile:owner.activeProfile, profiles:owner.profiles, colorNames:owner.colorNames};
vm.createContext(context);
vm.runInContext(hasSource + '\nthis.hasResetChanges = hasResetChanges;', context, {filename:'Settings.qml#hasResetChanges'});
vm.runInContext(specSource + '\nthis.settingsSubTabChangeSpec = settingsSubTabChangeSpec;', context, {filename:'SettingsNavigationController.qml#settingsSubTabChangeSpec'});
const has = (scope, arg) => context.hasResetChanges(scope, arg);
const spec = (tab, sub) => context.settingsSubTabChangeSpec(tab, sub);
const overrides = value => { owner.resetOverrides = value; };

// Exact keys and prefixes must be read from the sparse cache only.
overrides({weatherIconSize: 48});
assert.strictEqual(has('keys', spec('weather',1)), true, 'weather Now subtab sees its changed icon setting');
assert.strictEqual(has('keys', spec('weather',2)), false, 'weather Hourly subtab does not inherit a Now-only change');
overrides({weatherHourlyIntervalMinutes: 90});
assert.strictEqual(has('keys', spec('weather',2)), false, 'hourly refresh interval belongs to General, not the Hourly layout subtab');
overrides({weatherHourlyCount: 8});
assert.strictEqual(has('keys', spec('weather',2)), true, 'hourly layout subtab sees its own keys');
overrides({animationTimerOptionsDuration: 500});
assert.strictEqual(has('keys', spec('timers',5)), true, 'timer options subtab sees options-window animation changes');
overrides({timerOptionsDurationIconSize: 28});
assert.strictEqual(has('keys', spec('timers',5)), true, 'timer options subtab sees action icon appearance changes');
assert.strictEqual(has('keys', spec('timers',4)), false, 'timer options animation does not light the timer Animations subtab');
overrides({topAppsCpuBarColor:'#123456'});
assert.strictEqual(has('keys', spec('cpuRam',2)), true, 'Top Apps subtab sees changed colors stored in nested color map');
overrides({settingsTabLabels:{weather:'Forecast'}});
assert.strictEqual(has('keys', spec('settingsWindow',2)), true, 'Settings Window > Tabs detects tab labels');
assert.strictEqual(has('keys', spec('settingsWindow',1)), false, 'tab labels do not light the Window subtab');
overrides({colors:{settingsBackground:'#202020'}});
assert.strictEqual(has('keys', spec('settingsWindow',1)), true, 'nested settings background marks the Settings Window subtab');
overrides({moduleBlurEnabled:{settings:true}});
assert.strictEqual(has('keys', spec('settingsWindow',1)), true, 'nested settings blur marks the Settings Window subtab');
// Shared Launcher disabled-action array must light only the matching subtab.
overrides({launcherDisabledBuiltinActions:['tab.apps']});
assert.strictEqual(has('keys', spec('launcherActions',0)), true, 'Launcher transitions subtab sees its own disabled tab action');
assert.strictEqual(has('keys', spec('launcherActions',1)), false, 'Launcher tools subtab ignores a transitions-only change');
overrides({launcherDisabledBuiltinActions:['tool.emoji']});
assert.strictEqual(has('keys', spec('launcherActions',0)), false, 'Launcher transitions subtab ignores a tools-only change');
assert.strictEqual(has('keys', spec('launcherActions',1)), true, 'Launcher tools subtab sees its own disabled tool');
overrides({launcherDisabledBuiltinActions:['tab.network','tool.wallpapers']});
assert.strictEqual(has('keys', spec('launcherActions',0)), true, 'Launcher transitions subtab detects its entries in a mixed override');
assert.strictEqual(has('keys', spec('launcherActions',1)), true, 'Launcher tools subtab detects its entries in a mixed override');
overrides({launcherDisabledBuiltinActions:[]});
assert.strictEqual(has('keys', spec('launcherActions',0)), false, 'empty disabled-action array does not mark transitions');
assert.strictEqual(has('keys', spec('launcherActions',1)), false, 'empty disabled-action array does not mark tools');
overrides({colors:{topAppsCpuBarColor:'#123456'}});
const cpuSection = fs.readFileSync(path.join(base,'components/settings/sections/SettingsCpuRamSection.qml'),'utf8');
assert(cpuSection.includes('changeKeys: ({ nested: { colors: ["topAppsCpuBarColor"'), 'Top Apps color frame detects colors stored in the nested color map');
const launcherSection = fs.readFileSync(path.join(base,'components/settings/sections/SettingsLauncherSection.qml'),'utf8');
assert((launcherSection.match(/changeKeys: \(\{ arrayContains: \{ launcherDisabledBuiltinActions:/g) || []).length === 2, 'Launcher built-in frames use separate action-array selectors');

// Frame indicators opt into precise keys; headings render the marker only when modified.
assert(group.includes('property var changeKeys: null'), 'SettingsGroup exposes optional change selector');
assert(group.includes('root.settings.hasResetChanges("keys", root.changeKeys)'), 'frame marker reuses sparse override cache');
assert(group.includes('visible: root.hasHeading && root.modified'), 'frame marker only displays beside a visible heading');
for (const [file, heading] of [
  ['components/settings/sections/SettingsWeatherSection.qml','heading: "Температура комфорта"'],
  ['components/settings/sections/SettingsWeatherSection.qml','heading: "Стрелка ветра"'],
  ['components/settings/sections/SettingsTimersSection.qml','heading: "Анимация окна опций"'],
  ['components/settings/sections/SettingsTimersSection.qml','heading: "Иконки окна опций"'],
  ['components/settings/sections/SettingsCalendarSection.qml','heading: "Показ"'],
  ['components/settings/sections/SettingsWindowSection.qml','text: "Вкладки панели настроек"'],
]) {
  const source = fs.readFileSync(path.join(base,file),'utf8');
  if (file.endsWith('SettingsWindowSection.qml') && heading.includes('Вкладки панели')) {
    assert(source.includes('settingsWindowColumn.settings.hasResetChanges("keys", ({ keys: ["settingsNavigationOrder", "settingsTabLabels"] }))'), 'tab editor keeps one shared dirty marker for the complete grouped editor');
  } else {
    assert(source.includes(heading+'\n        changeKeys:'), `${heading} has a frame-level change selector`);
  }
}

// All Save All buttons are compact and icon-only; single-save buttons retain their floppy icon.
for (const file of saveFiles) {
  assert(!file.includes('text: "Всё"'), 'Save All no longer renders the word Всё');
  assert(file.includes('iconText: "󰆔"'), 'Save All keeps the paired-diskette glyph');
}
assert(pageHost.includes('modified: root.host && root.host.settingsSubTabHasChanges(root.host.currentPageId, index)'), 'subtabs bind modified state to their precise scope');
assert(pageHost.includes('SettingsSaveButton {\n                    actionAvailable: root.host && root.host.quickSaveProfileAvailable'), 'Save All uses the shared action primitive in the common header');
const savePrimitive = fs.readFileSync(path.join(base, 'components/settings/primitives/SettingsSaveButton.qml'), 'utf8');
assert(savePrimitive.includes('width: 30\n    height: 30'), 'shared Save action keeps the compact icon-button dimensions');

console.log('Settings subtab/frame dirty indicators and icon-only Save All: OK');
JS
