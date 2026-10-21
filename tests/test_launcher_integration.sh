#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
NETWORK="$ROOT/components/launcher/modules/common/Network.qml"

# Launcher is loaded lazily and must not require the optional qml-niri plugin.
# Windows are queried on demand through the Niri CLI so other tabs still load
# on sessions without Niri installed.
grep -q 'source: "components/launcher/Launcher.qml"' "$ROOT/shell.qml"
grep -q 'active: false' "$ROOT/shell.qml"
grep -q 'target: "launcher"' "$ROOT/shell.qml"
grep -q 'function toggle(): void' "$ROOT/shell.qml"
grep -q 'function openPackages(): void' "$ROOT/shell.qml"
grep -q 'function openPass(): void' "$ROOT/shell.qml"
grep -q 'function openProjects(): void' "$ROOT/shell.qml"

# Standalone launcher behavior is adapted for an embedded shell.
grep -q 'visible: false' "$LAUNCHER"
grep -q 'function openMode(modeName)' "$LAUNCHER"
grep -q 'import "./modules/common"' "$LAUNCHER"
grep -q 'import "./models"' "$LAUNCHER"
grep -q '^AppModel 1.0 AppModel.qml$' "$ROOT/components/launcher/models/qmldir"
[ -f "$ROOT/components/launcher/models/AppModel.qml" ]
[ ! -f "$ROOT/components/launcher/AppModel.qml" ]
! grep -q 'import Niri' "$LAUNCHER"
grep -q 'niri msg -j windows' "$LAUNCHER"
grep -q 'niri msg action focus-window' "$LAUNCHER"
! grep -q 'import qs.modules.common' "$LAUNCHER"
! grep -q 'Qt.quit()' "$LAUNCHER"
grep -q 'Alt+1..9' "$LAUNCHER"
grep -q 'Qt.Key_0' "$LAUNCHER"
grep -q 'Symbols Nerd Font Mono' "$ROOT/components/launcher/theme/Theme.qml"
grep -q '^Theme 1.0 Theme.qml$' "$ROOT/components/launcher/theme/qmldir"

# Launcher uses the shared theme palette and persists its user-facing geometry.
grep -q 'Config.settingsBackground' "$ROOT/components/launcher/theme/Theme.qml"
grep -q 'Config.accent' "$ROOT/components/launcher/theme/Theme.qml"
grep -q 'Config.launcherWidth' "$LAUNCHER"
grep -q 'Config.launcherItemHeight' "$LAUNCHER"
grep -Fq 'case 11: return ["Общее", "Вкладки", "Проекты"]' "$ROOT/components/settings/SettingsWidget.qml"
grep -q '"Лаунчер", "Окно настроек"' "$ROOT/components/settings/SettingsWidget.qml"
grep -q 'function resetLauncherSettings' "$ROOT/Settings.qml"
grep -q 'function resetLauncherSettings(owner, config)' "$ROOT/js/settings/SettingsResets.js"
grep -q 'launcherWidth: config.launcherWidth' "$ROOT/js/settings/SettingsPersistence.js"
grep -q 'launcherBackdropOpacity: config.launcherBackdropOpacity' "$ROOT/js/settings/SettingsPersistence.js"
grep -q 'launcherWidth: 720' "$ROOT/js/settings/SettingsDefaults.js"
grep -q '["launcherWidth", 500, 1400]' "$ROOT/js/settings/SettingsApplySystemVisual.js"
[ -f "$ROOT/components/settings/sections/SettingsLauncherSection.qml" ]

# Network scanning must be on-demand, must not filter names through a
# personal substring, and must preserve escaped colons in SSIDs.
grep -q 'function parseFields(line)' "$NETWORK"
grep -q '"IN-USE,SSID,SECURITY,BARS"' "$NETWORK"
! grep -q 'rg 14' "$NETWORK"
! grep -q 'interval: 1000' "$NETWORK"
grep -q 'singleton Network 1.0 Network.qml' "$ROOT/components/launcher/modules/common/qmldir"

# Keep the project with a single top-level README; don't carry the standalone
# launcher's README into this repo.
[ ! -f "$ROOT/components/launcher/README.md" ]
echo 'launcher integration: OK'
