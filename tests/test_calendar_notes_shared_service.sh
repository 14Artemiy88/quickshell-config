#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const registration = 'singleton CalendarNotes 1.0 services/CalendarNotes.qml';
const qmldir = read('qmldir');
const service = read('services/CalendarNotes.qml');
const calendar = read('components/CalendarWidget.qml');

assert.strictEqual(qmldir.split(registration).length - 1, 1,
  'the shared CalendarNotes singleton must be registered exactly once');
assert.match(service, /^pragma Singleton\s/m,
  'CalendarNotes must be a QML singleton, not instantiated independently by each consumer');
assert.match(service, /property var entries:\s*\(\{\}\)/,
  'the singleton must expose one shared in-memory note map');
assert.match(service, /property bool loaded:\s*false/,
  'the singleton must expose initial-load state');
assert.match(service, /command:\s*\[Quickshell\.shellDir \+ "\/scripts\/calendar_notes", "get"\]/,
  'the singleton must read notes through the existing storage script');
assert.match(service, /Quickshell\.execDetached\(\[\s*Quickshell\.shellDir \+ "\/scripts\/calendar_notes",\s*"set"/,
  'the singleton must save notes through the existing storage script');
assert.match(service, /function dateKeyForOffset\(dayOffset\)[\s\S]*new Date\(now\.getFullYear\(\), now\.getMonth\(\), now\.getDate\(\) \+ Number\(dayOffset \|\| 0\)\)/,
  'date keys must use local Date arithmetic so day offsets cross month/year boundaries');
assert.match(service, /readonly property string todayKey: dateKeyForOffset\(0\)/,
  'today must be derived from the shared local date');
assert.match(service, /readonly property string tomorrowKey: dateKeyForOffset\(1\)/,
  'tomorrow must be derived from the same local date');
assert.match(service, /readonly property string todayNote:/,
  'consumers must have a direct current-day note property');
assert.match(service, /readonly property string tomorrowNote:[\s\S]*entries\[tomorrowKey\]/,
  'consumers must have a direct next-day note property from the same note map');
assert.match(service, /Timer\s*\{[\s\S]*interval:\s*60000[\s\S]*onTriggered:\s*root\.now = new Date\(\)/,
  'the current date must roll over without polling the notes file');
assert.match(service, /function setNote\(key, text\)[\s\S]*root\.entries = next/,
  'note edits must update shared in-memory state immediately');

assert.match(calendar, /readonly property var calendarNotes:\s*CalendarNotes\.entries/,
  'CalendarWidget must consume the shared notes map');
assert.match(calendar, /readonly property bool notesLoaded:\s*CalendarNotes\.loaded/,
  'CalendarWidget must use the shared load state');
assert.match(calendar, /CalendarNotes\.setNote\(key, text\)/,
  'CalendarWidget must persist edits through the shared service');
assert.doesNotMatch(calendar, /id:\s*calendarNotesRead/,
  'CalendarWidget must not create a second notes reader process');
assert.doesNotMatch(calendar, /function setCalendarNotesFromJson/,
  'the old per-widget JSON parsing path must be removed');
assert.strictEqual((calendar.match(/scripts\/calendar_notes/g) || []).length, 0,
  'CalendarWidget must no longer access the notes script directly');
NODE
printf 'Calendar notes shared service: OK\n'
