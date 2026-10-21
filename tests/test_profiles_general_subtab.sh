#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
GENERAL="$ROOT/components/settings/sections/SettingsGeneralSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# Profiles live under General, not under Settings Window.
grep -Fq 'case 0: return ["Интерфейс", "Анимации", "Профили"]' "$WIDGET"
grep -Fq 'case 9: return ["Интерфейс", "Окно настроек"]' "$WIDGET"
grep -Fq 'visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 2' "$WINDOW"
! grep -Fq 'host.currentOtherTab === 9 && host.currentOtherSubTab === 2' "$WINDOW"

# The General > Interface tab now includes both font and frame controls;
# animation controls stay grouped in their own tab.
grep -Fq 'text: "Основной шрифт интерфейса"' "$GENERAL"
grep -Fq 'text: "Толщина рамки (0 = выкл.)"' "$GENERAL"
grep -Fq 'text: "Радиус скругления рамки"' "$GENERAL"
grep -Fq 'text: "Сглаживание"' "$GENERAL"
grep -Fq 'visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 1' "$GENERAL"
! grep -Fq 'visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 2' "$GENERAL"

# Profiles have their own all-settings reset; don't show a redundant tab reset.
grep -Fq 'visible: !(root.currentOtherTab === 0 && root.currentOtherSubTab === 2)' "$WIDGET"
grep -Fq 'settings.resetAllSettings()' "$WINDOW"

echo 'profiles under General and merged interface controls: OK'
