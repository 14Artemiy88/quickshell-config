#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
read = lambda path: (root / path).read_text(encoding="utf-8")
registry = read("js/settings/SettingsPageRegistry.js")
widget = read("components/settings/SettingsWidget.qml")
nav = read("components/settings/SettingsNavigation.qml")
host = read("components/settings/SettingsPageHost.qml")
section = read("components/settings/sections/SettingsLauncherSection.qml")
launcher = read("components/launcher/Launcher.qml")
config = read("Config.qml")
defaults = read("js/settings/SettingsDefaults.js")
persist = read("js/settings/SettingsPersistence.js")
apply_visual = read("js/settings/SettingsApplySystemVisual.js")
resets = read("js/settings/SettingsResets.js")

# The sidebar must expose Launcher as a collapsible folder, parallel to Modules.
assert '{ id: "launcher", label: "Лаунчер", symbol: "⌕", description:' in registry
launcher_pages = ("launcher", "launcherSearch", "launcherTabs", "launcherProjects", "launcherActions", "launcherAnimation", "launcherApplications")
for page_id in launcher_pages:
    assert f'id: "{page_id}"' in registry and f'groupId: "launcher"' in registry
assert 'if (!SettingsPageRegistry.navigationGroupForId(key)) return' in widget
assert 'launcher: false' in widget and 'settingsNavigationCollapsedGroups' in config and 'launcher: false' in defaults
assert 'settingsNavigationGroupCollapsed(modelData.id)' in nav and 'modelData.items.length > 1' in nav
assert 'root.host.currentPageSubTabs.length > 0' in host and 'SettingsSubTab' in host

# Large framed groups now live behind meaning-based subtabs.
for definition in (
    '{ id: "launcher", saveScope: "launcher", subTabs: ["Общее", "Навигация", "Оформление", "Поиск"] }',
    '{ id: "launcherSearch", saveScope: "launcher", subTabs: ["Приложения", "Действия", "Схемы", "Обои"] }',
    '{ id: "launcherActions", saveScope: "launcher", subTabs: ["Переходы", "Инструменты", "Пользовательские"] }',
):
    assert definition in registry, f'expected logical subtabs missing: {definition}'
assert 'id: "launcherTabs", saveScope: "launcher", subTabs: []' in registry
assert 'id: "launcherProjects", saveScope: "launcher", subTabs: []' in registry
assert 'id: "launcherAnimation", saveScope: "launcher", subTabs: []' in registry
assert 'id: "launcherApplications", saveScope: "launcher", subTabs: []' in registry
for page_id in launcher_pages:
    assert f'"{page_id}"' in section, f'{page_id}: Launcher settings page is not routed into its section'

# Navigation hint controls disappear with the footer, with a height/opacity transition.
assert 'Config.launcherShowNavigationHints' in section
assert 'heading: "Панель подсказок"' in section
assert 'label: "Отображать панель подсказок"' in section
assert 'id: launcherNavigationHintsControlsClip' in section
assert 'height: Config.launcherShowNavigationHints ? launcherNavigationHintsControls.implicitHeight : 0' in section
assert 'opacity: Config.launcherShowNavigationHints ? 1 : 0' in section
assert 'Behavior on height' in section and 'Behavior on opacity' in section
assert 'minimum: 0' in section and 'maximum: 48' in section
assert 'label: "Смещение текста по Y"' in section
assert 'minimum: -48' in section and 'maximum: 48' in section
assert 'Layout.preferredHeight: Config.launcherNavigationHintsHeight' in launcher
assert 'Layout.minimumHeight: 0' in launcher
assert 'Layout.maximumHeight: Config.launcherNavigationHintsHeight' not in launcher
assert 'transform: Translate { y: Config.launcherNavigationHintsTextY }' in launcher

for key, default in (("launcherNavigationHintsHeight", 24), ("launcherNavigationHintsTextY", 0)):
    assert f'property int {key}: {default}' in config
    assert f'{key}: {default}' in defaults
    assert f'{key}: config.{key}' in persist
    assert f'"{key}"' in apply_visual and f'"{key}"' in resets
print("Launcher settings folder, nested subtabs, and animated hint settings visibility: OK")
PY
