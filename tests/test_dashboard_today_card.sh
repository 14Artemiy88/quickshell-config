#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');

const registrySource = read('js/dashboard/DashboardCards.js')
  .replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
const registry = {};
vm.runInNewContext(registrySource + '\nthis.api = { DEFAULT_IDS, DEFINITIONS, defaults, normalize, normalizeOrder, orderedVisible };', registry);
assert.deepStrictEqual(Array.from(registry.api.defaults()), ['today', 'system', 'network', 'weather', 'media'],
  'Today is the first default Dashboard card');
assert.strictEqual(registry.api.DEFINITIONS[0].settingsPageId, undefined,
  'Today remains an informational card rather than a Calendar settings button');
assert.strictEqual(registry.api.normalize(['system', 'media']).includes('today'), false,
  'older explicit custom visibility lists remain unchanged and can be customized independently');
assert.deepStrictEqual(Array.from(registry.api.normalize(['system', 'network', 'weather', 'media'])),
  ['system', 'network', 'weather', 'media'],
  'runtime card visibility preserves an explicit choice to disable Today');

const dashboard = read('components/Dashboard.qml');
assert.match(dashboard, /todayTimeText:\s*root\.clock\s*\?\s*root\.clock\.time/,
  'the card reuses the existing shared Clock time source');
assert.match(dashboard, /todayDateText:[\s\S]*?root\.clock\.weekday\s*\+\s*" · "\s*\+\s*root\.clock\.dateText/,
  'the card reuses Clock weekday and date');
assert.match(dashboard, /todayNoteText:\s*CalendarNotes\.loaded\s*\?\s*String\(CalendarNotes\.todayNote\s*\|\|\s*""\)/,
  'the card consumes the shared CalendarNotes current-day note');
assert.match(dashboard, /tomorrowNoteText:\s*CalendarNotes\.loaded\s*\?\s*String\(CalendarNotes\.tomorrowNote\s*\|\|\s*""\)/,
  'the card consumes the shared CalendarNotes next-day note');
assert.match(dashboard, /visible:\s*infoCard\.cardId\s*===\s*"today"[\s\S]*?text:\s*infoCard\.todayTimeText[\s\S]*?text:\s*infoCard\.todayDateText/,
  'the time and date remain visible inside the Today card');
assert.match(dashboard, /visible:\s*infoCard\.todayNoteText\.trim\(\)\s*!==\s*""[\s\S]*?text:\s*infoCard\.todayNoteText/,
  'the current-day note is omitted when the calendar entry is empty');
assert.match(dashboard, /maximumLineCount:\s*infoCard\.expanded\s*\?\s*3\s*:\s*1/,
  'non-wide Today keeps its compact and expanded note limits');
assert.match(dashboard, /visible:\s*infoCard\.cardId\s*===\s*"today"\s*&&\s*infoCard\.wideLead[\s\S]*?text:\s*infoCard\.todayTimeText[\s\S]*?text:\s*infoCard\.todayDateText[\s\S]*?text:\s*"СЕГОДНЯ"[\s\S]*?text:\s*infoCard\.todayNoteText[\s\S]*?text:\s*"ЗАВТРА"[\s\S]*?text:\s*infoCard\.tomorrowNoteText/,
  'the wide-lead Today card includes separately labeled note rows for both dates when populated');
assert.match(dashboard, /Layout\.preferredHeight:\s*infoCard\.expanded\s*\?\s*112\s*:\s*92/,
  'compact wide Today uses a taller content track so the fixed compact card is not mostly empty');
assert.match(dashboard, /Layout\.horizontalStretchFactor:\s*infoCard\.hasAnyCalendarNotes \? 40 : 100/,
  'wide Today uses the 40/60 split only when notes exist and otherwise gives time/date the full width');
assert.match(dashboard, /visible:\s*infoCard\.hasAnyCalendarNotes[\s\S]*?Layout\.horizontalStretchFactor:\s*60/,
  'the note column and vertical separator are hidden when both notes are empty');
assert.match(dashboard, /readonly property bool hasTodayNote:\s*todayNoteText\.trim\(\) !== ""[\s\S]*?readonly property bool hasTomorrowNote:\s*tomorrowNoteText\.trim\(\) !== ""[\s\S]*?readonly property bool hasAnyCalendarNotes:\s*hasTodayNote \|\| hasTomorrowNote/,
  'Today exposes independent note-presence flags and a combined visibility flag');
assert.match(dashboard, /visible:\s*infoCard\.hasTodayNote[\s\S]*?text:\s*infoCard\.todayNoteText[\s\S]*?maximumLineCount:\s*2/,
  'today row is omitted when empty and supports two lines when present');
assert.match(dashboard, /visible:\s*infoCard\.hasTomorrowNote[\s\S]*?text:\s*infoCard\.tomorrowNoteText[\s\S]*?maximumLineCount:\s*2/,
  'tomorrow row is omitted when empty and supports two lines when present');
assert.match(dashboard, /visible:\s*infoCard\.hasTodayNote && infoCard\.hasTomorrowNote/,
  'the horizontal separator appears only when both notes are present');
assert.doesNotMatch(dashboard, /text:\s*infoCard\.(?:today|tomorrow)NoteText\.trim\(\) !== ""\s*\?\s*infoCard\.(?:today|tomorrow)NoteText : "Нет заметок"/,
  'missing notes do not render placeholder text');
assert.match(dashboard, /anchors\.margins: infoCard\.cardId === "today" && infoCard\.wideLead[\s\S]*?\? 6/,
  'all wide Today cards use tighter card-edge insets regardless of compact or expanded size');
assert.match(dashboard, /anchors\.margins: infoCard\.cardId === "today" && infoCard\.wideLead[\s\S]*?\? 6[\s\S]*?spacing: DashboardCards\.CARD_SECTION_GAP/,
  'wide Today preserves its established outer geometry while tightening the note composition itself');
assert.match(dashboard, /spacing: infoCard\.expanded \? 12 : 6[\s\S]*?spacing: infoCard\.expanded \? 8 : 5/,
  'compact wide Today reduces the gap between clock and notes while slightly increasing the clock/date spacing');
assert.match(dashboard, /anchors\.left: parent\.left[\s\S]*?anchors\.right: parent\.right[\s\S]*?anchors\.leftMargin: infoCard\.expanded \? 6 : 2[\s\S]*?anchors\.rightMargin: infoCard\.expanded \? 6 : 2[\s\S]*?anchors\.verticalCenter: parent\.verticalCenter[\s\S]*?spacing: infoCard\.expanded \? 4 : 2/,
  'wide note rows are tightly inset and kept together as a centred content cluster');
assert.match(dashboard, /Layout\.preferredHeight: infoCard\.expanded \? 34 : 30[\s\S]*?Layout\.maximumHeight: infoCard\.expanded \? 34 : 30[\s\S]*?spacing: 4/,
  'compact wide note rows have enough height for two lines at the slightly larger type scale');
assert.match(dashboard, /Layout\.fillHeight: !\(infoCard\.cardId === "today" && infoCard\.wideLead\)/g,
  'all wide Today cards avoid flexible empty space above and below their content');
assert.match(dashboard, /font\.pixelSize: infoCard\.expanded \? 40 : 34/,
  'compact wide Today increases the clock size to make better use of the compact content track');
assert.match(dashboard, /font\.pixelSize: infoCard\.expanded \? 12 : 11/,
  'compact wide Today increases date and note text size to reduce the oversized visual gaps');
assert.match(dashboard, /maximumLineCount: 2[\s\S]*?verticalAlignment: Text\.AlignVCenter[\s\S]*?visible: infoCard\.hasTomorrowNote/,
  'wide Today note text is allowed two lines in compact as well as expanded mode');
assert.doesNotMatch(dashboard, /Layout\.preferredWidth:\s*parent\.width\s*\*\s*0\.(?:42|58)/,
  'wide Today columns do not derive preferred widths from their RowLayout parent');
assert.match(dashboard, /visible:\s*infoCard\.cardId\s*===\s*"today"\s*&&\s*!infoCard\.wideLead/,
  'non-wide Today cards keep the original vertical composition');
assert.match(dashboard, /visible:\s*infoCard\.tomorrowNoteText\.trim\(\)\s*!==\s*""[\s\S]*?text:\s*infoCard\.tomorrowNoteText/,
  'non-wide Today cards include tomorrow notes when present');
assert.match(dashboard, /details\.push\("Текущее время " \+ infoCard\.todayTimeText\)/,
  'screen readers receive the current time');
assert.match(dashboard, /details\.push\("Дата " \+ infoCard\.todayDateText\)/,
  'screen readers receive the current date');
assert.match(dashboard, /"Заметка на сегодня: " \+ infoCard\.todayNoteText/,
  'screen readers receive the current note when present');
assert.match(dashboard, /"Заметка на завтра: " \+ infoCard\.tomorrowNoteText/,
  'screen readers receive tomorrow note when present');
assert.doesNotMatch(dashboard, /text:\s*root\.clock\s*\?\s*root\.clock\.time/,
  'Dashboard no longer repeats time as a separate header block');
assert.doesNotMatch(dashboard, /text:\s*root\.clock\s*\?\s*root\.clock\.weekday/,
  'Dashboard no longer repeats date as a separate header subtitle');

const calendarNotes = read('services/CalendarNotes.qml');
assert.match(calendarNotes, /readonly property string todayNote:/,
  'Today card is backed by the same singleton property as Calendar');
assert.match(calendarNotes, /function dateKeyForOffset\(dayOffset\)[\s\S]*?new Date\(now\.getFullYear\(\), now\.getMonth\(\), now\.getDate\(\) \+ Number\(dayOffset \|\| 0\)\)/,
  'calendar date offsets use local Date arithmetic, including month and year rollover');
assert.match(calendarNotes, /readonly property string tomorrowKey: dateKeyForOffset\(1\)/,
  'the next-day key is derived from the same clock as today');
assert.match(calendarNotes, /readonly property string tomorrowNote: String\(entries && entries\[tomorrowKey\] !== undefined/,
  'tomorrow note is read from the existing calendar notes store');
const dateOffsetMatch = calendarNotes.match(/function dateKeyForOffset\(dayOffset\) \{([\s\S]*?)\n    \}/);
assert(dateOffsetMatch, 'calendar date offset helper is executable');
const dateContext = { now: new Date(2026, 0, 31) };
vm.runInNewContext(`function dateKeyForOffset(dayOffset) {${dateOffsetMatch[1]}} this.dateKeyForOffset = dateKeyForOffset;`, dateContext);
assert.strictEqual(dateContext.dateKeyForOffset(1), '2026-02-01', 'tomorrow crosses month boundaries correctly');
dateContext.now = new Date(2026, 11, 31);
assert.strictEqual(dateContext.dateKeyForOffset(1), '2027-01-01', 'tomorrow crosses year boundaries correctly');
const calendar = read('components/CalendarWidget.qml');
assert.match(calendar, /CalendarNotes\.setNote\(key, text\)/,
  'Calendar edits update the shared model consumed by the Dashboard');
assert.doesNotMatch(dashboard, /Process\s*\{/,
  'Dashboard does not create a duplicate note reader or polling process');

const config = read('Config.qml');
const defaults = read('js/settings/SettingsDefaults.js');
assert.match(config, /dashboardVisibleCards:\s*\["today", "system", "network", "weather", "media"\]/);
assert.match(defaults, /dashboardVisibleCards:\s*\["today", "system", "network", "weather", "media"\]/);
const settings = read('components/settings/sections/SettingsDashboardSection.qml');
assert.match(settings, /model:\s*DashboardCards\.orderedVisible\(Config\.dashboardCardOrder, null\)/,
  'Today inherits the existing visibility, order and size controls');
const shell = read('shell.qml');
assert.doesNotMatch(shell, /openDashboardModuleSettings/,
  'Today is a passive information card and does not route into Calendar Settings');

console.log('Dashboard Today card: shared time/date/today+tomorrow notes, local date rollover and passive accessibility: OK');
NODE
echo 'dashboard Today card: OK'
