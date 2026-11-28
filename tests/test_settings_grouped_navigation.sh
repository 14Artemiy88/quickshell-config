#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# The grouped sidebar is rendered from six semantic folders; page membership is user-customizable.
grep -Fq 'model: root.navigationGroups' "$NAV"
grep -Fq 'function toggleSettingsNavigationGroup(id)' "$WIDGET"
grep -Fq 'function expandSettingsNavigationGroupForPage(pageId)' "$WIDGET"
grep -Fq 'root.expandSettingsNavigationGroupForPage(id)' "$WIDGET"
grep -Fq 'root.host.expandSettingsNavigationGroupForPage(entry.pageId)' "$ROOT/components/settings/SettingsSearchController.qml"
grep -Fq 'ScrollBar.vertical: SettingsScrollBar' "$NAV"
grep -Fq 'SettingsNavigationFolder {' "$NAV"
grep -Fq 'searchMatchCount: root.host.settingsSearchNavigationGroupMatchCount(groupId)' "$NAV"
grep -Fq 'border.width: root.searchMatchCount > 0' "$FOLDER"
grep -Fq 'SettingsNavigationVisualState.shouldShowCollapsedPageHint(' "$NAV"
grep -Fq 'currentPageLabel: collapsedWithCurrentPage' "$NAV"
grep -Fq 'visible: modelData.items.length === 1' "$NAV"
grep -Fq 'visible: navigationGroupDelegate.modelData.items.length !== 1' "$NAV"
grep -Fq 'function settingsTabCanMove(id, delta)' "$CONTROLLER"
grep -Fq 'function settingsTabCanMoveWithinGroup(groupId, id, delta)' "$CONTROLLER"
grep -Fq 'function moveSettingsTabWithinGroup(groupId, id, delta)' "$CONTROLLER"
grep -Fq 'listRepeater: settingsNavigationPagesOrderRepeater' "$WINDOW"
grep -Fq 'host.moveSettingsTabWithinGroupTo(' "$WINDOW"
grep -Fq 'host.moveSettingsTabToGroup(pageId, targetGroupId, targetIndex)' "$WINDOW"

node - "$REGISTRY" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: process.argv[2] });
const tabs = sandbox.tabDefinitions();
const groups = sandbox.navigationGroupDefinitions();
assert.strictEqual(groups.map(x => x.id).join(','), 'appearance,modules,dashboard,launcher,notifications,general');
assert.strictEqual(tabs.length, 26);
assert.strictEqual(new Set(tabs.map(x => x.id)).size, 26);
assert(tabs.every(x => groups.some(g => g.id === x.groupId)), 'every tab belongs to a navigation group');
assert.strictEqual(sandbox.navigationGroupIdForTabId('themes'), 'appearance');
assert.strictEqual(sandbox.navigationGroupIdForTabId('settingsWindow'), 'appearance');
assert.strictEqual(sandbox.navigationGroupIdForTabId('notifications'), 'notifications');
assert.strictEqual(sandbox.navigationGroupIdForTabId('dashboard'), 'dashboard');
assert.strictEqual(sandbox.navigationGroupIdForTabId('launcher'), 'launcher');
assert.strictEqual(sandbox.navigationGroupIdForTabId('general'), 'general');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('themes'), 'Внешний вид');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('notifications'), 'Уведомления');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('dashboard'), 'Dashboard');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('launcher'), 'Лаунчер');
assert.strictEqual(sandbox.navigationGroupLabelForTabId('general'), 'Общие');
const defaultOrder = ['modules','time','dashboard','themes','interface','general','timers','player','mopidy','weather','cava','cpuRam','network','volume','osd','calendar','launcher','launcherSearch','launcherTabs','launcherProjects','launcherActions','launcherAnimation','launcherApplications','notifications','notificationsDnd','settingsWindow'];
const grouped = sandbox.groupedTabOrder(defaultOrder);
assert.deepStrictEqual(Array.from(grouped), ['themes','interface','settingsWindow','modules','time','timers','player','mopidy','weather','cava','cpuRam','network','volume','osd','calendar','dashboard','launcher','launcherSearch','launcherTabs','launcherProjects','launcherActions','launcherAnimation','launcherApplications','notifications','notificationsDnd','general']);
assert.strictEqual(new Set(grouped).size, 26, 'grouping must preserve every page exactly once');
const customized = sandbox.groupedTabOrder(['player','modules','time','dashboard','themes','interface','settingsWindow','launcher','launcherActions','launcherSearch','launcherProjects','launcherTabs','launcherAnimation','launcherApplications','general','timers','mopidy','weather','cava','cpuRam','network','volume','calendar','notifications','notificationsDnd']);
assert.deepStrictEqual(Array.from(customized), ['themes','interface','settingsWindow','player','modules','time','timers','mopidy','weather','cava','cpuRam','network','volume','calendar','dashboard','launcher','launcherActions','launcherSearch','launcherProjects','launcherTabs','launcherAnimation','launcherApplications','notifications','notificationsDnd','general'], 'custom page order must remain stable within each group');
console.log('Settings grouped navigation registry: 26 pages assigned to 6 groups');
NODE

echo 'settings grouped navigation: OK'
