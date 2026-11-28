#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/settings/sections/SettingsColorsSection.qml").read_text()
assert 'delegate: SettingsGroup {' in source
assert 'showFrame: true' in source
assert 'heading: modelData.title' in source
assert 'SettingsSaveButton {' in source and 'SettingsResetButton {' in source
assert 'host.profileController.saveScope("colors", modelData.colors)' in source
assert 'settings.resetColors(modelData.colors)' in source
assert 'SettingsColorField {' in source and 'onValueEdited: function(value) { settings.setThemeDraftColor(colorName, value) }' in source
print("Theme editor palette categories have independent frames and retain scoped Save/Reset: OK")
PYTEST
