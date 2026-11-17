#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
HOST="$ROOT/components/settings/SettingsPageHost.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
GENERAL="$ROOT/components/settings/sections/SettingsGeneralSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# Profiles live under General, not under Settings Window.
grep -Fq '{ id: "general", saveScope: "general", subTabs: ["Интерфейс", "Профили", "Хранилища"] }' "$REGISTRY"
grep -Fq '{ id: "settingsWindow", saveScope: "settingsWindow", subTabs: ["Интерфейс", "Окно настроек", "Вкладки"] }' "$REGISTRY"
grep -Fq 'visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1' "$WINDOW"
! grep -Fq 'host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1' "$WINDOW"

# The General > Interface tab now includes both font and frame controls;
# per-module animation controls remain in each module.
grep -Fq 'text: "Основной шрифт интерфейса"' "$GENERAL"
grep -Fq 'text: "Толщина рамки (0 = выкл.)"' "$GENERAL"
grep -Fq 'text: "Радиус скругления рамки"' "$GENERAL"
! grep -Fq 'visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1' "$GENERAL"

# Profiles have their own all-settings reset; don't show a redundant tab reset.
grep -Fq 'readonly property bool currentPageResetAvailable:' "$WIDGET"
grep -Fq '!(root.currentPageId === "general" && (root.currentPageSubTabIndex === 1 || root.currentPageSubTabIndex === 2))' "$WIDGET"
grep -Fq 'visible: root.host && root.host.currentPageResetAvailable' "$HOST"
grep -Fq 'root.host.currentPageSaveScope !== ""' "$HOST"
grep -Fq 'root.host.profileController.canResetScope(root.host.currentPageSaveScope)' "$HOST"
grep -Fq 'visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 1 && host.profileController.canResetScope("all")' "$WINDOW"
grep -Fq 'settings.resetAllSettings()' "$WINDOW"

echo 'profiles under General and merged interface controls: OK'
