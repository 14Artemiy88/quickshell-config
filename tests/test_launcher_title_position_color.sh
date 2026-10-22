#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
for key in launcherTitleY launcherTitleColor; do
  grep -Fq "$key" "$CONFIG"
  grep -Fq "$key" "$DEFAULTS"
  grep -Fq "$key" "$PERSIST"
  grep -Fq "$key" "$APPLY"
  grep -Fq "$key" "$RESETS"
  grep -Fq "$key" "$SECTION"
  grep -Fq "$key" "$LAUNCHER"
done
grep -Fq 'minimum: -40; maximum: 40' "$SECTION"
grep -Fq 'targetProperty: "launcherTitleY"' "$SECTION"
grep -Fq 'label: "Цвет заголовка"' "$SECTION"
grep -Fq 'targetProperty: "launcherTitleColor"' "$SECTION"
grep -Fq 'color: Config.launcherTitleColor' "$LAUNCHER"
grep -Fq 'transform: Translate { y: Config.launcherTitleY }' "$LAUNCHER"
# Old configs without these optional keys keep defaults; explicit colors use standard validation.
grep -Fq 'launcherTitleY: 0' "$DEFAULTS"
grep -Fq 'launcherTitleColor: "#ffffff"' "$DEFAULTS"
grep -Fq 'Schema.normalizeSavedColor(o.launcherTitleColor' "$APPLY"
grep -Fq 'if (profile.launcherTitleY === undefined) config.launcherTitleY = 0' "$RESETS"
grep -Fq 'if (profile.launcherTitleColor === undefined) config.launcherTitleColor = "#ffffff"' "$RESETS"
echo 'Launcher title Y offset and color settings/persistence/profile reset: OK'
