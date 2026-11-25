#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const cardsSource = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = {};
vm.runInNewContext(cardsSource + '\nthis.normalizeWeatherTemperature = normalizeWeatherTemperature;', context);
const normalize = value => context.normalizeWeatherTemperature(value);
const number = value => {
  const normalized = normalize(value);
  return normalized !== '' ? Number(normalized.replace(',', '.')) : NaN;
};

for (const [input, expected] of [
  [-25, -25], [-25.75, -25.75], [0, 0], [38, 38], ['-3,8', -3.8],
  [' 21.00 ', 21], ['.5', 0.5], ['+,5', 0.5]
]) {
  assert.strictEqual(number(input), expected, `valid forecast temperature ${String(input)}`);
}
for (const input of [
  undefined, null, '', 'NaN', 'Infinity', '1e2', '0x10', '--2', 'warm',
  true, false, [], [21], {}, { C: 21 }, NaN, Infinity, -Infinity
]) {
  assert(Number.isNaN(number(input)), `invalid forecast temperature ${String(input)} is omitted`);
}

const item = fs.readFileSync(path.join(root, 'components/WeatherForecastItem.qml'), 'utf8');
assert(item.includes('import "../js/dashboard/DashboardCards.js" as DashboardCards'),
  'forecast item imports the shared weather normalizer');
assert(item.includes('DashboardCards.normalizeWeatherTemperature(value)'),
  'forecast values use the same strict normalizer as current weather');
assert(item.includes('function normalizedTemperatureNumber(value)'),
  'forecast number conversion happens only after validation');
assert(item.includes('return normalizedTemperatureNumber(value)'),
  'hourly and daily high temperatures use normalized values');
assert(item.includes('return normalizedTemperatureNumber(e.temperature?.air?.min?.C)'),
  'daily low temperatures use normalized values');
assert(!item.includes('return Number(hourly ? e.temperature'),
  'raw hourly/daily high temperatures are no longer coerced directly');
assert(!item.includes('return Number(e.temperature?.air?.min?.C)'),
  'raw daily low temperatures are no longer coerced directly');
console.log('Weather forecast temperature validation: valid signed decimals retained, malformed metadata omitted: OK');
NODE
echo 'Weather forecast temperature metadata validation: OK'
