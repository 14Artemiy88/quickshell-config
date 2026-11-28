#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
HOST="$ROOT/components/settings/SettingsPageHost.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
GENERAL="$ROOT/components/settings/sections/SettingsGeneralSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# Profiles live under General, not under Settings Window.
grep -Fq '{ id: "general", saveScope: "", subTabs: ["Профили", "Хранилища"] }' "$REGISTRY"
grep -Fq '{ id: "settingsWindow", saveScope: "settingsWindow", subTabs: ["Интерфейс", "Окно настроек", "Вкладки"] }' "$REGISTRY"
grep -Fq 'visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0' "$WINDOW"
! grep -Fq 'host.currentPageId === "settingsWindow" && host.currentPageSubTabIndex === 1' "$WINDOW"

# The Appearance > Interface page includes both font and frame controls;
# per-module animation controls remain in each module.
grep -Fq 'label: "Основной шрифт интерфейса"' "$ROOT/components/settings/sections/SettingsInterfaceSection.qml"
grep -Fq 'label: "Толщина рамки карточек (0 = выкл.)"' "$ROOT/components/settings/sections/SettingsInterfaceSection.qml"
grep -Fq 'label: "Радиус внешних рамок"' "$ROOT/components/settings/sections/SettingsInterfaceSection.qml"
! grep -Fq 'visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0' "$GENERAL"

# Profiles have their own all-settings reset; don't show a redundant tab reset.
grep -Fq 'readonly property bool currentPageResetAvailable:' "$WIDGET"
grep -Fq 'root.currentPageId !== "general"' "$WIDGET"
grep -Fq 'showResetButton: root.host && root.host.currentPageResetAvailable' "$HOST"
grep -Fq 'SettingsPageRegistry.saveScopeForPageId(' "$WIDGET"
grep -Fq 'profileController.canResetScope(root.currentPageSaveScope)' "$WIDGET"
grep -Fq 'showResetButton: root.host && root.host.currentPageResetAvailable' "$HOST"
grep -Fq 'visible: host.currentPageId === "general" && host.currentPageSubTabIndex === 0 && host.profileController.canResetScope("all")' "$WINDOW"
grep -Fq 'settings.resetAllSettings()' "$WINDOW"

echo 'profiles under General; Interface moved to Appearance: OK'
