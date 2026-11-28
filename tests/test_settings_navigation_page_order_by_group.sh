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
grep -Fq 'SettingsPageRegistry.navigationGroupIdForTabId(pageId) !== targetGroupId' "$CONTROLLER"

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
  'a page cannot be moved by controls from another group');
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
  'cross-group page move is rejected without changing the canonical hierarchy');
assert.strictEqual(saveCount, 1, 'rejected page move is not persisted');

const groups = registry.navigationGroupsForOrder(order, {});
const modules = groups.find(group => group.id === 'modules');
const notifications = groups.find(group => group.id === 'notifications');
assert.deepStrictEqual(Array.from(modules.items.map(item => item.id)), ['modules', 'timers', 'time', 'player', 'mopidy', 'weather', 'cava', 'cpuRam', 'network', 'volume', 'osd', 'calendar'],
  'sidebar model reflects the customized page order inside its own group');
assert.deepStrictEqual(Array.from(notifications.items.map(item => item.id)), ['notifications', 'notificationsDnd'], 'notification pages stay together in their dedicated folder');
assert.strictEqual(groups.find(group => group.id === 'appearance').items[0].id, 'themes',
  'other groups retain their independent order');
console.log('Settings page order by group: canonical membership, scoped movement, group boundaries, persistence and sidebar model: OK');
NODE

echo 'settings navigation page order by group: OK'
