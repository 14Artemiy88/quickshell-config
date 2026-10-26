#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
GENERAL="$ROOT/components/settings/sections/SettingsGeneralSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# Profiles live under General, not under Settings Window.
grep -Fq 'case 0: return ["Интерфейс", "Профили", "Хранилища"]' "$WIDGET"
grep -Fq 'case 9: return ["Интерфейс", "Окно настроек", "Вкладки"]' "$WIDGET"
grep -Fq 'visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1' "$WINDOW"
! grep -Fq 'host.currentOtherTab === 9 && host.currentOtherSubTab === 1' "$WINDOW"

# The General > Interface tab now includes both font and frame controls;
# per-module animation controls remain in each module.
grep -Fq 'text: "Основной шрифт интерфейса"' "$GENERAL"
grep -Fq 'text: "Толщина рамки (0 = выкл.)"' "$GENERAL"
grep -Fq 'text: "Радиус скругления рамки"' "$GENERAL"
! grep -Fq 'visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1' "$GENERAL"

# Profiles have their own all-settings reset; don't show a redundant tab reset.
grep -Fq 'visible: enabled && actionAvailable && !(root.currentOtherTab === 0 && (root.currentOtherSubTab === 1 || root.currentOtherSubTab === 2))' "$WIDGET"
grep -Fq 'settings.resetAllSettings()' "$WINDOW"

echo 'profiles under General and merged interface controls: OK'
