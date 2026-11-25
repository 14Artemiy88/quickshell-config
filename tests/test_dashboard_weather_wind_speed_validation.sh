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
vm.runInNewContext(source + '\nthis.normalizeWeatherWindSpeed = normalizeWeatherWindSpeed;', context);
const normalize = value => context.normalizeWeatherWindSpeed(value);

for (const [input, expected] of [
  [0, '0'],
  [2, '2'],
  [2.5, '2.5'],
  ['  3.7  ', '3.7'],
  ['3,7', '3,7'],
  ['.5', '.5'],
  [',5', ',5'],
  ['0004.20', '0004.20']
]) {
  assert.strictEqual(normalize(input), expected, `valid wind speed ${String(input)}`);
}

for (const input of [
  undefined, null, '', '   ', -1, '-0.1', 'NaN', 'Infinity', '-Infinity',
  '3 m/s', 'windy', '1e2', '0x10', '1,2.3', '1..2', {}, [], true
]) {
  assert.strictEqual(normalize(input), '', `invalid wind speed ${String(input)}`);
}

const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dashboard.includes('DashboardCards.normalizeWeatherWindSpeed(speed)'),
  'Dashboard routes the shared Gismeteo wind speed through the tested normalizer');
assert(dashboard.includes('normalized !== "" ? normalized + " м/с" : ""'),
  'invalid speed data remains omitted instead of rendering a misleading measurement');
assert(dashboard.includes('infoCard.windText'),
  'existing compact and expanded weather layouts continue to share the normalized wind text');
console.log('Dashboard Weather wind speed validation: decimal formats retained, invalid values omitted: OK');
NODE
echo 'Dashboard Weather wind speed validation: OK'
