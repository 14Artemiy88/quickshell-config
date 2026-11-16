#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/primitives/MorphGeometry.qml"

# A single normalized progress value must drive every geometric property.
grep -Fq 'property rect fromGeometry:' "$QML"
grep -Fq 'property rect toGeometry:' "$QML"
grep -Fq 'property real progress: 0' "$QML"
grep -Fq 'readonly property real normalizedProgress:' "$QML"
grep -Fq 'x: geometryX' "$QML"
grep -Fq 'y: geometryY' "$QML"
grep -Fq 'width: geometryWidth' "$QML"
grep -Fq 'height: geometryHeight' "$QML"
grep -Fq 'radius: root.geometryRadius' "$QML"
grep -Fq 'default property alias contentData: contentHost.data' "$QML"
grep -Fq 'property int animationDuration: 0' "$QML"
grep -Fq 'Behavior on progress' "$QML"
grep -Fq 'enabled: root.animationDuration > 0' "$QML"

# The settings theme chooser must use the shared geometry primitive for its expand/collapse.
SETTINGS_COLORS="$ROOT/components/settings/sections/SettingsColorsSection.qml"
grep -Fq 'import "../../primitives"' "$SETTINGS_COLORS"
grep -Fq 'MorphGeometry {' "$SETTINGS_COLORS"
grep -Fq 'progress: root.themesExpanded ? 1 : 0' "$SETTINGS_COLORS"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$SETTINGS_COLORS"
grep -Fq 'toGeometry: Qt.rect(0, 0, parent.width, expandedThemeContent.implicitHeight)' "$SETTINGS_COLORS"
grep -Fq 'animationEasing: Config.animationEasingType("standard", root.themesExpanded ? "enter" : "exit")' "$SETTINGS_COLORS"
grep -Fq 'readonly property bool showThemeCombo: !root.themesExpanded' "$SETTINGS_COLORS"
grep -Fq 'expandedThemeList.normalizedProgress <= 0.001' "$SETTINGS_COLORS"
grep -Fq 'height: showThemeCombo || showModifiedThemeName ? 30 : 0' "$SETTINGS_COLORS"
grep -Fq 'visible: themeSelectorSlot.showThemeCombo' "$SETTINGS_COLORS"
grep -Fq 'visible: themeSelectorSlot.showModifiedThemeName' "$SETTINGS_COLORS"
if grep -Fq 'id: modifiedThemeNameMorph' "$SETTINGS_COLORS"; then
  echo 'Modified-theme input replacement must not use MorphGeometry' >&2
  exit 1
fi

# Guard the endpoints and prevent negative dimensions/radii during interpolation.
grep -Fq 'Math.max(0, Math.min(1, Number(progress) || 0))' "$QML"
grep -Fq 'Math.max(0, fromGeometry.width +' "$QML"
grep -Fq 'Math.max(0, fromGeometry.height +' "$QML"
grep -Fq 'Math.max(0, fromRadius +' "$QML"

printf 'MorphGeometry interpolation and Settings theme-list integration: OK\n'
