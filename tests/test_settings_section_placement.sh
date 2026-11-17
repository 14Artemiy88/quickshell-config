#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
TIMERS="$ROOT/components/settings/sections/SettingsTimersSection.qml"
NETWORK="$ROOT/components/settings/sections/SettingsNetworkSection.qml"
PLAYER="$ROOT/components/settings/sections/SettingsPlayerSection.qml"
GENERAL="$ROOT/components/settings/sections/SettingsGeneralSection.qml"
VOLUME="$ROOT/components/settings/sections/SettingsVolumeSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
CAVA="$ROOT/components/settings/sections/SettingsCavaSection.qml"
CPU="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"

# Default sidebar order keeps Mopidy directly below Player; stable tab IDs preserve internal routing.
grep -Fq '"player", "mopidy", "weather"' "$ROOT/Config.qml"
grep -Fq 'model: root.settingsNavigationItems' "$WIDGET"
grep -Fq 'function isSettingsTabSelected(id)' "$WIDGET"
grep -Fq 'root.currentPageId === String(id)' "$WIDGET"
grep -Fq 'onClicked: root.selectSettingsTab(modelData.id)' "$WIDGET"
grep -Fq '{ id: "mopidy", defaultLabel: "Mopidy" }' "$REGISTRY"
grep -Fq '{ id: "launcher", defaultLabel: "Лаунчер" }' "$REGISTRY"

# Calendar controls are split into separate, visibility-scoped subtabs.
grep -Fq '{ id: "calendar", saveScope: "calendar", subTabs: ["Разметка", "Цвета", "Метки заметок", "Анимации"] }' "$REGISTRY"
grep -Fq 'visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 0' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"
grep -Fq 'visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 1' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"
grep -Fq 'visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 2' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"
grep -Fq 'visible: host.currentPageId === "calendar" && host.currentPageSubTabIndex === 3' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"

# Subtabs must match the controls that are actually grouped under them.
grep -Fq '{ id: "timers", saveScope: "timer", subTabs: ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации", "Опции таймера"] }' "$REGISTRY"
grep -Fq '{ id: "volume", saveScope: "volume", subTabs: ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность", "Анимация"] }' "$REGISTRY"

# Timer layout rows use host state; timer options popup animation controls live in dedicated subtab 5.
! grep -Eq 'visible: root\.currentOtherTab|visible: root\.currentPageSubTabIndex' "$TIMERS"
grep -Fq 'id: timerRowSpacingField' "$TIMERS"
grep -Fq 'visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 3' "$TIMERS"
grep -Fq 'targetProperty: "timerButtonFadeDuration"' "$TIMERS"
grep -Fq 'visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 5' "$TIMERS"
grep -Fq 'targetProperty: "animationTimerOptionsDuration"' "$TIMERS"
! grep -Fq 'visible: root.host.currentPageId === "timers" && root.host.currentPageSubTabIndex === 0' "$TIMERS"
! grep -Fq 'text: "Окно окончания таймера"' "$TIMERS"
! grep -Fq 'text: "Иконки таймера"' "$TIMERS"
! grep -Fq 'text: "Таймеры"' "$TIMERS"

# Global system-monitor interval belongs to Updates, network appearance to Network.
! grep -Fq 'text: "Обновления"' "$NETWORK"
grep -Fq 'targetProperty: "systemMonitorInterval"' "$NETWORK"
grep -Fq 'visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 0' "$NETWORK"
! grep -Fq 'text: "Сеть"' "$NETWORK"
grep -Fq 'heading: "Расположение"' "$NETWORK"
grep -Fq 'visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 1' "$NETWORK"

# Player headings map to their actual subtab instead of adjacent ones.
# Selected Player subtab title supplies the heading; duplicate in-section labels are omitted.
! grep -Fq 'text: "Оставшееся время"' "$PLAYER"
! grep -Fq 'text: "Метаданные"' "$PLAYER"
! grep -Fq 'text: "Полоска прогресса"' "$PLAYER"
! grep -Fq 'text: "Обложка и фон"' "$PLAYER"
! grep -Fq 'text: "Плеер"' "$PLAYER"

# Redundant general-section headings should not duplicate the selected tab title.
! grep -Fq 'text: "Общие"' "$GENERAL"
! grep -Fq 'text: "Рамки"' "$GENERAL"
! grep -Fq 'text: "Общие анимации"' "$GENERAL"
! grep -Fq 'text: "CAVA"' "$CAVA"
! grep -Fq 'text: "CPU и RAM"' "$CPU"
! grep -Fq 'text: "График CPU"' "$CPU"

# Volume controls are grouped by their displayed tab labels.
grep -Fq 'text: "Иконки громкости"' "$VOLUME"
grep -Fq 'id: volumeVerticalPaddingField' "$VOLUME"
grep -Fq 'id: volumeStreamTrackOffsetField' "$VOLUME"
grep -Fq 'text: "Адаптивные блоки"' "$VOLUME"
grep -Fq 'visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 5' "$VOLUME"
grep -Fq 'heading: "Анимация списка потоков"' "$VOLUME"
grep -Fq 'targetProperty: "volumeStreamsAnimationDuration"' "$VOLUME"

# Settings Window controls must use the actual section id and avoid repeated tab headings.
! grep -Fq 'root.settings' "$WINDOW"
grep -Fq 'settingsWindowColumn.settings' "$WINDOW"
! grep -Fq 'text: "Окно настроек"' "$WINDOW"
! grep -Fq 'text: "Профили"' "$WINDOW"

echo 'settings section placement audit: OK'
