#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
widget = (root / 'components/settings/SettingsWidget.qml').read_text(encoding='utf-8')
controller = (root / 'components/settings/SettingsProfileController.qml').read_text(encoding='utf-8')
modules = (root / 'components/settings/sections/SettingsModulesSection.qml').read_text(encoding='utf-8')
host = (root / 'components/settings/SettingsPageHost.qml').read_text(encoding='utf-8')
colors = (root / 'components/settings/sections/SettingsColorsSection.qml').read_text(encoding='utf-8')
settings = (root / 'Settings.qml').read_text(encoding='utf-8')
profiles = (root / 'js/settings/SettingsProfiles.js').read_text(encoding='utf-8')

assert 'function saveProfileScope(name, scope, argument)' in settings
assert 'return SettingsProfiles.saveProfileScope(root, name, scope, argument)' in settings
assert 'function saveProfileScope(owner, name, scope, argument)' in profiles
assert 'if (!selectedPaths.length) return false' in profiles, 'scoped save must never fall back to saving everything'
assert 'readonly property bool quickSavePageAvailable:' in widget
assert 'property alias profileController: settingsProfileController' in widget
assert 'function canSaveScope(scope, argument)' in controller
assert 'function saveScope(scope, argument)' in controller
assert 'function saveAll()' in controller
assert 'function loadProfile(name)' in controller
assert 'function deleteProfile(name)' in controller
assert 'root.host.profileController.saveScope(root.host.currentPageSaveScope)' in host
assert 'Сохранить всё в активный профиль' in host
assert 'text: "Всё"' not in widget
assert 'width: 30' in host and 'iconText: "󰆔"' in host, 'Save All should be compact and icon-only'
assert 'Сохранить изменения этого раздела в активный профиль' in host
assert 'host.profileController.saveScope("modules")' in modules
assert 'host.profileController.saveScope("module", moduleRow.moduleName)' in modules
assert 'host.profileController.saveScope("launcher")' in modules
assert 'host.profileController.saveScope("themes")' in colors
assert 'text: "Всё"' not in colors
assert 'width: 30' in colors and 'iconText: "󰆔"' in colors, 'Themes Save All should be compact and icon-only'
assert 'host.profileController.saveScope("colors", modelData.colors)' in colors
assert 'function profileSavePathMatches(owner, scope, argument, path)' in profiles
print('Scoped profile save controls and scope-aware visibility wiring: OK')
PY
