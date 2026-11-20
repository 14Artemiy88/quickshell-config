#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
modules = (root / "components/settings/sections/SettingsModulesSection.qml").read_text()
launcher = (root / "components/settings/sections/SettingsLauncherSection.qml").read_text()
widget = (root / "components/settings/SettingsWidget.qml").read_text()
meta = (root / "js/settings/SettingsMetadata.js").read_text()
config = (root / "Config.qml").read_text()
defaults = (root / "js/settings/SettingsDefaults.js").read_text()
persist = (root / "js/settings/SettingsPersistence.js").read_text()
apply_visual = (root / "js/settings/SettingsApplySystemVisual.js").read_text()
shell = (root / "shell.qml").read_text()
assert 'text: "Лаунчер"' in modules
assert 'checked: Config.launcherEnabled' in modules
assert 'targetProperty: "launcherWidth"' in modules
assert 'targetProperty: "launcherHeight"' in modules
# Dimension controls follow the shared 1-unit step and 10x Shift-wheel modifier.
for field_id in ('launcherWidthField', 'launcherHeightField'):
    field_start = modules.index('id: ' + field_id)
    field_end = modules.index('targetProperty:', field_start)
    field = modules[field_start:field_end]
    assert 'step: 1' in field and 'wheelStep: 1' in field
    assert 'shiftWheelMultiplier' not in field  # handled by SettingsNumberField's shared default
# Width/height are only configurable from Modules, not duplicated on the Launcher tab.
assert 'targetProperty: "launcherWidth"' not in launcher
assert 'targetProperty: "launcherHeight"' not in launcher
assert 'heading: "Элемент списка"' in launcher
assert 'heading: "Окно лаунчера"' in launcher
assert 'label: "Фон окна лаунчера"' in launcher
assert 'onClicked: settings.resetLauncherSettings()' in modules
# Notifications now participates in the same module row as all other modules.
assert 'var moduleNames = ["time"' in meta and '"networks","notifications"]' in meta
assert 'model: settings.moduleNames' in modules
assert 'moduleRow.moduleName === "notifications"' in modules
assert 'modulesSection.writeNotificationsGeometry(index, n)' in modules
repeater_end = modules.index('model: settings.moduleNames')
launcher_row = modules.index('id: launcherModuleRow')
assert launcher_row > repeater_end
# Keep the dedicated Launcher tab and its original three subtabs intact.
registry = (root / 'js/settings/SettingsPageRegistry.js').read_text()
assert '{ id: "launcher", defaultLabel: "Общее", groupId: "launcher" }' in registry
for page_id in ('launcherSearch', 'launcherTabs', 'launcherProjects', 'launcherActions', 'launcherAnimation', 'launcherApplications'):
    assert f'groupId: "launcher"' in registry and f'id: "{page_id}"' in registry
assert 'function isLauncherSettingsPage(pageId)' in launcher
assert 'root.isLauncherSettingsPage(host.currentPageId)' in launcher
assert 'property int currentLauncherSubTab' not in launcher
# Enabling/disabling is persisted and applied, and prevents IPC launches when disabled.
assert 'property bool launcherEnabled: true' in config
assert 'launcherEnabled: true' in defaults
assert 'launcherEnabled: config.launcherEnabled' in persist
assert 'if (o.launcherEnabled !== undefined) Config.launcherEnabled = !!o.launcherEnabled' in apply_visual
assert 'if (!Config.launcherEnabled) return' in shell
assert 'function onLauncherEnabledChanged()' in shell
print("Launcher module row, dimension steps, persistence, IPC guard, and non-duplicated Launcher tab: OK")
PY
