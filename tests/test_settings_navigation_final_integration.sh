#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const rootPath = process.argv[2];
const read = relative => fs.readFileSync(path.join(rootPath, relative), 'utf8');
const loadLibrary = relative => {
  const source = read(relative)
    .replace(/^\.pragma library\s*$/gm, '')
    .replace(/^\.import .*$/gm, '');
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context, { filename: relative });
  return context;
};
const functionBody = (source, name) => {
  const start = source.indexOf(`function ${name}(`);
  assert(start >= 0, `missing ${name}()`);
  const open = source.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}' && --depth === 0) return source.slice(open + 1, i);
  }
  throw new Error(`unterminated ${name}()`);
};
const asPlain = value => JSON.parse(JSON.stringify(value));

const registry = loadLibrary('js/settings/SettingsPageRegistry.js');
const dragReorder = loadLibrary('js/utils/DragReorder.js');
const controllerSource = read('components/settings/SettingsNavigationController.qml');
const widgetSource = read('components/settings/SettingsWidget.qml');
const searchSource = read('components/settings/SettingsSearchController.qml');
const navigationSource = read('components/settings/SettingsNavigation.qml');
const folderSource = read('components/settings/primitives/SettingsNavigationFolder.qml');
const windowSource = read('components/settings/sections/SettingsWindowSection.qml');
const defaultOrder = registry.defaultNavigationOrder();
const Config = {
  settingsNavigationOrder: asPlain(defaultOrder),
  settingsTabLabels: { weather: 'Прогноз' },
  settingsLastActivePageId: 'weather',
  settingsNavigationCollapsedGroups: { appearance: false, modules: false, launcher: false, notifications: false }
};
let saveCount = 0;
const host = {
  currentPageId: 'weather',
  currentPageSubTabIndex: 0,
  settingsNavigationReady: true,
  settings: { save() { saveCount++; } },
  settingsNavigationOrderNormalized() { return registry.normalizeNavigationOrder(Config.settingsNavigationOrder); },
  settingsNavigationGroupOrderNormalized() { return this.settingsNavigationOrderNormalized().groupOrder.slice(); },
  settingsNavigationGroups: [],
  settingsNavigationGroupCollapsed(id) { return Config.settingsNavigationCollapsedGroups[String(id)] === true; },
  setSettingsNavigationCollapsedGroups(value) {
    Config.settingsNavigationCollapsedGroups = asPlain(value);
    this.settings.save();
  },
  settingsTabLabelForId(id) {
    const page = registry.pageMetadataForId(id);
    return String(Config.settingsTabLabels[id] || (page && page.defaultLabel) || 'Настройки');
  },
  expandSettingsNavigationGroupForPage(pageId) {
    const groupId = registry.navigationGroupIdForTabIdInOrder(this.settingsNavigationOrderNormalized(), pageId);
    if (this.settingsNavigationGroupCollapsed(groupId)) {
      const next = Object.assign({}, Config.settingsNavigationCollapsedGroups, { [groupId]: false });
      this.setSettingsNavigationCollapsedGroups(next);
    }
  },
  focusSettingsNavigationPage(pageId) { this.focusedPageId = pageId; return true; },
  clearSettingsFocus() {}
};

const controller = {
  groupCanMove: new Function('id', 'delta', 'root', 'Config', 'SettingsPageRegistry',
    functionBody(controllerSource, 'settingsNavigationGroupCanMove')),
  moveGroup: new Function('id', 'delta', 'root', 'Config', 'SettingsPageRegistry', 'DragReorder',
    functionBody(controllerSource, 'moveSettingsNavigationGroup')),
  pageCanMove: new Function('groupId', 'id', 'delta', 'root', 'Config', 'SettingsPageRegistry',
    functionBody(controllerSource, 'settingsTabCanMoveWithinGroup')),
  movePage: new Function('groupId', 'id', 'delta', 'root', 'Config', 'SettingsPageRegistry', 'DragReorder',
    functionBody(controllerSource, 'moveSettingsTabWithinGroup'))
};
host.settingsNavigationGroupCanMove = (id, delta) => controller.groupCanMove(id, delta, host, Config, registry);
host.moveSettingsNavigationGroup = (id, delta) => controller.moveGroup(id, delta, host, Config, registry, dragReorder);
host.settingsTabCanMoveWithinGroup = (groupId, id, delta) => controller.pageCanMove(groupId, id, delta, host, Config, registry);
host.moveSettingsTabWithinGroup = (groupId, id, delta) => controller.movePage(groupId, id, delta, host, Config, registry, dragReorder);

// 1. Frame movement updates the canonical hierarchy, including singleton frames.
assert(host.settingsNavigationGroupCanMove('general', -1), 'General singleton frame is movable');
host.moveSettingsNavigationGroup('general', -1);
assert.deepStrictEqual(Array.from(Config.settingsNavigationOrder.groupOrder),
  ['appearance', 'modules', 'dashboard', 'launcher', 'general', 'notifications']);
assert(host.settingsNavigationGroupCanMove('dashboard', -1), 'Dashboard singleton frame is movable');
host.moveSettingsNavigationGroup('dashboard', -1);
assert.deepStrictEqual(Array.from(Config.settingsNavigationOrder.groupOrder),
  ['appearance', 'dashboard', 'modules', 'launcher', 'general', 'notifications']);

// Invalid and non-adjacent frame movement must not damage or save the hierarchy.
const orderBeforeInvalidFrameMove = asPlain(Config.settingsNavigationOrder);
const savesBeforeInvalidFrameMove = saveCount;
for (const invalidDelta of [0, 0.5, -0.5, 2, -2, NaN]) {
  assert.strictEqual(host.settingsNavigationGroupCanMove('modules', invalidDelta), false,
    `invalid group step ${invalidDelta} must be rejected`);
  host.moveSettingsNavigationGroup('modules', invalidDelta);
}
assert.deepStrictEqual(asPlain(Config.settingsNavigationOrder), orderBeforeInvalidFrameMove);
assert.strictEqual(saveCount, savesBeforeInvalidFrameMove, 'invalid frame moves do not write settings');

// 2. Page movement remains frame-scoped and independent from frame movement.
assert(host.settingsTabCanMoveWithinGroup('modules', 'weather', -1));
host.moveSettingsTabWithinGroup('modules', 'weather', -1);
assert.deepStrictEqual(Array.from(Config.settingsNavigationOrder.pagesByGroup.modules.slice(3, 5)),
  ['player', 'weather']);
const orderBeforeCrossFrame = asPlain(Config.settingsNavigationOrder);
const savesBeforeCrossFrame = saveCount;
assert.strictEqual(host.settingsTabCanMoveWithinGroup('appearance', 'weather', -1), false,
  'within-folder keyboard movement cannot act on a page outside that folder');
assert.deepStrictEqual(asPlain(Config.settingsNavigationOrder), orderBeforeCrossFrame);
assert.strictEqual(saveCount, savesBeforeCrossFrame, 'invalid within-folder movement does not persist');
const movePageAcrossGroups = new Function('id','targetGroupId','toIndex','root','Config','SettingsPageRegistry','DragReorder',
  functionBody(controllerSource, 'moveSettingsTabToGroup'));
assert.strictEqual(movePageAcrossGroups('weather', 'appearance', 2, host, Config, registry, dragReorder), true,
  'page can be dragged from Modules into Appearance');
assert.strictEqual(Config.settingsNavigationOrder.pagesByGroup.modules.includes('weather'), false);
assert.strictEqual(Config.settingsNavigationOrder.pagesByGroup.appearance[2], 'weather');

// 3. Sidebar and framed editor consume the same ordered group model.
host.settingsNavigationGroups = registry.navigationGroupsForOrder(Config.settingsNavigationOrder, Config.settingsTabLabels);
const groups = host.settingsNavigationGroups;
assert.deepStrictEqual(Array.from(groups, group => group.id),
  ['appearance', 'dashboard', 'modules', 'launcher', 'general', 'notifications']);
const editorPages = groups.flatMap(group => group.items.map(item => ({ groupId: group.id, id: item.id })));
assert.strictEqual(editorPages.length, 26);
assert.strictEqual(new Set(editorPages.map(item => item.id)).size, 26, 'each page occurs exactly once');
assert(editorPages.every(item => registry.navigationGroupIdForTabIdInOrder(Config.settingsNavigationOrder, item.id) === item.groupId),
  "sidebar/editor reflect the user-selected page-to-folder assignment");
assert.strictEqual(groups.find(group => group.id === 'modules').items[4].id, 'mopidy',
  'source group reflects removal of the moved page');
assert.strictEqual(groups.find(group => group.id === 'appearance').items[2].id, 'weather',
  'destination group shows the page at its selected insertion position');
assert.strictEqual(groups.find(group => group.id === 'appearance').items[2].label, 'Прогноз',
  'custom page labels survive cross-folder movement');
assert(windowSource.includes('model: host ? host.settingsNavigationGroups : []'),
  'framed editor reads the same group model as the sidebar');
assert(widgetSource.includes('SettingsPageRegistry.navigationGroupsForOrder('),
  'sidebar groups are derived from canonical hierarchy');

// 4. Collapsing the active folder keeps the active page and exposes its hint.
const toggleGroup = new Function('id', 'root', 'Config', 'SettingsSchema', 'SettingsPageRegistry',
  functionBody(widgetSource, 'toggleSettingsNavigationGroup'));
const hasCurrentPage = new Function('id', 'root', functionBody(widgetSource, 'settingsNavigationGroupHasCurrentPage'));
const currentPageLabel = new Function('id', 'root', functionBody(widgetSource, 'settingsNavigationGroupCurrentPageLabel'));
const SettingsSchema = { normalizeSettingsNavigationCollapsedGroups: value => value };
host.currentPageId = 'weather';
toggleGroup('appearance', host, Config, SettingsSchema, registry);
assert.strictEqual(host.currentPageId, 'weather', 'collapsing the active frame must not teleport the content page');
assert.strictEqual(host.settingsNavigationGroupCollapsed('appearance'), true, 'active page folder can collapse independently');
assert.strictEqual(hasCurrentPage('appearance', host), true, 'collapsed frame still reports that it contains the moved page');
assert.strictEqual(currentPageLabel('appearance', host), 'Прогноз', 'collapsed active-page hint respects custom label');
assert.strictEqual(host.settingsNavigationGroupCollapsed('modules'), false, 'other group state is untouched');

// 5. Explicit search navigation may reveal its destination, select the page and focus it.
const openSearchResult = new Function('entry', 'root', 'Qt', functionBody(searchSource, 'openSettingsSearchResult'));
const searchRoot = {
  host,
  settingsSearchQuery: 'ОЗУ',
  settingsSearchResults: [{ pageId: 'cpuRam', subTabIndex: 2 }],
  settingsSearchActiveMatchId: 'topAppsCpuBarColor'
};
openSearchResult(searchRoot.settingsSearchResults[0], searchRoot, { callLater(callback) { callback(); } });
assert.strictEqual(host.currentPageId, 'cpuRam', 'search result activates the stable page ID');
assert.strictEqual(host.currentPageSubTabIndex, 2, 'search result selects the matching subsection');
assert.strictEqual(host.settingsNavigationGroupCollapsed('modules'), false, 'explicit search selection reveals the destination frame');
assert.strictEqual(host.focusedPageId, 'cpuRam', 'search result returns focus to the selected navigation page');
assert.strictEqual(searchRoot.settingsSearchQuery, 'ОЗУ', 'search query remains active after navigation');
assert.strictEqual(searchRoot.settingsSearchActiveMatchId, 'topAppsCpuBarColor', 'active search match remains selected');

// 6. The new frame/page controls and keyboard/accessibility paths remain discoverable.
assert(windowSource.includes('heading: groupData.label') && windowSource.includes('text: String(index + 1)'),
  'framed editor keeps one frame per group and local page numbering');
assert(folderSource.includes('Accessible.name') && folderSource.includes('activeFocus'),
  'folder primitive exposes accessible labels and visible focus state');
assert(widgetSource.includes('function focusAdjacentSettingsNavigationItem(')
  && widgetSource.includes('function focusSettingsNavigationPage('),
  'sidebar maintains keyboard traversal and search-focus routing');
assert(registry.tabDefinitions().length === 26 && registry.navigationGroupDefinitions().length === 6);

// 7. Registration gate guards the integration and its constituent regression tests exactly once.
const check = read('CHECK.sh');
for (const name of [
  'test_settings_navigation_final_integration.sh',
  'test_settings_last_active_page_persistence.sh',
  'test_settings_collapsed_active_page_indicator.sh',
  'test_settings_navigation_group_frame_order_ui.sh',
  'test_settings_navigation_page_order_by_group.sh',
  'test_settings_navigation_framed_page_editor.sh',
  'test_settings_navigation_keyboard_accessibility.sh',
  'test_settings_flat_order_migration_cleanup.sh'
]) {
  const matches = check.match(new RegExp(`tests/${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'g')) || [];
  assert.strictEqual(matches.length, 1, `${name} must be registered exactly once`);
}

console.log('Settings navigation final integration: independent active page/collapse, ordered frames and pages, singleton groups, framed editor, search focus, keyboard/accessibility and migration: OK');
NODE
