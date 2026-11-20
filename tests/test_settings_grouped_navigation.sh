#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# The grouped sidebar is rendered from four fixed semantic groups.
grep -Fq 'model: root.settingsNavigationGroups' "$WIDGET"
grep -Fq 'function toggleSettingsNavigationGroup(id)' "$WIDGET"
grep -Fq 'function expandSettingsNavigationGroupForPage(pageId)' "$WIDGET"
grep -Fq 'root.expandSettingsNavigationGroupForPage(id)' "$WIDGET"
grep -Fq 'root.host.expandSettingsNavigationGroupForPage(entry.pageId)' "$ROOT/components/settings/SettingsSearchController.qml"
grep -Fq 'ScrollBar.vertical: SettingsScrollBar' "$WIDGET"
grep -Fq 'settingsNavigationGroupHasCurrentPage(modelData.id)' "$WIDGET"
grep -Fq 'if (modelData.items.length === 1)' "$WIDGET"
grep -Fq 'visible: navigationGroupDelegate.modelData.items.length > 1' "$WIDGET"
grep -Fq 'function settingsTabCanMove(id, delta)' "$CONTROLLER"
grep -Fq 'host.settingsTabCanMove(modelData.id, -1)' "$WINDOW"

node - "$REGISTRY" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: process.argv[2] });
const tabs = sandbox.tabDefinitions();
const groups = sandbox.navigationGroupDefinitions();
assert.strictEqual(groups.map(x => x.id).join(','), 'appearance,modules,launcher,general');
assert.strictEqual(tabs.length, 15);
assert.strictEqual(new Set(tabs.map(x => x.id)).size, 15);
assert(tabs.every(x => groups.some(g => g.id === x.groupId)), 'every tab belongs to a navigation group');
assert.strictEqual(sandbox.navigationGroupIdForTabId('themes'), 'appearance');
assert.strictEqual(sandbox.navigationGroupIdForTabId('settingsWindow'), 'appearance');
assert.strictEqual(sandbox.navigationGroupIdForTabId('notifications'), 'modules');
assert.strictEqual(sandbox.navigationGroupIdForTabId('launcher'), 'launcher');
assert.strictEqual(sandbox.navigationGroupIdForTabId('general'), 'general');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('themes'), 'Внешний вид');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('notifications'), 'Модули');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('launcher'), 'Лаунчер');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('general'), 'Общие');
const defaultOrder = ['modules','themes','general','timers','player','mopidy','weather','cava','cpuRam','network','volume','calendar','launcher','notifications','settingsWindow'];
const grouped = sandbox.groupedTabOrder(defaultOrder);
assert.deepStrictEqual(Array.from(grouped), ['themes','settingsWindow','modules','timers','player','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications','launcher','general']);
assert.strictEqual(new Set(grouped).size, 15, 'grouping must preserve every page exactly once');
const customized = sandbox.groupedTabOrder(['player','modules','themes','settingsWindow','launcher','general','timers','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications']);
assert.deepStrictEqual(Array.from(customized), ['themes','settingsWindow','player','modules','timers','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications','launcher','general'], 'custom page order must remain stable within each group');
console.log('Settings grouped navigation registry: 15 pages assigned to 4 groups');
NODE

echo 'settings grouped navigation: OK'
