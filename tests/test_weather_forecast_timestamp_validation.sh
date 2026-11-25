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
vm.runInNewContext(source + '\nthis.normalizeWeatherUnixTimestamp = normalizeWeatherUnixTimestamp;', context);
const normalize = value => context.normalizeWeatherUnixTimestamp(value);

for (const input of [
  1, 1785000000, '1785000000', ' 1785000000 ', 8640000000000
]) {
  const timestamp = normalize(input);
  assert(Number.isFinite(timestamp), `valid Unix timestamp ${String(input)} is retained`);
  assert.strictEqual(timestamp, Number(String(input).trim()));
  assert(Number.isFinite(new Date(timestamp * 1000).getTime()),
    `valid Unix timestamp ${String(input)} produces a representable Date`);
}

for (const input of [
  undefined, null, '', ' ', 'NaN', 'Infinity', '-Infinity', '1e9', '0x10',
  '-1', '+1', '1.5', '1,5', 'tomorrow', true, false, [], [1785000000], {},
  { unix: 1785000000 }, 0, -1, 1.5, NaN, Infinity, -Infinity,
  8640000000001, '999999999999999999999999999999999999999999'
]) {
  assert(Number.isNaN(normalize(input)),
    `invalid Unix timestamp ${String(input)} is rejected`);
}

const item = fs.readFileSync(path.join(root, 'components/WeatherForecastItem.qml'), 'utf8');
const list = fs.readFileSync(path.join(root, 'components/WeatherList.qml'), 'utf8');
assert(item.includes('DashboardCards.normalizeWeatherUnixTimestamp(e && e.date ? e.date.unix : null)'),
  'forecast labels validate the date before constructing Date');
assert(item.includes('if (!Number.isFinite(timestamp)) return ""'),
  'invalid forecast dates produce no misleading date label');
assert(item.includes('if (!Number.isFinite(d.getTime())) return ""'),
  'Date range is checked after conversion');
assert(list.includes('import "../js/dashboard/DashboardCards.js" as DashboardCards'),
  'forecast list imports the shared timestamp normalizer');
assert(list.includes('return Number.isFinite(timestamp) && timestamp > now'),
  'forecast list drops malformed and non-future dates before creating delegates');
assert(!list.includes('Number(e.date?.unix ?? 0) > now'),
  'forecast list no longer trusts coercive timestamp conversion');
console.log('Weather forecast timestamp validation: valid Unix seconds retained; malformed dates filtered before delegate creation: OK');
NODE

echo 'Weather forecast timestamp validation: OK'
