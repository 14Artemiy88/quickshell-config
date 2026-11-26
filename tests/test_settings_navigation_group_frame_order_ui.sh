#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"

# The live sidebar must consume the canonical hierarchical frame order rather
# than the registry's static default group list.
grep -Fq 'SettingsPageRegistry.navigationGroupsForOrder(' "$WIDGET"
grep -Fq 'settingsNavigationController.settingsNavigationOrderNormalized()' "$WIDGET"
! grep -Fq 'var definitions = settingsNavigationController.settingsNavigationGroupDefinitions' "$WIDGET"

# The Settings Window editor exposes a distinct framed control for moving the
# complete group, including the singleton Dashboard and General frames.
grep -Fq 'heading: "Порядок рамок"' "$WINDOW"
grep -Fq 'model: host ? host.settingsNavigationGroups : []' "$WINDOW"
grep -Fq 'id: settingsNavigationGroupsOrderRepeater' "$WINDOW"
grep -Fq 'listRepeater: settingsNavigationGroupsOrderRepeater' "$WINDOW"
grep -Fq 'dropIndicatorHost: settingsNavigationGroupOrderFrame' "$WINDOW"
grep -Fq 'host.moveSettingsNavigationGroupTo(' "$WINDOW"
grep -Fq 'Порядок страниц внутри разделов' "$WINDOW" || grep -Fq 'Порядок целых рамок настраивается отдельно выше' "$WINDOW"
grep -Fq 'function moveSettingsNavigationGroup(id, delta)' "$CONTROLLER"
grep -Fq 'function moveSettingsNavigationGroupTo(id, toIndex)' "$CONTROLLER"
grep -Fq 'order.groupOrder = DragReorder.move(groupOrder, fromIndex, destination)' "$CONTROLLER"

node - "$REGISTRY" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const registry = {};
vm.runInNewContext(source, registry, { filename: process.argv[2] });
const defaults = registry.defaultNavigationOrder();
const customOrder = {
  groupOrder: ['general', 'launcher', 'dashboard', 'modules', 'appearance', 'notifications'],
  pagesByGroup: defaults.pagesByGroup
};
const labels = { general: 'Мои общие настройки', dashboard: 'Обзор' };
const groups = Array.from(registry.navigationGroupsForOrder(customOrder, labels));
assert.deepStrictEqual(groups.map(group => group.id), customOrder.groupOrder,
  'sidebar groups follow the saved top-level frame order');
assert.strictEqual(groups.length, 6, 'all navigation frames remain present');
assert.strictEqual(groups[0].items[0].label, 'Мои общие настройки',
  'singleton General frame uses the customized page label');
assert.strictEqual(groups[2].items[0].label, 'Обзор',
  'singleton Dashboard frame uses the customized page label');
assert.deepStrictEqual(Array.from(groups[3].items.map(item => item.id)),
  Array.from(defaults.pagesByGroup.modules), 'moving a frame never changes its internal page order');
assert.deepStrictEqual(Array.from(groups[4].items.map(item => item.id)),
  Array.from(defaults.pagesByGroup.appearance), 'each frame retains its canonical page membership');
assert(groups.every(group => typeof group.description === 'string' && group.description.length > 0),
  'frame descriptions remain available to the navigation model');
console.log('Settings navigation group frame order UI: saved frame ordering, singleton frames, labels and stable page membership: OK');
NODE
