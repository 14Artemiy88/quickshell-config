#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
read = lambda rel: (root / rel).read_text(encoding="utf-8")
config = read("Config.qml")
defaults = read("js/settings/SettingsDefaults.js")
apply = read("js/settings/SettingsApplySystemVisual.js")
persist = read("js/settings/SettingsPersistence.js")
resets = read("js/settings/SettingsResets.js")
navigation = read("components/settings/SettingsNavigationController.qml")
settings = read("components/settings/sections/SettingsLauncherSection.qml")
launcher = read("components/launcher/Launcher.qml")
readme = read("README.md")

key = "launcherShowNavigationHints"
legacy_key = "launcherHideNavigationHints"
assert f"property bool {key}: true" in config, "navigation hints are visible by default in Config"
assert f"{key}: true" in defaults, "new profiles display the navigation hints by default"
assert f"if (o.{key} !== undefined)" in apply and f"Config.{key} = !!o.{key}" in apply, "profile application restores the new show preference"
assert legacy_key in apply and f"Config.{key} = true" in apply, "legacy hide-only profiles migrate to the new visible default"
assert f"{key}: config.{key}" in persist, "settings snapshots persist the show preference"
assert f'"{key}"' in resets and f"if (profile.{key} === undefined) config.{key} = true" in resets, "Launcher reset and legacy-profile fallback preserve the visible default"
assert f'"launcherVimKeybinds", "{key}",' in navigation, "Settings navigation tracks dirty state for this option"

assert 'label: "Отображать панель подсказок"' in settings, "Launcher settings expose the positive show option"
assert f"checked: Config.{key}" in settings, "checkbox reflects the default-on show state"
assert f"Config.{key} = checked" in settings and "root.settings.save()" in settings, "checkbox changes are persisted"
assert "onLauncherShowNavigationHintsChanged" in settings, "checkbox tracks profile/config changes"
keyboard_group = settings.split('heading: "Клавиатурная навигация"', 1)[1].split("SettingsGroup {", 1)[0]
panel_group = settings.split('heading: "Панель подсказок"', 1)[1].split("SettingsGroup {", 1)[0]
assert key not in keyboard_group, "the show checkbox belongs inside the panel settings frame, not keyboard navigation"
assert key in panel_group and 'label: "Отображать панель подсказок"' in panel_group, "panel visibility checkbox shares one frame with panel controls"

footer = launcher.split('text: "↑ ↓  navigate"', 1)[0].rsplit("RowLayout {", 1)[-1]
assert f"visible: Config.{key}" in footer, "the complete footer hint panel follows the show setting"
assert 'visible: Config.launcherVimKeybinds' in launcher, "the Vim-specific hint keeps its independent visibility rule"
assert "Отображать панель подсказок" in readme and "отображается по умолчанию" in readme.lower(), "README documents the default-visible panel"
assert legacy_key not in config + defaults + persist + navigation + settings + launcher, "legacy hide property is no longer used by current UI or persistence"
print("Launcher navigation hint panel positive visibility, default, persistence, legacy fallback and dirty-state integration: OK")
PY
