#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# The grouped sidebar is rendered from four fixed semantic groups, including the Launcher folder.
grep -Fq 'model: root.navigationGroups' "$NAV"
grep -Fq 'function toggleSettingsNavigationGroup(id)' "$WIDGET"
grep -Fq 'function expandSettingsNavigationGroupForPage(pageId)' "$WIDGET"
grep -Fq 'root.expandSettingsNavigationGroupForPage(id)' "$WIDGET"
grep -Fq 'root.host.expandSettingsNavigationGroupForPage(entry.pageId)' "$ROOT/components/settings/SettingsSearchController.qml"
grep -Fq 'ScrollBar.vertical: SettingsScrollBar' "$NAV"
grep -Fq 'root.host.settingsSearchNavigationGroupHasMatches(modelData.id)' "$NAV"
grep -Fq 'root.host.settingsNavigationGroupHasCurrentPage(modelData.id)' "$NAV"
grep -Fq 'if (modelData.items.length === 1)' "$NAV"
grep -Fq 'visible: navigationGroupDelegate.modelData.items.length > 1' "$NAV"
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
assert.strictEqual(groups.map(x => x.id).join(','), 'appearance,modules,dashboard,launcher,general');
assert.strictEqual(tabs.length, 22);
assert.strictEqual(new Set(tabs.map(x => x.id)).size, 22);
assert(tabs.every(x => groups.some(g => g.id === x.groupId)), 'every tab belongs to a navigation group');
assert.strictEqual(sandbox.navigationGroupIdForTabId('themes'), 'appearance');
assert.strictEqual(sandbox.navigationGroupIdForTabId('settingsWindow'), 'appearance');
assert.strictEqual(sandbox.navigationGroupIdForTabId('notifications'), 'modules');
assert.strictEqual(sandbox.navigationGroupIdForTabId('dashboard'), 'dashboard');
assert.strictEqual(sandbox.navigationGroupIdForTabId('launcher'), 'launcher');
assert.strictEqual(sandbox.navigationGroupIdForTabId('general'), 'general');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('themes'), 'Внешний вид');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('notifications'), 'Модули');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('dashboard'), 'Dashboard');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('launcher'), 'Лаунчер');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('general'), 'Общие');
const defaultOrder = ['modules','dashboard','themes','general','timers','player','mopidy','weather','cava','cpuRam','network','volume','calendar','launcher','launcherSearch','launcherTabs','launcherProjects','launcherActions','launcherAnimation','launcherApplications','notifications','settingsWindow'];
const grouped = sandbox.groupedTabOrder(defaultOrder);
assert.deepStrictEqual(Array.from(grouped), ['themes','settingsWindow','modules','timers','player','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications','dashboard','launcher','launcherSearch','launcherTabs','launcherProjects','launcherActions','launcherAnimation','launcherApplications','general']);
assert.strictEqual(new Set(grouped).size, 22, 'grouping must preserve every page exactly once');
const customized = sandbox.groupedTabOrder(['player','modules','dashboard','themes','settingsWindow','launcher','launcherActions','launcherSearch','launcherProjects','launcherTabs','launcherAnimation','launcherApplications','general','timers','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications']);
assert.deepStrictEqual(Array.from(customized), ['themes','settingsWindow','player','modules','timers','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications','dashboard','launcher','launcherActions','launcherSearch','launcherProjects','launcherTabs','launcherAnimation','launcherApplications','general'], 'custom page order must remain stable within each group');
console.log('Settings grouped navigation registry: 22 pages assigned to 5 groups');
NODE

echo 'settings grouped navigation: OK'
