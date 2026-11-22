#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DASH="$ROOT/components/Dashboard.qml"
SHELL="$ROOT/shell.qml"
README="$ROOT/README.md"
node - "$DASH" "$SHELL" "$README" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [dashPath, shellPath, readmePath] = process.argv.slice(2);
const dash = fs.readFileSync(dashPath, 'utf8');
const cardDefinitions = fs.readFileSync(require('path').join(require('path').dirname(dashPath), '..', 'js', 'dashboard', 'DashboardCards.js'), 'utf8');
const shell = fs.readFileSync(shellPath, 'utf8');
const readme = fs.readFileSync(readmePath, 'utf8');

assert.match(dash, /signal moduleSettingsRequested\(string pageId\)/,
  'Dashboard exposes a typed route signal for module settings');
const expectedDefinitions = [
  ['today', 'Сегодня', 'calendar'],
  ['system', 'Система', 'cpuRam'],
  ['network', 'Сеть', 'network'],
  ['weather', 'Погода', 'weather'],
  ['media', 'Медиа', 'player']
];
for (const [id, label, pageId] of expectedDefinitions) {
  assert(cardDefinitions.includes(`{ id: "${id}", label: "${label}"`), `missing Dashboard card definition ${label}`);
  const line = cardDefinitions.split('\n').find(value => value.includes(`{ id: "${id}",`));
  assert(line && line.includes(`settingsPageId: "${pageId}"`), `${label} must route to ${pageId}`);
}
assert.match(dash, /delegate: InfoCard[\s\S]*?settingsPageId: modelData\.settingsPageId[\s\S]*?onSettingsRequested: pageId => root\.moduleSettingsRequested\(pageId\)/,
  'ordered card delegates must forward each definition settings route');
assert.doesNotMatch(dash, /Настройки ↗|settingsActionLabel/,
  'the duplicate in-card settings button is removed');
assert.match(dash, /color: infoCard\.activeFocus[\s\S]*?: "transparent"/,
  'cards have no permanent background while hover and focus feedback remain');
assert.match(dash, /border\.color: infoCard\.activeFocus[\s\S]*?Qt\.rgba\(Config\.baseColor\.r, Config\.baseColor\.g, Config\.baseColor\.b, 0\.52\)/,
  'cards retain their subtle permanent outline while hover and focus remain accentuated');
assert.match(dash, /color: "transparent"\s+border\.width: 0/,
  'the wide Today note inset no longer draws a nested card surface');
assert.match(dash, /onClicked:\s*\{[\s\S]*?infoCard\.settingsRequested\(infoCard\.settingsPageId\)/,
  'clicking the card opens its existing module settings page');
assert.match(dash, /cursorShape: Qt\.PointingHandCursor/,
  'interactive cards expose a pointing cursor');

assert.match(shell, /function openDashboardModuleSettings\(pageId\)/,
  'shell provides a central and validated route handler');
assert.match(shell, /var allowedPages = \["cpuRam", "network", "weather", "player", "calendar", "dashboard"\]/,
  'only known Dashboard card settings routes are accepted');
assert.match(shell, /shell\.dashboardVisible = false[\s\S]*?shell\.settingsVisible = true/,
  'routing closes Dashboard and opens Settings');
assert.match(shell, /settingsWidget\.selectSettingsTab\(targetPage\)[\s\S]*?settingsWidget\.currentPageSubTabIndex = 0/,
  'routing selects the matching page and first subtab');
assert.match(shell, /onModuleSettingsRequested: pageId => shell\.openDashboardModuleSettings\(pageId\)/,
  'Dashboard signal is connected to the shell route handler');

// Execute the exact shell helper with small mocks to verify that each allowed
// route (card destinations plus the empty-state Dashboard settings action)
// opens Settings, closes Dashboard and selects the matching first subtab.
const helperStart = shell.indexOf('function openDashboardModuleSettings(pageId)');
assert(helperStart >= 0, 'route helper must exist');
const helperOpen = shell.indexOf('{', helperStart);
let depth = 0;
let helperEnd = -1;
for (let i = helperOpen; i < shell.length; i++) {
  if (shell[i] === '{') depth++;
  else if (shell[i] === '}' && --depth === 0) { helperEnd = i + 1; break; }
}
assert(helperEnd > helperOpen, 'route helper must have balanced braces');
const helperSource = shell.slice(helperStart, helperEnd);
for (const pageId of ['calendar', 'cpuRam', 'network', 'weather', 'player', 'dashboard']) {
  const state = { dashboardVisible: true, settingsVisible: false };
  const calls = [];
  const widget = {
    selected: '',
    currentPageSubTabIndex: 5,
    selectSettingsTab(id) { this.selected = id; }
  };
  const Qt = { callLater(callback) { calls.push(callback); } };
  const invoke = new Function('shell', 'Qt', 'settingsWidget', `${helperSource}; return openDashboardModuleSettings;`)(state, Qt, widget);
  invoke(pageId);
  assert.strictEqual(state.dashboardVisible, false, `${pageId} closes Dashboard`);
  assert.strictEqual(state.settingsVisible, true, `${pageId} opens Settings`);
  assert.strictEqual(calls.length, 1, `${pageId} schedules settings navigation`);
  calls[0]();
  assert.strictEqual(widget.selected, pageId, `${pageId} selects the matching Settings page`);
  assert.strictEqual(widget.currentPageSubTabIndex, 0, `${pageId} selects the first subtab`);
}
{
  const state = { dashboardVisible: true, settingsVisible: false };
  const calls = [];
  const widget = { selectSettingsTab() { throw new Error('invalid route must not navigate'); } };
  const invoke = new Function('shell', 'Qt', 'settingsWidget', `${helperSource}; return openDashboardModuleSettings;`)(
    state, { callLater(callback) { calls.push(callback); } }, widget);
  invoke('launcher');
  assert.deepStrictEqual(state, { dashboardVisible: true, settingsVisible: false }, 'invalid page IDs are ignored');
  assert.strictEqual(calls.length, 0, 'invalid page IDs do not schedule navigation');
}
assert.match(readme, /клик по всей карточке открывает настройки соответствующего модуля/i);
assert.match(readme, /карточка «Сегодня» объединяет текущее время, дату и заметки календаря на сегодня и завтра/i);
assert.match(readme, /отдельной кнопки перехода внутри карточки нет/i);
console.log('Dashboard card-to-module-settings routing: OK');
NODE
echo 'dashboard card module navigation: OK'
