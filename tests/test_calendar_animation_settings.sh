#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }
need "$ROOT/Config.qml" 'property int animationCalendarMorphDuration: 180'
need "$ROOT/Config.qml" 'property string animationCalendarMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationCalendarMorphDuration: 180'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationCalendarMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationCalendarMorphDuration: config.animationCalendarMorphDuration'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationCalendarMorphProfile: config.animationCalendarMorphProfile'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'applyMorphProfile(Config, o, "animationCalendarMorphProfile")'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'Config.animationCalendarMorphDuration = Math.max(0, Math.min(5000, Math.round(calendarMorphDuration)))'
need "$ROOT/components/settings/sections/SettingsCalendarSection.qml" 'SettingsAnimationGroup {'
need "$ROOT/components/settings/sections/SettingsCalendarSection.qml" 'heading: "Внутренние переходы календаря"'
need "$ROOT/components/settings/sections/SettingsCalendarSection.qml" 'heading: "Появление модуля"'
need "$ROOT/components/settings/SettingsNavigationController.qml" '{ prefixes: ["animationCalendar"] }'
need "$ROOT/components/CalendarWidget.qml" 'Config.animationDurationForProfile(true, Config.animationCalendarMorphProfile, Config.animationCalendarMorphDuration, "appearance")'
need "$ROOT/components/CalendarWidget.qml" 'animationProfile: Config.animationCalendarMorphProfile'
need "$ROOT/js/settings/SettingsProfiles.js" 'calendar: ["calendar", "animationCalendar"]'
need "$ROOT/js/settings/SettingsResets.js" '"animationCalendarMorphDuration", "animationCalendarMorphProfile"'
need "$ROOT/CHECK.sh" 'test_calendar_animation_settings.sh'
# The legacy module-level entrance/exit controls remain in place and independent.
need "$ROOT/components/settings/sections/SettingsCalendarSection.qml" 'animationCalendarVisibilityStyle'
need "$ROOT/components/CalendarWidget.qml" 'root.noteOverlayMode !== "" ? "enter" : "exit"'
echo 'Calendar internal animation settings schema, profile/reset persistence and note-overlay wiring passed'
