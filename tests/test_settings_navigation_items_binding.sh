#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const registryPath = path.join(root, 'js/settings/SettingsPageRegistry.js');
const registry = {};
vm.runInNewContext(fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/, ''), registry, { filename: registryPath });
const navigation = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const widget = fs.readFileSync(path.join(root, 'components/settings/SettingsWidget.qml'), 'utf8');
const view = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigation.qml'), 'utf8');
const ids = registry.tabDefinitions().map(page => page.id);
const orderedIds = Array.from(registry.groupedTabOrder(ids));
const items = Array.from(registry.navigationItemsForOrder(orderedIds, {}));
const groups = registry.navigationGroupDefinitions().map(group => ({
  id: group.id,
  items: items.filter(item => item.groupId === group.id)
}));
assert.strictEqual(items.length, ids.length, 'every settings page must render as a clickable navigation item');
assert(groups.every(group => group.items.length > 0), 'every navigation folder must have its pages');
assert(groups.find(group => group.id === 'appearance').items.some(item => item.id === 'themes'),
  'Appearance folder must contain the Themes tab');
assert(groups.find(group => group.id === 'modules').items.some(item => item.id === 'cpuRam'),
  'Modules folder must contain the CPU/RAM tab');
assert(view.includes('onClicked: root.host.selectSettingsTab(parent.modelData.id)'),
  'page row click must route to its stable page ID');
assert(view.includes('onToggleRequested: root.host.toggleSettingsNavigationGroup(groupId)'),
  'folder primitive routes its toggle action through the settings host');
const folder = fs.readFileSync(path.join(root, 'components/settings/primitives/SettingsNavigationFolder.qml'), 'utf8');
assert(folder.includes('root.toggleRequested()'), 'folder primitive exposes an explicit toggle signal');
assert(widget.includes('function toggleSettingsNavigationGroup(id)'),
  'settings host must expose the folder toggle');
assert(widget.includes('function selectSettingsTab(id)'),
  'settings host must expose page selection');
assert(navigation.includes('SettingsPageRegistry.navigationItemsForOrder('),
  'navigation controller must bind the complete row model');
console.log(`settings navigation rows: ${items.length} clickable pages across ${groups.length} populated folders: OK`);
NODE
