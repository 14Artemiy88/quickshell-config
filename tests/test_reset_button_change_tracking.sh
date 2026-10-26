#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$ROOT/Settings.qml"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
for token in 'function hasResetChanges(scope, argument)' 'var overrides = root.resetOverrides || {}' 'function hasNested(mapName, key)' 'scope === "colors"' 'scope === "module"' 'scope === "all"'; do
  grep -Fq "$token" "$SETTINGS" || { echo "Reset change tracking missing: $token" >&2; exit 1; }
done
grep -Fq 'onClicked: root.clicked()' "$RESET" || { echo 'Reset button still hides itself on click rather than following value changes' >&2; exit 1; }
grep -Fq 'actionAvailable: settings.hasResetChanges("colors", modelData.colors)' "$ROOT/components/settings/sections/SettingsColorsSection.qml" || { echo 'Per-color-group reset button lacks change tracking' >&2; exit 1; }
grep -Fq 'actionAvailable: settings.hasResetChanges("module", moduleRow.moduleName)' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || { echo 'Per-module reset button lacks change tracking' >&2; exit 1; }
grep -Fq 'actionAvailable: root.currentOtherTab === 0 ? settings.hasResetChanges("general")' "$WIDGET" || { echo 'Per-tab reset button lacks change tracking' >&2; exit 1; }
echo 'Reset buttons follow sparse settings.json profileOverrides presence: OK'
