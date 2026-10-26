#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"

# New preferences have backwards-compatible defaults and are part of the
# settings snapshot/profile/default reset pipeline.
grep -q 'property int launcherDefaultMode: 0' "$CONFIG"
grep -q 'property bool launcherShowResultCount: true' "$CONFIG"
grep -q 'launcherDefaultMode: 0' "$ROOT/js/settings/SettingsDefaults.js"
grep -q 'launcherShowResultCount: true' "$ROOT/js/settings/SettingsDefaults.js"
grep -q 'launcherDefaultMode: config.launcherDefaultMode' "$ROOT/js/settings/SettingsPersistence.js"
grep -q 'launcherShowResultCount: config.launcherShowResultCount' "$ROOT/js/settings/SettingsPersistence.js"
grep -q 'Config.launcherDefaultMode = isFinite(launcherMode)' "$ROOT/js/settings/SettingsApplySystemVisual.js"
grep -q 'Config.launcherShowResultCount = !!o.launcherShowResultCount' "$ROOT/js/settings/SettingsApplySystemVisual.js"
grep -q '"launcherDefaultMode", "launcherShowResultCount"' "$ROOT/js/settings/SettingsResets.js"

# User-facing controls are part of the shared settings section and save into
# existing Settings/profile infrastructure, rather than a standalone ini.
grep -q 'Вкладка по умолчанию' "$SECTION"
grep -q 'Config.launcherDefaultMode = Math.max(0, Math.min(9, index))' "$SECTION"
grep -q 'Показывать счётчик RESULTS' "$SECTION"
grep -q 'Config.launcherShowResultCount = checked' "$SECTION"
grep -q 'root.settings.save()' "$SECTION"
! grep -q 'launcher-settings.ini' "$ROOT/components/launcher/Launcher.qml"

# Toggle uses the configured default tab; explicit tab IPC calls remain direct.
grep -q 'function configuredDefaultMode()' "$LAUNCHER"
grep -q 'case "default": return root.configuredDefaultMode()' "$LAUNCHER"
grep -q 'visible: Config.launcherShowResultCount' "$LAUNCHER"
grep -q 'showLauncherMode("default")' "$ROOT/shell.qml"
for mode in Apps Run Windows Clipboard Network Nix Pass Power Projects Calculator; do
    grep -q "root.pointerHoveredMode === root.mode${mode}" "$LAUNCHER"
done

# Pointer hover is centrally tracked and requires real pointer movement after layout changes.
grep -q 'HoverHandler {' "$LAUNCHER"
grep -q 'function pointerIndexForList(activeList)' "$LAUNCHER"
grep -q 'function refreshHoverForMode()' "$LAUNCHER"
grep -q 'function refreshHoverVisualsForMode()' "$LAUNCHER"
grep -q 'onContentYChanged: root.disarmPointerHover()' "$LAUNCHER"
grep -q 'function disarmPointerHover()' "$LAUNCHER"
grep -q 'function updatePointerPosition(point)' "$LAUNCHER"
grep -q 'function activatePointerHoverAtCurrentPosition()' "$LAUNCHER"
! grep -qE '(appDelegate|runDelegate|windowDelegate|clipboardDelegate|networkDelegate|nixDelegate|passDelegate|powerDelegate)\.hovered[[:space:]]*=' "$LAUNCHER"

echo 'launcher preferences and centralized hover: OK'
