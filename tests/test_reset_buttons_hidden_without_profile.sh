#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTROLLER="$ROOT/components/settings/SettingsProfileController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
COLORS="$ROOT/components/settings/sections/SettingsColorsSection.qml"
MODULES="$ROOT/components/settings/sections/SettingsModulesSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

grep -Fq 'readonly property bool hasActiveProfile:' "$CONTROLLER"
grep -Fq 'Object.prototype.hasOwnProperty.call(settings.profiles, name)' "$CONTROLLER"
grep -Fq 'return root.hasActiveProfile && key.length > 0' "$CONTROLLER"
grep -Fq 'profileController.canResetScope(root.currentPageSaveScope)' "$WIDGET"
for file in "$COLORS" "$MODULES" "$WINDOW"; do
  grep -Fq 'profileController.hasActiveProfile' "$file" || { echo "Profile-dependent controls are not gated by the shared controller in $file" >&2; exit 1; }
done
grep -Fq 'visible: actionAvailable && settings.isCustomTheme(settings.activeTheme)' "$COLORS" || { echo 'Theme delete button must be hidden for built-in themes' >&2; exit 1; }
echo 'Profile-dependent reset controls and built-in theme deletion are hidden when unavailable: OK'
