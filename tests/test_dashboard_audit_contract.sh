#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
const qml = read('components/Dashboard.qml');
const cards = read('js/dashboard/DashboardCards.js');
const shell = read('shell.qml');

assert.match(qml, /readonly property real targetWidth:[\s\S]*?parent\.width \/ root\.drawerUiScale - 32/,
  'drawer width is bounded by available screen width and UI scale');
assert.match(qml, /readonly property real visualWidth: width \* root\.drawerUiScale/,
  'drawer placement uses its visual scaled dimensions');
assert.match(qml, /readonly property real targetX:[\s\S]*?parent\.width - visualWidth - 16/,
  'default placement keeps the visual right inset');
assert.match(qml, /anchors\.margins: 18/,
  'card content retains its established inner spacing');
assert.match(cards, /function resolveDashboardLayout\(/,
  'card arrangement remains centralized in DashboardCards');
assert.match(cards, /function drawerWidthForScreenWidth\(/,
  'drawer width policy remains centralized and testable');
assert.match(qml, /function moveKeyboardFocus\(/);
assert.match(qml, /function moveKeyboardPage\(/);
assert.match(qml, /function moveKeyboardToEdge\(/);
assert.match(qml, /Keys\.onPressed: function\(event\)/,
  'keyboard navigation is handled by the Dashboard drawer');
assert.match(qml, /id: compactMediaSeekMouseArea/);
assert.match(qml, /id: wideMediaSeekMouseArea/);
assert.match(qml, /root\.seekDashboardMediaAtPointer\(/,
  'media seeking remains available in compact and wide cards');
assert.match(qml, /Accessible\.role: Accessible\.Grouping/,
  'informational cards retain accessible grouping semantics');
assert.match(shell, /onSettingsRequested: shell\.settingsVisible = true/,
  'the explicit Settings entry point remains connected');
assert.doesNotMatch(qml, /signal moduleSettingsRequested/,
  'cards do not expose obsolete per-card settings navigation');
console.log('Dashboard audit contract: PASS');
NODE
