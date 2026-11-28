#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
node - "$REGISTRY" "$CONTROLLER" "$WIDGET" "$WINDOW" "$CONFIG" "$DEFAULTS" "$PERSIST" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [registryPath, controllerPath, widgetPath, windowPath, configPath, defaultsPath, persistPath] = process.argv.slice(2);
const read = path => fs.readFileSync(path, 'utf8');
const registry = {};
vm.runInNewContext(read(registryPath).replace(/^\.pragma library\s*/, ''), registry, { filename: registryPath });
const controller = read(controllerPath);
const widget = read(widgetPath);
const windowSection = read(windowPath);
const config = read(configPath);
const defaults = read(defaultsPath);
const persistence = read(persistPath);

const pages = registry.tabDefinitions();
const groups = registry.navigationGroupDefinitions();
assert.strictEqual(pages.length, 26, 'audit baseline must include all 26 stable settings pages');
assert.strictEqual(groups.length, 6, 'audit baseline must include all 6 navigation groups');
assert.strictEqual(new Set(pages.map(page => page.id)).size, pages.length, 'page IDs must remain unique');
assert(pages.every(page => groups.some(group => group.id === page.groupId)), 'every page must have a canonical group');
assert(groups.some(group => group.id === 'dashboard') && groups.some(group => group.id === 'general'),
  'Dashboard and General must remain explicit top-level groups');

// v1351 implements a root-level active-page preference without folding it into profiles.
assert(controller.includes('property string currentPageId: "interface"'), 'first-run navigation fallback must be General');
assert(config.includes('property string settingsLastActivePageId: "interface"'), 'Config must own the standalone last-page preference');
assert(persistence.includes('settingsLastActivePageId: String(config.settingsLastActivePageId || "interface")'), 'last page must be persisted at settings.json root');
assert(persistence.includes('delete state.settingsLastActivePageId'), 'last-page UI state must be excluded from profile diff');
assert(persistence.includes('managedKeys.push("settingsLastActivePageId")'), 'legacy root value must be managed');
assert(widget.includes('function restoreSettingsLastActivePage()'), 'last active page must restore after initial settings load');
assert(widget.includes('root.restoreSettingsLastActivePage()'), 'widget must invoke startup restoration');
assert(widget.includes('onCurrentPageIdChanged: root.persistCurrentSettingsPage()'), 'explicit page changes must persist');
assert(widget.includes('function persistCurrentSettingsPage()'), 'page selection persistence must be isolated');

// Collapsing a folder currently modifies only the standalone expansion map.
// Execute the real QML method body with a small host stub and assert no page teleport.
function functionBody(source, name) {
  const token = `function ${name}(`;
  const start = source.indexOf(token);
  assert(start >= 0, `missing ${name}()`);
  const open = source.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}' && --depth === 0) return source.slice(open + 1, i);
  }
  throw new Error(`unterminated ${name}()`);
}
const normalizeSchema = { normalizeSettingsNavigationCollapsedGroups: (value) => value };
const toggle = new Function('id', 'root', 'Config', 'SettingsSchema', 'SettingsPageRegistry', functionBody(widget, 'toggleSettingsNavigationGroup'));
let savedState = null;
const fakeRoot = {
  currentPageId: 'weather',
  collapsedSettingsNavigationGroups: { appearance: false, modules: false, launcher: false, notifications: false },
  settingsNavigationGroupCollapsed(id) { return this.collapsedSettingsNavigationGroups[id] === true; },
  setSettingsNavigationCollapsedGroups(value) {
    savedState = value;
    this.collapsedSettingsNavigationGroups = value;
  }
};
toggle('modules', fakeRoot, {}, normalizeSchema, registry);
assert.strictEqual(fakeRoot.currentPageId, 'weather', 'collapsing the active page folder must not teleport or deactivate its page');
assert.strictEqual(fakeRoot.settingsNavigationGroupCollapsed('modules'), true, 'folder must collapse independently');
assert.strictEqual(savedState.modules, true, 'collapsed state must be persisted separately');
assert(widget.includes('function settingsNavigationGroupHasCurrentPage(id)'), 'collapsed group must be able to indicate that it contains the active page');
assert(widget.includes('function expandSettingsNavigationGroupForPage(pageId)'), 'explicit destination selection must be able to reveal its parent group');

// The legacy flat-order helper remains for migration; the live sidebar now follows the hierarchical frame order.
assert(registry.groupedTabOrder.toString().includes('NAVIGATION_GROUPS'), 'legacy grouping currently imposes canonical frame order');
assert(controller.includes('function settingsTabCanMove(id, delta)'), 'legacy per-page movement API must be identified');
assert(controller.includes('SettingsPageRegistry.navigationGroupIdForTabIdInOrder(order, pageId)'), 'keyboard page movement follows the current user-assigned group');
assert(windowSection.includes('heading: \"Порядок рамок\"'), 'group frame ordering has its own editor section');
assert(windowSection.includes('host.moveSettingsNavigationGroupTo('), 'group frames can be reordered by the shared drag editor');
assert(widget.includes('SettingsPageRegistry.navigationGroupsForOrder('), 'sidebar follows the saved frame order');

// Keep the navigation contract executable in tests rather than in a
// repository design-note document: restore never expands a collapsed group,
// explicit navigation may expand it, and user-assigned page membership persists.
const restoreBody = functionBody(widget, 'restoreSettingsLastActivePage');
const persistBody = functionBody(widget, 'persistCurrentSettingsPage');
assert(!restoreBody.includes('expandSettingsNavigationGroupForPage'),
  'restoring the active page must not auto-expand its collapsed parent');
assert(persistBody.includes('expandSettingsNavigationGroupForPage'),
  'explicit page selection must reveal the destination group when needed');

const defaultOrder = registry.defaultNavigationOrder();
assert(defaultOrder.groupOrder.includes('dashboard') && defaultOrder.groupOrder.includes('general'),
  'singleton Dashboard and General frames must remain part of the reorderable group model');
const normalizedOrder = registry.normalizeNavigationOrder({
  groupOrder: ['general', 'dashboard', 'appearance', 'modules', 'launcher'],
  pagesByGroup: {
    modules: ['dashboard'],
    dashboard: ['dashboard']
  }
});
assert(normalizedOrder.pagesByGroup.modules.includes('dashboard'),
  'normalization must accept moving a page into another folder');
assert(normalizedOrder.pagesByGroup.dashboard.length === 0,
  'a source folder may become empty after its last page is moved');
assert(registry.navigationGroupIdForTabIdInOrder(normalizedOrder, 'dashboard') === 'modules',
  'runtime folder lookup follows the saved membership rather than default metadata');
const pageMoveBody = functionBody(controller, 'moveSettingsTabWithinGroupTo');
assert(pageMoveBody.includes('navigationGroupIdForTabIdInOrder(order, pageId) !== targetGroupId'),
  'page reorder API must validate the current dynamic group');
assert(controller.includes('function moveSettingsTabToGroup(id, targetGroupId, toIndex)'),
  'page editor exposes a cross-folder move API');
assert(windowSection.includes('function updatePageGroupDropTarget(')
  && windowSection.includes('onDragSessionFinished:'),
  'dragging over another frame records and commits a cross-folder destination');
const groupMoveBody = functionBody(controller, 'moveSettingsNavigationGroupTo');
assert(groupMoveBody.includes('order.groupOrder = DragReorder.move(groupOrder, fromIndex, destination)'),
  'top-level groups must be independently reorderable');
console.log('settings navigation audit: 26 pages, 6 folders, active-page/collapse behavior, dynamic membership and cross-folder drop support: OK');
NODE
