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
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
CHECK="$ROOT/CHECK.sh"
for path in "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$CALENDAR" "$SETTINGS" "$WIDGET" "$CHECK"; do test -f "$path"; done

grep -Fq 'function isCurrentMarkedDate(key)' "$CALENDAR"
grep -Fq 'String(key) === root.currentDateKey() && root.isCalendarDateMarked(key)' "$CALENDAR"
grep -Fq 'model: root.isCurrentMarkedDate(dayCell.dateKey) ? [' "$CALENDAR"
grep -Fq '{ dx: -0.45, dy: 0 }' "$CALENDAR"
grep -Fq '{ dx: 0.45, dy: 0 }' "$CALENDAR"
grep -Fq 'opacity: 0.9' "$CALENDAR"
grep -Fq 'color: Config.calendarWeekendColor' "$CALENDAR"
grep -Fq 'id: dayNumberText' "$CALENDAR"
if grep -Fq 'Text.Outline' "$CALENDAR"; then echo 'Built-in thick Text.Outline should not be used' >&2; exit 1; fi
grep -Fq 'color: root.calendarDayTextColor(parent.dateKey, parent.day, dayMouse.containsMouse)' "$CALENDAR"
grep -Fq 'Цвет обводки активной даты с событием' "$SETTINGS"
grep -Fq 'Цвет событий' "$SETTINGS"
if grep -R -Fq 'calendarSelectedEventFrameColorMode' "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$CALENDAR" "$SETTINGS" "$WIDGET"; then
    echo 'Obsolete calendar outline color-mode setting remains' >&2
    exit 1
fi
grep -Fq 'test_calendar_selected_event_outline.sh' "$CHECK"

python3 - "$CALENDAR" "$SETTINGS" "$WIDGET" <<'PY'
from pathlib import Path
import sys
calendar, settings, widget = (Path(p).read_text(encoding='utf-8') for p in sys.argv[1:])
assert 'function isCurrentMarkedDate(key)' in calendar
assert 'return !!key && String(key) === root.currentDateKey() && root.isCalendarDateMarked(key)' in calendar
assert 'model: root.isCurrentMarkedDate(dayCell.dateKey) ? [' in calendar
assert '{ dx: -0.45, dy: 0 }' in calendar
assert '{ dx: 0.45, dy: 0 }' in calendar
assert '{ dx: 0, dy: -0.45 }' in calendar
assert '{ dx: 0, dy: 0.45 }' in calendar
assert 'opacity: 0.9' in calendar
assert 'dx: -0.5, dy: -0.5' not in calendar
assert 'style: root.isCurrentMarkedDate(parent.dateKey) ? Text.Outline' not in calendar
# Keep the original accepted v966 text/hover binding; outline has no say in fill color.
assert 'color: root.calendarDayTextColor(parent.dateKey, parent.day, dayMouse.containsMouse)' in calendar
assert 'color: Config.accent' in calendar
assert 'function calendarDayTextColor(key, day, hovered)' in calendar
assert 'if (String(key || "") === root.currentDateKey()) return Config.accent' in calendar
assert 'if (hovered) return Config.accent' in calendar
assert 'return root.calendarDayColor(key, day)' in calendar
assert 'selectedDateKey' not in calendar
assert 'Цвет событий' in settings
assert 'color: Config.calendarWeekendColor' in calendar
assert 'selectedEventFrameColor' not in calendar
assert '{ prefixes: ["calendarNote"], keys: ["calendarNoteMarkerPosition", "calendarNoteMarkerStyle", "calendarNoteFrameColor"] }' in widget
print('Calendar subtle four-direction event-color glyph outline with active-date text color: OK')
PY

node - "$CALENDAR" <<'JS'
const fs = require('fs');
const source = fs.readFileSync(process.argv[2], 'utf8');
const extract = name => {
  const start = source.indexOf(`function ${name}(`);
  if (start < 0) throw new Error(`missing ${name}`);
  let depth = 0, began = false;
  for (let i = source.indexOf('{', start); i < source.length; i++) {
    if (source[i] === '{') { depth++; began = true; }
    else if (source[i] === '}') {
      depth--;
      if (began && depth === 0) return source.slice(start, i + 1);
    }
  }
  throw new Error(`incomplete ${name}`);
};
const Config = { accent: '#00cccc', calendarWeekendColor: '#d98282', calendarAdjacentDaysColor: '#555555', calendarPastDaysColorEnabled: false, calendarPastDaysColor: '#777777', text: '#dddddd' };
const marked = new Set(['2026-11-14', '2026-11-15']);
const root = {
  daysInMonth: () => 30,
  isCalendarDateMarked: key => marked.has(String(key)),
  currentDateKey: () => '2026-11-14',
  isWeekendDateKey: () => false,
  isPastDateKey: () => false
};
const make = new Function('Config', 'root', `${extract('calendarDayColor')}; ${extract('calendarDayTextColor')}; ${extract('isCurrentMarkedDate')}; return { calendarDayColor, calendarDayTextColor, isCurrentMarkedDate };`)(Config, root);
root.calendarDayColor = make.calendarDayColor;
root.isCurrentMarkedDate = make.isCurrentMarkedDate;
const cases = [
  ['current marked date gets outline', make.isCurrentMarkedDate('2026-11-14'), true],
  ['another marked date does not get current-day outline', make.isCurrentMarkedDate('2026-11-15'), false],
  ['unmarked current date does not get outline', make.isCurrentMarkedDate('2026-11-13'), false],
  ['marked current date keeps active color', make.calendarDayColor('2026-11-14', 14), Config.accent],
  ['current marked date keeps active color while hovered', make.calendarDayTextColor('2026-11-14', 14, true), Config.accent],
  ['ordinary date hover still uses accent', make.calendarDayTextColor('2026-11-13', 13, true), Config.accent],
  ['current marked date keeps active color without hover', make.calendarDayTextColor('2026-11-14', 14, false), Config.accent],
  ['other marked date keeps event color', make.calendarDayTextColor('2026-11-15', 15, false), Config.calendarWeekendColor]
];
for (const [name, actual, expected] of cases) {
  if (actual !== expected) throw new Error(`${name}: expected ${expected}, got ${actual}`);
}
console.log('Calendar current-date active color, event outline and hover behavior: OK');
JS

echo 'Calendar selected-event outline test: OK'
