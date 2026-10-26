#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
function loadLibrary(relativePath, appended = '') {
  const source = fs.readFileSync(path.join(root, relativePath), 'utf8')
    .replace(/^\.pragma library\s*$/gm, '')
    .replace(/^\.import .*$/gm, '');
  const context = {};
  vm.runInNewContext(source + '\n' + appended, context, { filename: relativePath });
  return context;
}
const apply = loadLibrary('js/settings/SettingsApplyCore.js',
  'this.api = { normalizeSettingsTabOrder, normalizeSettingsTabLabels, SETTINGS_TAB_IDS, DEFAULT_SETTINGS_TAB_LABELS };');
const ids = ['modules','themes','general','timers','player','mopidy','weather','cava','cpuRam','network','volume','calendar','launcher','settingsWindow'];
assert.deepStrictEqual(Array.from(apply.api.SETTINGS_TAB_IDS), ids);

// Keep all duplicated registries aligned so a future tab cannot accidentally
// be editable but missing from navigation, persistence, or default labels.
const widgetSource = fs.readFileSync(path.join(root, 'components/settings/SettingsWidget.qml'), 'utf8');
const configSource = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaultsSource = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const definitionBlock = widgetSource.match(/readonly property var settingsTabDefinitions: \[([\s\S]*?)\n    \]/);
assert(definitionBlock, 'settings tab definition registry must exist');
assert(widgetSource.includes('if (typeof saved[i] !== "string") continue'), 'UI path must reject malformed tab IDs before coercion');
const widgetIds = Array.from(definitionBlock[1].matchAll(/id: "([A-Za-z0-9]+)"/g), match => match[1]);
assert.deepStrictEqual(widgetIds, ids, 'sidebar definitions match normalized tab IDs');
const otherBlock = widgetSource.match(/readonly property var otherTabSettingsIds: \[([^\]]*)\]/);
assert(otherBlock, 'other tab route registry must exist');
const otherIds = Array.from(otherBlock[1].matchAll(/"([A-Za-z0-9]+)"/g), match => match[1]);
assert.deepStrictEqual(otherIds.slice().sort(), ids.filter(id => id !== 'modules' && id !== 'themes').slice().sort(), 'every non-core tab has exactly one content route');
const configOrder = configSource.match(/property var settingsTabOrder: \[([^\]]*)\]/);
assert(configOrder, 'Config tab defaults must exist');
assert.deepStrictEqual(Array.from(configOrder[1].matchAll(/"([A-Za-z0-9]+)"/g), match => match[1]), ids, 'Config default order matches the supported tab IDs');
const configLabelBlock = configSource.match(/property var settingsTabLabels: \(\{([\s\S]*?)\}\)/);
assert(configLabelBlock, 'Config tab labels must exist');
const configLabelIds = Array.from(configLabelBlock[1].matchAll(/([A-Za-z0-9]+)\s*:/g), match => match[1]);
assert.deepStrictEqual(configLabelIds, ids, 'Config labels match the supported tab IDs');
const defaultLabelBlock = defaultsSource.match(/settingsTabLabels: \(\{([\s\S]*?)\}\)/);
assert(defaultLabelBlock, 'profile defaults must define tab labels');
const defaultLabelIds = Array.from(defaultLabelBlock[1].matchAll(/([A-Za-z0-9]+)\s*:/g), match => match[1]);
assert.deepStrictEqual(defaultLabelIds, ids, 'profile default labels match supported tab IDs');

const normalizedOrder = apply.api.normalizeSettingsTabOrder(vm.runInContext("['launcher','launcher','bad-tab',null,3,{toString:null,valueOf:null},'settingsWindow']", apply));
assert.strictEqual(normalizedOrder.length, ids.length, 'all known tabs remain present');
assert(!normalizedOrder.includes('[object Object]'), 'objects and non-string values are rejected without coercion');
assert.strictEqual(new Set(normalizedOrder).size, ids.length, 'normalized order contains no duplicates');
assert.deepStrictEqual(Array.from(normalizedOrder.slice(0, 2)), ['launcher','settingsWindow'], 'valid saved order is preserved');
assert.deepStrictEqual(Array.from(apply.api.normalizeSettingsTabOrder(vm.runInContext('({})', apply))), ids, 'non-array order falls back to defaults');
assert.deepStrictEqual(Array.from(apply.api.normalizeSettingsTabOrder(vm.runInContext('([])', apply))), ids, 'empty order fills all defaults');

const defaults = apply.api.DEFAULT_SETTINGS_TAB_LABELS;
const labels = apply.api.normalizeSettingsTabLabels(
  vm.runInContext("({ general: '  Рабочее  ', themes: { invalid: true }, launcher: 'L'.repeat(50), staleTab: 'Stale' })", apply),
  vm.runInContext("({ modules: '  My Modules ', themes: 'Old Theme Name', mopidy: ['invalid'], staleTab: 'unknown' })", apply)
);
assert.strictEqual(labels.general, 'Рабочее', 'labels are trimmed');
assert.strictEqual(labels.modules, 'My Modules', 'partial label update preserves valid current labels');
assert.strictEqual(labels.themes, defaults.themes, 'malformed explicitly supplied label falls back to default');
assert.strictEqual(labels.mopidy, defaults.mopidy, 'malformed current label falls back to default');
assert.strictEqual(labels.launcher, 'L'.repeat(32), 'labels are length-limited');
assert.strictEqual(labels.staleTab, undefined, 'unsupported labels are removed');
assert.strictEqual(labels.settingsWindow, defaults.settingsWindow, 'missing label receives default');

// Exercise the real profile serializer with tab state included in snapshots.
const profiles = loadLibrary('js/settings/SettingsProfiles.js', 'this.api = { saveProfile, loadProfile, SPARSE_FORMAT };');
const defaultOrder = ids.slice();
const defaultLabels = JSON.parse(JSON.stringify(defaults));
const owner = {
  profileDefaults: { settingsTabOrder: defaultOrder, settingsTabLabels: defaultLabels },
  currentOrder: defaultOrder.slice(), currentLabels: JSON.parse(JSON.stringify(defaultLabels)),
  profiles: {}, activeProfile: '', profileStorageFormat: '', profileList: [], profilesRevision: 0,
  snapshotObject() { return { settingsTabOrder: this.currentOrder.slice(), settingsTabLabels: JSON.parse(JSON.stringify(this.currentLabels)) }; },
  applyObject(value) { this.currentOrder = value.settingsTabOrder.slice(); this.currentLabels = JSON.parse(JSON.stringify(value.settingsTabLabels)); },
  save() { this.saveCount = (this.saveCount || 0) + 1; }
};
owner.currentOrder = ['launcher','modules', ...ids.filter(id => !['launcher','modules'].includes(id))];
owner.currentLabels = { ...defaultLabels, general: 'Workspace', launcher: 'Tools' };
assert.strictEqual(profiles.api.saveProfile(owner, 'Custom'), true);
owner.currentOrder = defaultOrder.slice();
owner.currentLabels = JSON.parse(JSON.stringify(defaultLabels));
assert.strictEqual(profiles.api.saveProfile(owner, 'Default'), true);
owner.currentOrder = ['themes','modules', ...ids.filter(id => !['themes','modules'].includes(id))];
owner.currentLabels.general = 'Temporary';
assert.strictEqual(profiles.api.loadProfile(owner, 'Custom'), true);
assert.deepStrictEqual(Array.from(owner.currentOrder), ['launcher','modules', ...ids.filter(id => !['launcher','modules'].includes(id))]);
assert.strictEqual(owner.currentLabels.general, 'Workspace');
assert.strictEqual(owner.currentLabels.launcher, 'Tools');
assert.strictEqual(profiles.api.loadProfile(owner, 'Default'), true);
assert.deepStrictEqual(Array.from(owner.currentOrder), ids, 'loading a profile with default order removes another profile order');
assert.strictEqual(owner.currentLabels.general, defaults.general, 'loading a profile with default labels removes stale custom labels');
assert.strictEqual(owner.currentLabels.launcher, defaults.launcher);

// Verify the settings.json persistence payload records changed tab labels/order
// as sparse overrides and clears them again when restored to application defaults.
const persistence = loadLibrary('js/settings/SettingsPersistence.js', 'this.api = { payloadObject };');
const storageOwner = {
  profileDefaults: { settingsTabOrder: ids.slice(), settingsTabLabels: JSON.parse(JSON.stringify(defaults)) },
  activeProfile: '', profiles: {}, customThemes: {}, weatherToken: '',
  currentOrder: ['launcher','modules', ...ids.filter(id => !['launcher','modules'].includes(id))],
  currentLabels: { ...JSON.parse(JSON.stringify(defaults)), general: 'Workspace' },
  snapshotObject() { return { settingsTabOrder: this.currentOrder.slice(), settingsTabLabels: JSON.parse(JSON.stringify(this.currentLabels)), weatherToken: '' }; }
};
storageOwner.expandedProfileData = () => null;
let payload = persistence.api.payloadObject(storageOwner, {});
assert.deepStrictEqual(Array.from(payload.profileOverrides.settingsTabOrder), storageOwner.currentOrder, 'order is written to settings.json overrides');
assert.strictEqual(payload.profileOverrides.settingsTabLabels.general, 'Workspace', 'custom label is written to settings.json overrides');
assert.strictEqual(payload.profileOverrides.settingsTabLabels.modules, undefined, 'unchanged labels stay sparse');
let expanded = null;
const settingsPersistence = loadLibrary('js/settings/SettingsProfiles.js', 'this.api = { expandStoredSettings };');
expanded = settingsPersistence.api.expandStoredSettings(storageOwner, payload);
assert.deepStrictEqual(Array.from(expanded.settingsTabOrder), storageOwner.currentOrder, 'startup expansion restores order');
assert.strictEqual(expanded.settingsTabLabels.general, 'Workspace', 'startup expansion restores custom labels');
storageOwner.currentOrder = ids.slice();
storageOwner.currentLabels = JSON.parse(JSON.stringify(defaults));
payload = persistence.api.payloadObject(storageOwner, {});
assert.strictEqual(payload.profileOverrides.settingsTabOrder, undefined, 'default order removes stale override');
assert.strictEqual(payload.profileOverrides.settingsTabLabels, undefined, 'default labels remove stale override');
expanded = settingsPersistence.api.expandStoredSettings(storageOwner, payload);
assert.deepStrictEqual(Array.from(expanded.settingsTabOrder), ids, 'defaults restore after overrides are removed');
assert.strictEqual(expanded.settingsTabLabels.general, defaults.general);
console.log('settings tabs: malformed-data normalization, profile round-trip, and settings.json persistence: OK');
NODE
