#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"

# The page editor renders one framed editor per navigation group, supports
# local reordering and cross-folder drag/drop, including singleton pages.
grep -Fq 'text: "Вкладки панели настроек"' "$WINDOW"
grep -Fq 'model: host ? host.settingsNavigationGroups : []' "$WINDOW"
grep -Fq 'delegate: SettingsGroup {' "$WINDOW"
grep -Fq 'heading: groupData.label' "$WINDOW"
grep -Fq 'settingsSearchSubTabIndex: 2' "$WINDOW"
grep -Fq 'model: settingsNavigationPageGroup.groupData.items' "$WINDOW"
grep -Fq 'text: String(index + 1)' "$WINDOW"
grep -Fq 'host.setSettingsTabLabel(modelData.id, text)' "$WINDOW"
grep -Fq 'id: settingsNavigationPagesOrderRepeater' "$WINDOW"
grep -Fq 'listRepeater: settingsNavigationPagesOrderRepeater' "$WINDOW"
grep -Fq 'dropIndicatorHost: settingsNavigationPageGroup' "$WINDOW"
grep -Fq 'host.moveSettingsTabWithinGroupTo(' "$WINDOW"
grep -Fq 'allowSingleItemDrag: true' "$WINDOW"
grep -Fq 'host.moveSettingsTabToGroup(' "$WINDOW"
grep -Fq 'forceFrameBorder: settingsWindowColumn.pageGroupDropTargetId === groupData.id' "$WINDOW"
grep -Fq 'property bool forceFrameBorder: false' "$ROOT/components/settings/primitives/SettingsGroup.qml"
! grep -Fq 'model: host ? host.settingsNavigationItems : []' "$WINDOW"
grep -Fq 'settingsWindowColumn.settings.hasResetChanges("keys", ({ keys: ["settingsNavigationOrder", "settingsTabLabels"] }))' "$WINDOW"

node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const registrySource = read('js/settings/SettingsPageRegistry.js')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const registry = {};
vm.runInNewContext(registrySource, registry, { filename: 'SettingsPageRegistry.js' });
const windowSection = read('components/settings/sections/SettingsWindowSection.qml');
const pageEditor = windowSection.slice(
  windowSection.indexOf('text: "Вкладки панели настроек"'),
  windowSection.indexOf('visible: host && host.currentPageId === "general" && host.currentPageSubTabIndex === 0')
);
assert(pageEditor.includes('delegate: SettingsGroup {'), 'each navigation group has its own framed page editor');
assert(pageEditor.includes('heading: groupData.label'), 'frame heading comes from the matching navigation group');
assert(pageEditor.includes('model: settingsNavigationPageGroup.groupData.items'), 'nested repeater shows only pages from that group');
assert(pageEditor.includes('text: String(index + 1)'), 'page numbering restarts within each group');
assert(pageEditor.includes('settingsSearchSubTabIndex: 2'), 'each framed editor remains discoverable in Settings Window > Tabs search');

const defaultOrder = registry.defaultNavigationOrder();
const customOrder = {
  groupOrder: ['general', 'launcher', 'dashboard', 'modules', 'appearance', 'notifications'],
  pagesByGroup: JSON.parse(JSON.stringify(defaultOrder.pagesByGroup))
};
customOrder.pagesByGroup.modules = ['weather', 'modules', 'time', 'timers', 'player', 'mopidy', 'cava', 'cpuRam', 'network', 'volume', 'calendar', 'osd'];
customOrder.pagesByGroup.notifications = ['notifications', 'notificationsDnd'];
customOrder.pagesByGroup.appearance = ['settingsWindow', 'themes'];
const labels = { general: 'Мои настройки', dashboard: 'Обзор', weather: 'Прогноз' };
const groups = Array.from(registry.navigationGroupsForOrder(customOrder, labels));
assert.deepStrictEqual(groups.map(group => group.id), customOrder.groupOrder,
  'framed editor follows the current frame order');
assert.strictEqual(groups.length, 6, 'all six frames remain independently represented');
const allIds = groups.flatMap(group => group.items.map(item => item.id));
assert.strictEqual(allIds.length, 26, 'all 26 settings pages are represented');
assert.strictEqual(new Set(allIds).size, 26, 'no page is duplicated across frames');
for (const group of groups) {
  assert(group.items.length >= 1, `${group.id} frame is not empty`);
  assert(group.items.every(item => item.groupId === group.id), `${group.id} editor contains only its own pages`);
}
assert.deepStrictEqual(Array.from(groups.find(group => group.id === 'modules').items.map(item => item.id)),
  customOrder.pagesByGroup.modules, 'custom page order is reflected inside the Modules frame');
assert.deepStrictEqual(Array.from(groups.find(group => group.id === 'appearance').items.map(item => item.id)),
  ['settingsWindow', 'themes', 'interface'], 'Appearance maintains its own independently editable page order');
assert.strictEqual(groups.find(group => group.id === 'general').items[0].label, 'Мои настройки',
  'singleton General remains editable inside its own frame');
assert.strictEqual(groups.find(group => group.id === 'dashboard').items[0].label, 'Обзор',
  'singleton Dashboard remains editable inside its own frame');
assert.strictEqual(groups.find(group => group.id === 'modules').items[0].label, 'Прогноз',
  'page labels remain editable without affecting default frame membership');
const moved = JSON.parse(JSON.stringify(customOrder));
moved.pagesByGroup.modules = moved.pagesByGroup.modules.filter(id => id !== 'weather');
moved.pagesByGroup.appearance.splice(1, 0, 'weather');
const normalizedMoved = registry.normalizeNavigationOrder(moved);
const movedGroups = Array.from(registry.navigationGroupsForOrder(normalizedMoved, labels));
assert.deepStrictEqual(Array.from(movedGroups.find(group => group.id === 'modules').items.map(item => item.id)),
  Array.from(normalizedMoved.pagesByGroup.modules), 'source folder model reflects the removed page');
assert.deepStrictEqual(Array.from(movedGroups.find(group => group.id === 'appearance').items.map(item => item.id)),
  Array.from(normalizedMoved.pagesByGroup.appearance), 'destination folder model reflects the inserted page');
assert.strictEqual(movedGroups.find(group => group.id === 'appearance').items[1].groupId, 'appearance',
  'runtime row metadata uses the selected folder, not the canonical default folder');
console.log('Settings framed page editor: six frames, 26 unique pages, local order, singleton frames and editable labels: OK');
NODE

echo 'settings framed page editor: OK'
