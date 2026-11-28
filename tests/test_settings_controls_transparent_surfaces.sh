#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
settings = root / "components/settings"
tab = (settings / "primitives/SettingsTabBase.qml").read_text()
field = (settings / "primitives/SettingsInputField.qml").read_text()
combo = (settings / "primitives/SettingsComboBox.qml").read_text()
checkbox = (settings / "primitives/SettingsCheckBox.qml").read_text()
save = (settings / "primitives/SettingsSaveButton.qml").read_text()
reset = (settings / "primitives/SettingsResetButton.qml").read_text()
widget = (settings / "SettingsWidget.qml").read_text()
assert 'property color normalBackground: "transparent"' in tab
assert 'property color selectedBackground: "transparent"' in tab
assert 'property color persistentSelectedBackground: "transparent"' in tab
assert 'color: "transparent"' in field, "text input background must be transparent"
assert combo.count('color: "transparent"') >= 1, "closed ComboBox surface must be transparent"
assert 'color: Config.settingsBackground' in combo, "popup list keeps an opaque readable menu surface"
assert 'color: root.checked ? Config.accent : "transparent"' in checkbox
assert 'property color backgroundColor: "transparent"' in save
assert 'property color backgroundColor: "transparent"' in reset
assert 'color: Config.settingsBackground' in widget, "Settings window itself keeps its configured surface"
# Section-local custom TextField/ComboBox surfaces and action button surfaces must not reintroduce fills.
for path in settings.rglob('*.qml'):
    if path.name in ("SettingsWidget.qml", "SettingsComboBox.qml"):
        continue
    source = path.read_text()
    assert 'color: Config.settingsBackground' not in source, f"resting fill remains in {path.relative_to(root)}"
    assert 'backgroundColor: Config.settingsBackground' not in source, f"button fill remains in {path.relative_to(root)}"
print("Settings controls and tabs use transparent resting surfaces; window and popup menu remain readable: OK")
PYTEST
