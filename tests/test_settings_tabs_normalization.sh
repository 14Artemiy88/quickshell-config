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
const ids = ['modules','dashboard','themes','general','timers','player','mopidy','weather','cava','cpuRam','network','volume','calendar','launcher','launcherSearch','launcherTabs','launcherProjects','launcherActions','launcherAnimation','launcherApplications','notifications','settingsWindow'];
assert.deepStrictEqual(Array.from(apply.api.SETTINGS_TAB_IDS), ids);

// Keep all duplicated registries aligned so a future tab cannot accidentally
// be editable but missing from navigation, persistence, or default labels.
const widgetSource = fs.readFileSync(path.join(root, 'components/settings/SettingsWidget.qml'), 'utf8');
const navigationSource = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const configSource = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaultsSource = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const registrySource = loadLibrary('js/settings/SettingsPageRegistry.js',
  'this.api = { tabDefinitions, otherPageDefinitions, pageForId, hasOtherPageId, subtabsForPageId, saveScopeForPageId };');
const definitions = Array.from(registrySource.api.tabDefinitions());
const otherPages = Array.from(registrySource.api.otherPageDefinitions());
assert(navigationSource.includes('SettingsPageRegistry.tabDefinitions()'), 'navigation controller must consume the page registry');
assert(navigationSource.includes('SettingsPageRegistry.hasOtherPageId('), 'navigation routes must validate stable page IDs');
assert(navigationSource.includes('SettingsPageRegistry.subtabsForPageId('), 'subtab metadata must be resolved by stable page ID');
assert(widgetSource.includes('SettingsPageRegistry.saveScopeForPageId('), 'save scopes must be resolved by stable page ID');
assert(navigationSource.includes('if (typeof saved[i] !== "string") continue'), 'navigation path must reject malformed tab IDs before coercion');
assert(widgetSource.includes('property alias currentPageId: settingsNavigationController.currentPageId'), 'SettingsWidget exposes stable page state');
assert(navigationSource.includes('property string currentPageId: "modules"'), 'navigation controller owns primary page state');
assert(!/\bcurrentTab\b|\bcurrentOtherTab\b/.test(widgetSource), 'numeric primary page state is fully removed');
assert(!/currentOtherTab/.test(fs.readFileSync(path.join(root, 'components/settings/sections/SettingsCalendarSection.qml'), 'utf8')), 'content components no longer route by numeric page index');
assert(registrySource.api.hasOtherPageId('notifications'), 'known page IDs resolve');
assert(registrySource.api.hasOtherPageId('dashboard'), 'Dashboard settings page resolves');
assert.strictEqual(registrySource.api.saveScopeForPageId('dashboard', 0), 'dashboard', 'Dashboard cards have an independent profile scope');
assert(!registrySource.api.hasOtherPageId('not-a-page'), 'unknown page IDs are rejected');
const widgetIds = definitions.map(item => item.id);
assert.deepStrictEqual(widgetIds, ids, 'sidebar definitions match normalized tab IDs');
const otherIds = otherPages.map(page => page.id);
assert.deepStrictEqual(otherIds.slice().sort(), ids.filter(id => id !== 'modules' && id !== 'themes').slice().sort(), 'every non-core tab has exactly one content route');
assert.deepStrictEqual(otherPages.map(page => page.id), otherIds, 'page metadata order matches route order');
assert.deepStrictEqual(otherPages.map(page => page.saveScope), ['dashboard','general','timer','player','weather','cava','cpu','network','volume','calendar','settingsWindow','mopidy','launcher','launcher','launcher','launcher','launcher','launcher','launcher','notifications'], 'page save scopes remain aligned with their stable IDs');
for (let i = 0; i < otherPages.length; i++)
  assert.strictEqual(registrySource.api.saveScopeForPageId(otherPages[i].id, 0), otherPages[i].saveScope, `page ${otherPages[i].id} resolves its own save scope`);
assert(otherPages.every(page => Array.isArray(page.subTabs)), 'each registered page declares its subtab list');
assert.deepStrictEqual(Array.from(registrySource.api.subtabsForPageId('launcher')), ['Общее', 'Навигация', 'Оформление', 'Поиск'], 'Launcher general page contains compact logical subtabs');
assert.deepStrictEqual(Array.from(registrySource.api.subtabsForPageId('launcherSearch')), ['Приложения', 'Действия', 'Схемы', 'Обои'], 'Launcher search options are split by search source');
assert.deepStrictEqual(Array.from(registrySource.api.subtabsForPageId('launcherActions')), ['Переходы', 'Инструменты', 'Пользовательские'], 'built-in and custom actions have independent subtabs');
for (const id of ['launcherTabs', 'launcherProjects', 'launcherAnimation', 'launcherApplications']) assert.deepStrictEqual(Array.from(registrySource.api.subtabsForPageId(id)), [], `${id} is a direct page without extra subtabs`);
assert.deepStrictEqual(Array.from(registrySource.api.subtabsForPageId('notifications')), ['Поведение', 'Внешний вид', 'Размещение', 'Анимация'], 'notification animation subtab stays registered');
assert.deepStrictEqual(Array.from(registrySource.api.subtabsForPageId('unknown')), [], 'invalid routes return no subtabs');
assert.strictEqual(registrySource.api.saveScopeForPageId('general', 0), 'general', 'general interface keeps its scoped save');
assert.strictEqual(registrySource.api.saveScopeForPageId('general', 1), '', 'profile subtab has no unrelated scoped save');
for (const id of ids.filter(id => id.startsWith('launcher'))) assert.strictEqual(registrySource.api.saveScopeForPageId(id, 0), 'launcher', `${id} shares the Launcher save scope`);
assert.strictEqual(registrySource.api.saveScopeForPageId('unknown', 0), '', 'unknown routes have no save scope');
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
assert.deepStrictEqual(Array.from(normalizedOrder.slice(0, 2)), ['launcher','settingsWindow'], 'valid saved order is preserved when newer tabs are appended');
assert(normalizedOrder.includes('notifications'), 'new notification tab is appended to legacy saved orders');
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
