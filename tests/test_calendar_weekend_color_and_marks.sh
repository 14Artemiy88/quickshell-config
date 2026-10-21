#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
CALENDAR="$ROOT/components/CalendarWidget.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsCalendarSection.qml"
SCRIPT="$ROOT/scripts/calendar_marks"
CHECK="$ROOT/CHECK.sh"
for path in "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$CALENDAR" "$SETTINGS" "$SCRIPT" "$CHECK"; do
    test -f "$path"
done

grep -Fq 'property string calendarWeekendColor: "#d98282"' "$CONFIG"
grep -Fq 'calendarWeekendColor: "#d98282"' "$DEFAULTS"
grep -Fq 'calendarWeekendColor: config.calendarWeekendColor' "$PERSIST"
grep -Fq 'if (o.calendarWeekendColor !== undefined)' "$APPLY"
grep -Fq 'Config.calendarWeekendColor = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(weekendColor) ? weekendColor : "#d98282"' "$APPLY"
grep -Fq '"calendarWeekendColor"' "$RESETS"
grep -Fq 'function isWeekendDateKey(key)' "$CALENDAR"
grep -Fq 'return d.getDay() === 0 || d.getDay() === 6' "$CALENDAR"
grep -Fq 'if (root.isCalendarDateMarked(key)) return Config.calendarWeekendColor' "$CALENDAR"
grep -Fq 'if (root.isWeekendDateKey(key)) return Config.calendarWeekendColor' "$CALENDAR"
grep -Fq 'command: [Quickshell.shellDir + "/scripts/calendar_marks", "get"]' "$CALENDAR"
grep -Fq 'root.setCalendarDateMarked(root.noteDialogDate, !root.isCalendarDateMarked(root.noteDialogDate))' "$CALENDAR"
grep -Fq 'Цвет выходных и отмеченных дней' "$SETTINGS"
grep -Fq 'targetProperty: "calendarWeekendColor"' "$SETTINGS"
grep -Fq 'Отметить день' "$CALENDAR"
grep -Fq 'test_calendar_weekend_color_and_marks.sh' "$CHECK"

python3 - "$CALENDAR" "$SETTINGS" "$PERSIST" "$RESETS" <<'PY'
from pathlib import Path
import sys
calendar, settings, persist, resets = (Path(x).read_text(encoding="utf-8") for x in sys.argv[1:])
assert 'property var calendarMarkedDates: ({})' in calendar
assert 'function setCalendarMarksFromJson(raw)' in calendar
assert 'function setCalendarDateMarked(key, marked)' in calendar
assert 'visible: root.noteOverlayMode === "edit"' in calendar
assert 'calendarWeekendColor: config.calendarWeekendColor' in persist
assert resets.count('"calendarWeekendColor"') >= 2
assert 'Щёлкни правой кнопкой по дате' in settings
print('Calendar weekend color, marked dates and persistence wiring: OK')
PY

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
export QS_PROJECT_DIR="$ROOT"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"

[[ "$("$SCRIPT" get | jq -c 'type == "object" and length == 0')" == true ]] || { echo 'calendar marks initial get failed' >&2; exit 1; }
FILE="$XDG_DATA_HOME/quickshell-widgets/calendar-marks.json"
"$SCRIPT" set 2026-10-24 true
"$SCRIPT" set 2026-10-25 true
[[ "$(jq -r '.["2026-10-24"]' "$FILE")" == true ]]
[[ "$(jq -r '.["2026-10-25"]' "$FILE")" == true ]]
"$SCRIPT" set 2026-10-24 false
[[ "$(jq -r 'has("2026-10-24")' "$FILE")" == false ]]
[[ "$(jq -r '.["2026-10-25"]' "$FILE")" == true ]]
if "$SCRIPT" set 2026-02-30 true >/dev/null 2>&1; then
    echo 'calendar marks accepted an impossible date' >&2; exit 1
fi
if "$SCRIPT" set 2026-10-26 maybe >/dev/null 2>&1; then
    echo 'calendar marks accepted an invalid state' >&2; exit 1
fi
[[ "$(stat -c '%a' "$FILE")" == 600 ]]
[[ "$(stat -c '%a' "$XDG_DATA_HOME/quickshell-widgets/.calendar-marks.lock")" == 600 ]]

# Concurrent writes to separate dates must preserve every marker.
pids=()
for i in $(seq 1 24); do
    key="$(date -d "2028-01-01 +$((i - 1)) days" +%F)"
    "$SCRIPT" set "$key" true & pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid"; done
for i in $(seq 1 24); do
    key="$(date -d "2028-01-01 +$((i - 1)) days" +%F)"
    [[ "$(jq -r --arg k "$key" '.[$k] // false' "$FILE")" == true ]] || { echo "lost calendar mark $key" >&2; exit 1; }
done

# A malformed store is rejected without being overwritten.
printf '{invalid json\n' > "$FILE"
if "$SCRIPT" set 2028-02-01 true >/dev/null 2>&1; then
    echo 'calendar marks accepted malformed JSON' >&2; exit 1
fi
[[ "$(cat "$FILE")" == '{invalid json' ]]

bash -n "$SCRIPT"
echo 'Calendar weekend color and marked-day persistence test: OK'
