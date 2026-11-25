#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherBuiltinActions.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SHELL="$ROOT/shell.qml"
DASH="$ROOT/components/Dashboard.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
README="$ROOT/README.md"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ toolActions, knownIds, isEnabled, setEnabled })');
assert(api.toolActions.some(item => item.id === 'tool.dashboard'), 'Dashboard must have a stable built-in tool ID');
assert(api.isEnabled([], 'tool.dashboard'), 'Dashboard command must be enabled by default');
const disabled = api.setEnabled([], 'tool.dashboard', false);
assert(!api.isEnabled(disabled, 'tool.dashboard'), 'Dashboard command must be independently disableable');
assert(api.isEnabled(disabled, 'tool.colorSchemes'), 'Dashboard toggle must not affect other built-in tools');
JS

python3 - "$LAUNCHER" "$SHELL" "$DASH" "$SETTINGS" "$NAV" "$README" <<'PY'
from pathlib import Path
import sys
launcher, shell, dash, settings, nav, readme = [Path(p).read_text() for p in sys.argv[1:]]
assert 'signal dashboardRequested()' in launcher, 'Launcher must expose a Dashboard request signal'
assert 'function activateAppsSearchResult(result)' in launcher
activation = launcher[launcher.index('function activateAppsSearchResult(result)'):]
assert 'if (result.kind === "dashboardAction")' in activation
assert 'root.dashboardRequested()' in activation and 'root.hideLauncher()' in activation
palette = launcher[launcher.index('function buildLauncherActionResults'):launcher.index('function russianApplicationCount')]
assert 'builtinActionEnabled("tool.dashboard")' in palette
assert 'kind: "dashboardAction"' in palette
assert 'overview overview-panel system dashboard panel summary обзор обзорная панель сводка панель системы' in palette
# The generic Apps-result delegate must render this result type just like other built-in tools.
name_fn = launcher[launcher.index('function appsResultName'):launcher.index('function appsResultSubtitle')]
subtitle_fn = launcher[launcher.index('function appsResultSubtitle'):launcher.index('function buildAppsUnifiedResults')]
assert 'case "dashboardAction": return String(itemData.name || "Dashboard")' in name_fn
assert 'case "dashboardAction":' in subtitle_fn and 'ОБЗОР · Быстрая сводка системы · >dashboard' in subtitle_fn
assert 'appDelegate.itemData.kind === "dashboardAction"' in launcher, 'Dashboard action must have a visible icon fallback'
assert 'appDelegate.itemData.kind === "dashboardAction"' in launcher[launcher.index('text: root.highlightFuzzy('):launcher.index('textFormat: Text.StyledText', launcher.index('text: root.highlightFuzzy('))], 'Dashboard action name must use the palette query for highlighting'
# The generic Apps-result delegate must render this result type just like other built-in tools.
name_fn = launcher[launcher.index('function appsResultName'):launcher.index('function appsResultSubtitle')]
subtitle_fn = launcher[launcher.index('function appsResultSubtitle'):launcher.index('function buildAppsUnifiedResults')]
assert 'case "dashboardAction": return String(itemData.name || "Dashboard")' in name_fn
assert 'case "dashboardAction":' in subtitle_fn and 'ОБЗОР · Быстрая сводка системы · >dashboard' in subtitle_fn
app_delegate = launcher[launcher.index('Text {\n                                    anchors.centerIn: parent\n                                    visible: !appIconImage.visible', launcher.index('kind === "appCategory"')):launcher.index('ColumnLayout {\n                                Layout.fillWidth: true', launcher.index('kind === "appCategory"'))]
assert 'appDelegate.itemData.kind === "dashboardAction"' in app_delegate, 'Dashboard action must have a visible icon fallback'
assert 'appDelegate.itemData.kind === "dashboardAction"' in launcher[launcher.index('text: root.highlightFuzzy('):launcher.index('textFormat: Text.StyledText', launcher.index('text: root.highlightFuzzy('))], 'Dashboard action name must use the palette query for highlighting'
assert 'function onDashboardRequested() { if (Settings.dashboard) shell.dashboardVisible = true }' in shell
assert 'open: Settings.dashboard && shell.dashboardVisible' in shell
assert 'target: launcherLoader.status === Loader.Ready ? launcherLoader.item : null' in shell
assert 'visible: Settings.loaded && Settings.dashboard && (root.open || root.keepWindowDuringClose || root.layoutEditMode)' in dash
assert 'onOpenChanged:' in dash and 'closeWindowTimer.restart()' in dash
assert 'height: targetHeight' in dash and 'Math.min(600, Math.max(420, cards.implicitHeight + 280))' in dash
assert 'Math.max(1, parent.width - 32)' in dash
assert 'function resolveDashboardScreen()' in dash
assert 'tool.dashboard' in settings and 'tool.dashboard' in nav
assert '`>dashboard`' in readme and '`>overview`' in readme and '`>обзор`' in readme
assert 'visible: Settings.loaded\n' not in dash, 'Dashboard may not keep its fullscreen host visible while closed'
print('Dashboard launcher entry, visibility lifecycle, bounded drawer geometry and settings toggle: OK')
PY

echo 'dashboard launcher entry: OK'
