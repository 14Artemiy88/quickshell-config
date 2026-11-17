#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$ROOT/Settings.qml"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
HOST="$ROOT/components/settings/SettingsPageHost.qml"
for token in 'function hasResetChanges(scope, argument)' 'var overrides = root.resetOverrides || {}' 'function hasNested(mapName, key)' 'scope === "colors"' 'scope === "module"' 'scope === "all"'; do
  grep -Fq "$token" "$SETTINGS" || { echo "Reset change tracking missing: $token" >&2; exit 1; }
done
grep -Fq 'onClicked: root.clicked()' "$RESET" || { echo 'Reset button still hides itself on click rather than following value changes' >&2; exit 1; }
grep -Fq 'actionAvailable: host.profileController.canResetScope("colors", modelData.colors)' "$ROOT/components/settings/sections/SettingsColorsSection.qml" || { echo 'Per-color-group reset button lacks change tracking' >&2; exit 1; }
grep -Fq 'actionAvailable: host.profileController.canResetScope("module", moduleRow.moduleName)' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || { echo 'Per-module reset button lacks change tracking' >&2; exit 1; }
grep -Fq 'root.host.currentPageSaveScope !== ""' "$HOST" || { echo 'Per-tab reset button lacks its stable save scope' >&2; exit 1; }
grep -Fq 'root.host.profileController.canResetScope(root.host.currentPageSaveScope)' "$HOST" || { echo 'Per-tab reset button lacks change tracking' >&2; exit 1; }
grep -Fq 'function resetCurrentSettingsPage()' "$WIDGET" || { echo 'Per-tab reset dispatch must use stable page IDs' >&2; exit 1; }
echo 'Reset buttons follow sparse settings.json profileOverrides presence: OK'
