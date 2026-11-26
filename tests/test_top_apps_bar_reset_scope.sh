#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const settingsQml = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
const resetSource = fs.readFileSync(path.join(root, 'js/settings/SettingsResets.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '');
const profilesSource = fs.readFileSync(path.join(root, 'js/settings/SettingsProfiles.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '');
const sections = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsCpuRamSection.qml'), 'utf8');
const navigation = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const host = fs.readFileSync(path.join(root, 'components/settings/SettingsPageHost.qml'), 'utf8');
const widget = fs.readFileSync(path.join(root, 'components/settings/SettingsWidget.qml'), 'utf8');

// Extract and execute the real sparse-override visibility function.
const start = settingsQml.indexOf('    function hasResetChanges(scope, argument) {');
const end = settingsQml.indexOf('\n    function activeProfileData()', start);
assert(start >= 0 && end > start, 'extract the actual hasResetChanges implementation');
const visibilityContext = {
  root: { resetOverrides: { colors: { topAppsCpuBarColor: '#112233' } } },
  activeProfile: 'Work', profiles: { Work: {} }, colorNames: []
};
vm.createContext(visibilityContext);
vm.runInContext(settingsQml.slice(start, end) + '\nthis.hasResetChanges = hasResetChanges;', visibilityContext);
assert.strictEqual(visibilityContext.hasResetChanges('cpu'), true,
  'CPU page-level Save/Reset visibility sees Top Apps colors in the nested colors map');

// Run the actual CPU reset helper and ensure it restores only its four palette keys.
const resetContext = {};
vm.createContext(resetContext);
vm.runInContext(resetSource + '\nthis.resetCpuSettings = resetCpuSettings;', resetContext);
const baselineColors = {
  topAppsCpuBarColor: '#00cccc', topAppsCpuBarTrackColor: '#4d006666',
  topAppsRamBarColor: '#3daee9', topAppsRamBarTrackColor: '#4d006666',
  text: '#ffffff'
};
const profile = { colors: baselineColors };
const config = {
  topAppsCpuBarColor: '#112233', topAppsCpuBarTrackColor: '#223344',
  topAppsRamBarColor: '#334455', topAppsRamBarTrackColor: '#445566', text: '#abcdef'
};
const owner = {
  activeProfile: 'Work', profiles: { Work: profile },
  resetUnavailable(message) { throw new Error(message); },
  save() { this.saveCount = (this.saveCount || 0) + 1; }
};
resetContext.resetCpuSettings(owner, config);
for (const key of Object.keys(baselineColors).filter(key => key.startsWith('topApps'))) {
  assert.strictEqual(config[key], baselineColors[key], `${key} is restored from the active profile`);
}
assert.strictEqual(config.text, '#abcdef', 'CPU reset leaves unrelated palette colors untouched');
assert.strictEqual(owner.saveCount, 1, 'CPU reset queues one persistence save');

// The page reset action routes through resetCpuSettings and exposes the page scope.
assert(widget.includes('SettingsPageRegistry.saveScopeForPageId(\n        root.currentPageId, root.currentPageSubTabIndex)'),
  'SettingsWidget resolves the active page save scope from its stable page ID');
assert(widget.includes('profileController.canResetScope(root.currentPageSaveScope)'),
  'page-level Reset availability follows the active page scope');
assert(host.includes('showResetButton: root.host && root.host.currentPageResetAvailable'),
  'page header consumes the host-computed reset availability');
assert(navigation.includes('case "cpuRam": settings.resetCpuSettings(); break'),
  'CPU/RAM page Reset dispatches to resetCpuSettings');
assert(sections.includes('changeKeys: ({ nested: { colors: ["topAppsCpuBarColor"'),
  'Top Apps color group tracks the four nested palette overrides');

// Scoped profile Save must own those nested color paths as well.
const saveStart = profilesSource.indexOf('function profileSavePathMatches(owner, scope, argument, path) {');
const saveEnd = profilesSource.indexOf('\nfunction currentValueAtPath', saveStart);
assert(saveStart >= 0 && saveEnd > saveStart, 'extract profileSavePathMatches');
const saveContext = {};
vm.createContext(saveContext);
vm.runInContext(profilesSource.slice(saveStart, saveEnd) + '\nthis.profileSavePathMatches = profileSavePathMatches;', saveContext);
for (const key of Object.keys(baselineColors).filter(key => key.startsWith('topApps'))) {
  assert.strictEqual(saveContext.profileSavePathMatches({}, 'cpu', undefined, ['colors', key]), true,
    `CPU scoped Save owns nested ${key}`);
}
assert.strictEqual(saveContext.profileSavePathMatches({}, 'cpu', undefined, ['colors', 'text']), false,
  'CPU scoped Save does not absorb unrelated palette colors');
console.log('Top Apps bar colors: CPU page reset visibility, scoped reset, and scoped save: OK');
NODE
