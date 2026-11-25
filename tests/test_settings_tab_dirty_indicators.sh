#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
widget = (root / 'components/settings/SettingsWidget.qml').read_text(encoding='utf-8')
navigation = (root / 'components/settings/SettingsNavigationController.qml').read_text(encoding='utf-8')
host = (root / 'components/settings/SettingsPageHost.qml').read_text(encoding='utf-8')
page_heading = (root / 'components/settings/primitives/SettingsPageHeading.qml').read_text(encoding='utf-8')
save_button = (root / 'components/settings/primitives/SettingsSaveButton.qml').read_text(encoding='utf-8')
navigation_view = (root / 'components/settings/SettingsNavigation.qml').read_text(encoding='utf-8')
tab_base = (root / 'components/settings/primitives/SettingsTabBase.qml').read_text(encoding='utf-8')
modules = (root / 'components/settings/sections/SettingsModulesSection.qml').read_text(encoding='utf-8')
colors = (root / 'components/settings/sections/SettingsColorsSection.qml').read_text(encoding='utf-8')

expected_scopes = {
    'modules': 'modules', 'themes': 'themes', 'general': 'general',
    'timers': 'timer', 'player': 'player', 'mopidy': 'mopidy',
    'weather': 'weather', 'cava': 'cava', 'cpuRam': 'cpu',
    'network': 'network', 'volume': 'volume', 'calendar': 'calendar',
'notifications': 'notifications', 'settingsWindow': 'settingsWindow',
}
assert 'function settingsTabHasChanges(id)' in navigation
assert 'return scope !== "" && settings.hasResetChanges(scope)' in navigation
assert 'function launcherPageHasChanges(pageId)' in navigation
assert 'return root.launcherPageHasChanges(pageId)' in navigation
assert 'launcher: "launcher"' not in navigation, 'Launcher pages must not use a shared dirty marker scope'
assert 'function settingsTabHasChanges(id) { return settingsNavigationController.settingsTabHasChanges(id) }' in widget
assert 'modified: root.host.settingsTabHasChanges(parent.modelData.id)' in navigation_view
for tab_id, scope in expected_scopes.items():
    assert f'{tab_id}: "{scope}"' in navigation, f'missing dirty scope for sidebar tab {tab_id}'

assert 'property bool modified: false' in tab_base
assert 'visible: root.modified' in tab_base, 'dirty marker should only render when the section has changes'
assert 'color: root.selected ? root.selectedTextColor : root.modifiedColor' in tab_base, 'marker must remain visible on the selected tab'
assert 'anchors.rightMargin: root.horizontalPadding + (root.modified ? 10 : 0)' in tab_base, 'tab label must not overlap the dirty marker'

# Nerd Font Material Design Icon md-content_save_all (U+F0194), visually the paired diskettes.
double_save = chr(0xF0194)
assert f'iconText: "{double_save}"' in page_heading, 'Save All in the common settings header should use the paired-diskette icon'
assert 'SettingsPageHeading {' in modules, 'Modules should use the shared page heading'
assert 'SettingsPageHeading {' in colors, 'Themes should use the shared page heading'
assert 'property string iconText: "\\uf0c7"' in save_button, 'shared Save primitive should provide the single-floppy default'
assert 'iconText: root.iconText' in save_button, 'shared Save primitive should forward its default icon'
for source, name in [(host, 'SettingsPageHost'), (modules, 'Modules'), (colors, 'Themes')]:
    assert 'SettingsPageHeading {' in source, f'{name} should use the shared page heading'
assert 'SettingsSaveButton {' in page_heading, 'page heading should own shared Save primitive'

print('Settings tab dirty markers use cached profile overrides; Save All uses paired-diskette icon: OK')
PY
