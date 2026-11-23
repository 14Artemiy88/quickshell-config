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
  const source = read(file).replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
  const context = {...bindings};
  vm.createContext(context);
  vm.runInContext(source, context, {filename: file});
  return context;
};

// Central page metadata is the single source for sidebar and search context.
const registry = loadLibrary('js/settings/SettingsPageRegistry.js');
const pages = Array.from(registry.pageMetadataCatalog());
const groups = Array.from(registry.navigationGroupDefinitions());
const rows = Array.from(registry.navigationItemsForOrder(pages.map(page => page.id), {}));
assert.strictEqual(pages.length, 22);
assert.strictEqual(groups.length, 5);
assert.strictEqual(rows.length, pages.length);
assert.strictEqual(new Set(rows.map(row => row.id)).size, pages.length);
assert(rows.every(row => groups.some(group => group.id === row.groupId)));
assert.strictEqual(pages.reduce((sum, page) => sum + page.subTabs.length, 0), 65);
assert(pages.every(page => page.keywords.length > 0 && page.subTabs.every(subtab => Array.isArray(subtab.keywords))));

const navigation = read('components/settings/SettingsNavigationController.qml');
const search = read('components/settings/SettingsSearchController.qml');
assert(navigation.includes('SettingsPageRegistry.navigationItemsForOrder('));
assert(read('components/settings/SettingsWidget.qml').includes('Config.settingsNavigationCollapsedGroups'));
assert(search.includes('SettingsPageRegistry.pageMetadataForId(activePageId)'));
assert(search.includes('subTabMetadata.keywords'));

// Navigation expansion is persisted as UI state, never as a profile override.
const persistence = loadLibrary('js/settings/SettingsPersistence.js');
const payloadOwner = {
  snapshotObject: () => ({settingsNavigationCollapsedGroups: {appearance: true, modules: false}, modules: {}, colors: {accent: '#fff'}}),
  activeProfile: '', profiles: {}, customThemes: {},
  config: {settingsNavigationCollapsedGroups: {appearance: true, modules: false}}
};
const payload = persistence.payloadObject(payloadOwner, payloadOwner.config);
assert.deepStrictEqual(JSON.parse(JSON.stringify(payload.settingsNavigationCollapsedGroups)), {appearance: true, modules: false});
assert(!Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsNavigationCollapsedGroups'));
assert(payload.managedKeys.includes('settingsNavigationCollapsedGroups'));

// CPU/RAM page scope includes all four nested Top Apps colors for Save/Reset.
const specs = navigation.match(/"cpuRam":\s*\[([\s\S]*?)\n\s*\],/);
assert(specs, 'CPU/RAM scoped change specification exists');
for (const key of ['topAppsCpuBarColor', 'topAppsCpuBarTrackColor', 'topAppsRamBarColor', 'topAppsRamBarTrackColor'])
  assert(specs[1].includes(key), `${key} remains in CPU/RAM nested color scope`);
const resets = read('js/settings/SettingsResets.js');
for (const key of ['topAppsCpuBarColor', 'topAppsCpuBarTrackColor', 'topAppsRamBarColor', 'topAppsRamBarTrackColor'])
  assert(resets.includes(key), `${key} is handled by profile reset`);

// Component colors are disjoint from global theme colors and are preserved by theme operations.
const metadata = loadLibrary('js/settings/SettingsMetadata.js');
const managed = Array.from(metadata.themeManagedColorNames);
const independent = Array.from(metadata.independentThemeColorNames);
const allColors = Array.from(metadata.colorNames);
assert.strictEqual(managed.length + independent.length, allColors.length);
assert.strictEqual(new Set([...managed, ...independent]).size, allColors.length);
assert.deepStrictEqual([...managed, ...independent].sort(), allColors.slice().sort());
const themeManager = read('js/settings/SettingsThemeManager.js');
assert(themeManager.includes('themeManagedColorNames'));
assert(themeManager.includes('owner.independentThemeColorNames'));

// Parent-toggle behavior and shared disabled presentation remain integrated.
const dependentTest = read('tests/test_settings_dependent_controls_consistency.sh');
assert(dependentTest.includes('topAppsBarColorsMorph'));
assert(dependentTest.includes('playerProgressOptionsMorph'));
assert(dependentTest.includes('volumeStreamTrackOffsetMorph'));
for (const file of [
  'components/settings/primitives/SettingsInputField.qml',
  'components/settings/primitives/SettingsComboBox.qml',
  'components/settings/primitives/SettingsCheckBox.qml'
]) assert(read(file).includes('opacity: root.enabled ? 1 : 0.55'), `${file} retains shared disabled-state appearance`);

// Keep the key regression suites registered exactly once in the release gate.
const check = read('CHECK.sh');
for (const name of [
  'test_settings_navigation_collapsed_persistence.sh',
  'test_top_apps_bar_reset_scope.sh',
  'test_settings_unified_page_metadata.sh',
  'test_settings_search_synonyms.sh',
  'test_settings_dependent_controls_consistency.sh',
  'test_theme_independent_colors_are_not_palette_state.sh'
]) {
  const matches = check.match(new RegExp(`tests/${name.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&')}`, 'g')) || [];
  assert.strictEqual(matches.length, 1, `${name} is registered exactly once`);
}
console.log('Settings final integration: 5 groups, 22 pages, 65 subtabs, navigation UI state, search, Top Apps reset, dependent controls and theme/profile ownership: OK');
JS
