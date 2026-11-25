#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

# Persisted tab visibility/order have stable defaults and participate in profiles.
grep -q 'property var launcherTabOrder: \[0, 1, 2, 3, 4, 5, 6, 7, 8, 9\]' "$CONFIG"
grep -q 'property var launcherTabVisible: \[true, true, true, true, true, true, true, true, true, true\]' "$CONFIG"
grep -q 'launcherTabOrder: \[0, 1, 2, 3, 4, 5, 6, 7, 8, 9\]' "$DEFAULTS"
grep -q 'launcherTabVisible: \[true, true, true, true, true, true, true, true, true, true\]' "$DEFAULTS"
grep -q 'launcherTabOrder: JSON.parse(JSON.stringify(config.launcherTabOrder' "$PERSIST"
grep -q 'launcherTabVisible: JSON.parse(JSON.stringify(config.launcherTabVisible' "$PERSIST"
grep -q 'Config.launcherTabOrder = validLauncherOrder' "$APPLY"
grep -q 'Config.launcherTabVisible = validLauncherVisibility' "$APPLY"
grep -q 'launcherTabOrder.*launcherTabVisible.*launcherTabLabels.*launcherTabIcons.*launcherProjects' "$RESETS"

# The unified settings navigation exposes the new subtab before/alongside common options.
grep -Fq '{ id: "launcherTabs", saveScope: "launcher", subTabs: [] }' "$ROOT/js/settings/SettingsPageRegistry.js"
grep -Fq '{ id: "launcher", saveScope: "launcher", subTabs: ["Общее", "Навигация", "Оформление", "Поиск"] }' "$ROOT/js/settings/SettingsPageRegistry.js"
grep -q 'currentPageId === "launcherTabs"' "$SECTION"
grep -q 'objectName: "settings-search-page:launcherTabs"' "$SECTION"
grep -q 'function setTabVisible(tabId, value)' "$SECTION"
grep -q 'function visibleTabCount()' "$SECTION"
grep -q 'root.visibleTabCount() <= 1' "$SECTION"
! grep -q 'enabled: launcherTabRow.modelData.visible' "$SECTION"
grep -q 'function moveTab(tabId, delta)' "$SECTION"
grep -q 'function moveTabToIndex(tabId, destination)' "$SECTION"
grep -q 'DragReorderHandle {' "$SECTION"
grep -q 'listRepeater: launcherTabsRepeater' "$SECTION"
grep -q 'onToggled: root.setTabVisible' "$SECTION"

# Hidden tabs remain re-enableable even when only one other tab is visible.
node - "$SECTION" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8');
const start = source.indexOf('    function visibleTabCount() {');
const end = source.indexOf('    function moveTab(tabId, delta) {', start);
assert(start >= 0 && end > start, 'tab visibility functions exist');
const context = {
  Config: {},
  root: { tabDefinitions: Array.from({ length: 10 }, (_, id) => ({ id })), settings: { save() {} } }
};
vm.createContext(context);
vm.runInContext('Config.launcherTabVisible = [true, true, false, false, false, false, false, false, false, false];', context);
vm.runInContext(source.slice(start, end) + '\nroot.visibleTabCount = visibleTabCount; root.setTabVisible = setTabVisible;', context);
context.root.setTabVisible(0, false);
assert.strictEqual(context.Config.launcherTabVisible[0], false, 'Apps can be disabled while Run remains visible');
context.root.setTabVisible(0, true);
assert.strictEqual(context.Config.launcherTabVisible[0], true, 'Apps can be re-enabled when Run is the only visible tab');
context.root.setTabVisible(1, false);
assert.strictEqual(context.Config.launcherTabVisible[1], false, 'Run can be disabled while Apps remains visible');
context.root.setTabVisible(1, true);
assert.strictEqual(context.Config.launcherTabVisible[1], true, 'Run can be re-enabled when Apps is the only visible tab');
context.root.setTabVisible(0, false);
context.root.setTabVisible(1, false);
assert.strictEqual(context.Config.launcherTabVisible[1], true, 'the last visible tab cannot be disabled');
JS
grep -q 'root.moveTabToIndex(launcherTabRow.modelData.id, toIndex)' "$SECTION"
! grep -q 'Цвета из активной темы' "$SECTION"
! grep -q 'Палитра лаунчера автоматически' "$SECTION"
! grep -q 'почти непрозрачно' "$SECTION"

# The launcher selector obeys visibility/order. Alt number shortcuts follow visible order,
# while the explicit IPC methods are separate and continue to map fixed mode IDs.
grep -q 'readonly property var displayedModeTabs' "$LAUNCHER"
grep -q 'model: root.displayedModeTabs' "$LAUNCHER"
grep -q 'root.setMode(root.displayedModeTabs\[shortcutIndex\].mode)' "$LAUNCHER"
grep -q 'function openMode(modeName)' "$LAUNCHER"
grep -q 'root.modeCalculator' "$LAUNCHER"
grep -q '{ id: 9, label: "Calculator", icon: "󰃬" }' "$SECTION"

printf 'launcher tab visibility/order settings: OK\n'
