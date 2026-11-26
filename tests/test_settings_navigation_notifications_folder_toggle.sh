#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
node - "$WIDGET" "$FOLDER" "$SCHEMA" "$REGISTRY" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [widgetPath, folderPath, schemaPath, registryPath] = process.argv.slice(2);
const widget = fs.readFileSync(widgetPath, 'utf8');
const folder = fs.readFileSync(folderPath, 'utf8');
const schemaSource = fs.readFileSync(schemaPath, 'utf8').replace(/^\.pragma library\s*/m, '');
const registrySource = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*/m, '');

assert(widget.includes('if (!SettingsPageRegistry.navigationGroupForId(key)) return'), 'group toggle validates IDs against canonical navigation registry');
assert(!widget.includes('key !== "appearance" && key !== "modules" && key !== "launcher"'), 'hard-coded group allowlist is removed');
assert(widget.includes('next[key] = !root.settingsNavigationGroupCollapsed(key)'), 'folder state toggles symmetrically');
assert(folder.includes('signal toggleRequested()'), 'shared folder primitive retains its expansion signal');
assert(folder.includes('root.toggleRequested()'), 'folder header dispatches the expansion action');

const registry = {};
vm.createContext(registry);
vm.runInContext(registrySource, registry);
assert(registry.navigationGroupForId('notifications'), 'Notifications is a canonical navigation folder');

const schema = {};
vm.createContext(schema);
vm.runInContext(schemaSource, schema);
const normalized = schema.normalizeSettingsNavigationCollapsedGroups({ notifications: true }, {});
assert.strictEqual(normalized.notifications, true, 'Notifications collapsed state persists through settings schema');

const bodyStart = widget.indexOf('function toggleSettingsNavigationGroup(id)');
const bodyOpen = widget.indexOf('{', bodyStart);
let depth = 0, bodyEnd = -1;
for (let i = bodyOpen; i < widget.length; i++) {
  if (widget[i] === '{') depth++;
  else if (widget[i] === '}' && --depth === 0) { bodyEnd = i; break; }
}
assert(bodyStart >= 0 && bodyEnd > bodyOpen, 'navigation group toggle implementation is extractable');
const toggle = new Function('id', 'root', 'Config', 'SettingsSchema', 'SettingsPageRegistry', widget.slice(bodyOpen + 1, bodyEnd));
const fakeRoot = {
  collapsedSettingsNavigationGroups: { appearance: false, modules: false, launcher: false, notifications: false },
  settingsNavigationGroupCollapsed(id) { return this.collapsedSettingsNavigationGroups[id] === true; },
  setSettingsNavigationCollapsedGroups(value) { this.collapsedSettingsNavigationGroups = value; }
};
toggle('notifications', fakeRoot, {}, schema, registry);
assert.strictEqual(fakeRoot.settingsNavigationGroupCollapsed('notifications'), true, 'Notifications folder can be collapsed');
toggle('notifications', fakeRoot, {}, schema, registry);
assert.strictEqual(fakeRoot.settingsNavigationGroupCollapsed('notifications'), false, 'Notifications folder can be expanded again');
console.log('Settings navigation folders: Notifications toggle, canonical group validation and persistence: OK');
JS
