#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# The page editor must pass the canonical group ID to both capability checks
# and move operations. This makes the frame boundary explicit at the UI edge.
grep -Fq 'listRepeater: settingsNavigationPagesOrderRepeater' "$WINDOW"
grep -Fq 'dropIndicatorHost: settingsNavigationPageGroup' "$WINDOW"
grep -Fq 'host.moveSettingsTabWithinGroupTo(' "$WINDOW"
grep -Fq 'function moveSettingsTabWithinGroup(groupId, id, delta)' "$WIDGET"
grep -Fq 'function settingsTabCanMoveWithinGroup(groupId, id, delta)' "$WIDGET"
grep -Fq 'SettingsPageRegistry.navigationGroupIdForTabIdInOrder(order, pageId) !== targetGroupId' "$CONTROLLER"
grep -Fq 'function moveSettingsTabToGroup(id, targetGroupId, toIndex)' "$CONTROLLER"
grep -Fq 'allowSingleItemDrag: true' "$WINDOW"
grep -Fq 'onDragSessionFinished:' "$WINDOW"
grep -Fq 'updatePageGroupDropTarget(' "$WINDOW"

node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const source = read('js/settings/SettingsPageRegistry.js')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const registry = {};
vm.runInNewContext(source, registry, { filename: 'SettingsPageRegistry.js' });
const dragSource = read('js/utils/DragReorder.js').replace(/^\.pragma library\s*$/gm, '');
const dragReorder = {};
vm.runInNewContext(dragSource, dragReorder, { filename: 'DragReorder.js' });
const controller = read('components/settings/SettingsNavigationController.qml');
function body(name) {
  const start = controller.indexOf(`function ${name}(`);
  assert(start >= 0, `missing function ${name}`);
  const open = controller.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < controller.length; i++) {
    if (controller[i] === '{') depth++;
    else if (controller[i] === '}' && --depth === 0) return controller.slice(open + 1, i);
  }
  throw new Error(`unterminated function ${name}`);
}

let order = registry.defaultNavigationOrder();
const flat = registry.flattenNavigationOrder(order);
const items = registry.navigationItemsForOrder(flat, {});
assert.strictEqual(items.length, 26, 'all 26 pages are available in the editor model');
for (const item of items) {
  assert.strictEqual(item.groupId, registry.navigationGroupIdForTabId(item.id), `${item.id} carries its canonical group ID`);
}

let saveCount = 0;
const fakeRoot = {
  settingsNavigationOrderNormalized: () => JSON.parse(JSON.stringify(order)),
  settingsTabCanMoveWithinGroup(groupId, id, delta) {
    return canMove(groupId, id, delta, this, registry);
  },
  settings: { save() { saveCount++; } }
};
const canMove = new Function('groupId','id','delta','root','SettingsPageRegistry', body('settingsTabCanMoveWithinGroup'));
const move = new Function('groupId','id','delta','root','Config','SettingsPageRegistry','DragReorder', body('moveSettingsTabWithinGroup'));
const config = {};

assert.strictEqual(canMove('modules', 'timers', -1, fakeRoot, registry), true,
  'a page can move up inside its own group');
assert.strictEqual(canMove('appearance', 'timers', -1, fakeRoot, registry), false,
  'within-group control cannot reorder a page assigned to another group');
assert.strictEqual(canMove('modules', 'modules', -1, fakeRoot, registry), false,
  'first page cannot move above the first position');
assert.strictEqual(canMove('notifications', 'notificationsDnd', 1, fakeRoot, registry), false,
  'last page cannot move below the last position');
assert.strictEqual(canMove('modules', 'timers', 0, fakeRoot, registry), false,
  'page movement is limited to one adjacent step');
assert.strictEqual(canMove('modules', 'timers', 0.5, fakeRoot, registry), false,
  'non-integer movement deltas are rejected');

move('modules', 'timers', -1, fakeRoot, config, registry, dragReorder);
order = JSON.parse(JSON.stringify(config.settingsNavigationOrder));
assert.deepStrictEqual(Array.from(order.pagesByGroup.modules.slice(0, 3)), ['modules', 'timers', 'time'],
  "valid move changes only the selected group's page order");
assert.deepStrictEqual(Array.from(order.pagesByGroup.appearance), ['themes', 'interface', 'settingsWindow'],
  'appearance page order remains unchanged');
assert.deepStrictEqual(Array.from(order.pagesByGroup.dashboard), ['dashboard'],
  'singleton Dashboard frame remains unchanged');
assert.deepStrictEqual(Array.from(order.pagesByGroup.general), ['general'],
  'singleton General frame remains unchanged');
assert.strictEqual(saveCount, 1, 'successful page move is persisted once');

const beforeInvalid = JSON.stringify(order);
move('appearance', 'timers', -1, fakeRoot, config, registry, dragReorder);
assert.strictEqual(JSON.stringify(config.settingsNavigationOrder), beforeInvalid,
  'invalid within-group move leaves the hierarchy unchanged');
const moveToGroup = new Function('id','targetGroupId','toIndex','root','Config','SettingsPageRegistry','DragReorder', body('moveSettingsTabToGroup'));
assert.strictEqual(moveToGroup('timers', 'appearance', 1, fakeRoot, config, registry, dragReorder), true,
  'cross-folder move accepts the destination group');
order = JSON.parse(JSON.stringify(config.settingsNavigationOrder));
assert.strictEqual(order.pagesByGroup.modules.includes('timers'), false);
assert.strictEqual(order.pagesByGroup.appearance[1], 'timers');
assert.strictEqual(registry.navigationGroupIdForTabIdInOrder(order, 'timers'), 'appearance');
assert.strictEqual(saveCount, 2, 'both accepted moves are persisted exactly once');

const groups = registry.navigationGroupsForOrder(order, {});
const modules = groups.find(group => group.id === 'modules');
const notifications = groups.find(group => group.id === 'notifications');
assert.deepStrictEqual(Array.from(modules.items.map(item => item.id)), ['modules', 'time', 'player', 'mopidy', 'weather', 'cava', 'cpuRam', 'network', 'volume', 'osd', 'calendar'],
  'source sidebar model reflects the removal after cross-folder move');
assert.deepStrictEqual(Array.from(notifications.items.map(item => item.id)), ['notifications', 'notificationsDnd'], 'notification pages stay together in their dedicated folder');
assert.deepStrictEqual(Array.from(groups.find(group => group.id === 'appearance').items.map(item => item.id)), ['themes', 'timers', 'interface', 'settingsWindow'],
  'destination sidebar model includes the page at its chosen position');
console.log('Settings page order by group: default grouping, dynamic cross-folder membership, scoped movement, persistence and sidebar model: OK');
NODE

echo 'settings navigation page order by group: OK'
