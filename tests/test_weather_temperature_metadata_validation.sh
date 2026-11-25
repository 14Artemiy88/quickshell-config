#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = {};
vm.runInNewContext(source + '\nthis.normalizeWeatherTemperature = normalizeWeatherTemperature;', context);
const normalize = value => context.normalizeWeatherTemperature(value);

for (const [input, expected] of [
  [-25, '-25'],
  [-25.75, '-25.75'],
  [0, '0'],
  [38, '38'],
  [38.4, '38.4'],
  ['-12', '-12'],
  ['+7.5', '+7.5'],
  ['-3,8', '-3,8'],
  ['  21.00  ', '21.00'],
  ['.5', '.5'],
  ['-,5', '-,5'],
  ['0002.40', '0002.40']
]) {
  assert.strictEqual(normalize(input), expected, `valid temperature ${String(input)}`);
}

for (const input of [
  undefined, null, '', '   ', 'NaN', 'Infinity', '-Infinity',
  '1e2', '-1e2', '0x10', '--2', '2-', '3 °C', 'warm', '1,2.3', '1..2', '.', ',',
  true, false, [], [21], {}, { C: 21 },
  NaN, Infinity, -Infinity
]) {
  assert.strictEqual(normalize(input), '', `invalid temperature ${String(input)}`);
}

const weatherNow = fs.readFileSync(path.join(root, 'components/WeatherNow.qml'), 'utf8');
assert(weatherNow.includes('DashboardCards.normalizeWeatherTemperature(value)'),
  'Weather Now uses the shared temperature normalizer');
assert(weatherNow.includes('text: root.normalizedAirTemperature')
    && weatherNow.includes('visible: root.normalizedAirTemperature !== ""'),
  'invalid or missing air temperature is hidden');
assert(weatherNow.includes('DashboardCards.normalizeWeatherTemperature(value)'),
  'air and comfort values use shared normalization');
assert(weatherNow.includes('root.normalizedComfortTemperature'),
  'comfort label reads the normalized comfort value');
assert(!weatherNow.includes('text: root.weather.temperature?.air?.C ?? ""'),
  'Weather Now no longer renders raw air temperature');
assert(!weatherNow.includes('String(root.weather.temperature?.comfort?.C ?? "")'),
  'Weather Now no longer renders raw comfort temperature');

const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dashboard.includes('DashboardCards.normalizeWeatherTemperature(value ? value.C : null)'),
  'Dashboard primary temperature is normalized');
assert(dashboard.includes('DashboardCards.normalizeWeatherTemperature(\n            temperature && temperature.comfort ? temperature.comfort.C : null)'),
  'Dashboard comfort temperature is normalized');
assert(dashboard.includes('return celsius !== "" ? celsius + "°C" : "—"'),
  'Dashboard retains its em dash fallback for an unavailable air temperature');
assert(!/String\(value\.C\)/.test(dashboard),
  'Dashboard no longer converts raw air temperature directly to display text');
console.log('Weather temperature validation: signed decimal values retained, malformed metadata omitted: OK');
NODE
echo 'Weather temperature metadata validation: OK'
