#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
CONFIG="$ROOT/Config.qml"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }

# All ten built-in modes remain represented and user-customizable.
need "$LAUNCHER" 'readonly property var defaultModeTabs: ['
for mode in modeApps modeRun modeWindows modeClipboard modePower modeNetwork modeNix modePass modeProjects modeCalculator; do
  need "$LAUNCHER" "mode: root.$mode"
done
need "$LAUNCHER" 'var labels = Config.launcherTabLabels instanceof Array'
need "$LAUNCHER" 'var icons = Config.launcherTabIcons instanceof Array'
need "$LAUNCHER" 'function normalizedModeTabOrder()'
need "$LAUNCHER" 'readonly property var displayedModeTabs:'

# Search stays mode-aware, supports text selection and keyboard navigation.
need "$LAUNCHER" 'id: searchField'
need "$LAUNCHER" 'selectByMouse: true'
need "$LAUNCHER" 'Keys.priority: Keys.BeforeItem'
need "$LAUNCHER" 'Keys.onPressed: function(event)'
need "$LAUNCHER" 'event.key === Qt.Key_Return || event.key === Qt.Key_Enter'
need "$LAUNCHER" 'readonly property var calculatorEvaluation: Calculator.evaluate(searchField.text)'
need "$LAUNCHER" 'function buildCalculatorResults()'

# Window sizing remains driven by the existing persisted launcher dimensions;
# this audit does not silently introduce screen-specific geometry overrides.
need "$CONFIG" 'property int launcherWidth: 720'
need "$CONFIG" 'property int launcherHeight: 640'
need "$LAUNCHER" 'width: Config.launcherWidth'
need "$LAUNCHER" 'height: Config.launcherHeight'
need "$LAUNCHER" 'Settings.geometryForLayout("launcher")'
need "$LAUNCHER" 'root.launcherUiScale'

# The list/grid content clips within its viewport and app tiles use its live width.
need "$LAUNCHER" 'clip: true'
need "$LAUNCHER" 'cellWidth: root.wallpaperPickerActive && !root.wallpaperRandomMode ? width / wallpaperColumnCount : width'
need "$LAUNCHER" 'elide: Text.ElideRight'

echo 'Launcher audit contract: modes, search, calculator, keyboard navigation and geometry passed'
