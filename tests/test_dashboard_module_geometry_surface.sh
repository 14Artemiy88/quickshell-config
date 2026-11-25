#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
const load = (name, bindings = {}) => {
  const source = read(name).replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
  const context = { ...bindings };
  vm.createContext(context);
  vm.runInContext(source, context, { filename: name });
  return context;
};

const metadata = load('js/settings/SettingsMetadata.js');
assert.deepStrictEqual(Array.from(metadata.defaultGeometry.dashboard), [-999999, -999999, 560, 0]);
assert.strictEqual(metadata.defaultModuleFrames.dashboard, true);
assert.strictEqual(metadata.defaultModuleBackgrounds.dashboard, true);
assert.strictEqual(metadata.defaultModuleBlurEnabled.dashboard, false);

const settings = read('Settings.qml');
const modules = read('components/settings/sections/SettingsModulesSection.qml');
const dashboard = read('components/Dashboard.qml');
assert.match(settings, /dashboard:\s*\[-999999,-999999,560,0\]/);
assert.match(settings, /moduleFrames:.*dashboard:true/);
assert.match(settings, /moduleBackgrounds:.*dashboard:true/);
assert.match(settings, /moduleBlurEnabled:.*dashboard:false/);
assert(modules.includes('model: settings.moduleNames'));
for (const control of ['dashboardGeometryValue(index)', 'writeDashboardGeometry(index, n)',
  'settings.moduleFrames[moduleRow.moduleName] !== false',
  'settings.moduleBackgrounds[moduleRow.moduleName] !== false',
  'settings.moduleBlurEnabled[moduleRow.moduleName] === true'])
  assert(modules.includes(control), `Modules editor exposes ${control}`);
assert(modules.includes('settings.resetDashboardModule()'));
assert(modules.includes('"dashboardModule" : "module"'));

assert(dashboard.includes('Settings.moduleMonitors || {}).dashboard'));
assert(dashboard.includes('Settings.geometry || {}).dashboard'));
assert(dashboard.includes('root.dashboardFrameVisible ? Math.max(1, Config.frameBorderWidth) : 0'));
assert(dashboard.includes('root.dashboardBackgroundVisible ? Config.settingsBackground : Config.transparent'));
assert(dashboard.includes('item: root.dashboardBlurEnabled ? drawer : null'));
assert(dashboard.includes('x: (root.layoutEditMode || (root.open && root.visibilityAnimationReady)) ? targetX : hiddenX'));
assert(dashboard.includes('y: (root.layoutEditMode || (root.open && root.visibilityAnimationReady)) ? targetY : hiddenY'));
assert(dashboard.includes('readonly property string visibilityStyle: DashboardAnimation.resolveVisibilityStyle('));
assert(dashboard.includes('height: targetHeight'));

const profiles = load('js/settings/SettingsProfiles.js');
for (const map of ['modules', 'moduleFrames', 'moduleBackgrounds', 'moduleBlurEnabled', 'moduleMonitors', 'geometry'])
  assert(profiles.profileSavePathMatches({}, 'dashboardModule', null, [map, 'dashboard']),
    `Dashboard scoped save includes ${map}.dashboard`);
assert.strictEqual(profiles.profileSavePathMatches({}, 'dashboardModule', null, ['geometry', 'notifications']), false);

const resets = load('js/settings/SettingsResets.js');
const resetOwner = {
  activeProfile: 'Work', profiles: { Work: { modules: { dashboard: true }, dashboardVisibleCards: ['today'] } },
  dashboard: false, geometry: { dashboard: [90, 80, 700, 500] },
  moduleFrames: { dashboard: false }, moduleBackgrounds: { dashboard: false },
  moduleBlurEnabled: { dashboard: true }, moduleMonitors: { dashboard: 'DISPLAY-2' },
  defaultGeometry: { dashboard: [-999999, -999999, 560, 0] },
  defaultModuleFrames: { dashboard: true }, defaultModuleBackgrounds: { dashboard: true },
  defaultModuleBlurEnabled: { dashboard: false }, defaultModules: { dashboard: true },
  defaultConfig: { dashboardVisibleCards: ['today', 'system', 'network', 'weather', 'media'],
    dashboardCardOrder: ['today', 'system', 'network', 'weather', 'media'], dashboardColumnsMode: 'auto',
    dashboardCardSizes: { today: 'compact', system: 'compact', network: 'compact', weather: 'compact', media: 'compact' } },
  expandedProfileData() { return this.profiles.Work; }, save() {}, resetUnavailable() {},
};
resets.resetDashboardModule(resetOwner, {
  dashboardVisibleCards: [], dashboardCardOrder: [], dashboardColumnsMode: 'two', dashboardCardSizes: {},
});
assert.deepStrictEqual(Array.from(resetOwner.geometry.dashboard), [-999999, -999999, 560, 0]);
assert.strictEqual(resetOwner.moduleFrames.dashboard, true);
assert.strictEqual(resetOwner.moduleBackgrounds.dashboard, true);
assert.strictEqual(resetOwner.moduleBlurEnabled.dashboard, false);
assert.strictEqual(resetOwner.moduleMonitors.dashboard, undefined);
console.log('Dashboard module geometry, frame/background/blur controls, profiles and runtime: OK');
JS
