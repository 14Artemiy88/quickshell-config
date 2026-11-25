#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const root = process.argv[2];
const dash = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const defs = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8');
const shell = fs.readFileSync(path.join(root, 'shell.qml'), 'utf8');
const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');

assert.doesNotMatch(dash, /signal (?:launcherRequested|calendarRequested|moduleSettingsRequested)/,
  'Dashboard no longer exports redundant quick actions or per-card settings routes');
assert.doesNotMatch(dash, /settingsPageId|settingsRequested\(string pageId\)|moduleSettingsRequested/,
  'card definitions are not wired to Settings pages');
assert.doesNotMatch(defs, /settingsPageId:/,
  'the Dashboard card registry no longer carries unused settings destinations');
assert.match(dash, /Accessible\.role: Accessible\.Grouping[\s\S]*?Accessible\.name: infoCard\.title/,
  'cards are exposed as informational groups, not buttons');
assert.match(dash, /details\.push\("Карточка предназначена для просмотра\./,
  'screen readers are told that cards are informational surfaces');
const cardStart = dash.indexOf('component InfoCard: Rectangle {');
const cardEnd = dash.indexOf('\n    }\n}', cardStart);
const card = dash.slice(cardStart, cardEnd);
assert(!card.includes('MouseArea {') && !card.includes('Keys.onPressed:'),
  'pointer click and Enter/Space no longer open module settings from the card surface');
assert.match(card, /HoverHandler\s*\{[\s\S]*?id: cardHover/,
  'cards retain a passive hover treatment without an activation surface');
assert.match(dash, /MouseArea\s*\{\s*anchors\.fill: parent\s*z: 0\s*acceptedButtons: Qt\.AllButtons[\s\S]*?mouse\.accepted = true/,
  'the drawer absorbs passive card clicks so they cannot reach the desktop-dismiss backdrop');
assert(!shell.includes('openDashboardModuleSettings'), 'the obsolete per-card route helper is removed');
assert(!shell.includes('onModuleSettingsRequested'), 'the shell no longer handles per-card settings routes');
assert.match(shell, /Dashboard\s*\{[\s\S]*?onSettingsRequested: shell\.settingsVisible = true/,
  'the single icon button still opens general Settings');
assert.match(readme, /Карточки информационные: клик по их поверхности ничего не открывает/,
  'README documents passive card behavior');
assert.match(readme, /кнопка общих настроек в правом верхнем углу/,
  'README documents the icon-only Settings entry point');
assert.doesNotMatch(readme, /быстрые переходы к Launcher, календарю и Settings|Клик по всей карточке открывает настройки/,
  'README does not describe the removed quick actions or card-to-settings clicks');
console.log('Dashboard passive information cards and explicit Settings navigation: PASS');
NODE
