#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
CALENDAR="$ROOT/components/CalendarWidget.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsCalendarSection.qml"
CHECK="$ROOT/CHECK.sh"

for path in "$CONFIG" "$DEFAULTS" "$PERSIST" "$APPLY" "$RESETS" "$CALENDAR" "$SETTINGS" "$CHECK"; do
    test -f "$path"
done

grep -Fq 'property string calendarAdjacentDaysColor: "#777777"' "$CONFIG"
grep -Fq 'calendarAdjacentDaysColor: "#777777"' "$DEFAULTS"
grep -Fq 'calendarAdjacentDaysColor: config.calendarAdjacentDaysColor' "$PERSIST"
grep -Fq 'if (o.calendarAdjacentDaysColor !== undefined)' "$APPLY"
grep -Fq 'Config.calendarAdjacentDaysColor = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(adjacentDaysColor) ? adjacentDaysColor : "#777777"' "$APPLY"
grep -Fq '"calendarAdjacentDaysColor"' "$RESETS"
grep -Fq 'function gridCellCount()' "$CALENDAR"
grep -Fq 'Math.ceil((root.firstDay() + root.daysInMonth()) / 7) * 7' "$CALENDAR"
grep -Fq 'function calendarGridDayNumber(day)' "$CALENDAR"
grep -Fq 'text: root.calendarGridDayNumber(parent.day)' "$CALENDAR"
grep -Fq 'if (parent.day < 1)' "$CALENDAR"
grep -Fq 'if (parent.day > root.daysInMonth())' "$CALENDAR"
grep -Fq 'return Config.calendarAdjacentDaysColor' "$CALENDAR"
grep -Fq 'label: "Цвет дней соседних месяцев"' "$SETTINGS"
grep -Fq 'targetProperty: "calendarAdjacentDaysColor"' "$SETTINGS"
grep -Fq 'test_calendar_adjacent_month_days.sh' "$CHECK"

node - <<'JS'
const assert = require('assert');
function firstDay(year, month) {
  const day = new Date(year, month, 1).getDay();
  return day === 0 ? 6 : day - 1;
}
function daysInMonth(year, month) { return new Date(year, month + 1, 0).getDate(); }
function count(year, month) { return Math.ceil((firstDay(year, month) + daysInMonth(year, month)) / 7) * 7; }
function row(year, month, index) { return new Date(year, month, index - firstDay(year, month) + 1).getDate(); }
function sequence(year, month) {
  return Array.from({length: count(year, month)}, (_, i) => ({
    day: i - firstDay(year, month) + 1,
    shown: row(year, month, i)
  }));
}
// May 2021 starts Saturday: leading cells show April 26–30 and final row ends June 6.
let may = sequence(2021, 4);
assert.strictEqual(may.length, 42);
assert.deepStrictEqual(may.slice(0, 5).map(x => x.shown), [26, 27, 28, 29, 30]);
assert.strictEqual(may[5].shown, 1);
assert.deepStrictEqual(may.slice(-6).map(x => x.shown), [1, 2, 3, 4, 5, 6]);
// February 2021 begins Monday and has exactly four complete weeks.
let feb = sequence(2021, 1);
assert.strictEqual(feb.length, 28);
assert.deepStrictEqual(feb.map(x => x.shown), Array.from({length: 28}, (_, i) => i + 1));
// December 2024 starts Sunday and crosses the year boundary in the trailing cells.
let dec = sequence(2024, 11);
assert.strictEqual(dec.length, 42);
assert.deepStrictEqual(dec.slice(-5).map(x => x.shown), [1, 2, 3, 4, 5]);
// A 5-week month should stop at Sunday instead of displaying excessive next-month dates.
let june = sequence(2024, 5);
assert.strictEqual(june.length, 35);
assert.strictEqual(june[june.length - 1].shown, 30);
console.log('Calendar adjacent-month date arithmetic: OK');
JS

python3 - "$CALENDAR" "$SETTINGS" "$PERSIST" "$RESETS" <<'PY'
from pathlib import Path
import sys
calendar, settings, persist, resets = (Path(x).read_text(encoding='utf-8') for x in sys.argv[1:])
assert 'color: dayMouse.containsMouse' in calendar
assert 'Config.accent' in calendar
assert 'dateKeyForDay(day)' in calendar # Notes remain restricted to days in the visible month.
assert 'calendarAdjacentDaysColor: config.calendarAdjacentDaysColor' in persist
assert resets.count('"calendarAdjacentDaysColor"') >= 2
assert 'onClicked: function(mouse)' in calendar
assert 'root.shiftMonth(-1)' in calendar and 'root.shiftMonth(1)' in calendar
assert 'settings.save()' in settings
print('Calendar adjacent-month configuration and interaction: OK')
PY

echo 'Calendar adjacent-month dates/color test: OK'
