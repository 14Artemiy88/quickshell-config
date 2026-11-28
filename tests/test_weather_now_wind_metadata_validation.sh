#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const dashboardCards = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = {};
vm.runInNewContext(dashboardCards + '\nthis.normalizeWeatherWindScale = normalizeWeatherWindScale; this.normalizeWeatherWindSpeed = normalizeWeatherWindSpeed;', context);
const normalizeScale = value => context.normalizeWeatherWindScale(value);
const normalizeSpeed = value => context.normalizeWeatherWindSpeed(value);

for (const [input, expected] of [
  [0, 0], ['0', 0], [1, 1], ['2', 2], [8, 8], ['08', 8]
]) {
  assert.strictEqual(normalizeScale(input), expected, `valid direction ${String(input)}`);
}
for (const input of [undefined, null, '', '  ', -1, 9, 1.5, '1.0', '1e0', '0x3', true, false, [], {}, 'NaN']) {
  assert.strictEqual(normalizeScale(input), -1, `invalid direction ${String(input)}`);
}
for (const [input, expected] of [[0, '0'], [2.5, '2.5'], ['3,7', '3,7'], [' 4 ', '4']]) {
  assert.strictEqual(normalizeSpeed(input), expected, `valid speed ${String(input)}`);
}
for (const input of [undefined, null, '', -1, 'NaN', 'Infinity', '1e2', '3 m/s', true, [], {}]) {
  assert.strictEqual(normalizeSpeed(input), '', `invalid speed ${String(input)}`);
}

const qml = fs.readFileSync(path.join(root, 'components/WeatherNow.qml'), 'utf8');
assert(qml.includes('import "../js/dashboard/DashboardCards.js" as DashboardCards'),
  'WeatherNow reuses Dashboard weather metadata validation');
assert(qml.includes('const n = DashboardCards.normalizeWeatherWindScale(scale)'),
  'wind direction mapping uses strict 0..8 normalization');
assert(qml.includes('case 0: return "Calm"') && qml.includes('default: return ""'),
  'only explicit scale 0 maps to calm; unknown scale is omitted');
assert(qml.includes('return key !== "" ? (Config["weatherWind" + key + "Icon"] || "") : ""'),
  'invalid direction does not fall back to the calm glyph');
assert(qml.includes('return DashboardCards.normalizeWeatherWindSpeed(speed)'),
  'module wind speed uses the shared strict speed normalizer');
assert(qml.includes('text: root.normalizedWindSpeed') && qml.includes('visible: root.normalizedWindSpeed !== ""'),
  'invalid wind speed value is hidden');
assert(qml.includes('text: "м/с"\n                        visible: root.normalizedWindSpeed !== ""'),
  'wind speed unit is hidden when the measurement is invalid or absent');
assert(!qml.includes('text: root.weather.wind?.speed?.m_s ?? ""'),
  'raw unvalidated wind speed is no longer rendered');
console.log('WeatherNow uses strict shared wind direction and speed validation: OK');
NODE
echo 'WeatherNow wind metadata validation: OK'
