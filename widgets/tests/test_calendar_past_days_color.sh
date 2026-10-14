#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
CALENDAR="$ROOT/components/CalendarWidget.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsCalendarSection.qml"
CHECK="$ROOT/CHECK.sh"

for path in "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$CALENDAR" "$SETTINGS"; do
    test -f "$path"
done

grep -Fq 'property bool calendarPastDaysColorEnabled: false' "$CONFIG"
grep -Fq 'property string calendarPastDaysColor: "#888888"' "$CONFIG"
grep -Fq 'calendarPastDaysColorEnabled: false' "$DEFAULTS"
grep -Fq 'calendarPastDaysColor: "#888888"' "$DEFAULTS"
grep -Fq 'calendarPastDaysColorEnabled: config.calendarPastDaysColorEnabled' "$PERSIST"
grep -Fq 'calendarPastDaysColor: config.calendarPastDaysColor' "$PERSIST"
grep -Fq 'Config.calendarPastDaysColorEnabled = !!o.calendarPastDaysColorEnabled' "$APPLY"
grep -Fq 'Config.calendarPastDaysColor = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(pastDaysColor) ? pastDaysColor : "#888888"' "$APPLY"
grep -Fq '"calendarPastDaysColorEnabled", "calendarPastDaysColor"' "$RESETS"
grep -Fq 'root.isPastDateKey(key)' "$CALENDAR"
grep -Fq 'value < root.currentDateKey()' "$CALENDAR"
grep -Fq 'root.calendarDayColor(parent.dateKey, parent.day)' "$CALENDAR"
grep -Fq 'root.noteMarkerColor(parent.dateKey, Config.calendarNoteFrameColor)' "$CALENDAR"
grep -Fq 'root.noteMarkerColor(dateKey, Config.accent)' "$CALENDAR"
grep -Fq 'Выделять прошедшие дни и их заметки другим цветом' "$SETTINGS"
grep -Fq 'targetProperty: "calendarPastDaysColor"' "$SETTINGS"
grep -Fq 'root.openNoteEditor(parent.dateKey)' "$CALENDAR"
grep -Fq 'root.openNoteViewer(parent.dateKey)' "$CALENDAR"
grep -Fq 'test_calendar_past_days_color.sh' "$CHECK"

python3 - "$CALENDAR" "$SETTINGS" <<'PY'
from pathlib import Path
import sys
calendar = Path(sys.argv[1]).read_text(encoding="utf-8")
settings = Path(sys.argv[2]).read_text(encoding="utf-8")
assert 'function currentDateKey()' in calendar
assert 'String(today.getMonth() + 1).padStart(2, "0")' in calendar
assert 'String(today.getDate()).padStart(2, "0")' in calendar
assert 'if (String(key || "") === root.currentDateKey()) return Config.accent' in calendar
assert 'color: noteMarker.markerColor' in calendar
assert 'property color markerColor: root.noteMarkerColor(dateKey, Config.accent)' in calendar
assert 'onCalendarPastDaysColorEnabledChanged()' in settings
assert 'settings.save()' in settings
print('Calendar past-day and note-marker color configuration: OK')
PY
