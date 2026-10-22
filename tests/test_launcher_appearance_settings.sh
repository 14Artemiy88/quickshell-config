#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
for key in launcherTitleText launcherTitleFont launcherTitleFontSize launcherTitleLetterSpacing launcherTitleBold launcherSearchFont launcherSearchFontSize launcherSearchHeight launcherSearchRadius launcherSearchBackground launcherSearchPlaceholder; do
  grep -Fq "$key" "$CONFIG"
  grep -Fq "$key" "$DEFAULTS"
  grep -Fq "$key" "$PERSIST"
  grep -Fq "$key" "$APPLY"
  grep -Fq "$key" "$RESETS"
  grep -Fq "$key" "$SECTION"
done
grep -Fq 'text: Config.launcherTitleText' "$LAUNCHER"
grep -Fq 'font.pixelSize: Config.launcherTitleFontSize' "$LAUNCHER"
grep -Fq 'font.family: Config.launcherSearchFont.trim() === "" ? "" : Config.launcherSearchFont' "$LAUNCHER"
grep -Fq 'text: Config.launcherSearchPlaceholder' "$ROOT/components/settings/sections/SettingsLauncherSection.qml"
grep -Fq 'return Config.launcherSearchPlaceholder' "$LAUNCHER"
grep -Fq 'visible: root.mode !== root.modePower' "$LAUNCHER"
grep -Fq 'focus: root.mode === root.modePower' "$LAUNCHER"
grep -Fq 'Keys.onPressed: function(event)' "$LAUNCHER"
grep -Fq 'if (root.mode === root.modePower)' "$LAUNCHER"
grep -Fq 'root.activate()' "$LAUNCHER"
if grep -Fq 'return "Power..."' "$LAUNCHER"; then
  echo 'Power search placeholder still exists' >&2
  exit 1
fi
echo 'Launcher title/search appearance settings and Power search removal: OK'
