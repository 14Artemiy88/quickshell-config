#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPR='settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined'
for file in \
  "$ROOT/components/settings/SettingsWidget.qml" \
  "$ROOT/components/settings/sections/SettingsColorsSection.qml" \
  "$ROOT/components/settings/sections/SettingsModulesSection.qml" \
  "$ROOT/components/settings/sections/SettingsWindowSection.qml"; do
  grep -Fq "$EXPR" "$file" || { echo "Profile-dependent reset controls are not gated in $file" >&2; exit 1; }
done
grep -Fq 'visible: actionAvailable && settings.customThemes && settings.customThemes[settings.activeTheme] !== undefined' "$ROOT/components/settings/sections/SettingsColorsSection.qml" || { echo 'Theme delete button must be hidden for built-in themes' >&2; exit 1; }
echo 'Profile-dependent reset controls and built-in theme deletion are hidden when unavailable: OK'
