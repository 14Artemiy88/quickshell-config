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
  config: {settingsNavigationCollapsedGroups: {appearance: true, modules: false}, settingsLastActivePageId: 'weather'}
};
const payload = persistence.payloadObject(payloadOwner, payloadOwner.config);
assert.deepStrictEqual(JSON.parse(JSON.stringify(payload.settingsNavigationCollapsedGroups)), {appearance: true, modules: false});
assert(!Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsNavigationCollapsedGroups'));
assert(payload.managedKeys.includes('settingsNavigationCollapsedGroups'));
assert.strictEqual(payload.settingsLastActivePageId, 'weather', 'last selected page persists as root-level UI state');
assert(!Object.prototype.hasOwnProperty.call(payload.profileOverrides, 'settingsLastActivePageId'), 'last active page remains outside profiles');

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

// Shared Save/Reset primitives must remain connected to page and nested scopes.
const pageHost = read('components/settings/SettingsPageHost.qml');
const saveButton = read('components/settings/primitives/SettingsSaveButton.qml');
const resetButton = read('components/settings/primitives/SettingsResetButton.qml');
const modulesSection = read('components/settings/sections/SettingsModulesSection.qml');
const themesSection = read('components/settings/sections/SettingsColorsSection.qml');
assert(saveButton.includes('property string iconText: "\\uf0c7"'));
assert(saveButton.includes('iconText: root.iconText'));
assert(saveButton.includes('SettingsButton {'));
assert(pageHost.includes('SettingsSaveButton {') && pageHost.includes('SettingsResetButton {'));
assert(pageHost.includes('root.host.profileController.saveScope(root.host.currentPageSaveScope)'));
assert(pageHost.includes('root.host.resetCurrentSettingsPage()'));
assert(pageHost.includes('profileController.canResetScope(root.host.currentPageSaveScope)'));
assert(resetButton.includes('visible: enabled && actionAvailable'));
assert(modulesSection.includes('host.profileController.saveScope("module", moduleRow.moduleName)'));
assert(themesSection.includes('host.profileController.saveScope("colors", modelData.colors)'));

// Navigation-order editor uses a single settingsWindow page-level dirty/save/reset scope.
const settingsWindow = read('components/settings/sections/SettingsWindowSection.qml');
assert(settingsWindow.includes('hasResetChanges("keys", ({ keys: ["settingsNavigationOrder", "settingsTabLabels"] }))'));
assert(navigation.includes('"settingsWindow": [') && navigation.includes('"settingsNavigationOrder", "settingsTabLabels"'));

// Search counters and match explanations stay consistent between wide and compact navigation.
const tabBase = read('components/settings/primitives/SettingsTabBase.qml');
const navigationView = read('components/settings/SettingsNavigation.qml');
assert(tabBase.includes('Config.settingsUiSize(Config.settingsSearchMatchCountFontSize)'));
assert(tabBase.includes('ToolTip.text: root.settingsSearchMatched && root.settingsSearchMatchHint.length > 0'));
assert(navigationView.includes('root.compactNavigation') && navigationView.includes('Math.max(7, Config.settingsSearchMatchCountFontSize - 1)'));
assert(search.includes('SettingsSearch.explainMatch(entry, root.settingsSearchQuery)'));

// Keep the key regression suites registered exactly once in the release gate.
const check = read('CHECK.sh');
for (const name of [
  'test_settings_navigation_collapsed_persistence.sh',
  'test_settings_last_active_page_persistence.sh',
  'test_top_apps_bar_reset_scope.sh',
  'test_settings_unified_page_metadata.sh',
  'test_settings_search_synonyms.sh',
  'test_settings_dependent_controls_consistency.sh',
  'test_settings_save_button_primitive.sh',
  'test_settings_reset_button_primitive.sh',
  'test_profile_management_guardrails.sh',
  'test_settings_theme_editor_morph_batch.sh',
  'test_settings_ui_snapshot_preserves_unknown_fields.sh',
  'test_settings_focus_restore_page_transitions.sh',
  'test_theme_independent_colors_are_not_palette_state.sh'
]) {
  const matches = check.match(new RegExp(`tests/${name.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&')}`, 'g')) || [];
  assert.strictEqual(matches.length, 1, `${name} is registered exactly once`);
}
console.log('Settings final integration: 5 groups, 22 pages, 65 subtabs, navigation, focus/search, shared Save/Reset, profile/theme ownership and persistence: OK');
JS
