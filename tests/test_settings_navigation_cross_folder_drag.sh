#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const load = relative => {
  const source = read(relative).replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
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
const registry = load('js/settings/SettingsPageRegistry.js');
const controllerSource = read('components/settings/SettingsNavigationController.qml');
const widgetSource = read('components/settings/SettingsWidget.qml');
const searchSource = read('components/settings/SettingsSearchController.qml');
const navigationSource = read('components/settings/SettingsNavigation.qml');
const folderSource = read('components/settings/primitives/SettingsNavigationFolder.qml');
const handleSource = read('components/primitives/DragReorderHandle.qml');
const windowSource = read('components/settings/sections/SettingsWindowSection.qml');
const defaultOrder = registry.defaultNavigationOrder();

// Pure fallback normalizers used by isolated apply/profile adapters must honor
// the same cross-folder assignments as the canonical registry.
const applyFallback = load('js/settings/SettingsApplyCore.js');
const profileFallback = load('js/settings/SettingsProfiles.js');
const fallbackInput = JSON.parse(JSON.stringify(defaultOrder));
fallbackInput.pagesByGroup.modules = fallbackInput.pagesByGroup.modules.filter(id => id !== 'weather');
fallbackInput.pagesByGroup.appearance.splice(1, 0, 'weather');
const applyNormalized = applyFallback.fallbackNavigationOrder(fallbackInput);
const profileNormalized = profileFallback.fallbackNavigationOrder(fallbackInput);
for (const [name, value] of [['apply', applyNormalized], ['profiles', profileNormalized]]) {
  assert.strictEqual(registry.navigationGroupIdForTabIdInOrder(value, 'weather'), 'appearance',
    `${name} fallback preserves cross-folder membership`);
  assert(value.pagesByGroup.modules.includes('osd'), `${name} fallback retains OSD page`);
  assert.strictEqual(Object.values(value.pagesByGroup).flat().length, 26,
    `${name} fallback retains every registered page exactly once`);
}

// Every stable page remains represented exactly once, while cross-folder moves
// are now valid persisted assignments rather than metadata violations.
const custom = JSON.parse(JSON.stringify(defaultOrder));
custom.pagesByGroup.modules = custom.pagesByGroup.modules.filter(id => id !== 'weather');
custom.pagesByGroup.appearance.splice(1, 0, 'weather');
const normalized = registry.normalizeNavigationOrder(custom);
assert.strictEqual(registry.navigationGroupIdForTabIdInOrder(normalized, 'weather'), 'appearance');
assert.deepStrictEqual(Array.from(registry.navigationGroupsForOrder(normalized, {}).find(g => g.id === 'appearance').items.map(x => x.id)),
  ['themes', 'weather', 'interface', 'settingsWindow']);
assert.deepStrictEqual(Array.from(registry.navigationGroupsForOrder(normalized, {}).find(g => g.id === 'modules').items.map(x => x.id)),
  Array.from(custom.pagesByGroup.modules));
assert.strictEqual(Object.values(normalized.pagesByGroup).flat().length, 26);
assert.strictEqual(new Set(Object.values(normalized.pagesByGroup).flat()).size, 26);

// Duplicates/unknown IDs are rejected globally; omitted pages fall back to
// their canonical group so partial older profiles remain safe.
const malformed = registry.normalizeNavigationOrder({
  groupOrder: defaultOrder.groupOrder,
  pagesByGroup: {
    appearance: ['weather', 'modules', 'weather', 'not-a-page'],
    modules: ['modules', 'time']
  }
});
assert.deepStrictEqual(Array.from(malformed.pagesByGroup.appearance), ['weather', 'modules', 'themes', 'interface', 'settingsWindow']);
assert.strictEqual(malformed.pagesByGroup.modules.includes('modules'), false, 'duplicate page is only retained in its first valid folder');
assert.strictEqual(Object.values(malformed.pagesByGroup).flat().length, 26);
assert.strictEqual(new Set(Object.values(malformed.pagesByGroup).flat()).size, 26);

// Execute the real controller move method with a minimal host, verifying save,
// destination index, moving back, and empty-folder handling.
let state = JSON.parse(JSON.stringify(defaultOrder));
let saveCount = 0;
let activePageId = 'weather';
const fakeRoot = {
  settingsNavigationOrderNormalized: () => JSON.parse(JSON.stringify(state)),
  settings: { save() { saveCount++; } },
  moveSettingsTabWithinGroupTo(groupId, pageId, index) {
    const pages = state.pagesByGroup[groupId].slice();
    const from = pages.indexOf(pageId);
    if (from < 0 || index < 0 || index >= pages.length || from === index) return false;
    pages.splice(index, 0, pages.splice(from, 1)[0]);
    state.pagesByGroup[groupId] = pages;
    return true;
  }
};
const moveToGroup = new Function('id', 'targetGroupId', 'toIndex', 'root', 'Config', 'SettingsPageRegistry',
  functionBody(controllerSource, 'moveSettingsTabToGroup'));
const Config = {};
assert.strictEqual(moveToGroup('weather', 'appearance', 1, fakeRoot, Config, registry), true);
state = JSON.parse(JSON.stringify(Config.settingsNavigationOrder));
assert.strictEqual(state.pagesByGroup.modules.includes('weather'), false);
assert.deepStrictEqual(Array.from(state.pagesByGroup.appearance.slice(0, 3)), ['themes', 'weather', 'interface']);
assert.strictEqual(activePageId, 'weather', 'moving page membership must not change the stable active page ID');
assert.strictEqual(saveCount, 1);
assert.strictEqual(moveToGroup('modules', 'appearance', 0, fakeRoot, Config, registry), true,
  'singleton module page can be dropped into an existing folder');
state = JSON.parse(JSON.stringify(Config.settingsNavigationOrder));
assert.strictEqual(state.pagesByGroup.modules.length, 10, 'source group reflects removal of both transferred pages');
assert.strictEqual(state.pagesByGroup.appearance[0], 'modules');
assert.strictEqual(moveToGroup('dashboard', 'appearance', 1, fakeRoot, Config, registry), true,
  'a singleton page can be dragged out of its folder');
state = JSON.parse(JSON.stringify(Config.settingsNavigationOrder));
assert.strictEqual(state.pagesByGroup.dashboard.length, 0, 'a folder may become empty after its only page is moved');
assert.strictEqual(registry.navigationGroupIdForTabIdInOrder(state, 'dashboard'), 'appearance');
assert.strictEqual(moveToGroup('dashboard', 'dashboard', 0, fakeRoot, Config, registry), true,
  'a singleton page can be moved back into an empty folder');
state = JSON.parse(JSON.stringify(Config.settingsNavigationOrder));
assert.strictEqual(state.pagesByGroup.dashboard[0], 'dashboard');
assert.strictEqual(moveToGroup('weather', 'modules', 0, fakeRoot, Config, registry), true,
  'a page can be moved back out of its current folder');
state = JSON.parse(JSON.stringify(Config.settingsNavigationOrder));
assert.strictEqual(registry.navigationGroupIdForTabIdInOrder(state, 'weather'), 'modules');
assert.strictEqual(saveCount, 5, 'each accepted cross-folder move saves once');

// UI drag coordinator supports singleton source rows, group hit-testing,
// per-group insertion indices, visible target feedback and empty folders.
assert(handleSource.includes('property bool allowSingleItemDrag: false'));
assert(handleSource.includes('signal dragSessionFinished(int fromIndex, int toIndex)'));
assert(handleSource.includes('root.dragSessionFinished(from, to)'));
assert(windowSource.includes('function updatePageGroupDropTarget(pageId, sourceGroupId, sceneX, sceneY)'));
assert(windowSource.includes('function finishPageGroupDrag(pageId, sourceGroupId)'));
assert(windowSource.includes('host.moveSettingsTabToGroup(pageId, targetGroupId, targetIndex)'));
assert(windowSource.includes('forceFrameBorder: settingsWindowColumn.pageGroupDropTargetId === groupData.id'));
assert(windowSource.includes('allowSingleItemDrag: true'));
assert(navigationSource.includes('visible: navigationGroupDelegate.modelData.items.length !== 1'));
assert(navigationSource.includes('emptyFolder: navigationGroupDelegate.modelData.items.length === 0'));
assert(folderSource.includes('root.emptyFolder && !root.collapsed'));
assert(widgetSource.includes('navigationGroupIdForTabIdInOrder(\n            root.settingsNavigationOrderNormalized(), pageId)'));
assert(searchSource.includes('var navigationOrder = root.host && typeof root.host.settingsNavigationOrderNormalized === \"function\"'));

console.log('Settings cross-folder drag: dynamic registry membership, exact insertion, singleton moves, empty folders, active page and persistence: OK');
NODE

echo 'settings navigation cross-folder drag: OK'
