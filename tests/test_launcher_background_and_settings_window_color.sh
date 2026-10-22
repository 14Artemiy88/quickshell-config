#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
THEME="$ROOT/components/launcher/theme/Theme.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
COLORS="$ROOT/components/settings/sections/SettingsColorsSection.qml"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"

grep -Fq 'property color launcherBackground: "#e6000000"' "$CONFIG"
grep -Fq 'readonly property color launcherBackground: Config.launcherBackground' "$THEME"
grep -Fq '? theme.launcherBackground : theme.transparent' "$LAUNCHER"
grep -Fq 'targetProperty: "launcherBackground"' "$SECTION"
grep -Fq 'launcherBackground: String(config.launcherBackground)' "$PERSIST"
grep -Fq 'Schema.normalizeSavedColor(o.launcherBackground' "$APPLY"
grep -Fq '"launcherBackground"' "$RESETS"
grep -Fq '"launcherDefaultMode"' "$RESETS"
grep -Fq 'launcherBackground: "#e6000000"' "$DEFAULTS"
grep -Fq 'label: "Фон окна настроек"' "$WINDOW"
grep -Fq 'targetProperty: "settingsBackground"' "$WINDOW"
# The theme editor should no longer provide the settings-background field; it is now under Settings Window.
if grep -Fq '"settingsBackground", "settingsBorder"' "$COLORS"; then
  echo 'Settings background color was not moved out of the theme editor' >&2
  exit 1
fi
grep -Fq 'settingsBorder", "settingsSubheading' "$COLORS"
grep -Fq 'config.settingsBackground = profile.colors.settingsBackground' "$RESETS"
echo 'Launcher background and settings-window background settings: OK'
