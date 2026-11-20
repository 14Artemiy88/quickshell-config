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

assert "property bool launcherVimKeybinds: false" in config, "Config keeps Vim navigation opt-in"
assert "launcherVimKeybinds: false" in defaults, "new profiles default Vim navigation to off"
assert "if (o.launcherVimKeybinds !== undefined)" in apply and "Config.launcherVimKeybinds = !!o.launcherVimKeybinds" in apply, "profile application restores the preference"
assert "launcherVimKeybinds: config.launcherVimKeybinds" in persist, "settings persistence stores the preference"
assert '"launcherVimKeybinds"' in resets and "if (profile.launcherVimKeybinds === undefined) config.launcherVimKeybinds = false" in resets, "Launcher reset and legacy-profile fallback include the preference"
assert '{ keys: ["launcherVimKeybinds", "launcherShowNavigationHints", "launcherNavigationHintsHeight", "launcherNavigationHintsFontSize", "launcherNavigationHintsTextY"] }' in navigation, "dirty-state navigation tracks the setting in General > Navigation"
assert 'heading: "Клавиатурная навигация"' in settings and 'id: launcherVimKeybindsCheckBox' in settings, "Launcher settings expose the new switch"
assert 'Config.launcherVimKeybinds = checked' in settings and 'root.settings.save()' in settings, "changing the switch is persisted"
assert "Ctrl+J или Ctrl+N" in settings and "Ctrl+K или Ctrl+P" in settings, "settings explain both directions"

# Both focus paths must support the same mappings: the search input for all normal
# tabs and the launcher surface when the fixed Power list owns keyboard focus.
assert launcher.count("Config.launcherVimKeybinds && (event.modifiers & Qt.ControlModifier)") >= 2, "search and Power focus paths both honor the preference"
for key in ("Qt.Key_J", "Qt.Key_N", "Qt.Key_K", "Qt.Key_P"):
    assert key in launcher, f"missing Vim navigation key {key}"
assert "root.moveSelectionDown()" in launcher and "root.moveSelectionUp()" in launcher, "Vim mappings reuse the shared selection logic"
assert 'event.key === Qt.Key_Tab' in launcher and 'root.nextMode()' in launcher and 'root.previousMode()' in launcher, "existing Tab-based tab switching remains intact"
assert 'visible: Config.launcherVimKeybinds' in launcher and 'Ctrl+J/N ↓  Ctrl+K/P ↑' in launcher, "footer hint follows the setting"
assert "disabled by default" in readme, "README documents that Vim navigation is opt-in"
print("Launcher optional Vim navigation settings, profile persistence, focus routing and Tab compatibility: OK")
PY
