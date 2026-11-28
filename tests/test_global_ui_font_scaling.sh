#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = process.argv[2];
const config = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaults = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const persistence = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8');
const resets = fs.readFileSync(path.join(root, 'js/settings/SettingsResets.js'), 'utf8');
const general = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsInterfaceSection.qml'), 'utf8');
const settingsWindow = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsWindowSection.qml'), 'utf8');

for (const key of ['fontScale', 'settingsFontScale']) {
  assert.match(config, new RegExp(`property int ${key}: 100`), `${key} defaults to 100%`);
  assert.match(defaults, new RegExp(`${key}: 100`), `${key} is included in profile defaults`);
  assert.ok(persistence.includes(`${key}: config.${key}`), `${key} is persisted in profiles`);
}
assert.match(config, /function uiFontSize\(baseSize\)[\s\S]*?fontScale[\s\S]*?scale \/ 100/,
  'module font helper multiplies by the global module font scale');
assert.match(config, /function settingsUiSize\(baseSize\)[\s\S]*?settingsFontScale[\s\S]*?Math\.max\(75, Math\.min\(150, scale\)\)[\s\S]*?scale \/ 100/,
  'settings font helper multiplies by the independently clamped settings font scale');
assert.match(config, /function uiFontSize\(baseSize\)[\s\S]*?Math\.max\(75, Math\.min\(150, scale\)\)[\s\S]*?scale \/ 100/,
  'module font helper clamps the global font scale');
assert.ok(resets.includes('"fontScale"'), 'general reset includes module font scale');
assert.ok(resets.includes('"settingsFontScale"'), 'settings reset includes settings font scale');
assert.ok(general.includes('targetProperty: "fontScale"'), 'module font scale is editable in Appearance → Interface settings');
assert.ok(settingsWindow.includes('targetProperty: "settingsFontScale"'), 'settings font scale is editable in Settings window settings');
const topApps = fs.readFileSync(path.join(root, 'components/TopApps.qml'), 'utf8');
assert.ok(topApps.includes('readonly property int displayFontSize: Config.uiFontSize(Config.topAppsFontSize)'),
  'TopApps derived row/font measurement includes the shared global font scale');

const allowedDerived = new Set([
  'root.iconPixelSize', 'root.valuePixelSize', 'root.displayFontSize',
  'Math.max(8, root.valuePixelSize - 1)',
  'root.effectiveTimeFontSize', 'root.effectiveDateFontSize', 'root.effectiveWeekdayFontSize',
  'root.effectiveDisplayFontSize', 'root.effectiveStreamLabelFontSize',
  'measuredTimerItem.displaySize', 'timerDisplay.displaySize'
]);
const qmlFiles = [];
function walk(dir) {
  for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.isFile() && full.endsWith('.qml')) qmlFiles.push(full);
  }
}
walk(path.join(root, 'components'));
qmlFiles.push(path.join(root, 'shell.qml'));
let count = 0;
const unscaled = [];
for (const file of qmlFiles) {
  const source = fs.readFileSync(file, 'utf8');
  const re = /font\.pixelSize\s*:\s*([^;\n}]+)/g;
  let match;
  while ((match = re.exec(source))) {
    count++;
    const expr = match[1].trim();
    if (expr.includes('Config.uiFontSize(') || expr.includes('Config.settingsUiSize(') || allowedDerived.has(expr)) continue;
    if (expr === 'root.hourly' && path.relative(root, file) === 'components/WeatherForecastItem.qml') {
      const end = source.indexOf('elide:', match.index);
      const propertyBody = source.slice(match.index, end >= 0 ? end : match.index + 500);
      assert.ok((propertyBody.match(/Config\.uiFontSize\(/g) || []).length >= 2, 'WeatherForecastItem multiline hourly/daily font branches both apply the global font scale');
      continue;
    }
    const line = source.slice(0, match.index).split('\n').length;
    unscaled.push(`${path.relative(root, file)}:${line}: ${expr}`);
  }
}
assert.ok(count > 600, `expected broad font coverage, found ${count} font.pixelSize declarations`);
const derivedChecks = [
  ['components/NetworkStatRow.qml', 'readonly property int valuePixelSize: Math.round(Config.uiFontSize('],
  ['components/TimeWidget.qml', 'readonly property int effectiveTimeFontSize: Math.max(1, Math.round(\n        Config.uiFontSize('],
  ['components/TimeWidget.qml', 'readonly property int effectiveDateFontSize: Math.max(1, Math.round(\n        Config.uiFontSize('],
  ['components/TimeWidget.qml', 'readonly property int effectiveWeekdayFontSize: Math.max(1, Math.round(\n        Config.uiFontSize('],
  ['components/TopApps.qml', 'readonly property int displayFontSize: Config.uiFontSize('],
  ['components/Volumes.qml', 'Config.uiFontSize(Config.volumeStreamLabelFontSize)']
];
for (const [file, snippet] of derivedChecks) assert.ok(fs.readFileSync(path.join(root, file), 'utf8').includes(snippet), `${file} derives its cached font size from the shared scale helper`);
assert.deepEqual(unscaled, [], `all QML text sizes must use a shared scale helper:\n${unscaled.join('\n')}`);
console.log(`PASS: global font scaling covers ${count} QML pixel-size declarations; settings/module scales and profile reset/persistence are wired.`);
NODE
