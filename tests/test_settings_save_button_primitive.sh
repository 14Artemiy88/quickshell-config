#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAVE="$ROOT/components/settings/primitives/SettingsSaveButton.qml"
RESET="$ROOT/components/settings/primitives/SettingsResetButton.qml"
BUTTON="$ROOT/components/settings/primitives/SettingsButton.qml"
for file in "$SAVE" "$RESET" "$BUTTON"; do test -f "$file"; done

grep -Fq 'property bool actionAvailable: true' "$SAVE"
grep -Fq 'visible: enabled && actionAvailable' "$SAVE"
grep -Fq 'SettingsButton {' "$SAVE"
grep -Fq 'anchors.fill: parent' "$SAVE"
grep -Fq 'onClicked: root.clicked()' "$SAVE"
grep -Fq 'backgroundColor: root.backgroundColor' "$SAVE"
grep -Fq 'tooltip: root.tooltip' "$SAVE"
grep -Fq 'width: 30' "$SAVE"
grep -Fq 'height: 30' "$SAVE"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
files = [
    root / 'components/settings/SettingsPageHost.qml',
    root / 'components/settings/sections/SettingsModulesSection.qml',
    root / 'components/settings/sections/SettingsColorsSection.qml',
]
for path in files:
    source = path.read_text(encoding='utf-8')
    assert 'SettingsSaveButton {' in source, f'{path.name} does not use the shared save primitive'
    assert 'SettingsButton {\n' not in source or 'iconText: "\\uf0c7"' not in source, f'{path.name} keeps a manual scoped-save button'
    assert 'backgroundColor: Config.settingsBackground' not in source or 'iconText: "\\uf0c7"' not in source, f'{path.name} duplicates save-button surface styling'

host = files[0].read_text(encoding='utf-8')
modules = files[1].read_text(encoding='utf-8')
colors = files[2].read_text(encoding='utf-8')
assert 'actionAvailable: root.host && root.host.quickSaveProfileAvailable' in host
assert 'actionAvailable: root.host && root.host.quickSavePageAvailable' in host
assert 'onClicked: root.host.profileController.saveAll()' in host
assert 'onClicked: root.host.profileController.saveScope(root.host.currentPageSaveScope)' in host
for source, token in [
    (modules, 'host.profileController.canSaveScope("modules")'),
    (modules, 'host.profileController.canSaveScope("module", moduleRow.moduleName)'),
    (modules, 'host.profileController.canSaveScope("launcher")'),
    (colors, 'host.profileController.canSaveScope("themes")'),
    (colors, 'host.profileController.canSaveScope("colors", modelData.colors)'),
]:
    assert token in source, f'missing scoped-save availability: {token}'
assert 'SettingsResetButton {' in host and 'SettingsResetButton {' in modules and 'SettingsResetButton {' in colors
print('Settings Save controls share one primitive and retain scoped visibility/actions: OK')
PY
