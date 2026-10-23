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
grep -q 'property var launcherTabOrder: \[0, 1, 2, 3, 4, 5, 6, 7, 8\]' "$CONFIG"
grep -q 'property var launcherTabVisible: \[true, true, true, true, true, true, true, true, true\]' "$CONFIG"
grep -q 'launcherTabOrder: \[0, 1, 2, 3, 4, 5, 6, 7, 8\]' "$DEFAULTS"
grep -q 'launcherTabVisible: \[true, true, true, true, true, true, true, true, true\]' "$DEFAULTS"
grep -q 'launcherTabOrder: JSON.parse(JSON.stringify(config.launcherTabOrder' "$PERSIST"
grep -q 'launcherTabVisible: JSON.parse(JSON.stringify(config.launcherTabVisible' "$PERSIST"
grep -q 'Config.launcherTabOrder = validLauncherOrder' "$APPLY"
grep -q 'Config.launcherTabVisible = validLauncherVisibility' "$APPLY"
grep -q '"launcherTabOrder", "launcherTabVisible", "launcherTabLabels", "launcherTabIcons", "launcherProjects"' "$RESETS"

# The unified settings navigation exposes the new subtab before/alongside common options.
grep -Fq 'case 11: return ["Общее", "Вкладки", "Проекты"]' "$WIDGET"
grep -q 'visible: root.host && root.host.currentOtherSubTab === 0' "$SECTION"
grep -q 'visible: root.host && root.host.currentOtherSubTab === 1' "$SECTION"
grep -q 'function setTabVisible(tabId, value)' "$SECTION"
grep -q 'function visibleTabCount()' "$SECTION"
grep -q 'root.visibleTabCount() > 1' "$SECTION"
grep -q 'function moveTab(tabId, delta)' "$SECTION"
grep -q 'MoveArrowButton {' "$SECTION"
grep -q 'onToggled: root.setTabVisible' "$SECTION"
grep -q 'onClicked: root.moveTab' "$SECTION"
! grep -q 'Цвета из активной темы' "$SECTION"
! grep -q 'Палитра лаунчера автоматически' "$SECTION"
! grep -q 'почти непрозрачно' "$SECTION"

# The launcher selector obeys visibility/order. Alt number shortcuts follow visible order,
# while the explicit IPC methods are separate and continue to map fixed mode IDs.
grep -q 'readonly property var displayedModeTabs' "$LAUNCHER"
grep -q 'model: root.displayedModeTabs' "$LAUNCHER"
grep -q 'root.setMode(root.displayedModeTabs\[shortcutIndex\].mode)' "$LAUNCHER"
grep -q 'function openMode(modeName)' "$LAUNCHER"

printf 'launcher tab visibility/order settings: OK\n'
