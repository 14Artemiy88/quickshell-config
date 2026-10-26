#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY_ASSERT'
from pathlib import Path
import sys
r = Path(sys.argv[1])
read = lambda p: (r / p).read_text(encoding="utf-8")

# Quick-save control is adjacent to reset and operates on the currently active profile.
widget = read("components/settings/SettingsWidget.qml")
modules = read("components/settings/sections/SettingsModulesSection.qml")
assert 'readonly property bool quickSaveProfileAvailable:' in widget
assert 'settings.hasResetChanges("all")' in widget
assert 'iconText: "\\uf0c7"' in widget
assert 'tooltip: "Сохранить всё в активный профиль"' in widget
assert 'tooltip: "Сохранить изменения этого раздела в активный профиль"' in widget
assert 'onClicked: settings.saveProfileScope(settings.activeProfile, root.currentOtherSaveScope)' in widget
assert 'onClicked: settings.saveProfile(settings.activeProfile)' in widget
assert widget.index('tooltip: "Сохранить всё в активный профиль"') < widget.index('tooltip: "Сбросить текущую вкладку"')
assert 'onClicked: settings.saveProfile(settings.activeProfile)' in modules
assert 'onClicked: settings.saveProfileScope(settings.activeProfile, "modules")' in modules
assert 'onClicked: settings.saveProfileScope(settings.activeProfile, "module", moduleRow.moduleName)' in modules
assert modules.index('onClicked: settings.saveProfile(settings.activeProfile)') < modules.index('actionAvailable: settings.hasResetChanges("modules")')

# Calendar always-visible option is stored and participates in runtime visibility/input-mask state.
config = read("Config.qml")
defaults = read("js/settings/SettingsDefaults.js")
persist = read("js/settings/SettingsPersistence.js")
apply_visual = read("js/settings/SettingsApplySystemVisual.js")
calendar_ui = read("components/settings/sections/SettingsCalendarSection.qml")
shell = read("shell.qml")
assert 'property bool calendarAlwaysVisible: false' in config
assert 'calendarAlwaysVisible: false' in defaults
assert 'calendarAlwaysVisible: config.calendarAlwaysVisible' in persist
assert 'Config.calendarAlwaysVisible = !!o.calendarAlwaysVisible' in apply_visual
assert 'text: "Показывать календарь всегда"' in calendar_ui
assert 'Config.calendarAlwaysVisible = checked' in calendar_ui
assert 'shown: shell.calendarVisible || Config.calendarAlwaysVisible' in shell
assert 'inputMaskEnabled: shell.calendarVisible || Config.calendarAlwaysVisible || calendarVisibility.running || shell.layoutEditMode' in shell
assert 'backgroundBlurVisible: shell.calendarVisible || Config.calendarAlwaysVisible || calendarVisibility.running' in shell

# Timer options have a dedicated subtab and an independent, persistent animation style.
assert 'case 1: return ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации", "Опции таймера"]' in widget
timers = read("components/settings/sections/SettingsTimersSection.qml")
assert 'heading: "Анимация окна опций"' in timers
assert 'visible: host && host.currentOtherTab === 1 && host.currentOtherSubTab === 5' in timers
assert 'Config.animationTimerOptionsVisibilityStyle' in timers
assert 'targetProperty: "animationTimerOptionsDuration"' in timers
assert 'text: "Стиль анимации таймера"' in timers
assert 'currentOtherSubTab === 4' in timers and 'Config.animationTimerVisibilityStyle' in timers
options = read("components/TimerOptions.qml")
assert 'Config.animationTimerOptionsVisibilityStyle' in options
assert 'function onAnimationTimerOptionsVisibilityStyleChanged() { root.syncVisualState() }' in options
assert 'function onAnimationTimerVisibilityStyleChanged() { root.syncVisualState() }' not in options
assert 'property string animationTimerOptionsVisibilityStyle: "fade"' in config
assert 'animationTimerOptionsVisibilityStyle: "fade"' in defaults
assert 'animationTimerOptionsVisibilityStyle: config.animationTimerOptionsVisibilityStyle' in persist
assert 'settingsSchemaVersion: SETTINGS_SCHEMA_VERSION' in persist
assert 'var SETTINGS_SCHEMA_VERSION = 1' in persist
apply_behaviour = read("js/settings/SettingsApplyBehaviour.js")
assert '"animationTimerOptionsVisibilityStyle"' in apply_behaviour
assert 'o.animationTimerVisibilityStyle !== undefined' in apply_behaviour, 'old settings must migrate popup animation from the former shared style'
loader = read("Settings.qml")
assert 'schemaNeedsMigration = Number(diskObject.settingsSchemaVersion || 0) < SettingsPersistence.SETTINGS_SCHEMA_VERSION' in loader
assert 'root.profileMigrationPending || storageFormatNeedsMigration || schemaNeedsMigration' in loader
apply_state = read("js/settings/SettingsApplyState.js")
assert 'completedLegacyProfile.animationTimerOptionsVisibilityStyle = String(' in apply_state
assert 'Number(o.settingsSchemaVersion || 0) < 1' in apply_state, 'legacy full snapshots need the same one-time style migration'

# Weather layout alignment, concise labels and removal of the obsolete width field from UI only.
weather = read("components/settings/sections/SettingsWeatherSection.qml")
now_icon = weather.split('heading: "Иконка текущей погоды"', 1)[1].split('heading: "Стрелка ветра"', 1)[0]
wind = weather.split('heading: "Стрелка ветра"', 1)[1].split('heading: "Дополнительные параметры"', 1)[0]
comfort = weather.split('heading: "Температура комфорта"', 1)[1].split('heading: "Положение элементов"', 1)[0]
assert 'Item { width: 210; height: 24 }' in now_icon
assert 'Text { width: 210; height: 30; text: "Иконка"' in now_icon
wind_header = weather.split('id: windDirectionSettingsHeader', 1)[1].split('MouseArea', 1)[0]
assert 'width: 24' in wind_header
assert 'font.pixelSize: Config.settingsUiSize(17)' in wind_header
assert 'Item { width: 210; height: 30 }' in wind
assert 'text: "X"' not in wind and 'text: "Y"' not in wind and 'text: "Размер"' not in wind
assert 'heading: "Температура комфорта"' in weather
assert 'text: "Показывать"' in comfort and 'width: 24; height: 30; indicatorOnly: true' in comfort
assert 'label: "Цвет обводки"' in comfort and 'text: "Толщина обводки"' in comfort
assert 'text: "Положение Y"' in comfort and 'text: "Смещение X"' in comfort
assert 'value: Config.weatherComfortY + Config.weatherComfortOffsetY' in comfort
assert 'Config.weatherComfortOffsetY = n - baseY' in comfort
assert 'id: weatherComfortOffsetYField' not in comfort, 'comfort temperature should expose only one Y control'
assert 'weatherTempColumnWidth' not in weather, 'legacy field must no longer be presented in settings UI'
assert 'weatherTempColumnWidth' in config and 'weatherTempColumnWidth: config.weatherTempColumnWidth' in persist, 'keep the old stored field for compatibility'
print('Settings quick-save, timer options subtab, always-visible calendar, and weather refinements: OK')
PY_ASSERT
