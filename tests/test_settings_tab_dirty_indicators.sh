#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
widget = (root / 'components/settings/SettingsWidget.qml').read_text(encoding='utf-8')
tab_base = (root / 'components/settings/primitives/SettingsTabBase.qml').read_text(encoding='utf-8')
modules = (root / 'components/settings/sections/SettingsModulesSection.qml').read_text(encoding='utf-8')
colors = (root / 'components/settings/sections/SettingsColorsSection.qml').read_text(encoding='utf-8')

expected_scopes = {
    'modules': 'modules', 'themes': 'themes', 'general': 'general',
    'timers': 'timer', 'player': 'player', 'mopidy': 'mopidy',
    'weather': 'weather', 'cava': 'cava', 'cpuRam': 'cpu',
    'network': 'network', 'volume': 'volume', 'calendar': 'calendar',
    'launcher': 'launcher', 'settingsWindow': 'settingsWindow',
}
assert 'function settingsTabHasChanges(id)' in widget
assert 'return scope !== "" && settings.hasResetChanges(scope)' in widget
assert 'modified: root.settingsTabHasChanges(modelData.id)' in widget
for tab_id, scope in expected_scopes.items():
    assert f'{tab_id}: "{scope}"' in widget, f'missing dirty scope for sidebar tab {tab_id}'

assert 'property bool modified: false' in tab_base
assert 'visible: root.modified' in tab_base, 'dirty marker should only render when the section has changes'
assert 'color: root.selected ? root.selectedTextColor : root.modifiedColor' in tab_base, 'marker must remain visible on the selected tab'
assert 'anchors.rightMargin: root.horizontalPadding + (root.modified ? 10 : 0)' in tab_base, 'tab label must not overlap the dirty marker'

# Nerd Font Material Design Icon md-content_save_all (U+F0194), visually the paired diskettes.
double_save = chr(0xF0194)
assert f'iconText: "{double_save}"' in widget, 'Save All in the common settings header should use the paired-diskette icon'
assert f'iconText: "{double_save}"' in modules, 'Save All in Modules should use the paired-diskette icon'
assert f'iconText: "{double_save}"' in colors, 'Save All in Themes should use the paired-diskette icon'
assert 'iconText: "\\uf0c7"' in widget and 'iconText: "\\uf0c7"' in modules and 'iconText: "\\uf0c7"' in colors, 'section-scoped save buttons should retain the single-floppy icon'

print('Settings tab dirty markers use cached profile overrides; Save All uses paired-diskette icon: OK')
PY
