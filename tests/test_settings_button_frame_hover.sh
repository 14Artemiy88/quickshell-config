#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUTTON="$ROOT/components/settings/primitives/SettingsButton.qml"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
MOVE="$ROOT/components/primitives/MoveArrowButton.qml"
ICON="$ROOT/components/primitives/HoverIconButton.qml"
for file in "$BUTTON" "$RESET" "$MOVE" "$ICON"; do test -f "$file"; done

grep -Fq 'property bool fillOnHover: false' "$BUTTON"
grep -Fq 'property color outlineColor: Config.baseColor' "$BUTTON" || { echo 'SettingsButton default outlineColor is undefined' >&2; exit 1; }
grep -Fq 'root.emphasized || (root.borderOnHover && mouse.containsMouse)' "$BUTTON"
grep -Fq 'property bool fillOnHover: false' "$RESET"
grep -Fq 'visible: root.requestedVisible' "$MOVE"
grep -Fq 'opacity: (!root.hideWhenDisabled || root.interactionEnabled) ? 1 : 0' "$MOVE"
grep -Fq 'enabled: root.requestedVisible && (!root.hideWhenDisabled || root.interactionEnabled)' "$MOVE"
grep -Fq 'backgroundColor: root.hoverMode === "frame" ? Config.settingsBackground : Config.transparent' "$ICON"
grep -Fq 'borderColor: root.hoverMode === "frame" ? Config.baseColor : Config.transparent' "$ICON"
grep -Fq 'hoverBorderEnabled: root.hoverMode === "frame"' "$ICON"
for file in   "$ROOT/components/settings/sections/SettingsPlayerSection.qml"   "$ROOT/components/settings/sections/SettingsTimersSection.qml"   "$ROOT/components/settings/sections/SettingsLauncherSection.qml"   "$ROOT/components/settings/sections/mopidy/SettingsMopidyIconsSection.qml"; do
  grep -Fq 'hoverMode: "frame"' "$file"
done
echo 'Settings buttons use subtle surfaces, accent hover borders, and arrows reserve unavailable slots: OK'
