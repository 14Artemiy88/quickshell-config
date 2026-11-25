#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
heading = (root / 'components/settings/primitives/SettingsPageHeading.qml').read_text(encoding='utf-8')
host = (root / 'components/settings/SettingsPageHost.qml').read_text(encoding='utf-8')
modules = (root / 'components/settings/sections/SettingsModulesSection.qml').read_text(encoding='utf-8')
themes = (root / 'components/settings/sections/SettingsColorsSection.qml').read_text(encoding='utf-8')
assert 'font.pixelSize: Config.settingsUiSize(15)' in heading, 'shared page title must keep the large 15px size'
assert 'text: root.host ? root.host.currentPageTitle : ""' in heading, 'shared title must use canonical page title'
assert 'color: Config.accent' in heading, 'shared page title must use the common accent color'
assert 'SettingsSaveButton {' in heading and 'SettingsResetButton {' in heading, 'page actions belong to the shared heading'
assert 'SettingsPageHeading {' in host, 'generic pages must use the shared page heading'
assert 'SettingsPageHeading {' in modules and 'saveScope: "modules"' in modules, 'Modules must use the large shared page heading and scope'
assert 'onResetRequested: modulesSection.settings.resetModules()' in modules, 'Modules reset action must remain connected'
assert 'SettingsPageHeading {' in themes and 'saveScope: "themes"' in themes, 'Themes must use the large shared page heading and scope'
for path, source in [('Modules', modules), ('Themes', themes)]:
    assert 'heading: "Модули и их расположение"' not in source, f'{path}: small frame legend must be removed'
    assert 'heading: "Темы"' not in source, f'{path}: small frame legend must be removed'
    assert 'SettingsGroup {' in source and 'showFrame: true' in source, f'{path}: content frame remains separate from page title'
print('Modules and Themes use the same large page heading and profile actions as all other settings pages: OK')
PY
