#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const loadLibrary = (file, bindings = {}) => {
  const source = read(file)
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/mg, '');
  const context = { ...bindings };
  vm.createContext(context);
  vm.runInContext(source, context, { filename: file });
  return context;
};

const metadata = loadLibrary('js/settings/SettingsMetadata.js');
assert(metadata.moduleNames.includes('dashboard'), 'Dashboard is part of the persisted module list');
assert.strictEqual(metadata.moduleLabels.dashboard, 'Dashboard');
assert.strictEqual(metadata.defaultModules.dashboard, true, 'existing Dashboard behavior stays enabled by default');

const settingsQml = read('Settings.qml');
const modulesQml = read('components/settings/sections/SettingsModulesSection.qml');
const shell = read('shell.qml');
const launcher = read('components/launcher/Launcher.qml');
assert.match(settingsQml, /property bool dashboard: true/);
assert(modulesQml.includes('model: settings.moduleNames.filter(function(name) { return name !== "dashboard" })'),
  'regular module geometry editor excludes Dashboard, which is a full-screen overlay');
const dashboardRowStart = modulesQml.indexOf('id: dashboardModuleRow');
const dashboardRowEnd = modulesQml.indexOf('id: launcherModuleRow', dashboardRowStart);
assert(dashboardRowStart >= 0 && dashboardRowEnd > dashboardRowStart, 'Dashboard has its own Modules row');
const dashboardRow = modulesQml.slice(dashboardRowStart, dashboardRowEnd);
assert(dashboardRow.includes('text: "Dashboard"') && dashboardRow.includes('checked: settings.dashboard'));
assert(dashboardRow.includes('settings.dashboard = checked') && dashboardRow.includes('settings.save()'));
assert(dashboardRow.includes('settingsSearchId: "module.dashboard.enabled"'));
assert(dashboardRow.includes('saveScope("dashboardModule")'));
assert(dashboardRow.includes('settings.resetDashboardModule()'));
assert(dashboardRow.includes('canSaveScope("dashboardModule")'));
assert(dashboardRow.includes('canResetScope("dashboardModule")'));
assert(!dashboardRow.includes('SettingsNumberField') && !dashboardRow.includes('moduleFrames')
  && !dashboardRow.includes('moduleBackgrounds') && !dashboardRow.includes('moduleBlurEnabled'),
  'Dashboard does not expose fictitious geometry or regular-module surface controls');

const persistence = loadLibrary('js/settings/SettingsPersistence.js');
const snapshot = persistence.snapshotObject({
  moduleNames: metadata.moduleNames, dashboard: false, colorNames: [], weatherToken: ''
}, {});
assert.strictEqual(snapshot.modules.dashboard, false, 'Dashboard enable state is included in settings snapshots');

const applyContext = loadLibrary('js/settings/SettingsApplyState.js', {
  Schema: {
    normalizeSavedColor: value => value,
    normalizeCustomThemes: value => value || {},
  },
  Profiles: { SPARSE_FORMAT: 'sparse-v1' },
  Themes: { builtinThemeNames: ['14 Theme'], palette: () => ({}) },
});
const makeOwner = () => ({
  dashboard: true,
  moduleNames: metadata.moduleNames,
  moduleFrames: {}, moduleBackgrounds: {}, moduleBlurEnabled: {}, moduleMonitors: {},
  geometry: { notifications: [-999999, 16, 380, 0] },
  profiles: {}, customThemes: {}, activeProfile: '', activeTheme: '14 Theme',
  settingsGeometry: [0, 0, 0, 0], settingsMonitorName: '', themeStateRevision: 0,
  rebuildProfileList() {}, changed() {},
});
const config = { notificationsCardWidth: 380 };
const disabledOwner = makeOwner();
applyContext.apply(disabledOwner, config, { modules: { dashboard: false } }, metadata.moduleNames, {}, {}, [], {});
assert.strictEqual(disabledOwner.dashboard, false, 'saved disabled state is restored');
const legacyOwner = makeOwner();
applyContext.apply(legacyOwner, config, {}, metadata.moduleNames, {}, {}, [], {});
assert.strictEqual(legacyOwner.dashboard, true, 'older settings without a Dashboard key preserve the enabled default');

const profiles = loadLibrary('js/settings/SettingsProfiles.js');
assert(profiles.profileSavePathMatches({}, 'module', 'dashboard', ['modules', 'dashboard']),
  'Dashboard is included in its module-scoped profile save path');
assert(profiles.modulePathMatches(['modules', 'dashboard'], 'dashboard'));
assert(profiles.profileSavePathMatches({}, 'dashboardModule', null, ['modules', 'dashboard']),
  'combined Dashboard row scope includes the enable toggle');
for (const key of ['dashboardVisibleCards', 'dashboardCardOrder', 'dashboardColumnsMode', 'dashboardCardSizes']) {
  assert(profiles.profileSavePathMatches({}, 'dashboardModule', null, [key]),
    `combined Dashboard row scope includes ${key}`);
}
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboardModule', null, ['modules', 'networks']), false,
  'Dashboard row save must not capture unrelated module toggles');

// Exercise the same scoped-save path used by the Modules row. Dashboard edits
// and the module switch must be saved, while unrelated module edits stay dirty.
const profileBase = {
  modules: { dashboard: true, networks: true },
  dashboardVisibleCards: ['today', 'system'],
  dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media'],
  dashboardColumnsMode: 'auto',
  dashboardCardSizes: { today: 'compact' },
  settingsNavigationOrder: { groupOrder: [], pagesByGroup: {} },
};
const currentSnapshot = JSON.parse(JSON.stringify(profileBase));
currentSnapshot.modules.dashboard = false;
currentSnapshot.modules.networks = false;
currentSnapshot.dashboardVisibleCards = ['today', 'weather'];
currentSnapshot.dashboardCardOrder = ['weather', 'today', 'system', 'network', 'media'];
currentSnapshot.dashboardColumnsMode = 'two';
currentSnapshot.dashboardCardSizes = { today: 'expanded' };
const saveOwner = {
  profileDefaults: profileBase,
  profiles: { Work: {} },
  profileStorageFormat: profiles.SPARSE_FORMAT,
  activeProfile: 'Work',
  profileList: [], profilesRevision: 0, resetOverrides: {},
  normalizeSettingsNavigationOrder: value => value || profileBase.settingsNavigationOrder,
  snapshotObject: () => currentSnapshot,
  save() {},
};
assert.strictEqual(profiles.saveProfileScope(saveOwner, 'Work', 'dashboardModule'), true,
  'Dashboard row scoped Save must persist real profile differences');
assert.strictEqual(saveOwner.profiles.Work.modules.dashboard, false,
  'Dashboard enabled state is saved by the dedicated row');
assert.strictEqual(Object.prototype.hasOwnProperty.call(saveOwner.profiles.Work.modules, 'networks'), false,
  'Dashboard save does not capture unrelated module changes');
assert.deepStrictEqual(Array.from(saveOwner.profiles.Work.dashboardVisibleCards), ['today', 'weather']);
assert.deepStrictEqual(Array.from(saveOwner.profiles.Work.dashboardCardOrder), ['weather', 'today', 'system', 'network', 'media']);
assert.strictEqual(saveOwner.profiles.Work.dashboardColumnsMode, 'two');
assert.deepStrictEqual(JSON.parse(JSON.stringify(saveOwner.profiles.Work.dashboardCardSizes)), { today: 'expanded' });

const resets = loadLibrary('js/settings/SettingsResets.js');
const resetOwner = {
  activeProfile: 'Work', profiles: { Work: { modules: { dashboard: true } } }, dashboard: false,
  geometry: {}, moduleFrames: {}, moduleBackgrounds: {}, moduleBlurEnabled: {}, moduleMonitors: {},
  defaultModuleFrames: {}, defaultModuleBackgrounds: {}, defaultModuleBlurEnabled: {},
  save() {},
};
resets.resetModule(resetOwner, {}, 'dashboard');
assert.strictEqual(resetOwner.dashboard, true, 'legacy module reset still restores Dashboard from the active profile');

const dashboardResetConfig = {
  dashboardVisibleCards: [], dashboardCardOrder: [], dashboardColumnsMode: 'two', dashboardCardSizes: {},
};
const dashboardResetOwner = {
  activeProfile: 'Work', profiles: { Work: {} }, dashboard: false,
  defaultModules: { dashboard: true },
  defaultConfig: {
    dashboardVisibleCards: ['today', 'system', 'network', 'weather', 'media'],
    dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media'],
    dashboardColumnsMode: 'auto', dashboardCardSizes: {},
  },
  expandedProfileData: () => ({
    modules: { dashboard: true },
    dashboardVisibleCards: ['weather', 'media'],
    dashboardCardOrder: ['media', 'weather', 'today', 'system', 'network'],
    dashboardColumnsMode: 'one', dashboardCardSizes: { media: 'expanded' },
  }),
  save() {}, resetUnavailable() {},
};
resets.resetDashboardSettings(dashboardResetOwner, dashboardResetConfig, true);
assert.strictEqual(dashboardResetOwner.dashboard, true, 'Dashboard Modules Reset restores module enable state');
assert.deepStrictEqual(Array.from(dashboardResetConfig.dashboardVisibleCards), ['weather', 'media']);
assert.strictEqual(dashboardResetConfig.dashboardColumnsMode, 'one');
assert.deepStrictEqual(JSON.parse(JSON.stringify(dashboardResetConfig.dashboardCardSizes)), { today: 'compact', system: 'compact', network: 'compact', weather: 'compact', media: 'expanded' });

assert(shell.includes('function onDashboardChanged()') && shell.includes('shell.dashboardVisible = false'),
  'disabling Dashboard closes an already-open overlay');
assert(shell.includes('open: Settings.dashboard && shell.dashboardVisible'));
const ipc = shell.slice(shell.indexOf('target: "dashboard"'), shell.indexOf('Dashboard {', shell.indexOf('target: "dashboard"')));
assert(ipc.includes('if (Settings.dashboard)'), 'Dashboard IPC toggle/show are guarded by its module switch');
const launcherPalette = launcher.slice(launcher.indexOf('const dashboardActionScore'), launcher.indexOf('if (dashboardActionScore >= 0)'));
assert(launcherPalette.includes('Settings.dashboard && root.builtinActionEnabled("tool.dashboard")'),
  'Launcher hides its Dashboard action when the module is disabled');

console.log('Dashboard Modules toggle, persistence, legacy default, profile save/reset, Launcher and IPC guards: OK');
JS
echo 'dashboard modules toggle: OK'
