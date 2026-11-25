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
vm.runInNewContext(source + '\nthis.normalizeWeatherWindScale = normalizeWeatherWindScale;', context);
const normalize = value => context.normalizeWeatherWindScale(value);

for (const [input, expected] of [
  [0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8],
  ['0', 0], ['1', 1], [' 2 ', 2], ['08', 8]
]) {
  assert.strictEqual(normalize(input), expected, `valid wind scale ${String(input)}`);
}

for (const input of [
  undefined, null, '', '   ', -1, 9, 1.5, '1.0', '1.5', '-0', '-1',
  '1e0', '0x3', '+3', '3.0', '3,0', 'NaN', 'Infinity',
  true, false, [], [3], {}, { value: 3 }
]) {
  assert.strictEqual(normalize(input), -1, `invalid wind scale ${String(input)}`);
}

const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dashboard.includes('DashboardCards.normalizeWeatherWindScale(direction)'),
  'Dashboard routes Gismeteo scale_8 through the tested strict normalizer');
assert(!/Math\.round\(scale\).*scale >= 0/.test(dashboard),
  'old permissive Number coercion is removed from the Dashboard property');
console.log('Dashboard Weather wind direction validation: valid scale 0..8 retained, malformed values omitted: OK');
NODE
echo 'Dashboard Weather wind direction validation: OK'
