#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const rootDir = process.argv[2];
function loadLibrary(relativePath, append = '') {
  const source = fs.readFileSync(path.join(rootDir, relativePath), 'utf8')
    .replace(/^\.pragma library\s*$/gm, '')
    .replace(/^\.import .*$/gm, '');
  const context = {};
  vm.runInNewContext(source + '\n' + append, context, { filename: relativePath });
  return context;
}
const registry = loadLibrary('js/settings/SettingsPageRegistry.js',
  'this.api = { tabDefinitions, otherPageDefinitions, pageForId, hasOtherPageId, subtabsForPageId, saveScopeForPageId };').api;
const widget = fs.readFileSync(path.join(rootDir, 'components/settings/SettingsWidget.qml'), 'utf8');
const searchController = fs.readFileSync(path.join(rootDir, 'components/settings/SettingsSearchController.qml'), 'utf8');
const navigation = fs.readFileSync(path.join(rootDir, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const definitions = Array.from(registry.tabDefinitions());
const otherPages = Array.from(registry.otherPageDefinitions());
const ids = definitions.map(page => page.id);
assert(widget.includes('property alias currentPageId: settingsNavigationController.currentPageId'), 'SettingsWidget exposes the controller-owned stable page ID');
assert(navigation.includes('property string currentPageId: "modules"'), 'navigation controller owns one stable primary page ID');
assert(!/\bcurrentTab\b|\bcurrentOtherTab\b/.test(widget), 'numeric main/other page route state is removed');
assert(!/currentPageId\s*===\s*\d+/.test(widget), 'page comparisons never use numeric indices');
assert(searchController.includes('root.host.currentPageId = entry.pageId'), 'search navigation opens the result page by ID through the host');
assert(navigation.includes('root.currentPageId = pageId'), 'sidebar navigation selects the page by ID in the controller');

const sectionDir = path.join(rootDir, 'components/settings/sections');
const sectionSources = [];
function collect(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) collect(file);
    else if (entry.name.endsWith('.qml')) sectionSources.push(fs.readFileSync(file, 'utf8'));
  }
}
collect(sectionDir);
const modules = fs.readFileSync(path.join(sectionDir, 'SettingsModulesSection.qml'), 'utf8');
const themes = fs.readFileSync(path.join(sectionDir, 'SettingsColorsSection.qml'), 'utf8');
assert(modules.includes('host.currentPageId === "modules"'), 'Modules section is keyed by its stable ID');
assert(themes.includes('host.currentPageId === "themes"'), 'Themes section is keyed by its stable ID');
for (const page of otherPages) {
  assert.strictEqual(registry.pageForId(page.id).id, page.id, `${page.id} resolves to its own definition`);
  assert.strictEqual(registry.hasOtherPageId(page.id), true, `${page.id} is an accepted route`);
  assert.deepStrictEqual(Array.from(registry.subtabsForPageId(page.id)), Array.from(page.subTabs), `${page.id} sub-tabs resolve by ID`);
  assert.strictEqual(registry.saveScopeForPageId(page.id, 0), page.saveScope, `${page.id} save scope resolves by ID`);
  assert(sectionSources.some(source => source.includes(`currentPageId === "${page.id}"`)), `${page.id} QML component is routed by ID`);
}
assert.strictEqual(registry.pageForId('unknown'), null, 'unknown page ID does not resolve');
assert.strictEqual(registry.hasOtherPageId('unknown'), false, 'unknown page ID is not routable');
assert.deepStrictEqual(Array.from(registry.subtabsForPageId('unknown')), [], 'unknown page ID has no subtabs');
assert.strictEqual(registry.saveScopeForPageId('unknown', 0), '', 'unknown page ID has no save scope');
assert.strictEqual(registry.saveScopeForPageId('general', 1), '', 'General profile subtab has no unrelated scoped save');

const resetStart = navigation.indexOf('    function resetCurrentSettingsPage() {');
const resetEnd = navigation.indexOf('\n    function setSettingsTabLabel', resetStart);
assert(resetStart >= 0 && resetEnd > resetStart, 'stable-ID reset dispatcher exists');
const resetSource = navigation.slice(resetStart, resetEnd).trim();
const resetMethods = {
  general: 'resetGeneralSettings', timers: 'resetTimerSettings', player: 'resetPlayerSettings',
  weather: 'resetWeatherSettings', cava: 'resetCavaSettings', cpuRam: 'resetCpuSettings',
  network: 'resetNetworkSettings', volume: 'resetVolumeSettings', calendar: 'resetCalendarSettings',
  settingsWindow: 'resetSettingsWindow', mopidy: 'resetMopidySettings', launcher: 'resetLauncherSettings',
  launcherSearch: 'resetLauncherSettings', launcherTabs: 'resetLauncherSettings', launcherProjects: 'resetLauncherSettings',
  launcherActions: 'resetLauncherSettings', launcherAnimation: 'resetLauncherSettings', launcherApplications: 'resetLauncherSettings',
  notifications: 'resetNotificationsSettings'
};
for (const [pageId, method] of Object.entries(resetMethods)) {
  const calls = [];
  const settings = {};
  for (const name of Object.values(resetMethods)) settings[name] = () => calls.push(name);
  const context = { root: { currentPageId: pageId }, settings };
  vm.createContext(context);
  vm.runInContext(resetSource + '\nthis.reset = resetCurrentSettingsPage;', context);
  context.reset();
  assert.deepStrictEqual(calls, [method], `${pageId} reset dispatches to the matching settings method`);
}

const specStart = navigation.indexOf('    function settingsSubTabChangeSpec(pageId, sub) {');
const specEnd = navigation.indexOf('\n    function settingsSubTabHasChanges', specStart);
assert(specStart >= 0 && specEnd > specStart, 'dirty-indicator selector accepts a page ID');
const context = {};
vm.createContext(context);
vm.runInContext(navigation.slice(specStart, specEnd).trim() + '\nthis.spec = settingsSubTabChangeSpec;', context);
for (const page of otherPages) {
  if (page.subTabs.length > 0) {
    assert(context.spec(page.id, 0) !== null, `${page.id} dirty-indicator scope resolves by ID`);
  } else if (page.id.startsWith('launcher')) {
    assert.strictEqual(registry.saveScopeForPageId(page.id, 0), 'launcher', `${page.id} still uses the shared Launcher save scope`);
  } else {
    assert.strictEqual(registry.saveScopeForPageId(page.id, 0), page.saveScope, `${page.id} keeps its own declared save scope`);
  }
}

console.log(`Settings stable page-ID routing: ${ids.length} pages and ${Object.keys(resetMethods).length} reset routes: OK`);
NODE
