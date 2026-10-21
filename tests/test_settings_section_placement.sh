#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
TIMERS="$ROOT/components/settings/sections/SettingsTimersSection.qml"
NETWORK="$ROOT/components/settings/sections/SettingsNetworkSection.qml"
PLAYER="$ROOT/components/settings/sections/SettingsPlayerSection.qml"
GENERAL="$ROOT/components/settings/sections/SettingsGeneralSection.qml"
VOLUME="$ROOT/components/settings/sections/SettingsVolumeSection.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
CAVA="$ROOT/components/settings/sections/SettingsCavaSection.qml"
CPU="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"

# Sidebar display order places Mopidy directly below Player and Launcher directly before Settings Window while preserving internal tab IDs.
grep -Fq 'readonly property var otherTabDisplayOrder: [0, 1, 2, 10, 3, 4, 5, 6, 7, 8, 11, 9]' "$WIDGET"
grep -Fq 'model: ["Модули", "Темы", "Общие", "Таймеры", "Плеер", "Mopidy", "Погода"' "$WIDGET"
grep -Fq '"Календарь", "Лаунчер", "Окно настроек"' "$WIDGET"
grep -Fq 'root.currentOtherTab === root.otherTabIdForDisplayIndex(index - 2)' "$WIDGET"
grep -Fq 'root.currentOtherTab = root.otherTabIdForDisplayIndex(index - 2)' "$WIDGET"

# Calendar controls are split into separate, visibility-scoped subtabs.
grep -Fq 'case 8: return ["Разметка", "Цвета", "Метки заметок", "Анимации"]' "$WIDGET"
grep -Fq 'visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"
grep -Fq 'visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 1' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"
grep -Fq 'visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 2' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"
grep -Fq 'visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 3' "$ROOT/components/settings/sections/SettingsCalendarSection.qml"

# Subtabs must match the controls that are actually grouped under them.
grep -Fq 'case 1: return ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации"]' "$WIDGET"
grep -Fq 'case 7: return ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность"]' "$WIDGET"

# Timer layout rows must reference host state; animation controls live together in subtab 4.
! grep -Eq 'visible: root\.currentOtherTab|visible: root\.currentOtherSubTab' "$TIMERS"
grep -Fq 'id: timerRowSpacingField' "$TIMERS"
grep -Fq 'visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 3' "$TIMERS"
grep -Fq 'targetProperty: "timerButtonFadeDuration"' "$TIMERS"
grep -Fq 'visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 4' "$TIMERS"
grep -Fq 'targetProperty: "animationTimerOptionsDuration"' "$TIMERS"
! grep -Fq 'visible: root.host.currentOtherTab === 1 && root.host.currentOtherSubTab === 0' "$TIMERS"
! grep -Fq 'text: "Окно окончания таймера"' "$TIMERS"
! grep -Fq 'text: "Иконки таймера"' "$TIMERS"
! grep -Fq 'text: "Таймеры"' "$TIMERS"

# Global system-monitor interval belongs to Updates, network appearance to Network.
! grep -Fq 'text: "Обновления"' "$NETWORK"
grep -Fq 'targetProperty: "systemMonitorInterval"' "$NETWORK"
grep -Fq 'visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 0' "$NETWORK"
! grep -Fq 'text: "Сеть"' "$NETWORK"
grep -Fq 'text: "Внешний вид и расположение сетевого трафика"' "$NETWORK"
grep -Fq 'visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1' "$NETWORK"

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
! grep -Eq 'currentOtherSubTab === 5' "$VOLUME"

# Settings Window controls must use the actual section id and avoid repeated tab headings.
! grep -Fq 'root.settings' "$WINDOW"
grep -Fq 'settingsWindowColumn.settings' "$WINDOW"
! grep -Fq 'text: "Окно настроек"' "$WINDOW"
! grep -Fq 'text: "Профили"' "$WINDOW"

echo 'settings section placement audit: OK'
