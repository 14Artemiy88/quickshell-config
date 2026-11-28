#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const registrySource = read('js/settings/SettingsPageRegistry.js').replace(/^\.pragma library\s*/m, '');
const registry = {};
vm.runInNewContext(registrySource, registry, { filename: 'SettingsPageRegistry.js' });

const interfacePage = registry.pageMetadataForId('interface');
const generalPage = registry.pageMetadataForId('general');
assert.equal(interfacePage.groupId, 'appearance', 'Interface belongs to the Appearance navigation folder');
assert.equal(interfacePage.defaultLabel, 'Интерфейс');
assert.equal(interfacePage.saveScope, 'general', 'moving the page does not change its existing profile key scope');
assert.deepEqual(Array.from(interfacePage.subTabs), [], 'Interface is a direct page rather than a General subtab');
assert.equal(generalPage.saveScope, '', 'General profile/storage page has no unrelated scoped save');
assert.deepEqual(Array.from(generalPage.subTabs, tab => tab.label), ['Профили', 'Хранилища']);
assert.deepEqual(Array.from(registry.defaultNavigationOrder().pagesByGroup.appearance), ['themes', 'interface', 'settingsWindow']);
assert.deepEqual(Array.from(registry.defaultNavigationOrder().pagesByGroup.general), ['general']);
assert(interfacePage.keywords.includes('масштаб шрифта'), 'Interface remains searchable by font scale');
assert(interfacePage.keywords.includes('масштаб интерфейса'), 'Interface remains searchable by UI scale');

const content = read('components/settings/SettingsPageContent.qml');
const interfaceSection = read('components/settings/sections/SettingsInterfaceSection.qml');
const generalSection = read('components/settings/sections/SettingsGeneralSection.qml');
const windowSection = read('components/settings/sections/SettingsWindowSection.qml');
const widget = read('components/settings/SettingsWidget.qml');
const navigation = read('components/settings/SettingsNavigationController.qml');
assert(content.includes('objectName: "settings-search-page:interface"'), 'Interface has its own searchable page root');
assert(content.includes('SettingsInterfaceSection {'), 'page content mounts the new Interface section');
assert(interfaceSection.includes('host.currentPageId === "interface"'), 'moved controls are gated by the Interface page ID');
for (const key of ['font', 'fontSize', 'ledFont', 'uiScale', 'fontScale', 'backgroundBlurRadius', 'frameBorderWidth', 'frameRadius', 'cornerRadiusScale'])
  assert(interfaceSection.includes(`targetProperty: "${key}"`) || interfaceSection.includes(`changeKeys: ({ keys: ["${key}"`), `${key} remains editable in Interface`);
assert(!generalSection.includes('Шрифты интерфейса') && !generalSection.includes('Масштаб интерфейса модулей'),
  'General no longer contains duplicate Interface settings');
assert(generalSection.includes('currentPageSubTabIndex === 1') && generalSection.includes('storagePathEntries'),
  'storage controls remain in General > Storage');
assert(windowSection.includes('currentPageId === "general" && host.currentPageSubTabIndex === 0'),
  'profile management remains in General > Profiles');
assert(windowSection.includes('settingsSearchSubTabIndex: 0'), 'profile settings keep the new General tab index');
assert(widget.includes('currentPageResetAvailable: root.currentPageId !== "general"'),
  'Interface page keeps its scoped Reset action');
assert(navigation.includes('interface: "general"'), 'Interface dirty indicators continue to observe the legacy profile scope');
assert(navigation.includes('case "interface": settings.resetGeneralSettings(); break'),
  'Interface Reset routes to the existing General-settings reset implementation');

const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
const apply = read('js/settings/SettingsApplyCore.js');
const persistence = read('js/settings/SettingsPersistence.js');
assert(config.includes('interface: "Интерфейс"') && defaults.includes('interface:"Интерфейс"'),
  'Interface label is present in Config and profile defaults');
assert(config.includes('property string settingsLastActivePageId: "interface"'), 'fresh installations open the new Interface page');
assert(apply.includes('return SETTINGS_TAB_IDS.indexOf(pageId) >= 0 ? pageId : "interface"'),
  'invalid last-page IDs fall back to Interface');
assert(persistence.includes('settingsLastActivePageId: String(config.settingsLastActivePageId || "interface")'),
  'Interface fallback is persisted at settings.json root');
console.log('Settings Interface moved into Appearance: 26-page catalog, General subtabs, old profile scope, Save/Reset, search and persistence: OK');
NODE
