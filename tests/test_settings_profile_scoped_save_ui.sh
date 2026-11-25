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
heading = (root / 'components/settings/primitives/SettingsPageHeading.qml').read_text(encoding='utf-8')
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
assert 'root.host.profileController.saveScope(root.resolvedSaveScope)' in heading
assert 'Сохранить всё в активный профиль' in heading
assert 'text: "Всё"' not in widget
assert 'SettingsPageHeading {' in host and 'SettingsSaveButton {' in heading and 'iconText: "󰆔"' in heading, 'all pages should use the shared compact page-heading/save primitive'
assert 'Сохранить изменения этого раздела в активный профиль' in heading
assert 'saveScope: "modules"' in modules
assert 'host.profileController.saveScope(moduleRow.moduleName === "dashboard" ? "dashboardModule" : "module", moduleRow.moduleName)' in modules
assert 'host.profileController.saveScope("launcher")' in modules
assert 'saveScope: "themes"' in colors
assert 'text: "Всё"' not in colors
assert 'SettingsPageHeading {' in colors, 'Themes should use the shared page heading and save primitive'
assert 'host.profileController.saveScope("colors", modelData.colors)' in colors
assert 'function profileSavePathMatches(owner, scope, argument, path)' in profiles
print('Scoped profile save controls and scope-aware visibility wiring: OK')
PY
